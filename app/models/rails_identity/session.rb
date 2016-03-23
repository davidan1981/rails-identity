module RailsIdentity
  class Session < ActiveRecord::Base
    include UUIDModel
    # does not act as paranoid!

    belongs_to :user, foreign_key: "user_uuid", primary_key: "uuid"
    validates :user, presence: true

    # Creates a session object. The attributes must include user.
    def initialize(attributes={})
      super
      self.uuid = UUIDTools::UUID.timestamp_create().to_s
      iat = Time.now.to_i
      payload = {
        user_uuid: self.user_uuid,
        session_uuid: self.uuid,
        role: self.user.role,
        iat: iat,
        exp: iat + 14 * 3600
      }
      self.secret = UUIDTools::UUID.random_create
      self.token = JWT.encode(payload, self.secret, 'HS256')
    end

  end
end
