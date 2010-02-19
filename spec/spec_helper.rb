$: << File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.join(File.dirname(__FILE__))

require 'bundler'
Bundler.require

require 'models'
require 'factory_girl'

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end
