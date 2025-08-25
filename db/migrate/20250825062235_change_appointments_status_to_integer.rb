class ChangeAppointmentsStatusToInteger < ActiveRecord::Migration[7.2]
  def up
    # Si tenías strings descriptivos, convénselos antes (opcional según tus datos)
    execute "UPDATE appointments SET status = '0' WHERE status IS NULL OR status = '' OR status = 'scheduled';"
    execute "UPDATE appointments SET status = '1' WHERE status = 'canceled_by_admin';"
    execute "UPDATE appointments SET status = '2' WHERE status = 'canceled_by_client';"

    change_column :appointments, :status, :integer, default: 0, null: false
  end

  def down
    change_column :appointments, :status, :string
  end
end
