# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: google/api/client.proto

require 'google/protobuf'

require 'google/api/launch_stage_pb'
require 'google/protobuf/descriptor_pb'
require 'google/protobuf/duration_pb'


descriptor_data = "\n\x17google/api/client.proto\x12\ngoogle.api\x1a\x1dgoogle/api/launch_stage.proto\x1a google/protobuf/descriptor.proto\x1a\x1egoogle/protobuf/duration.proto\"t\n\x16\x43ommonLanguageSettings\x12\x1e\n\x12reference_docs_uri\x18\x01 \x01(\tB\x02\x18\x01\x12:\n\x0c\x64\x65stinations\x18\x02 \x03(\x0e\x32$.google.api.ClientLibraryDestination\"\xfb\x03\n\x15\x43lientLibrarySettings\x12\x0f\n\x07version\x18\x01 \x01(\t\x12-\n\x0claunch_stage\x18\x02 \x01(\x0e\x32\x17.google.api.LaunchStage\x12\x1a\n\x12rest_numeric_enums\x18\x03 \x01(\x08\x12/\n\rjava_settings\x18\x15 \x01(\x0b\x32\x18.google.api.JavaSettings\x12-\n\x0c\x63pp_settings\x18\x16 \x01(\x0b\x32\x17.google.api.CppSettings\x12-\n\x0cphp_settings\x18\x17 \x01(\x0b\x32\x17.google.api.PhpSettings\x12\x33\n\x0fpython_settings\x18\x18 \x01(\x0b\x32\x1a.google.api.PythonSettings\x12/\n\rnode_settings\x18\x19 \x01(\x0b\x32\x18.google.api.NodeSettings\x12\x33\n\x0f\x64otnet_settings\x18\x1a \x01(\x0b\x32\x1a.google.api.DotnetSettings\x12/\n\rruby_settings\x18\x1b \x01(\x0b\x32\x18.google.api.RubySettings\x12+\n\x0bgo_settings\x18\x1c \x01(\x0b\x32\x16.google.api.GoSettings\"\xa8\x03\n\nPublishing\x12\x33\n\x0fmethod_settings\x18\x02 \x03(\x0b\x32\x1a.google.api.MethodSettings\x12\x15\n\rnew_issue_uri\x18\x65 \x01(\t\x12\x19\n\x11\x64ocumentation_uri\x18\x66 \x01(\t\x12\x16\n\x0e\x61pi_short_name\x18g \x01(\t\x12\x14\n\x0cgithub_label\x18h \x01(\t\x12\x1e\n\x16\x63odeowner_github_teams\x18i \x03(\t\x12\x16\n\x0e\x64oc_tag_prefix\x18j \x01(\t\x12;\n\x0corganization\x18k \x01(\x0e\x32%.google.api.ClientLibraryOrganization\x12;\n\x10library_settings\x18m \x03(\x0b\x32!.google.api.ClientLibrarySettings\x12)\n!proto_reference_documentation_uri\x18n \x01(\t\x12(\n rest_reference_documentation_uri\x18o \x01(\t\"\xe3\x01\n\x0cJavaSettings\x12\x17\n\x0flibrary_package\x18\x01 \x01(\t\x12L\n\x13service_class_names\x18\x02 \x03(\x0b\x32/.google.api.JavaSettings.ServiceClassNamesEntry\x12\x32\n\x06\x63ommon\x18\x03 \x01(\x0b\x32\".google.api.CommonLanguageSettings\x1a\x38\n\x16ServiceClassNamesEntry\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\r\n\x05value\x18\x02 \x01(\t:\x02\x38\x01\"A\n\x0b\x43ppSettings\x12\x32\n\x06\x63ommon\x18\x01 \x01(\x0b\x32\".google.api.CommonLanguageSettings\"A\n\x0bPhpSettings\x12\x32\n\x06\x63ommon\x18\x01 \x01(\x0b\x32\".google.api.CommonLanguageSettings\"\xcb\x01\n\x0ePythonSettings\x12\x32\n\x06\x63ommon\x18\x01 \x01(\x0b\x32\".google.api.CommonLanguageSettings\x12N\n\x15\x65xperimental_features\x18\x02 \x01(\x0b\x32/.google.api.PythonSettings.ExperimentalFeatures\x1a\x35\n\x14\x45xperimentalFeatures\x12\x1d\n\x15rest_async_io_enabled\x18\x01 \x01(\x08\"B\n\x0cNodeSettings\x12\x32\n\x06\x63ommon\x18\x01 \x01(\x0b\x32\".google.api.CommonLanguageSettings\"\xaa\x03\n\x0e\x44otnetSettings\x12\x32\n\x06\x63ommon\x18\x01 \x01(\x0b\x32\".google.api.CommonLanguageSettings\x12I\n\x10renamed_services\x18\x02 \x03(\x0b\x32/.google.api.DotnetSettings.RenamedServicesEntry\x12K\n\x11renamed_resources\x18\x03 \x03(\x0b\x32\x30.google.api.DotnetSettings.RenamedResourcesEntry\x12\x19\n\x11ignored_resources\x18\x04 \x03(\t\x12 \n\x18\x66orced_namespace_aliases\x18\x05 \x03(\t\x12\x1e\n\x16handwritten_signatures\x18\x06 \x03(\t\x1a\x36\n\x14RenamedServicesEntry\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\r\n\x05value\x18\x02 \x01(\t:\x02\x38\x01\x1a\x37\n\x15RenamedResourcesEntry\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\r\n\x05value\x18\x02 \x01(\t:\x02\x38\x01\"B\n\x0cRubySettings\x12\x32\n\x06\x63ommon\x18\x01 \x01(\x0b\x32\".google.api.CommonLanguageSettings\"@\n\nGoSettings\x12\x32\n\x06\x63ommon\x18\x01 \x01(\x0b\x32\".google.api.CommonLanguageSettings\"\xcf\x02\n\x0eMethodSettings\x12\x10\n\x08selector\x18\x01 \x01(\t\x12<\n\x0clong_running\x18\x02 \x01(\x0b\x32&.google.api.MethodSettings.LongRunning\x12\x1d\n\x15\x61uto_populated_fields\x18\x03 \x03(\t\x1a\xcd\x01\n\x0bLongRunning\x12\x35\n\x12initial_poll_delay\x18\x01 \x01(\x0b\x32\x19.google.protobuf.Duration\x12\x1d\n\x15poll_delay_multiplier\x18\x02 \x01(\x02\x12\x31\n\x0emax_poll_delay\x18\x03 \x01(\x0b\x32\x19.google.protobuf.Duration\x12\x35\n\x12total_poll_timeout\x18\x04 \x01(\x0b\x32\x19.google.protobuf.Duration*\xa3\x01\n\x19\x43lientLibraryOrganization\x12+\n\'CLIENT_LIBRARY_ORGANIZATION_UNSPECIFIED\x10\x00\x12\t\n\x05\x43LOUD\x10\x01\x12\x07\n\x03\x41\x44S\x10\x02\x12\n\n\x06PHOTOS\x10\x03\x12\x0f\n\x0bSTREET_VIEW\x10\x04\x12\x0c\n\x08SHOPPING\x10\x05\x12\x07\n\x03GEO\x10\x06\x12\x11\n\rGENERATIVE_AI\x10\x07*g\n\x18\x43lientLibraryDestination\x12*\n&CLIENT_LIBRARY_DESTINATION_UNSPECIFIED\x10\x00\x12\n\n\x06GITHUB\x10\n\x12\x13\n\x0fPACKAGE_MANAGER\x10\x14:9\n\x10method_signature\x12\x1e.google.protobuf.MethodOptions\x18\x9b\x08 \x03(\t:6\n\x0c\x64\x65\x66\x61ult_host\x12\x1f.google.protobuf.ServiceOptions\x18\x99\x08 \x01(\t:6\n\x0coauth_scopes\x12\x1f.google.protobuf.ServiceOptions\x18\x9a\x08 \x01(\t:8\n\x0b\x61pi_version\x12\x1f.google.protobuf.ServiceOptions\x18\xc1\xba\xab\xfa\x01 \x01(\tBi\n\x0e\x63om.google.apiB\x0b\x43lientProtoP\x01ZAgoogle.golang.org/genproto/googleapis/api/annotations;annotations\xa2\x02\x04GAPIb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool

