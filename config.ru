require_relative './main'
require_relative 'lib/subdomain_mapper'

require 'rack/lobster'

for_subdomain /^api\./, run: Rack::Lobster.new
run ShortIsBetter::MainServer
