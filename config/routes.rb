# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
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
