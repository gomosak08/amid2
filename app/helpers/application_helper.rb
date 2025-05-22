module ApplicationHelper
    SPANISH_MONTHS = {
        "January" => "enero", "February" => "febrero", "March" => "marzo",
        "April" => "abril", "May" => "mayo", "June" => "junio",
        "July" => "julio", "August" => "agosto", "September" => "septiembre",
        "October" => "octubre", "November" => "noviembre", "December" => "diciembre"
      }.freeze
    Recaptcha.configure do |config|
      config.site_key  = '6Lc7QcAqAAAAAPk1u8ZUhERnY-TUqN3Y041KBOzN'
      config.secret_key = 'your-secret-key'
    end
end
