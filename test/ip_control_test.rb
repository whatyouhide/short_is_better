require_relative 'test_helper'

class IpControlTest < Minitest::Test
  def test_reset_class_method
    # Ensure an empty slate.
    redis.flushall

    random_ips = ips(10)
    random_ips.each do |ip|
      rand(1..10).times { redis.incr(ip) }
    end

    assert redis.keys.size == random_ips.size

    ShortIsBetter::IpControl.flush!
    assert_empty redis.keys
  end

  private

  # Return an array of `count` random IPs.
  def ips(count = 10)
    (0...count).map do
      Array.new(4) { rand(256) }.join('.')
    end
  end

  def redis
    @redis ||= Redis.new(url: ShortIsBetter::Base.settings.redis['ip_control'])
  end
end
