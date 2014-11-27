
require 'net/http'
require_relative "./lib/xmlrpc/client"

#API_KEY="TTU8rKwDFEN4uL4iuyO9wlNDTJE78kXR"
API_KEY='bL5fwQZNDFdHkIR1hjxYCFIBrVRV78Hw'



class AtacProxy
	attr_accessor :token, :service_paline , :service_percorso
	def initialize(_token="")
		XMLRPC::Config.module_eval do
			    remove_const :ENABLE_NIL_PARSER
			    const_set :ENABLE_NIL_PARSER, true
		end
		autenticazione    =  XMLRPC::Client.new("muovi.roma.it", "/ws/xml/autenticazione/1", 80)
		@service_paline   =  XMLRPC::Client.new("muovi.roma.it", "/ws/xml/paline/7", 80)	
		@service_percorso =  XMLRPC::Client.new("muovi.roma.it", "/ws/xml/percorso/2", 80)
		
		if _token.blank?
			begin
			puts "Creating new client"
			@token = autenticazione.call("autenticazione.Accedi", API_KEY, '')
			
		rescue XMLRPC::FaultException => e
		  puts "Error:"
		  puts e.faultCode
		  puts e.faultString
		end		
		else
		@token=_token
		end
	end

	def search_path(from, to )
	  #https://bitbucket.org/agenziamobilita/muoversi-a-roma/wiki/percorso.Cerca
	  path = @service_percorso.call("percorso.Cerca", @token,  from, to, {mezzo: 1, piedi: 0, bus:true, metro:false, ferro:false, carpooling:false, max_distanza_bici:0 },Time.now.strftime("%Y-%m-%d %H:%M:%S"), "IT")
  end

  # get stops of a bus track line
  #
  # * *Args*    :
  #   - +track number+
  #   - +bus_number+ (to track a particoular bus)
  #   - +date+ (to have prevision for a particular date DD-MM-YYYY)
  # * *Returns* :
  #   - {"percorso"=>{"id_percorso"=>"53121", "arrivo"=>"Augusto Imperatore", "carteggio"=>"", "id_linea"=>"913", "abilitata"=>1, "id_news"=>-1,
  #             "gestore"=>"Atac", "carteggio_dec"=>"", "descrizione"=>nil}, "no_orari"=>false, "note_no_orari"=>"",
  # "orari_partenza_vicini"=>[#<XMLRPC::DateTime:0x000000035635d0 @year=2014, @month=11, @day=27, @hour=16, @min=6, @sec=0>,
  # #<XMLRPC::DateTime:0x00000003561d70 @year=2014, @month=11, @day=27, @hour=16, @min=12, @sec=0>,
  # #<XMLRPC::DateTime:0x00000003560ab0 @year=2014, @month=11, @day=27, @hour=16, @min=18, @sec=0>,
  # #<XMLRPC::DateTime:0x00000003567720 @year=2014, @month=11, @day=27, @hour=16, @min=24, @sec=0>,
  # #<XMLRPC::DateTime:0x00000003566190 @year=2014, @month=11, @day=27, @hour=16, @min=30, @sec=0>], "abilitato"=>1,
  # "percorsi"=>[   {"id_percorso"=>"53121", "arrivo"=>"Augusto Imperatore", "carteggio"=>"", "id_linea"=>"913", "abilitata"=>1, "id_news"=>-1,
  # "gestore"=>"Atac", "carteggio_dec"=>"", "descrizione"=>nil},
  #                    {"id_percorso"=>"55479", "arrivo"=>"Staz.ne Monte Mario (FS-FL3)", "carteggio"=>"", "id_linea"=>"913",
  #       "abilitata"=>true, "id_news"=>-1, "gestore"=>"Atac", "carteggio_dec"=>"", "descrizione"=>nil}],
  #   "fermate"=>[{"nome_ricapitalizzato"=>"Staz.ne Monte Mario (FS-FL3)", "nome"=>"STAZ.NE MONTE MARIO (FS-FL3)", "stato_traffico"=>0, "id_palina"=>"73492", "soppressa"=>false, "veicolo"=>{"lat"=>41.93904649900723, "lon"=>12.421159102376864, "id_veicolo"=>"5410", "id_prossima_palina"=>"73492"}}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Chiarugi V.", "id_palina"=>"76934", "soppressa"=>false, "nome"=>"CHIARUGI V."}, {"nome_ricapitalizzato"=>"Trionfale/S. Maria Della Pieta' (H)", "nome"=>"TRIONFALE/S. MARIA DELLA PIETA' (H)", "stato_traffico"=>3, "id_palina"=>"75741", "soppressa"=>false, "veicolo"=>{"lat"=>41.941265307771765, "lon"=>12.420188375363207, "id_veicolo"=>"3152", "id_prossima_palina"=>"75741"}}, {"stato_traffico"=>4, "nome_ricapitalizzato"=>"Acquedotto Del Peschiera/Trionfale", "id_palina"=>"81829", "soppressa"=>false, "nome"=>"ACQUEDOTTO DEL PESCHIERA/TRIONFALE"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Acquedotto Del Peschiera", "id_palina"=>"00308", "soppressa"=>false, "nome"=>"ACQUEDOTTO DEL PESCHIERA"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Trionfale/Pineta Sacchetti", "id_palina"=>"80439", "soppressa"=>false, "nome"=>"TRIONFALE/PINETA SACCHETTI"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Trionfale/Universita' Cattolica Sacro Cuore", "id_palina"=>"80440", "soppressa"=>false, "nome"=>"TRIONFALE/UNIVERSITA' CATTOLICA SACRO CUORE"}, {"nome_ricapitalizzato"=>"Trionfale/Monte Gaudio", "nome"=>"TRIONFALE/MONTE GAUDIO", "stato_traffico"=>3, "id_palina"=>"75750", "soppressa"=>false, "veicolo"=>{"lat"=>41.93479792494869, "lon"=>12.432791806058129, "id_veicolo"=>"3082", "id_prossima_palina"=>"75750"}}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Trionfale/Fani", "id_palina"=>"75751", "soppressa"=>false, "nome"=>"TRIONFALE/FANI"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Trionfale/Cervinia", "id_palina"=>"75752", "soppressa"=>false, "nome"=>"TRIONFALE/CERVINIA"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Trionfale/Pennestri", "id_palina"=>"75753", "soppressa"=>false, "nome"=>"TRIONFALE/PENNESTRI"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Trionfale/Camilluccia", "id_palina"=>"75754", "soppressa"=>false, "nome"=>"TRIONFALE/CAMILLUCCIA"}, {"stato_traffico"=>4, "nome_ricapitalizzato"=>"Prisciano/Trionfale", "id_palina"=>"75755", "soppressa"=>false, "nome"=>"PRISCIANO/TRIONFALE"}, {"stato_traffico"=>4, "nome_ricapitalizzato"=>"Prisciano/Medaglie D'oro", "id_palina"=>"77574", "soppressa"=>false, "nome"=>"PRISCIANO/MEDAGLIE D'ORO"}, {"stato_traffico"=>4, "nome_ricapitalizzato"=>"Medaglie D'oro/Tito Livio", "id_palina"=>"75760", "soppressa"=>false, "nome"=>"MEDAGLIE D'ORO/TITO LIVIO"}, {"stato_traffico"=>4, "nome_ricapitalizzato"=>"Medaglie D'oro/Romagnoli", "id_palina"=>"75767", "soppressa"=>false, "nome"=>"MEDAGLIE D'ORO/ROMAGNOLI"}, {"stato_traffico"=>4, "nome_ricapitalizzato"=>"Medaglie D'oro/Publio Stazio", "id_palina"=>"75768", "soppressa"=>false, "nome"=>"MEDAGLIE D'ORO/PUBLIO STAZIO"}, {"stato_traffico"=>4, "nome_ricapitalizzato"=>"Medaglie D'oro/Svetonio", "id_palina"=>"75770", "soppressa"=>false, "nome"=>"MEDAGLIE D'ORO/SVETONIO"}, {"nome_ricapitalizzato"=>"Medaglie D'oro/Marziale", "nome"=>"MEDAGLIE D'ORO/MARZIALE", "stato_traffico"=>4, "id_palina"=>"75772", "soppressa"=>false, "veicolo"=>{"lat"=>41.91273567098955, "lon"=>12.443657929874673, "id_veicolo"=>"3168", "id_prossima_palina"=>"75772"}}, {"stato_traffico"=>4, "nome_ricapitalizzato"=>"Medaglie D'oro/Montezemolo", "id_palina"=>"75773", "soppressa"=>false, "nome"=>"MEDAGLIE D'ORO/MONTEZEMOLO"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Doria A./Mocenigo", "id_palina"=>"74294", "soppressa"=>false, "nome"=>"DORIA A./MOCENIGO"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Doria A./L.go Trionfale", "id_palina"=>"74295", "soppressa"=>false, "nome"=>"DORIA A./L.GO TRIONFALE"}, {"nome_ricapitalizzato"=>"Giulio Cesare/Ottaviano (MA)", "nome"=>"GIULIO CESARE/OTTAVIANO (MA)", "stato_traffico"=>3, "id_palina"=>"72805", "soppressa"=>false, "veicolo"=>{"lat"=>41.90922593291631, "lon"=>12.457280855950742, "id_veicolo"=>"3086", "id_prossima_palina"=>"72805"}}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Giulio Cesare/Fabio Massimo", "id_palina"=>"72843", "soppressa"=>false, "nome"=>"GIULIO CESARE/FABIO MASSIMO"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Giulio Cesare/Ezio", "id_palina"=>"72847", "soppressa"=>false, "nome"=>"GIULIO CESARE/EZIO"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Marcantonio Colonna", "id_palina"=>"77832", "soppressa"=>false, "nome"=>"MARCANTONIO COLONNA"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Cicerone/Plinio", "id_palina"=>"70258", "soppressa"=>false, "nome"=>"CICERONE/PLINIO"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Cicerone/Cavour", "id_palina"=>"70259", "soppressa"=>false, "nome"=>"CICERONE/CAVOUR"}, {"stato_traffico"=>3, "nome_ricapitalizzato"=>"Vittoria Colonna", "id_palina"=>"70261", "soppressa"=>false, "nome"=>"VITTORIA COLONNA"}, {"nome_ricapitalizzato"=>"Augusto Imperatore", "nome"=>"AUGUSTO IMPERATORE", "stato_traffico"=>3, "id_palina"=>"70359", "soppressa"=>false, "veicolo"=>{"lat"=>41.905014045078254, "lon"=>12.473847035223601, "id_veicolo"=>"3134", "id_prossima_palina"=>"70359"}}]

  #   - [[track_number, last_stop_name]]
  # * *Raises* :
  #   - none
  #   - +ArgumentError+ -> if no argument
  #
	def get_stops(percorso, mezzo="", data="" )
		#puts ["paline.Percorso", @token,  percorso, mezzo, data, "IT"]
		begin
      stops = @service_paline.call("paline.Percorso", @token,  percorso.to_s, mezzo, data, "IT")
		  return stops["risposta"]
    rescue  XMLRPC::FaultException => e
      puts "Error:"
      puts e.faultCode
      puts e.faultString
      return nil
    end
	end
	def get_linee(palina)
       begin
	   	linee = @service_paline.call("paline.PalinaLinee", @token,  palina,  "IT")
	   	return linee["risposta"]
	   rescue  XMLRPC::FaultException => e
		  puts "Error:"
		  puts e.faultCode
		  puts e.faultString
	   linee = []
           end
  end
  def previsioni(palina)
       begin
         previsioni = @service_paline.call("paline.Previsioni", @token,  palina,  "IT")
	   return previsioni["risposta"]
	   rescue  XMLRPC::FaultException => e
		  puts "Error:"
		  puts e.faultCode
		  puts e.faultString
	   linee = []
           end
  end


  # get tracks (tipically 2) of a bus line
  #
  # * *Args*    :
  #   - +line+ -> the bus line ex 913
  # * *Returns* :
  #   - [[track_number, last_stop_name]]
  # * *Raises* :
  #   - none
  #   - +ArgumentError+ -> if no argument
  #
	def get_percorsi(linea)
		puts "get perscorsi per #{linea}"
	   begin
		linee = @service_paline.call("paline.Percorsi", @token,  linea,  "IT")
		return linee["risposta"]["percorsi"].map{|x| [x["id_percorso"], x["capolinea"]]}
	   rescue  XMLRPC::FaultException => e
		  puts "Error:"
		  puts e.faultCode
		  puts e.faultString
	   	linee = []
    end
	end

	def smart_search(query)
		result = @service_paline.call("paline.SmartSearch", @token, query)
	end
end
