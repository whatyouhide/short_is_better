ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/pride'
require 'bundler/setup'

Bundler.require(:test)

require_relative '../main'

class RackMiniTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Server
  end
end
