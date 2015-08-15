require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '12345' 

get '/' do
  erb :index
end

post '/user' do
  if params[:player_name].empty?
    redirect '/'
  else
    session[:player_name] = params[:player_name]
    session[:balance] = 500
    redirect '/bet'
  end
end

get '/bet' do
  erb :bet
end

post '/bet' do
  if params[:bet].empty?
    redirect '/bet'
  else
    session[:balance] -= params[:bet].to_i
    session[:bet] = params[:bet].to_i
    redirect '/play'
  end
end

get '/play' do
  erb :play
end