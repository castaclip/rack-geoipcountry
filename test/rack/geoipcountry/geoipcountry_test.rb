require 'rack'
require 'rack/test'

class Riot::Situation
  include Rack::Test::Methods
  def app
    @app
  end
end


class Riot::Context
  def app
    Rack::Builder.new {
      use Rack::CommonLogger
      use Rack::GeoIPCountry, :data_file => "/usr/local/share/GeoIP/GeoLiteCity.dat", :method => "GET", :field => "client_ip"
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
  setup do
    get("/", { "client_ip" => "8.8.8.8" })
    last_response
  end
  asserts(:status).equals(200)
  asserts(:body).equals("Ohai")
end
