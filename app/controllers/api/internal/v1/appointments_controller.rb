module Api
  module Internal
    module V1
      class AppointmentsController < BaseController
        MAX_PERIOD_DAYS = 90
        ALLOWED_CLINICAL_STATUSES = Appointment.clinical_statuses.keys.freeze

        before_action :set_appointment, only: %i[show update cancel clinical_status]

        def index
          date_from, date_to = requested_period
          appointments = Appointment
            .includes(:doctor, :package)
            .where(start_date: date_from.beginning_of_day..date_to.end_of_day)
          appointments = appointments.where(dummy: [false, nil]) if Appointment.column_names.include?("dummy")
          appointments = apply_filters(appointments).order(:start_date, :id)

          total_count = appointments.count
          appointments = paginate(appointments)

          render_success(
            data: appointments.map { |appointment| serialize_appointment(appointment) },
            meta: pagination_meta(total_count).merge(
              date_from: date_from.iso8601,
              date_to: date_to.iso8601
            )
          )
        end

        def show
          render_success(data: serialize_appointment(@appointment))
        end

        def create
          key = require_idempotency_key!
          return unless key

          if Appointment.column_names.include?("api_idempotency_key")
            existing = Appointment.find_by(api_idempotency_key: key)
            return render_idempotent_replay(existing) if existing
          end

          appointment = Api::Internal::V1::AppointmentWriter.new(
            payload: appointment_params,
            idempotency_key: key,
            request_digest: request_digest
          ).build
          appointment.save!

          render_success(
            data: serialize_appointment(appointment),
            meta: { idempotent_replay: false },
            status: :created
          )
        rescue ActiveRecord::RecordNotUnique
          existing = Appointment.find_by!(api_idempotency_key: key)
          render_idempotent_replay(existing)
        rescue ActiveRecord::RecordInvalid => error
          render_appointment_validation_error(error.record)
        end

        def update
          Api::Internal::V1::AppointmentWriter.new(
            appointment: @appointment,
            payload: appointment_params
          ).assign_updates
          @appointment.save!

          render_success(data: serialize_appointment(@appointment))
        rescue ActiveRecord::RecordInvalid => error
          render_appointment_validation_error(error.record)
        end

        def cancel
          if canceled?(@appointment)
            return render_success(
              data: serialize_appointment(@appointment),
              meta: { idempotent_replay: true }
            )
          end

          reason = cancellation_params[:reason].to_s.strip
          raise ArgumentError, "El motivo de cancelación es obligatorio." if reason.blank?

          @appointment.status = cancellation_status
          assign_if_appointment_column(@appointment, :canceled_at, Time.current)
          assign_if_appointment_column(@appointment, :cancellation_reason, reason)
          assign_if_appointment_column(
            @appointment,
            :canceled_by_source,
            cancellation_params[:canceled_by].presence || "clinical_history"
          )
          @appointment.save!

          render_success(data: serialize_appointment(@appointment))
        rescue ActiveRecord::RecordInvalid => error
          render_appointment_validation_error(error.record)
        end

        def clinical_status
          permitted = clinical_status_params
          new_status = permitted[:status].to_s

          unless ALLOWED_CLINICAL_STATUSES.include?(new_status)
            return render_error(
              code: "invalid_clinical_status",
              message: "El estado clínico no es válido.",
              status: :unprocessable_entity,
              details: {
                received: new_status,
                allowed: ALLOWED_CLINICAL_STATUSES
              }
            )
          end

          occurred_at = parse_iso8601_time(
            permitted[:occurred_at].presence || Time.current.iso8601,
            parameter: "occurred_at"
          )

          if stale_clinical_event?(@appointment, occurred_at)
            return render_error(
              code: "stale_clinical_event",
              message: "Existe una actualización clínica más reciente.",
              status: :conflict,
              details: {
                clinical_updated_at: @appointment.clinical_updated_at
              }
            )
          end

          attributes = {
            clinical_status: new_status,
            clinical_updated_at: occurred_at
          }
          attributes[:clinical_check_in_id] = permitted[:clinical_check_in_id] if permitted.key?(:clinical_check_in_id)

          if new_status == "checked_in" && @appointment.attended_at.blank?
            attributes[:attended_at] = occurred_at
          end

          attributes[:status] = "completed" if new_status == "completed" && appointment_status_available?("completed")

          if new_status == "checked_in" && @appointment.respond_to?(:no_show?) && @appointment.no_show?
            attributes[:status] = "scheduled" if appointment_status_available?("scheduled")
          end

          @appointment.update!(attributes)
          render_success(data: serialize_appointment(@appointment))
        end

        private

        def set_appointment
          scope = Appointment.includes(:doctor, :package)
          scope = scope.where(dummy: [false, nil]) if Appointment.column_names.include?("dummy")
          @appointment = scope.find(params[:id])
        end

        def appointment_params
          params.require(:appointment).permit(
            :clinic_id,
            :doctor_id,
            :package_id,
            :start_at,
            :notes,
            :source,
            patient: %i[
              external_patient_id
              name
              age
              phone
              email
              sex
            ]
          )
        end

        def cancellation_params
          params.require(:cancellation).permit(:reason, :canceled_by)
        end

        def clinical_status_params
          params.require(:appointment).permit(
            :status,
            :clinical_check_in_id,
            :occurred_at
          )
        end

        def apply_filters(scope)
          scope = scope.where(doctor_id: params[:doctor_id]) if params[:doctor_id].present?
          scope = scope.where(package_id: params[:package_id]) if params[:package_id].present?
          scope = scope.where(status: params[:status]) if params[:status].present?

          if params[:clinical_status].present? && Appointment.column_names.include?("clinical_status")
            scope = scope.where(clinical_status: params[:clinical_status])
          end

          if params[:patient_query].present?
            query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:patient_query].to_s.downcase)}%"
            conditions = ["LOWER(appointments.name) LIKE ?"]
            values = [query]

            if Appointment.column_names.include?("email")
              conditions << "LOWER(appointments.email) LIKE ?"
              values << query
            end
            if Appointment.column_names.include?("phone")
              conditions << "LOWER(appointments.phone) LIKE ?"
              values << query
            end

            scope = scope.where(conditions.join(" OR "), *values)
          end

          if params[:updated_since].present?
            updated_since = parse_iso8601_time(
              params[:updated_since],
              parameter: "updated_since"
            )
            scope = scope.where("appointments.updated_at >= ?", updated_since)
          end

          scope
        end

        def requested_period
          if params[:date].present?
            date = parse_iso8601_date(params[:date], parameter: "date")
            return [date, date]
          end

          date_from = parse_iso8601_date(
            params[:date_from].presence || Date.current.iso8601,
            parameter: "date_from"
          )
          date_to = parse_iso8601_date(
            params[:date_to].presence || date_from.iso8601,
            parameter: "date_to"
          )

          raise ArgumentError, "La fecha final no puede ser anterior a la inicial." if date_to < date_from
          if (date_to - date_from).to_i > MAX_PERIOD_DAYS
            raise ArgumentError, "El periodo máximo permitido es de #{MAX_PERIOD_DAYS} días."
          end

          [date_from, date_to]
        end

        def render_idempotent_replay(existing)
          if Appointment.column_names.include?("api_request_digest") &&
             existing.api_request_digest.present? &&
             existing.api_request_digest != request_digest
            return render_error(
              code: "idempotency_conflict",
              message: "La misma Idempotency-Key fue usada con un contenido distinto.",
              status: :conflict
            )
          end

          render_success(
            data: serialize_appointment(existing),
            meta: { idempotent_replay: true }
          )
        end

        def render_appointment_validation_error(appointment)
          messages = appointment.errors.full_messages
          conflict = messages.any? do |message|
            message.match?(/horario|disponib|ocupad|bloque|empalm|reserv/i)
          end

          render_error(
            code: conflict ? "appointment_conflict" : "validation_failed",
            message: conflict ? "El horario seleccionado ya no está disponible." : "La cita no es válida.",
            status: conflict ? :conflict : :unprocessable_entity,
            details: { errors: appointment.errors.to_hash }
          )
        end

        def canceled?(appointment)
          appointment.status.to_s.match?(/cancel/i)
        end

        def cancellation_status
          statuses = Appointment.defined_enums.fetch("status", {}).keys
          statuses.find { |status| status == "canceled_by_admin" } ||
            statuses.find { |status| status.match?(/cancel/i) } ||
            "canceled_by_admin"
        end

        def appointment_status_available?(status)
          enum = Appointment.defined_enums["status"].to_h
          enum.blank? || enum.key?(status)
        end

        def stale_clinical_event?(appointment, occurred_at)
          return false unless appointment.respond_to?(:clinical_updated_at)
          return false if appointment.clinical_updated_at.blank?

          occurred_at < appointment.clinical_updated_at
        end

        def assign_if_appointment_column(appointment, name, value)
          return unless Appointment.column_names.include?(name.to_s)

          appointment.public_send("#{name}=", value)
        end
      end
    end
  end
end