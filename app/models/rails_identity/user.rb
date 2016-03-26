module RailsIdentity
  class User < ActiveRecord::Base
    include UUIDModel
    acts_as_paranoid

    has_one :cart, foreign_key: "user_uuid", primary_key: "uuid"
    has_many :orders, foreign_key: "user_uuid", primary_key: "uuid"

    has_secure_password
    validates :username, presence: true, uniqueness: true,
              format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }
    validates :password, confirmation: true
    before_save :default_role

    alias_attribute :email, :username

    def default_role
      self.role ||= Roles::USER
    end

  end
end