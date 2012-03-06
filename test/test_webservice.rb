require "test/unit"
require 'nfe'

class TestWebservice < Test::Unit::TestCase
  ROOT_PATH = File.join(File.dirname(__FILE__), '..')

  def test_webservice_without_pkey
    assert_raise( OpenSSL::PKey::RSAError ) do
      Nfe::WebService.new(false, '', ROOT_PATH)
    end
  end

  def test_webservice_with_pkey
    nfe = nil
    assert_nothing_raised( OpenSSL::PKey::RSAError ) do
      nfe = Nfe::WebService.new(false, 'iriedi', ROOT_PATH)
    end

    assert nfe, "Nfe nao foi instanciado"
  end

  def test_consulta_servico
    nfe_ws = Nfe::WebService.new(false, 'iriedi', ROOT_PATH)
    assert nfe_ws.respond_to? 'consulta_nfe'
    chave_acesso = "41111077856995000111550010000248771095965342"
    resp = nfe_ws.consulta_nfe(chave_acesso)
    assert resp.respond_to? 'status'
  end
end
