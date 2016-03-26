require "rails_identity/engine"

module RailsIdentity

  # Fixed set of roles.
  module Roles
    PUBLIC = 0
    USER = 10
    ADMIN = 100
    OWNER = 1000
  end

  # Errors defined by RailsIdentity
  module Errors
    class InvalidTokenError < StandardError; end
    class ObjectNotFoundError < StandardError; end
    class UnauthorizedError < StandardError; end
  end

  # This module is a mixin that allows the model to use UUIDs instead of
  # normal IDs. By including this module, the model class declares that the
  # primary key is called "uuid" and an UUID is generated right before
  # save(). You may assign an UUID prior to save, in which case, no new UUID
  # will be generated.
  module UUIDModel

    def self.included(klass)
      # Triggered when this module is included.

      klass.primary_key = "uuid"
      klass.before_create :generate_uuid
    end

    def generate_uuid()
      # Generates an UUID for the model object only if it hasn't been assigned
      # one yet.

      if self.uuid.nil?
        self.uuid = UUIDTools::UUID.timestamp_create().to_s
      end
    end
  end

end