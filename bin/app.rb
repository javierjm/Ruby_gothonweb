require 'sinatra'
#require 'File'
require './lib/gothonweb/map.rb'

enable :sessions

set :port, 8080
set :static, true 
set :public_folder, "static"
set :views, "views"

get '/' do 
	session[:room] = 'START'
	redirect to('/game')
end

get '/game' do 
	room = Map::load_room(session)
			puts "loading room #{room}, for session: #{session}"

	if room 
		erb :show_room, :locals => {:room => room}
	else
		erb :you_died
	end
end

post '/game' do 
	room = Map::load_room(session)
	action = params[:action]

	if room 
		next_room = room.go(action) || room.go("*")
		if next_room
			Map::save_room(session, next_room)
		end
	else 
		erb :you_died
	end
end


get '/hello/' do
	erb :hello_form
end

get '/register/' do
	erb :register_form
end

post '/hello/' do
	greeting = params[:greeting] || 'Hi there'
	name = params[:name] || "Nobody"

	erb :index, :locals => {'greeting' => greeting, 'name'=>name}
end

post '/registered/' do 
	@filename = ''
	@path = ''
	if params[:image] && params[:image][:filename]
		filename = params[:image][:filename]
    	file = params[:image][:tempfile]
    	puts "File is: #{params[:image][:tempfile]}"
    	path = "./static/uploads/#{filename}"

	    # Write file to disk
	    File.open(path, 'wb') do |f|
	      f.write(file.read)
	    end
	end

	greeting = params[:greeting] || 'Hi there'
	name = params[:name] || "Nobody"

	erb :index, :locals => {'greeting' => greeting, 'name'=>name, 'filename'=>filename, 'path'=>path}

end 
