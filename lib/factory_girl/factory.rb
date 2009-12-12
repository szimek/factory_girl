module FactoryGirl

  class Factory

    class << self
      attr_accessor :factories #:nodoc:

      # An Array of strings specifying locations that should be searched for
      # factory definitions. By default, factory_girl will attempt to require
      # "factories," "test/factories," and "spec/factories." Only the first
      # existing file will be loaded.
      attr_accessor :definition_file_paths
    end

    self.factories = {}
    self.definition_file_paths = %w(factories test/factories spec/factories)

    attr_reader :attributes #:nodoc:
    attr_reader :build_class #:nodoc:

    def default_strategy #:nodoc:
      @options[:default_strategy] || :create
    end

    def initialize(build_class, attributes, options = {}) #:nodoc:
      assert_valid_options(options)
      @options      = options
      @attributes   = attributes
      @build_class  = build_class
      if parent = options.delete(:parent)
        inherit_from(self.class.factory_by_name(parent))
      end

      attribute_names = attributes.reject { |attribute| attribute.is_a?(Attribute::Callback) }.collect {|attribute| attribute.name }
      unless attribute_names == attribute_names.uniq
        raise AttributeDefinitionError, "Attributes defined twice"
      end
    end

    def inherit_from(parent) #:nodoc:
      parent.attributes.each do |attribute|
        unless attribute_defined?(attribute.name)
          @attributes << attribute.clone
        end
      end
    end

    def run(strategy, overrides) #:nodoc:
      proxy_class = Proxy.const_get(variable_name_to_class_name(strategy))
      proxy = proxy_class.new(build_class)
      overrides = symbolize_keys(overrides)
      overrides.each {|attr, val| proxy.set(attr, val) }
      passed_keys = overrides.keys.collect {|k| Alias.aliases_for(k) }.flatten
      @attributes.each do |attribute|
        unless passed_keys.include?(attribute.name)
          attribute.add_to(proxy)
        end
      end
      proxy.result
    end

    def self.factory_by_name(name)
      factories[name.to_sym] or raise ArgumentError.new("No such factory: #{name.to_s}")
    end

    def associations
      attributes.select {|attribute| attribute.is_a?(Attribute::Association) }
    end

    def ensure_not_associated_with(factory)
      if associations.any? { |association| association.factory == factory }
        raise FactoryGirl::AssociationDefinitionError,
              "can't associate with #{factory}"
      end
    end

    private

    def custom_class?
      @options.key?(:class)
    end

    def attribute_defined?(name)
      !@attributes.detect {|attr| attr.name == name && ! attr.is_a?(Attribute::Callback) }.nil?
    end

    def assert_valid_options(options)
      invalid_keys = options.keys - [:class, :parent, :default_strategy]
      unless invalid_keys == []
        raise ArgumentError, "Unknown arguments: #{invalid_keys.inspect}"
      end
      assert_valid_strategy(options[:default_strategy]) if options[:default_strategy]
    end

    def assert_valid_strategy(strategy)
      unless Proxy.const_defined? variable_name_to_class_name(strategy)
        raise ArgumentError, "Unknown strategy: #{strategy}"
      end
    end

    # Based on ActiveSupport's underscore inflector
    # TODO: move this into an inflector module
    def class_name_to_variable_name(name)
      name.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    # Based on ActiveSupport's camelize inflector
    # TODO: move this into an inflector module
    def variable_name_to_class_name(name)
      name.to_s.
        gsub(/\/(.?)/) { "::#{$1.upcase}" }.
        gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    # From ActiveSupport
    def symbolize_keys(hash)
      hash.inject({}) do |options, (key, value)|
        options[(key.to_sym rescue key) || key] = value
        options
      end
    end

  end
end
