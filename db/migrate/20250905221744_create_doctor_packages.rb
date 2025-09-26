class CreateDoctorPackages < ActiveRecord::Migration[7.2]
  def change
    create_table :doctor_packages do |t|
      t.references :doctor,  null: false, foreign_key: true
      t.references :package, null: false, foreign_key: true

      t.timestamps
    end

    add_index :doctor_packages, [ :doctor_id, :package_id ], unique: true
  end
end
