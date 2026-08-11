class AddInternalApiFieldsToAppointments < ActiveRecord::Migration[7.2]
  def up
    add_column :appointments, :source, :string unless column_exists?(:appointments, :source)
    add_column :appointments, :external_patient_id, :string unless column_exists?(:appointments, :external_patient_id)
    add_column :appointments, :cancellation_reason, :text unless column_exists?(:appointments, :cancellation_reason)
    add_column :appointments, :canceled_by_source, :string unless column_exists?(:appointments, :canceled_by_source)
    add_column :appointments, :api_idempotency_key, :string unless column_exists?(:appointments, :api_idempotency_key)
    add_column :appointments, :api_request_digest, :string unless column_exists?(:appointments, :api_request_digest)

    unless index_exists?(:appointments, :api_idempotency_key, unique: true)
      add_index :appointments,
                :api_idempotency_key,
                unique: true,
                where: "api_idempotency_key IS NOT NULL"
    end
  end

  def down
    remove_index :appointments, :api_idempotency_key if index_exists?(:appointments, :api_idempotency_key)
    remove_column :appointments, :api_request_digest if column_exists?(:appointments, :api_request_digest)
    remove_column :appointments, :api_idempotency_key if column_exists?(:appointments, :api_idempotency_key)
    remove_column :appointments, :canceled_by_source if column_exists?(:appointments, :canceled_by_source)
    remove_column :appointments, :cancellation_reason if column_exists?(:appointments, :cancellation_reason)
    remove_column :appointments, :external_patient_id if column_exists?(:appointments, :external_patient_id)
    remove_column :appointments, :source if column_exists?(:appointments, :source)
  end
end