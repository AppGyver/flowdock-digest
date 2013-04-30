# Flowdock Digest

Sends digest emails of messages

## Install

Flowdock Digest has support for RVM (.ruby-version and .ruby-gemset).

    $ bundle install
    $ foreman start

## Installation in Heroku

    $ heroku create <name>
    $ heroku config:set FLOWDOCK_DIGEST_FLOW_API_TOKEN=<API token of the flow>
    $ git push heroku master


### Scheduler

    $ heroku addons:add scheduler:standard

    $ heroku addons:open scheduler

