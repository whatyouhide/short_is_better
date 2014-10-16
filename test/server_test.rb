require_relative 'test_helper'

class ServerTest < RackMiniTest
  SAMPLE_URL = 'https://github.com'

  def test_shorten_url_goes_fine_and_returns_json
    shorten SAMPLE_URL
    assert last_response.successful?
    assert_equal 'application/json', last_response.content_type
  end

  def test_new_returns_the_original_url
    shorten SAMPLE_URL
    data = JSON.parse(last_response.body)
    assert_equal SAMPLE_URL, data['original_url']
  end

  def test_new_returns_a_working_short_url
    shorten SAMPLE_URL
    data = JSON.parse(last_response.body)

    refute_nil data['short_url']

    get('/' + data['short_url'])
    assert last_response.redirect?

    follow_redirect!
    assert_match /#{Regexp.escape(SAMPLE_URL)}/, last_request.url
  end

  def test_new_doesnt_create_anything_if_the_url_already_exists
    url = 'https://uniqueurl.com'
    shorten url
    assert_equal 201, last_response.status

    shorten url
    assert last_response.ok?
  end

  def test_url_not_found
    get '/i-m-sure-this-url-doesnt-exist-am-iii'
    assert last_response.not_found?
  end

  def test_url_is_invalid
    shorten 'foo'
    assert_equal 400, last_response.status
  end

  private

  def shorten(long_url)
    post '/new', url: long_url
  end
end
