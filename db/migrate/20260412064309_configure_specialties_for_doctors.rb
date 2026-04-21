class ConfigureSpecialtiesForDoctors < ActiveRecord::Migration[7.2]
  def up
    add_reference :doctors, :specialty, null: true, foreign_key: true
    
    Doctor.reset_column_information
    Doctor.find_each do |doctor|
      val = doctor.read_attribute(:specialty)
      if val.present? && val.is_a?(String)
        sp = Specialty.find_or_create_by!(name: val)
        doctor.update_column(:specialty_id, sp.id)
      end
    end

    remove_column :doctors, :specialty, :string
  end

  def down
    add_column :doctors, :specialty, :string
    
    Doctor.reset_column_information
    Doctor.find_each do |doctor|
      if doctor.specialty_id.present?
        str = Specialty.find_by(id: doctor.specialty_id)&.name
        doctor.update_column(:specialty, str) if str
      end
    end
    
    remove_reference :doctors, :specialty
  end
end
