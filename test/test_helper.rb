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

  attr_reader :fixtures

  def self.app(app)
    define_method(:app) { app }
  end

  def load_fixtures!
    @fixtures = {}
    fixtures = YAML.load_file(File.expand_path('fixtures.yml'))
    redis = Redis.new

    fixtures['urls'].each do |url|
      short = ShortIsBetter::Url.new(url, redis).shorten
      @fixtures[short] = url
    end

    fixtures['custom_urls'].each do |short, long|
      redis.set(short, long)
      @fixtures[short] = long
    end
  end
end
