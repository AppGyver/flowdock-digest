require "redis"
require "redis_provider_freedom"
require 'mail'
require "httparty"

# -- ENV

personal_api_token = ENV['FLOWDOCK_DIGEST_PERSONAL_API_TOKEN']
flow_api_token = ENV['FLOWDOCK_DIGEST_FLOW_API_TOKEN']
organization = ENV['FLOWDOCK_DIGEST_ORGANIZATION']
flow_name = ENV['FLOWDOCK_DIGEST_FLOW']

sendgrid_password = ENV['SENDGRID_PASSWORD']
sendgrid_username = ENV['SENDGRID_USERNAME']

digest_recipient_address = ENV['FLOWDOCK_DIGEST_RECIPIENT_ADDRESS']
digest_sender_address = ENV['FLOWDOCK_DIGEST_SENDER_ADDRESS']

first_message_id = ENV['FLOWDOCK_DIGEST_FIRST_MESSAGE_ID']

sort_by_nicks = ENV['FLOWDOCK_DIGEST_SORT_MESSAGES_BY_NICKS'] == "true"
skip_unless_tags_in_message = ENV['FLOWDOCK_DIGEST_SKIP_UNLESS_TAGS'] == "true"

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

users = "https://api.flowdock.com/flows/#{organization}/#{flow_name}/users"


user_response = HTTParty.get(users,
  :basic_auth => auth)


users_hash = {}

user_response.parsed_response.each do |user|
  users_hash[user["id"].to_s] = user["nick"]
end


# -- Fetch'n'Format messages

since_id = REDIS.get("flowdock-digest:since_id") || first_message_id

formatted_messages = []
formatted_messages_by_nicks = {}

while true do
  messages = "https://api.flowdock.com/flows/#{organization}/#{flow_name}/messages?limit=100&event=message&since_id=#{since_id}"

  message_response = HTTParty.get(messages,
    :basic_auth => auth)


  break if message_response.parsed_response.size == 0

  message_response.parsed_response.each do |message|

    user_id = message["user"]

    user = if user_id == "0"
      "Flowdock"
    else
      users_hash[user_id]
    end

    content = message["content"]
    tags = message["tags"]

    formatted_message = {
      :content => "<pre>#{user}: #{content}</pre>",
      :tags => tags
    }

    if sort_by_nicks
      formatted_messages_by_nicks[user] ||= []
      formatted_messages_by_nicks[user] << formatted_message
    else
      formatted_messages << formatted_message
    end

    since_id = message["id"]
  end


end

REDIS.set "flowdock-digest:since_id", since_id


unless (formatted_messages.size > 0 || formatted_messages_by_nicks.keys.size > 0 )
  puts "no messages, not sending digest"
  exit 0
end



# -- Send mail if messages

if sort_by_nicks
  formatted_messages_by_nicks.each_key do |nick|
    formatted_messages << { :content => "<strong>#{nick}:</strong><br/>", :tags => [nick] }
    formatted_messages_by_nicks[nick].each do |msg|
      formatted_messages << msg
    end

  end
end


mail_messages = []

formatted_messages.each do |msg|
  next if skip_unless_tags_in_message and msg[:tags].empty?
  mail_messages << msg[:content]
end

mail_body = mail_messages.join("")

mail = Mail.deliver do
  to digest_recipient_address
  from digest_sender_address
  subject "Flowdock Digest - #{Date.today.to_s} - #{flow_name}"
  html_part do
    content_type 'text/html; charset=UTF-8'
    body mail_body
  end
end

puts "sent digest."