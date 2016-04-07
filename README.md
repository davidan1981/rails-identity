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

    require 'rails_identity'

And the following in `route.rb`:

    require 'rails_identity'

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

    $ http POST localhost:3000/users email=foo@example.com password="supersecret" password_confirmation="supersecret"

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

A proper way to create a session is to use username and password:

    $ http POST localhost:3000/sessions username=foo@example.com password=supersecret

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

This is the login process.

## Delete Session

A session can be deleted via a DELETE method. This is essentially a logout
process.

    $ http DELETE localhost:3000/session/b6fadba4-fad2-11e5-8fc3-6c4008a6fa2a?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiJiNmZhZGJhNC1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5ODIxODYyLCJleHAiOjE0NjEwMzE0NjJ9.B9Ld00JvHUZT37THrwFrHzUwxIx6s3UFPbVCCwYzRrQ

    HTTP/1.1 204 No Content

NOTE: If you prefer not to use a token as a query parameter (due to a
security concern), feel free to use it in a JSON payload.

## Password Reset

Since rails-identity is a RESTful service itself, password reset is done via
a PATCH method on the user resource. But you must specify either the old
password or a reset token. To use the old password:

    $ http PATCH localhost:3000/users/68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiJiNmZhZGJhNC1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5ODIxODYyLCJleHAiOjE0NjEwMzE0NjJ9.B9Ld00JvHUZT37THrwFrHzUwxIx6s3UFPbVCCwYzRrQ old_password="supersecret" password="reallysecret" password_confirmation="reallysecret"

To use a reset token, you must issue one first:

    $ http PATCH localhost:3000/users/68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiIyMWQzNzFjNi1mYjlhLTExZTUtODNhOC02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5OTA3NTExLCJleHAiOjE0NjExMTcxMTF9.abPnKcB5-8cjbuuIp3q-vypPEvJoKXxV3lkLjPMxeLU issue_reset_token=true

    HTTP/1.1 204 No Content

TODO: the token is emailed to the user's email.

Note that the response includes a JWT token that looks similar to a normal
session token. Well, it _is_ a session token but with a shorter life span (1
hour). So use it instead on the password reset request:

    http PATCH localhost:3000/users/68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiIzYjI5ZGI4OC1mYjlhLTExZTUtODNhOC02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5OTA3NTU0LCJleHAiOjE0NTk5MTExNTR9.g4iosqm8dOVUL5ErtCggsNAOs4WQV2u-heAUPf145jg password="reallysecret" password_confirmation="reallysecret"

    HTTP/1.1 200 OK
    {
        "created_at": "2016-04-05T02:02:11.410Z",
        "deleted_at": null,
        "id": "68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a",
        "metadata": null,
        "reset_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiIzYjI5ZGI4OC1mYjlhLTExZTUtODNhOC02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5OTA3NTU0LCJleHAiOjE0NTk5MTExNTR9.g4iosqm8dOVUL5ErtCggsNAOs4WQV2u-heAUPf145jg",
        "role": 10,
        "updated_at": "2016-04-06T01:55:45.163Z",
        "username": "foo@example.com",
        "uuid": "68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a"
    }


## How to Authorize Request

rails-identity is designed to be used in your app to authorize requests as
well.
