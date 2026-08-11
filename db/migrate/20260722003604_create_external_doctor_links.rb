class CreateExternalDoctorLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :external_doctor_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :source_system
      t.string :external_doctor_id
      t.string :external_doctor_name
      t.boolean :active

      t.timestamps
    end
  end
end
