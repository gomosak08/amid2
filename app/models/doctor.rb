# app/models/doctor.rb
class Doctor < ApplicationRecord
    has_many :appointments, dependent: :destroy 
    
    def available_hours
      JSON.parse(super || '{}')
    rescue JSON::ParserError
      {}
    end
  
    # Ensure available_hours is converted to a JSON string before saving
    def available_hours=(value)
      super(value.is_a?(String) ? value : value.to_json)
    end
  end
  