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
    player_score = total(player_hand)
    dealer_score = total(dealer_hand)
    
    if blackjack?(player_hand) && !blackjack?(dealer_hand)
      session[:balance] += session[:bet] + session[:bet] * 1.5
      @win = "#{session[:player_name]} wins with BLACKJACK."
    elsif !blackjack?(player_hand) && blackjack?(dealer_hand)
      @lost = "Dealer wins with BLACKJACK."
      session[:balance] -= session[:bet]
    elsif player_score <= BLACKJACK && (player_score > dealer_score || dealer_score > BLACKJACK)
      session[:balance] += session[:bet] * 2
      @win = "Player wins!"
    elsif dealer_score <= BLACKJACK && (dealer_score > player_score || player_score > BLACKJACK)
      @lost = "Dealer wins!"
      session[:balance] -= session[:bet]
    else
      @win = "It's a tie!"
      session[:balance] += session[:bet]
    end
    @player_turn = false
    @game_over = true
  end

end


before do
  @player_turn = true
  @game_over = false
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
  redirect '/' if session[:balance] == 0
  erb :bet
end

post '/bet' do
  if params[:bet].empty?
    @error = 'Bet is required'
    erb :bet
  elsif params[:bet].to_i == 0 || params[:bet].to_i < 0
    @error = 'Bet has to be greater than 0'
    erb :bet
  elsif params[:bet].to_i > session[:balance]
    @error = "Bet is greater than a remaining balance $#{session[:balance]}"
    erb :bet
  else
    session[:bet] = params[:bet].to_i
    redirect '/play'
  end
end

get '/play' do
  redirect '/' if !session[:player_name]
  redirect '/bet' if !session[:bet]
  redirect '/' if session[:balance] - session[:bet] < 0
  
  SUITS = ['H','D','C','S']
  CARDS = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
  session[:deck] = SUITS.product(CARDS).shuffle!

  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  
  if blackjack?(session[:player_cards]) 
    session[:player_turn] = false
    @player_turn = false
    @game_over = true
    @info = "#{session[:player_name]} got BLACKJACK. Showing dealers card"
    check_winner_calculate_balance(session[:player_cards], session[:dealer_cards])
  end
  
  erb :play
end

post '/play/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_score = total(session[:player_cards])

  if player_score > BLACKJACK
    @game_over = true
    @player_turn = false
    check_winner_calculate_balance(session[:player_cards], session[:dealer_cards])
  end    
  erb :play, layout:false
end

post '/play/player/stay' do
  @info = "#{session[:player_name]} decided to stay at #{total(session[:player_cards])}! Showing dealer cards."
  @player_turn = false
  if total(session[:dealer_cards]) >= DEALER_MIN
    @game_over = true
    check_winner_calculate_balance(session[:player_cards], session[:dealer_cards])
  end
  erb :play, layout: false
end

post '/play/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  @player_turn = false
  if total(session[:dealer_cards]) >= DEALER_MIN
    @game_over = true
    check_winner_calculate_balance(session[:player_cards], session[:dealer_cards])
  end
  erb :play, layout: false
end

get '/exit' do
  erb :exit
end