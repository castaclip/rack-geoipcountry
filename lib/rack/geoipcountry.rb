require 'geoip'

module Rack
  # Rack::GeoIPCountry uses the geoip gem and the GeoIP database to lookup the country of a request by its IP address
  # The database can be downloaded from:
  # http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
  #
  # Usage:
  # use Rack::GeoIPCountry, :file => "GeoIP.dat"
  #
  # Other options:
  #   * data_file_path: path to the data file (defaults to "/usr/local/share/GeoIP/")
  #   * method: can be "GET" or "POST" and will get the IP address to use from the request
  #     (defaults to false which means that the IP address will be fetched from REMOTE_ADDR header field)
  #   * field: field name where the IP address is to be found (works in concert with the method option)
  #
  # By default all requests are looked up and the X_GEOIP_* headers are added to the request
  # The headers can then be read in the application
  # The country name is added to the request header as X_GEOIP_COUNTRY, eg:
  # X_GEOIP_COUNTRY: United Kingdom
  #
  # The full set of GEOIP request headers is below:
  # X_GEOIP_COUNTRY_MATCHED - If the GeoIP database could find a match for the IP address; 1 if yes, 0 if no
  # If this field is 0 then all the other fields will be missing!
  # X_GEOIP_COUNTRY_CODE - The ISO3166-1 two-character country code
  # X_GEOIP_COUNTRY_CODE3 - The ISO3166-2 three-character country code
  # X_GEOIP_COUNTRY - The ISO3166 English-language name of the country, if not found set to "N/A"
  # X_GEOIP_CONTINENT - The two-character continent code, if not found set to --
  # X_GEOIP_REGION - The English-language name of the region, if not found set to "" (e.g. "CA")
  # X_GEOIP_CITY - The English-language name of the city, if not found set to "" (e.g. "Mountain View")
  # X_GEOIP_POSTAL_CODE - The postal code, if not found set to "" (e.g. "94043")

  #
  #
  # You can use the included Mapping class to trigger lookup only for certain requests by specifying matching path prefix in options, eg:
  # use Rack::GeoIPCountry::Mapping, :prefix => '/video_tracking'
  # The above will lookup IP addresses only for requests matching /video_tracking etc.
  #
  # MIT License - Karol Hosiawa ( http://twitter.com/hosiawak )
  class GeoIPCountry
    def initialize(app, options = {})
      default_options = {
        :data_file  => "/usr/local/share/GeoIP/GeoCity.dat",
        :field      => nil,
        :geo_header => true
      }
      @options = default_options.merge(options)
      @db = GeoIP.new(@options[:data_file])
      @app = app
    end

    def call(env)
      address = @options[:field] ? Request.new(env)[@options[:field]] : env['REMOTE_ADDR']

      res = @db.country(address)
      if !res.nil?
        env['X_GEOIP_MATCHED'] = '1'
        env['X_GEOIP_COUNTRY_CODE']  = res['country_code2']
        env['X_GEOIP_COUNTRY_CODE3'] = res['country_code3']
        env['X_GEOIP_COUNTRY']       = res['country_name']
        env['X_GEOIP_CONTINENT']     = res['continent_code']
        env['X_GEOIP_REGION']        = res['region_name']
        env['X_GEOIP_CITY']          = res['city_name']
        env['X_GEOIP_POSTAL_CODE']   = res['postal_code']

        if @options[:geo_header] == true
          env['Geo-Location']        = "#{res['latitude']};#{res['longitude']}"
          env['Geo-Country']         = res['country_code2']
        end
      else
        # prevent request header injection
        env.reject! { |key, value| key =~ /^X_GEOIP_/ }
        env['X_GEOIP_MATCHED'] = '0'
      end

      env['X_GEOIP_MATCHING_ADDRESS'] = address

      @app.call(env)
    end

    class Mapping
      def initialize(app, options = {})
        @app, @prefix = app, /^#{options.delete(:prefix)}/
        @geoip_country = GeoIPCountry.new(app, options)
      end

      def call(env)
        if env['PATH_INFO'] =~ @prefix
          @geoip_country.call(env)
        else
          @app.call(env)
        end
      end
    end
  end
end
