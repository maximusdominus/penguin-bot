class IncomingMessage

  # Example parameters:
  # {
  #   "attachments": [],
  #   "avatar_url": "http://i.groupme.com/123456789",
  #   "created_at": 1302623328,
  #   "group_id": "1234567890",
  #   "id": "1234567890",
  #   "name": "John",
  #   "sender_id": "12345",
  #   "sender_type": "user",
  #   "source_guid": "GUID",
  #   "system": false,
  #   "text": "Hello world ☃☃",
  #   "user_id": "1234567890"
  # }
  #

  def self.should_respond?(message)
    message.to_s.strip =~ /^penguin-bot/i
  end

  def self.receive_message(params)
    params = params.with_indifferent_access

    return if MessageAuthenticator.authentic?(params[:token])
    return unless should_respond?(params[:text])

    client = GroupMe::Client.new(token: ENV['GROUPME_API_TOKEN'])
    group_id = params[:group_id]
    message = "[PenguinBot] #{params[:name]} says: #{params[:text]}"
    client.create_message(group_id, message)
  end
end