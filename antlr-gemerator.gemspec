$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'antlr-gemerator/version'

Gem::Specification.new do |s|
  s.name     = 'antlr-gemerator'
  s.version  = ::AntlrGemerator::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron/antlr-gemerator'

  s.description = s.summary = 'Generate a complete Rubygem from any ANTLR4 grammar.'

  s.platform = Gem::Platform::RUBY

  s.add_dependency 'antlr4-native', '~> 1.0'
  s.add_dependency 'gli', '~> 2.0'

  s.executables << 'antlr-gemerator'

  s.require_path = 'lib'
  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'README.md', 'Rakefile', 'antlr-gemerator.gemspec']
end
