require 'rack'
require 'rack/test'
require 'rack/geoipcountry'

class Riot::Situation
  include Rack::Test::Methods
  def app
    @app
  end
end


class Riot::Context
  def geoip_app(config)
    Rack::Builder.new {
      use Rack::CommonLogger
      use Rack::GeoIPCountry config

      map "/" do
        run -> env { [200, { "Content-Length" => "4" }, ['Ohai']] }
      end
    }.to_app
  end

  def app(app=nil, &block)
    setup { @app = (app || block.call) }
  end
end

class Riot::Context
  def app(app=nil, &block)
    setup { @app = (app || block.call) }
  end
end

context "Geo location lookup" do
  geoip_app({:data_file => "/me/no/existy"})

  setup do
    get("/", { "client_ip" => "8.8.8.8" })
    last_response
  end
  asserts(:status).equals(200)
  asserts(:body).equals("Ohai")
end
