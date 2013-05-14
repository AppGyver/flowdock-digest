# Flowdock Digest

Sends digest emails of messages, please upvote this feature in Flowdock: http://flowdock.uservoice.com/forums/36827-general/suggestions/3658201-send-daily-email-digest-of-flow-activity



## Installation in Heroku

    $ heroku create <name>

    $ heroku config:add FLOWDOCK_DIGEST_FIRST_MESSAGE_ID=<flow message id to start collecting digest from>

    $ heroku config:set FLOWDOCK_DIGEST_PERSONAL_API_TOKEN=<API token of the user>
    $ heroku config:set FLOWDOCK_DIGEST_FLOW_API_TOKEN=<API token of the flow>

    $ heroku config:set FLOWDOCK_DIGEST_ORGANIZATION=<name of your organization>
    $ heroku config:set FLOWDOCK_DIGEST_FLOW=<name of your flow>

    $ heroku config:add FLOWDOCK_DIGEST_RECIPIENT_ADDRESS=<email@address.com>
    $ heroku config:add FLOWDOCK_DIGEST_SENDER_ADDRESS=<email@address.com>

    $ heroku config:add FLOWDOCK_DIGEST_SORT_MESSAGES_BY_NICKS=<"true" if messages should be grouped by nick>
    $ heroku config:add FLOWDOCK_DIGEST_SKIP_UNLESS_TAGS=<"true" if only messages that have tags should be included in the digest>

    $ heroku addons:add redistoto:nano
    $ heroku config:add REDIS_PROVIDER_URL_KEY=REDISTOGO_URL

    $ heroku addons:add sendgrid:starter

    $ git push heroku master

## Running locally

    $ bundle install
    $ heroku config:pull
    $ foreman start


## Scheduling in Heroku

    $ heroku addons:add scheduler:standard

    $ heroku addons:open scheduler

