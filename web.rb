require 'sinatra'
require 'json'
require 'net/http'
require 'aws/s3'
require 'mechanize'

if File.exists?("heroku_env.rb")
  heroku_env = File.open("heroku_env.rb")
  load(heroku_env)
end


def awsConnect
  AWS::S3::Base.establish_connection!(
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
  )
end

def getMechData
  a = Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
  }

  #a.get('http://google.com/') do |page|
  a.get('http://marinetraffic.com/ais/') do |page|
    #puts "trying to load, got page:"
    #puts page.body
           
    a.get('http://marinetraffic.com/ais/getjson.aspx?sw_x=4&sw_y=51.8&ne_x=4.6000000000000005&ne_y=52&zoom=12&fleet=&station=0',[],page) do |jsonpage|
      str = jsonpage.body
      str.gsub!(",,",",0,")
      str.gsub!("--","0")
      ["\\","\a","\b","\r","\n","\s","\t"].each { |s| str.gsub!(s,"") }
      return str
    end

  end
 

end

def getFi
  key = "46714.MKs6jdB7j9MB6ol"
  #url = "http://api.aprs.fi/api/get?name=M6LZX-A&what=loc&apikey="+key+"&format=json"
  url = "http://aprs.fi/xml2?n=jngrt&box=51.65131,3.47322,52.25897,5.00032" #&rid=41913-8243&winid=U2bgNj2P&timerange=3600&lastupd=1351109359&oth=1"
  #resp = Net::HTTP.get_response(URI.parse(url))
  #resp.body
  http = Net::HTTP.new("aprs.fi")
  req = Net::HTTP::Get.new("xml2?n=jngrt&box=51.65131,3.47322,52.25897,5.00032&rid=41913-8243&winid=U2bgNj2P&timerange=3600&lastupd=1351109359&oth=1",{'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.94 Safari/537.4'})
  resp = http.request(req)
  resp.body

end

def getShipData
  
  #url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=3&sw_y=51&ne_x=5&ne_y=53&zoom=10&fleet=&station=0"
  #url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=3&sw_y=51&ne_x=5&ne_y=53&zoom=13&fleet=&station=0"
  #url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=4&sw_y=51.8&ne_x=4.6&ne_y=53&zoom=13&fleet=&station=0"
  #url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=4&sw_y=51.8&ne_x=5&ne_y=52.2&zoom=10&fleet=&station=0"
  url = '/ais/getjson.aspx?sw_x=4&sw_y=51.8&ne_x=4.6000000000000005&ne_y=52&zoom=12&fleet=&station=0' 
  http = Net::HTTP.new("marinetraffic.com")
  req = Net::HTTP::Get.new(url,{'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.94 Safari/537.4'})
  resp = http.request(req)
  #resp = Net::HTTP.get_response(URI.parse(url))
  str = resp.body
  str.gsub!(",,",",0,")
  #["\"","\\","\a","\b","\r","\n","\s","\t"].each { |s| str.gsub!(s,"") }
  str
end

def refreshData
  jsonstr = getMechData

  if jsonstr.length > 2000 #make sure we have enough json data, otherwise fall back
    AWS::S3::S3Object.store("data.json",jsonstr,ENV['AWS_BUCKET'])
  else
    @error = "json data not long enough:"+jsonstr;
  end
end


get '/' do
  awsConnect
  
  if AWS::S3::S3Object.exists? "data.json", ENV['AWS_BUCKET']
    s3file = AWS::S3::S3Object.find "data.json", ENV['AWS_BUCKET']
    mod = DateTime.parse s3file.about['last-modified']
    if mod < DateTime.now - (0.25/24.0)
      refreshData
    end
  end

  if AWS::S3::S3Object.exists? "data.json", ENV['AWS_BUCKET']
    return AWS::S3::S3Object.value "data.json", ENV['AWS_BUCKET']
  else
    return "file not found"
  end 

end

get '/read' do
  awsConnect
  AWS::S3::S3Object.value "data.json", ENV['AWS_BUCKET']
end

get '/date' do
  awsConnect
  if AWS::S3::S3Object.exists? "data.json", ENV['AWS_BUCKET']
    s3file = AWS::S3::S3Object.find "data.json", ENV['AWS_BUCKET']
    mod = DateTime.parse s3file.about['last-modified']
    return mod.strftime("%d-%m-%Y %R")
  end
  "file not found"
end

get '/refresh' do
  awsConnect
  refreshData
  if defined? @error
    return @error
  else
    return "refresh done"
  end
end

get '/test' do
  awsConnect
  str = AWS::S3::S3Object.value "data.json", ENV['AWS_BUCKET']
begin
  json = JSON.parse(str)
rescue JSON::ParserError => e
  return e.to_s
end

  return 'valid json: \n'+json.to_s
end
    
