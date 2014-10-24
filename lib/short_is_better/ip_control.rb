# @todo docs
class ShortIsBetter::IpControl
  # @todo docs
  def self.reset!
    new.reset!
  end

  # Create a new instance of `IpControl` and connect to the proper Redis
  # database. Environment handling is performed by the `Sinatra::ConfigFile`
  # extension.
  def initialize
    @redis = Redis.new(url: ShortIsBetter::Base.settings.redis['ip_control'])
  end

  # @todo docs
  def reset!
    @redis.flushall
  end
end
