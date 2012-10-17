require 'sinatra'
require 'json'
require 'net/http'
require 'data_mapper'

#DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://test.sqlite')

DataMapper.setup(:default, ENV['DATABASE_URL'] ||
                 "sqlite3://#{Dir.pwd}/test.db")

class ShipData
  include DataMapper::Resource
  property :id, Serial
  property :json, Text
  property :created_at, DateTime
  property :updated_at, DateTime
end
DataMapper.auto_upgrade!
get '/test' do
  url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=3&sw_y=51&ne_x=5&ne_y=53&zoom=10&fleet=&station=0"
    resp = Net::HTTP.get_response(URI.parse(url))
    raw = resp.body
    clean = raw.gsub(",,",",0,")
    parsed = JSON.parse(clean)
    "raw:"+raw+"<br/><br/>clean:"+clean+"<br/><br/>json:"+parsed.inspect
end
get '/' do
  if ShipData.count == 0
  #xcoord = "4.60000000000005" + rand(1000).to_s
  #url = "http://marinetraffic.com/ais/getjson.aspx?"+
  #      "sw_x=3.8&sw_y=51.8&ne_x="+xcoord+
  #      "&ne_y=52&"+
  #      "zoom=12&fleet=&station=0"
    url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=3&sw_y=51&ne_x=5&ne_y=53&zoom=10&fleet=&station=0"
    resp = Net::HTTP.get_response(URI.parse(url))
    raw = resp.body
    clean = raw.gsub(",,",",0,")
    #check if parseable
    parsed = JSON.parse(clean)
    ship = ShipData.create(:json => clean )
    return clean
  else
    "got content:"+ShipData.first().json
  end
  #clean = raw.gsub(/,\s*,/ , ",0,")
#parsed = JSON.parse(clean);
end

get '/count' do
  "count:"+ShipData.count.to_s
end
get '/empty' do
  ShipData.all().destroy
end
