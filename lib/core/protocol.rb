require 'nokogiri'

module Nfe
  class ResponseBase
    def initialize(xml)
      make_attributes
      fill_data Nokogiri::XML(xml)
    end

    def self.configure(hash)
      @@attr_mapping = hash
    end

    private

    def make_attributes
      @@attr_mapping.each_pair do |k, v|
        self.class.send :attr_accessor, k.to_s
      end
    end

    def fill_data(xml)
      elements = xml.css("env|Body")[0].children()[0].children()[0]   
      elements.children().each do |e|
        if @@attr_mapping.has_value? e.name
          k = @@attr_mapping.key e.name
          if  e.name == 'protNFe'
            p = create_protocol(e.children()[0].element_children)
            send("protocolo=".to_sym, p)  
          else
            send("#{k}=".to_sym, e.content)
          end
        end
      end
    end
    
    def create_protocol(protocol_xml)
      h = {}
      protocol_xml.each do |n|
        h[n.name] = n.content
      end
      return Protocolo.new h
    end
  end

  class ResponseStatusServico < ResponseBase
    configure :ambiente => 'tpAmb', :status => 'cStat', :uf => 'cUF',
              :versao_aplicacao => 'verAplic',:motivo => 'xMotivo',
              :data => 'dhRecbto', :tempo_medio => 'tMed'
  end

  class ResponseConsultaNota < ResponseBase
    configure :status => 'cStat', :uf => 'cUF', :chave_acesso => 'chNFe',
              :ambiente => 'tpAmb', :versao_aplicacao => 'verAplic',
              :motivo => 'xMotivo', :protocolo => 'protNFe'
  end

  class Protocolo
    attr_accessor :ambiente, :versao, :chave_acesso, :data_recibo, :status,
                  :digito_validador, :motivo, :protocolo
                  
    def initialize(hsh)
      @ambiente = hsh['tpAmb']
      @versao = hsh['verAplic']
      @chave_acesso = hsh['chNFe']
      @data_recibo = hsh['dhRecbto']
      @protocolo = hsh['nProt']
      @digito_validador = hsh['digVal']
      @status = hsh['cStat']
      @motivo = hsh['xMotivo']
    end
  end
end
