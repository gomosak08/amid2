class CreateDoctorCalendarBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :doctor_calendar_blocks do |t|
      t.references :doctor, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean :all_day, null: false, default: false
      t.text :reason
      t.string :source, null: false, default: "amid"
      t.string :api_idempotency_key
      t.datetime :canceled_at
      t.timestamps
    end

    add_index :doctor_calendar_blocks,
              :api_idempotency_key,
              unique: true,
              where: "api_idempotency_key IS NOT NULL"
    add_index :doctor_calendar_blocks,
              %i[doctor_id starts_at ends_at],
              name: "idx_doctor_calendar_blocks_range"
  end
end