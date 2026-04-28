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
end
