require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe FactoryGirl::Factory do
  it "should return associations" do
    attributes = [FactoryGirl::Attribute::Association.new(:author, :object, {}),
                  FactoryGirl::Attribute::Association.new(:editor, :object, {})]
    factory = FactoryGirl::Factory.new(:post, attributes)
    factory.associations.each do |association|
      association.should be_a(FactoryGirl::Attribute::Association)
    end
    factory.associations.size.should == 2
  end

  it "should have a factory name" do
    FactoryGirl::Factory.new(:user, []).factory_name.should == :user
  end

  it "should have a default strategy" do
    FactoryGirl::Factory.new(:user, []).default_strategy.should == :create
  end

  it "should guess the build class from the factory name" do
    FactoryGirl::Factory.new(:user, []).build_class.should == User
  end

  it "should return a custom class as the build class" do
    klass   = User
    factory = FactoryGirl::Factory.new(:author, [], :class => klass)
    factory.build_class.should == klass
  end

  it "should guess the name from a class" do
    klass   = ArgumentError
    name    = :argument_error
    factory = FactoryGirl::Factory.new(klass, [])
    factory.factory_name.should == name
    factory.build_class.should == klass
  end

  it "accept a custom class name" do
    klass   = ArgumentError
    factory = FactoryGirl::Factory.new(:author, [], :class => :argument_error)
    factory.build_class.should == klass
  end

  it "should not allow two attributes with the same name" do
    lambda {
      FactoryGirl::Factory.new(:post, [FactoryGirl::Attribute::Static.new(:first_name, 'value'),
                                       FactoryGirl::Attribute::Static.new(:first_name, 'other')])
    }.should raise_error(FactoryGirl::AttributeDefinitionError)
  end

  it "should replace a predefined attribute value when overridden with an alias" do
    factory = FactoryGirl::Factory.new(:post,
                                       [FactoryGirl::Attribute::Static.new(:test, 'original')])
    FactoryGirl::Alias.alias(/(.*)_alias/, '\1')
    result = factory.run(:attributes_for, :test_alias => 'new')
    result[:test_alias].should == 'new'
    result[:test].should be_nil
  end

  it "should return an overridden value in the generated attributes" do
    attributes = [FactoryGirl::Attribute::Static.new(:name, 'The price is wrong')]
    factory = FactoryGirl::Factory.new(:post, attributes)
    result = factory.run(:attributes_for, { :name => 'expected' })
    result[:name].should == 'expected'
  end

  it "should not call a lazy attribute block for an overridden attribute" do
    attributes = [FactoryGirl::Attribute::Dynamic.new(:name, lambda { flunk })]
    factory = FactoryGirl::Factory.new(:post, attributes)
    result = factory.run(:attributes_for, { :name => 'expected' })
  end

  it "should override a symbol parameter with a string parameter" do
    attributes = [FactoryGirl::Attribute::Static.new(:name, 'The price is wrong')]
    factory = FactoryGirl::Factory.new(:post, attributes)
    result = factory.run(:attributes_for, { 'name' => 'expected' })
    result[:name].should == 'expected'
  end

  describe 'defining a factory with a parent parameter' do
    before do
      @parent = FactoryGirl::Factory.new(:object,
                                         [FactoryGirl::Attribute::Static.new(:name, 'Name')])
      FactoryGirl::Factory.factories[:object] = @parent
    end

    it "should raise an ArgumentError when trying to use a non-existent factory as parent" do
      lambda {
        FactoryGirl::Factory.new(:child, [], :parent => :nonexsitent)
      }.should raise_error(ArgumentError)
    end

    it "should create a new factory using the class of the parent" do
      child = FactoryGirl::Factory.new(:child, [], :parent => :object)
      child.build_class.should == @parent.build_class
    end

    it "should create a new factory while overriding the parent class" do
      class Other; end

      child = FactoryGirl::Factory.new(:child, [], :parent => :object, :class => Other)
      child.build_class.should == Other
    end

    it "should create a new factory with attributes of the parent" do
      child = FactoryGirl::Factory.new(:child, [], :parent => :object)
      child.attributes.size.should == 1
      child.attributes.first.name.should == :name
    end

    it "should allow to define additional attributes" do
      child = FactoryGirl::Factory.new(:child,
                          [FactoryGirl::Attribute::Static.new(:email, 'person@somebody.com')],
                          :parent => :object)
      child.attributes.size.should == 2
    end

    it "should allow to override parent attributes" do
      child = FactoryGirl::Factory.new(:child,
                          [FactoryGirl::Attribute::Dynamic.new(:name, lambda { 'Child Name' })],
                          :parent => :object)
      child.attributes.size.should == 1
      child.attributes.first.should be_kind_of(FactoryGirl::Attribute::Dynamic)
    end
  end

  describe 'defining a factory with a default strategy parameter' do
    it "should raise an ArgumentError when trying to use a non-existent factory" do
      lambda {
        FactoryGirl::Factory.new(:object, [], :default_strategy => :nonexistent)
      }.should raise_error(ArgumentError)
    end

    it "should create a new factory with a specified default strategy" do
      factory = FactoryGirl::Factory.new(:object, [], :default_strategy => :stub)
      factory.default_strategy.should == :stub
    end
  end

  it "should return the factory name without underscores for the human name" do
    factory = FactoryGirl::Factory.new(:name_with_underscores, [])
    factory.human_name.should == 'name with underscores'
  end

  it "should raise for a self referencing association" do
    pending
    lambda {
      subject.association(:parent, :factory => subject.factory_name)
    }.should raise_error(FactoryGirl::AssociationDefinitionError)
  end

