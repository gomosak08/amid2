class CreatePackages < ActiveRecord::Migration[7.2]
  def change
    create_table :packages do |t|
      t.string :name
      t.text :description
      t.string :image
      t.decimal :price
      t.integer :duration

      t.timestamps
    end
  end
end
