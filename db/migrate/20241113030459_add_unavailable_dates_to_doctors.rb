class AddUnavailableDatesToDoctors < ActiveRecord::Migration[7.2]
  def change
    add_column :doctors, :unavailable_dates, :text
  end
end
