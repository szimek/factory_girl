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

    attr_reader :factory_name #:nodoc:
    attr_reader :attributes #:nodoc:

    def class_name #:nodoc:
      @options[:class] || factory_name
    end

    def build_class #:nodoc:
      @build_class ||= class_for(class_name)
    end

    def default_strategy #:nodoc:
      @options[:default_strategy] || :create
    end

    def initialize(name, attributes, options = {}) #:nodoc:
      assert_valid_options(options)
      @factory_name = factory_name_for(name)
      @options      = options
      @attributes   = attributes
      if parent = options.delete(:parent)
        inherit_from(self.class.factory_by_name(parent))
      end

      attribute_names = attributes.collect {|attribute| attribute.name }
      unless attribute_names == attribute_names.uniq
        raise AttributeDefinitionError, "Attributes defined twice"
      end
    end

    def inherit_from(parent) #:nodoc:
      @options[:class] ||= parent.class_name
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

    def human_name(*args, &block)
      if args.size == 0 && block.nil?
        factory_name.to_s.gsub('_', ' ')
      else
        add_attribute(:human_name, *args, &block)
      end
    end

    def associations
      attributes.select {|attribute| attribute.is_a?(Attribute::Association) }
    end

    private

    def class_for(class_or_to_s)
      if class_or_to_s.respond_to?(:to_sym)
        Object.const_get(variable_name_to_class_name(class_or_to_s))
      else
        class_or_to_s
      end
    end

    def factory_name_for(class_or_to_s)
      if class_or_to_s.respond_to?(:to_sym)
        class_or_to_s.to_sym
      else
        class_name_to_variable_name(class_or_to_s).to_sym
      end
    end

    def attribute_defined?(name)
      !@attributes.detect {|attr| attr.name == name }.nil?
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
    def class_name_to_variable_name(name)
      name.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    # Based on ActiveSupport's camelize inflector
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
