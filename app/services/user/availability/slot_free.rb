# app/services/availability/slot_free.rb
# frozen_string_literal: true

module User::Availability
  class SlotFree
    def self.call(doctor_id:, start_date:)
      true
    end
  end
end
