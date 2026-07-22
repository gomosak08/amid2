module Api
  module Internal
    class AppointmentsController < BaseController
      MAX_PERIOD_DAYS = 90

      def index
        date_from, date_to = requested_period

        appointments = Appointment
          .includes(:doctor, :package)
          .where(
            start_date: date_from.beginning_of_day..date_to.end_of_day
          )
          .where(dummy: [false, nil])
          .order(:start_date)

        render json: {
          date_from: date_from.iso8601,
          date_to: date_to.iso8601,
          count: appointments.size,
          appointments: appointments.map { |appointment|
            serialize_appointment(appointment)
          }
        }
      rescue Date::Error
        render json: {
          error: "Las fechas deben tener el formato YYYY-MM-DD"
        }, status: :unprocessable_entity
      rescue ArgumentError => e
        render json: {
          error: e.message
        }, status: :unprocessable_entity
      end

      def show
        appointment = Appointment
          .includes(:doctor, :package)
          .where(dummy: [false, nil])
          .find(params[:id])

        render json: serialize_appointment(appointment)
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "La cita no existe"
        }, status: :not_found
      end

     def clinical_status
      appointment = Appointment.find(params[:id])
      new_clinical_status = clinical_status_params[:status].to_s

      attributes = {
        clinical_status: new_clinical_status,
        attended_at: attended_at_for(
          appointment,
          new_clinical_status
        ),
        clinical_check_in_id:
          clinical_status_params[:clinical_check_in_id],
        clinical_updated_at: Time.current
      }

      case new_clinical_status
      when "completed"
        # Cuando Historiales completa la cita,
        # también se completa en AMID.
        attributes[:status] = "completed"

      when "checked_in"
        # Si estaba marcada como no asistió, se reactiva.
        attributes[:status] = "scheduled" if appointment.no_show?
      end

      appointment.update!(attributes)

      render json: {
        id: appointment.id,
        status: appointment.status,
        clinical_status: appointment.clinical_status,
        attended_at: appointment.attended_at,
        clinical_check_in_id: appointment.clinical_check_in_id,
        clinical_updated_at: appointment.clinical_updated_at
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        error: "La cita no existe"
      }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error(
        "[ClinicalStatus] No se pudo actualizar la cita #{params[:id]}: " \
        "#{e.record.errors.full_messages.join(', ')}"
      )

      render json: {
        error: e.record.errors.full_messages.to_sentence,
        errors: e.record.errors.full_messages
      }, status: :unprocessable_entity
    end


      

    private
    def clinical_status_params
        params.require(:appointment).permit(
          :status,
          :clinical_check_in_id
        )
      end

    def attended_at_for(appointment, status)
      return appointment.attended_at if appointment.attended_at.present?

      status == "checked_in" ? Time.current : nil
    end

    def requested_period
      if params[:date].present?
        date = Date.iso8601(params[:date])

        return [date, date]
      end

      date_from =
        if params[:date_from].present?
          Date.iso8601(params[:date_from])
        else
          Date.current
        end

      date_to =
        if params[:date_to].present?
          Date.iso8601(params[:date_to])
        else
          date_from
        end

      if date_to < date_from
        raise ArgumentError,
              "La fecha final no puede ser anterior a la inicial"
      end

      if (date_to - date_from).to_i > MAX_PERIOD_DAYS
        raise ArgumentError,
              "El periodo máximo permitido es de #{MAX_PERIOD_DAYS} días"
      end

      [date_from, date_to]
    end

    def serialize_appointment(appointment)
      {
        id: appointment.id,

        booking: {
          label: appointment.name,
          age: appointment.age,
          email: appointment.email,
          phone: appointment.phone,
          phone_number_e164: appointment.phone_number_e164,
          sex: appointment.sex
        },

        schedule: {
          start_at: appointment.start_date,
          end_at: appointment.end_date,
          duration_minutes:
            appointment.duration.presence ||
            appointment.package&.duration
        },

        doctor_id: appointment.doctor_id,
        package_id: appointment.package_id,

        doctor: serialize_doctor(appointment.doctor),
        package: serialize_package(appointment.package),

        status: appointment.status,
        scheduled_by: appointment.scheduled_by,
        canceled_at: appointment.canceled_at,

        references: {
          unique_code: appointment.unique_code
        },

        created_at: appointment.created_at,
        updated_at: appointment.updated_at
      }
    end

    def serialize_doctor(doctor)
      return nil unless doctor

      {
        id: doctor.id,
        name: doctor.name
      }
    end

    def serialize_package(package)
        return nil unless package

        {
          id: package.id,
          name: package.name,
          description: package.description,
          duration_minutes: package.duration,
          price: package.price,
          kind: package.kind
        }
      end
    end
  end
end
