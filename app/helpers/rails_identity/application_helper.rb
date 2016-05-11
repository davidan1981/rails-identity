module RailsIdentity
  module ApplicationHelper
    include Repia::BaseHelper

    ##
    # Helper method to get the user object in the request, which is
    # specified by :user_id parameter. There are two ways to specify the
    # user id--one in the routing or the auth context.
    #
    # An Repia::Errors::Unauthorized is raised if the authenticated user is
    # not authorized for the specified user information.
    #
    # An Repia::Errors::NotFound is raised if the specified user cannot
    # be found.
    # 
    def get_user(fallback: true)
      user_id = params[:user_id]
      logger.debug("Attempting to get user #{user_id}")
      if !user_id.nil? && user_id != "current"
        @user = find_object(User, params[:user_id])  # will throw error if nil
        unless authorized?(@user)
          raise Repia::Errors::Unauthorized,
                "Not authorized to access user #{user_id}"
        end
      elsif fallback || user_id == "current"
        @user = @auth_user
      else
        # :nocov:
        raise Repia::Errors::NotFound, "User #{user_id} does not exist"
        # :nocov:
      end
    end

    ##
    # :method: require_auth
    #
    # Requires authentication. Either token or api key must be present.
    #

    ##
    # :method: require_admin_auth
    #
    # Requires admin authentication. Either token or api key of admin must
    # be present.
    #

    ##
    # :method: accept_auth
    #
    # Accepts authentication if present. Either token or api key is accepted.
    #

    ##
    # :method: require_token
    #
    # Requires authentication. Token must be present.
    #

    ##
    # :method: require_admin_token
    #
    # Requires admin authentication. Admin token must # be present.
    #

    ##
    # :method: accept_token
    #
    # Accepts authentication if present. Only token is accepted.
    #
    ##
    # :method: require_api_key
    #
    # Requires authentication. API key must be present.
    #

    ##
    # :method: require_admin_api_key
    #
    # Requires admin authentication. Admin api key must be present.
    #

    ##
    # :method: accept_api_key
    #
    # Accepts authentication if present. Only api key is accepted.
    #

    #
    # Metaprogramming baby
    #
    ["auth", "token", "api_key"].each do |suffix|

      define_method "require_#{suffix}" do
        self.method("get_#{suffix}").call
      end

      define_method "require_admin_#{suffix}" do
        self.method("get_#{suffix}").call(required_role: Roles::ADMIN)
      end

      define_method "accept_#{suffix}" do
        begin
          self.method("get_#{suffix}").call
        rescue StandardError => e
          logger.debug("Suppressing error")
        end
      end
    end

    ##
    # Determines if the user is authorized for the object.
    #
    def authorized?(obj)
      logger.debug("Checking to see if authorized to access object")
      if @auth_user.nil?
        # :nocov:
        return false
        # :nocov:
      elsif @auth_user.role >= Roles::ADMIN
        return true
      elsif obj.is_a? User
        return obj == @auth_user
      else
        return obj.try(:user) == @auth_user
      end
    end

    protected

      ##
      # Attempts to retrieve the payload encoded in the token. It checks if
      # the token is "valid" according to JWT definition and not expired.
      #
      # An Repia::Errors::Unauthorized is raised if token cannot be decoded.
      #
      def get_token_payload(token)
        begin
          decoded = JWT.decode token, nil, false
        rescue JWT::DecodeError => e
          logger.error("Token decode error: #{e.message}")
          raise Repia::Errors::Unauthorized, "Invalid token: #{token}"
        end

        # At this point, we know that the token is not expired and
        # well formatted. Find out if the payload is well defined.
        payload = decoded[0]
        if payload.nil?
          # :nocov:
          logger.error("Token payload is nil: #{token}")
          raise Repia::Errors::Unauthorized, "Invalid token payload: #{token}"
          # :nocov:
        end
        return payload
      end

      ##
      # Truly verifies the token and its payload. It ensures the user and
      # session specified in the token payload are indeed valid. The
      # required role is also checked.
      #
      # An Repia::Errors::Unauthorized is thrown for all cases where token is
      # invalid.
      #
      def verify_token_payload(token, payload, required_role: Roles::PUBLIC)
        user_uuid = payload["user_uuid"]
        session_uuid = payload["session_uuid"]
        if user_uuid.nil? || session_uuid.nil?
          logger.error("User UUID or session UUID is nil")
          raise Repia::Errors::Unauthorized,
                "Invalid token payload content: #{token}"
        end
        logger.debug("Token well formatted for user #{user_uuid},
                     session #{session_uuid}")

        logger.debug("Cache miss. Try database.")
        auth_user = User.find_by_uuid(user_uuid)
        if auth_user.nil? || auth_user.role < required_role
          raise Repia::Errors::Unauthorized,
                "Well-formed but invalid user token: #{token}"
        end
        auth_session = Session.find_by_uuid(session_uuid)
        if auth_session.nil?
          raise Repia::Errors::Unauthorized,
                "Well-formed but invalid session token: #{token}"
        end
        begin
          JWT.decode token, auth_session.secret, true
        rescue JWT::DecodeError => e
          logger.error(e.message)
          raise Repia::Errors::Unauthorized, "Cannot verify token: #{token}"
        end
        logger.debug("Token well formatted and verified. Set cache.")
        return auth_session
      end

      ##
      # Attempt to get a token for the session. Token must be specified in
      # query string or part of the JSON object.
      #
      # Raises a Repia::Errors::Unauthorized if cached session has less role
      # than what's required.
      #
      def get_token(required_role: Roles::PUBLIC)
        token = params[:token]
        payload = get_token_payload(token)
        # Look up the cache. If present, use it and skip the verification.
        # Use token itself as part of the key so it's *verified*.
        @auth_session = Cache.get(kind: :session, token: token)
        if @auth_session.nil?
          @auth_session = verify_token_payload(token, payload,
                                               required_role: required_role)
          @auth_session.role  # NOTE: no-op
          Cache.set({kind: :session, token: token}, @auth_session)
        elsif @auth_session.role < required_role
          raise Repia::Errors::Unauthorized
        end
        @auth_user = @auth_session.user
        @token = @auth_session.token
      end

      ##
      # Get API key from the request.
      #
      # Raises a Repia::Errors::Unauthorized if API key is not valid (or not
      # provided).
      #
      def get_api_key(required_role: Roles::PUBLIC)
        api_key = params[:api_key]
        if api_key.nil?
          # This case is not likely, but as a safeguard in case migration
          # has not gone well.
          # :nocov:
          raise Repia::Errors::Unauthorized, "Invalid api key"
          # :nocov:
        end
        auth_user = User.find_by_api_key(api_key)
        if auth_user.nil? || auth_user.role < required_role
          raise Repia::Errors::Unauthorized, "Invalid api key"
        end
        @auth_user = auth_user
        @auth_session = nil
        @token = nil
      end

      ##
      # Get auth data from the request. The token takes the precedence.
      #
      def get_auth(required_role: Roles::USER)
        if params[:token]
          get_token(required_role: required_role)
        else
          get_api_key(required_role: required_role)
        end
      end
  end
end
