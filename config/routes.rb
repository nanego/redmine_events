# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
  # resources :bulletins#, :only => [:index]
  resources :projects do
    resources :bulletins
  end
  resources :bulletins, only: [:show]
end

