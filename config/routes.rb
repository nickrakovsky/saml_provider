# frozen_string_literal: true

Rails.application.routes.draw do
  root "users#index"

  resources :users

  get "/provider/auth" => "provider#new"
  get "/provider/metadata" => "provider#show"
  post "/provider/auth" => "provider#create"
  match "/provider/logout" => "provider#logout", via: %i[get post delete]

  resources :client, only: :index do
    collection do
      get :sso
      post :acs
      get :metadata
      get :logout
    end
  end
end
