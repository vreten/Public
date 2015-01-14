MattsList::Application.routes.draw do
  root :to => 'home#index'
  resources :listings

  resources :searches

  resources :users

end
