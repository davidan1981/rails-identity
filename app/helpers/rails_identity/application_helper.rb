module RailsIdentity
  module ApplicationHelper
    def get_user
      @user = User.find_by_uuid(params[:user_id])
      if @user.nil?
        render_error(404, "Cannot find user #{params[:user_id]}")
      end
      return @user
    end

    def render_error(status, msg)
      render json: {errors: [msg]}, status: status
    end

    def render_errors(status, msgs)
      render json: {errors: msgs}, status: status
    end

  end
end