begin
  pool.add_serialized_file(descriptor_data)
rescue TypeError
  # Compatibility code: will be removed in the next major version.
  require 'google/protobuf/descriptor_pb'
  parsed = Google::Protobuf::FileDescriptorProto.decode(descriptor_data)
  parsed.clear_dependency
  serialized = parsed.class.encode(parsed)
  file = pool.add_serialized_file(serialized)
  warn "Warning: Protobuf detected an import path issue while loading generated file #{__FILE__}"
  imports = [
    ["google.protobuf.Duration", "google/protobuf/duration.proto"],
  ]
  imports.each do |type_name, expected_filename|
    import_file = pool.lookup(type_name).file_descriptor
    if import_file.name != expected_filename
      warn "- #{file.name} imports #{expected_filename}, but that import was loaded as #{import_file.name}"
    end
  end
  warn "Each proto file must use a consistent fully-qualified name."
  warn "This will become an error in the next major version."
end

module Google
  module Api
    CommonLanguageSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.CommonLanguageSettings").msgclass
    ClientLibrarySettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.ClientLibrarySettings").msgclass
    Publishing = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.Publishing").msgclass
    JavaSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.JavaSettings").msgclass
    CppSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.CppSettings").msgclass
    PhpSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.PhpSettings").msgclass
    PythonSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.PythonSettings").msgclass
    PythonSettings::ExperimentalFeatures = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.PythonSettings.ExperimentalFeatures").msgclass
    NodeSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.NodeSettings").msgclass
    DotnetSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.DotnetSettings").msgclass
    RubySettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.RubySettings").msgclass
    GoSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.GoSettings").msgclass
    MethodSettings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.MethodSettings").msgclass
    MethodSettings::LongRunning = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.MethodSettings.LongRunning").msgclass
    ClientLibraryOrganization = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.ClientLibraryOrganization").enummodule
    ClientLibraryDestination = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("google.api.ClientLibraryDestination").enummodule
  end
