# -*- encoding: utf-8 -*-
# stub: tailwindcss-rails 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "tailwindcss-rails".freeze
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 3.2.0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/rails/tailwindcss-rails", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2024-10-15"
  s.email = "david@loudthinking.com".freeze
  s.homepage = "https://github.com/rails/tailwindcss-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Integrate Tailwind CSS with the asset pipeline in Rails.".freeze

  s.installed_by_version = "3.3.7" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<railties>.freeze, [">= 7.0.0"])
    s.add_runtime_dependency(%q<tailwindcss-ruby>.freeze, [">= 0"])
  else
    s.add_dependency(%q<railties>.freeze, [">= 7.0.0"])
    s.add_dependency(%q<tailwindcss-ruby>.freeze, [">= 0"])
  end
end
