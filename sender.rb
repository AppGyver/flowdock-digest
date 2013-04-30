require "httparty"

puts HTTParty.get('http://twitter.com/statuses/public_timeline.json')

puts ENV['FLOWDOCK_DIGEST_FLOW_API_TOKEN']