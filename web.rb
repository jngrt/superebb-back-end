require 'sinatra'
require 'json'
require 'net/http'
require 'data_mapper'

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

def getShipData
  #url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=3&sw_y=51&ne_x=5&ne_y=53&zoom=10&fleet=&station=0"
  #resp = Net::HTTP.get_response(URI.parse(url))
  #raw = resp.body
  #clean = raw.gsub(",,",",0,")
  #check if parseable
  #parsed = JSON.parse(clean)
  #return clean
  url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=3&sw_y=51&ne_x=5&ne_y=53&zoom=10&fleet=&station=0"
  resp = Net::HTTP.get_response(URI.parse(url))
  raw = resp.body
  clean = raw.gsub(",,",",0,")
end


get '/' do
  
  if ShipData.count > 0
    if ShipData.first.updated_at < DateTime.now - (2/24.0)
      jsonstr = getShipData()
      if jsonstr.length > 100
        ShipData.first().update(:json => jsonstr )
      end        
    end
  else
    jsonstr = getShipData()
    ShipData.create(:json => jsonstr)  
  end  
  ShipData.first().json
end

get '/count' do
  "count:"+ShipData.count.to_s
end
get '/empty' do
  ShipData.all().destroy
end
