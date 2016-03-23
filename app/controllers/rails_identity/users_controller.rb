require_dependency "rails_identity/application_controller"

module RailsIdentity
  class UsersController < ApplicationController
    # All except user creation requires a session token.
    prepend_before_action :require_token, except: [:index, :create, :options]
    prepend_before_action :require_admin_token, only: [:index]

    # Some actions must have a user specified.
    before_action :get_user, only: [:show, :update, :destroy]

    # List all users (but only works for admin user)
    def index
      @users = User.all
      render json: @users, except: [:password_digest]
    end

    def create
      @user = User.new(user_params)
      if @user.save
        render json: @user, except: [:password_digest], status: 201
      else
        render_errors 400, @user.errors.full_messages
      end
    end

    def show
      render json: @user, except: [:password_digest], methods: [:role]
    end

    def update
      if @user.update_attributes(user_params)
        render json: @user, except: [:password_digest]
      else
        render_errors 400, @user.errors.full_messages
      end
    end

    def destroy
      if @user.destroy
        render body: '', status: 204
      else
        render_error 500, "Something went wrong!"
      end
    end

    private

      def get_user
        @user = find_object(User, params[:id])
        raise Errors::UnauthorizedError unless authorized?(@user)
      end

      def user_params
        params.permit(:username, :password, :password_confirmation)
      end 

  end
end
