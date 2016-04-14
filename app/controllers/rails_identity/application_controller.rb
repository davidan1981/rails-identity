module RailsIdentity

  ##
  # The root application controller class in rails-identity.
  #
  class ApplicationController < ActionController::Base
    include ApplicationHelper

    # This is a catch-all.
    rescue_from StandardError do |exception|
      # :nocov:
      logger.error exception.message
      render_error 500, "Unknown error occurred: #{exception.message}"
      # :nocov:
    end

    # Most actions require a session token. If token is invalid, rescue the
    # exception and throw an HTTP 401 response.
    rescue_from Errors::InvalidTokenError do |exception|
      logger.error exception.message
      render_error 401, "Invalid token"
    end

    # Some actions require a resource object via id. If no such object
    # exists, throw an HTTP 404 response.
    rescue_from Errors::ObjectNotFoundError do |exception|
      logger.error exception.message
      render_error 404, exception.message
    end

    # The request is authenticated but not authorized for the specified
    # action. Throw an HTTP 401 response.
    #
    rescue_from Errors::UnauthorizedError do |exception|
      logger.error exception.message
      render_error 401, "Unauthorized request"
    end

    ##
    # Renders a generic OPTIONS response. The actual controller must
    # override this action if desired to have specific OPTIONS handling
    # logic.
    #
    def options()
      # echo back access-control-request-headers
      if request.headers["Access-Control-Request-Headers"]
        response["Access-Control-Allow-Headers"] = request.headers["Access-Control-Request-Headers"]
      end
      render body: "", status: 200
    end

    protected

      ##
      # Helper method to get the user object in the request context. There
      # are two ways to specify the user id--one in the routing or the auth
      # context. Only admin can actually specify the user id in the routing.
      #
      # A Errors::UnauthorizedError is raised if the authenticated user
      # is not authorized for the specified user information.
      #
      # A Errors::ObjectNotFoundError is raised if the specified user cannot
      # be found.
      # 
      def get_user(fallback: true)
        user_id = params[:user_id]
        logger.debug("Attempting to get user #{user_id}")
        if !user_id.nil? && user_id != "current"
          @user = find_object(User, params[:user_id])  # will throw error if nil
          unless authorized?(@user)
            raise Errors::UnauthorizedError, "Not authorized to access user #{user_id}"
          end
        elsif fallback || user_id == "current"
          @user = @auth_user
        else
          # :nocov:
          raise Errors::ObjectNotFoundError, "User #{user_id} does not exist"
          # :nocov:
        end
      end

      ##
      # Finds an object by model and UUID and throws an error (which will be
      # caught and re-thrown as an HTTP error.)
      #
      # A Errors::ObjectNotFoundError is raised if specified to do so when
      # the object could not be found using the uuid.
      #
      def find_object(model, uuid, error: Errors::ObjectNotFoundError)
        logger.debug("Attempting to get #{model.name} #{uuid}")
        obj = model.find_by_uuid(uuid)
        if obj.nil? && !error.nil?
          raise error, "#{model.name} #{uuid} cannot be found" 
        end
        return obj
      end

      ##
      # Attempt to get a token for the session. Token must be specified in query
      # string or part of the JSON object.
      #
      # A Errors::InvalidTokenError is raised if the JWT is malformed or not
      # valid against its secret.
      #
      def get_token(required_role: Roles::PUBLIC, suppress_error: false)
        token = params[:token]

        begin
          decoded = JWT.decode token, nil, false

          # At this point, we know that the token is not expired and
          # well formatted. Find out the session ID to look up in the cache.
          payload = decoded[0]
          user_uuid = payload["user_uuid"]
          session_uuid = payload["session_uuid"]
          logger.debug("Token well formatted for user #{user_uuid}, session #{session_uuid}")

          # Look up the cache. If present, use it and skip the verification.
          @auth_session = Rails.cache.fetch("#{CACHE_PREFIX}-session-#{session_uuid}")
          if @auth_session.nil?
            logger.debug("Cache miss. Try database.")
            auth_user = User.find_by_uuid(user_uuid)
            if auth_user.nil? || auth_user.role < required_role
              raise "Not valid user"
            end
            @auth_session = Session.find_by_uuid(session_uuid)
            raise "Not valid session" if @auth_session.nil?
            JWT.decode token, @auth_session.secret, true
            logger.debug("Token well formatted and verified. Set cache.")
            Rails.cache.write("#{CACHE_PREFIX}-session-#{session_uuid}", @auth_session)
          end
        rescue
          if suppress_error
            logger.info("Invalid token but suppressing error")
          else
            raise Errors::InvalidTokenError, "Invalid token: #{token}"
          end
        else
          @auth_user = @auth_session.user
          @token = @auth_session.token
        end
      end

      ## 
      # Requires a token.
      #
      def require_token
        logger.debug("Requires a token")
        get_token
      end

      ##
      # Accepts a token if present. If not, it's still ok.
      #
      def accept_token()
        logger.debug("Accepts a token")
        get_token(suppress_error: true)
      end

      ##
      # Requires an admin session. All this means is that the session is
      # issued for an admin user (role == 1000).
      #
      def require_admin_token
        logger.debug("Requires an admin token")
        get_token(required_role: Roles::ADMIN)
      end

      ##
      # Determines if the user is authorized for the object.
      #
      def authorized?(obj)
        logger.debug("Checking to see if authorized to access object")
        if !@auth_user
          # :nocov:
          return false
          # :nocov:
        elsif @auth_user.role >= Roles::ADMIN
          return true
        elsif obj.is_a? User
          return obj == @auth_user
        else
          return obj.user == @auth_user
        end
      end
  end
end
