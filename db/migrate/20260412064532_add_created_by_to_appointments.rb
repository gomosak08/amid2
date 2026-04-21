class AddCreatedByToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_reference :appointments, :created_by, null: true, foreign_key: { to_table: :users }
  end
end
