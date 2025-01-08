class CreateAppointments < ActiveRecord::Migration[7.2]
  def change
    create_table :appointments do |t|
      t.string :name
      t.integer :age
      t.string :email
      t.string :phone
      t.string :sex
      t.integer :doctor_id
      t.integer :package_id
      t.string :status
      t.datetime :start_date
      t.datetime :end_date
      t.integer :duration
      t.datetime :canceled_at
      t.text :cancellation_reason

      t.timestamps
    end
  end
end
