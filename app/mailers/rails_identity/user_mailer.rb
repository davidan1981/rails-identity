module RailsIdentity
  class UserMailer < ApplicationMailer
    def password_reset(user)
      @user = user
      mail(to: @user.username, subject: "Here is the link to reset password")
    end
  end
end
