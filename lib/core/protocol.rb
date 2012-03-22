require 'nokogiri'

module Nfe
  class ResponseBase
    def initialize(xml)
      make_attributes
      fill_data Nokogiri::XML(xml)
    end

    # Método utilizado em subclasses para fazer o mapeamento de dos atributos
    # contidos no XML e atributos da classe Ruby
    #
    # Ex:
    #
    # class ResponseStatusServico < ResponseBase
    #   configure :ambiente => 'tpAmb', :status => 'cStat', :uf => 'cUF',
    #             :versao_aplicacao => 'verAplic',:motivo => 'xMotivo',
    #             :data => 'dhRecbto', :tempo_medio => 'tMed'
    # end
    #
    # Nesta classe está sendo criada o mapeamento dos atributos do XML para
    # atributos de classe, além de que será criado attr_acessors para os nomes
    # conforme o informado.
    def self.configure(hash)
      @@attr_mapping = hash
    end

    def to_xml
      xml = "<retorno>"
      @@attr_mapping.each do |k,v|
        value = send k
        xml += "<#{k}>" + value + "</#{k}>" if value
      end
      xml += "</retorno>"

      return xml
    end

    private

    # Metaprogramação para criar attr_accessors em tempo de execução para a
    # classe conforme as chaves do hash.
    def make_attributes
      @@attr_mapping.each_pair do |k, v|
        self.class.send :attr_accessor, k.to_s
      end
    end

    # Preenche os dados nas variáveis de instância conforme o os dados do XML.
    def fill_data(xml)
      elements = get_dados_xml(xml)
      elements.each do |e|
        if @@attr_mapping.has_value? e.name
          k = @@attr_mapping.key e.name
          if  e.name == 'protNFe'
            value = protocol_xml_to_hash(e.children()[0].children())
          else
            value = e.content
          end
          send("#{k}=".to_sym, value)
        end
      end
    end

    # Retorna apenas os dados referentes aos dados do Body.
    def get_dados_xml(xml)
      xml.remove_namespaces!
      xml.css("Body")[0].children()[0].children()[0].children()
    end

    # Cria uma instância da classe Protocolo conforme os dados recebidos no XML.
    def protocol_xml_to_hash(protocol_xml)
      h = {}
      protocol_xml.each do |n| # para cada elemento do protocolo
        h[n.name] = n.content
      end
      return Protocolo.new h
    end
  end

  # Classe que representa o retorno da solicitação de consultar o status do
  # serviço.
  class ResponseStatusServico < ResponseBase
    configure :ambiente => 'tpAmb', :status => 'cStat', :uf => 'cUF',
              :versao_aplicacao => 'verAplic',:motivo => 'xMotivo',
              :data => 'dhRecbto', :tempo_medio => 'tMed'
  end

  # Classe que representa o retorno da solicitação de consultar o status da
  # nota fiscal eletrônica.
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

    def to_str
      xml = "<ambiente>" + @ambiente + "</ambiente>"
      xml += "<versao>" + @versao + "</versao>"
      xml += "<chave_acesso>" + @chave_acesso + "</chave_acesso>"
      xml += "<data_recibo>" + @data_recibo + "</data_recibo>"
      xml += "<protocolo>" + @protocolo + "</protocolo>"
      xml += "<digito_validador>" + @digito_validador + "</digito_validador>"
      xml += "<status>" + @status + "</status>"
      xml += "<motivo>" + @motivo + "</motivo>"

      return xml
    end
  end
end
