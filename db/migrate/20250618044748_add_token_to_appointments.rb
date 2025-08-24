class AddTokenToAppointments < ActiveRecord::Migration[7.2]
  def change
   unless column_exists?(:appointments, :token)
      add_column :appointments, :token, :string
      add_index  :appointments, :token, unique: true
    end
  end
end
