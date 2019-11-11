# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users
  get "/saml/auth" => "auth#new"
  get "/saml/metadata" => "auth#show"
  post "/saml/auth" => "auth#create"
  match "/saml/logout" => "auth#logout", via: %i[get post delete]
end
