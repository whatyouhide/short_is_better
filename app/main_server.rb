# The main server class. This can be run as a Rack application.
class MainServer < Base
  # Redirect to a regular URL from a short url.
  # GET /shorturl
  get '/:short_url' do |short_url|
    url = redis_for_short_urls.get(short_url) || not_found
    redirect url
  end
end
