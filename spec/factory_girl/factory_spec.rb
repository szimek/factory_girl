require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Factory do
  describe "a factory" do
    before do
      @name    = :user
      @class   = User
      @factory = Factory.new(@name)
    end

    it "should have a factory name" do
      @factory.factory_name.should == @name
    end

    it "should have a build class" do
      @factory.build_class.should == @class
    end

    it "should have a default strategy" do
      @factory.default_strategy.should == :create
    end

    # TODO: use constructor
    it "should not allow the same attribute to be added twice" do
      lambda {
        2.times { @factory.add_attribute :first_name }
      }.should raise_error(Factory::AttributeDefinitionError)
    end

    describe "after adding an attribute" do
      before do
        @attribute = "attribute"
        @proxy     = "proxy"

        stub(@attribute).name { :name }
        stub(@attribute).add_to
        stub(@proxy).set
        stub(@proxy).result { 'result' }
        stub(Factory::Attribute::Static).new { @attribute }
        stub(Factory::Proxy::Build).new { @proxy }

        # TODO: use constructor
        @factory.add_attribute(:name, 'value')
      end

      it "should create the right proxy using the build class when running" do
        mock(Factory::Proxy::Build).new(@factory.build_class) { @proxy }
        @factory.run(Factory::Proxy::Build, {})
      end

      it "should add the attribute to the proxy when running" do
        mock(@attribute).add_to(@proxy)
        @factory.run(Factory::Proxy::Build, {})
      end

      it "should return the result from the proxy when running" do
        mock(@proxy).result() { 'result' }
        @factory.run(Factory::Proxy::Build, {}).should == 'result'
      end
    end

    it "should return associations" do
      factory = Factory.new(:post)
      # TODO: use constructor
      factory.association(:author)
      factory.association(:editor)
      factory.associations.each do |association|
        association.should be_a(Factory::Attribute::Association)
      end
      factory.associations.size.should == 2
    end

    # TODO: use constructor
    describe "when overriding generated attributes with a hash" do
      before do
        @attr  = :name
        @value = 'The price is right!'
        @hash  = { @attr => @value }
      end

      it "should return the overridden value in the generated attributes" do
        @factory.add_attribute(@attr, 'The price is wrong, Bob!')
        result = @factory.run(Factory::Proxy::AttributesFor, @hash)
        result[@attr].should == @value
      end

      it "should not call a lazy attribute block for an overridden attribute" do
        @factory.add_attribute(@attr) { flunk }
        result = @factory.run(Factory::Proxy::AttributesFor, @hash)
      end

      it "should override a symbol parameter with a string parameter" do
        @factory.add_attribute(@attr, 'The price is wrong, Bob!')
        @hash = { @attr.to_s => @value }
        result = @factory.run(Factory::Proxy::AttributesFor, @hash)
        result[@attr].should == @value
      end
    end

    # TODO: use constructor
    describe "overriding an attribute with an alias" do
      before do
        @factory.add_attribute(:test, 'original')
        Factory.alias(/(.*)_alias/, '\1')
        @result = @factory.run(Factory::Proxy::AttributesFor,
                               :test_alias => 'new')
      end

      it "should use the passed in value for the alias" do
        @result[:test_alias].should == 'new'
      end

      it "should discard the predefined value for the attribute" do
        @result[:test].should be_nil
      end
    end

    it "should guess the build class from the factory name" do
      @factory.build_class.should == User
    end

    describe "when defined with a custom class" do
      before do
        @class   = User
        @factory = Factory.new(:author, :class => @class)
      end

      it "should use the specified class as the build class" do
        @factory.build_class.should == @class
      end
    end

    describe "when defined with a class instead of a name" do
      before do
        @class   = ArgumentError
        @name    = :argument_error
        @factory = Factory.new(@class)
      end

      it "should guess the name from the class" do
        @factory.factory_name.should == @name
      end

      it "should use the class as the build class" do
        @factory.build_class.should == @class
      end
    end

    describe "when defined with a custom class name" do
      before do
        @class   = ArgumentError
        @factory = Factory.new(:author, :class => :argument_error)
      end

      it "should use the specified class as the build class" do
        @factory.build_class.should == @class
      end
    end
  end

  describe "a factory with a name ending in s" do
    before do
      @name    = :business
      @class   = Business
      @factory = Factory.new(@name)
    end

    it "should have a factory name" do
      @factory.factory_name.should == @name
    end

    it "should have a build class" do
      @factory.build_class.should == @class
    end
  end

  describe "a factory with a string for a name" do
    before do
      @name    = :user
      @factory = Factory.new(@name.to_s) {}
    end

    it "should convert the string to a symbol" do
      @factory.factory_name.should == @name
    end
  end

  describe "a factory defined with a string name" do
    before do
      Factory.factories = {}
      @name    = :user
      @factory = Factory.define(@name.to_s) {}
    end

    it "should store the factory using a symbol" do
      Factory.factories[@name].should == @factory
    end
  end

  # TODO: move into constructor
  describe 'defining a factory with a parent parameter' do
    before do
      @parent = Factory.define :object do |f|
        f.name  'Name'
      end
    end

    it "should raise an ArgumentError when trying to use a non-existent factory as parent" do
      lambda {
        Factory.define(:child, :parent => :nonexsitent) {}
      }.should raise_error(ArgumentError)
    end

    it "should create a new factory using the class of the parent" do
      child = Factory.define(:child, :parent => :object) {}
      child.build_class.should == @parent.build_class
    end

    it "should create a new factory while overriding the parent class" do
      class Other; end

      child = Factory.define(:child, :parent => :object, :class => Other) {}
      child.build_class.should == Other
    end

    it "should create a new factory with attributes of the parent" do
      child = Factory.define(:child, :parent => :object) {}
      child.attributes.size.should == 1
      child.attributes.first.name.should == :name
    end

    it "should allow to define additional attributes" do
      child = Factory.define(:child, :parent => :object) do |f|
        f.email 'person@somebody.com'
      end
      child.attributes.size.should == 2
    end

    it "should allow to override parent attributes" do
      child = Factory.define(:child, :parent => :object) do |f|
        f.name { 'Child Name' }
      end
      child.attributes.size.should == 1
      child.attributes.first.should be_kind_of(Factory::Attribute::Dynamic)
    end
  end

  # TODO: move into constructor
  describe 'defining a factory with a default strategy parameter' do
    it "should raise an ArgumentError when trying to use a non-existent factory" do
      lambda {
        Factory.define(:object, :default_strategy => :nonexistent) {}
      }.should raise_error(ArgumentError)
    end

    it "should create a new factory with a specified default strategy" do
      factory = Factory.define(:object, :default_strategy => :stub) {}
      factory.default_strategy.should == :stub
    end
  end

  it "should return the factory name without underscores for the human name" do
    factory = Factory.new(:name_with_underscores)
    factory.human_name.should == 'name with underscores'
  end

end
