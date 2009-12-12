require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "defining a factory" do
  before do
    @factory = generate_factory
  end

  it "should create a new factory using the specified name and options" do
    attribute = generate_attribute
    stub(FactoryGirl::Attribute::Static).new { attribute }
    lambda {
      Factory.define(:user, :class => :post) {|f| f.name 'value' }
    }.should register_factory(:name        => :user,
                              :build_class => Post,
                              :attributes  => [attribute])
  end

  it "should pass a definition proxy to the block" do
    yielded = nil
    Factory.define(:user) do |y|
      yielded = y
    end
    yielded.should be_a(FactoryGirl::Syntax::Default::DefinitionProxy)
  end

  it "should add the factory to the list of factories" do
    factory = Factory.define(:user) {|f| }
    FactoryGirl::Factory.factories[:user].should == factory
  end

  it "should allow that factory to be found by name" do
    factory = Factory.define(:user) {|f| }
    FactoryGirl::Factory.factory_by_name(:user).should == factory
  end

  it "should allow that factory to be found by name when defined with a class" do
    factory = Factory.define(User) {|f| }
    FactoryGirl::Factory.factory_by_name(:user).should == factory
  end

  it "should not allow a duplicate factory definition" do
    lambda { 
      2.times { Factory.define(:user) {|f| } }
    }.should raise_error(FactoryGirl::DuplicateDefinitionError)
  end
end

describe FactoryGirl::Syntax::Default::DefinitionProxy do
  before do
    @proxy = FactoryGirl::Syntax::Default::DefinitionProxy.new
  end

  subject { @proxy }

  it "should add a static attribute when an attribute is defined with a value" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    mock(FactoryGirl::Attribute::Static).new(:name, 'value') { attribute }
    subject.add_attribute(:name, 'value')
    subject.attributes.should include(attribute)
  end

  it "should add a dynamic attribute when an attribute is defined with a block" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    block     = lambda {}
    mock(FactoryGirl::Attribute::Dynamic).new(:name, block) { attribute }
    subject.add_attribute(:name, &block)
    subject.attributes.should include(attribute)
  end

  it "should raise for an attribute with a value and a block" do
    lambda {
      subject.add_attribute(:name, 'value') {}
    }.should raise_error(FactoryGirl::AttributeDefinitionError)
  end

  describe "adding an attribute using a in-line sequence" do
    it "should create the sequence" do
      mock(FactoryGirl::Sequence).new
      subject.sequence(:name) {}
    end

    it "should add a dynamic attribute" do
      attribute = 'attribute'
      stub(attribute).name { :name }
      mock(FactoryGirl::Attribute::Dynamic).new(:name, is_a(Proc)) { attribute }
      subject.sequence(:name) {}
      subject.attributes.should include(attribute)
    end
  end

  it "should add an association without a factory name or overrides" do
    name    = :user
    attr    = 'attribute'
    mock(FactoryGirl::Attribute::Association).new(name, name, {}) { attr }
    subject.association(name)
    subject.attributes.should include(attr)
  end

  it "should add an association with overrides" do
    name      = :user
    attr      = 'attribute'
    overrides = { :first_name => 'Ben' }
    mock(FactoryGirl::Attribute::Association).new(name, name, overrides) { attr }
    subject.association(name, overrides)
    subject.attributes.should include(attr)
  end

  it "should add an association with a factory name" do
    attr = 'attribute'
    mock(FactoryGirl::Attribute::Association).new(:author, :user, {}) { attr }
    subject.association(:author, :factory => :user)
    subject.attributes.should include(attr)
  end

  it "should add an association with a factory name and overrides" do
    attr = 'attribute'
    mock(FactoryGirl::Attribute::Association).new(:author, :user, :first_name => 'Ben') { attr }
    subject.association(:author, :factory => :user, :first_name => 'Ben')
    subject.attributes.should include(attr)
  end

  it "should add an attribute using the method name when passed an undefined method" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    block = lambda {}
    mock(FactoryGirl::Attribute::Static).new(:name, 'value') { attribute }
    subject.send(:name, 'value')
    subject.attributes.should include(attribute)
  end

  it "should allow human_name as a static attribute name" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    mock(FactoryGirl::Attribute::Static).new(:human_name, 'value') { attribute}
    subject.human_name 'value'
  end

  it "should allow human_name as a dynamic attribute name" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    block     = lambda {}
    mock(FactoryGirl::Attribute::Dynamic).new(:human_name, block) { attribute }
    subject.human_name(&block)
  end

  it "should add a callback attribute when the after_build attribute is defined" do
    mock(FactoryGirl::Attribute::Callback).new(:after_build, is_a(Proc)) { 'after_build callback' }
    subject.after_build {}
    subject.attributes.should include('after_build callback')
  end

  it "should add a callback attribute when the after_create attribute is defined" do
    mock(FactoryGirl::Attribute::Callback).new(:after_create, is_a(Proc)) { 'after_create callback' }
    subject.after_create {}
    subject.attributes.should include('after_create callback')
  end

  it "should add a callback attribute when the after_stub attribute is defined" do
    mock(FactoryGirl::Attribute::Callback).new(:after_stub, is_a(Proc)) { 'after_stub callback' }
    subject.after_stub {}
    subject.attributes.should include('after_stub callback')
  end

  it "should add a callback attribute when defining a callback" do
    mock(FactoryGirl::Attribute::Callback).new(:after_create, is_a(Proc)) { 'after_create callback' }
    subject.callback(:after_create) {}
    subject.attributes.should include('after_create callback')
  end

  it "should raise an InvalidCallbackNameError when defining a callback with an invalid name" do
    lambda{
      subject.callback(:invalid_callback_name) {}
    }.should raise_error(FactoryGirl::InvalidCallbackNameError)
  end

