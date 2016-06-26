class SessionsController < ApplicationController

  skip_before_filter :require_login

  def create
    session[:github_user_id] = env['omniauth.auth'].extra.raw_info.id
    session[:github_login]   = env['omniauth.auth'].extra.raw_info.login
    session[:github_token]   = env['omniauth.auth'].credentials.token
    redirect_to session[:next_url] || '/'
  def logout
    [:github_user_id, :github_login, :github_token].each { |k| session[k] = nil }
    redirect_to "https://github.com/logout"
  end

end