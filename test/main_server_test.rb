require_relative 'test_helper'

class MainServerTest < RackTest
  app ShortIsBetter::MainServer

  def setup
    load_fixtures!
  end
end
