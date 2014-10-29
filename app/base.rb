# The base class which inherits from Sinatra::Base. All the Sinatra apps that
# form this application inherit from this class, which sets up some common
# options and useful methods.
class Base < Sinatra::Base
  register Sinatra::ConfigFile

  # Configurations.
  set :root, File.expand_path('../../', __FILE__)
  set :environments, %w(development test production staging)
  enable :logging

  config_file 'config/environments/*.yml'

  protected

  def redis_for_short_urls
    @redis_for_short_urls ||= Redis.new(url: settings.redis['short_urls'])
  end
end
