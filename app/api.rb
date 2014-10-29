require 'json'

# This class represents the API exposed at the `api.{domain}` domain. Its job is
# to store new urls in the database.
class Api < Base
  register Sinatra::Namespace
  register Sinatra::CrossOrigin
  helpers Sinatra::JSON

  # CORS.
  enable :cross_origin
  set :allow_origin, :any
  set :allow_methods, %i(post)
  set :allow_credentials, false
  set :max_age, '1728000'
  set :expose_headers, ['Content-Type']

  # Every time a request is received, instantiate a new `IpControl` object with
  # the IP of that request.
  before do
    @ip_control = IpControl.new(request.ip)
  end

  # Version 1 of the API.
  namespace '/v1' do
    # Allow preflight requests (for CORS purposes).
    options('*') {}

    # The main endpoint of the API, used to shorten URLs.
    post '/new/?' do
      # Some validation checks.
      ensure_ip_is_under_the_limit!
      ensure_theres_a_well_formed_url_paramer!

      # Url storing.
      short, long = params[:short_url], params[:url]
      stored_url = short ? create_custom(short, long) : shorten(long)

      # If the URL has been created, increment the count of stored urls (for
      # that IP).
      @ip_control.increment! if status == 201

      json short_url: stored_url
    end
  end

  # Catch every error and return its body as the "message" key of a JSON object.
  error 400..599 do
    json message: body.join('')
  end

  private

  # Ensure there's a `:url` parameter and that it is a well formed URL. If not,
  # halt with a `400 Bad Request` code and an explanative error message.
  # @return [void]
  def ensure_theres_a_well_formed_url_paramer!
    url = params[:url]
    halt(400, "The 'url' parameter is missing") unless url
    halt(400, "'#{url}' isn't a valid url") unless valid_url?(url)
  end

  # Ensure that the requesting IP is under the limit of stored urls per day,
  # halting with a 429 Too Many Requests error if it's over the limit.
  def ensure_ip_is_under_the_limit!
    msg = "The IP address %s has reached its limit for stored urls per day" %
      [request.ip]

    halt(429, msg) unless @ip_control.under_the_limit?
  end

  # Try to store a custom short URL. If it succeedes, set the status code to
  # `201 Created` and return the custom short URL, otherwise fail with a `409
  # Conflict` error. If the previous long url stored at `short_url` is the same
  # as the current `long_url`, a 200 OK response is returned.
  # @param [String] short_url
  # @param [String] long_url
  # @return [String] The custom short URL
  def create_custom(short_url, long_url)
    existing, created = redis_for_short_urls.multi do
      redis_for_short_urls.get(short_url)
      redis_for_short_urls.setnx(short_url, long_url)
    end

    if !created && existing != long_url
      halt(409, "'#{short_url}' was already taken")
    end

    # The long url at `short_url` could have been the same as `long_url`, in
    # which case we return a 200 OK instead of a 201 Created.
    status(created ? 201 : 200)
    short_url
  end

  # Shorten a given `long_url` and return its shortened version. If the long url
  # was already in the database, set the status to `200 OK`; otherwise, set the
  # status to `201 Created`.
  # @param [String] long_url
  # @return [String]
  def shorten(long_url)
    shortener = Shortener.new(params[:url], redis_for_short_urls)
    short = shortener.shorten_and_store!
    status (shortener.created? ? 201 : 200)
    short
  end

  # Whether the given url is a valid url.
  # @param [String] url
  # @return [Boolean]
  def valid_url?(url)
    SimpleIDN.to_ascii(url) =~ /\A#{URI::regexp}\z/
  end
end
