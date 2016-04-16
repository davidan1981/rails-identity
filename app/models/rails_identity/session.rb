module RailsIdentity
  class Session < ActiveRecord::Base
    include UUIDModel
    # does not act as paranoid!

    belongs_to :user, foreign_key: "user_uuid", primary_key: "uuid"
    validates :user, presence: true

    ##
    # Creates a session object. The attributes must include user. The secret
    # to the JWT is generated here and is unique to the session being
    # created. Since the JWT includes the session id, the secret can be
    # retrieved.
    #
    def initialize(attributes = {})
      seconds = attributes.delete(:seconds) || (24 * 3600 * 14)
      super
      self.uuid = UUIDTools::UUID.timestamp_create().to_s
      iat = Time.now.to_i
      payload = {
        user_uuid: self.user.uuid,
        session_uuid: self.uuid,
        role: self.user.role,
        iat: iat,
        exp: iat + seconds
      }
      self.secret = UUIDTools::UUID.random_create
      self.token = JWT.encode(payload, self.secret, 'HS256')
    end

    ##
    # Determines if the session has expired or not.
    #
    def expired?
      begin
        JWT.decode self.token, nil, false
      rescue JWT::ExpiredSignature
        return true
      end
      return false
    end

  end
end
