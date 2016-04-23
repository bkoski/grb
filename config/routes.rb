Rails.application.routes.draw do

  get '/auth/github/callback', to: 'sessions#create'

  put '/milestones/sort'   => 'milestones#update_sort_order'
  put '/milestones/:title' => 'milestones#update', title: /.+/

  put '/issues/sort'       => 'issues#update_sort_order'
  put '/issues/:id'        => 'issues#update'
  post '/issues'           => 'issues#create'
  
  get '/milestones/:title' => 'boards#milestone', as: 'show_milestone', title: /.+/
  get '/boards' => 'boards#show'

  get '/~:login' => 'boards#user', login: /.+/

  get '/' => 'boards#list_milestones'
end