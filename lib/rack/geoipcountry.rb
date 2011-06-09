require 'geoip'

module Rack

  class GeoIPCountry
    def initialize(app, options = {})
      options[:file] ||= 'GeoIP.dat'
      options[:data_file_path] ||= "/usr/local/share/GeoIP/"
      data_file = ::File.join(options[:data_file_path], options[:file])
      options[:method] ||= false
      options[:field] ||= 'REMOTE_ADDR'
      @db = GeoIP.new(data_file)
      @options = options
      @app = app
    end

    def call(env)
      address = @options[:method] ? Request.new(env)[@options[:field]] : env[:field]

      res = @db.country(address)
      if !res.nil?
        env['X_GEOIP_MATCHED'] = 1
        env['X_GEOIP_COUNTRY_CODE'] = res['country_code2']
        env['X_GEOIP_COUNTRY_CODE3'] = res['country_code3']
        env['X_GEOIP_COUNTRY'] = res['country_name']
        env['X_GEOIP_CONTINENT'] = res['continent_code']
        env['X_GEOIP_REGION'] = res['region_name']
        env['X_GEOIP_CITY'] = res['city_name']
        env['X_GEOIP_POSTAL_CODE'] = res['postal_code']
      else
        # prevent request header injection
        env.reject! { |key, value| key =~ /^X_GEOIP_/ }
        env['X_GEOIP_MATCHED'] = 0
      end

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
