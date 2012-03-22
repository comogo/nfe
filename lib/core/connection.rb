#encoding: utf-8

require 'net/imap'
require 'yaml'
require 'logger'

module Mail
  class Connection
    @@connection = nil
    @@params = nil

    def self.run(mailbox, read_only, &block)
      connection = get_connection
      if read_only
        method = 'examine'
      else
        method = 'select'
      end
      connection.send(method, mailbox)
      block.call connection
    end

    def self.get_connection
      unless @@connection
        @@params = YAML.load_file('./conf/email.yml') if @@params.nil?
        @@connection = Net::IMAP.new(@@params['address'])
        @@connection.login @@params['username'], @@params['password']
      end
      @@connection
    end
  end
end





