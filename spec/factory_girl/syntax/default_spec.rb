require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "defining a factory" do
  before do
    @name    = :user
    @factory = "factory"
    stub(@factory).factory_name { @name }
    @options = { :class => 'magic' }
    stub(Factory).new { @factory }
  end

  it "should create a new factory using the specified name and options" do
    mock(Factory).new(@name, @options) { @factory }
    Factory.define(@name, @options) {|f| }
  end

  it "should pass the factory do the block" do
    yielded = nil
    Factory.define(@name) do |y|
      yielded = y
    end
    yielded.should == @factory
  end

  it "should add the factory to the list of factories" do
    Factory.define(@name) {|f| }
    @factory.should == Factory.factories[@name]
  end

  it "should allow that factory to be found by name" do
    Factory.factory_by_name(@name).should == @factory
  end
end

describe "a definition proxy" do
  before do
    @proxy = Factory.new(:post)
  end

  subject { @proxy }

  it "should add a static attribute when an attribute is defined with a value" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    mock(Factory::Attribute::Static).new(:name, 'value') { attribute }
    subject.add_attribute(:name, 'value')
    subject.attributes.should include(attribute)
  end

  it "should add a dynamic attribute when an attribute is defined with a block" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    block     = lambda {}
    mock(Factory::Attribute::Dynamic).new(:name, block) { attribute }
    subject.add_attribute(:name, &block)
    subject.attributes.should include(attribute)
  end

  it "should raise for an attribute with a value and a block" do
    lambda {
      subject.add_attribute(:name, 'value') {}
    }.should raise_error(Factory::AttributeDefinitionError)
  end

  describe "adding an attribute using a in-line sequence" do
    it "should create the sequence" do
      mock(Factory::Sequence).new
      subject.sequence(:name) {}
    end

    it "should add a dynamic attribute" do
      attribute = 'attribute'
      stub(attribute).name { :name }
      mock(Factory::Attribute::Dynamic).new(:name, is_a(Proc)) { attribute }
      subject.sequence(:name) {}
      subject.attributes.should include(attribute)
    end
  end

  it "should add an association without a factory name or overrides" do
    name    = :user
    attr    = 'attribute'
    mock(Factory::Attribute::Association).new(name, name, {}) { attr }
    subject.association(name)
    subject.attributes.should include(attr)
  end

  it "should add an association with overrides" do
    factory   = Factory.new(:post)
    name      = :user
    attr      = 'attribute'
    overrides = { :first_name => 'Ben' }
    mock(Factory::Attribute::Association).new(name, name, overrides) { attr }
    factory.association(name, overrides)
    factory.attributes.should include(attr)
  end

  it "should add an association with a factory name" do
    factory = Factory.new(:post)
    attr = 'attribute'
    mock(Factory::Attribute::Association).new(:author, :user, {}) { attr }
    factory.association(:author, :factory => :user)
    factory.attributes.should include(attr)
  end

  it "should add an association with a factory name and overrides" do
    factory = Factory.new(:post)
    attr = 'attribute'
    mock(Factory::Attribute::Association).new(:author, :user, :first_name => 'Ben') { attr }
    factory.association(:author, :factory => :user, :first_name => 'Ben')
    factory.attributes.should include(attr)
  end

  it "should raise for a self referencing association" do
    factory = Factory.new(:post)
    lambda {
      factory.association(:parent, :factory => :post)
    }.should raise_error(Factory::AssociationDefinitionError)
  end

  it "should add an attribute using the method name when passed an undefined method" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    block = lambda {}
    mock(Factory::Attribute::Static).new(:name, 'value') { attribute }
    subject.send(:name, 'value')
    subject.attributes.should include(attribute)
  end

  it "should allow human_name as a static attribute name" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    mock(Factory::Attribute::Static).new(:human_name, 'value') { attribute}
    subject.human_name 'value'
  end

  it "should allow human_name as a dynamic attribute name" do
    attribute = 'attribute'
    stub(attribute).name { :name }
    block     = lambda {}
    mock(Factory::Attribute::Dynamic).new(:human_name, block) { attribute }
    subject.human_name(&block)
  end

  describe "after defining a factory" do
    before do
      @name    = :user
      @factory = "factory"

      Factory.factories[@name] = @factory
    end

    after { Factory.factories.clear }

    it "should use Proxy::AttributesFor for Factory.attributes_for" do
      mock(@factory).run(Factory::Proxy::AttributesFor, :attr => 'value') { 'result' }
      Factory.attributes_for(@name, :attr => 'value').should == 'result'
    end

    it "should use Proxy::Build for Factory.build" do
      mock(@factory).run(Factory::Proxy::Build, :attr => 'value') { 'result' }
      Factory.build(@name, :attr => 'value').should == 'result'
    end

    it "should use Proxy::Create for Factory.create" do
      mock(@factory).run(Factory::Proxy::Create, :attr => 'value') { 'result' }
      Factory.create(@name, :attr => 'value').should == 'result'
    end

    it "should use Proxy::Stub for Factory.stub" do
      mock(@factory).run(Factory::Proxy::Stub, :attr => 'value') { 'result' }
      Factory.stub(@name, :attr => 'value').should == 'result'
    end

    it "should use default strategy option as Factory.default_strategy" do
      stub(@factory).default_strategy { :create }
      mock(@factory).run(Factory::Proxy::Create, :attr => 'value') { 'result' }
      Factory.default_strategy(@name, :attr => 'value').should == 'result'
    end

    it "should use the default strategy for the global Factory method" do
      stub(@factory).default_strategy { :create }
      mock(@factory).run(Factory::Proxy::Create, :attr => 'value') { 'result' }
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