end

#### Source proto file: google/api/client.proto ####
#
# // Copyright 2024 Google LLC
# //
# // Licensed under the Apache License, Version 2.0 (the "License");
# // you may not use this file except in compliance with the License.
# // You may obtain a copy of the License at
# //
# //     http://www.apache.org/licenses/LICENSE-2.0
# //
# // Unless required by applicable law or agreed to in writing, software
# // distributed under the License is distributed on an "AS IS" BASIS,
# // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# // See the License for the specific language governing permissions and
# // limitations under the License.
#
# syntax = "proto3";
#
# package google.api;
#
# import "google/api/launch_stage.proto";
# import "google/protobuf/descriptor.proto";
# import "google/protobuf/duration.proto";
#
# option go_package = "google.golang.org/genproto/googleapis/api/annotations;annotations";
# option java_multiple_files = true;
# option java_outer_classname = "ClientProto";
# option java_package = "com.google.api";
# option objc_class_prefix = "GAPI";
#
# extend google.protobuf.MethodOptions {
#   // A definition of a client library method signature.
#   //
#   // In client libraries, each proto RPC corresponds to one or more methods
#   // which the end user is able to call, and calls the underlying RPC.
#   // Normally, this method receives a single argument (a struct or instance
#   // corresponding to the RPC request object). Defining this field will
#   // add one or more overloads providing flattened or simpler method signatures
#   // in some languages.
#   //
#   // The fields on the method signature are provided as a comma-separated
#   // string.
#   //
#   // For example, the proto RPC and annotation:
#   //
#   //   rpc CreateSubscription(CreateSubscriptionRequest)
#   //       returns (Subscription) {
#   //     option (google.api.method_signature) = "name,topic";
#   //   }
#   //
#   // Would add the following Java overload (in addition to the method accepting
#   // the request object):
#   //
#   //   public final Subscription createSubscription(String name, String topic)
#   //
#   // The following backwards-compatibility guidelines apply:
#   //
#   //   * Adding this annotation to an unannotated method is backwards
#   //     compatible.
#   //   * Adding this annotation to a method which already has existing
#   //     method signature annotations is backwards compatible if and only if
#   //     the new method signature annotation is last in the sequence.
#   //   * Modifying or removing an existing method signature annotation is
#   //     a breaking change.
#   //   * Re-ordering existing method signature annotations is a breaking
#   //     change.
#   repeated string method_signature = 1051;
# }
#
# extend google.protobuf.ServiceOptions {
#   // The hostname for this service.
#   // This should be specified with no prefix or protocol.
#   //
#   // Example:
#   //
#   //   service Foo {
#   //     option (google.api.default_host) = "foo.googleapi.com";
#   //     ...
#   //   }
#   string default_host = 1049;
#
#   // OAuth scopes needed for the client.
#   //
#   // Example:
#   //
#   //   service Foo {
#   //     option (google.api.oauth_scopes) = \
#   //       "https://www.googleapis.com/auth/cloud-platform";
#   //     ...
#   //   }
#   //
#   // If there is more than one scope, use a comma-separated string:
#   //
#   // Example:
#   //
#   //   service Foo {
#   //     option (google.api.oauth_scopes) = \
#   //       "https://www.googleapis.com/auth/cloud-platform,"
#   //       "https://www.googleapis.com/auth/monitoring";
#   //     ...
#   //   }
#   string oauth_scopes = 1050;
#
#   // The API version of this service, which should be sent by version-aware
#   // clients to the service. This allows services to abide by the schema and
#   // behavior of the service at the time this API version was deployed.
#   // The format of the API version must be treated as opaque by clients.
#   // Services may use a format with an apparent structure, but clients must
#   // not rely on this to determine components within an API version, or attempt
#   // to construct other valid API versions. Note that this is for upcoming
#   // functionality and may not be implemented for all services.
#   //
#   // Example:
#   //
#   //   service Foo {
#   //     option (google.api.api_version) = "v1_20230821_preview";
#   //   }
#   string api_version = 525000001;
# }
#
# // Required information for every language.
# message CommonLanguageSettings {
#   // Link to automatically generated reference documentation.  Example:
#   // https://cloud.google.com/nodejs/docs/reference/asset/latest
#   string reference_docs_uri = 1 [deprecated = true];
#
#   // The destination where API teams want this client library to be published.
#   repeated ClientLibraryDestination destinations = 2;
# }
#
# // Details about how and where to publish client libraries.
# message ClientLibrarySettings {
#   // Version of the API to apply these settings to. This is the full protobuf
#   // package for the API, ending in the version element.
#   // Examples: "google.cloud.speech.v1" and "google.spanner.admin.database.v1".
#   string version = 1;
#
#   // Launch stage of this version of the API.
#   LaunchStage launch_stage = 2;
#
#   // When using transport=rest, the client request will encode enums as
#   // numbers rather than strings.
#   bool rest_numeric_enums = 3;
#
#   // Settings for legacy Java features, supported in the Service YAML.
#   JavaSettings java_settings = 21;
#
#   // Settings for C++ client libraries.
#   CppSettings cpp_settings = 22;
#
#   // Settings for PHP client libraries.
#   PhpSettings php_settings = 23;
#
#   // Settings for Python client libraries.
#   PythonSettings python_settings = 24;
#
#   // Settings for Node client libraries.
#   NodeSettings node_settings = 25;
#
#   // Settings for .NET client libraries.
#   DotnetSettings dotnet_settings = 26;
#
#   // Settings for Ruby client libraries.
#   RubySettings ruby_settings = 27;
#
#   // Settings for Go client libraries.
#   GoSettings go_settings = 28;
# }
#
# // This message configures the settings for publishing [Google Cloud Client
# // libraries](https://cloud.google.com/apis/docs/cloud-client-libraries)
# // generated from the service config.
# message Publishing {
#   // A list of API method settings, e.g. the behavior for methods that use the
#   // long-running operation pattern.
#   repeated MethodSettings method_settings = 2;
#
#   // Link to a *public* URI where users can report issues.  Example:
#   // https://issuetracker.google.com/issues/new?component=190865&template=1161103
#   string new_issue_uri = 101;
#
#   // Link to product home page.  Example:
#   // https://cloud.google.com/asset-inventory/docs/overview
#   string documentation_uri = 102;
#
#   // Used as a tracking tag when collecting data about the APIs developer
#   // relations artifacts like docs, packages delivered to package managers,
#   // etc.  Example: "speech".
#   string api_short_name = 103;
#
#   // GitHub label to apply to issues and pull requests opened for this API.
#   string github_label = 104;
#
#   // GitHub teams to be added to CODEOWNERS in the directory in GitHub
#   // containing source code for the client libraries for this API.
#   repeated string codeowner_github_teams = 105;
#
#   // A prefix used in sample code when demarking regions to be included in
#   // documentation.
#   string doc_tag_prefix = 106;
#
#   // For whom the client library is being published.
#   ClientLibraryOrganization organization = 107;
#
#   // Client library settings.  If the same version string appears multiple
#   // times in this list, then the last one wins.  Settings from earlier
#   // settings with the same version string are discarded.
#   repeated ClientLibrarySettings library_settings = 109;
#
#   // Optional link to proto reference documentation.  Example:
#   // https://cloud.google.com/pubsub/lite/docs/reference/rpc
#   string proto_reference_documentation_uri = 110;
#
#   // Optional link to REST reference documentation.  Example:
#   // https://cloud.google.com/pubsub/lite/docs/reference/rest
#   string rest_reference_documentation_uri = 111;
# }
#
# // Settings for Java client libraries.
# message JavaSettings {
#   // The package name to use in Java. Clobbers the java_package option
#   // set in the protobuf. This should be used **only** by APIs
#   // who have already set the language_settings.java.package_name" field
#   // in gapic.yaml. API teams should use the protobuf java_package option
#   // where possible.
#   //
#   // Example of a YAML configuration::
#   //
#   //  publishing:
#   //    java_settings:
#   //      library_package: com.google.cloud.pubsub.v1
#   string library_package = 1;
#
#   // Configure the Java class name to use instead of the service's for its
#   // corresponding generated GAPIC client. Keys are fully-qualified
#   // service names as they appear in the protobuf (including the full
#   // the language_settings.java.interface_names" field in gapic.yaml. API
#   // teams should otherwise use the service name as it appears in the
#   // protobuf.
#   //
#   // Example of a YAML configuration::
#   //
#   //  publishing:
#   //    java_settings:
#   //      service_class_names:
#   //        - google.pubsub.v1.Publisher: TopicAdmin
#   //        - google.pubsub.v1.Subscriber: SubscriptionAdmin
#   map<string, string> service_class_names = 2;
#
#   // Some settings.
#   CommonLanguageSettings common = 3;
# }
#
# // Settings for C++ client libraries.
# message CppSettings {
#   // Some settings.
#   CommonLanguageSettings common = 1;
# }
#
# // Settings for Php client libraries.
# message PhpSettings {
#   // Some settings.
#   CommonLanguageSettings common = 1;
# }
#
# // Settings for Python client libraries.
# message PythonSettings {
#   // Experimental features to be included during client library generation.
#   // These fields will be deprecated once the feature graduates and is enabled
#   // by default.
#   message ExperimentalFeatures {
#     // Enables generation of asynchronous REST clients if `rest` transport is
#     // enabled. By default, asynchronous REST clients will not be generated.
#     // This feature will be enabled by default 1 month after launching the
#     // feature in preview packages.
#     bool rest_async_io_enabled = 1;
#   }
#
#   // Some settings.
#   CommonLanguageSettings common = 1;
#
#   // Experimental features to be included during client library generation.
#   ExperimentalFeatures experimental_features = 2;
# }
#
# // Settings for Node client libraries.
# message NodeSettings {
#   // Some settings.
#   CommonLanguageSettings common = 1;
# }
#
# // Settings for Dotnet client libraries.
# message DotnetSettings {
#   // Some settings.
#   CommonLanguageSettings common = 1;
#
#   // Map from original service names to renamed versions.
#   // This is used when the default generated types
#   // would cause a naming conflict. (Neither name is
#   // fully-qualified.)
#   // Example: Subscriber to SubscriberServiceApi.
#   map<string, string> renamed_services = 2;
#
#   // Map from full resource types to the effective short name
#   // for the resource. This is used when otherwise resource
#   // named from different services would cause naming collisions.
#   // Example entry:
#   // "datalabeling.googleapis.com/Dataset": "DataLabelingDataset"
#   map<string, string> renamed_resources = 3;
#
#   // List of full resource types to ignore during generation.
#   // This is typically used for API-specific Location resources,
#   // which should be handled by the generator as if they were actually
#   // the common Location resources.
#   // Example entry: "documentai.googleapis.com/Location"
#   repeated string ignored_resources = 4;
#
#   // Namespaces which must be aliased in snippets due to
#   // a known (but non-generator-predictable) naming collision
#   repeated string forced_namespace_aliases = 5;
#
#   // Method signatures (in the form "service.method(signature)")
#   // which are provided separately, so shouldn't be generated.
#   // Snippets *calling* these methods are still generated, however.
#   repeated string handwritten_signatures = 6;
# }
#
# // Settings for Ruby client libraries.
# message RubySettings {
#   // Some settings.
#   CommonLanguageSettings common = 1;
# }
#
# // Settings for Go client libraries.
# message GoSettings {
#   // Some settings.
#   CommonLanguageSettings common = 1;
# }
#
# // Describes the generator configuration for a method.
# message MethodSettings {
#   // Describes settings to use when generating API methods that use the
#   // long-running operation pattern.
#   // All default values below are from those used in the client library
#   // generators (e.g.
#   // [Java](https://github.com/googleapis/gapic-generator-java/blob/04c2faa191a9b5a10b92392fe8482279c4404803/src/main/java/com/google/api/generator/gapic/composer/common/RetrySettingsComposer.java)).
#   message LongRunning {
#     // Initial delay after which the first poll request will be made.
#     // Default value: 5 seconds.
#     google.protobuf.Duration initial_poll_delay = 1;
#
#     // Multiplier to gradually increase delay between subsequent polls until it
#     // reaches max_poll_delay.
#     // Default value: 1.5.
#     float poll_delay_multiplier = 2;
#
#     // Maximum time between two subsequent poll requests.
#     // Default value: 45 seconds.
#     google.protobuf.Duration max_poll_delay = 3;
#
#     // Total polling timeout.
#     // Default value: 5 minutes.
#     google.protobuf.Duration total_poll_timeout = 4;
#   }
#
#   // The fully qualified name of the method, for which the options below apply.
#   // This is used to find the method to apply the options.
#   //
#   // Example:
#   //
#   //    publishing:
#   //      method_settings:
#   //      - selector: google.storage.control.v2.StorageControl.CreateFolder
#   //        # method settings for CreateFolder...
#   string selector = 1;
#
#   // Describes settings to use for long-running operations when generating
#   // API methods for RPCs. Complements RPCs that use the annotations in
#   // google/longrunning/operations.proto.
#   //
#   // Example of a YAML configuration::
#   //
#   //    publishing:
#   //      method_settings:
#   //      - selector: google.cloud.speech.v2.Speech.BatchRecognize
#   //        long_running:
#   //          initial_poll_delay: 60s # 1 minute
#   //          poll_delay_multiplier: 1.5
#   //          max_poll_delay: 360s # 6 minutes
#   //          total_poll_timeout: 54000s # 90 minutes
#   LongRunning long_running = 2;
#
#   // List of top-level fields of the request message, that should be
#   // automatically populated by the client libraries based on their
#   // (google.api.field_info).format. Currently supported format: UUID4.
#   //
#   // Example of a YAML configuration:
#   //
#   //    publishing:
#   //      method_settings:
#   //      - selector: google.example.v1.ExampleService.CreateExample
#   //        auto_populated_fields:
#   //        - request_id
#   repeated string auto_populated_fields = 3;
# }
#
# // The organization for which the client libraries are being published.
# // Affects the url where generated docs are published, etc.
# enum ClientLibraryOrganization {
#   // Not useful.
#   CLIENT_LIBRARY_ORGANIZATION_UNSPECIFIED = 0;
#
#   // Google Cloud Platform Org.
#   CLOUD = 1;
#
#   // Ads (Advertising) Org.
#   ADS = 2;
#
#   // Photos Org.
#   PHOTOS = 3;
#
#   // Street View Org.
#   STREET_VIEW = 4;
#
#   // Shopping Org.
#   SHOPPING = 5;
#
#   // Geo Org.
#   GEO = 6;
#
#   // Generative AI - https://developers.generativeai.google
#   GENERATIVE_AI = 7;
# }
#
# // To where should client libraries be published?
# enum ClientLibraryDestination {
#   // Client libraries will neither be generated nor published to package
#   // managers.
#   CLIENT_LIBRARY_DESTINATION_UNSPECIFIED = 0;
#
#   // Generate the client library in a repo under github.com/googleapis,
#   // but don't publish it to package managers.
#   GITHUB = 10;
#
#   // Publish the library to package managers like nuget.org and npmjs.com.
#   PACKAGE_MANAGER = 20;
# }
