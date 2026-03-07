class CreatePhoneBans < ActiveRecord::Migration[7.2]
  def change
    create_table :phone_bans do |t|
      t.string :phone_e164, null: false
      t.integer :level, null: false, default: 0
      t.integer :source, null: false, default: 0
      t.string :reason, null: false
      t.boolean :active, null: false, default: true
      t.datetime :expires_at
      t.integer :trigger_count
      t.references :created_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :phone_bans, :phone_e164, unique: true
    add_index :phone_bans, :active
  end
end
