require 'sinatra'
require 'json'
require 'net/http'

get '/' do
  xcoord = "4.60000000000005" + rand(1000).to_s
  #url = "http://marinetraffic.com/ais/getjson.aspx?"+
  #      "sw_x=3.8&sw_y=51.8&ne_x="+xcoord+
  #      "&ne_y=52&"+
  #      "zoom=12&fleet=&station=0"
  url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=3&sw_y=51&ne_x=5&ne_y=53&zoom=10&fleet=&station=0"
  resp = Net::HTTP.get_response(URI.parse(url))
  raw = resp.body
  #clean = raw.sub(",,",",0,")
  #clean = raw.gsub(/,\s*,/ , ",0,")
#parsed = JSON.parse(clean);
end
