# @todo docs
class ShortIsBetter::IpControl
  # @todo docs
  def self.flush!
    new.flush!
  end

  # Create a new instance of `IpControl` and connect to the proper Redis
  # database. Environment handling is performed by the `Sinatra::ConfigFile`
  # extension.
  def initialize
    @redis = Redis.new(url: ShortIsBetter::Base.settings.redis['ip_control'])
  end

  # @todo docs
  def flush!
    @redis.flushdb
  end
end
