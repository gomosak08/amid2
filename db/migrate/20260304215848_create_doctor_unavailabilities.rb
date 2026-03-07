class CreateDoctorUnavailabilities < ActiveRecord::Migration[7.2]
  def change
    create_table :doctor_unavailabilities do |t|
      t.references :doctor, null: false, foreign_key: true
      t.date :date, null: false
      t.string :reason
      t.timestamps
    end

    add_index :doctor_unavailabilities, [ :doctor_id, :date ], unique: true
  end
end
