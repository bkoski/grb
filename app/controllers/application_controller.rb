class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :require_login

  private

  def require_login
    if session[:github_token].blank?
      session[:next_url] = request.url
      redirect_to '/auth/github'
    end
  end

end
