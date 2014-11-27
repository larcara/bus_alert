require "sinatra"
require "sinatra/reloader" if development?
require "haml"
require "less"
require 'therubyracer'
require 'mongoid'
require 'omniauth-twitter'
require_relative "./atac_proxy.rb"
require_relative "./alert.rb"
require 'json/ext' # required for .to_json
Mongoid.load!("./config/mongoid.yml")

set :port, 8080
set :bind, '0.0.0.0'
set :sessions, true




use OmniAuth::Builder do
  consumer_key=ENV["CONSUMER_KEY"]
  consumer_secret=ENV["CONSUMER_SECRET"]
  provider :twitter, consumer_key, consumer_secret
end




enable :sessions


get "/" do
  redirect to("/alerts")
end


get '/login' do
  redirect to("/auth/twitter")
end

get '/logout' do
  session[:username]  = nil
end

get '/alerts' do
	current_user!
  @data = Alert.get_alerts(session[:username])
  # a=AtacProxy.new()
  # @percorsi=a.get_percorsi("913")
  # @percorsi.each do |percorso|
  #    puts percorso[0]
  #    @fermate=a.get_stops(percorso[0])
  #    puts @fermate["percorso"].inspect
  #    puts @fermate["percorsi"].inspect
  #    puts @fermate["orari_partenza_vicini"].inspect
  #    puts "--------------"
  #    @fermate["fermate"].each do |fermata|
  #     puts fermata.inspect
  #     puts "........"
  #    end
  #  end
  # return ""
  haml :home
end

get '/add_alert' do
   current_user!
   @percorsi=[]
   haml :add_alert
end

post '/add_alert' do
   current_user!
   Alert.add_alert(line: params[:bus_line], stop: params[:bus_stop], user: @current_user)
   redirect to("/alerts")
end

get '/auth/twitter/callback' do
  if auth=env['omniauth.auth']
    puts auth.inspect
    puts auth.info.inspect
    session[:username]="@#{auth.info.nickname}"
    puts session[:username]
    redirect to("/alerts") unless session[:username].nil?
    return
  end
  halt(401,'Not Authorized')
end

get '/auth/failure' do
  params[:message]
end

def current_user!
 redirect to("/login") if session[:username].nil?

end

