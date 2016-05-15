module RailsIdentity
  class User < ActiveRecord::Base
    include Repia::UUIDModel
    acts_as_paranoid
    has_secure_password

    validates :username, uniqueness: true,
              format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,
                        on: [:create, :update] }
    validates :password, confirmation: true
    validate :valid_user
    before_save :default_role

    alias_attribute :email, :username

    ##
    # This method validates if the user object is valid. A user is valid if
    # username and password exist OR oauth integration exists.
    #
    def valid_user
      return (self.username && self.password) ||
             (self.oauth_provider && self.oauth_uid)
    end

    ##
    # Create a user from oauth.
    #
    def self.from_omniauth(auth)
      params = {
        oauth_provider: auth[:provider],
        oauth_uid: auth[:uid]
      }
      where(params).first_or_initialize.tap do |user|
        user.oauth_provider = auth.provider
        user.oauth_uid = auth.uid
        user.oauth_name = auth.info.name
        user.oauth_token = auth.credentials.token
        user.oauth_expires_at = Time.at(auth.credentials.expires_at)
        user.save!
      end
    end

    ##
    # Initializes the user. User is not verified initially. The user has one
    # hour to get verified. After that, a PATCH request must be made to
    # re-issue the verification token.
    #
    def initialize(attributes = {})
      attributes[:api_key] = SecureRandom.hex(32)
      super
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