end

describe "after defining a factory" do
  before do
    @name    = :user
    @factory = "factory"

    FactoryGirl::Factory.factories[@name] = @factory
  end

  it "should use attributes_for for Factory.attributes_for" do
    mock(@factory).run(:attributes_for, :attr => 'value') { 'result' }
    Factory.attributes_for(@name, :attr => 'value').should == 'result'
  end

  it "should use build for Factory.build" do
    mock(@factory).run(:build, :attr => 'value') { 'result' }
    Factory.build(@name, :attr => 'value').should == 'result'
  end

  it "should use create for Factory.create" do
    mock(@factory).run(:create, :attr => 'value') { 'result' }
    Factory.create(@name, :attr => 'value').should == 'result'
  end

  it "should use stub for Factory.stub" do
    mock(@factory).run(:stub, :attr => 'value') { 'result' }
    Factory.stub(@name, :attr => 'value').should == 'result'
  end

  it "should use default strategy option as Factory.default_strategy" do
    stub(@factory).default_strategy { :create }
    mock(@factory).run(:create, :attr => 'value') { 'result' }
    Factory.default_strategy(@name, :attr => 'value').should == 'result'
  end

  it "should use the default strategy for the global Factory method" do
    stub(@factory).default_strategy { :create }
    mock(@factory).run(:create, :attr => 'value') { 'result' }
    Factory(@name, :attr => 'value').should == 'result'
  end

  [:build, :create, :attributes_for, :stub].each do |method|
    it "should raise an ArgumentError on #{method} with a nonexistant factory" do
      lambda { Factory.send(method, :bogus) }.should raise_error(ArgumentError)
    end

    it "should recognize either 'name' or :name for Factory.#{method}" do
      stub(@factory).run
      lambda { Factory.send(method, @name.to_s) }.should_not raise_error
      lambda { Factory.send(method, @name.to_sym) }.should_not raise_error
    end
  end
end

