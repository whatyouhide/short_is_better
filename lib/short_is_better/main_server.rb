# The main server class. This can be run as a Rack application.
class ShortIsBetter::MainServer < Sinatra::Base
  # Initialize the app and connect to Redis.
  def initialize(app = nil)
    @redis = Redis.new
    super(app)
  end

  # Redirect to a regular URL from a short url.
  # GET /shorturl
  get '/:short_url' do |short_url|
    url = @redis.get(short_url) || not_found
    redirect url
  end
end
