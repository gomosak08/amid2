module Api
  module Internal
    class DoctorsController < BaseController
      # GET /api/internal/doctors
      def index
        doctors = Doctor
          .includes(:user)
          .order(:id)

        render json: {
          doctors: doctors.map { |doctor| doctor_data(doctor) }
        }
      end

      # GET /api/internal/doctors/:id
      def show
        doctor = Doctor
          .includes(:user)
          .find(params[:id])

        render json: {
          doctor: doctor_data(doctor)
        }
      end

      private

      def doctor_data(doctor)
        {
          id: doctor.id,
          name: doctor_name(doctor),
          email: doctor_email(doctor),
          phone: doctor_phone(doctor),
          active: doctor_active?(doctor),
          specialty: doctor_specialty(doctor)
        }
      end

      def doctor_name(doctor)
        return doctor.name if doctor.respond_to?(:name) && doctor.name.present?
        return doctor.user.name if doctor.user&.respond_to?(:name)

        nil
      end

      def doctor_email(doctor)
        return doctor.email if doctor.respond_to?(:email) && doctor.email.present?

        doctor.user&.email
      end

      def doctor_phone(doctor)
        return doctor.phone if doctor.respond_to?(:phone) && doctor.phone.present?

        if doctor.user&.respond_to?(:phone)
          doctor.user.phone
        end
      end

      def doctor_active?(doctor)
        return doctor.active if doctor.respond_to?(:active)

        true
      end

      def doctor_specialty(doctor)
        return doctor.specialty if doctor.respond_to?(:specialty)

        nil
      end
    end
  end
end