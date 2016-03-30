module RailsIdentity
  module ApplicationHelper
    def render_error(status, msg)
      render json: {errors: [msg]}, status: status
    end

    def render_errors(status, msgs)
      render json: {errors: msgs}, status: status
    end

  end
end
