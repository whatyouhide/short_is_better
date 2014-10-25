# @todo docs
class ShortIsBetter::IpControl
  # @todo docs
  def self.flush!
    new.flush!
  end

  # @todo docs
  def initialize(ip = nil)
    @ip = ip unless ip.nil?
    @settings = ShortIsBetter::Api.settings
    @redis = Redis.new(url: @settings.redis['ip_control'])
  end

  # @todo docs
  def flush!
    @redis.flushdb
  end

  # @todo docs
  def under_the_limit?
    current_value = @redis.get(@ip).to_i
    current_value < @settings.urls_per_ip_per_day
  end

  # @todo docs
  def increment!
    @redis.incr(@ip)
  end
end
