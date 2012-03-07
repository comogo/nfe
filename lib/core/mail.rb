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
        c.search(key_array).each do |email_id|
          email = Email.new(@folder, email_id)

          raw_body = c.fetch(email_id, ['BODY'])[0].attr['BODY']
          raw_envelope = c.fetch(email_id, ['ENVELOPE'])[0].attr['ENVELOPE']

          email.raw_body = raw_body
          email.raw_envelope = raw_envelope

          if email.is_multipart?
            atta_id = 1
            atts = []
            while email.body.parts[atta_id] != nil
              att = Attachment.new(@folder, email_id, atta_id, email.body.parts[atta_id])

              index = "BODY[#{atta_id + 1}]"
              att.body = c.fetch(email_id, index)[0].attr[index]
              atts << att
              atta_id += 1
            end
            email.attachments = atts
          end

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

    attr_accessor :body

    def initialize(folder, email_id, attachment_id, raw_attachment)
      @folder = folder
      @email_id = email_id
      @attachment_id = attachment_id
      @raw_attachment = raw_attachment
    end

    def save_attachments(path='./')
      unless File.directory?(path)
        Dir.mkdir(path)
      end
      File.write(File.join(path, name), body, mode: 'w')
    end

    def body_unpacked
      return case encoding
        when 'BASE64' then @body.unpack('m')[0]
        else nil
      end if @body
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
    attr_accessor :raw_body, :raw_envelope, :email_id, :attachments

    def initialize(folder, email_id)
      @folder = folder
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
      @raw_body
    end

    def media_type
      body['media_type'] if body
    end

    def is_multipart?
      media_type == 'MULTIPART'
    end
  end
end
