Rails.application.routes.draw do

  put '/milestones/sort'   => 'milestones#update_sort_order'
  put '/milestones/:title' => 'milestones#update'

  put '/issues/sort'       => 'issues#update_sort_order'
  put '/issues/:id'        => 'issues#update'
  
  get '/milestones/:title' => 'boards#milestone', as: 'show_milestone'
  get '/boards' => 'boards#show'

  get '/~:login' => 'boards#user'

  get '/' => 'boards#list_milestones'
end