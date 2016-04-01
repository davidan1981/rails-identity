module RailsIdentity
  class ApplicationController < ActionController::Base
    include ApplicationHelper

    # Most actions require a session token. If token is invalid, rescue the
    # exception and throw an HTTP 401 response.
    rescue_from Errors::InvalidTokenError, with: :invalid_token_error

    # Some actions require a resource object via id. If no such object
    # exists, throw an HTTP 404 response.
    rescue_from Errors::ObjectNotFoundError do |exception|
      render_error 404, exception.message
    end

    # The request is authenticated but not authorized for the specified
    # action. Throw an HTTP 401 response.
    rescue_from Errors::UnauthorizedError, with: :unauthorized_error

    def invalid_token_error; render_error 401, "Invalid token" end
    def unauthorized_error; render_error 401, "Unauthorized request" end

    def options()
      # echo back access-control-request-headers
      if request.headers["Access-Control-Request-Headers"]
        response["Access-Control-Allow-Headers"] = request.headers["Access-Control-Request-Headers"]
      end
      render body: "", status: 200
    end

    protected

      # Helper method to get the user object in the request context. There
      # are two ways to specify the user id--one in the routing or the auth
      # context. Only admin can actually specify the user id in the routing.
      def get_user(fallback: true)
        user_id = params[:user_id]
        if !user_id.nil? && user_id != "current"
          @user = find_object(User, params[:user_id])  # will throw error if nil
          raise Errors::UnauthorizedError unless authorized?(@user)
        elsif fallback || user_id == "current"
          @user = @auth_user
        else
          # :nocov:
          raise Errors::ObjectNotFoundError
          # :nocov:
        end
      end

      # Finds an object by model and UUID and throws an error (which will be
      # caught and re-thrown as an HTTP error.)
      def find_object(model, uuid, error=Errors::ObjectNotFoundError)
        obj = model.find_by_uuid(uuid)
        if obj.nil? && !error.nil?
          raise error, "#{model.name} #{uuid} cannot be found" 
        end
        return obj
      end

      # Requires a session for an action. Token must be specified in query
      # string or part of the JSON object.
      def require_token(required_role: Roles::PUBLIC, suppress_error: false)
        begin 
          token = params[:token]
          decoded = JWT.decode token, nil, false
          raise "Could not decode" unless decoded
          payload = decoded[0]
          user_uuid = payload['user_uuid']
          logger.debug("Valid token for #{user_uuid}")
          auth_user = User.find_by_uuid(payload["user_uuid"])
          raise "User is not valid" unless auth_user
          raise "User has insufficient role" if auth_user.role < required_role
          session = Session.find_by_uuid(payload["session_uuid"])
          raise "Session is not valid" unless session
          JWT.decode token, session.secret, true
        rescue
          if !suppress_error
            logger.warn("Invalid token")
            raise Errors::InvalidTokenError
          end
        end
        @token = token
        @auth_session = session
        @auth_user = auth_user
      end

      # Requires an admin session. All this means is that the session is
      # issued for an admin user (role == 1000).
      def require_admin_token
        require_token(required_role: Roles::ADMIN)
      end

      def authorized?(user)
        return (@auth_user.role >= Roles::ADMIN) || (user == @auth_user)
      end
  end
end
