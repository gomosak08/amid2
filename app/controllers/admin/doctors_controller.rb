# app/controllers/admin/doctors_controller.rb
module Admin
  class DoctorsController < ApplicationController
    before_action :authenticate_user!   # Ensure the user is logged in
    before_action :require_admin        # Ensure only admins can access these actions
    before_action :set_doctor, only: [ :edit, :update, :destroy, :mark_unavailable_day, :clear_unavailable_day ]

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
      # @doctor ya viene del before_action
      # Normaliza available_hours para edición
      @doctor.available_hours ||= default_hours
      @doctor.available_hours = normalize_hours(@doctor.available_hours)
    end

    def update
      Rails.logger.debug "Processed Params: #{doctor_params.inspect}"
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

    # Bloquea TODO el día creando una única cita dummy que cubre 00:00-23:59:59 local
    def mark_unavailable_day
      date = params[:date].present? ? Date.parse(params[:date]) : Time.zone.today

      Time.use_zone("America/Mexico_City") do
        day_start = date.in_time_zone.beginning_of_day
        day_end   = date.in_time_zone.end_of_day

        Appointment.create!(
          doctor: @doctor,
          package_id: nil,          # Pon un id válido si tu validación lo exige
          name: "Unavailable",
          age: 0,
          sex: "N/A",
          email: "block@system.local",
          phone: 0,
          start_date: day_start,
          end_date: day_end,
          dummy: true               # clave: marca el bloqueo
        )
      end

      redirect_to admin_doctors_path, notice: "Doctor marcado como no disponible para #{I18n.l(date)}."
    rescue ArgumentError
      redirect_to admin_doctors_path, alert: "Fecha inválida."
    end

    # Limpia todos los bloqueos dummy del día
    def clear_unavailable_day
      date = params[:date].present? ? Date.parse(params[:date]) : Time.zone.today

      destroyed = 0
      Time.use_zone("America/Mexico_City") do
        day_range = date.in_time_zone.all_day
        destroyed = Appointment.where(doctor_id: @doctor.id, dummy: true, start_date: day_range).destroy_all.size
      end

      if destroyed.positive?
        flash[:notice] = "Se limpiaron #{destroyed} bloqueos del #{I18n.l(date)}."
      else
        flash[:alert]  = "No se encontraron bloqueos para el #{I18n.l(date)}."
      end
      redirect_to admin_doctors_path
    rescue ArgumentError
      redirect_to admin_doctors_path, alert: "Fecha inválida."
    end

    def default_hours
      {
        "Monday"    => [ "09:00-17:00" ],
        "Tuesday"   => [ "09:00-17:00" ],
        "Wednesday" => [ "09:00-17:00" ],
        "Thursday"  => [ "09:00-17:00" ],
        "Friday"    => [ "09:00-17:00" ],
        "Saturday"  => [ "09:00-17:00" ],
        "Sunday"    => [ "09:00-17:00" ]
      }
    end

    private

    # Devuelve un Hash con arrays de rangos "HH:MM-HH:MM" por día
    def normalize_hours(value)
      h =
        case value
        when String
          # viene como JSON string en la DB
          JSON.parse(value) rescue {}
        when Hash, ActionController::Parameters
          value.to_h
        else
          {}
        end

      # Asegura que cada valor sea array de strings
      h.transform_values do |v|
        arr = v.is_a?(Array) ? v : Array(v)
        arr.compact.map(&:to_s).reject(&:blank?)
      end
    end

    # Calcula slots disponibles (ignora bloqueos dummy)
    def fetch_available_times(doctor, selected_date, duration_minutes)
      date = selected_date.is_a?(String) ? Date.parse(selected_date) : selected_date

      hours_by_day = normalize_hours(doctor.available_hours || default_hours)
      day_name = date.strftime("%A")

      slots = []

      Time.use_zone("America/Mexico_City") do
        now = Time.zone.now
        ranges = hours_by_day[day_name] || []

        ranges.each do |range|
          start_str, end_str = range.split("-")
          next if start_str.blank? || end_str.blank?

          start_time = Time.zone.parse("#{date} #{start_str}")
          end_time   = Time.zone.parse("#{date} #{end_str}")
          next if start_time.blank? || end_time.blank? || start_time >= end_time

          cursor = start_time
          while cursor < end_time
            slots << cursor if cursor >= now
            cursor += duration_minutes.to_i.minutes
          end
        end

        # Citas reales (no dummy) del día
        booked_times = Appointment.where(doctor_id: doctor.id, start_date: date.in_time_zone.all_day, dummy: [ false, nil ])
                                  .pluck(:start_date)

        # Si hay bloqueo dummy del día, devolver []
        return [] if Appointment.exists?(doctor_id: doctor.id, dummy: true, start_date: date.in_time_zone.all_day)

        slots.reject { |t| booked_times.include?(t) }
      end
    end

    # Ya no se usa para crear muchos dummies; dejamos 1 bloqueo de día completo en mark_unavailable_day.
    # Mantengo el método por si lo llamas desde otro lado.
    def create_dummy_appointments(doctor, selected_date, duration)
      Time.use_zone("America/Mexico_City") do
        day_start = selected_date.in_time_zone.beginning_of_day
        day_end   = selected_date.in_time_zone.end_of_day

        Appointment.create!(
          doctor: doctor,
          package_id: nil,          # Ajusta si necesitas validar
          name: "Unavailable",
          age: 0,
          sex: "N/A",
          email: "block@system.local",
          phone: 0,
          start_date: day_start,
          end_date: day_end,
          dummy: true
        )
      end
    end

    def set_doctor
      @doctor = Doctor.find_by(id: params[:id])
      unless @doctor
        redirect_to admin_doctors_path, alert: "Doctor not found."
      end
    end

    # Espera params como:
    # params[:doctor][:available_hours] = {
    #   "Monday" => ["09:00", "17:00"], ...
    # }  ó  { "Monday" => ["09:00-17:00"] }
    def doctor_params
      permitted = params.require(:doctor).permit(:name, :specialty, :email, available_hours: {})
      if permitted[:available_hours].present?
        # Normaliza a ["HH:MM-HH:MM"] por día
        normalized = permitted[:available_hours].to_h.transform_values do |times|
          arr = Array(times).map(&:to_s).reject(&:blank?)
          if arr.size == 2 && !arr.first.include?("-")
            [ "#{arr.first}-#{arr.last}" ]
          else
            arr
          end
        end
        permitted[:available_hours] = normalized
      end
      permitted
    end

    def require_admin
      unless current_user&.admin?
        redirect_to root_path, alert: "You are not authorized to access this page."
      end
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
