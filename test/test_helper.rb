ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/pride'
require 'rack/test'
require 'fakeredis'

require_relative '../server'

class RackMiniTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Server
  end
end
