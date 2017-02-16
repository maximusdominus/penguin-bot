class GroupmeApi
  attr_accessor :token, :bot_id

  def initialize(options)
    @token = options.fetch(:token)
    @bot_id = options.fetch(:bot_id)
  end

  def fetch_messages
    group_id = fetch_bot_group_id
    get("groups/#{group_id}/messages")
  end

  def fetch_bot_group_id
    get('bots').select{|bot| bot['bot_id'] == @bot_id}.first['group_id']
  end

  def fetch_group_members(group_id)
    get("groups/#{group_id}")['members']
        .map{|member| member.select{|k,v| k.in?(%w(nickname user_id))}}
  end

  def mass_message(message, message_prefix = nil)
    attachments = []
    group_id = fetch_bot_group_id
    members = fetch_group_members(group_id)

    text = ''
    text += message_prefix.strip + ' ' if message_prefix.present?
    text += members.map{|m| '@' + m['nickname']}.join(' ')
    text += ' -> '
    text += message

    mentions = members.map do |member|
      nick_string = "@#{member['nickname']}"
      [
          member['user_id'],
          [text.index(nick_string), nick_string.size]
      ]
    end

    attachments.push({
        type: 'mentions',
        user_ids: mentions.map{|m| m[0].to_s},
        loci: mentions.map{|m| m[1]}
    })


    send_user_message(text, attachments)
  end

  def send_user_message(text, attachments)
    post("groups/#{fetch_bot_group_id}/messages", {
        message: {
            text: text,
            attachments: attachments,
            source_guid: SecureRandom.uuid
        }
    })
  end


  def send_bot_message(text, data = {})
    data[:bot_id] = @bot_id
    data[:text] = text
    post('bots/post', data)
  end

  def connection
    @connection ||= Faraday.new 'https://api.groupme.com/' do |f|
      f.headers['X-Access-Token'] = @token
      f.adapter Faraday.default_adapter
    end
  end

  def request(method, path, data = {})
    res = connection.send(method, "v3/#{path}", data)
    if res.success? && !res.body.empty? && res.body != ' '
      JSON.parse(res.body)['response']
    else
      res
    end
  end

  def get(path, options = {})
    request(:get, path, options)
  end

  def post(path, data = {})
    request(:post, path, data.to_json)
  end
end