# This class is the core  *Alert* object
# An Alert is based on a bus_line (aka -percorso-) and store 
# info about line stops, line number and user asking for alert

# Author::    Luca Arcara  (mailto:larcara@gmail.com)
# Copyright:: Copyright (c) 2014 Luca Arcara
# License::   Distributes under the same terms as Ruby

#
# Usage:
#  you can  add an alert by call Alert.add_alert(bus_line: 913, bus_stop: 75779, user: "@lucaa76")
#

require 'mongoid'
require_relative "./atac_proxy.rb"
require 'twitter'
Mongoid.load!("./config/mongoid.yml", "development")



class Alert
	# This class holds the letters in the original
	# word or phrase. The is_anagram? method allows us
	# to test if subsequent words or phrases are
	# anagrams of the original.
	# * *Args*    :
  #   - +_track_number+ -> the track number that identify the line
  # * *Returns* :
  #   - a new alert object. Initialize the staging and refresh the data
  # * *Raises* :
  #   - +ArgumentError+ -> if no argument
  #
	def initialize(_track_number=nil, _bus_line=nil, _stop_number=nil)
    raise ArgumentError, "_track_number must be specified" if [_track_number, _bus_line, _stop_number] == [nil,nil,nil]
    @alert=BusAlert.where(percorso: _track_number).first
    @alert||=BusAlert.where(bus_line: _bus_line).in(stops: _stop_number).first

    if @alert.nil?  # a new track ... initialize from Atac
      atac_proxy=AtacProxy.new()
      response=atac_proxy.get_stops(_track_number)
      raise ArgumentError, "_track_number isn't valid" if response.nil?
      _bus_line=response["percorso"]["id_linea"]
      stops=response["fermate"]

      raise ArgumentError, "_track_number isn't valid" if (stops.nil? || stops.size==0)

      @alert=BusAlert.create(bus_line: _bus_line, percorso: _track_number,
         stops: stops.map{|x| x["id_palina"]}, 
         stops_data: stops.inject({}){|m,c| m[c["id_palina"]]=c;m}
         #stops_data: stops.map{|x| x.delete("veicolo"); x.delete("stato_traffico"); x}
          ) 
    end

  end
  def stops
   @alert.stops
  end
  def alert_data
   @alert.alert_data
  end

  def destroy
    @alert.delete
  end
  # Add am user alert to monitor 3 stops
  # given an *Alert* -stops- save stops numbers: [7008, 7009, 7040, 7890, 7440]
  #
  # if you ask to monitor stop number 7890  it return ["@user", [7009, 7040, 7890] ]
  #
  # * *Args*    :
  #   - +stop_number+ -> the track number that identify the line
  #   - +user+ -> the twitter user name
  # * *Returns* :
  #   - a new alert object. Initialize the staging and refresh the data
  # * *Raises* :
  #   - +ArgumentError+ -> if no argument
  #
  def add_alert_data!(user, stops )
    @alert.add_alert_data(user, stops)
  end

  class BusAlert
    include Mongoid::Document
    #field :stop_number
    field :bus_line
    field :percorso
    field :stops, type: Array
    field :stops_data, type: Hash #{"nome_ricapitalizzato"=>"Augusto Imperatore", "nome"=>"AUGUSTO IMPERATORE", "stato_traffico"=>0, "id_palina"=>"70359", "soppressa"=>false}
    field :last_update, type: Date, default: Proc.new{Date.today}
    field :users, type: Array, default: []
    field :alert_data, type: Array, default: []

    def add_alert_data(user, stops)
      current_user_alert = [user, []]
      puts "current_user_alert : #{current_user_alert.inspect}"
      current_user_alert[1] +=  stops
      puts "new current_user_alert : #{current_user_alert.inspect}"
      self.add_to_set(alert_data: [current_user_alert])
      self.add_to_set(users: user)
      current_user_alert
    end
  end

  def self.add_alert(options={}) #line: params[:bus_line], stop: params[:bus_stop], user: @current_user
    puts "Start adding alert for #{options.inspect}"
   return options.map{|x| add_alert(x)} if options.is_a? Array 

   alert=Alert.get_alert(options)
   index= alert.stops.index(options[:bus_stop].to_s)
   raise ArgumentError, "invalid _stop number " if index.nil?
   # x= [ ["primo", 1, 2,3] , ["secondo", 5,6,7] ] -> x.asssoc("primo") => ["primo", 1, 2,3]
   user_data = []
   user_data << alert.stops[index]
   user_data << alert.stops[index-1] if index > 1
   user_data << alert.stops[index-2] if index > 2
   return  alert.add_alert_data!(options[:user], user_data)


  end

  def self.check_alert(cicle_count, debug=false,  &block)
  	atac=AtacProxy.new()
    response=[]
    final_result={}
    cicle_count.times do |i|
      final_result={}
      puts "..#{i}.."
      BusAlert.exists(alert_data: 1).each do |percorso|
        track_number=percorso["percorso"]
        final_result[track_number]={}
        puts "check line #{track_number}"
        response=atac.get_stops(track_number.to_i)
        next_bus=response["orari_partenza_vicini"]
        busses=[]
        response["fermate"].each {|x| busses << x["id_palina"] if x["veicolo"] }
        #puts busses.inspect if debug

        percorso.alert_data.each do |user|
          puts "#{user.inspect} <-> #{busses.inspect}" if debug
          user_stops=user[1].flatten
          coming_bus=(user_stops & busses)
          if coming_bus.size > 0
            puts "coming_bus: #{coming_bus}"
            puts "monitored_stop: #{user_stops.first}"
            #puts "stops_data: #{percorso["stops_data"]}"
            
            stop_name=percorso["stops_data"][user_stops.first]["nome"]
            result= [user[0], "bus #{percorso.bus_line} coming at #{stop_name} in #{user_stops.index(coming_bus.first)} stops!!!" ]
            if block_given?
              yield result
            else
              final_result[track_number][user]= result
            end
          end
        end
      end
      sleep 10
    end
    return final_result
  end
  def self.tweet_bus
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["CONSUMER_KEY"]
      config.consumer_secret     = ENV["CONSUMER_SECRET"]
      config.access_token        = ENV["YOUR_ACCESS_TOKEN"]
      config.access_token_secret = ENV["YOUR_ACCESS_SECRET"]
    end
    check_alert(100) {|user, message| client.update("#{user} #{message}")}
  end
  private
  # This method search for an alert based on track_number or [bus_line, bus_stop]
  # anagrams of the original.
  # * *Args*    :
  #   - +{bus_line, bus_stop, track_number}
  # * *Returns* :
  #   - an alert object.
  # * *Raises* :
  #   - +ArgumentError+ -> if no argument
  #
  def self.get_alert(options={})
    return Alert.new(options[:percorso]) unless options[:percorso].nil?
    a=AtacProxy.new()
    percorsi=a.get_percorsi(options[:bus_line])
    percorsi.each do |percorso|
      fermate=a.get_stops(percorso[0])
      fermate=fermate["fermate"].map{|x| x["id_palina"]}
      return Alert.new(percorso[0]) if fermate.include?(options[:bus_stop].to_s)
    end
    return nil
  end
  def self.get_alerts(username)
    data=BusAlert.in("users"=> [username]).to_a
    result={}

    data.each{|alert| result[alert["bus_line"]]=alert["alert_data"].map{|data| data[1] if data[0]==username}}
    return result
  end
end
