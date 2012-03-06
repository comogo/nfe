require 'yaml'

module Nfe
  class Util
    @@urls = nil
    @@ufs = nil
    def initialize
      url_file_path = 'conf/url.yml'
      uf_file_path = 'conf/uf.yml'
      @@urls = YAML.load_file(url_file_path) if @@urls.nil?
      @@ufs = YAML.load_file( uf_file_path) if @@ufs.nil?
    end

    def get_url_for(uf, ambiente, tipo)
      if uf.instance_of? Fixnum
        uf = get_uf(uf)
      end

      if ambiente.instance_of? Fixnum
        ambiente = ambiente == 1 ? :producao : :homologacao
      end

      @@urls[uf.to_s][ambiente.to_s][tipo.to_s]
    end

    def get_uf_id(uf)
      @@ufs[uf.to_s]
    end

    def get_uf(uf_id)
      @@ufs.key uf_id.to_i
    end
  end
end
