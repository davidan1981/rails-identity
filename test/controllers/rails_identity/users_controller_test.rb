require 'json'
require 'test_helper'

module RailsIdentity
  class UsersControllerTest < ActionController::TestCase

    setup do
      @routes = Engine.routes
      @session = rails_identity_sessions(:one)
      @token = @session.token
    end

    test "public can see options" do
      @request.headers["Access-Control-Request-Headers"] = "GET"
      get :options
      assert_response :success
      assert_equal "GET", @response.headers["Access-Control-Allow-Headers"]
    end

    test "admin can list all users" do 
      @session = rails_identity_sessions(:admin_one)
      @token = @session.token
      get :index, token: @token
      assert_response :success
      users = assigns(:users)
      assert_not_nil users
      assert_equal Session.count, users.length
    end

    test "non-admin cannot list users" do
      get :index, token: @token
      assert_response 401
    end

    test "create a user" do
      post :create, username: "foo@example.com", password: "secret",
           password_confirmation: "secret"
      assert_response :success
      user = assigns(:user)
      assert_not_nil user
      assert user.username = "foo@example.com"
      json = JSON.parse(@response.body)
      assert_equal "foo@example.com", json["username"]
      assert_not json.has_key?("password_digest")
    end 

    test "user cannot create an admin user" do
      post :create, username: "foo@example.com", password: "secret",
           password_confirmation: "secret", role: Roles::ADMIN
      assert_response :success
      user = assigns(:user)
      assert_not_nil user
      assert_equal Roles::USER, user.role
    end

    test "admin can create an admin user" do
      @session = rails_identity_sessions(:admin_one)
      @token = @session.token
      post :create, username: "foo@example.com", password: "secret",
           password_confirmation: "secret", role: Roles::ADMIN, token: @token
      assert_response :success
      user = assigns(:user)
      assert_not_nil user
      assert_equal Roles::ADMIN, user.role
    end

    test "cannot create a user without username" do
      post :create, password: "secret",
           password_confirmation: "secret"
      assert_response 400
      json = JSON.parse(@response.body)
      assert 0 < json["errors"].length
    end 

    test "cannot create a user without a password" do
      post :create, username: "foo@example.com"
      assert_response 400
      json = JSON.parse(@response.body)
      assert_equal 1, json["errors"].length
    end 

    test "show a user" do
      get :show, id: 1, token: @token
      assert_response 200
      json = JSON.parse(@response.body)
      assert_equal rails_identity_users(:one).username, json["username"]
    end

    test "show a current user" do
      get :show, id: "current", token: @token
      assert_response 200
      json = JSON.parse(@response.body)
      assert_equal rails_identity_users(:one).username, json["username"]
    end

    test "cannot show other user" do
      get :show, id: 2, token: @token
      assert_response 401
    end

    test "admin can show other user" do
      @session = rails_identity_sessions(:admin_one)
      @token = @session.token
      get :show, id: 1, token: @token
      assert_response :success
    end

    test "cannot show a nonexisting user" do
      get :show, id: 999, token: @token
      assert_response 404
      json = JSON.parse(@response.body)
      assert_equal 1, json["errors"].length
    end

    test "update a user" do
      patch :update, id: 1, username: 'foo@example.com', token: @token
      assert_response 200
      json = JSON.parse(@response.body)
      assert_equal "foo@example.com", json["username"]
    end

    test "update current user" do
      patch :update, id: "current", username: 'foo@example.com', token: @token
      assert_response 200
      json = JSON.parse(@response.body)
      assert_equal "foo@example.com", json["username"]
    end

    test "update (issue) a new reset token" do
      patch :update, id: 1, issue_reset_token: true, token: @token
      assert_response 200
      json = JSON.parse(@response.body)
      new_reset_token = json["reset_token"]
      assert_not_nil new_reset_token
      patch :update, id: 1, username: "foo@example.com", token: @token
      assert_response 200
      json = JSON.parse(@response.body)
      assert_equal "foo@example.com", json["username"]
      assert_equal new_reset_token, json["reset_token"]
    end

    test "cannot update invalid email" do
      patch :update, id: 1, username: 'foobar', token: @token
      assert_response 400
    end

    test "cannot update another user" do
      patch :update, id: 2, username: 'foo@example.com', token: @token
      assert_response 401
    end

    test "delete a user" do
      delete :destroy, id: 1, token: @token
      assert_response 204
    end

    test "delete current user" do
      delete :destroy, id: "current", token: @token
      assert_response 204
    end

    test "cannot delete another user" do
      delete :destroy, id: 2, token: @token
      assert_response 401
    end

    test "admin can delete other user" do
      @session = rails_identity_sessions(:admin_one)
      @token = @session.token
      delete :destroy, id: 1, token: @token
      assert_response :success
    end

  end
end
