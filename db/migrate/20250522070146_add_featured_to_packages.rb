class AddFeaturedToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :featured, :boolean
  end
end
