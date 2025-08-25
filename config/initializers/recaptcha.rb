Recaptcha.configure do |c|
  c.site_key        =  ENV["RECAPTCHA_SITE_KEY"]      # pública
  c.secret_key      =  ENV["RECAPTCHA_SECRET_KEY"]    # privada — LA MISMA que usaste en curl
  c.enterprise      = false                          # estás con v3 estándar
  c.skip_verify_env = []                             # no saltar en ningún entorno
end
