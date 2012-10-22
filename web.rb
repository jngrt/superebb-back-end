require 'sinatra'
require 'json'
require 'net/http'
require 'aws/s3'

heroku_env = File.open("heroku_env.rb")
load(heroku_env) if File.exists?(heroku_env)

def awsConnect
  AWS::S3::Base.establish_connection!(
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
  )
end

def getShipData
  url = "http://marinetraffic.com/ais/getjson.aspx?sw_x=3&sw_y=51&ne_x=5&ne_y=53&zoom=10&fleet=&station=0"
  resp = Net::HTTP.get_response(URI.parse(url))
  raw = resp.body
  clean = raw.gsub(",,",",0,")
end

def refreshData
  jsonstr = getShipData
  if jsonstr.length > 2000 #make sure we have enough json data, otherwise fall back
    AWS::S3::S3Object.store("data.json",jsonstr,ENV['AWS_BUCKET'])
  end
end

get '/' do
  awsConnect
  
  if AWS::S3::S3Object.exists? "data.json", ENV['AWS_BUCKET']
    s3file = AWS::S3::S3Object.find "data.json", ENV['AWS_BUCKET']
    mod = DateTime.parse s3file.about['last-modified']
    if mod < DateTime.now - (1.0/24.0)
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
    return mod.to_s
  end
  "file not found"
end
