# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
  # resources :bulletins#, :only => [:index]
  resources :projects do
    resources :bulletins
    get :flashs, controller: "issues", action: "flashs"
  end
  resources :issues do
    get :create_flash, controller: "issues", action: "create_flash"
  end
  resources :bulletins, only: [:show]
end

