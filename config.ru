require_relative './main'

use Rack::Domain, /^api\./, run: Api
run MainServer
