# config/initializers/recaptcha_debug.rb
if defined?(Recaptcha::Configuration)
  LOGFILE = Rails.root.join("log/recaptcha_debug.log")

  def _recaptcha_dbg(msg)
    File.open(LOGFILE, "a") { |f| f.puts("[#{Time.now.iso8601}] #{msg}") }
  end

  # Log initial al boot
  begin
    cfg = Recaptcha.configuration
    _recaptcha_dbg "BOOT cfg: site=#{cfg.site_key.to_s[0, 8]}..., secret_present=#{cfg.secret_key.present?}, enterprise=#{cfg.enterprise}"
  rescue => e
    _recaptcha_dbg "BOOT error: #{e.class}: #{e.message}"
  end

  # 1) Intercepta cualquier llamada a Recaptcha.configure
  Recaptcha.singleton_class.class_eval do
    alias_method :_orig_recaptcha_configure, :configure
    def configure(&blk)
      origin = caller_locations(1, 20).map(&:to_s).find { |s| s.start_with?(Rails.root.to_s) } || caller_locations(1, 1).first.to_s
      File.open(Rails.root.join("log/recaptcha_debug.log"), "a") do |f|
        f.puts "[#{Time.now.iso8601}] Recaptcha.configure called FROM: #{origin}"
      end
      _orig_recaptcha_configure(&blk)
    end
  end

  # 2) Intercepta el setter de site_key y loguea el origen REAL (primer frame dentro de tu app)
  Recaptcha::Configuration.class_eval do
    alias_method :_orig_site_key_setter, :site_key=
    define_method(:site_key=) do |val|
      origin = caller_locations(1, 20).map(&:to_s).find { |s| s.start_with?(Rails.root.to_s) } || caller_locations(1, 1).first.to_s
      File.open(Rails.root.join("log/recaptcha_debug.log"), "a") do |f|
        f.puts "[#{Time.now.iso8601}] SETTING site_key to #{val.to_s[0, 8]}... FROM: #{origin}"
      end
      _orig_site_key_setter(val)
    end
  end
end
