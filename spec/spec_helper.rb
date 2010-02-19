$: << File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.join(File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
Bundler.require

require 'models'
require 'factory_girl'
require 'rr' # FIXME not required automatically by Bundler

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end
