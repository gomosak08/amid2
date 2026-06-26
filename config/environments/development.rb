require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Recargar código en cada petición
  config.enable_reloading = true

  # No eager load en desarrollo
  config.eager_load = false

  # Mostrar errores completos
  config.consider_all_requests_local = true

  # Desactivar caché
  config.action_controller.perform_caching = false

  # Hosts permitidos
  config.hosts << "localhost"
  config.hosts << "127.0.0.1"

  # URLs por defecto
  config.action_controller.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost:3000"),
    protocol: ENV.fetch("APP_PROTOCOL", "http")
  }

  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost:3000"),
    protocol: ENV.fetch("APP_PROTOCOL", "http")
  }

  Rails.application.routes.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost:3000"),
    protocol: ENV.fetch("APP_PROTOCOL", "http")
  }

  # Archivos locales
  config.active_storage.service = :local

  # Logs
  config.log_level = :debug
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.active_record.logger = ActiveSupport::Logger.new(STDOUT)

  config.log_tags = [ :request_id ]

  # Active Job
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Mailer
  config.action_mailer.perform_caching = false

  # Internacionalización
  config.i18n.fallbacks = true

  # Deprecaciones
  config.active_support.report_deprecations = true

  # No forzar HTTPS en desarrollo
  config.force_ssl = false

  # No volcar schema después de migraciones
  config.active_record.dump_schema_after_migration = false
end
