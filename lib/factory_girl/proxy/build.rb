module FactoryGirl
  class Proxy #:nodoc:
    class Build < Proxy #:nodoc:
      def initialize(klass)
        @instance = klass.new
      end

      def get(attribute)
        @instance.send(attribute)
      end

      def set(attribute, value)
        @instance.send(:"#{attribute}=", value)
      end

      def associate(name, factory_name, overrides)
        set(name, association(factory_name, overrides))
      end

      def association(factory_name, overrides = {})
        FactoryGirl::Factory.factory_by_name(factory_name).run(:create, overrides)
      end

      def result
        @instance
      end
    end
  end
end
