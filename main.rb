require 'rubygems'
require 'sinatra'
require 'pry'

# use Rack::Session::Cookie, :key => 'rack.session',
#                            :path => '/',
#                            :secret => '12345' 

set :sessions, true

helpers do
  BLACKJACK = 21
  CARD_VALUES = {'2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6, '7' => 7, '8' => 8, '9' => 9, '10' => 10, 'J' => 10, 'Q' => 10, 'K' => 10, 'A' =>11}
  
  def total(cards)
    total = 0
    cards.each do |card|
      total += CARD_VALUES[card[1]]
    end

    cards.each do |card|
      total -= 10 if total > 21 && card.include?('A')
    end
    total
  end

  def find_suit(suit)
    case suit
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'S' then 'spades'
      when 'C' then 'clubs'
    end
  end

  def find_value(value)
    case value
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'A' then 'ace'
      else value
    end
  end

  def get_image(card)
    suit = find_suit(card[0])
    value = find_value(card[1])
    "#{suit}_#{value}.jpg"
  end
end

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
  if session[:player_name].empty?
    redirect '/'
  else
    erb :bet
  end
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

post '/hit' do
  session[:dealer_cards] << session[:deck].pop
  erb :play
end   

get '/play' do
  
  session[:player_turn] = 1
  if session[:player_name].empty?
    redirect '/'
  elsif session[:bet] == 0
    redirect '/bet'
  else
    SUITS = ['H','D','C','S']
    CARDS = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
    session[:deck] = SUITS.product(CARDS).shuffle!

    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    erb :play
  end
end