describe "finding definitions" do
  def self.in_directory_with_files(*files)
    before do
      @pwd = Dir.pwd
      @tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
      FileUtils.mkdir_p @tmp_dir
      Dir.chdir(@tmp_dir)

      files.each do |file|
        FileUtils.mkdir_p File.dirname(file)
        FileUtils.touch file
        stub(Factory).require(file)
      end
    end

    after do
      Dir.chdir(@pwd)
      FileUtils.rm_rf(@tmp_dir)
    end
  end

  def require_definitions_from(file)
    simple_matcher do |given, matcher|
      has_received = have_received.require(file)
      result = has_received.matches?(given)
      matcher.description = "require definitions from #{file}"
      matcher.failure_message = has_received.failure_message
      result
    end
  end

  share_examples_for "finds definitions" do
    before do
      stub(Factory).require
      Factory.find_definitions
    end
    subject { Factory }
  end

  describe "with factories.rb" do
    in_directory_with_files 'factories.rb'
    it_should_behave_like "finds definitions"
    it { should require_definitions_from('factories.rb') }
  end

  %w(spec test).each do |dir|
    describe "with a factories file under #{dir}" do
      in_directory_with_files File.join(dir, 'factories.rb')
      it_should_behave_like "finds definitions"
      it { should require_definitions_from("#{dir}/factories.rb") }
    end

    describe "with a factories file under #{dir}/factories" do
      in_directory_with_files File.join(dir, 'factories', 'post_factory.rb')
      it_should_behave_like "finds definitions"
      it { should require_definitions_from("#{dir}/factories/post_factory.rb") }
    end

    describe "with several factories files under #{dir}/factories" do
      in_directory_with_files File.join(dir, 'factories', 'post_factory.rb'),
                              File.join(dir, 'factories', 'person_factory.rb')
      it_should_behave_like "finds definitions"
      it { should require_definitions_from("#{dir}/factories/post_factory.rb") }
      it { should require_definitions_from("#{dir}/factories/person_factory.rb") }
    end

    describe "with nested and unnested factories files under #{dir}" do
      in_directory_with_files File.join(dir, 'factories.rb'),
                              File.join(dir, 'factories', 'post_factory.rb'),
                              File.join(dir, 'factories', 'person_factory.rb')
      it_should_behave_like "finds definitions"
      it { should require_definitions_from("#{dir}/factories.rb") }
      it { should require_definitions_from("#{dir}/factories/post_factory.rb") }
      it { should require_definitions_from("#{dir}/factories/person_factory.rb") }
    end
  end
end

describe "default syntax" do
  it "should delegate to Alias when defining aliases" do
    stub(FactoryGirl::Alias).alias
    Factory.alias(/(.*)_suffix/, '\1')
    FactoryGirl::Alias.should have_received.alias(/(.*)_suffix/, '\1')
  end

  it "should return a hash of factories" do
    stub(FactoryGirl::Factory).factories { { 'test' => 'value' } }
    Factory.factories.should == { 'test' => 'value' }
  end

  it "should correctly guess the build class for a factory name ending in s" do
    lambda { Factory.define(:business) {|f| } }.
      should register_factory(:name => :business, :build_class => Business)
  end

  it "should convert a string name to a symbol" do
    lambda { Factory.define('user') {|f| } }.
      should register_factory(:name => :user, :build_class => User)
  end

  it "should guess the name from a class" do
    lambda { Factory.define(ArgumentError) {|f| } }.
      should register_factory(:name => :argument_error, :build_class => ArgumentError)
  end

  it "accept a custom class name" do
    lambda { Factory.define(:author, :class => :argument_error) {|f| } }.
      should register_factory(:name => :author, :build_class => ArgumentError)
  end

  it "should guess the build class from the factory name" do
    lambda { Factory.define(:user) {|f| } }.
      should register_factory(:name => :user,
                              :build_class => User)
  end

  it "should ensure it doesn't associate with itself" do
    lambda {
      Factory.define(:user) do |factory|
        factory.association :user
      end
    }.should raise_error(FactoryGirl::AssociationDefinitionError)
  end

end

describe "with a parent factory" do
  before do
    @parent = generate_factory(:build_class => Object)
    FactoryGirl::Factory.factories[:object] = @parent
  end

  it "should create a new factory using the class of the parent" do
    lambda do
      Factory.define(:child, :parent => :object) {|f| }
    end.should register_factory(:build_class => Object,
                                :parent => :object,
                                :name   => :child)
  end

  it "should create a new factory while overriding the parent class" do
    class Other; end
    lambda do
      Factory.define(:child, :parent => :object, :class => Other) {|f| }
    end.should register_factory(:build_class => Other,
                                :parent      => :object,
                                :name        => :child)
  end

end
