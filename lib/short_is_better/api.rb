require 'json'

# This class represents the API exposed at the `api.{domain}` domain. Its job is
# to store new urls in the database.
class ShortIsBetter::Api < Sinatra::Base
  register Sinatra::Namespace
  helpers Sinatra::JSON

  # Initialize this app (with the next `app` on the Rack stack) and setup a
  # Redis connection.
  def initialize(app = nil)
    @redis = Redis.new
    super(app)
  end

  # This API is hooked up to the "api." subdomain of the domain this application
  # is running on. Everything else results in a 404 error.
  namespace host_name: /^api\./ do

    # Version 1 of the API.
    namespace '/v1' do

      # The main endpoint of the api, used to shorten URLs.
      post '/new' do
        ensure_theres_a_well_formed_url_paramer!
        short, long = params[:short_url], params[:url]

        stored_url = short ? create_custom(short, long) : shorten(long)
        json short_url: stored_url
      end
    end

    # Catch every error and return its body as the "message" key of a JSON object.
    # The most important thing of this handler is that it *keeps the error code
    # intact*: this way, even if this catches a 404 or 405 error, the Rack cascade
    # will still keep cascading and the next app will catch the request.
    error 400..599 do
      json message: body.join('')
    end
  end

  private

  # Ensure there's a `:url` parameter and that it is a well formed URL. If not,
  # halt with a `400 Bad Request` code and an explanative error message.
  # @return [void]
  def ensure_theres_a_well_formed_url_paramer!
    url = params[:url]
    halt(400, "The 'url' paramer is missing") unless url
    halt(400, "'#{url}' isn't a valid url") unless valid_url?(url)
  end

  # Try to store a custom short URL. If it succeedes, set the status code to
  # `201 Created` and return the custom short URL, otherwise fail with a `409
  # Conflict` error.
  # @param [String] short_url
  # @param [String] long_url
  # @return [String] The custom short URL
  def create_custom(short_url, long_url)
    created = @redis.setnx(short_url, long_url)

    halt(409, "'#{short_url}' was already taken") unless created

    status 201
    short_url
  end

  # Shorten a given `long_url` and return its shortened version. If the long url
  # was already in the database, set the status to `200 OK`; otherwise, set the
  # status to `201 Created`.
  # @param [String] long_url
  # @return [String]
  def shorten(long_url)
    shortener = ShortIsBetter::Shortener.new(params[:url], @redis)
    short = shortener.shorten_and_store!
    status (shortener.created? ? 201 : 200)
    short
  end

  # Whether the given url is a valid url.
  # @param [String] url
  # @return [bool]
  def valid_url?(url)
    url =~ /\A#{URI::regexp}\z/
  end
end
