require_relative './main'

use Rack::Reloader, 0

run Rack::Cascade.new([
  ShortIsBetter::Api,
  ShortIsBetter::MainServer
])
