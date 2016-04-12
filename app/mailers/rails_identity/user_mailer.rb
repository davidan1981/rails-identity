module RailsIdentity
  class UserMailer < ApplicationMailer

    def email_verification(user)
      @user = user
      mail(to: @user.username, subject: "[rails-identity] Email Confirmation")
    end

    def password_reset(user)
      @user = user
      mail(to: @user.username, subject: "[rails-identity] Password Reset")
    end
  end
end
