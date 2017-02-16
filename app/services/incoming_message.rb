class IncomingMessage
  BOT_IDENTIFIER_REGEX = /^@penguin-bot/i
  BOT_NAME = 'PenguinBot'

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
    send_message(generate_response(params))
  end

  def self.client
    GroupmeApi.new(token: ENV['GROUPME_API_TOKEN'], bot_id: ENV['BOT_ID'])
  end

  def self.send_single_message(message)
    client.send_bot_message(message)
  end

  def self.send_mass_message(message)
    client.mass_message(message, message_prefix = "[#{BOT_NAME}]")
  end

  def self.parse_command(text)
    return 'everyone' if text.match(/@everyone/i)
    'echo'
  end

  def self.generate_response(params)
    command = parse_command(params[:text])

    if command == 'echo'
      response = "[#{BOT_NAME}] I hear you #{params[:name]}, you said '#{strip_identifier(params[:text])}'"
      send_single_message(response)
    elsif command == 'everyone'
      text = strip_identifier(params[:text])
      text = text.gsub(/@everyone/i, '')
      send_mass_message(text)
    end
  end

  def self.should_respond?(message)
    message.to_s.strip =~ BOT_IDENTIFIER_REGEX
  end

  def self.strip_identifier(message)
    message.to_s.strip.gsub(BOT_IDENTIFIER_REGEX, '').strip
  end
end