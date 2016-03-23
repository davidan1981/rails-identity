module RailsIdentity
  class ApplicationController < ActionController::Base
    include ApplicationHelper
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    # protect_from_forgery with: :exception

    # Most actions require a session token. If it is invalid, rescue the
    # exception and throw a 401 response.
    rescue_from Errors::InvalidTokenError, with: :invalid_token_error

    # Some actions require an object via id
    rescue_from Errors::ObjectNotFoundError do |exception|
      render_error 404, exception.message
    end

    # Authenticated but not authorized for the action
    rescue_from Errors::UnauthorizedError, with: :unauthorized_error

    def invalid_token_error
      render_error 401, "Invalid token"
    end

    def unauthorized_error
      render_error 401, "Unauthorized request"
    end

    def options()
      # echo back access-control-request-headers
      if request.headers["Access-Control-Request-Headers"]
        response["Access-Control-Allow-Headers"] = request.headers["Access-Control-Request-Headers"]
      end
      render body: "", status: 200
    end

    protected

      # Finds an object by model and UUID and throws an error (which will be
      # caught and re-thrown as an HTTP error.)
      def find_object(model, uuid, error=Errors::ObjectNotFoundError)
        obj = model.find_by_uuid(uuid)
        raise error, "#{model.name} #{uuid} cannot be found" if obj.nil? && !error.nil?
        return obj
      end

      # Requires a session for an action. Token must be specified in query
      # string or part of the JSON object.
      def require_token(required_role: 0)
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
          logger.warn("Invalid token")
          raise Errors::InvalidTokenError
        end
        @token = token
        @session = session
        @auth_user = auth_user
      end

      # Requires an admin session. All this means is that the session is
      # issued for an admin user (role == 1000).
      def require_admin_token
        require_token(required_role: 1000)
      end

      def authorized?(user)
        return (@auth_user.role >= 1000) || (user == @auth_user)
      end
  end
end
