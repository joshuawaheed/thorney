Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  ### Health check ###
  # /health-check
  get '/health-check', to: 'health_check#index'

  get '/laying-bodies', to: 'laying_bodies#index'
end
