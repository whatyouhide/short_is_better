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
    prevent_invalid_url!(long_url)
    short_url = create_new(long_url)
    json short_url: short_url, original_url: long_url
  end

  # Redirect to a regular URL from a short url.
  # GET /shorturl
  get '/:short_url' do |short_url|
    url = @redis.get(short_url) || not_found
    redirect url
  end

  private

  def json(hash)
    content_type :json
    body hash.to_json
  end

  def create_new(long_url)
    url = Url.new(long_url, @redis)
    short_url = url.shorten
    url.created? ? status(201) : status(200)
    short_url
  end

  def prevent_invalid_url!(url)
    return if url =~ /\A#{URI::regexp}\z/
    json message: "#{url} isn't a valid URL"
    error status_code(:bad_request)
  end
end
