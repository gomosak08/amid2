# app/lib/phone_normalizer.rb
class PhoneNormalizer
  def self.to_e164(phone, default_country: "MX")
    return nil if phone.blank?

    digits = phone.to_s.gsub(/\D+/, "")

    if default_country == "MX"
      return "+52#{digits}" if digits.length == 10
      return "+#{digits}" if digits.length == 12 && digits.start_with?("52")
      return "+#{digits}" if digits.length >= 11
    end

    "+#{digits}"
  end
end
