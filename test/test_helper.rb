ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.require(:default, :test)

require 'yaml'
require_relative '../main'

# Change the default Minitest reporter.
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Simple test class that includes Rack test methods and defines the `app`
# method, which is used to set the current Rack app to test (inside the test
# class).
class RackTest < Minitest::Test
  include Rack::Test::Methods

  attr_accessor :fixtures

  # DSL-like method that lets you call:
  #   app MyApp
  # at the beginning of a RackTest subclass, defining an `app` instance method
  # that Rack::Test uses to make requests to.
  def self.app(app)
    define_method(:app) { app }
  end

  # Read the fixtures from test/fixtures.yml and load them into the Redis
  # (fakeredis) database.
  def self.load_fixtures!
    redis_settings = YAML.load_file(File.expand_path('../../config/test.yml', __FILE__))['test']['redis']
    redis1 = Redis.new(url: redis_settings['short_urls'])
    redis2 = Redis.new(url: redis_settings['ip_control'])

    redis1.flushdb
    redis2.flushdb

    fixtures = {}
    yaml = YAML.load_file(File.expand_path('../fixtures.yml', __FILE__))

    yaml['urls'].each do |url|
      short = ShortIsBetter::Shortener.new(url, redis1).shorten_and_store!
      fixtures[short] = url
    end

    yaml['custom_urls'].each do |short, long|
      redis1.set(short, long)
      fixtures[short] = long
    end

    define_method(:fixtures) { fixtures }
  end

  def assert_last_status(status)
    assert last_response.status == status,
      "last_response.status is #{last_response.status} instead of #{status}"
  end
end
