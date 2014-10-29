# This class provides facilities for dealing with IP addresses control: checking
# if an IP address stored too many urls, resetting the stored urls per IP (used
# for cronjobs) and so on.
class IpControl
  # Remove all the keys in the designated Redis database, which results in
  # resetting the stored urls per IP per day.
  # @return [void]
  def self.flush!
    new.flush!
  end

  # Create a new instance of this class, fetch the settings of the `Api` Sinatra
  # application and connect to the designated Redis server.
  # If an `ip` is given, it will be memorized by this instance so that methods
  # like `under_the_limit?` don't have to accept any arguments.
  # @param [String] ip The IP address of the current request, usually.
  def initialize(ip = nil)
    @ip = ip unless ip.nil?
    @settings = Api.settings
    @redis = Redis.new(url: @settings.redis['ip_control'])
  end

  # Like `IpControl.flush`. Actually, `IpControl.flush` is just a proxy to this
  # method so that it can be cleanly called on the `IpControl` class from
  # outside the applicaton, without instantiating anything.
  # @return [void]
  def flush!
    @redis.flushdb
  end

  # Return `true` if the IP address passed to the constructor has stored a
  # number of urls which is *strictly* smaller than the number allowed; return
  # `false` otherwise.
  # @return [Boolean]
  def under_the_limit?
    current_value = @redis.get(@ip).to_i
    current_value < @settings.urls_per_ip_per_day
  end

  # Increment the number of stored urls for the IP passed to the constructor.
  # This function writes to the Redis database.
  # @return [Fixnum] The updated number of stored urls for the given IP.
  def increment!
    @redis.incr(@ip)
  end
end
