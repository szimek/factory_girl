require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Factory do
  it "should return associations" do
    factory = Factory.new(:post, [Attribute::Association.new(:author, :object, {}),
                                  Attribute::Association.new(:editor, :object, {})])
    factory.associations.each do |association|
      association.should be_a(Attribute::Association)
    end
    factory.associations.size.should == 2
  end

  it "should have a factory name" do
    Factory.new(:user, []).factory_name.should == :user
  end

  it "should have a default strategy" do
    Factory.new(:user, []).default_strategy.should == :create
  end

  it "should guess the build class from the factory name" do
    Factory.new(:user, []).build_class.should == User
  end

  it "should return a custom class as the build class" do
    klass   = User
    factory = Factory.new(:author, [], :class => klass)
    factory.build_class.should == klass
  end

  it "should guess the name from a class" do
    klass   = ArgumentError
    name    = :argument_error
    factory = Factory.new(klass, [])
    factory.factory_name.should == name
    factory.build_class.should == klass
  end

  it "accept a custom class name" do
    klass   = ArgumentError
    factory = Factory.new(:author, [], :class => :argument_error)
    factory.build_class.should == klass
  end

  it "should not allow two attributes with the same name" do
    lambda {
      Factory.new(:post, [Attribute::Static.new(:first_name, 'value'),
                          Attribute::Static.new(:first_name, 'other')])
    }.should raise_error(AttributeDefinitionError)
  end

  it "should replace a predefined attribute value when overridden with an alias" do
    factory = Factory.new(:post, [Attribute::Static.new(:test, 'original')])
    Factory.alias(/(.*)_alias/, '\1')
    result = factory.run(Proxy::AttributesFor, :test_alias => 'new')
    result[:test_alias].should == 'new'
    result[:test].should be_nil
  end

  it "should return an overridden value in the generated attributes" do
    factory = Factory.new(:post, [Attribute::Static.new(:name, 'The price is wrong')])
    result = factory.run(Proxy::AttributesFor, { :name => 'expected' })
    result[:name].should == 'expected'
  end

  it "should not call a lazy attribute block for an overridden attribute" do
    factory = Factory.new(:post, [Attribute::Dynamic.new(:name, lambda { flunk })])
    result = factory.run(Proxy::AttributesFor, { :name => 'expected' })
  end

  it "should override a symbol parameter with a string parameter" do
    factory = Factory.new(:post, [Attribute::Static.new(:name, 'The price is wrong')])
    result = factory.run(Proxy::AttributesFor, { 'name' => 'expected' })
    result[:name].should == 'expected'
  end

  describe 'defining a factory with a parent parameter' do
    before do
      @parent = Factory.new(:object, [Attribute::Static.new(:name, 'Name')])
      Factory.factories[:object] = @parent
    end

    it "should raise an ArgumentError when trying to use a non-existent factory as parent" do
      lambda {
        Factory.new(:child, [], :parent => :nonexsitent)
      }.should raise_error(ArgumentError)
    end

    it "should create a new factory using the class of the parent" do
      child = Factory.new(:child, [], :parent => :object)
      child.build_class.should == @parent.build_class
    end

    it "should create a new factory while overriding the parent class" do
      class Other; end

      child = Factory.new(:child, [], :parent => :object, :class => Other)
      child.build_class.should == Other
    end

    it "should create a new factory with attributes of the parent" do
      child = Factory.new(:child, [], :parent => :object)
      child.attributes.size.should == 1
      child.attributes.first.name.should == :name
    end

    it "should allow to define additional attributes" do
      child = Factory.new(:child,
                          [Attribute::Static.new(:email, 'person@somebody.com')],
                          :parent => :object)
      child.attributes.size.should == 2
    end

    it "should allow to override parent attributes" do
      child = Factory.new(:child,
                          [Attribute::Dynamic.new(:name, lambda { 'Child Name' })],
                          :parent => :object)
      child.attributes.size.should == 1
      child.attributes.first.should be_kind_of(Attribute::Dynamic)
    end
  end

  describe 'defining a factory with a default strategy parameter' do
    it "should raise an ArgumentError when trying to use a non-existent factory" do
      lambda {
        Factory.new(:object, [], :default_strategy => :nonexistent)
      }.should raise_error(ArgumentError)
    end

    it "should create a new factory with a specified default strategy" do
      factory = Factory.new(:object, [], :default_strategy => :stub)
      factory.default_strategy.should == :stub
    end
  end

  it "should return the factory name without underscores for the human name" do
    factory = Factory.new(:name_with_underscores, [])
    factory.human_name.should == 'name with underscores'
  end

  it "should raise for a self referencing association" do
    pending
    lambda {
      subject.association(:parent, :factory => subject.factory_name)
    }.should raise_error(Factory::AssociationDefinitionError)
  end

end

describe Factory, "with a registered instance" do
  before do
    @factory = Factory.new(:object, [])
    @name = :post
    Factory.factories[@name] = @factory
  end

  after do
    Factory.factories.clear
  end

  it "should allow that factory to be found by name" do
    Factory.factory_by_name(@name).should == @factory
  end
end

describe Factory, "with an attribute" do
  before do
    @attribute = "attribute"
    @proxy     = "proxy"

    stub(@attribute).name { :name }
    stub(@attribute).add_to
    stub(@proxy).set
    stub(@proxy).result { 'result' }
    stub(Attribute::Static).new { @attribute }
    stub(Proxy::Build).new { @proxy }

    @factory = Factory.new(:post, [Attribute::Static.new(:name, 'value')])
  end

  it "should create the right proxy using the build class when running" do
    mock(Proxy::Build).new(@factory.build_class) { @proxy }
    @factory.run(Proxy::Build, {})
  end

  it "should add the attribute to the proxy when running" do
    mock(@attribute).add_to(@proxy)
    @factory.run(Proxy::Build, {})
  end

  it "should return the result from the proxy when running" do
    mock(@proxy).result() { 'result' }
    @factory.run(Proxy::Build, {}).should == 'result'
  end
end

describe Factory, "with a name ending in s" do
  before do
    @name    = :business
    @class   = Business
    @factory = Factory.new(@name, [])
  end

  it "should have a factory name" do
    @factory.factory_name.should == @name
  end

  it "should have a build class" do
    @factory.build_class.should == @class
  end
end

describe Factory, "with a string for a name" do
  before do
    @name    = :user
    @factory = Factory.new(@name.to_s, [])
  end

  it "should convert the string to a symbol" do
    @factory.factory_name.should == @name
  end
end

describe Factory, "defined with a string name" do
  before do
    Factory.factories = {}
    @name    = :user
    @factory = Factory.new(@name.to_s, [])
  end

  it "should store the factory using a symbol" do
    pending
    @factory.factories[@name].should == @factory
  end
end

