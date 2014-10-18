ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/pride'
require 'bundler/setup'

Bundler.require(:default, :test)

require_relative '../server'

class RackMiniTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Server
  end
end
