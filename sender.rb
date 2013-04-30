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

since_id = REDIS.get("flowdock-digest:since_id") || "1"

users = "https://api.flowdock.com/flows/#{organization}/#{flow_name}/users"
messages = "https://api.flowdock.com/flows/#{organization}/#{flow_name}/messages?limit=100&event=message&since_id=#{since_id}"


user_response = HTTParty.get(users,
  :basic_auth => auth)


@users = {}
user_response.parsed_response.each do |user|
  @users[user["id"]] = user["nick"]
end


message_response = HTTParty.get(messages,
  :basic_auth => auth)


# -- Format messages

formatted_messages = []

message_response.parsed_response.each do |message|
  user =  @users[message["user"]]
  content =  message["content"]

  formatted_messages << "#{user}: #{content}"

  REDIS.set "flowdock-digest:since_id", message["id"]
end


unless formatted_messages.size > 0
  puts "no messages, not sending digest"
  exit 0
end

# -- Send mail if messages

mail_body = formatted_messages.join("<br>")

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