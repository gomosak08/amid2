class RemoveCancellationReasonFromAppointments < ActiveRecord::Migration[7.2]
  def change
    remove_column :appointments, :cancellation_reason, :text
  end
end
