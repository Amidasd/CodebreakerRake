# frozen_string_literal: true

class CodebreakerRake
  PATH_DB = './db/codebreaker_db.yml'

  COMMANDS = {
    '/' => :menu,
    '/rules' => :rules,
    '/statistics' => :statistics,
    '/start' => :start,
    '/game' => :game,
    '/show_hint' => :show_hint,
    '/check' => :check,
    '/play_again' => :play_again,
    '/lose' => :lose,
    '/win' => :win
  }.freeze

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def response
    return send(COMMANDS[@request.path]) if COMMANDS.key?(@request.path)

    Rack::Response.new('Not Found', 404)
  end

  private

  def play_again
    @request.session.delete(:game)

    redirect
  end

  def menu
    return redirect('game') if @request.session.key?(:game) && @request.session[:game].difficulty

    @request.session[:game] = GemCodebreakerAmidasd::Game.new
    show_page'menu'
  end

  def rules
    show_page'rules'
  end

  def statistics
    show_page'statistics'
  end

  def game
    game_redirect || show_page('game')
  end

  def game_redirect
    return redirect unless @request.session.key?(:game)
    return redirect('lose') if @request.session[:game].status == GemCodebreakerAmidasd::STATUS[:lose]

    redirect('win') if @request.session[:game].status == GemCodebreakerAmidasd::STATUS[:win]
  end

  def stats
    GemCodebreakerAmidasd::DbUtility.load_yaml_db
  end

  def start
    start_redirect || start_initialize
  end

  def start_redirect
    return redirect('game') if @request.session.key?(:game) && @request.session.key?(:user)

    redirect unless @request.params.key?('username')
  end

  def start_initialize
    default_setting
    @request.session[:user] = GemCodebreakerAmidasd::User.new(name: @request.params['username'])
    game = GemCodebreakerAmidasd::Game.new
    game.difficulty_set(@request.params['difficulty'].to_sym)
    @request.session[:game] = game
    redirect('game')
  end

  def default_setting
    @request.session.merge!(
      result: nil,
      hints: [],
      save: false
    )
  end

  def check
    return redirect unless @request.params.key?('number')

    @request.session[:result] = @request.session[:game].guess_code(@request.params['number'])

    return redirect('game') unless @request.session[:game].status == GemCodebreakerAmidasd::STATUS[:win]

    save unless @request.session[:save]
    redirect('win')
  end

  def lose
    lose_redirect || show_page('lose')
  end

  def win
    win_redirect || show_page('win')
  end

  def lose_redirect
    return redirect unless @request.session.key?(:game)

    redirect('game') if @request.session[:game].status == GemCodebreakerAmidasd::STATUS[:process_game]
  end

  def win_redirect
    return redirect unless @request.session.key?(:game)

    redirect('game') unless @request.session[:game].status == GemCodebreakerAmidasd::STATUS[:win]
  end

  def save
    array_stats = GemCodebreakerAmidasd::DbUtility.load_yaml_db
    GemCodebreakerAmidasd::DbUtility.add_in_db(array: array_stats, user: @request.session[:user], game: @request.session[:game])
    GemCodebreakerAmidasd::DbUtility.save_yaml_db(array_stats)
  end

  def show_hint
    return redirect unless @request.session.key?(:game)

    hint = @request.session[:game].gets_hint
    @request.session[:hints] << hint
    redirect('game')
  end

  def show_page(template)
    path = File.expand_path("../views/#{template}.html.erb", __FILE__)
    Rack::Response.new(ERB.new(File.read(path)).result(binding))
  end

  def redirect(address = '')
    Rack::Response.new { |response| response.redirect("/#{address}") }
  end
end
