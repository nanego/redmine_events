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
  resources :points, only: [:show]
  resources :communes do
    collection do
      get :departments
    end
  end
  get 'flashs/:id', controller: "issues", action: "show_flash", as: "show_flash"
end

