require 'fileutils'
require 'antlr4-native'

require 'pry-byebug'

module AntlrGemerator
  autoload :Template, 'antlr-gemerator/template'

  class << self
    def create(options)
      generator = Antlr4Native::Generator.new(
        grammar_files:      options[:grammar],
        output_dir:         'ext/',
        parser_root_method: options[:root]
      )

      bindings = {
        gem_name:            generator.ext_name,
        gem_namepace:        generator.parser_ns,
        gem_author_name:     options[:author],
        gem_author_email:    options[:email],
        gem_homepage:        options[:homepage] || '',
        gem_description:     options[:desc],
        grammar_files_array: options[:grammar],
        root_method:         options[:root]
      }

      mkdir options[:output]
      Dir.chdir(options[:output])

      # root level files
      render 'gitignore.erb', '.gitignore', bindings
      render 'Gemfile.erb', 'Gemfile', bindings
      render 'gemspec.erb', "#{bindings[:gem_name]}.gemspec", bindings
      render 'Rakefile.erb', 'Rakefile', bindings

      # lib
      mkdir File.join('lib', bindings[:gem_name])

      render 'entrypoint.rb.erb', "#{bindings[:gem_name]}.rb", bindings
      render 'version.rb.erb', File.join('lib', 'version.rb'), bindings
    end

    private

    def render(src, dest, bindings)
      tmpl = Template.new(File.read(File.join(template_dir, src)), bindings)
      File.write(dest, tmpl.render)
    end

    def mkdir(dir)
      FileUtils.mkdir_p(dir)
    end

    def template_dir
      @template_dir ||= File.expand_path(File.join('antlr-gemerator', 'templates'), __dir__)
    end
  end
end
