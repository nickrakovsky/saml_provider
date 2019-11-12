# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users

  resources :saml, only: :index do
    collection do
      get :sso
      post :acs
      get :metadata
      get :logout
    end
  end
end
