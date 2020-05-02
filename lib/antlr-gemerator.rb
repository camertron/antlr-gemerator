require 'fileutils'
require 'antlr4-native'
require 'etc'

module AntlrGemerator
  autoload :Template, 'antlr-gemerator/template'

  class << self
    def create(options)
      root_dir = '.'
      lib_dir = File.join(root_dir, 'lib')
      ext_dir = File.join(root_dir, 'ext')

      # ANTLR does weird things if the grammar file isn't in the current
      # working directory
      grammars = options[:grammar].map do |g|
        local_g = File.join(root_dir, File.basename(g))
        FileUtils.cp(g, local_g)
        local_g
      end

      generator = Antlr4Native::Generator.new(
        grammar_files:      grammars,
        output_dir:         ext_dir,
        parser_root_method: options[:root]
      )

      bindings = {
        gem_name:            generator.gem_name,
        ext_name:            generator.ext_name,
        gem_namespace:       generator.parser_ns,
        gem_author_name:     options[:author],
        gem_author_email:    options[:email],
        gem_homepage:        options[:homepage] || '',
        gem_description:     options[:desc],
        grammar_files_array: grammars,
        root_method:         options[:root]
      }

      # root level files
      render 'gitignore.erb', File.join(root_dir, '.gitignore'), bindings
      render 'Gemfile.erb', File.join(root_dir, 'Gemfile'), bindings
      render 'gemspec.erb', File.join(root_dir, "#{bindings[:gem_name]}.gemspec"), bindings
      render 'Rakefile.erb', File.join(root_dir, 'Rakefile'), bindings

      # lib
      mkdir File.join(lib_dir, bindings[:gem_name])

      render 'entrypoint.rb.erb', File.join(lib_dir, "#{bindings[:gem_name]}.rb"), bindings
      render 'version.rb.erb', File.join(lib_dir, bindings[:gem_name], 'version.rb'), bindings

      # ext
      antlr_version = Antlr4Native::Generator::ANTLR_VERSION
      antlr_upstream_dir = File.join(ext_dir, bindings[:gem_name], 'antlr4-upstream')

      mkdir File.join(ext_dir, bindings[:gem_name])

      extension_dir = File.join(ext_dir, bindings[:gem_name])
      extconf_path = File.join(extension_dir, 'extconf.rb')
      render 'extconf.rb.erb', extconf_path, bindings

      run 'git init', root_dir

      # git is very stupid and won't let me pass a tag to git submodule add
      run "git submodule add git://github.com/antlr/antlr4 #{antlr_upstream_dir}", root_dir
      Dir.chdir(antlr_upstream_dir) { run "git checkout #{antlr_version}" }

      generator.generate

      bx 'bundle install', root_dir

      # build
      bx "ruby extconf.rb", extension_dir
      run "make -j #{Etc.nprocessors}", extension_dir
    end

    private

    def render(src, dest, bindings)
      puts "RENDER #{dest}"
      tmpl = Template.new(File.read(File.join(template_dir, src)), bindings)
      File.write(dest, tmpl.render)
    end

    def mkdir(dir)
      "MKDIR #{dir}"
      FileUtils.mkdir_p(dir)
    end

    def run(cmd, in_dir = '.')
      puts "RUN #{cmd}"
      Dir.chdir(in_dir) { system(cmd) }
    end

    def bx(cmd, in_dir)
      runner = -> { run(cmd, in_dir) }

      if Kernel.const_defined?(:Bundler)
        Bundler.with_clean_env(&runner)
      else
        runner.call
      end
    end

    def template_dir
      @template_dir ||= File.expand_path(File.join('antlr-gemerator', 'templates'), __dir__)
    end
  end
end
