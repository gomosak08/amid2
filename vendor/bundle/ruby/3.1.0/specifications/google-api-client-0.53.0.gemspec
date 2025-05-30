# -*- encoding: utf-8 -*-
# stub: google-api-client 0.53.0 ruby lib generated

Gem::Specification.new do |s|
  s.name = "google-api-client".freeze
  s.version = "0.53.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "documentation_uri" => "https://googleapis.dev/ruby/google-api-client/v0.53.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze, "generated".freeze]
  s.authors = ["Steven Bazyl".freeze, "Tim Emiola".freeze, "Sergio Gomes".freeze, "Bob Aman".freeze]
  s.date = "2021-01-18"
  s.email = ["sbazyl@google.com".freeze]
  s.homepage = "https://github.com/google/google-api-ruby-client".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.post_install_message = "*******************************************************************************\nThe google-api-client gem is deprecated and will likely not be updated further.\n\nInstead, please install the gem corresponding to the specific service to use.\nFor example, to use the Google Drive V3 client, install google-apis-drive_v3.\nFor more information, see the FAQ in the OVERVIEW.md file or the YARD docs.\n*******************************************************************************\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Client for accessing Google APIs".freeze

  s.installed_by_version = "3.3.7" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<google-apis-core>.freeze, ["~> 0.1"])
    s.add_runtime_dependency(%q<google-apis-generator>.freeze, ["~> 0.1"])
  else
    s.add_dependency(%q<google-apis-core>.freeze, ["~> 0.1"])
    s.add_dependency(%q<google-apis-generator>.freeze, ["~> 0.1"])
  end
end
