class AddClinicalStatusToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments,
               :clinical_status,
               :integer,
               default: 0,
               null: false

    add_column :appointments,
               :attended_at,
               :datetime

    add_column :appointments,
               :clinical_check_in_id,
               :string

    add_column :appointments,
               :clinical_updated_at,
               :datetime

    add_index :appointments, :clinical_status
    add_index :appointments, :clinical_check_in_id
  end
end