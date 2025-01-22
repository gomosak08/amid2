# -*- encoding: utf-8 -*-
# stub: google-cloud-recaptcha_enterprise 1.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "google-cloud-recaptcha_enterprise".freeze
  s.version = "1.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Google LLC".freeze]
  s.date = "2024-08-09"
  s.description = "reCAPTCHA Enterprise is a service that protects your site from spam and abuse.".freeze
  s.email = "googleapis-packages@google.com".freeze
  s.homepage = "https://github.com/googleapis/google-cloud-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "API Client library for the reCAPTCHA Enterprise API".freeze

  s.installed_by_version = "3.3.7" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<google-cloud-core>.freeze, ["~> 1.6"])
    s.add_runtime_dependency(%q<google-cloud-recaptcha_enterprise-v1>.freeze, [">= 0.17", "< 2.a"])
    s.add_runtime_dependency(%q<google-cloud-recaptcha_enterprise-v1beta1>.freeze, [">= 0.12", "< 2.a"])
  else
    s.add_dependency(%q<google-cloud-core>.freeze, ["~> 1.6"])
    s.add_dependency(%q<google-cloud-recaptcha_enterprise-v1>.freeze, [">= 0.17", "< 2.a"])
    s.add_dependency(%q<google-cloud-recaptcha_enterprise-v1beta1>.freeze, [">= 0.12", "< 2.a"])
  end
end
