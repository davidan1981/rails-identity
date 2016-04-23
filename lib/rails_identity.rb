require "rails_identity/engine"

module RailsIdentity

  # App MUST monkey patch this constant
  MAILER_EMAIL = "no-reply@rails-identity.com"

  # To be able to break cache when backwards compatibility breaks. Update it
  # only when compatibility breaks
  CACHE_PREFIX = "rails-identity-0.0.2"

  # Fixed set of roles.
  module Roles
    PUBLIC = 0
    USER = 10
    ADMIN = 100
    OWNER = 1000
  end

end
