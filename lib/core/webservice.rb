require_relative 'services'
require_relative 'protocol'
require_relative 'template'
require 'rest_client'

module Nfe
  class WebService
    def initialize(producao=false, key_password='', uf=:pr, verbose=false)
      cert_path = "cert/cert.pem"
      key_path= "cert/key.pem"
      generate_cert_key cert_path, key_path, key_password
      @key_password = key_password
      @producao = producao
      @verbose = verbose
      @url_generator = Util.new
      @uf = @url_generator.get_uf_id(uf)
    end

    # Realiza uma consulta de status da nota fiscal sefa.
    def consulta_nfe(chave_acesso)
      uf_id = @url_generator.get_uf_id get_uf_chave_acesso(chave_acesso)

      template = Template.new "requests/consulta_nfe.xml.erb" do |t|
        t.add :uf_id_certificado, @uf
        t.add :uf_id, uf_id
        t.add :chave_acesso, chave_acesso
        t.add :ambiente, get_ambiente
      end

      url = @url_generator.get_url_for uf_id, get_ambiente, :consulta_nfe
      if @verbose
        template.render
      end
      xml = request url, template.render
      ResponseConsultaNota.new(xml)
    end

    def consulta_servico(uf)
      template = Template.new "requests/consulta_servico.xml.erb" do |t|
        t.add :uf_id_certificado, @uf
        t.add :ambiente, get_ambiente
        t.add :uf_id, @url_generator.get_uf_id(uf)
      end

      url = @url_generator.get_url_for uf, get_ambiente, :consulta_servico
      if @verbose
        template.render
      end
      xml = request url, template.render
      ResponseStatusServico.new(xml)
    end

  private
    def request(url, content)
      request = RestClient::Resource.new(
        url,
        :ssl_client_cert  =>  @cert,
        :ssl_client_key   =>  @key,
        :verify_ssl       =>  OpenSSL::SSL::VERIFY_NONE
      )

      request.post(content, :content_type =>  'application/soap+xml;charset=UTF-8')
    end

    def generate_cert_key(cert_path, key_path, key_password)
      @cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
      @key = OpenSSL::PKey::RSA.new(File.read(key_path), key_password)
    end

    def get_uf_chave_acesso(chave_acesso)
       @url_generator.get_uf chave_acesso[0...2]
    end

    def get_ambiente
      @producao ? 1 : 2
    end
  end
end
