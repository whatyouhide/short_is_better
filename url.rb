require 'digest'
require 'base62'

# An Url object encapsulates a regular URL and provides facilities for creating
# a shortened version of that URL and storing that into a given Redis db.
class Url
  # The default length of the hashed version of an url.
  MINIMUM_HEX_LENGTH = 6

  # Create a new URL based on a `long_url`. `redis_connection` is used to pass a
  # Redis connection to the new object.
  # @param [String] long_url
  # @param [Redis] redis_connection
  def initialize(long_url, redis_connection)
    @long = long_url
    @redis = redis_connection
  end

  # Return an hashed version of this URL using the MD5 algorithm.
  # Actually, return only the first `length` characters in the hash.
  # @param [Fixnum] length The length of the resulting digest
  # @return [String]
  def hashed(length)
    @digest ||= Digest::MD5.hexdigest(@long)
    @digest.slice(0, length)
  end

  # Shorten the current URL. If the same URL is in the database, it'll have the
  # same hash and that will be used. If the hash has already been used but on a
  # different URL (*very* little probability), the same hash but longer will be
  # used.
  # @param [Fixnum] length The lenght of the underlying hash, which is not
  #   strictly related to the lenght of the shortened URL.
  # @return [String] The newly created short url
  def shorten(length = MINIMUM_HEX_LENGTH)
    short = hashed(length).hex.base62_encode

    # If such short url doesn't exist, create it and return early.
    if !@redis.exists(short)
      @redis.set(short, @long)
      @created = true
      return short
    end

    # If the existing URL is the same as the one we're creating, return that,
    # otherwise recursively call this function with a greater length.
    @redis.get(short) == @long ? short : shorten(length + 1)
  end

  # Whether the URL has been created and inserted into the Redis db or an
  # existing URL has been used.
  def created?
    @created
  end
end
