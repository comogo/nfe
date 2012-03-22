require 'erb'

module Nfe
  class Template
    def initialize(file_path)
      @template = ERB.new(File.read(file_path), 0, '>')
      if block_given?
        yield self
        render
      end
    end

    def add(name, value)
      self.class.send :attr_accessor, name
      send "#{name}=".to_sym, value
    end

    def render
      if block_given?
        yield self
      end

      template = @template.result(binding)
      compress(template)
    end

    private

    def compress(template)
      rendered = ""
      template.split("\n").each do |t|
        rendered += t.strip
      end

      return rendered
    end
  end
end
