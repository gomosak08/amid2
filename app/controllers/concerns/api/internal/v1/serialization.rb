module Api
  module Internal
    module V1
      module Serialization
        private

        def serialize_appointment(appointment)
          {
            id: appointment.id,
            booking: {
              label: attribute_value(appointment, :name),
              age: attribute_value(appointment, :age),
              email: attribute_value(appointment, :email),
              phone: attribute_value(appointment, :phone),
              phone_number_e164: attribute_value(appointment, :phone_number_e164),
              sex: attribute_value(appointment, :sex),
              external_patient_id: attribute_value(appointment, :external_patient_id)
            },
            schedule: {
              start_at: attribute_value(appointment, :start_date),
              end_at: attribute_value(appointment, :end_date),
              duration_minutes: attribute_value(appointment, :duration).presence ||
                attribute_value(appointment.package, :duration)
            },
            doctor_id: appointment.doctor_id,
            package_id: appointment.package_id,
            doctor: serialize_doctor_summary(appointment.doctor),
            package: serialize_package_summary(appointment.package),
            status: attribute_value(appointment, :status),
            scheduled_by: attribute_value(appointment, :scheduled_by),
            source: attribute_value(appointment, :source),
            notes: attribute_value(appointment, :notes),
            canceled_at: attribute_value(appointment, :canceled_at),
            cancellation_reason: attribute_value(appointment, :cancellation_reason),
            clinical: {
              status: attribute_value(appointment, :clinical_status),
              check_in_id: attribute_value(appointment, :clinical_check_in_id),
              attended_at: attribute_value(appointment, :attended_at),
              updated_at: attribute_value(appointment, :clinical_updated_at)
            },
            references: {
              unique_code: attribute_value(appointment, :unique_code)
            },
            created_at: appointment.created_at,
            updated_at: appointment.updated_at
          }
        end

        def serialize_doctor(doctor)
          user = doctor.respond_to?(:user) ? doctor.user : nil
          specialty = doctor.respond_to?(:specialty) ? doctor.specialty : nil

          {
            id: doctor.id,
            user_id: user&.id,
            name: doctor_name(doctor, user),
            first_name: first_present_attribute(doctor, user, :first_name),
            last_name: first_present_attribute(doctor, user, :last_name),
            email: first_present_attribute(doctor, user, :email),
            phone: first_present_attribute(doctor, user, :phone),
            active: doctor_active?(doctor, user),
            specialty: serialize_specialty(specialty),
            professional_license: first_present_attribute(
              doctor,
              user,
              :professional_license
            ),
            timezone: first_present_attribute(doctor, user, :timezone),
            created_at: doctor.created_at,
            updated_at: doctor.updated_at
          }
        end

        def serialize_package(package)
          {
            id: package.id,
            name: attribute_value(package, :name),
            description: attribute_value(package, :description),
            price: attribute_value(package, :price)&.to_s,
            currency: attribute_value(package, :currency),
            duration: attribute_value(package, :duration),
            kind: attribute_value(package, :kind),
            active: package_active?(package),
            image_url: image_url_for(package),
            form_schema: attribute_value(package, :form_schema),
            created_at: package.created_at,
            updated_at: package.updated_at
          }
        end

        def serialize_time_block(block)
          ends_on = block.all_day? ? (block.ends_at.to_date - 1.day) : nil

          {
            id: block.id,
            doctor_id: block.doctor_id,
            starts_at: block.starts_at,
            ends_at: block.ends_at,
            starts_on: block.all_day? ? block.starts_at.to_date : nil,
            ends_on: ends_on,
            all_day: block.all_day,
            reason: block.reason,
            source: block.source,
            status: block.canceled_at.present? ? "canceled" : "active",
            canceled_at: block.canceled_at,
            created_at: block.created_at,
            updated_at: block.updated_at
          }
        end

        def serialize_calendar_appointment(appointment)
          {
            id: "appointment-#{appointment.id}",
            resource_type: "appointment",
            resource_id: appointment.id,
            title: attribute_value(appointment.package, :name).presence || "Cita",
            start_at: attribute_value(appointment, :start_date),
            end_at: attribute_value(appointment, :end_date),
            all_day: false,
            status: attribute_value(appointment, :status),
            editable: appointment_editable?(appointment),
            metadata: {
              package_name: attribute_value(appointment.package, :name),
              patient_display_name: attribute_value(appointment, :name),
              phone: attribute_value(appointment, :phone)
            }
          }
        end

        def serialize_calendar_block(block)
          {
            id: "time-block-#{block.id}",
            resource_type: "time_block",
            resource_id: block.id,
            title: block.reason.presence || "No disponible",
            start_at: block.starts_at,
            end_at: block.ends_at,
            all_day: block.all_day,
            status: block.canceled_at.present? ? "canceled" : "active",
            editable: block.canceled_at.blank?,
            metadata: {
              reason: block.reason,
              source: block.source
            }
          }
        end

        def serialize_doctor_summary(doctor)
          return nil unless doctor

          {
            id: doctor.id,
            name: doctor_name(doctor, doctor.respond_to?(:user) ? doctor.user : nil)
          }
        end

        def serialize_package_summary(package)
          return nil unless package

          {
            id: package.id,
            name: attribute_value(package, :name),
            description: attribute_value(package, :description),
            duration_minutes: attribute_value(package, :duration),
            price: attribute_value(package, :price)&.to_s,
            kind: attribute_value(package, :kind)
          }
        end

        def serialize_specialty(specialty)
          return nil if specialty.blank?

          if specialty.respond_to?(:id) && specialty.respond_to?(:name)
            {
              id: specialty.id,
              name: specialty.name
            }
          else
            {
              id: nil,
              name: specialty.to_s
            }
          end
        end

        def image_url_for(package)
          return nil unless package.respond_to?(:image)
          return nil unless package.image.attached?

          rails_blob_url(package.image, host: request.base_url)
        end

        def doctor_name(doctor, user)
          name = attribute_value(doctor, :name)
          return name if name.present?

          name = attribute_value(user, :name)
          return name if name.present?

          [
            first_present_attribute(doctor, user, :first_name),
            first_present_attribute(doctor, user, :last_name)
          ].compact.join(" ").presence
        end

        def doctor_active?(doctor, user)
          return doctor.active if doctor.respond_to?(:active)
          return user.active if user&.respond_to?(:active)

          true
        end

        def package_active?(package)
          return package.active if package.respond_to?(:active)

          true
        end

        def appointment_editable?(appointment)
          status = attribute_value(appointment, :status).to_s
          !status.include?("cancel") && status != "completed"
        end

        def first_present_attribute(primary, fallback, name)
          value = attribute_value(primary, name)
          return value if value.present?

          attribute_value(fallback, name)
        end

        def attribute_value(record, name)
          return nil unless record
          return nil unless record.respond_to?(name)

          record.public_send(name)
        end
      end
    end
  end
end