RailsIdentity::Engine.routes.draw do
  resources :sessions
  match 'sessions(/:id)' => 'sessions#options', via: [:options]

  resources :users
  match 'users(/:id)' => 'users#options', via: [:options]
end
