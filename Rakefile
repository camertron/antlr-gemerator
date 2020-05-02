require 'bundler'
require 'antlr4-native'

Bundler::GemHelper.install_tasks

task :generate do
  generator = Antlr4Native::Generator.new(
    grammar_files:      ["../python3-parser-rb/Python3.g4"],
    output_dir:         'ext/',
    parser_root_method: 'file_input'
  )

  generator.generate
end
