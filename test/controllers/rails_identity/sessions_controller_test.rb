require 'test_helper'

module RailsIdentity
  class SessionsControllerTest < ActionController::TestCase
    setup do
      Rails.cache.clear
      @routes = Engine.routes
      @session = rails_identity_sessions(:one)
      @token = @session.token
    end

    test "public can see options" do
      get :options
      assert_response :success
    end

    test "user can list all his sessions" do 
      get :index, token: @token
      assert_response :success
      sessions = assigns(:sessions)
      assert_not_nil sessions
      all_his_sessions = Session.where(user: @session.user)
      assert_equal sessions.length, all_his_sessions.length
      sessions.each do |session|
        assert session.user == @session.user
      end
    end

    test "user can list all his sessions using user id in routing" do
      get :index, user_id: @session.user.uuid, token: @token
      assert_response :success
      sessions = assigns(:sessions)
      assert_not_nil sessions
      all_his_sessions = Session.where(user: @session.user)
      assert_equal sessions.length, all_his_sessions.length
      sessions.each do |session|
        assert session.user == @session.user
      end
    end

    test "user cannot list expired session" do
      session = Session.new(user: @session.user, seconds: -1)
      session.save()
      get :index, user_id: session.user.uuid, token: @token
      assert_response :success
      json = JSON.parse(@response.body)
      assert_equal 1, json.length
    end

    test "user cannot list other's sessions" do
      get :index, user_id: rails_identity_users(:two), token: @token
      assert_response 401
    end

    test "public cannot list sessions" do
      get :index
      assert_response 401
    end

    test "create a session" do
      user = rails_identity_users(:one)
      post :create, username: user.username, password: "password"
      assert_response :success
      session = assigns(:session)
      assert_not_nil session
      json = JSON.parse(@response.body)
      assert json.has_key?("token")
      assert !json.has_key?("secret")
    end 

    test "cannot create a session if not verified" do
      user = rails_identity_users(:one)
      user.verified = false
      user.save()
      post :create, username: user.username, password: "password"
      assert_response 401
    end 

    test "cannot create a session with non-existent username" do
      post :create, username: 'idontexist', password: "secret"
      assert_response 401
      json = JSON.parse(@response.body)
      assert json["errors"].length == 1
    end 

    test "cannot create a session without username" do
      post :create, password: "secret"
      assert_response 401
      json = JSON.parse(@response.body)
      assert json["errors"].length == 1
    end 

    test "cannot create a session without a password" do
      post :create, username: rails_identity_users(:one).username
      assert_response 401
      json = JSON.parse(@response.body)
      assert json["errors"].length == 1
    end 

    test "cannot create a session with a wrong password" do
      post :create, username: rails_identity_users(:one).username, password: "notsecret"
      assert_response 401
      json = JSON.parse(@response.body)
      assert json["errors"].length == 1
    end 

    test "public cannot create sessions" do
      get :index
      assert_response 401
    end

    test "show a session" do
      get :show, id: 1, token: @token
      assert_response 200
      json = JSON.parse(@response.body)
      assert_equal @token, json["token"]
      # Do a quick cache check
      session = Rails.cache.fetch("#{CACHE_PREFIX}-session-#{json["token"]}")
      assert_not_nil session
      assert_equal @token, session.token
    end

    test "show a current session" do
      get :show, id: "current", token: @token
      assert_response 200
      json = JSON.parse(@response.body)
      assert_equal @token, json["token"]
    end

    test "cannot show other's session" do
      get :show, id: 2, token: @token
      assert_response 401
    end

    test "cannot show expired session" do
      session = Session.new(user: @session.user, seconds: -1)
      session.save()
      get :show, id: session.uuid, token: @token
      assert_response 404
    end

    test "public cannot show session" do
      get :show, id:1
      assert_response 401
    end

    test "admin can show other's session" do
      @session = rails_identity_sessions(:admin_one)
      @token = @session.token
      get :show, id: 1, token: @token
      assert_response :success
      json = JSON.parse(@response.body)
      session = rails_identity_sessions(:one)
      assert_equal session.token, json["token"]
    end

    test "cannot show a nonexisting session" do
      get :show, id: 999, token: @token
      assert_response 404
      json = JSON.parse(@response.body)
      assert json["errors"].length == 1
    end

    test "delete a session" do
      delete :destroy, id: 1, token: @token
      assert_response 204
    end

    test "delete a current session" do
      delete :destroy, id: "current", token: @token
      assert_response 204
    end

    test "cannot delete a non-existent session" do
      delete :destroy, id: 999, token: @token
      assert_response 404
    end

    test "cannot delete other's session" do
      delete :destroy, id: 2, token: @token
      assert_response 401
    end

    test "admin can delete other's session" do
      @session = rails_identity_sessions(:admin_one)
      @token = @session.token
      delete :destroy, id: 1, token: @token
      assert_response :success
    end

  end
end
