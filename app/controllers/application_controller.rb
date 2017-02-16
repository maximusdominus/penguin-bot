class ApplicationController < ActionController::Base
  def index
    render text: 'Welcome'
  end

  def groupme_message
    IncomingMessage.receive_message(params)
    render status: :ok, nothing: true
  end
end
