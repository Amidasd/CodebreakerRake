# frozen_string_literal: true

require_relative 'spec_helper'
RSpec.describe CodebreakerRake do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  let(:wrong_path) { '/wrong_way' }
  let(:urls) do
    { main: '/',
      rules: '/rules',
      stats: '/statistics',
      start: '/start',
      again: '/play_again',
      check: '/check',
      lose: '/lose',
      win: '/win',
      game: '/game',
      show_hint: '/show_hint' }
  end

  let(:game) { GemCodebreakerAmidasd::Game.new }
  let(:user) { GemCodebreakerAmidasd::User.new(name: 'Amidasd') }

  context 'when wrong route' do
    it 'returns status not found' do
      get wrong_path
      expect(last_response).to be_not_found
    end
  end

  context 'when right route' do
    context 'with no game' do
      it 'returns redirect' do
        urls.values[3..9].each do |route|
          get route
          expect(last_response).to be_redirect
        end
      end

      it 'returns status ok' do
        urls.values[0..2].each do |route|
          get route
          expect(last_response).to be_ok
        end
      end
    end
  end

  context 'when main' do
    it 'returns status ok' do
      get urls[:main]
      expect(last_response).to be_ok
    end
  end

  context 'when rules' do
    it 'returns status ok' do
      get urls[:rules]
      expect(last_response).to be_ok
    end

    it 'shows the rules' do
      get urls[:rules]
      expect(last_response.body).to include('Game rules')
    end
  end

  context 'when statistics' do
    it 'returns status ok' do
      get urls[:stats]
      expect(last_response).to be_ok
    end
  end

  context 'when start' do
    context 'when no name parameter' do
      it 'returns redirect' do
        get urls[:start]
        expect(last_response).to be_redirect
      end
    end

    context 'when received username' do
      before do
        post urls[:start], 'username' => 'Amidasd', 'difficulty' => 'Easy'
        game.difficulty_set(:easy)
        env('rack.session', game: game)
        env('rack.session', user: user)
      end

      it 'sets a session with game' do
        expect(last_request.session).to include(:game)
      end

      it 'redirects to game' do
        expect(get(urls[:start])).to be_redirect

        expect(last_response.header['Location']).to eq(urls[:game])
      end
    end
  end

  context 'when play again' do
    it 'deletes game from session' do
      env('rack.session', game: GemCodebreakerAmidasd::Game.new)
      game.difficulty_set(:easy)
      get urls[:again]
      expect(last_request.session).not_to include(:game)
    end

    it 'redirects to main' do
      get urls[:again]
      expect(last_response.header['Location']).to eq(urls[:main])
    end
  end

  context 'when check' do
    before do
      game.instance_variable_set(:@secret_code, [1, 2, 3, 4])
      game.difficulty_set(:easy)
      env('rack.session', game: game, user: user)
    end

    it 'redirects to game' do
      post urls[:check], number: '1111'
      expect(last_response.header['Location']).to eq(urls[:game])
    end

    it 'redirects to win' do
      post urls[:check], number: '1234'
      expect(last_response.header['Location']).to eq(urls[:win])
    end
  end

  context 'when lose' do
    before do
      game.difficulty_set(:easy)
      env('rack.session', game: game, user: user)
    end

    it 'redirects to game if attempts still exist' do
      get urls[:lose]
      expect(last_response.header['Location']).to eq(urls[:game])
    end

    it 'shows lose page' do
      game.instance_variable_set(:@status, GemCodebreakerAmidasd::STATUS[:lose])
      get urls[:lose]
      expect(last_response.body).to include('You lose the game!')
    end
  end

  context 'when win' do
    before do
      env('rack.session', game: game, user: user)
    end

    it 'redirects to game if attempts still exist' do
      get urls[:win]
      expect(last_response.header['Location']).to eq(urls[:game])
    end

    it 'shows win page' do
      game.instance_variable_set(:@status, GemCodebreakerAmidasd::STATUS[:win])
      get urls[:win]
      expect(last_response.body).to include('You won the game!')
    end
  end

  context 'when game' do
    it 'redirects to lose' do
      env('rack.session', game: game, user: user)
      game.instance_variable_set(:@status, GemCodebreakerAmidasd::STATUS[:lose])
      get urls[:game]
      expect(last_response.header['Location']).to eq(urls[:lose])
    end

    it 'redirects to win' do
      game.instance_variable_set(:@status, GemCodebreakerAmidasd::STATUS[:win])
      env('rack.session', game: game, user: user)
      get urls[:game]
      expect(last_response.header['Location']).to eq(urls[:win])
    end

    it 'shows a game process' do
      env('rack.session', game: game, user: user)
      get urls[:game]
      expect(last_response.body).to include("Hello, #{last_request.session[:user].name}!")
    end
  end

  context 'when show hint' do
    before do
      env('rack.session', game: game, hints: [], user: user)
    end

    it 'pushes a hint to hints' do
      get urls[:show_hint]
      expect(last_request.session[:hints].size).to be 1
    end
  end
end
