# app/services/security/recaptcha_verify.rb
# frozen_string_literal: true

module User::Security
  class RecaptchaVerify
    def self.call(response:, action:, min_score: 0.0, remote_ip: nil)
      # TODO: integrar con la gema/SDK de reCAPTCHA que uses; devolver true/false
      false
    end
  end
end
