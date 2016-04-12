module RailsIdentity
  class User < ActiveRecord::Base
    include UUIDModel
    acts_as_paranoid
    has_secure_password

    validates :username, presence: true, uniqueness: true,
              format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,
                        on: [:create, :update] }
    validates :password, confirmation: true
    before_save :default_role

    alias_attribute :email, :username

    ##
    # Initializes the user. User is not verified initially. The user has one
    # hour to get verified. After that, a PATCH request must be made to
    # re-issue the verification token.
    #
    def initialize(attributes = {})
      super
      session = Session.new(user: self, seconds: 3600)
      self.verification_token = session.token
      self.verified = false
    end

    ##
    # Sets the default the role for the user if not set.
    #
    def default_role
      self.role ||= Roles::USER
    end

    ##
    # This method will generate a reset token that lasts for an hour.
    #
    def issue_token(kind)
      session = Session.new(user: self, seconds: 3600)
      session.save
      if kind == :reset_token
        self.reset_token = session.token
      elsif kind == :verification_token
        self.verification_token = session.token
      end
    end

  end
end
