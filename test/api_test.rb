require_relative 'test_helper'
require 'securerandom'

class ApiTest < RackTest
  app ShortIsBetter::Api

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

  def test_is_able_to_regenerate_urls_until_a_free_one_is_found
    old_minimum_length = ShortIsBetter::Shortener.minimum_length
    ShortIsBetter::Shortener.minimum_length = 1

    lots_of_urls = Array.new(100) { unique_url }.uniq

    short_urls = lots_of_urls.map do |url|
      shorten url: url
      assert_last_status 201
      responded_json['short_url']
    end

    assert short_urls.any? { |url| url.length > 1 }
    assert short_urls.any? { |url| url.length == 1 }

    ShortIsBetter::Shortener.minimum_length = old_minimum_length
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

  private

  def shorten(opts)
    post API_STARTING_ENDPOINT + '/new', opts
  end

  def unique_url
    SAMPLE_URL + '/' + SecureRandom.hex
  end

  def responded_json
    JSON.parse last_response.body
  end
end
