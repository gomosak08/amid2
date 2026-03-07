# app/controllers/admin/doctors_controller.rb
module Admin
  class DoctorsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_doctor, except: %i[index new create]

    def index
      @doctors = Doctor.all
    end

    def new
      @doctor = Doctor.new
    end

    def create
      @doctor = Doctor.new(doctor_params)

      if @doctor.save
        redirect_to admin_doctors_path, notice: "Doctor was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @doctor.available_hours ||= default_hours
      @doctor.available_hours = normalize_hours(@doctor.available_hours)

      @unavailabilities = @doctor.doctor_unavailabilities.order(:date)
      @time_blocks = @doctor.doctor_time_blocks.order(:starts_at)
    end

    def update
      if @doctor.update(doctor_params)
        redirect_to admin_doctors_path, notice: "Doctor was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @doctor.destroy
      redirect_to admin_doctors_path, notice: "Doctor was successfully deleted."
    end

    # ===========================
    # Bloqueo día completo
    # ===========================
    def mark_unavailable_day
      date = params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
      reason = params[:reason].presence

      DoctorUnavailability.create!(
        doctor: @doctor,
        date: date,
        reason: reason
      )

      redirect_to edit_admin_doctor_path(@doctor),
                  notice: "Doctor marcado como no disponible para #{I18n.l(date)}."
    rescue ActiveRecord::RecordNotUnique
      redirect_to edit_admin_doctor_path(@doctor),
                  alert: "Ese día ya estaba marcado como no disponible."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_admin_doctor_path(@doctor),
                  alert: e.record.errors.full_messages.to_sentence
    rescue ArgumentError
      redirect_to edit_admin_doctor_path(@doctor),
                  alert: "Fecha inválida."
    end

    def mark_unavailable_range
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      reason = params[:reason].presence

      if end_date < start_date
        redirect_to edit_admin_doctor_path(@doctor), alert: "El rango es inválido."
        return
      end

      (start_date..end_date).each do |date|
        DoctorUnavailability.find_or_create_by!(doctor: @doctor, date: date) do |u|
          u.reason = reason
        end
      end

      redirect_to edit_admin_doctor_path(@doctor),
                  notice: "Bloqueado del #{I18n.l(start_date)} al #{I18n.l(end_date)}."
    rescue ArgumentError
      redirect_to edit_admin_doctor_path(@doctor),
                  alert: "Fechas inválidas."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_admin_doctor_path(@doctor),
                  alert: e.record.errors.full_messages.to_sentence
    end

    def destroy_unavailability
      id = params[:unavailability_id].to_i
      record = @doctor.doctor_unavailabilities.find_by(id: id)

      unless record
        redirect_to edit_admin_doctor_path(@doctor),
                    alert: "No se encontró un bloqueo de día completo con ese ID para este doctor."
        return
      end

      record.destroy
      redirect_to edit_admin_doctor_path(@doctor),
                  notice: "Bloqueo de día completo eliminado."
    end

    # ===========================
    # Bloqueos recurrentes por hora
    # ===========================
    def create_time_block
      days = Array(params[:days_of_week]).map(&:to_i)
      reason = params[:reason].presence

      Time.use_zone("America/Mexico_City") do
        starts_at = Time.zone.parse(params[:starts_at].to_s)
        ends_at = Time.zone.parse(params[:ends_at].to_s)

        block = @doctor.doctor_time_blocks.new(
          starts_at: starts_at,
          ends_at: ends_at,
          days_of_week: days,
          reason: reason
        )

        if block.save
          redirect_to edit_admin_doctor_path(@doctor), notice: "Bloqueo recurrente creado."
        else
          redirect_to edit_admin_doctor_path(@doctor), alert: block.errors.full_messages.to_sentence
        end
      end
    rescue ArgumentError
      redirect_to edit_admin_doctor_path(@doctor),
                  alert: "Horario inválido."
    end

    def destroy_time_block
      id = params[:time_block_id].to_i
      block = @doctor.doctor_time_blocks.find_by(id: id)

      unless block
        redirect_to edit_admin_doctor_path(@doctor),
                    alert: "No se encontró un bloqueo recurrente con ese ID para este doctor."
        return
      end

      block.destroy
      redirect_to edit_admin_doctor_path(@doctor),
                  notice: "Bloqueo recurrente eliminado."
    end

    # ===========================
    # Calendario
    # ===========================
    def calendar_events
      tz = "America/Mexico_City"

      Time.use_zone(tz) do
        start_date = params[:start].present? ? Time.zone.parse(params[:start]).to_date : Date.current
        end_date = params[:end].present? ? Time.zone.parse(params[:end]).to_date : (Date.current + 30)

        events = []

        # 1) Bloqueos de día completo
        unavails = @doctor.doctor_unavailabilities.where(date: start_date..end_date)
        blocked_dates = unavails.pluck(:date).to_h { |date| [ date, true ] }

        unavails.find_each do |u|
          events << {
            id: "unavail-#{u.id}",
            title: u.reason.presence || "Bloqueado",
            start: u.date.beginning_of_day.in_time_zone(tz).iso8601,
            end: (u.date + 1).beginning_of_day.in_time_zone(tz).iso8601,
            allDay: true,
            color: "#ef4444",
            extendedProps: {
              kind: "bloqueo_dia",
              record_id: u.id,
              reason: u.reason
            }
          }
        end

        # 2) Bloqueos recurrentes por hora
        @doctor.doctor_time_blocks.find_each do |tb|
          days = Array(tb.days_of_week).map(&:to_i)

          (start_date..end_date).each do |day|
            next unless days.include?(day.wday)
            next if blocked_dates[day]

            start_dt = Time.zone.local(day.year, day.month, day.day, tb.starts_at.hour, tb.starts_at.min)
            end_dt = Time.zone.local(day.year, day.month, day.day, tb.ends_at.hour, tb.ends_at.min)
            end_dt += 1.day if end_dt <= start_dt

            events << {
              id: "tb-#{tb.id}-#{day}",
              title: tb.reason.presence || "Bloqueo horario",
              start: start_dt.iso8601,
              end: end_dt.iso8601,
              allDay: false,
              color: "#f97316",
              extendedProps: {
                kind: "bloqueo_horas",
                record_id: tb.id,
                reason: tb.reason,
                days_of_week: tb.days_of_week,
                starts_at: tb.starts_at.strftime("%H:%M"),
                ends_at: tb.ends_at.strftime("%H:%M")
              }
            }
          end
        end

        # 3) Citas no canceladas
        appt_scope = Appointment.where(doctor_id: @doctor.id).includes(:package)

        start_col =
          if Appointment.column_names.include?("start_date")
            "start_date"
          elsif Appointment.column_names.include?("starts_at")
            "starts_at"
          end

        end_col =
          if Appointment.column_names.include?("end_date")
            "end_date"
          elsif Appointment.column_names.include?("ends_at")
            "ends_at"
          end

        if start_col
          appt_scope = appt_scope.where(start_col => start_date.beginning_of_day..end_date.end_of_day)
        end

        if Appointment.column_names.include?("status")
          appt_scope = appt_scope.where.not(status: "cancelled")
        elsif Appointment.column_names.include?("canceled_at")
          appt_scope = appt_scope.where(canceled_at: nil)
        end

        appt_scope.find_each do |appointment|
          start_time = start_col ? appointment.public_send(start_col) : nil
          next unless start_time

          end_time =
            if end_col && appointment.public_send(end_col).present?
              appointment.public_send(end_col)
            else
              start_time + 30.minutes
            end

          patient_name = appointment.name.presence || "Cita ##{appointment.id}"
          package_name = appointment.package&.name
          scheduled_by = appointment.scheduled_by

          scheduled_by_label =
            case scheduled_by
            when "patient" then "Paciente"
            when "admin" then "Admin"
            else scheduled_by.to_s
            end

          title = [ patient_name, package_name ].compact.join(" · ")

          events << {
            id: "appt-#{appointment.id}",
            title: title,
            start: start_time.in_time_zone(tz).iso8601,
            end: end_time.in_time_zone(tz).iso8601,
            allDay: false,
            color: "#3b82f6",
            extendedProps: {
              kind: "cita",
              record_id: appointment.id,
              patient_name: patient_name,
              package_id: appointment.package_id,
              package_name: package_name,
              scheduled_by: scheduled_by,
              scheduled_by_label: scheduled_by_label,
              status: appointment.respond_to?(:status) ? appointment.status : nil
            }
          }
        end

        render json: events
      end
    rescue ArgumentError
      render json: [], status: :ok
    end

    private

    def set_doctor
      @doctor = Doctor.find_by(id: params[:id])
      redirect_to(admin_doctors_path, alert: "Doctor not found.") unless @doctor
    end

    def doctor_params
      permitted = params.require(:doctor).permit(:name, :specialty, :email, available_hours: {})

      if permitted[:available_hours].present?
        permitted[:available_hours] = permitted[:available_hours].to_h.transform_values do |times|
          arr = Array(times).map(&:to_s).reject(&:blank?)
          if arr.size == 2 && !arr.first.include?("-")
            [ "#{arr.first}-#{arr.last}" ]
          else
            arr
          end
        end
      end

      permitted
    end

    def normalize_hours(value)
      hours =
        case value
        when String
          JSON.parse(value) rescue {}
        when Hash, ActionController::Parameters
          value.to_h
        else
          {}
        end

      hours.transform_values do |ranges|
        Array(ranges).compact.map(&:to_s).reject(&:blank?)
      end
    end

    def default_hours
      {
        "Monday" => [ "09:00-17:00" ],
        "Tuesday" => [ "09:00-17:00" ],
        "Wednesday" => [ "09:00-17:00" ],
        "Thursday" => [ "09:00-17:00" ],
        "Friday" => [ "09:00-17:00" ],
        "Saturday" => [ "09:00-17:00" ],
        "Sunday" => [ "09:00-17:00" ]
      }
    end

    def require_admin
      redirect_to(root_path, alert: "You are not authorized to access this page.") unless current_user&.admin?
    end

    def authenticate_user!
      if user_signed_in?
        super
      else
        redirect_to root_path, alert: "You need to sign in to access this page."
      end
    end
  end
end
