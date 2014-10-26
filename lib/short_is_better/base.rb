# @todo generic docs, maybe better naming, maybe some methods can be moved
# elsewhere (I'm looking at you, redis_for_ip_control).
class ShortIsBetter::Base < Sinatra::Base
  register Sinatra::ConfigFile

  set :root, File.expand_path('../../..', __FILE__)
  set :environments, %w(development test production staging)

  config_file 'config/*.yml'

  enable :logging

  protected

  def redis_for_short_urls
    @redis_for_short_urls ||= Redis.new(url: settings.redis['short_urls'])
  end

  def redis_for_ip_control
    @redis_for_ip_control ||= Redis.new(url: settings.redis['ip_control'])
  end
end
