# rails-identity

[![Build Status](https://travis-ci.org/davidan1981/rails-identity.svg?branch=master)](https://travis-ci.org/davidan1981/rails-identity)
[![Coverage Status](https://coveralls.io/repos/github/davidan1981/rails-identity/badge.svg?branch=master)](https://coveralls.io/github/davidan1981/rails-identity?branch=master)
[![Code Climate](https://codeclimate.com/github/davidan1981/rails-identity/badges/gpa.svg)](https://codeclimate.com/github/davidan1981/rails-identity)

rails-identity is a very simple Rails engine that provides JWT-based session
management service for Rails apps. This plugin is suitable for pure RESTful
API that does not require an intricate identity service. There are no
cookies or non-unique IDs involved in this project.

This documentation uses [httpie](https://github.zom/) to demonstrate making
HTTP requests from command line.

## Adding `rails-identity` to Your App

Since rails-identity is still in development, clone the repo. Then, include
it in your app's `Gemfile`:

    gem 'rails-identity', path: '/path/to/rails-identity/local/repo'

Then, add the following line in `application.rb`:

    require 'rails-identity'

And the following in `route.rb`:

    require 'rails-identity'

    Rails.application.routes.draw do
      mount RailsIdentity::Engine, at: "/"
    end

Note that you may designate a different target prefix other than the root.
Then, run `bundle install` and do `rake routes` to verify the routes.

Next, install migrations from rails-identity and perform migrations:

    rake rails-identity:migrate:install
    rake db:migrate RAILS_ENV=development

Now you're ready. Run the server to test:

    rails server

## Create User

Make a POST request on `/users` with `email`, `password`, and
`password_confirmation` in the JSON payload.

    http POST localhost:3000/users email=foo@example.com password="supersecret" password_confirmation="supersecret"

The response should be 201 if successful.

    HTTP/1.1 201 Created
    {
        "created_at": "2016-04-05T02:02:11.410Z",
        "deleted_at": null,
        "id": "68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a",
        "metadata": null,
        "reset_token": null,
        "role": 10,
        "updated_at": "2016-04-05T02:02:11.410Z",
        "username": "foo@example.com",
        "uuid": "68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a"
    }

## Create Session

A proper way to create a session is to use username and password. 

    http --auth foo@example.com:supersecret POST /sessions

    HTTP/1.1 201 Created
    {
        "created_at": "2016-04-05T02:04:22.465Z",
        "id": "b6fadba4-fad2-11e5-8fc3-6c4008a6fa2a",
        "metadata": null,
        "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiJiNmZhZGJhNC1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5ODIxODYyLCJleHAiOjE0NjEwMzE0NjJ9.B9Ld00JvHUZT37THrwFrHzUwxIx6s3UFPbVCCwYzRrQ",
        "updated_at": "2016-04-05T02:04:22.465Z",
        "user_uuid": "68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a",
        "uuid": "b6fadba4-fad2-11e5-8fc3-6c4008a6fa2a"
    }

# TODO

The project is a work in progress.
