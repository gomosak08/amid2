module ApplicationHelper
    SPANISH_MONTHS = {
        "January" => "enero", "February" => "febrero", "March" => "marzo",
        "April" => "abril", "May" => "mayo", "June" => "junio",
        "July" => "julio", "August" => "agosto", "September" => "septiembre",
        "October" => "octubre", "November" => "noviembre", "December" => "diciembre"
      }.freeze

    # Formats money as MXN without locale currency symbols (e.g. "$1234.50").
    def mxn(amount)
      return "—" if amount.blank?

      "$#{number_with_precision(amount, precision: 2, separator: ".", delimiter: "")}"
    end

    PUBLIC_HIDDEN_SERVICE_NAMES = [
      "Ultrasonido Doppler",
      "Ultrasonido de Riñón"
    ].freeze

    PUBLIC_GYNECOLOGY_SERVICE_NAMES = [
      "Ultrasonido de Embarazo",
      "Blanqueamiento íntimo",
      "Histeroscopia",
      "Láser para incontinencia",
      "Láser para cicatrices",
      "Láser para estrías",
      "Láser para VPH",
      "Láser para rejuvenecimiento vaginal",
      "Láser para verrugas genitales",
      "Vacuna para VPH",
      "Biopsia de Cérvix",
      "Biopsia de Endometrio"
    ].freeze

    PUBLIC_SPECIAL_SERVICE_NAMES = [
      "Atención Psicológica",
      "Nutrición"
    ].freeze

    def amid_public_service_groups(packages)
      services = packages.select { |package| package.kind.to_s == "servicios" }
      visible_services = services.reject { |package| PUBLIC_HIDDEN_SERVICE_NAMES.include?(package.name) }

      ultrasounds = visible_services.select { |package| package.name.to_s.start_with?("Ultrasonido") }
      gynecology = visible_services.select { |package| PUBLIC_GYNECOLOGY_SERVICE_NAMES.include?(package.name) }
      special = visible_services.select { |package| PUBLIC_SPECIAL_SERVICE_NAMES.include?(package.name) }
      grouped_ids = (ultrasounds + gynecology + special).map(&:id).uniq
      general = visible_services.reject { |package| grouped_ids.include?(package.id) }

      {
        general: general,
        ultrasounds: ultrasounds,
        gynecology: gynecology,
        special: special
      }
    end

    def amid_missing_special_service_names(packages)
      existing_names = packages.map(&:name)
      PUBLIC_SPECIAL_SERVICE_NAMES - existing_names
    end
end
