class AddCanUploadResultsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_upload_results, :boolean, default: false
  end
end
