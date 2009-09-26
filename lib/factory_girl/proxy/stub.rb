module FactoryGirl
  class Proxy
    class Stub < Proxy #:nodoc:
      @@next_id = 1000

      def initialize(klass)
        @stub = klass.new
        @stub.id = next_id
        @stub.instance_eval do
          def new_record?
            id.nil?
          end

          def connection
            raise "stubbed models are not allowed to access the database"
          end

          def reload
            raise "stubbed models are not allowed to access the database"
          end
        end
      end

      def next_id
        @@next_id += 1
      end

      def get(attribute)
        @stub.send(attribute)
      end

      def set(attribute, value)
        @stub.send(:"#{attribute}=", value)
      end

      def associate(name, factory_name, attributes)
        set(name, association(factory_name))
      end

      def association(factory, overrides = {})
        FactoryGirl::Factory.factory_by_name(factory).run(:stub, overrides)
      end

      def result
        @stub
      end
    end
  end
end
