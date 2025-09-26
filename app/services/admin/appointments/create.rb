# app/services/admin/appointments/create.rb
# frozen_string_literal: true

module Admin
  module Appointments
    class Create
      def self.call(params:, package:, caller_role:)
        ::User::Appointments::Create.call(
          params: params,
          package: package,
          caller_role: caller_role
        )
      end
    end
  end
end
