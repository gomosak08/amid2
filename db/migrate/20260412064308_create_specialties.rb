class CreateSpecialties < ActiveRecord::Migration[7.2]
  def change
    create_table :specialties do |t|
      t.string :name

      t.timestamps
    end
  end
end
