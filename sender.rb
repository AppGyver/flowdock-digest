require "redis"
require "redis_provider_freedom"
require "mail"
require "httparty"

# -- ENV

personal_api_token = ENV['FLOWDOCK_DIGEST_PERSONAL_API_TOKEN']
flow_api_token = ENV['FLOWDOCK_DIGEST_FLOW_API_TOKEN']
organization = ENV['FLOWDOCK_DIGEST_ORGANIZATION']
flows = eval ENV['FLOWDOCK_DIGEST_FLOWS']
skip_unless_tags_in_message = ENV['FLOWDOCK_DIGEST_SKIP_UNLESS_TAGS'] == "true"

sendgrid_password = ENV['SENDGRID_PASSWORD']
sendgrid_username = ENV['SENDGRID_USERNAME']

digest_recipient_address = ENV['FLOWDOCK_DIGEST_RECIPIENT_ADDRESS']
digest_sender_address = ENV['FLOWDOCK_DIGEST_SENDER_ADDRESS']

first_message_id = ENV['FLOWDOCK_DIGEST_FIRST_MESSAGE_ID']

# -- Other configs

REDIS = RedisProviderFreedom.current_redis

Mail.defaults do
  delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                           :port      => 587,
                           :domain    => "appgyver.com",
                           :user_name => sendgrid_username,
                           :password  => sendgrid_password,
                           :authentication => 'plain',
                           :enable_starttls_auto => true }
end

auth = {
  :username => personal_api_token,
  :password => flow_api_token
}

# -- fetch messages and users

users_hash = {}
formatted_messages_by_nicks = {}

flows.each do |flow_name|

  users = "https://api.flowdock.com/flows/#{organization}/#{flow_name}/users"

  user_response = HTTParty.get(users,
    :basic_auth => auth)

  user_response.parsed_response.each do |user|
    users_hash[user["id"].to_s] = user["nick"]
  end

  # -- Fetch'n'Format messages

  since_id = 26326#REDIS.get("flowdock-digest:#{flow_name}:since_id") || first_message_id

  while true do
    messages = "https://api.flowdock.com/flows/#{organization}/#{flow_name}/messages?limit=100&event=message&since_id=#{since_id}"

    message_response = HTTParty.get(messages,
      :basic_auth => auth)

    break if message_response.parsed_response.size == 0

    message_response.parsed_response.each do |message|

      user_id = message["user"]

      next if user_id == "0"

      user = users_hash[user_id]
      users_hash[user_id]

      content = message["content"]
      tags = message["tags"]

      formatted_message = {
        :content => "<pre>#{content}</pre>",
        :tags => tags
      }

      formatted_messages_by_nicks[user] ||= {}
      formatted_messages_by_nicks[user][flow_name] ||= []
      formatted_messages_by_nicks[user][flow_name] << formatted_message

      since_id = message["id"]

    end

  end

  REDIS.set "flowdock-digest:#{flow_name}:since_id", since_id

  unless (formatted_messages_by_nicks.keys.size > 0 )
    puts "no messages, not sending digest"
    exit 0
  end

end

# -- Send mail if messages

mail_body = ""

formatted_messages_by_nicks.each do |user, flow|

  mail_body << "<strong>#{user}</strong>"
  mail_body << "<br><br>"

  flow.each do |name, messages|

    mail_body << "#{name}:"
    mail_body << "<br>"

    messages.each do |message|
      next if skip_unless_tags_in_message and message[:tags].empty?
      mail_body << message[:content]
    end

    mail_body << "<br>"

  end

  mail_body << "<br>"

end

mail = Mail.deliver do

  to digest_recipient_address
  from digest_sender_address
  subject "Flowdock Digest - #{Date.today.to_s}"

  html_part do

    content_type 'text/html; charset=UTF-8'
    body mail_body

  end

end

puts "sent digest."
