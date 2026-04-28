# app/controllers/admin/doctors_controller.rb
module Admin
  class DoctorsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_doctor, except: %i[index new create]
    before_action :require_admin_or_self_doctor

    def index
      if current_user&.doctor? && !current_user.admin?
        if current_user.doctor.present?
          redirect_to edit_admin_doctor_path(current_user.doctor)
        else
          redirect_to root_path, alert: "No tienes un perfil de doctor asignado."
        end
        return
      end

      @doctors = Doctor.all
    end

    def new
      @doctor = Doctor.new
      @doctor.available_hours = default_hours
      @doctor.build_user
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

    def create_unified_block
      start_date = Date.parse(params[:start_date])
      # JS gives exclusive end date for display purposes if not handled, but let's assume UI sets inclusive backend end_date or we adapt
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : start_date
      reason = params[:reason].presence
      start_time = params[:start_time].presence
      end_time = params[:end_time].presence
      is_recurring = params[:is_recurring] == "1" || params[:is_recurring] == "true"

      if end_date < start_date
        redirect_to edit_admin_doctor_path(@doctor), alert: "El rengo es inválido."
        return
      end

      failed_count = 0

      Time.use_zone("America/Mexico_City") do
        if is_recurring
          # RECURSIVO (Semanal)
          # Calcular qué días de la semana (wday) incluye el rango seleccionado
          days = (start_date..end_date).map(&:wday).uniq
          
          # Si no hay hora, asume todo el día
          s_time = start_time.present? ? Time.zone.parse(start_time) : Time.zone.parse("00:00")
          e_time = end_time.present? ? Time.zone.parse(end_time) : Time.zone.parse("23:59:59")

          block = @doctor.doctor_time_blocks.new(
            starts_at: s_time,
            ends_at: e_time,
            days_of_week: days,
            reason: reason
          )

          if block.save
            failed_count += reassign_appointments_for_recurring_block(@doctor, block)
            msg = "Bloqueo recurrente creado exitosamente para #{days.count} día(s) de la semana."
            msg += " Atención: #{failed_count} cita(s) no pudieron ser reasignadas." if failed_count > 0
            redirect_to edit_admin_doctor_path(@doctor), notice: msg
          else
            redirect_to edit_admin_doctor_path(@doctor), alert: "Error: #{block.errors.full_messages.to_sentence}"
          end

        else
          # FECHAS ESPECÍFICAS
          s_time = start_time.present? ? Time.zone.parse(start_time) : nil
          e_time = end_time.present? ? Time.zone.parse(end_time) : nil

          (start_date..end_date).each do |date|
            DoctorUnavailability.find_or_create_by!(
              doctor: @doctor, date: date, start_time: s_time, end_time: e_time
            ) { |u| u.reason = reason }
            
            range_start = s_time ? Time.zone.local(date.year, date.month, date.day, s_time.hour, s_time.min) : date.beginning_of_day
            range_end   = e_time ? Time.zone.local(date.year, date.month, date.day, e_time.hour, e_time.min) : date.end_of_day
            range_end += 1.day if range_end <= range_start
            
            failed_count += reassign_appointments_for_range(@doctor, range_start, range_end)
          end

          msg = "Bloqueo creado para el rango #{I18n.l(start_date)} al #{I18n.l(end_date)}."
          msg += " Atención: #{failed_count} cita(s) no pudieron reasignarse y bloquearon este horario obligando a manejo manual." if failed_count > 0

          redirect_to edit_admin_doctor_path(@doctor), notice: msg
        end
      end
    rescue ArgumentError
      redirect_to edit_admin_doctor_path(@doctor), alert: "Fechas o horas inválidas suministradas."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_admin_doctor_path(@doctor), alert: e.record.errors.full_messages.to_sentence
    end

    def mark_unavailable_range
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      reason = params[:reason].presence
      start_time = params[:start_time].presence
      end_time = params[:end_time].presence

      if end_date < start_date
        redirect_to edit_admin_doctor_path(@doctor), alert: "El rango es inválido."
        return
      end

      failed_count = 0

      Time.use_zone("America/Mexico_City") do
        s_time = start_time.present? ? Time.zone.parse(start_time) : nil
        e_time = end_time.present? ? Time.zone.parse(end_time) : nil

        (start_date..end_date).each do |date|
          DoctorUnavailability.find_or_create_by!(doctor: @doctor, date: date, start_time: s_time, end_time: e_time) do |u|
            u.reason = reason
          end
          
          # Reassignment Logic
          range_start = s_time ? Time.zone.local(date.year, date.month, date.day, s_time.hour, s_time.min) : date.beginning_of_day
          range_end   = e_time ? Time.zone.local(date.year, date.month, date.day, e_time.hour, e_time.min) : date.end_of_day
          range_end += 1.day if range_end <= range_start
          
          failed_count += reassign_appointments_for_range(@doctor, range_start, range_end)
        end
      end

      msg = "Bloqueado del #{I18n.l(start_date)} al #{I18n.l(end_date)}."
      msg += " Atención: #{failed_count} cita(s) no pudieron ser reasignadas y su horario ahora está bloqueado. Favor de ajustarlas manualmente." if failed_count > 0

      redirect_to edit_admin_doctor_path(@doctor),
                  notice: msg
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
      reason = params[:reason].presence

      Time.use_zone("America/Mexico_City") do
        if params[:blocks_json].present?
          blocks = JSON.parse(params[:blocks_json])
          saved_any = false
          errors = []

          blocks.each do |b|
            starts_at = Time.zone.parse(b["startTime"])
            ends_at = Time.zone.parse(b["endTime"])
            days = Array(b["days"]).map(&:to_i)

            block = @doctor.doctor_time_blocks.new(
              starts_at: starts_at,
              ends_at: ends_at,
              days_of_week: days,
              reason: reason
            )

            if block.save
              saved_any = true
              failed_count += reassign_appointments_for_recurring_block(@doctor, block)
            else
              errors << block.errors.full_messages.to_sentence
            end
          end

          msg = ""
          msg = "Atención: #{failed_count} cita(s) no pudieron ser reasignadas. " if failed_count > 0

          if saved_any && errors.empty?
            redirect_to edit_admin_doctor_path(@doctor), notice: "Bloqueos recurrentes creados exitosamente. #{msg}"
          elsif saved_any
            redirect_to edit_admin_doctor_path(@doctor), notice: "Algunos bloqueos se crearon, pero hubo errores: #{errors.uniq.join('. ')}. #{msg}"
          else
            redirect_to edit_admin_doctor_path(@doctor), alert: "Error al crear bloqueos: #{errors.uniq.join('. ')}"
          end
        else
          # Fallback if old format is submitted
          days = if params[:days_of_week_json].present?
                   JSON.parse(params[:days_of_week_json]).map(&:to_i)
                 else
                   Array(params[:days_of_week]).map(&:to_i)
                 end

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
      end
    rescue ArgumentError, JSON::ParserError
      redirect_to edit_admin_doctor_path(@doctor), alert: "Horario o formato inválido."
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
          is_all_day = u.start_time.blank? || u.end_time.blank?
          s_time = is_all_day ? u.date.beginning_of_day : Time.zone.local(u.date.year, u.date.month, u.date.day, u.start_time.hour, u.start_time.min)
          e_time = is_all_day ? (u.date + 1).beginning_of_day : Time.zone.local(u.date.year, u.date.month, u.date.day, u.end_time.hour, u.end_time.min)
          e_time += 1.day if e_time <= s_time && !is_all_day
          
          events << {
            id: "unavail-#{u.id}",
            title: u.reason.presence || "Bloqueado",
            start: s_time.in_time_zone(tz).iso8601,
            end: e_time.in_time_zone(tz).iso8601,
            allDay: is_all_day,
            color: is_all_day ? "#ef4444" : "#f97316",
            extendedProps: {
              kind: is_all_day ? "bloqueo_dia" : "bloqueo_horas",
              record_id: u.id,
              reason: u.reason,
              starts_at: is_all_day ? nil : u.start_time.strftime("%H:%M"),
              ends_at: is_all_day ? nil : u.end_time.strftime("%H:%M")
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
          appt_scope = appt_scope.where.not(status: ["canceled_by_admin", "canceled_by_client", "no_show"])
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
          scheduled_by_label = appointment.scheduled_by_label

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
      permitted = params.require(:doctor).permit(
        :name, :specialty_id, :email,
        package_ids: [],
        user_attributes: [:id, :email, :phone, :password, :role],
        available_hours: {}
      )

      if permitted[:user_attributes].present?
        # Ensure role is always doctor securely
        permitted[:user_attributes][:role] = "doctor"
        # Avoid Devise validation if password is not being updated
        if permitted[:user_attributes][:password].blank?
          permitted[:user_attributes].delete(:password)
        end
      end

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

    def require_admin_or_self_doctor
      return if current_user&.admin?

      if current_user&.doctor?
        # El médico solo puede editar su propio perfil, no puede crear ni borrar doctores
        if %w[new create destroy].include?(action_name)
          redirect_to root_path, alert: "Acceso denegado a esta sección general."
        elsif @doctor && @doctor.user_id != current_user.id
          redirect_to root_path, alert: "Solo puedes gestionar tu propio perfil médico y calendario."
        end
      else
        redirect_to root_path, alert: "No autorizado."
      end
    end

    def authenticate_user!
      if user_signed_in?
        super
      else
        redirect_to root_path, alert: "You need to sign in to access this page."
      end
    end

    def reassign_appointments_for_range(doctor, start_dt, end_dt)
      failed = 0
      appts = Appointment.where(doctor_id: doctor.id)
                         .where.not(status: ["canceled_by_admin", "canceled_by_client", "no_show", "completed"])
                         .where("start_date >= ? AND start_date < ?", start_dt, end_dt)

      appts.find_each do |appt|
        failed += reassign_single_appointment(appt) ? 0 : 1
      end
      failed
    end

    def reassign_appointments_for_recurring_block(doctor, block)
      failed = 0
      # Find all future appointments
      appts = Appointment.where(doctor_id: doctor.id)
                         .where.not(status: ["canceled_by_admin", "canceled_by_client", "no_show", "completed"])
                         .where("start_date >= ?", Time.zone.now)

      appts.find_each do |appt|
        wday = appt.start_date.wday
        next unless Array(block.days_of_week).include?(wday)
        
        # Check time overlap
        appt_start_hm = appt.start_date.strftime("%H:%M")
        appt_end_hm = appt.end_date ? appt.end_date.strftime("%H:%M") : (appt.start_date + appt.duration.to_i.minutes).strftime("%H:%M")
        
        block_s = block.starts_at.strftime("%H:%M")
        block_e = block.ends_at.strftime("%H:%M")

        # overlap logic on HH:MM
        if appt_start_hm < block_e && appt_end_hm > block_s
          failed += reassign_single_appointment(appt) ? 0 : 1
        end
      end
      failed
    end

    def reassign_single_appointment(appt)
      # Find available doctors for this package and time
      doctors = Doctor.for_package(appt.package_id).where.not(id: appt.doctor_id)
      
      Time.use_zone("America/Mexico_City") do
        valid_doctor = doctors.find do |doc|
          # Check if this doctor is available exactly at `appt.start_date`
          times = User::Availability::FetchTimes.call(
            doctor: doc,
            date: appt.start_date.to_date,
            duration: appt.duration
          )
          times.include?(appt.start_date)
        end

        if valid_doctor
          # Clonar todos los atributos excepto los de identidad principal
          new_attributes = appt.attributes.except(
            "id", "created_at", "updated_at", 
            "unique_code", "token", "google_calendar_id"
          )
          
          # Asignar nuevo doctor y asegurar el status
          new_attributes["doctor_id"] = valid_doctor.id
          new_attributes["status"] = "scheduled"

          # 1. Crear nueva cita clonada
          new_appt = Appointment.new(new_attributes)
          
          # Forzar a saltarnos validaciones de disponibilidad extra por si es necesario
          # pero con new_appt.save(validate: false) nos arriesgamos a fallos silenciosos.
          # Lo ideal es que save dispare el after_create
          if new_appt.save
            # 2. Cancelar la vieja cita
            appt.update!(status: :canceled_by_admin)
            return true
          else
            Rails.logger.error "[Reasignación] Error al clonar cita #{appt.id}: #{new_appt.errors.full_messages}"
            return false
          end
        end
      end
      
      false
    end
  end
end
