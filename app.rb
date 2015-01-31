require 'sinatra'
require 'json'
require 'haml'
require 'net/http'
require 'logger'

configure do
	set :environment, :development
	set :public_folder, File.dirname(__FILE__) + '/public'
	set :views, File.dirname(__FILE__) + '/views'

	# Latitude and longtitude for Thunder Bay, Ontario, Canada
	set :lat, 48.4025585
	set :long, -89.2719957

	set :logger, Logger.new('log.txt')
end

helpers do
	def getAPIKey
		key = File.read('apikey.txt')
	end

	def getCache
		if not File.exists?('cache.json') then
			settings.logger.warn("Cache doesn't exist. Writing new cache with current data.")

			writeCache(getWeatherFromServer())
		end

		File.open('cache.json', 'r')
	end

	def writeCache(contents)
		File.open('cache.json', 'w') do |f|
			f.write(contents)
		end

		settings.logger.info("Cache written with new data.")
	end

	def getWeatherFromServer
		apiKey = getAPIKey()

		uri = URI("https://api.forecast.io/forecast/#{apiKey}/#{settings.lat},#{settings.long}?units=si")
		response = Net::HTTP.get_response(uri)

		return response.body

		settings.logger.info("Weather information retrieved from ForecastIO server.")
	end

	def getWeatherData
		cache = getCache()

		elapsedTime = (Time.now - cache.ctime) / 60 # In minutes

		if elapsedTime > 2 then
			settings.logger.info("Cache data out of date. Retrieving fresh information.")

			writeCache(getWeatherFromServer())
		end

		data = JSON.parse(cache.read)

		cache.close
		return data
	end

	def weather(*args)
		weatherData = getWeatherData()

		args.each do |arg|
			weatherData = weatherData[arg]
		end

		return weatherData
	end
end

get '/' do
	haml :index
end