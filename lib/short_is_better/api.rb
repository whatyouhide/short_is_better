require 'json'

# This class represents the API exposed at the `api.{domain}` domain. Its job is
# to store new urls in the database.
class ShortIsBetter::Api < ShortIsBetter::Base
  register Sinatra::Namespace
  helpers Sinatra::JSON

  # Version 1 of the API.
  namespace '/v1' do

    # The main endpoint of the API, used to shorten URLs.
    post '/new' do
      ensure_ip_is_under_the_limit!
      ensure_theres_a_well_formed_url_paramer!

      short, long = params[:short_url], params[:url]

      stored_url = short ? create_custom(short, long) : shorten(long)

      # If an URL has been created, increment the count of stored urls for that
      # IP.
      increment_ips_stored_urls if status == 201

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
    halt(400, "The 'url' paramer is missing") unless url
    halt(400, "'#{url}' isn't a valid url") unless valid_url?(url)
  end

  # Ensure that the requesting IP is under the limit of stored urls per day,
  # halting with a 429 Too Many Requests error if it's over the limit.
  def ensure_ip_is_under_the_limit!
    msg = "The IP address %s has reached its limit for stored urls per day" %
      [request.ip]

    halt(429, msg) if ip_over_the_limit?
  end

  # Increment the count of stored urls for the requesting IP address.
  def increment_ips_stored_urls
    redis_for_ip_control.incr(request.ip)
  end

  # Try to store a custom short URL. If it succeedes, set the status code to
  # `201 Created` and return the custom short URL, otherwise fail with a `409
  # Conflict` error.
  # @param [String] short_url
  # @param [String] long_url
  # @return [String] The custom short URL
  def create_custom(short_url, long_url)
    created = redis_for_short_urls.setnx(short_url, long_url)

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
    shortener = ShortIsBetter::Shortener.new(params[:url], redis_for_short_urls)
    short = shortener.shorten_and_store!
    status (shortener.created? ? 201 : 200)
    short
  end

  # Whether the given url is a valid url.
  # @param [String] url
  # @return [Boolean]
  def valid_url?(url)
    url =~ /\A#{URI::regexp}\z/
  end

  # Whether this ip has reached the limit of stored urls per day.
  # @return [Boolean]
  def ip_over_the_limit?
    stored_urls = redis_for_ip_control.get(request.ip).to_i
    stored_urls >= settings.urls_per_ip_per_day
  end
end
