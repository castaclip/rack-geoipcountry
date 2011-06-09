Rack::GeoIPCountry uses the geoip gem and the GeoIP database to lookup the country of a request by its IP address
The database can be downloaded from:
http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz

Usage
=====

use Rack::GeoIPCountry, :data_file => "/path/to/GeoIP.dat"

Options
=======

  * data_file: path to the data file (defaults to "/usr/local/share/GeoIP/GeoCity.dat")
  * method: can be "GET" or "POST" and will get the IP address to use from the request
    (defaults to false which means that the IP address will be fetched from REMOTE_ADDR header field)
  * field: field name where the IP address is to be found (works in concert with the method option)

By default all requests are looked up and the `X_GEOIP_*` headers are added to the request
The headers can then be read in the application
The country name is added to the request header as `X_GEOIP_COUNTRY`, eg:
`X_GEOIP_COUNTRY`: United Kingdom

The full set of X_GEOIP_* request headers is below
==================================================

`X_GEOIP_COUNTRY_MATCHED` - If the GeoIP database could find a match for the IP address; 1 if yes, 0 if no

*If this field is 0 then all the other fields will be missing!*

`X_GEOIP_COUNTRY_CODE` - The ISO3166-1 two-character country code
`X_GEOIP_COUNTRY_CODE3` - The ISO3166-2 three-character country code
`X_GEOIP_COUNTRY` - The ISO3166 English-language name of the country, if not found set to "N/A"
`X_GEOIP_CONTINENT` - The two-character continent code, if not found set to --
`X_GEOIP_REGION` - The English-language name of the region, if not found set to "" (e.g. "CA")
`X_GEOIP_CITY` - The English-language name of the city, if not found set to "" (e.g. "Mountain View")
`X_GEOIP_POSTAL_CODE` - The postal code, if not found set to "" (e.g. "94043")


You can use the included Mapping class to trigger lookup only for certain requests by specifying matching path prefix in options, eg:
use Rack::GeoIPCountry::Mapping, :prefix => '/video_tracking'
The above will lookup IP addresses only for requests matching /video_tracking etc.

MIT License - Karol Hosiawa (http://twitter.com/hosiawak)
