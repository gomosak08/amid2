module User::Concerns
  module AvailableFields
    extend ActiveSupport::Concern

    def available_fields
      @package = Package.find_by(id: params[:package_id])
      return head :not_found unless @package

      @appointment = Appointment.new(package: @package)

      ctx    = appointment_context_builder.call(params: params, appointment: @appointment)
      prefix = admin_controller? ? "admin/appointments" : "appointments"

      doctors =
        if @package.respond_to?(:doctors) && @package.doctors.exists?
          @package.doctors.order(:name)
        else
          Doctor.order(:name)
        end

      doctor_id        = (ctx[:doctor_id].presence || params[:doctor_id]).presence
      appointment_date = (ctx[:start_date].presence || params[:appointment_date]).presence
      time_slot        = params[:time_slot].presence
      duration         = (@package.try(:duration).presence || ctx[:duration].presence || 30).to_i
      duration         = 30 if duration <= 0

      available_times = []
      if doctor_id.present? && appointment_date.present?
        if (doctor = Doctor.find_by(id: doctor_id))
          available_times = User::Availability::FetchTimes.call(
            doctor: doctor,
            date: appointment_date,   # "YYYY-MM-DD"
            duration: duration        # minutos
          )
        end
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(
              "doctor_date_frame",
              partial: "#{prefix}/doctor_date_form",
              locals:  {
                ctx: ctx, appointment: @appointment, package: @package,
                doctors: doctors, doctor_id: doctor_id, appointment_date: appointment_date
              }
            ),
            turbo_stream.update(
              "available_times_frame",
              partial: "#{prefix}/available_times_form",
              locals:  {
                available_times: available_times,
                doctor_id: doctor_id,
                appointment_date: appointment_date,
                package: @package,
                time_slot: time_slot,
                duration: duration
              }
            ),
            turbo_stream.update(
              "client_data_frame",
              partial: "#{prefix}/client_data_form",
              locals:  {
                appointment: @appointment, package: @package,
                doctor_id: doctor_id, appointment_date: appointment_date,
                time_slot: time_slot,
                duration: duration
              }
            )
          ]
        end

        format.html do
          redirect_to(
            admin_controller? ?
              new_admin_appointment_path(package_id: @package.id) :
              new_appointment_path(package_id: @package.id)
          )
        end
      end
    end

    private

    def admin_controller?
      self.class.name.start_with?("Admin::")
    end

    def appointment_context_builder
      Admin::Forms::AppointmentAdminFormContext
    end
  end
end
