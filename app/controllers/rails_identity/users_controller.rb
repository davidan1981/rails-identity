require_dependency "rails_identity/application_controller"

module RailsIdentity
  
  ##
  # Users controller that performs CRUD on users.
  #
  class UsersController < ApplicationController

    # All except user creation requires a session token. Note that reset
    # token is also a legit session token, so :require_token will suffice.
    prepend_before_action :require_token, only: [:show, :destroy]
    prepend_before_action :accept_token, only: [:update, :create]
    prepend_before_action :require_admin_token, only: [:index]

    # Some actions must have a user specified.
    before_action :get_user, only: [:show, :destroy]

    ##
    # List all users (but only works for admin user).
    #
    def index
      @users = User.all
      render json: @users, except: [:password_digest]
    end

    ##
    # Creates a new user. This action does not require any auth although it
    # is optional.
    #
    def create
      @user = User.new(user_params)
      if @user.save
        render json: @user, except: [:password_digest], status: 201
      else
        render_errors 400, @user.errors.full_messages
      end
    end

    ## 
    # Renders a user data.
    #
    def show
      render json: @user, except: [:password_digest], methods: [:role]
    end

    ##
    # Patches the user. Some overloading operations here. There are three
    # notable ways to update a user.
    #
    #   - Issue a reset token
    #     If params has :issue_reset_token set to true, the action will
    #     issue a reset token for the user and returns 204. Yes, 204 No
    #     Content. TODO: in the future, the action will trigger an email.
    #   - Reset the password
    #     Two ways to reset password:
    #       - Provide the old password along with the new password and
    #         confirmation.
    #       - Provide the reset token as the auth token.
    #   - Change other data
    #
    def update
      if params[:issue_reset_token]
        # For issuing a reset token, one does not need an auth token. so do
        # not authorize the request.
        raise Errors::UnauthorizedError unless params[:id] == "current"
        get_user_for_reset_token()
        raise Errors::UnauthorizedError unless params[:username] == @user.username
        update_reset_token()
      else
        get_user()
        if params[:password]
          if params[:old_password]
            raise Errors::UnauthorizedError unless @user.authenticate(params[:old_password])
          else
            raise Errors::UnauthorizedError unless @token == @user.reset_token
          end
        end
        update_user(user_params)
      end
    end

    ##
    # Deletes a user.
    #
    def destroy
      if @user.destroy
        render body: '', status: 204
      else
        # :nocov:
        render_error 500, "Something went wrong!"
        # :nocov:
      end
    end

    protected

      ## 
      # This method normally updates the user using permitted params.
      #
      def update_user(update_user_params)
        if @user.update_attributes(update_user_params)
          render json: @user, except: [:password_digest, :reset_token]
        else
          render_errors 400, @user.errors.full_messages
        end
      end

      ##
      # This method updates user with a new reset token. Only used for this
      # operation.
      #
      def update_reset_token
        @user.issue_reset_token()
        @user.save
        render body: '', status: 204
        UserMailer.password_reset(@user).deliver_later
      end

    private

      ##
      # This overrides the application controller's get_user method. Since
      # resource object of this users controller is user, the id is
      # specified in :id param.
      #
      def get_user
        params[:id] = @auth_user.id if params[:id] == "current"
        @user = find_object(User, params[:id])
        raise Errors::UnauthorizedError unless authorized?(@user)
        return @user
      end

      ##
      # For issuing a new reset token, use this method to get user.
      #
      def get_user_for_reset_token
        @user = User.find_by_username(params[:username])
        raise Errors::ObjectNotFoundError if @user.nil?
        return @user
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
