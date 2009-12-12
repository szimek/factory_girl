module FactoryGirl
  module Syntax

    # Extends ActiveRecord::Base to provide a make class method, which is an
    # alternate syntax for defining factories.
    #
    # Usage:
    #
    #   require 'factory_girl/syntax/blueprint'
    #
    #   User.blueprint do
    #     name  { 'Billy Bob'             }
    #     email { 'billy@bob.example.com' }
    #   end
    #
    #   Factory(:user, :name => 'Johnny')
    #
    # This syntax was derived from Pete Yandell's machinist.
    module Blueprint
      module ActiveRecord #:nodoc:

        def self.included(base) # :nodoc:
          base.extend ClassMethods
        end

        module ClassMethods #:nodoc:

          def blueprint(&block)
            factory_name = Syntax::Default::Factory.factory_name_for(self)
            proxy = Syntax::Default::DefinitionProxy.new
            proxy.instance_eval(&block)
            instance = Factory.new(self, proxy.attributes)
            Factory.factories[factory_name] = instance
          end

        end

      end
    end
  end
end

ActiveRecord::Base.send(:include, FactoryGirl::Syntax::Blueprint::ActiveRecord)

