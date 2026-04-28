# frozen_string_literal: true

class Admin::StatisticsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_or_assistant

  def index
    @from = parse_date(params[:from]) || Date.current.beginning_of_month
    @to   = parse_date(params[:to]) || Date.current.end_of_month

    @doctor_options  = Doctor.order(:name)
    @package_options = Package.order(:kind, :name)
    @creator_options = User
      .where(id: Appointment.where.not(created_by_id: nil).distinct.select(:created_by_id))
      .order(:role, :name, :email)

    doctor_ids  = normalize_ids(params[:doctor_ids])
    package_ids = normalize_ids(params[:package_ids])
    creator_filters = Array(params[:creator_filters]).reject(&:blank?)
    statuses    = Array(params[:statuses]).reject(&:blank?)

    scope = Appointment
      .includes(:doctor, :package, :created_by)
      .where(start_date: @from.beginning_of_day..@to.end_of_day)

    scope = scope.where(doctor_id: doctor_ids) if doctor_ids.any?
    scope = scope.where(package_id: package_ids) if package_ids.any?
    if creator_filters.any?
      creator_ids = creator_filters.filter_map do |value|
        value.to_s.start_with?("user:") ? value.to_s.delete_prefix("user:").to_i : nil
      end
      include_patient = creator_filters.include?("patient")

      if include_patient && creator_ids.any?
        scope = scope.where(created_by_id: creator_ids + [ nil ])
      elsif include_patient
        scope = scope.where(created_by_id: nil)
      elsif creator_ids.any?
        scope = scope.where(created_by_id: creator_ids)
      end
    end
    scope = scope.where(status: statuses) if statuses.any?

    @appointments = scope.order(start_date: :desc).to_a
    @completed_appointments = @appointments.select(&:completed?)

    @summary = {
      total: @appointments.size,
      scheduled: @appointments.count(&:scheduled?),
      completed: @appointments.count(&:completed?),
      canceled: @appointments.count { |appointment| appointment.canceled_by_admin? || appointment.canceled_by_client? },
      no_show: @appointments.count(&:no_show?),
      revenue: @completed_appointments.sum { |appointment| appointment.package&.price.to_d }
    }

    @appointments_by_doctor = @appointments
      .group_by(&:doctor)
      .map do |doctor, appointments|
        {
          doctor: doctor,
          doctor_name: doctor&.name.presence || "Sin médico",
          total: appointments.size,
          completed: appointments.count(&:completed?),
          canceled: appointments.count { |appointment| appointment.canceled_by_admin? || appointment.canceled_by_client? },
          revenue: appointments
            .select(&:completed?)
            .sum { |appointment| appointment.package&.price.to_d }
        }
      end
      .sort_by { |row| [-row[:total], row[:doctor_name]] }

    @appointments_by_creator = @appointments
      .group_by(&:created_by)
      .map do |creator, appointments|
        {
          creator: creator,
          creator_label: creator_label_for(creator),
          total: appointments.size,
          completed: appointments.count(&:completed?),
          scheduled: appointments.count(&:scheduled?)
        }
      end
      .sort_by { |row| [-row[:total], row[:creator_label]] }

  end

  private

  def parse_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def normalize_ids(values)
    Array(values).reject(&:blank?).map(&:to_i).uniq
  end

  def creator_label_for(creator)
    return "Paciente / sin usuario" if creator.blank?

    role_label =
      case creator.role
      when "admin" then "Administrador"
      when "assistant" then "Asistente"
      when "doctor" then "Médico"
      else "Usuario"
      end

    base_name = creator.try(:name).presence || creator.email.to_s.split("@").first
    "#{role_label} - #{base_name}"
  end

  def require_admin_or_assistant
    unless current_user&.admin? || current_user&.assistant?
      redirect_to root_path, alert: "No tienes permiso para acceder a estadísticas."
    end
  end
end
