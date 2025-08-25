Rails.application.routes.default_url_options[:host]     = ENV.fetch("APP_HOST", "amid.mx")
Rails.application.routes.default_url_options[:protocol] = ENV.fetch("APP_PROTOCOL", "http")
