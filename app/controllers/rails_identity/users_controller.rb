require_dependency "rails_identity/application_controller"

module RailsIdentity
  class UsersController < ApplicationController

    # All except user creation requires a session token. Note that reset
    # token is also a legit session token, so :require_token will suffice.
    prepend_before_action :require_token, except: [:index, :create, :options]
    prepend_before_action :require_admin_token, only: [:index]

    # Some actions must have a user specified.
    before_action :get_user, only: [:show, :update, :destroy]

    # List all users (but only works for admin user).
    def index
      @users = User.all
      render json: @users, except: [:password_digest]
    end

    def create
      require_token(suppress_error: true)
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

    # Patches the user. It updates :reset_token only if :issue_reset_token
    # is set to true. It will not update :reset_token directly.
    def update
      update_params = user_params

      if params[:issue_reset_token]
        @user.issue_reset_token
        # maybe send the token via email?
      end

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
        # :nocov:
        render_error 500, "Something went wrong!"
        # :nocov:
      end
    end

    private

      # This overrides the application controller's get_user method. Since
      # resource object of this users controller is user, the id is
      # specified in :id param.
      def get_user
        params[:id] = @auth_user.id if params[:id] == "current"
        @user = find_object(User, params[:id])
        raise Errors::UnauthorizedError unless authorized?(@user)
      end

      def user_params
        # Only ADMIN can assign the attribute role. The attribute value will
        # be ignored if the user is not an ADMIN.
        if @auth_user.try(:role).try(:>=, Roles::ADMIN)
          params.permit(:username, :password, :password_confirmation, :role)
        else
          params.permit(:username, :password, :password_confirmation)
        end
      end 

  end
end
