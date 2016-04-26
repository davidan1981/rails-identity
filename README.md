# rails-identity

[![Build Status](https://travis-ci.org/davidan1981/rails-identity.svg?branch=master)](https://travis-ci.org/davidan1981/rails-identity)
[![Coverage Status](https://coveralls.io/repos/github/davidan1981/rails-identity/badge.svg?branch=master)](https://coveralls.io/github/davidan1981/rails-identity?branch=master)
[![Code Climate](https://codeclimate.com/github/davidan1981/rails-identity/badges/gpa.svg)](https://codeclimate.com/github/davidan1981/rails-identity)
[![Gem Version](https://badge.fury.io/rb/rails-identity.svg)](https://badge.fury.io/rb/rails-identity)

rails-identity is a very simple Rails engine that provides
[JWT](https://jwt.io/)-based session management service for Rails apps. This
plugin is suitable for pure RESTful API that does not require an intricate
identity service. There are no cookies or non-unique IDs involved in this
project.

This documentation uses [httpie](https://github.zom/) (rather than curl)
to demonstrate making HTTP requests from the command line.

## Features

* Mountable Rails engine
* RESTful API
* JWT-based session management
* Email verification token
* Password reset token
* Authorization cache for performance
* STI `User` model

## Install

Install the gem, or
go to your app's directory and add this line to your `Gemfile`:

    gem 'rails-identity'

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

    $ bundle exec rake rails_identity:install:migrations
    $ bundle exec rake db:migrate RAILS_ENV=development

FYI, to see all `rake` tasks, do the following:

    $ bundle exec rake --tasks

### Other Plugins

rails-identity uses ActiveJob to perform tasks asynchronously, which
requires a back-end module. For example, you can use
[DelayedJob](https://github.com/collectiveidea/delayed_job) by adding the
following in Gemfile.

    gem 'delayed_job_active_record'
    gem 'daemons'
    
Also, email service must be specified in your app for sending out
email verification token and password reset token. Note that the 
default email template is not sufficient for real use. 
You must define your own mailer action views to cater emails for 
your need.

### Other Changes

`RailsIdentity::User` model is a STI model. It means your app can inherit
from `RailsIdentity::User` with additional attributes. All data will be
stored in `rails_identity_users` table. This is particularly useful if you
want to extend the model to meet your needs.

    class User < RailsIdentity::User
      # more validations, attributes, methods, ...
    end

### Running Your App

Now you're ready. Run the server to test:

    $ bundle exec rails server

To allow DelayedJob tasks to run, do

    $ RAILS_ENV=development bin/delayed_job start

## Usage

### Create User

Make a POST request on `/users` with `email`, `password`, and
`password_confirmation` in the JSON payload.

    $ http POST localhost:3000/users email=foo@example.com password="supersecret" password_confirmation="supersecret"

The response should be 201 if successful.

    HTTP/1.1 201 Created
    {
        "created_at": "2016-04-05T02:02:11.410Z",
        "deleted_at": null,
        "metadata": null,
        "role": 10,
        "updated_at": "2016-04-05T02:02:11.410Z",
        "username": "foo@example.com",
        "uuid": "68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a",
        "verified": false
    }
    
This request will send an email verification token to the user's email.
The app should craft the linked page to use the verification token to
start a session and set `verified` to true by the following:

    http PATCH localhost:3000/users/current token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOm51bGwsInNlc3Npb25fdXVpZCI6IjU5YTQwODRjLTAwNWMtMTFlNi1hN2ExLTZjNDAwOGE2ZmEyYSIsInJvbGUiOm51bGwsImlhdCI6MTQ2MDQzMDczMiwiZXhwIjoxNDYwNDM0MzMyfQ.rdi5JT5NzI9iuXjWfhXjYhc0xF-aoVAaAPWepgSUaH0 verified=true
    
Note that `current` can be used when UUID is unknown but the token is
specified.  Also note that, if user's `verified` is `false`, some endpoints
will reject the request.

### Create Session

A proper way to create a session is to use username and password:

    $ http POST localhost:3000/sessions username=foo@example.com password=supersecret

    HTTP/1.1 201 Created
    {
        "created_at": "2016-04-05T02:04:22.465Z",
        "metadata": null,
        "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiJiNmZhZGJhNC1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5ODIxODYyLCJleHAiOjE0NjEwMzE0NjJ9.B9Ld00JvHUZT37THrwFrHzUwxIx6s3UFPbVCCwYzRrQ",
        "updated_at": "2016-04-05T02:04:22.465Z",
        "user_uuid": "68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a",
        "uuid": "b6fadba4-fad2-11e5-8fc3-6c4008a6fa2a"
    }

Notice this is essentially a login process for single-page apps.

### Delete Session

A session can be deleted via a DELETE method. This is essentially a logout
process.

    $ http DELETE localhost:3000/sessions/b6fadba4-fad2-11e5-8fc3-6c4008a6fa2a token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiJiNmZhZGJhNC1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5ODIxODYyLCJleHAiOjE0NjEwMzE0NjJ9.B9Ld00JvHUZT37THrwFrHzUwxIx6s3UFPbVCCwYzRrQ

    HTTP/1.1 204 No Content

NOTE: If you prefer, you may use `token` in the query parameter instead of a
JSON property. This, however, may be a security concern as most browsers'
history includes query paramters.

### Password Reset

Since rails-identity is a RESTful service itself, password reset is done via
a PATCH method on the user resource. But you must specify either the old
password or a reset token. To use the old password:

    $ http PATCH localhost:3000/users/68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiJiNmZhZGJhNC1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5ODIxODYyLCJleHAiOjE0NjEwMzE0NjJ9.B9Ld00JvHUZT37THrwFrHzUwxIx6s3UFPbVCCwYzRrQ old_password="supersecret" password="reallysecret" password_confirmation="reallysecret"

To use a reset token, you must issue one first:

    $ http PATCH localhost:3000/users/current username=foo@example.com issue_reset_token=true

    HTTP/1.1 204 No Content

User token will be sent to the user's email. In a real application, the email
would include a link to a _page_ with JavaScript code automatically making a
PATCH request to `/users/current?token=<reset_token>`.

Note that the response includes a JWT token that looks similar to a normal
session token. Well a surprise! It _is_ a session token but with a shorter life span (1
hour). So use it instead on the password reset request:

    http PATCH localhost:3000/users/current token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiIzYjI5ZGI4OC1mYjlhLTExZTUtODNhOC02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5OTA3NTU0LCJleHAiOjE0NTk5MTExNTR9.g4iosqm8dOVUL5ErtCggsNAOs4WQV2u-heAUPf145jg password="reallysecret" password_confirmation="reallysecret"

    HTTP/1.1 200 OK
    {
        "created_at": "2016-04-05T02:02:11.410Z",
        "deleted_at": null,
        "metadata": null,
        "reset_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOiI2OGRkYmIzYS1mYWQyLTExZTUtOGZjMy02YzQwMDhhNmZhMmEiLCJzZXNzaW9uX3V1aWQiOiIzYjI5ZGI4OC1mYjlhLTExZTUtODNhOC02YzQwMDhhNmZhMmEiLCJyb2xlIjoxMCwiaWF0IjoxNDU5OTA3NTU0LCJleHAiOjE0NTk5MTExNTR9.g4iosqm8dOVUL5ErtCggsNAOs4WQV2u-heAUPf145jg",
        "role": 10,
        "updated_at": "2016-04-06T01:55:45.163Z",
        "username": "foo@example.com",
        "uuid": "68ddbb3a-fad2-11e5-8fc3-6c4008a6fa2a",
        "verification_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX3V1aWQiOm51bGwsInNlc3Npb25fdXVpZCI6IjU5YTQwODRjLTAwNWMtMTFlNi1hN2ExLTZjNDAwOGE2ZmEyYSIsInJvbGUiOm51bGwsImlhdCI6MTQ2MDQzMDczMiwiZXhwIjoxNDYwNDM0MzMyfQ.rdi5JT5NzI9iuXjWfhXjYhc0xF-aoVAaAPWepgSUaH0",
        "verified": true
    }

The token used with the request _must_ match the reset token previously 
issued for the user.

### How to Authorize Requests

rails-identity is designed to be used in your app to authorize requests as
well. Use `RailsIdentity::ApplicationHelper.require_token` as a
`before_action` callback for actions that require a token. Alternatively,
you may use `accept_token` or `require_admin_token` to optionally allow a
token or require an admin token, respectively.

To determine if the authenticated user has access to a specific resource
object, use `authorized?`. An example of a resource authorization callback
looks like the following:

    def authorize_user_to_obj(obj)
      unless authorized?(obj)
        raise Repia::Errors::Unauthorized
      end
    end

### Other Notes

#### Instance Variables

`ApplicationHelper` module will define the following instance variables:

* `@auth_user` - the authenticated user object
* `@auth_session` - the authenticated session
* `@token` - the token that authenticated the current session
* `@user` - the context user, only available if `get_user` is called 

Try not to overload these variables. (Instead, utilize them!)

#### Roles

For convenience, rails-identity pre-defined four roles:

* Owner (1000) - the owner of the app
* Admin (100) - the admin(s) of the app
* User (10) - the user(s) of the app
* Public (0) - the rest of the world
