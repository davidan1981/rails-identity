require "rails_identity/engine"
require "rails_identity/cache"

module RailsIdentity

  # App MUST monkey patch this constant
  MAILER_EMAIL = "no-reply@rails-identity.com"

  # Fixed set of roles.
  module Roles
    PUBLIC = 0
    USER = 10
    ADMIN = 100
    OWNER = 1000
  end

end
