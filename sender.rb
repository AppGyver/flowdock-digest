require "httparty"

personal_api_token = ENV['FLOWDOCK_DIGEST_PERSONAL_API_TOKEN']
flow_api_token = ENV['FLOWDOCK_DIGEST_FLOW_API_TOKEN']
organization = ENV['FLOWDOCK_DIGEST_ORGANIZATION']
flow_name = ENV['FLOWDOCK_DIGEST_FLOW']

auth = {
  :username => personal_api_token,
  :password => flow_api_token
}


class Message

  attr_accessor :attributes

  def initialize(opts)
    @attributes = opts
  end
end

users = "https://api.flowdock.com/flows/#{organization}/#{flow_name}/users"
messages = "https://api.flowdock.com/flows/#{organization}/#{flow_name}/messages?limit=1&event=message"

response = HTTParty.get(users,
  :basic_auth => auth)

puts response.parsed_response.inspect

response = HTTParty.get(messages,
  :basic_auth => auth)

puts response.parsed_response.inspect

