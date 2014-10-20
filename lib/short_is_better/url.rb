require 'digest'

# An Url object encapsulates a regular URL and provides facilities for creating
# a shortened version of that URL and storing that into a given Redis db.
class ShortIsBetter::Url
  # The default length of the hashed version of an url.
  MINIMUM_SHORT_URL_LENGTH = 4

  # Reserved URLs are parts of the URL that are reserved for the API (e.g.
  # '/api') and can't be used as hashes.
  RESERVED_URLS = %w(api)

  ALLOWED_CHARS = (
    ('a'..'z').to_a +
    ('A'..'Z').to_a +
    (0..9).to_a -
    %w(0 O I l)
  )

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
  def hashed(length, charset = ALLOWED_CHARS)
    @hex_digest ||= Digest::MD5.hexdigest(@long)
    @stream ||= MothereffingBases[@hex_digest].in_hex.to_base(charset)

    @stream.slice(0, length)
  end

  # Shorten the current URL. If the same URL is in the database, it'll have the
  # same hash and that will be used. If the hash has already been used but on a
  # different URL (*very* little probability), the same hash but longer will be
  # used.
  # @param [Fixnum] length The lenght of the underlying hash, which is not
  #   strictly related to the lenght of the shortened URL.
  # @return [String] The newly created short url
  def shorten(length = MINIMUM_SHORT_URL_LENGTH)
    short = hashed(length)

    shorten(length + 1) if RESERVED_URLS.include?(short)

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
