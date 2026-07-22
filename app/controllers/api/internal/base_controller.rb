module Api
  module Internal
    class BaseController < ActionController::API
      before_action :authenticate_internal_request!

      private

      def authenticate_internal_request!
        expected_token = ENV["CLINICAL_API_TOKEN"].to_s
        provided_token = bearer_token

        return if valid_token?(provided_token, expected_token)

        render json: { error: "No autorizado" }, status: :unauthorized
      end

      def bearer_token
        authorization = request.headers["Authorization"].to_s
        scheme, token = authorization.split(" ", 2)

        return unless scheme&.casecmp("Bearer")&.zero?

        token
      end

      def valid_token?(provided_token, expected_token)
        return false if provided_token.blank? || expected_token.blank?

        provided_digest = Digest::SHA256.hexdigest(provided_token)
        expected_digest = Digest::SHA256.hexdigest(expected_token)

        ActiveSupport::SecurityUtils.secure_compare(
          provided_digest,
          expected_digest
        )
      end
    end
  end
end