end

describe FactoryGirl::Factory, "with a registered instance" do
  before do
    @factory = FactoryGirl::Factory.new(:object, [])
    @name = :post
    FactoryGirl::Factory.factories[@name] = @factory
  end

  after do
    FactoryGirl::Factory.factories.clear
  end

  it "should allow that factory to be found by name" do
    FactoryGirl::Factory.factory_by_name(@name).should == @factory
  end
end

describe FactoryGirl::Factory, "with an attribute" do
  before do
    @attribute = "attribute"
    @proxy     = "proxy"

    stub(@attribute).name { :name }
    stub(@attribute).add_to
    stub(@proxy).set
    stub(@proxy).result { 'result' }
    stub(FactoryGirl::Attribute::Static).new { @attribute }
    stub(FactoryGirl::Proxy::Build).new { @proxy }

    @factory = FactoryGirl::Factory.new(:post, [FactoryGirl::Attribute::Static.new(:name, 'value')])
  end

  it "should create the right proxy using the build class when running" do
    mock(FactoryGirl::Proxy::Build).new(@factory.build_class) { @proxy }
    @factory.run(:build, {})
  end

  it "should add the attribute to the proxy when running" do
    mock(@attribute).add_to(@proxy)
    @factory.run(:build, {})
  end

  it "should return the result from the proxy when running" do
    mock(@proxy).result() { 'result' }
    @factory.run(:build, {}).should == 'result'
  end
end

describe FactoryGirl::Factory, "with a name ending in s" do
  before do
    @name    = :business
    @class   = Business
    @factory = FactoryGirl::Factory.new(@name, [])
  end

  it "should have a factory name" do
    @factory.factory_name.should == @name
  end

  it "should have a build class" do
    @factory.build_class.should == @class
  end
end

describe FactoryGirl::Factory, "with a string for a name" do
  before do
    @name    = :user
    @factory = FactoryGirl::Factory.new(@name.to_s, [])
  end

  it "should convert the string to a symbol" do
    @factory.factory_name.should == @name
  end
end

describe FactoryGirl::Factory, "defined with a string name" do
  before do
    FactoryGirl::Factory.factories = {}
    @name    = :user
    @factory = FactoryGirl::Factory.new(@name.to_s, [])
  end

  it "should store the factory using a symbol" do
    pending
    @factory.factories[@name].should == @factory
  end
end

