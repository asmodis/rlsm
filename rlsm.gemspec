# -*- ruby -*-

require "rake"
require File.join(File.dirname(__FILE__), 'lib', 'rlsm')

Gem::Specification.new do |s|
  s.author = "Gunther Diemant"
  s.email = "g.diemant@gmx.net"
  s.homepage = "http://github.com/asmodis/rlsm"
  s.rubyforge_project = 'rlsm'

  s.name = 'rlsm'
  s.version = RLSM::VERSION
  s.add_development_dependency('minitest')
  s.add_development_dependency('thoughtbot-shoulda')
  s.summary = "Library for investigating regular languages and syntactic monoids."
  s.description = "see README"

  s.files = File.open("Manifest").to_a.map { |file| file.strip }
  s.test_files = FileList['test/test_*.rb']
  s.extensions = FileList['ext/**/extconf.rb']

  s.has_rdoc = true
  s.extra_rdoc_files = ['README']
  s.rdoc_options << '--main' << 'README'
end
