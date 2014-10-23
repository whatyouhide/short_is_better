require_relative './main'

use Rack::Domain, /^api\./, run: ShortIsBetter::Api
run ShortIsBetter::MainServer
