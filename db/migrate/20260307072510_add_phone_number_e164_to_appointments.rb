class AddPhoneNumberE164ToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :appointments, :phone_number_e164, :string
  end
end
