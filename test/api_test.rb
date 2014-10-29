require_relative 'test_helper'
require 'securerandom'

class ApiTest < RackTest
  app Api
  flush_databases!

  def test_201_created_when_a_url_is_created
    shorten url: unique_url
    assert_last_status 201
    refute_nil responded_json['short_url']
  end

  def test_doesnt_recreate_an_already_existing_url
    urls = Array.new(5) { unique_url }.uniq

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
    assert_error_message "parameter is missing"
  end

  def test_fails_if_the_url_isnt_well_formed
    bad_urls = %W(no-url bad foo/:/bar #{"hey there"})

    bad_urls.each do |url|
      shorten url: url
      assert_last_status 400
      assert_error_message "isn't a valid url"
    end
  end

  def test_the_new_endpoint_works_with_a_trailing_slash
    post API_STARTING_ENDPOINT + '/new/', url: 'http://trailing-slash.com'
    assert last_response.successful?
  end

  def test_custom_short_urls_are_allowed
    shorten url: SAMPLE_URL, short_url: 'maccheroni'
    assert_last_status 201
    assert_equal responded_json['short_url'], 'maccheroni'
  end

  def test_same_custom_url_for_same_long_url_doesnt_fail
    shorten url: SAMPLE_URL, short_url: 'foobarbaz'
    shorten url: SAMPLE_URL, short_url: 'foobarbaz'
    assert_last_status 200
    assert_equal responded_json['short_url'], 'foobarbaz'
  end

  def test_fails_if_the_custom_url_is_already_taken
    shorten url: SAMPLE_URL, short_url: 'taken'
    shorten url: SAMPLE_URL + '/bar', short_url: 'taken'
    assert_last_status 409
    assert_error_message 'already taken'
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
    assert_error_message 'reached its limit'

    app.set :urls_per_ip_per_day, previous_limit
  end

  private

  def assert_error_message(error_msg, msg = nil)
    refute_nil responded_json['message']
    assert_includes responded_json['message'],
      error_msg,
      (msg || 'The responded JSON does not include the given message')
  end

  def shorten(params, env = {})
    post(API_STARTING_ENDPOINT + '/new', params, env)
  end

  def responded_json
    JSON.parse last_response.body
  end
end
