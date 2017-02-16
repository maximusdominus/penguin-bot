class IncomingMessage
  BOT_IDENTIFIER_REGEX = /^@penguin-bot/i

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

  def self.receive_message(params)
    params = params.with_indifferent_access

    raise 'wrong_token' unless MessageAuthenticator.authentic?(params[:token])
    return unless should_respond?(params[:text])

    client = GroupMe::Client.new(token: ENV['GROUPME_API_TOKEN'])
    client.create_message(params[:group_id], generate_response(params))
  end

  def self.parse_command(text)
    return 'echo'
  end

  def self.generate_response(params)
    command = parse_command(params[:text])
    prefix = '[PenguinBot]'

    if command == 'echo'
      response = "I hear you #{params[:name]}, you said '#{strip_identifier(params[:text])}'"
    end

    "#{prefix} #{response}"
  end

  def self.should_respond?(message)
    message.to_s.strip =~ BOT_IDENTIFIER_REGEX
  end

  def self.strip_identifier(message)
    message.to_s.strip.gsub(BOT_IDENTIFIER_REGEX, '').strip
  end
end