require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe FactoryGirl::Proxy::Build do
  before do
    @class       = Class.new
    @instance    = "built-instance"
    @association = "associated-instance"

    stub(@class).new { @instance }
    stub(@instance).attribute { 'value' }
    @user_factory = 'a factory'
    stub(@user_factory).run { @association }
    stub(@instance, :attribute=)
    stub(@instance, :owner=)

    @proxy = FactoryGirl::Proxy::Build.new(@class)
    stub(FactoryGirl::Factory).factory_by_name(:user) { @user_factory }
  end

  it "should instantiate the class" do
    @class.should have_received.new
  end

  describe "when asked to associate with another factory" do
    before do
      @proxy.associate(:owner, :user, {})
    end

    it "should create the associated instance" do
      @user_factory.should have_received.run(:create, {})
    end

    it "should set the associated instance" do
      @instance.should have_received.method_missing(:owner=, @association)
    end
  end

  it "should call Factory.create when building an association" do
    association = 'association'
    attribs     = { :first_name => 'Billy' }
    factory     = 'a factory'
    stub(factory).run { association }
    stub(FactoryGirl::Factory).factory_by_name(:user) { factory }
    @proxy.association(:user, attribs).should == association
    factory.should have_received.run(:create, attribs)
  end

  it "should return the built instance when asked for the result" do
    @proxy.result.should == @instance
  end

  it "should run the :after_build callback when retrieving the result" do
    spy = Object.new
    stub(spy).foo
    @proxy.add_callback(:after_build, proc{ spy.foo })
    @proxy.result
    spy.should have_received.foo
  end

  describe "when setting an attribute" do
    before do
      stub(@instance).attribute = 'value'
      @proxy.set(:attribute, 'value')
    end

    it "should set that value" do
      @instance.should have_received.method_missing(:attribute=, 'value')
    end
  end

  describe "when getting an attribute" do
    before do
      @result = @proxy.get(:attribute)
    end

    it "should ask the built class for the value" do
      @instance.should have_received.attribute
    end

    it "should return the value for that attribute" do
      @result.should == 'value'
    end
  end
end

