ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.require(:default, :test)

require_relative '../server'

# Change the default Minitest reporter.
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Simple test class that includes Rack test methods and defines the `app`
# method.
class RackMiniTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Server
  end
end
