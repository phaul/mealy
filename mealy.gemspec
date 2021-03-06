# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'mealy'
  s.version     = '0.1.0'
  s.date        = '2018-09-24'
  s.summary     = 'A ruby DSL to create mealy state machines.'
  s.description = <<ED
An easy on the eye DSL to define Mealy FSMs. Can be used for lexers, stream
transformers etc.
ED
  s.authors     = ['Paul Sonkoly']
  s.email       = 'sonkoly.pal@gmail.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'http://github.com/phaul/mealy'
  s.license     = 'MIT'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
end
