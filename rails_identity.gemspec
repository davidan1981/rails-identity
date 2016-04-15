$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_identity/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails-identity"
  s.version     = RailsIdentity::VERSION
  s.authors     = ["David An"]
  s.email       = ["davidan1981@gmail.com"]
  s.homepage    = "https://github.com/davidan1981/rails_identity"
  s.summary     = "rails-identity is a Rails engine that provides a simple JWT-based session management service."
  s.description = "See README.md"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.3"
  s.add_dependency "bcrypt", "~> 3.1.7"
  s.add_dependency "uuidtools", "~> 2.1.5"
  s.add_dependency "jwt", "~> 1.5.4"
  s.add_dependency "paranoia", "~> 2.0"
  s.add_dependency "simplecov"
  s.add_dependency "coveralls"

  s.add_development_dependency "sqlite3"
end
