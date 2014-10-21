require_relative 'test_helper'
require 'securerandom'

class ApiTest < RackTest
  parallelize_me!
  app ShortIsBetter::Api

  SAMPLE_URL = 'https://github.com'

  def test_created_when_a_url_is_created
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
    post '/api/v1/new'
    assert_last_status 400
  end

  def test_fails_if_the_url_isnt_well_formed
    bad_urls = %W(no-url bad foo/:/bar #{"hey there"})

    bad_urls.each do |url|
      shorten url: url
      assert_last_status 400
      refute_nil responded_json['error']
    end
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
    refute_nil responded_json['error']
  end

  private

  def shorten(opts)
    post '/api/v1/new', opts
  end

  def unique_url
    SAMPLE_URL + '/' + SecureRandom.hex
  end

  def responded_json
    JSON.parse last_response.body
  end
end
