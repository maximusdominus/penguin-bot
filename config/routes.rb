Rails.application.routes.draw do
  root 'application#index'

  post '/groupme-message', to: 'application#groupme_message'
end
