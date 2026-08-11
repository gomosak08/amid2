module Api
  module Internal
    class PackagesController < BaseController
      def index
        packages = Package
          .with_attached_image
          .order(:id)

        render json: {
          packages: packages.map { |package| package_data(package) },
          synchronized_at: Time.current.iso8601
        }
      end

      def show
        package = Package.with_attached_image.find(params[:id])

        render json: {
          package: package_data(package)
        }
      end

      private

      def package_data(package)
        {
          id: package.id,
          name: package.name,
          description: package.try(:description),
          price: package.price,
          duration: package.duration,
          kind: package.kind,
          image_url: image_url_for(package),
          created_at: package.created_at.iso8601,
          updated_at: package.updated_at.iso8601
        }
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