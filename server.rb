require 'json'
require_relative 'url'

# The main server class. This can be run as a Rack application.
class Server < Sinatra::Base
  # Initialize the app and connect to Redis.
  def initialize(app = nil)
    @redis = Redis.new
    super(app)
  end

  # Shorten an URL passed as `url` in the parameters.
  # POST /new
  # Params: url={encoded_url}
  post '/new' do
    long_url = URI.decode(params[:url])

    if valid_url?(long_url)
      respond_with_json short_url: create_new(long_url), original_url: long_url
    else
      invalid_url_error(long_url)
    end
  end

  # Redirect to a regular URL from a short url.
  # GET /shorturl
  get '/:short_url' do |short_url|
    url = @redis.get(short_url) || not_found
    redirect url
  end

  private

  # Respond to the current request with a JSON representation of `hash_data`.
  # This method also sets the content type to 'application/json'.
  # @param [Hash] hash_data A, well, hash of data.
  # @return [void]
  def respond_with_json(hash_data)
    content_type :json
    body hash_data.to_json
  end

  # Create a new short url and return it.
  # @param [String] long_url
  # @return [String]
  def create_new(long_url)
    url = Url.new(long_url, @redis)
    short_url = url.shorten
    url.created? ? status(201) : status(200)
    short_url
  end

  # Halt with a 404 error and a custom message for the given (supposedly
  # invalid) `url`.
  # @param [String] url
  # @return [void]
  def invalid_url_error(url)
    error status_code(:bad_request), "#{url} isn't a valid URL"
  end

  # Return `true` if `url` is a valid URL, `false` otherwise.
  # @param [String] url
  # @return [bool]
  def valid_url?(url)
    url =~ /\A#{URI::regexp}\z/
  end
end
