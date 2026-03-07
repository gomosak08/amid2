class ChangeDaysOfWeekOnDoctorTimeBlocks < ActiveRecord::Migration[7.2]
  def change
    change_column :doctor_time_blocks, :days_of_week, :json, default: [], null: false
  end
end
