class AddGoogleCalendarIdToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :appointments, :google_calendar_id, :string
  end
end
