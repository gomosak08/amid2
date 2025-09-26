class AddScheduledByToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :appointments, :scheduled_by, :integer
  end
end
