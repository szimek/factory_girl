module CreationMethods
  def generate_factory(opts = {})
    opts = {
      :build_class => User,
      :attributes  => []
    }.merge(opts)
    FactoryGirl::Factory.new(opts.delete(:build_class), opts.delete(:attributes), opts)
  end

  def generate_attribute(opts = {})
    opts = {
      :name  => :name
    }.merge(opts)
    FactoryGirl::Attribute::Static.new(opts[:name], 'value')
  end

  def generate_callback(opts = {})
    FactoryGirl::Attribute::Callback.new(:after_build, lambda { |factory| })
  end
end
