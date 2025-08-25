# app/services/availability/slot_free.rb
# frozen_string_literal: true

module Availability
  class SlotFree
    def self.call(doctor_id:, start_date:)
      # TODO: true si el slot está libre
      true
    end
  end
end
