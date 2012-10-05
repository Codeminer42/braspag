# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rbraspag/version"

Gem::Specification.new do |s|
  s.name        = "rbraspag"
  s.version     = Braspag::VERSION
  s.authors     = ["Celestino Gomes", "Renato Elias", "Luca Bastos", "Lenon Marcel", "Madson Cardoso", "Marcelo Linhares"]
  s.email       = %w[tinorj@gmail.com renato.elias@gmail.com lucabastos@gmail.com lenon.marcel@gmail.com madsonmac@gmail.com marcelolinhares@gmail.com]
  s.homepage    = "http://github.com/concretesolutions/rbraspag"
  s.summary     = "rbraspag gem to use Braspag gateway"
  s.description = "rbraspag gem to use Braspag gateway"

  s.rubyforge_project = "rbraspag"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'httpi', '>= 0.9.6'
  s.add_dependency 'json', '>= 1.6.1'
  s.add_dependency 'nokogiri', '>= 1.4.7'
  s.add_dependency 'savon', '>= 0.9.9'

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "fakeweb"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-bundler"
  s.add_development_dependency "debugger"
end
