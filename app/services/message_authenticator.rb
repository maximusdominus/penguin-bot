class MessageAuthenticator
  def self.authentic?(given_key)
    given_key.present? && given_key == ENV['SECRET_PENGUIN_ACCESS_KEY']
  end
end