require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe FactoryGirl::Factory do
  it "should return associations" do
    attributes = [FactoryGirl::Attribute::Association.new(:author, :object, {}),
                  FactoryGirl::Attribute::Association.new(:editor, :object, {})]
    factory = generate_factory(:attributes => attributes)
    factory.associations.each do |association|
      association.should be_a(FactoryGirl::Attribute::Association)
    end
    factory.associations.size.should == 2
  end

  it "should not allow the same attribute to be added twice" do
    attributes = [generate_attribute(:name => 'name'),
                  generate_attribute(:name => 'name')]
    lambda {
      generate_factory(:attributes => attributes)
    }.should raise_error(FactoryGirl::AttributeDefinitionError)
  end

  it "should have a default strategy" do
    generate_factory.default_strategy.should == :create
  end

  it "should have a build class" do
    generate_factory(:build_class => User).build_class.should == User
  end

  it "should not allow two attributes with the same name" do
    lambda {
      generate_factory(:attributes => [generate_attribute(:name => :first_name),
                                       generate_attribute(:name => :first_name)])
    }.should raise_error(FactoryGirl::AttributeDefinitionError)
  end

  it "should replace a predefined attribute value when overridden with an alias" do
    factory =
      generate_factory(:attributes => [FactoryGirl::Attribute::Static.new(:test, 'original')])
    FactoryGirl::Alias.alias(/(.*)_alias/, '\1')
    result = factory.run(:attributes_for, :test_alias => 'new')
    result[:test_alias].should == 'new'
    result[:test].should be_nil
  end

  it "should return an overridden value in the generated attributes" do
    attributes = [FactoryGirl::Attribute::Static.new(:name, 'The price is wrong')]
    factory = generate_factory(:attributes => attributes)
    result = factory.run(:attributes_for, { :name => 'expected' })
    result[:name].should == 'expected'
  end

  it "should not call a lazy attribute block for an overridden attribute" do
    attributes = [FactoryGirl::Attribute::Dynamic.new(:name, lambda { flunk })]
    factory = generate_factory(:attributes => attributes)
    result = factory.run(:attributes_for, { :name => 'expected' })
  end

  it "should override a symbol parameter with a string parameter" do
    attributes = [FactoryGirl::Attribute::Static.new(:name, 'The price is wrong')]
    factory = generate_factory(:attributes => attributes)
    result = factory.run(:attributes_for, { 'name' => 'expected' })
    result[:name].should == 'expected'
  end

  describe 'defining a factory with a parent parameter' do
    before do
      @parent =
        generate_factory(:build_class => Object,
                         :attributes  => [FactoryGirl::Attribute::Static.new(:name, 'Name')])
      FactoryGirl::Factory.factories[:object] = @parent
    end

    after { Factory.factories.clear }

    it "should raise an ArgumentError when trying to use a non-existent factory as parent" do
      lambda {
        generate_factory(:parent => :nonexistent)
      }.should raise_error(ArgumentError)
    end

    it "should create a new factory with attributes of the parent" do
      child = generate_factory(:parent => :object)
      child.attributes.size.should == 1
      child.attributes.first.name.should == :name
    end

    it "should allow to define additional attributes" do
      child =
        generate_factory(:attributes => [generate_attribute(:name => :other)], :parent => :object)
      child.attributes.size.should == 2
    end

    it "should allow to override parent attributes" do
      new_attribute = FactoryGirl::Attribute::Dynamic.new(:name, lambda { 'Child Name' })
      child = generate_factory(:attributes => [new_attribute], :parent => :object)
      child.attributes.should == [new_attribute]
    end

    it "inherit all callbacks" do
      parent_callback = generate_callback
      child_callback = generate_callback
      parent = generate_factory(:attributes => [parent_callback])
      FactoryGirl::Factory.factories[:parent] = parent
      child = generate_factory(:parent => :parent, :attributes => [child_callback])

      child.attributes.size.should == 2
    end
  end

  describe 'defining a factory with a default strategy parameter' do
    it "should raise an ArgumentError when trying to use a non-existent factory" do
      lambda { generate_factory(:default_strategy => :nonexistent) }.
        should raise_error(ArgumentError)
    end

    it "should create a new factory with a specified default strategy" do
      generate_factory(:default_strategy => :stub).default_strategy.should == :stub
    end
  end

  it "should raise an error when associated with the given factory" do
    association = FactoryGirl::Attribute::Association.new(:post, :post, {})
    factory = generate_factory(:attributes => [association])
    lambda { factory.ensure_not_associated_with(:post) }.
      should raise_error(FactoryGirl::AssociationDefinitionError)
  end

  it "should not raise an error when not associated with the given factory" do
    association = FactoryGirl::Attribute::Association.new(:post, :user, {})
    factory = generate_factory(:attributes => [association])
    lambda { factory.ensure_not_associated_with(:post) }.
      should_not raise_error
  end
end

describe FactoryGirl::Factory, "with a registered instance" do
  before do
    @factory = generate_factory
    @name = :post
    FactoryGirl::Factory.factories[@name] = @factory
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

    @factory = generate_factory(:attributes => [generate_attribute])
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

