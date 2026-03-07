class CreateDoctorTimeBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :doctor_time_blocks do |t|
      t.references :doctor, null: false, foreign_key: true
      t.time :starts_at
      t.time :ends_at
      t.text :days_of_week
      t.string :reason

      t.timestamps
    end
  end
end
