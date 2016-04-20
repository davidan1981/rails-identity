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
        response["Access-Control-Allow-Headers"] =
            request.headers["Access-Control-Request-Headers"]
      end
      render body: "", status: 200
    end
  end
end
