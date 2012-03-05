#encoding: utf-8

require 'net/imap'
require 'yaml'
require 'logger'

module Mail
  class Connection
    @@connection = nil
    @@params = nil

    def self.run(mailbox, read_only)
      connection = get_connection
      if read_only
        method = 'examine'
      else
        method = 'select'
      end
      connection.send(method, mailbox)
      yield connection
    end

    def self.get_connection
      if @@connection
        return @@connection
      else
        @@params = YAML.load_file('conf/email.yml') if @@params.nil?
        @@connection = Net::IMAP.new(@@params['address'])
        @@connection.login @@params['username'], @@params['password']
        @@connection
      end
    end
  end
end
