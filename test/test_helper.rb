ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.require(:default, :test)

require 'yaml'
require_relative '../lib/short_is_better'

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

  # Empty the Redis (fakeredis actually) database before each `setup` block.
  # See http://docs.seattlerb.org/minitest/Minitest/Test/LifecycleHooks.html
  def before_setup
    @redis = Redis.new
    @redis.flushall
    super
  end

  # Read the fixtures from test/fixtures.yml and load them into the Redis
  # (fakeredis) database.
  def load_fixtures!
    @fixtures = {}
    yaml = YAML.load_file(File.expand_path('fixtures.yml'))

    yaml['urls'].each do |url|
      short = ShortIsBetter::Url.new(url, @redis).shorten
      @fixtures[short] = url
    end

    yaml['custom_urls'].each do |short, long|
      @redis.set(short, long)
      @fixtures[short] = long
    end
  end
end
