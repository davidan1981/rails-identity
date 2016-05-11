require 'test_helper'

module RailsIdentity

  class TestsController < ApplicationController
    def index
      render json: {}, status: 200
    end
  end

  class TestsControllerTest < ActionController::TestCase
    setup do 
      Rails.cache.clear
      @session = rails_identity_sessions(:one)
      @token = @session.token
      @admin_session = rails_identity_sessions(:admin_one)
      @admin_token = @admin_session.token
      @api_key = rails_identity_users(:one).api_key
      @admin_api_key = rails_identity_users(:admin_one).api_key
      # Rails.application.routes.draw do
      RailsIdentity::Engine.routes.draw do
        match "tests" => "tests#index", via: [:get]
      end
      @routes = Engine.routes
    end

    teardown do
      RailsIdentity::Engine.routes.draw do
        resources :sessions
        match 'sessions(/:id)' => 'sessions#options', via: [:options]

        resources :users
        match 'users(/:id)' => 'users#options', via: [:options]
      end
    end

    test "require only token" do
      class ::RailsIdentity::TestsController < ApplicationController
        reset_callbacks :process_action
        before_action :require_token, only: [:index]
      end
      get :index, token: @token
      assert_response :success
      get :index
      assert_response 401
    end

    test "require only admin token" do
      class ::RailsIdentity::TestsController < ApplicationController
        reset_callbacks :process_action
        before_action :require_admin_token, only: [:index]
      end
      get :index, token: @admin_token
      assert_response :success
      Cache.set({kind: :session, token: @token}, @session) 
      get :index, token: @token
      assert_response 401
    end

    test "accept only token" do
      class ::RailsIdentity::TestsController < ApplicationController
        reset_callbacks :process_action
        before_action :accept_token, only: [:index]
      end
      get :index, token: @token
      assert_response :success
      get :index
      assert_response :success
    end

    test "require only api key" do
      class ::RailsIdentity::TestsController < ApplicationController
        reset_callbacks :process_action
        before_action :require_api_key, only: [:index]
      end
      get :index, api_key: @api_key
      assert_response :success
      get :index, token: @token
      assert_response 401
      get :index
      assert_response 401
    end

    test "require only admin api key" do
      class ::RailsIdentity::TestsController < ApplicationController
        reset_callbacks :process_action
        before_action :require_admin_api_key, only: [:index]
      end
      get :index, api_key: @admin_api_key
      assert_response :success
      get :index, api_key: @api_key
      assert_response 401
    end

    test "accept only api key" do
      class ::RailsIdentity::TestsController < ApplicationController
        reset_callbacks :process_action
        before_action :accept_api_key, only: [:index]
      end
      get :index, api_key: @api_key
      assert_response :success
      get :index
      assert_response :success
    end
  end
end
