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
      logger.debug("Create new user")
      @user = User.new(user_params)
      if @user.save

        # Save succeeded. Render the response based on the created user.
        render json: @user, except: [:verification_token, :reset_token, :password_digest], status: 201

        # Then, issue the verification token and send the email for
        # verification.
        @user.issue_token(:verification_token)
        @user.save
        UserMailer.email_verification(@user).deliver_later
      else
        render_errors 400, @user.errors.full_messages
      end
    end

    ## 
    # Renders a user data.
    #
    def show
      render json: @user, except: [:password_digest]
    end

    ##
    # Patches the user. Some overloading operations here. There are five
    # notable ways to update a user.
    #
    #   - Issue a reset token
    #     If params has :issue_reset_token set to true, the action will
    #     issue a reset token for the user and returns 204. Yes, 204 No
    #     Content.
    #   - Reset the password
    #     Two ways to reset password:
    #       - Provide the old password along with the new password and
    #         confirmation.
    #       - Provide the reset token as the auth token.
    #   - Issue a verification token
    #   - Change other data
    #
    def update
      if params[:issue_reset_token] || params[:issue_verification_token]
        # For issuing a reset token, one does not need an auth token. so do
        # not authorize the request.
        raise Repia::Errors::Unauthorized unless params[:id] == "current"
        get_user_for_token()
        raise Repia::Errors::Unauthorized unless params[:username] == @user.username
        if params[:issue_reset_token]
          update_token(:reset_token)
        else
          update_token(:verification_token)
        end
      else
        get_user()
        if params[:password]
          if params[:old_password]
            raise Repia::Errors::Unauthorized unless @user.authenticate(params[:old_password])
          else
            raise Repia::Errors::Unauthorized unless @token == @user.reset_token
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
          render json: @user, except: [:password_digest]
        else
          render_errors 400, @user.errors.full_messages
        end
      end

      ##
      # This method updates user with a new reset token. Only used for this
      # operation.
      #
      def update_token(kind)
        @user.issue_token(kind)
        @user.save
        if kind == :reset_token
          UserMailer.password_reset(@user).deliver_later
        else
          UserMailer.email_verification(@user).deliver_later
        end
        render body: '', status: 204
      end

    private

      ##
      # This overrides the application controller's get_user method. Since
      # resource object of this users controller is user, the id is
      # specified in :id param.
      #
      def get_user
        if params[:id] == "current"
          raise Repia::Errors::Unauthorized if @auth_user.nil?
          params[:id] = @auth_user.uuid
        end
        @user = find_object(User, params[:id])
        raise Repia::Errors::Unauthorized unless authorized?(@user)
        return @user
      end

      ##
      # For issuing a new reset or for re-issuing a verification token, use
      # this method to get user.
      #
      def get_user_for_token
        @user = User.find_by_username(params[:username])
        raise Repia::Errors::NotFound if @user.nil?
        return @user
      end

      def user_params
        # Only ADMIN can assign the attribute role. The attribute value will
        # be ignored if the user is not an ADMIN.
        if @auth_user.try(:role).try(:>=, Roles::ADMIN)
          params.permit(:username, :password, :password_confirmation, :role, :verified)
        else
          params.permit(:username, :password, :password_confirmation, :verified)
        end
      end 

  end
end
