# frozen_string_literal: true

class Admin::StatisticsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_or_assistant

  def index
    from = params[:from].presence ? Date.parse(params[:from]) : Date.current.beginning_of_month
    to   = params[:to].presence ? Date.parse(params[:to]) : Date.current.end_of_month
    
    base_query = Appointment.where(start_date: from.beginning_of_day..to.end_of_day)

    @appointments_by_doctor = base_query
      .includes(:doctor)
      .group(:doctor_id)
      .count
      .transform_keys { |k| Doctor.find_by(id: k)&.name || "Sin Médico" }

    @appointments_by_creator = base_query
      .includes(:created_by)
      .group(:created_by_id)
      .count
      .transform_keys { |k| User.find_by(id: k)&.name || "Paciente/Desconocido" }
  end

  private

  def require_admin_or_assistant
    unless current_user&.admin? || current_user&.assistant?
      redirect_to root_path, alert: "No tienes permiso para acceder a estadísticas."
    end
  end
end
