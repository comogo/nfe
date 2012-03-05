# encoding: UTF-8
require_relative 'connection'

module Mail
  class NfeMailer
    def initialize(params)
      @folder = folder(params[:folder]) || :inbox
      @read_only = params[:read_only] || true
    end

    def get_emails(params)
      emails = []
      key_array = keys(params)
      Mail::Connection.run(@folder, @read_only) do |c|
        c.search(key_array).each do |mail_id|
          email = Email.new(@folder, mail_id)
          if email.body
            emails << email
          end
        end
      end
      emails
    end

# As chaves podem ser encontradas na documentação do IMAP, seção 6.4.4
# conforme link a seguir http://tools.ietf.org/html/rfc3501section-6.4.4
# samples: 
# ["SINCE", "29-Feb-2012", "UNSEEN"]
# ["DELETED", "FROM", "SMITH" "SINCE" "1-Feb-1994"]
    def keys(params)
      keys_array = []
      keys_array << "ANSWERED" if params[:answered]
      keys_array << "SINCE" if params[:since]
      keys_array << params[:since] if params[:since]
      keys_array << "UNSEEN" if params[:unseen]
      keys_array
    end

    private
    def folder(f)
      f.to_s.upcase
    end
  end
   
  # Classe responsável por retornar um Attachment com os seguintes parâmetros
  class Attachment
    def initialize(folder, msg_id, attachment_id, raw_attachment)
      @folder = folder
      @msg_id = msg_id
      @attachment_id = attachment_id
      @raw_attachment = raw_attachment
      @body = nil
    end

    def save_attachments(path='./')
      unless File.directory?(path)
        Dir.mkdir(path)
      end
      File.write(File.join(path, name), body, mode: 'w')
    end

    def body    
      Mail::Connection.run(@folder, true) do |c|      
        index = "BODY[#{@attachment_id + 1}]"
        body_packed = c.fetch(@msg_id, index)[0].attr[index]
        @body = case encoding
                  when 'BASE64' then body_packed.unpack('m')[0]
                  else
                    nil
                end unless @body
      end
      @body
    end

    def media_type
      @raw_attachment.media_type
    end

    def subtype
      @raw_attachment.subtype
    end

    def name
      @raw_attachment.param['NAME']
    end

    def content_id    
      @raw_attachment.content_id
    end

    def description
      @raw_attachment.description    
    end

    def encoding
      @raw_attachment.encoding
    end
    
    def size
      @raw_attachment.size
    end

    def lines  
      @raw_attachment.lines
    end

    def md5   
      @raw_attachment.md5
    end

    def disposition
      @raw_attachment.disposition
    end

    def language 
      @raw_attachment.language
    end

    def extension
      @raw_attachment.extension
    end

    def raw_attachment
      @raw_attachment
    end
  end

  class Email
    def initialize(folder, email_id)
      @folder = folder
      @email_id = email_id
      @raw_body = get_body
      @raw_envelope = get_envelope
    end

    def to_s
      begin
        "Email: #{@email_id}, From: #{from}, Date: #{date}"
      rescue => err
        puts "email #{@email_id} gerou a exceção #{err}."
      end
    end

    def from
      senders = []      
      @raw_envelope.from.each do |s|
        senders << {
          :name => s.name,
          :email => s.mailbox + '@' + s.host
        }
      end if @raw_envelope
      senders
    end

    def to
      receivers = []
      @raw_envelope.to.each do |r|
        receivers << {
          :name => r.name,
          :email => r.mailbox + '@' + r.host
        }
      end if @raw_envelope
      receivers
    end

    def subject
      @raw_envelope.subject if @raw_envelope
    end

    def date
      @raw_envelope.date if @raw_envelope
    end

    def body
      get_body
      @raw_body
    end

    def attachments
      i = 1
      atts = []
      while body.parts[i] != nil
        atts << Attachment.new(@folder, @email_id, i, body.parts[i])
        i+=1
      end if is_multipart?
      atts
    end

    def media_type
      body['media_type'] if body
    end

    def is_multipart?      
      media_type == 'MULTI_PART'
    end

    private

    def get_body
      raw_body = nil
      begin
        Mail::Connection.run(@folder, true) do |c|
          raw_body = c.fetch(@email_id, ['BODY'])[0].attr['BODY']
        end unless @raw_body
      rescue
        raw_body = nil
      end
      raw_body
    end

    def get_envelope
      raw_envelope = nil
      begin
        Mail::Connection.run(@folder, true) do |c|
          raw_envelope = c.fetch(@email_id, ['ENVELOPE'])[0].attr['ENVELOPE']
        end unless @raw_envelope
      rescue
        raw_envelope = nil
      end
      raw_envelope
    end
  end
end
