# encoding: utf-8

Gem::Specification.new do |s|
  s.name        = 'nfe'
  s.version     = '0.0.3'
  s.date        = '2012-03-05'
  s.summary     = "Nota Fiscal Eletrônica"
  s.description = "Biblioteca para auxiliar na emissão NFe"
  s.authors     = ["Mateus Lorandi dos Santos", "José Gomes Júnior"]
  s.email       = ['mcomogo@gmail.com', 'zegomesjf@gmail.com']
  s.files       = `git ls-files| grep lib`.split("\n")
  s.require_paths = ['lib']
  s.homepage    = 'https://github.com/comogo/nfe'
  s.required_ruby_version = '>= 1.9.1'
  s.executables << 'nfe'

  s.add_dependency('nokogiri', '1.5.0')
  s.add_dependency('rest-client', '1.6.7')
end
