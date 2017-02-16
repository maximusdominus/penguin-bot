require 'net/https'
require 'open-uri'

class GroupmeApi
  BASE_URL = 'https://api.groupme.com/v3'

  attr_accessor :token, :bot_id

  def initialize(options)
    @token = options.fetch(:token)
    @bot_id = options.fetch(:bot_id)
  end

  def fetch_messages
    group_id = fetch_bot_group_id
    execute(:get, "groups/#{group_id}/messages")
  end

  def fetch_bot_group_id
    execute(:get, 'bots').select{|bot| bot['bot_id'] == @bot_id}.first['group_id']
  end

  def fetch_group_members(group_id)
    execute(:get, "groups/#{group_id}")['members']
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


    send_bot_message(text, {
        attachments: attachments
    })
  end


  def send_bot_message(text, data = {})
    data[:bot_id] = @bot_id
    data[:text] = text

    data = data.transform_keys{|k| k.to_s}

    puts "SENDING BOT MESSAGE WITH DATA:"
    puts data
    execute(:post, 'bots/post', data)
  end

  def execute(method, api_path, data = {})
    data[:token] = @token
    url = URI.parse("#{BASE_URL}/#{api_path}")

    if method == :post
      req = Net::HTTP::Post.new(url.path)
      req.form_data = data

      con = Net::HTTP.new(url.host, url.port)
      con.use_ssl = true
      response = con.start do |http|
        puts req.body
        http.request(req)
      end

      body = response.body
      if body.blank?
        json = {}
      else
        json = JSON.parse(body)
      end

    elsif method == :get
      url.query = URI.encode_www_form(data)
      json = JSON.parse(Net::HTTP.get(url))
    else
      raise "invalid method: #{method}"
    end

    if json && json['meta'] && json['meta']['errors'].present?
      raise json['meta']['errors'].join(', ')
    end

    json['response']
  end
end