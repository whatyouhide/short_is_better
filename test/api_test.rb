require_relative 'test_helper'
require 'securerandom'

class ApiTest < RackTest
  app ShortIsBetter::Api
  flush_databases!

  SAMPLE_URL = 'https://github.com'
  API_STARTING_ENDPOINT = 'http://api.example.com/v1'

  def test_201_created_when_a_url_is_created
    shorten url: unique_url
    assert_last_status 201
    refute_nil responded_json['short_url']
  end

  def test_doesnt_recreate_an_already_existing_url
    urls = Array.new(15) { unique_url }.uniq

    urls.each do |url|
      shorten url: url
      previous_short_url = responded_json['short_url']
      assert_last_status 201

      shorten url: url
      new_short_url = responded_json['short_url']
      assert_last_status 200

      assert_equal new_short_url, previous_short_url
    end
  end

  def test_fails_if_no_url_is_given
    post API_STARTING_ENDPOINT + '/new'
    assert_last_status 400
  end

  def test_fails_if_the_url_isnt_well_formed
    bad_urls = %W(no-url bad foo/:/bar #{"hey there"})

    bad_urls.each do |url|
      shorten url: url
      assert_last_status 400
    end
  end

  def test_the_new_endpoint_works_with_a_trailing_slash
    post API_STARTING_ENDPOINT + '/new/', url: 'http://trailing-slash.com'
    assert_last_status 201
  end

  def test_is_able_to_regenerate_urls_until_a_free_one_is_found
    # In this test, we do quite a big no-no: we tamper the code at its core!
    # We're touching the `MINIMUM_LENGTH` constant of the `Shortener` class
    # so that we can choose (at runtime) how long the generated short url needs
    # to be. Doing it in a "clean" way would require to add some code (lik an
    # attr_accessor) to the `Shortener` class, but changing the code in order to
    # make tests easier is bad.
    # Maybe this stuff could be moved to a more general configuration (like
    # `ShortIsBetter.config`) so that this thing is programmatically exposed,
    # which could turn in handy.
    old_minimum_length = ShortIsBetter::Shortener.const_get(:MINIMUM_LENGTH)
    ShortIsBetter::Shortener.send(:remove_const, :MINIMUM_LENGTH)
    ShortIsBetter::Shortener.const_set(:MINIMUM_LENGTH, 1)

    lots_of_urls = Array.new(100) { unique_url }.uniq

    short_urls = lots_of_urls.map do |url|
      shorten url: url
      assert_last_status 201
      responded_json['short_url']
    end

    assert short_urls.any? { |url| url.length > 1 }
    assert short_urls.any? { |url| url.length == 1 }

    ShortIsBetter::Shortener.send(:remove_const, :MINIMUM_LENGTH)
    ShortIsBetter::Shortener.const_set(:MINIMUM_LENGTH, old_minimum_length)
  end

  def test_custom_short_urls_are_allowed
    shorten url: SAMPLE_URL, short_url: 'maccheroni'
    assert_last_status 201
    assert_equal responded_json['short_url'], 'maccheroni'
  end

  def test_fails_if_the_custom_url_is_already_taken
    shorten url: SAMPLE_URL, short_url: 'taken'
    shorten url: SAMPLE_URL, short_url: 'taken'

    # Assert there's a 409 Conflict.
    refute last_response.successful?
    assert_last_status 409
  end

  def test_ips_are_limited_on_the_number_of_urls_created_per_day
    # Remember the limit before this test, and reset it at the end of it.
    previous_limit = app.settings.urls_per_ip_per_day

    app.set :urls_per_ip_per_day, 5
    env_with_ip = { 'REMOTE_ADDR' => '1.2.3.4' }

    # Shorten random URLs until we find one that was not in the database; repeat
    # 5 times in order to store 5 urls for this ip.
    5.times do
      loop do
        shorten({ url: unique_url }, env_with_ip)
        break if last_response.status == 201
      end
    end

    shorten({ url: 'https://this-is-not-in-the.database' }, env_with_ip)
    assert_last_status 429 # 429 Too Many Requests

    app.set :urls_per_ip_per_day, previous_limit
  end

  private

  def shorten(params, env = {})
    post(API_STARTING_ENDPOINT + '/new', params, env)
  end

  def unique_url
    SAMPLE_URL + '/' + SecureRandom.hex
  end

  def responded_json
    JSON.parse last_response.body
  end
end
