require_dependency "rails_identity/application_controller"

module RailsIdentity
  class SessionsController < ApplicationController
    prepend_before_action :require_token, except: [:create, :options]
    before_action :get_session, only: [:show, :destroy]
    before_action :get_user, only: [:index]

    # List all sessions that belong to the authenticated user.
    def index
      @sessions = Session.where(user: @user)
      render json: @sessions, except: [:secret]
    end

    # This action is essentially the login action. Note that get_user is not
    # triggered for this action because we will look at username first. That
    # would be the "normal" way to login. The alternative would be with the
    # token based authentication. If the latter doesn't make sense, just use
    # the username and password approach.
    def create
      @user = User.find_by_username(session_params[:username])
      if (@user && @user.authenticate(session_params[:password])) || get_user()
        @session = Session.new(user: @user)
        if @session.save
          render json: @session, except: [:secret], status: 201
        else
          # :nocov:
          render_errors 400, @session.full_error_messages
          # :nocov:
        end
      else
          render_error 401, "Invalid username or password"
      end
    end

    def show
      render json: @session
    end

    def destroy
      if @session.destroy
        render body: "", status: 204
      else 
        # :nocov:
        render_error 500, "Something went wrong. Oops!"
        # :nocov:
      end
    end

    private

      def get_session
        @session = find_object(Session, params[:id])
        raise Errors::UnauthorizedError unless authorized?(@session.user)
      end

      def session_params
        params.permit(:username, :password)
      end

  end
end
