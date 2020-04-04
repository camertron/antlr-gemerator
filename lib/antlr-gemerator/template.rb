require 'erb'

module AntlrGemerator
  class Template
    def initialize(tmpl, bindings)
      @tmpl = tmpl
      @bindings = bindings
    end

    def render
      ERB.new(@tmpl).result(binding)
    end

    def method_missing(mtd, *args, &block)
      if @bindings.include?(mtd)
        @bindings[mtd]
      else
        raise NoMethodError, "no method `#{mtd}' for #{self.class}"
      end
    end

    def respond_to?(mtd)
      return true if @bindings.include?(mtd)
      super
    end
  end
end
