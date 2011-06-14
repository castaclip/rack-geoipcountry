require 'geoip'

module Rack
  module GeoIP
    class Matching
      def initialize(app, options = {})
        default_options = {
          :data_file  => "/usr/local/share/GeoIP/GeoCity.dat",
          :param_name => nil,
          :header_field => nil,
          :geo_header => true
        }
        @options = default_options.merge(options)
        @db = GeoIP.new(@options[:data_file])
        @app = app
      end


      def call(env)
        if @options[:param_name]
          address = Request.new(env)[@options[:param_name]]
        elsif @options[:header_field]
          address = env[@options[:header_field]]
        else
          address = env['REMOTE_ADDR']
        end

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
        env['X_GEOIP_MATCHING_ADDRESS'] = address

          if @options[:geo_header] == true
            env['Geo-Location']        = "#{res['latitude']};#{res['longitude']}"
            env['Geo-Country']         = res['country_code2']
          end
        else
          # prevent request header injection
          env.reject! { |key, value| key =~ /^X_GEOIP_/ }
          env['X_GEOIP_MATCHED'] = '0'
        end


        @app.call(env)
      end

      class Mapping
        def initialize(app, options = {})
          pp options
          @app, @prefix = app, /^#{options.delete(:prefix)}/
          @geoip_country = GeoIP.new(app, options)
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
end
