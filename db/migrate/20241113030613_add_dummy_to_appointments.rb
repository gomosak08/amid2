class AddDummyToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :appointments, :dummy, :boolean
  end
end
