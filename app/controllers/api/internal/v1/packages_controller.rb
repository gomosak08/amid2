module Api
  module Internal
    module V1
      class PackagesController < BaseController
        before_action :set_package, only: :show

        # GET /api/internal/v1/packages
        def index
          packages = Package
            .with_attached_image
            .order(:id)

          packages = apply_filters(packages)

          total_count = packages.count
          packages = paginate(packages)

          render_success(
            data: packages.map do |package|
              serialize_package(package)
            end,
            meta: pagination_meta(total_count).merge(
              synchronized_at: Time.current.iso8601
            )
          )
        end

        # GET /api/internal/v1/packages/:id
        def show
          render_success(
            data: serialize_package(@package)
          )
        end

        private

        def set_package
          @package = Package
            .with_attached_image
            .find(params[:id])
        end

        def apply_filters(scope)
          if params[:kind].present? &&
             Package.column_names.include?("kind")
            scope = scope.where(kind: params[:kind])
          end

          if params[:active].present? &&
             Package.column_names.include?("active")
            active = ActiveModel::Type::Boolean.new.cast(
              params[:active]
            )

            scope = scope.where(active: active)
          end

          if params[:updated_since].present?
            updated_since = parse_iso8601_time(
              params[:updated_since]
            )

            return scope if performed?

            scope = scope.where(
              "packages.updated_at >= ?",
              updated_since
            )
          end

          scope
        end

        def serialize_package(package)
          {
            id: package.id,
            name: package.name,
            description: value_if_present(
              package,
              :description
            ),
            price: package.price&.to_s,
            currency: value_if_present(
              package,
              :currency
            ),
            duration: package.duration,
            kind: package.kind,
            active: package_active?(package),
            image_url: image_url_for(package),
            form_schema: value_if_present(
              package,
              :form_schema
            ),
            created_at: package.created_at,
            updated_at: package.updated_at
          }
        end

        def package_active?(package)
          return package.active if package.has_attribute?(:active)

          true
        end

        def value_if_present(record, name)
          return nil unless record.respond_to?(name)

          record.public_send(name)
        end

        def image_url_for(package)
          return nil unless package.image.attached?

          rails_blob_url(
            package.image,
            host: request.base_url
          )
        end
      end
    end
  end
end
