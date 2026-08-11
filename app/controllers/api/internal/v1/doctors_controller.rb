module Api
  module Internal
    module V1
      class DoctorsController < BaseController
        before_action :set_doctor, only: :show

        def index
          doctors = Doctor.includes(:user).order(:id)
          doctors = apply_filters(doctors)

          total_count = doctors.count
          doctors = paginate(doctors)

          render_success(
            data: doctors.map { |doctor| serialize_doctor(doctor) },
            meta: pagination_meta(total_count)
          )
        end

        def show
          render_success(data: serialize_doctor(@doctor))
        end

        private

        def set_doctor
          @doctor = Doctor.includes(:user).find(params[:id])
        end

        def apply_filters(scope)
          if params[:active].present?
            if Doctor.column_names.include?("active")
              scope = scope.where(active: boolean_param(params[:active]))
            elsif Doctor.reflect_on_association(:user) && User.column_names.include?("active")
              scope = scope.joins(:user).where(users: { active: boolean_param(params[:active]) })
            end
          end

          if params[:specialty].present?
            if Doctor.column_names.include?("specialty")
              scope = scope.where(specialty: params[:specialty])
            elsif Doctor.column_names.include?("specialty_id")
              scope = scope.joins(:specialty).where(
                "LOWER(specialties.name) = ?",
                params[:specialty].to_s.downcase
              )
            end
          end

          if params[:updated_since].present?
            updated_since = parse_iso8601_time(
              params[:updated_since],
              parameter: "updated_since"
            )
            scope = scope.where("doctors.updated_at >= ?", updated_since)
          end

          scope
        end
      end
    end
  end
end