# app/models/doctor.rb
class Doctor < ApplicationRecord
    has_many :appointments, dependent: :destroy 
    
    def available_hours
      JSON.parse(super || '{}')
    end
  
    def available_hours=(value)
      super(value.to_json)
    end
  end
  