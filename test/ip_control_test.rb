require_relative 'test_helper'

class IpControlTest < RackTest
  flush_databases!

  def setup
    @settings ||= Api.settings
    @redis ||= Redis.new(url: @settings.redis['ip_control'])
  end

  def test_reset_class_method
    @redis.flushdb

    size = 10
    (Array.new(size) { random_ip }).each { |ip| @redis.incr(ip) }

    assert_equal size, @redis.keys.size
    IpControl.flush!
    assert_empty @redis.keys
  end

  def test_under_the_limit?
    limit = 5
    ip = '237.164.194.0'

    with_settings(Api, urls_per_ip_per_day: limit) do
      ip_control = IpControl.new(ip)

      (limit - 1).times do
        @redis.incr(ip)
        assert ip_control.under_the_limit?, 'Should be under'
      end

      @redis.incr(ip)
      refute ip_control.under_the_limit?, 'Should be over'
    end
  end

  def test_increment!
    ip = '99.99.99.99'
    ip_control = IpControl.new(ip)

    old_value = (@redis.get(ip) || 0).to_i
    assert_equal old_value + 1, ip_control.increment!
  end

  private

  def random_ip
    Array.new(4) { rand(256) }.join('.')
  end
end
