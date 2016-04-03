module RailsIdentity
  module ApplicationHelper

    ##
    # Renders a single error.
    #
    def render_error(status, msg)
      render json: {errors: [msg]}, status: status
    end

    ##
    # Renders multiple errors
    #
    def render_errors(status, msgs)
      render json: {errors: msgs}, status: status
    end

  end
end
