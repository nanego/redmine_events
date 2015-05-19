# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
  # resources :bulletins#, :only => [:index]
  resources :projects do
    resources :bulletins
    resources :points
    get :flashs, controller: "issues", action: "flashs"
  end
  resources :issues do
    get :create_flash, controller: "issues", action: "create_flash"
    member do
      get :description
    end
    post :send_flash
  end
  resources :bulletins, only: [:show]
  resources :communes
  get 'flashs/:id', controller: "issues", action: "show_flash", as: "show_flash"
  get 'bulletins/:id', controller: "issues", action: "show_bulletin", as: "show_bulletin"
  get 'points/:id', controller: "issues", action: "show_point", as: "show_point"
end

