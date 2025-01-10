class AddKindToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :kind, :string
  end
end
