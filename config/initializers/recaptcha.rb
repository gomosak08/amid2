Recaptcha.configure do |config|
    config.site_key  = Rails.application.credentials.dig(:recaptcha, :site_key)
    config.secret_key = Rails.application.credentials.dig(:recaptcha, :secret_key)
    #config.site_key  = ENV['RECAPTCHA_SITE_KEY']
    #config.secret_key = ENV['RECAPTCHA_SECRET_KEY']
    #Rails.logger.debug(ENV['RECAPTCHA_SITE_KEY'])
  end
  