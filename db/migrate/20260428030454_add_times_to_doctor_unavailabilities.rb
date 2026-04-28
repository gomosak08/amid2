class AddTimesToDoctorUnavailabilities < ActiveRecord::Migration[7.2]
  def change
    add_column :doctor_unavailabilities, :start_time, :time
    add_column :doctor_unavailabilities, :end_time, :time
  end
end
