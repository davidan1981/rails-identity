Gem.loaded_specs['rails-identity'].dependencies.each do |d|
 require d.name
end

module RailsIdentity
  class Engine < ::Rails::Engine
    isolate_namespace RailsIdentity
  end
end
