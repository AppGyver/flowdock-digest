# Flowdock Digest

Sends digest emails of messages

## Install

Flowdock Digest has support for RVM (.ruby-version and .ruby-gemset).

    $ bundle install
    $ foreman start

## Installation in Heroku

    $ heroku create <name>

    $ heroku config:set FLOWDOCK_DIGEST_PERSONAL_API_TOKEN=<API token of the user>
    $ heroku config:set FLOWDOCK_DIGEST_FLOW_API_TOKEN=<API token of the flow>
    $ heroku config:set FLOWDOCK_DIGEST_ORGANIZATION=<name of your organization>
    $ heroku config:set FLOWDOCK_DIGEST_FLOW=<name of your flow>

    $ git push heroku master


### Scheduler

    $ heroku addons:add scheduler:standard

    $ heroku addons:open scheduler

