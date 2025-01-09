class RemoveImageFromPackages < ActiveRecord::Migration[7.2]
  def change
    remove_column :packages, :image, :string
  end
end
