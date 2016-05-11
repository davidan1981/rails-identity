require "rails_identity/engine"
require "rails_identity/cache"
require "rails_identity/roles"

module RailsIdentity

  # App MUST monkey patch this constant
  MAILER_EMAIL = "no-reply@rails-identity.com"

end
