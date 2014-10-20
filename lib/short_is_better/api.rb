require 'json'
require_relative 'url'
require_relative 'api/validators/correct_url'

class ShortIsBetter::Api < Grape::API
  version 'v1'
  format :json
  prefix :api

  helpers do
    def redis
      @redis ||= Redis.new
    end

    def shorten_and_set_status_code(long_url)
      url = ShortIsBetter::Url.new(long_url, redis)
      short_url = url.shorten
      url.created? ? status(201) : status(200)
      short_url
    end

    def save_custom_short_url!(short_url, long_url)
      # Throw a '409 Conflict' error if the `short_url` exists.
      if redis.exists(short_url)
        error!( { error: %("#{short_url}" is taken!) }, 409)
      else
        redis.set(short_url, long_url)
      end
    end
  end


  # POST /new
  desc <<-DESC
    Shorten a given URL using either a custom short URL (which will result in a
    409 Conflict error if taken) or a computer-generated URL.
  DESC

  params do
    requires :url,
      correct_url: true,
      desc: 'The URL you want to shorten'
    optional :short_url,
      desc: 'An optional custom short URL'
  end

  post :new do
    if params[:short_url].nil?
      short_url = shorten_and_set_status_code(params[:url])
    else
      save_custom_short_url!(params[:short_url], params[:url])
      status 201
      short_url = params[:short_url]
    end

    { short_url: short_url }
  end
end
