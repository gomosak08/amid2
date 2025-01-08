class AddUniqueCodeToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :appointments, :unique_code, :string
  end
end
