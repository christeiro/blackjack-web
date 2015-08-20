require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '12345' 

helpers do
  BLACKJACK = 21
  DEALER_MIN = 17
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

  def blackjack?(card)
    total(card) == BLACKJACK and card.size == 2
  end

  def announce_winner(player_score, dealer_score)
    if dealer_score <= BLACKJACK && (dealer_score > player_score || player_score > BLACKJACK)
      "Dealer Wins"
    elsif player_score <= BLACKJACK && (player_score > dealer_score || dealer_score > BLACKJACK)
      "#{session[:player_name]} wins!"
    else
      "It's a tie"
    end
  end

  def check_winner_calculate_balance(player_hand, dealer_hand)
    if blackjack?(player_hand) && !blackjack?(dealer_hand)
      session[:balance] += session[:bet] + session[:bet] * 1.5
      @win = "#{session[:player_name]} wins with BLACKJACK."
    elsif !blackjack?(player_hand) && blackjack?(dealer_hand)
      @lost = "Dealer wins with BLACKJACK."
    elsif total(player_hand) > total(dealer_hand) || (total(player_hand) <= BLACKJACK && total(dealer_hand) > BLACKJACK)
      session[:balance] += session[:bet] * 2
      @win = "Player wins!"
    elsif total(player_hand) < total(dealer_hand) || (total(player_hand) > BLACKJACK && total(dealer_hand) <= BLACKJACK)
      @lost = "Dealer wins!"
    else
      @win = "It's a tie!"
      session[:balance] += session[:bet]
    end
    session[:game_started] = false
  end

end

get '/' do
  session[:game_started] = false
  session[:player_turn] = true
  erb :index  
end

post '/user' do
  if params[:player_name].empty?
    @error = 'Player name is required!'
    halt erb(:index)
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
    @error = 'Bet is required'
    erb :bet
  else
    session[:balance] -= params[:bet].to_i
    session[:bet] = params[:bet].to_i
    session[:game_over] = false
    redirect '/play'
  end
end

post '/game/*/*' do |participant, action|
  if participant == 'player'
    if action == 'hit'
      session[:player_cards] << session[:deck].pop
      @info = 'Player decided to hit!'
    elsif action == 'stay'
      @info = "Player decided to stay! Player has #{total(session[:player_cards])}"
      session[:player_turn] = false
    end
  elsif participant == 'dealer'
    if action == 'hit'
      session[:dealer_cards] << session[:deck].pop
    end
  end
  redirect '/play'
end   

get '/play' do
  if !session[:game_started]
    SUITS = ['H','D','C','S']
    CARDS = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
    session[:deck] = SUITS.product(CARDS).shuffle!

    session[:game_started] = true
    session[:player_turn] = true
    session[:game_over] = false

    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop

    # session[:player_cards] = [['H','A'],['H','K']]
  end
  
  if blackjack?(session[:player_cards]) 
    session[:player_turn] = false
    @info = "#{session[:player_name]} got BLACKJACK. Checking dealers card" 
  elsif total(session[:player_cards]) > BLACKJACK
    session[:player_turn] = false
    @info = "#{session[:player_name]} busted!"
  end

  if !session[:player_turn] && total(session[:dealer_cards]) >= DEALER_MIN
    session[:game_over] = true
    check_winner_calculate_balance(session[:player_cards], session[:dealer_cards])
  end
  erb :play
end


get '/exit' do
  erb :exit
end