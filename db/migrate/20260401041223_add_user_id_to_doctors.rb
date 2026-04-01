class AddUserIdToDoctors < ActiveRecord::Migration[7.2]
  def change
    add_reference :doctors, :user, null: true, foreign_key: true
  end
end
