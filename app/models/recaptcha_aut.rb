class RecaptchaAut
    require "google/cloud/recaptcha_enterprise"

    # Crea una evaluación para analizar el riesgo de una acción de la IU.
    #
    # @param recaptcha_key [String] La clave reCAPTCHA asociada con el sitio o la aplicación
    # @param token [String] El token generado obtenido del cliente.
    # @param project_id [String] El ID del proyecto de Google Cloud.
    # @param recaptcha_action [String] El nombre de la acción que corresponde al token.
    # @return [void]
    def create_assessment recaptcha_key:, token:, project_id:, recaptcha_action:
      # Crea el cliente de reCAPTCHA.
      client = ::Google::Cloud::RecaptchaEnterprise.recaptcha_enterprise_service
    
      request = { parent: "projects/#{project_id}",
                  assessment: {
                    event: {
                      site_key: recaptcha_key,
                      token: token
                    }
                  } }
    
      response = client.create_assessment request
    
      # Verifica si el token es válido.
      if !response.token_properties.valid
        puts "The create_assessment() call failed because the token was invalid with the following reason:" \
             "#{response.token_properties.invalid_reason}"
      # Verifica si se ejecutó la acción esperada.
      elsif response.token_properties.action == recaptcha_action
        # Obtén la puntuación de riesgo y los motivos.
        # Para obtener más información sobre cómo interpretar la evaluación, consulta:
        # https://cloud.google.com/recaptcha-enterprise/docs/interpret-assessment
        puts "The reCAPTCHA score for this token is: #{response.risk_analysis.score}"
        response.risk_analysis.reasons.each { |reason| puts reason }
      else
        puts "The action attribute in your reCAPTCHA tag does not match the action you are expecting to score"
      end
    end
end