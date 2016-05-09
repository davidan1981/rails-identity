require_dependency "rails_identity/application_controller"

module RailsIdentity

  ##
  # This class is sessions controller that performs CRD on session objects.
  # Note that a token includes its session ID. Use "current" to look up a
  # session in the current context.
  #
  class SessionsController < ApplicationController

    prepend_before_action :require_auth, except: [:create, :options]
    before_action :get_session, only: [:show, :destroy]
    before_action :get_user, only: [:index]

    ##
    # Lists all sessions that belong to the specified or authenticated user. 
    #
    def index
      @sessions = Session.where(user: @user)
      expired = []
      active = []
      @sessions.each do |session|
        if session.expired?
          expired << session.uuid
        else
          active << session
        end
      end
      SessionsCleanupJob.perform_later(*expired)
      render json: active, except: [:secret]
    end

    ##
    # This action is essentially the login action. Note that get_user is not
    # triggered for this action because we will look at username first. That
    # would be the "normal" way to login. The alternative would be with the
    # token based authentication. If the latter doesn't make sense, just use
    # the username and password approach.
    #
    # A Repia::Errors::Unauthorized is thrown if user is not verified.
    #
    def create
      @user = User.find_by_username(session_params[:username])
      if (@user && @user.authenticate(session_params[:password])) || get_user()
        raise Repia::Errors::Unauthorized unless @user.verified
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

    ##
    # Shows a session information.
    #
    def show
      render json: @session, except: [:secret]
    end

    ##
    # Deletes a session.
    #
    def destroy
      if @session.destroy
        render body: "", status: 204
      else 
        # :nocov:
        render_error 400, @session.errors.full_messages
        # :nocov:
      end
    end

    private

      ##
      # Get the specified or current session.
      # 
      # A Repia::Errors::NotFound is raised if the session does not
      # exist (or deleted due to expiration).
      #
      # A Repia::Errors::Unauthorized is raised if the authenticated user
      # does not have authorization for the specified session.
      #
      def get_session
        session_id = params[:id]
        if session_id == "current"
          if @auth_session.nil?
            raise Repia::Errors::NotFound
          end
          session_id = @auth_session.id
        end
        @session = find_object(Session, session_id)
        if !authorized?(@session)
          raise Repia::Errors::Unauthorized
        elsif @session.expired?
          @session.destroy
          raise Repia::Errors::NotFound
        end
      end

      def session_params
        params.permit(:username, :password)
      end

  end
end
