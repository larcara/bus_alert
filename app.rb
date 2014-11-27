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

get 'remove_alert' do
  current_user!
  Alert.remove(@current_user, params[:percorso])

end

post '/add_alert' do
   current_user!
   percorso=params[:percorso]
   if percorso.nil? || percorso==""
    atac=AtacProxy.new
    @percorsi={}
    atac.get_percorsi(params[:bus_line]).each do |linea|
      @percorsi[linea[0]]= {capolinea: linea[1], stops: atac.get_stops(linea[0])}
    end
    @data=[]
    haml :home
   else
     percorso=percorso.split("|")
     Alert.add_alert(bus_line: params[:bus_line], bus_stop: percorso[1], user: @current_user)
     redirect to("/alerts")
   end
end

get '/auth/twitter/callback' do
  if auth=env['omniauth.auth']
    puts auth.inspect
    puts auth.info.inspect
    session[:username]="@#{auth.info.nickname}"
    redirect to("/alerts") unless session[:username].nil?
    return
  end
  halt(401,'Not Authorized')
end

get '/auth/failure' do
  params[:message]
end

def current_user!
  if session[:username].nil?
    redirect to("/login")
  else
    @current_user=session[:username]
    @data = Alert.get_alerts(session[:username])

  end

end

