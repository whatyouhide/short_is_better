require 'digest'

class ShortIsBetter::Shortener
  # Reserved URLs are parts of the URL that are reserved for the API (e.g.
  # '/api') and can't be used as hashes.
  RESERVED = %w(api)

  # The characters allowed for use in an URL.
  # For now, these are all the alphanumeric (uppercase and lowercase) characters
  # except for `[0, O, I, l]`.
  ALLOWED_CHARS =
    'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ123456789'.split ''

  def initialize(long_url, redis_connection)
    @redis = redis_connection || Redis.new
    @long = long_url
  end

  def shorten_and_store!(length = 4)
    short = hashed(length)

    # Move on to the next version of the short url if this version is a reserved
    # url keyword (like '/api').
    if RESERVED.include?(short)
      return shorten_and_store!(length + 1)
    end

    @created, existing = @redis.multi do
      @redis.setnx(short, @long)
      @redis.get(short)
    end

    # If it has been created or it's already there and the corresponding url is
    # the same as the current one, return that short url.
    if @created || existing == @long
      short
    else
      # The short url was taken by another long url, so move on to the next short
      # url and try again.
      shorten_and_store!(length + 1)
    end
  end

  def created?
    @created
  end

  private

  # @param [Fixnum]
  # @return [String]
  def hashed(length, charset = ALLOWED_CHARS)
    @hex_digest ||= Digest::MD5.hexdigest(@long)
    @stream ||= Bases[@hex_digest].in_hex.to_base(charset)

    @stream.slice(0, length)
  end
end
