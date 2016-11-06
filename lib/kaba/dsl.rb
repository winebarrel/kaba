class Kaba::DSL
  class << self
    def convert(exported, options = {})
      Kaba::DSL::Converter.convert(exported, options)
    end

    def parse(dsl, path, options = {})
      # XXX:
      #Kaba::DSL::Context.eval(dsl, path, options).result
    end
  end # of class methods
end
