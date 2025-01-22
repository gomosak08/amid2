# -*- encoding: utf-8 -*-
# stub: google-cloud-recaptcha_enterprise-v1beta1 0.15.2 ruby lib

Gem::Specification.new do |s|
  s.name = "google-cloud-recaptcha_enterprise-v1beta1".freeze
  s.version = "0.15.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Google LLC".freeze]
  s.date = "2024-10-15"
  s.description = "reCAPTCHA Enterprise is a service that protects your site from spam and abuse. Note that google-cloud-recaptcha_enterprise-v1beta1 is a version-specific client library. For most uses, we recommend installing the main client library google-cloud-recaptcha_enterprise instead. See the readme for more details.".freeze
  s.email = "googleapis-packages@google.com".freeze
  s.homepage = "https://github.com/googleapis/google-cloud-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Help protect your website from fraudulent activity, spam, and abuse without creating friction.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<gapic-common>.freeze, [">= 0.21.1", "< 2.a"])
  s.add_runtime_dependency(%q<google-cloud-errors>.freeze, ["~> 1.0"])
end
