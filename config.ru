require 'bundler/setup'
Bundler.require(:default)
require_relative 'lib/short_is_better'

use Rack::Reloader, 0

run Rack::Cascade.new([
  ShortIsBetter::Api,
  ShortIsBetter::MainServer
])
