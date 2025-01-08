class CreateDoctors < ActiveRecord::Migration[7.2]
  def change
    create_table :doctors do |t|
      t.string :name
      t.string :specialty
      t.string :email
      t.text :available_hours

      t.timestamps
    end
  end
end
