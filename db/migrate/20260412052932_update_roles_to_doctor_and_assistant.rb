class UpdateRolesToDoctorAndAssistant < ActiveRecord::Migration[7.2]
  def up
    User.where(role: "medic").update_all(role: "doctor")
    User.where(role: "secretary").update_all(role: "assistant")
  end

  def down
    User.where(role: "doctor").update_all(role: "medic")
    User.where(role: "assistant").update_all(role: "secretary")
  end
end
