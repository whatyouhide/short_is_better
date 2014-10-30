require 'digest'

class Shortener
  # Reserved URLs are parts of the URL that are reserved for the API (e.g.
  # '/api') and can't be used as hashes.
  RESERVED = %w()

  # The characters allowed for use in an URL.
  # For now, these are all the alphanumeric (uppercase and lowercase) characters
  # except for `[0, O, I, l]`.
  ALLOWED_CHARS =
    'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ123456789'.split ''

  def initialize(long_url, redis_connection)
    @redis = redis_connection
    @long = long_url
    @minimum_length = Base.settings.short_url_minimum_length
  end

  def shorten_and_store!(length = @minimum_length)
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

    # As per #17, the `existing` string is extracted with an US-ASCII encoding
    # instead of UTF8.
    existing = existing.force_encoding('utf-8')

    # If it has been created or it's already there and the corresponding url is
    # the same as the current one, return that short url; otherwise, increment
    # the length of the hashed url.
    if @created || existing == @long
      short
    else
      shorten_and_store!(length + 1)
    end
  end

  def created?
    @created
  end

  private

  def hashed(length, charset = ALLOWED_CHARS)
    @hex_digest ||= Digest::SHA2.hexdigest(@long)
    @stream ||= Bases[@hex_digest].in_hex.to_base(charset)

    @stream.slice(0, length)
  end
end
