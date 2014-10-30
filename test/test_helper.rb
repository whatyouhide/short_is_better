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
  SAMPLE_URL = 'https://github.com'
  API_STARTING_ENDPOINT = 'http://api.example.com/v1'

  def self.app(app)
    self.include(Rack::Test::Methods)
    define_method(:app) { app }
  end

  def self.flush_databases!
    set_redis_databases
    @redis_for_short_urls.flushdb
    @redis_for_ip_control.flushdb
  end

  # Read the fixtures from test/fixtures.yml and load them into the Redis
  # database.
  def self.load_fixtures!
    set_redis_databases
    fixtures = {}
    yaml = load_fixtures_from_yaml_file

    yaml['urls'].each do |url|
      short = Shortener.new(url, @redis_for_short_urls).shorten_and_store!
      fixtures[short] = url
    end

    yaml['custom_urls'].each do |short, long|
      @redis_for_short_urls.set(short, long)
      fixtures[short] = long
    end

    define_method(:fixtures) { fixtures }
  end

  def assert_last_status(status)
    assert last_response.status == status,
      "last_response.status is #{last_response.status} instead of #{status}"
  end

  def with_settings(app_or_hash, hash_if_app = nil, &block)
    if hash_if_app.nil?
      hash = app_or_hash
      app = self.app
    else
      app = app_or_hash
      hash = hash_if_app
    end

    previous_hash = hash.keys.reduce({}) do |acc, sett|
      acc.merge({ sett => app.settings.send(sett) })
    end

    hash.each { |sett, val| app.set(sett, val) }
    yield
    previous_hash.each { |sett, val| app.set(sett, val) }
  end

  protected

  def unique_url
    SAMPLE_URL + '/' + SecureRandom.hex
  end

  class << self
    private

    def set_redis_databases
      redis_urls = Base.settings.redis
      @redis_for_short_urls ||= Redis.new(url: redis_urls['short_urls'])
      @redis_for_ip_control ||= Redis.new(url: redis_urls['ip_control'])
    end

    def load_fixtures_from_yaml_file
      YAML.load_file(File.expand_path('../fixtures.yml', __FILE__))
    end
  end
end
