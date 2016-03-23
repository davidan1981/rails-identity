$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_identity/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_identity"
  s.version     = RailsIdentity::VERSION
  s.authors     = ["David An"]
  s.email       = ["davidan1981@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of RailsIdentity."
  s.description = "TODO: Description of RailsIdentity."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.3"

  s.add_development_dependency "sqlite3"
end
