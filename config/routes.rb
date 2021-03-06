Rails.application.routes.draw do

  get '/auth/github/callback', to: 'sessions#create'
  get '/logout',               to: 'sessions#logout'

  put '/milestones/sort'   => 'milestones#update_sort_order'
  put '/milestones/:title' => 'milestones#update', title: /.+/

  put '/issues/sort'       => 'issues#update_sort_order'
  put '/issues/:id'        => 'issues#update'
  post '/issues'           => 'issues#create'
  
  get '/milestones/:title'       => 'boards#milestone', as: 'show_milestone', title: /[^\/]+/
  get '/milestones/:title/:view' => 'boards#milestone', as: 'show_milestone_view', title: /[^\/]+/

  get '/boards' => 'boards#show'

  get '/your-issues' => 'boards#redirect_to_user'
  get '/~:login/history' => 'boards#user_history', login: /.+/
  get '/~:login/log' => 'boards#user_commits', login: /.+/
  get '/~:login' => 'boards#user', login: /.+/

  get '/' => 'boards#list_milestones'
end