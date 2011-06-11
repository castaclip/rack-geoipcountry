require 'rack'
require 'rack/test'
require 'rack/geoipcountry'
require 'pp'

class Riot::Context
  def app(app=nil, &block)
    setup { @app = (app || block.call) }
  end

  def geoip_app(options = {})
    Rack::Builder.new {
      use Rack::CommonLogger
      use Rack::GeoIPCountry, options
      map "/" do
        run -> env { [200, { "Content-Length" => "4" }, ["Yay."]] }
      end
    }.to_app
  end
end

class Riot::Situation
  include Rack::Test::Methods
  def app
    @app
  end
end

context "Geo location lookup" do
  context "with default settings" do
    app { geoip_app() }

    setup do
      get("/", {}, {'REMOTE_ADDR' => "8.8.8.8"})
      last_request.env
    end

    asserts("match field")            { topic["X_GEOIP_MATCHED"] }.equals("1")
    asserts("matched IP in header")   { topic["X_GEOIP_MATCHING_ADDRESS"] }.equals("8.8.8.8")
    asserts("correct country code")   { topic["X_GEOIP_COUNTRY_CODE"] }.equals("US")
    asserts("correct country code")   { topic["X_GEOIP_COUNTRY_CODE3"] }.equals("USA")
    asserts("correct country")        { topic["X_GEOIP_COUNTRY"] }.equals("United States")
    asserts("correct continent")      { topic["X_GEOIP_CONTINENT"] }.equals("NA")
    asserts("correct region")         { topic["X_GEOIP_REGION"] }.equals("CA")
    asserts("correct city")           { topic["X_GEOIP_CITY"] }.equals("Mountain View")
    asserts("correct postal code")    { topic["X_GEOIP_POSTAL_CODE"] }.equals("94043")
  end

  context "with custom ip field in header" do
    app { geoip_app({:header_field => "my_custom_ip"}) }

    setup do
      get("/", {}, {'my_custom_ip' => "8.8.8.8", 'REMOTE_ADDR' => "10.0.0.1"})
      last_request.env
    end

    asserts("matches existing IP"){topic["X_GEOIP_MATCHED"]}.equals("1")
    asserts("matches existing IP"){topic["X_GEOIP_MATCHING_ADDRESS"]}.equals("8.8.8.8")
  end


  context "with custom GET parameter" do
    app { geoip_app({:param_name => "my_custom_ip"}) }

    setup do
      get("/", {'my_custom_ip' => "8.8.8.8"}, {'REMOTE_ADDR' => "10.0.0.1"})
      last_request.env
    end

    asserts("matches existing IP"){topic["X_GEOIP_MATCHED"]}.equals("1")
    asserts("matches existing IP"){topic["X_GEOIP_MATCHING_ADDRESS"]}.equals("8.8.8.8")
  end

  context "with custom POST parameter" do
    app { geoip_app({:param_name => "my_custom_ip"}) }

    setup do
      post("/", {'my_custom_ip' => "8.8.8.8"}, {'REMOTE_ADDR' => "10.0.0.1"})
      last_request.env
    end

    asserts("matches existing IP"){topic["X_GEOIP_MATCHED"]}.equals("1")
    asserts("matches existing IP"){topic["X_GEOIP_MATCHING_ADDRESS"]}.equals("8.8.8.8")
  end
end


context "HTTP header injection" do
  context "is prevented" do
    app { geoip_app() }

    setup do
      get("/", {}, {'X_GEOIP_MATCHED' => "1", 'X_GEOIP_COUNTRY_CODE' => "FTW", 'X_GEOIP_MATCHING_ADDRESS' => "133.7.133.7", 'REMOTE_ADDR' => "10.0.0.1"})
      last_request.env
    end

    asserts("match field") { topic["X_GEOIP_MATCHED"] }.equals("0")
    asserts("IP in header is corrected") { topic["X_GEOIP_MATCHING_ADDRESS"] }.equals("10.0.0.1")
    asserts("country code") { topic["X_GEOIP_COUNTRY_CODE"] }.nil
  end
end

context "IETF draft geo header" do
  context "is added by default" do
    app { geoip_app() }

    setup do
      get("/", {}, {'REMOTE_ADDR' => "8.8.8.8"})
      last_request.env
    end

    asserts("Geo-Country") { topic["Geo-Country"] }.equals("US")
    asserts("Geo-Location") { topic["Geo-Location"] }.equals("37.41919999999999;-122.0574")
  end
end
context "can be removed at will" do
  context "can be removed at will" do
    app { geoip_app({ :geo_header => false }) }

    setup do
      get("/", {}, {'REMOTE_ADDR' => "8.8.8.8"})
      last_request.env
    end

    asserts("Geo-Country") { topic["Geo-Country"] }.nil
    asserts("Geo-Location") { topic["Geo-Location"] }.nil
  end
end
