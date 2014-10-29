require 'uri'
require_relative 'test_helper'


class MainServerTest < RackTest
  app MainServer
  flush_databases!
  load_fixtures!

  def test_basic_redirect
    fixtures.each do |short, long|
      get "/#{short}"

      assert last_response.redirect?, 'Response was not a redirect'

      follow_redirect!
      assert_urls_match long, last_request.url
    end
  end

  def test_not_found_when_the_short_url_isnt_in_the_database
    bad_urls = %w(
      thisisnotinthedatabase
      And-NEITHER-i$-ThIs
      foo-bar-baz-were-going-out-for-a-drink
      under_scoring_all_the_things
    )

    bad_urls.each do |bad_url|
      get "/#{bad_url}"
      assert last_response.not_found?, 'Response was not a 404 error'
    end
  end

  private

  def assert_urls_match(expected, actual)
    expected, actual = URI.parse(expected), URI.parse(actual)
    expected_path = expected.path.empty? ? '/' : expected.path
    actual_path = actual.path.empty? ? '/' : actual.path
    assert_equal expected.scheme, actual.scheme
    assert_equal expected.host, actual.host
    assert_equal expected.query, actual.query
    assert_equal expected.fragment, actual.fragment
    assert_equal expected_path, actual_path
  end
end
