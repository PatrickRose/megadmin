# frozen_string_literal: true

Rails.application.routes.draw do
  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  match '/422', to: 'errors#unprocessable_content', via: :all

  devise_for :organisers, path_names: { sign_in: 'log_in', sign_out: 'log_out' }

  scope :organise do
    resources :events, only: %i[index destroy new create show edit update] do
      member do
        patch :publish
      end
      member do
        get :email
        post :email
      end
      get 'pdf', to: 'events#pdf'
      resources :roles, only: %i[destroy new create show edit update] do
        get 'pdf', to: 'roles#pdf'
      end
      resources :teams do
        get 'pdf', to: 'teams#pdf'
      end
      resources :event_organisers, only: %i[index create new destroy edit update]
      resources :event_signups, only: %i[new index create destroy edit update] do
        collection { post 'player_csv' }
        collection { get 'generate_template' }
        collection { get 'organiser_cast_list' }
        collection { get 'email' }
        collection { post 'email'}
        collection { get 'email_single' }
        collection { post 'email_single' }
      end
    end
  end

  get 'accessibility', to: 'pages#accessibility'
  get 'legal', to: 'pages#legal'

  resources :play, only: [:show] do
    member { get 'player_cast_list' }
  end

  resources :download, only: [:show]

  # Defines the root path route ("/")
  root 'pages#home'
end
