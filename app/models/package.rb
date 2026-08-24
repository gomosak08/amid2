class Package < ApplicationRecord
  KIND_OPTIONS = {
    "servicio" => "Servicios",
    "paquete" => "Paquetes",
    "ginecologia" => "Ginecología",
    "ultrasonido" => "Ultrasonidos",
    "servicio_especial" => "Servicios Especiales"
  }.freeze

  KIND_ALIASES = {
    "servicios" => "servicio",
    "Ultrasonido" => "ultrasonido",
    "Ultrasonidos" => "ultrasonido",
    "Servicio Especiale" => "servicio_especial",
    "Servicios Especiales" => "servicio_especial"
  }.freeze

  has_many :doctor_packages, dependent: :destroy
  has_many :doctors, through: :doctor_packages
  has_one_attached :image

  serialize :kinds, coder: JSON, type: Array unless connection.adapter_name == "PostgreSQL"

  before_validation :normalize_kinds

  validates :image, presence: true
  validates :kinds, presence: true
  validate :kinds_are_supported

  scope :publicly_listed, lambda {
    if connection.adapter_name == "PostgreSQL"
      where.not(kinds: []).where("NOT ('cirugia' = ANY(packages.kinds))")
    else
      where("kinds <> ?", "[]").where("kinds NOT LIKE ?", '%"cirugia"%')
    end
  }

  def self.with_kind(value)
    if connection.adapter_name == "PostgreSQL"
      where("? = ANY(packages.kinds)", value.to_s)
    else
      where("kinds LIKE ?", '%"' + sanitize_sql_like(value.to_s) + '"%')
    end
  end

  def kind_labels
    kinds.map { |value| KIND_OPTIONS.fetch(value, value.humanize) }
  end

  private

  def normalize_kinds
    selected = Array(kinds).filter_map do |value|
      normalized = value.to_s.strip
      next if normalized.blank?

      KIND_ALIASES.fetch(normalized, normalized)
    end

    legacy_kind = kind.to_s.strip
    selected << KIND_ALIASES.fetch(legacy_kind, legacy_kind) if selected.empty? && legacy_kind.present?

    self.kinds = selected.uniq
    self.kind = kinds.first
  end

  def kinds_are_supported
    unsupported = Array(kinds) - KIND_OPTIONS.keys
    errors.add(:kinds, "incluye tipos no válidos: #{unsupported.join(', ')}") if unsupported.any?
  end
end
