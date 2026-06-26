# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  #before_action :require_admin, only: [:destroy_user_session]

  protect_from_forgery with: :exception


  
  private

  def appointment_booking_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("APPOINTMENT_BOOKING_ENABLED", "1"))
  end

  def ensure_appointment_booking_enabled!
    return if appointment_booking_enabled?

    redirect_to root_path,
                alert: "El agendado en línea está temporalmente desactivado por pruebas. Por favor no agendes por ahora.",
                status: :see_other
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied.'
    end
  end
end
