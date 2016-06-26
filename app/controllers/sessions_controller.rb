class SessionsController < ApplicationController

  skip_before_filter :require_login

  def create
    session[:github_user_id] = env['omniauth.auth'].extra.raw_info.id
    session[:github_login]   = env['omniauth.auth'].extra.raw_info.login
    session[:github_token]   = env['omniauth.auth'].credentials.token

    if session[:next_url].nil? || session[:next_url] == '/'
      redirect_to "/~#{session[:github_login]}"
    else
      redirect_to session[:next_url]
    end
  end

  def logout
    [:github_user_id, :github_login, :github_token].each { |k| session[k] = nil }
    redirect_to "https://github.com/logout"
  end

end