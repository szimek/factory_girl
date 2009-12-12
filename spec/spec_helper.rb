PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$: << File.join(PROJECT_ROOT, 'lib')

require 'rubygems'

require 'activerecord'

require 'spec'
require 'spec/autorun'
require 'rr'

Dir.glob(File.join(PROJECT_ROOT, 'spec', 'support', '**', '*.rb')).each { |file| require(file) }

require 'factory_girl'

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
  config.include CreationMethods
  config.include Matchers

  config.after do
    FactoryGirl::Factory.factories.clear
    FactoryGirl::Sequence.sequences.clear
  end
end
