require "digest"

module Api
  module Internal
    module V1
      class BaseController < Api::Internal::BaseController
        include Api::Internal::V1::Serialization

        DEFAULT_PAGE_SIZE = 50
        MAX_PAGE_SIZE = 100

        rescue_from ActiveRecord::RecordNotFound,
                    with: :render_record_not_found

        rescue_from ActiveRecord::RecordInvalid,
                    with: :render_record_invalid

        rescue_from ActionController::ParameterMissing,
                    with: :render_parameter_missing

        rescue_from Date::Error,
                    with: :render_invalid_date

        rescue_from ArgumentError,
                    with: :render_invalid_argument

        private

        # ------------------------------------------------------------
        # Respuestas JSON
        # ------------------------------------------------------------

        def render_success(data:, meta: {}, status: :ok)
          render json: {
            data: data,
            meta: {
              request_id: request.request_id
            }.merge(meta)
          }, status: status
        end

        def render_error(code:, message:, status:, details: nil)
          error = {
            code: code,
            message: message
          }

          error[:details] = details if details.present?

          render json: {
            error: error,
            meta: {
              request_id: request.request_id
            }
          }, status: status
        end

        # ------------------------------------------------------------
        # Paginación
        # ------------------------------------------------------------

        def page_number
          requested_page = params.fetch(:page, 1).to_i

          [requested_page, 1].max
        end

        def page_size
          requested_size = params.fetch(
            :page_size,
            DEFAULT_PAGE_SIZE
          ).to_i

          requested_size = 1 if requested_size < 1

          [requested_size, MAX_PAGE_SIZE].min
        end

        def paginate(scope)
          scope
            .offset((page_number - 1) * page_size)
            .limit(page_size)
        end

        def pagination_meta(total_count)
          total_pages =
            if total_count.zero?
              0
            else
              (total_count.to_f / page_size).ceil
            end

          {
            page: page_number,
            page_size: page_size,
            total_count: total_count,
            total_pages: total_pages
          }
        end

        # ------------------------------------------------------------
        # Conversión y validación de parámetros
        # ------------------------------------------------------------

        def parse_iso8601_time(value, parameter: "datetime")
          return nil if value.blank?

          Time.iso8601(value.to_s)
        rescue ArgumentError
          raise ArgumentError,
                "#{parameter} debe usar formato ISO 8601, por ejemplo " \
                "2026-07-25T10:00:00-06:00."
        end

        def parse_iso8601_date(value, parameter: "date")
          return nil if value.blank?

          Date.iso8601(value.to_s)
        rescue Date::Error, ArgumentError
          raise ArgumentError,
                "#{parameter} debe usar formato YYYY-MM-DD."
        end

        def boolean_param(value)
          ActiveModel::Type::Boolean.new.cast(value)
        end

        # ------------------------------------------------------------
        # Idempotencia
        # ------------------------------------------------------------

        def idempotency_key
          request.headers["Idempotency-Key"]
            .to_s
            .strip
            .presence
        end

        def require_idempotency_key!
          key = idempotency_key

          return key if key.present?

          render_error(
            code: "idempotency_key_required",
            message: "El header Idempotency-Key es obligatorio.",
            status: :bad_request
          )

          nil
        end

        def request_digest
          Digest::SHA256.hexdigest(request.raw_post.to_s)
        end

        # ------------------------------------------------------------
        # Manejo centralizado de errores
        # ------------------------------------------------------------

        def render_record_not_found(_exception = nil)
          render_error(
            code: "record_not_found",
            message: "El recurso solicitado no existe.",
            status: :not_found
          )
        end

        def render_record_invalid(exception)
          render_error(
            code: "validation_failed",
            message: "No fue posible guardar el recurso.",
            status: :unprocessable_entity,
            details: {
              errors: exception.record.errors.to_hash
            }
          )
        end

        def render_parameter_missing(exception)
          render_error(
            code: "parameter_missing",
            message: "Falta un parámetro requerido.",
            status: :bad_request,
            details: {
              parameter: exception.param
            }
          )
        end

        def render_invalid_date(exception)
          render_error(
            code: "invalid_date",
            message: exception.message.presence ||
              "La fecha proporcionada no es válida.",
            status: :unprocessable_entity
          )
        end

        def render_invalid_argument(exception)
          render_error(
            code: "invalid_parameter",
            message: exception.message,
            status: :unprocessable_entity
          )
        end
      end
    end
  end
end