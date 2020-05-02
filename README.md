# antlr-gemerator

Generate a complete Rubygem from any ANTLR grammar.

## What is this thing?

This gem leverages the functionality in [antlr4-native](https://github.com/camertron/antlr4-native) to generate a complete rubygem from an ANTLR grammar. The resulting gem contains a working parser and visitor, and is ready to be published to rubygems.org.

## Background

ANTLR is a wonderful tool for generating parsers, and is capable of parsing just about anything. Parsers (and corresponding lexers) are described via a grammar file, which declaratively defines the rules of the language or format. ANTLR generates parser code in the desired target programming language (Java by default), which can subsequently be used to parse documents that use the syntax defined in the grammar.

For example, let's say you want to parse some [Lua](https://www.lua.org/about.html) code. You'd obtain ANTLR (usually by downloading a .jar file from the ANTLR website), find a grammar for Lua, then run the ANTLR tool like this:

```bash
java -jar /path/to/antlr.jar -o /path/to/output/dir ./Lua.g4
```

ANTLR will emit a bunch of .java files you can include in your Java project to parse Lua source code.

### ANTLR and Ruby

ANTLR can generate parsers in a number of target programming languages, but unfortunately Ruby isn't one of them. A couple of attempts have been made over the years to add a Ruby target to ANTLR, including [this excellent one](https://github.com/MODLanguage/antlr4-ruby-runtime) from [@twalmsley](https://github.com/twalmsley). Unfortunately none of these attempts have been merged into ANTLR proper yet.

The real problem with a Ruby target however is execution speed. The runtime linked above runs \~80% slower than the equivalent Java-based Python parser I'm working on.

### Speeding things up with native extensions

One way to speed things up is to generate a parser in a more performant language and somehow build it as a Ruby native extension or FFI-compatible library. As it happens, ANTLR can target C++... and Ruby extensions can be written in C++! From there it was just a matter of writing some C++ glue code, and voila! ANTLR parsers wrapped in a loving Ruby embrace.

## Usage

antlr-gemerator runs from the command-line. First, install the gem by running:

```bash
gem install antlr-gemerator
```

If you're using rbenv, don't forget to run `rbenv rehash` to make the `antlr-gemerator` executable available in your shell.

Next, change directory to where you'd like to generate your new gem and invoke `antlr-gemerator`:

```bash
antlr-gemerator create \
  --author 'Mickey Mouse' \
  --desc 'A Lua parser for Ruby' \
  --email 'mickey@disney.com' \
  --homepage 'https://github.com/mickeymouse/lua-parser-rb' \
  --grammar path/to/Lua.g4 \
  --root chunk
```

**NOTE**: You can specify the `-g` option more than once, i.e. for each .g4 file. It's common for the parser and lexer in ANTLR grammars to exist in individual files.

**NOTE**: The `--root` option tells antlr-gemerator which context represents the root of the parse tree. This context functions as the starting point for visitors. Look inside your .g4 file (the parser one if there is more than one) and find the first grammar element. For the Lua grammar, this root element is called `chunk`.

You should see a bunch of console output as antlr-gemerator emits all the files necessary for a Lua parser gem. It will also add the ANTLR runtime as a git submodule and build the native extension for you.

### Using your gem

Now that your gem has been generated and built, try it out by parsing some Lua code. Save the following snippet as tester.rb and run it with `bundle exec ruby tester.rb`:

```ruby
require 'lua-parser'

lua_code = <<~END
  -- test for even number
  if n % 2 == 0 then
    print "The number is even"
  end

  -- test for odd number
  if not (n % 2 == 0) then
    print "The number is odd"
  end
END

class MyFuncVisitor < LuaParser::Visitor
  def visit_functioncall(ctx)
    puts ctx.var_or_exp.text
    visit_children(ctx)
  end
end

parser = LuaParser::Parser.parse(lua_code)
parser.visit(MyFuncVisitor.new)
```

You should see the following output:

```
$> bundle exec ruby tester.rb
print
print
```

The `MyFuncVisitor` instance passed to `Parser#visit` prints the name of each function call, then visits the child contexts in the parsed subtree.

## Publishing your gem

To package your gem into a .gem file, run:

```bash
bundle exec rake build
```

The .gem file will be built into the pkg/ directory. Publish it by running:

```bash
gem push pkg/lua-parser-1.0.0.gem
```

You'll need to be signed into rubygems.org before publishing. Take a look at this [handy guide](https://guides.rubygems.org/publishing/) for instructions.

## Maintaining your gem

Each gem created by antlr-gemerator comes with several rake tasks to help make maintenance easier.

1. `build`: builds the gem into a .gem file suitable for publishing to rubygems.org.
2. `compile`: builds the native extension (i.e. compiles all the generated C++ code and the ANTLR runtime).
3. `generate`: regenerates the C++ code by invoking antlr4-native. It's like running `antlr-gemerator` all over again, but _after_ your gem has been created.

For example, to compile the native extension, run:

```bash
bundle exec rake compile
```

## Caveats

See the caveats listed in [antlr4-native's README](https://github.com/camertron/antlr4-native-rb#caveats).

## System Requirements

See the system requirements listed in [antlr4-native's README](https://github.com/camertron/antlr4-native-rb#system-requirements).

## License

Licensed under the MIT license. See LICENSE.txt for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
