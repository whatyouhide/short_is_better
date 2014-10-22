class SubdomainMapper
  def initialize(next_app, regex_filter, app_to_run = nil, &block)
    fail ArgumentError if app_to_run && block_given?

    @next_app = next_app
    @regex_filter = regex_filter
    @dsl_block = block
    @app_to_run = app_to_run
  end

  def call(env)
    @request = Rack::Request.new(env)

    if @request.host =~ @regex_filter
      if @app_to_run
        @app_to_run.call(env)
      else
        app = Rack::Builder.new(&@dsl_block)
        app.call(env)
      end
    else
      @next_app.call(env)
    end
  end
end

class Rack::Builder
  def for_subdomain(regex, opts, &block)
    use(SubdomainMapper, regex, opts[:run], &block)
  end
end
