require_dependency "rails_identity/application_controller"

module RailsIdentity
  class SessionsController < ApplicationController
    prepend_before_action :require_token, except: [:create, :options]
    before_action :get_session, only: [:show, :destroy]

    # List all sessions that belong to the authenticated user.
    def index
      @sessions = Session.where(user_uuid: @auth_user.uuid)
      render json: @sessions, except: [:secret]
    end

    # This action is essentially the login action
    def create
      @user = User.find_by_username(session_params[:username])
      if @user and @user.authenticate(session_params[:password])
        @session = Session.new(user: @user)
        if @session
          if @session.save
            render json: @session, except: [:secret], status: 201
          else
            render_errors 400, @session.full_error_messages
          end
        else
          render_errors 400, "Session cannot be created"
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
        render_error 500, "Something went wrong. Oops!"
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
