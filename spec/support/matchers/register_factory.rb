module Matchers
  class RegisterFactory

    attr_reader :failure_message

    def initialize(name, build_class, attributes)
      @name = name
      @build_class = build_class
      @attributes = attributes
    end

    def matches?(block)
      block.call
      @registered = FactoryGirl::Factory.factories.keys
      @factory = FactoryGirl::Factory.factories[@name]
      match_name! &&
        match_build_class! &&
        match_attributes!
    end

    private

    def match_name!
      if @factory.nil?
        @failure_message = "Expected to define a factory named #{@name}, but defined factories: " +
                           @registered.inspect
        false
      else
        true
      end
    end

    def match_build_class!
      return true unless @build_class
      if @build_class == @factory.build_class
        true
      else
        @failure_message = "Expected build class #{@build_class.inspect}, got #{@factory.build_class.inspect}"
        false
      end
    end

    def match_attributes!
      return true unless @attributes
      if @attributes == @factory.attributes
        true
      else
        @failure_message = "Expected attributes #{@attributes}, got #{@factory.attributes}"
        false
      end
    end
  end

  def register_factory(opts = {})
    RegisterFactory.new(opts.delete(:name),
                        opts.delete(:build_class),
                        opts.delete(:attributes))
  end
end
