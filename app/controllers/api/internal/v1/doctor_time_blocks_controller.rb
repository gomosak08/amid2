module Api
  module Internal
    module V1
      class DoctorTimeBlocksController < BaseController
        before_action :set_doctor
        before_action :set_time_block, only: %i[show update destroy]

        def index
          date_from = parse_iso8601_date(
            params[:date_from].presence || Date.current.iso8601,
            parameter: "date_from"
          )
          date_to = parse_iso8601_date(
            params[:date_to].presence || (date_from + 90.days).iso8601,
            parameter: "date_to"
          )

          blocks = DoctorCalendarBlock.active
            .where(doctor_id: @doctor.id)
            .overlapping(date_from.beginning_of_day, date_to.end_of_day)
            .order(:starts_at)

          render_success(data: blocks.map { |block| serialize_time_block(block) })
        end

        def show
          render_success(data: serialize_time_block(@time_block))
        end

        def create
          key = require_idempotency_key!
          return unless key

          existing = DoctorCalendarBlock.find_by(api_idempotency_key: key)
          if existing
            return render_success(
              data: serialize_time_block(existing),
              meta: { idempotent_replay: true }
            )
          end

          attributes = normalized_time_block_attributes
          conflicts = conflicting_appointments(attributes[:starts_at], attributes[:ends_at])
          return render_block_conflict(conflicts) if conflicts.exists?

          block = @doctor.doctor_calendar_blocks.create!(
            attributes.merge(
              source: time_block_params[:source].presence || "clinical_history",
              api_idempotency_key: key
            )
          )

          render_success(
            data: serialize_time_block(block),
            meta: { idempotent_replay: false },
            status: :created
          )
        rescue ActiveRecord::RecordNotUnique
          existing = DoctorCalendarBlock.find_by!(api_idempotency_key: key)
          render_success(
            data: serialize_time_block(existing),
            meta: { idempotent_replay: true }
          )
        end

        def update
          attributes = normalized_time_block_attributes
          conflicts = conflicting_appointments(attributes[:starts_at], attributes[:ends_at])
          return render_block_conflict(conflicts) if conflicts.exists?

          @time_block.update!(attributes)
          render_success(data: serialize_time_block(@time_block))
        end

        def destroy
          @time_block.update!(canceled_at: Time.current)
          render_success(data: serialize_time_block(@time_block))
        end

        private

        def set_doctor
          @doctor = Doctor.find(params[:doctor_id])
        end

        def set_time_block
          @time_block = @doctor.doctor_calendar_blocks.find(params[:id])
        end

        def time_block_params
          params.require(:time_block).permit(
            :starts_at,
            :ends_at,
            :starts_on,
            :ends_on,
            :all_day,
            :reason,
            :source
          )
        end

        def normalized_time_block_attributes
          permitted = time_block_params
          all_day = boolean_param(permitted[:all_day])

          if all_day
            starts_on = parse_iso8601_date(permitted.require(:starts_on), parameter: "starts_on")
            ends_on = parse_iso8601_date(
              permitted[:ends_on].presence || starts_on.iso8601,
              parameter: "ends_on"
            )
            raise ArgumentError, "ends_on no puede ser anterior a starts_on." if ends_on < starts_on

            starts_at = Time.zone.local(starts_on.year, starts_on.month, starts_on.day)
            exclusive_end = ends_on + 1.day
            ends_at = Time.zone.local(exclusive_end.year, exclusive_end.month, exclusive_end.day)
          else
            starts_at = parse_iso8601_time(permitted.require(:starts_at), parameter: "starts_at")
            ends_at = parse_iso8601_time(permitted.require(:ends_at), parameter: "ends_at")
          end

          raise ArgumentError, "La fecha final debe ser posterior a la inicial." unless ends_at > starts_at

          {
            starts_at: starts_at,
            ends_at: ends_at,
            all_day: all_day,
            reason: permitted[:reason].to_s.strip.presence
          }
        end

        def conflicting_appointments(starts_at, ends_at)
          scope = Appointment
            .where(doctor_id: @doctor.id)
            .where("start_date < ? AND end_date > ?", ends_at, starts_at)
          scope = scope.where(dummy: [false, nil]) if Appointment.column_names.include?("dummy")

          canceled_values = Appointment.defined_enums
            .fetch("status", {})
            .select { |name, _value| name.match?(/cancel/i) }
            .values
          scope = scope.where.not(status: canceled_values) if canceled_values.present?
          scope
        end

        def render_block_conflict(conflicts)
          render_error(
            code: "time_block_conflict",
            message: "El bloqueo se cruza con citas existentes.",
            status: :conflict,
            details: {
              appointment_ids: conflicts.limit(20).pluck(:id),
              policy: "El bloqueo debe crearse después de reprogramar o cancelar las citas."
            }
          )
        end
      end
    end
  end
end