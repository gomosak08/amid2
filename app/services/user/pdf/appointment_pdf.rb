# frozen_string_literal: true

module User::Pdf
  class AppointmentPdf
    def initialize(appointment, logo_path:, brand_color: "3A86FF")
      @a          = appointment
      @logo_path  = logo_path
      @brand_hex  = hex(brand_color)
    end

    def render
      Prawn::Document.new(page_size: "A4", margin: [ 42, 42, 50, 42 ]) do |pdf|
        setup_fonts(pdf)

        draw_header(pdf)
        draw_main_card(pdf)
        draw_location_card(pdf)
        draw_link_and_qr(pdf)
        draw_instructions(pdf)
        draw_footer(pdf)
      end.render
    end

    private

    # ---------- helpers ----------
    def hex(v)
      v.to_s.delete("#").upcase
    end

    def palette
      @palette ||= {
        brand:      @brand_hex,
        brand_dark: hex("1D4ED8"),
        light_bg:   hex("F8FAFC"),
        soft_blue:  hex("EFF6FF"),
        border:     hex("DDE7F3"),
        text:       hex("0F172A"),
        text_gray:  hex("475569"),
        muted:      hex("64748B"),
        success_bg: hex("DCFCE7")
      }
    end

    def with_g(pdf)
      pdf.save_graphics_state
      yield
    ensure
      pdf.restore_graphics_state
    end

    def clinic_address
      ENV.fetch("AMID_ADDRESS", "Nueva Chapultepec, Morelia")
    end

    def clinic_maps_url
      ENV["AMID_MAPS_URL"].presence
    end

    # --- ESTATUS ---
    def status_key
      @a.status.to_s.presence || "scheduled"
    end

    def status_color
      case status_key
      when "scheduled"
        hex("2BB673")
      when "pending"
        hex("F4B942")
      when "canceled_by_admin", "canceled_by_client", "canceled"
        hex("E63946")
      else
        palette[:brand]
      end
    end

    # ---------- fuentes ----------
    def setup_fonts(pdf)
      font = pdf_font_paths
      return if font.blank?

      pdf.font_families.update(
        "AmidSans" => {
          normal: font[:normal],
          bold: font[:bold]
        }
      )

      pdf.font "AmidSans"
    rescue
      # Usa la fuente default si no hay fuentes disponibles.
    end

    def pdf_font_paths
      candidates = [
        {
          normal: Rails.root.join("app/assets/fonts/Inter-Regular.ttf"),
          bold: Rails.root.join("app/assets/fonts/Inter-Bold.ttf")
        },
        {
          normal: Pathname.new("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
          bold: Pathname.new("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
        },
        {
          normal: Pathname.new("/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf"),
          bold: Pathname.new("/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf")
        }
      ]

      candidates.find { |paths| paths.values.all? { |path| File.exist?(path.to_s) } }
    end

    # ---------- secciones ----------
    def draw_header(pdf)
      generated_at = format_datetime(Time.zone.now)
      header_h = 118
      start_y = pdf.cursor

      with_g(pdf) do
        pdf.fill_color palette[:soft_blue]
        pdf.fill_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, header_h, 14
        pdf.stroke_color palette[:border]
        pdf.stroke_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, header_h, 14
      end

      pdf.bounding_box([ pdf.bounds.left + 20, start_y - 18 ],
                       width: pdf.bounds.width - 40,
                       height: header_h - 28) do
        if logo_available?
          pdf.image @logo_path.to_s, fit: [ 112, 52 ], at: [ 0, 80 ]
        else
          pdf.fill_color palette[:brand]
          pdf.text "AMID", size: 22, style: :bold
        end

        pdf.fill_color palette[:brand_dark]
        pdf.text_box "Confirmación\nde cita",
                     size: 16,
                     style: :bold,
                     leading: 1,
                     at: [ 132, 78 ],
                     width: 178,
                     height: 44

        pdf.fill_color palette[:muted]
        pdf.text_box "Generado el #{generated_at}",
                     size: 8.5,
                     at: [ 132, 28 ],
                     width: 190

        badge_w = 142
        bx = pdf.bounds.width - badge_w
        by = 76

        with_g(pdf) do
          pdf.fill_color status_color
          pdf.fill_rounded_rectangle [ bx, by ], badge_w, 24, 7
          pdf.fill_color "FFFFFF"

          pdf.bounding_box([ bx, by ], width: badge_w, height: 24) do
            pdf.text @a.status_label.to_s.upcase,
                     size: 8.5,
                     style: :bold,
                     align: :center,
                     valign: :center
          end
        end

        pdf.fill_color palette[:text_gray]
        pdf.text_box "Código: #{safe_text(@a.unique_code)}",
                     size: 10.5,
                     at: [ bx, 40 ],
                     width: badge_w,
                     align: :center

        pdf.fill_color "000000"
      end

      pdf.move_cursor_to(start_y - header_h - 16)
    end

    def draw_main_card(pdf)
      card_h = 214
      start_y = pdf.cursor

      with_g(pdf) do
        pdf.fill_color "FFFFFF"
        pdf.stroke_color palette[:border]
        pdf.fill_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, card_h, 12
        pdf.stroke_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, card_h, 12
      end

      pdf.bounding_box([ pdf.bounds.left + 20, start_y - 18 ],
                       width: pdf.bounds.width - 40,
                       height: card_h - 30) do
        pdf.fill_color palette[:brand_dark]
        pdf.text "Datos de la cita", size: 14, style: :bold
        pdf.move_down 12

        package_box_y = pdf.cursor

        with_g(pdf) do
          pdf.fill_color palette[:soft_blue]
          pdf.fill_rounded_rectangle [ 0, package_box_y ], pdf.bounds.width, 54, 8
        end

        pdf.bounding_box([ 14, package_box_y - 10 ],
                         width: pdf.bounds.width - 28,
                         height: 36) do
          pdf.fill_color palette[:muted]
          pdf.text "PAQUETE / ESTUDIO", size: 8.5, style: :bold

          pdf.move_down 3

          pdf.fill_color palette[:text]
          pdf.text safe_text(@a.package&.name),
                   size: 12.5,
                   style: :bold,
                   leading: 1
        end

        col_w = (pdf.bounds.width - 20) / 2.0
        row_y = package_box_y - 76

        pdf.bounding_box([ 0, row_y ], width: col_w, height: 92) do
          text_pair(pdf, "Paciente", @a.name, bold_value: true, value_size: 14)
          text_pair(pdf, "Doctor(a)", @a.doctor&.name)
        end

        pdf.bounding_box([ col_w + 20, row_y ], width: col_w, height: 92) do
          text_pair(pdf, "Fecha y hora", appointment_start_text, bold_value: true)
          text_pair(pdf, "Teléfono", @a.phone)
        end
      end

      pdf.move_cursor_to(start_y - card_h - 16)
    end

    def draw_location_card(pdf)
      box_h = 96
      start_y = pdf.cursor

      with_g(pdf) do
        pdf.fill_color palette[:light_bg]
        pdf.stroke_color palette[:border]
        pdf.fill_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, box_h, 12
        pdf.stroke_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, box_h, 12
      end

      pdf.bounding_box([ pdf.bounds.left + 20, start_y - 16 ],
                       width: pdf.bounds.width - 40,
                       height: box_h - 24) do
        pdf.fill_color palette[:brand_dark]
        pdf.text "Lugar de la cita", size: 13, style: :bold

        pdf.move_down 8

        pdf.fill_color palette[:text]
        pdf.text clinic_address, size: 11.5, style: :bold, leading: 1.4

        if clinic_maps_url.present?
          pdf.move_down 7

          pdf.formatted_text [
            {
              text: "Abrir ubicación en Google Maps",
              link: clinic_maps_url,
              styles: [ :underline ],
              color: palette[:brand_dark]
            }
          ], size: 10
        end
      end

      pdf.move_cursor_to(start_y - box_h - 16)
    end

    def draw_link_and_qr(pdf)
      token = appointment_token

      if token.present?
        url = appointment_url(token)
        box_h = 136
        start_y = pdf.cursor

        if start_y - box_h < 54
          pdf.start_new_page
          start_y = pdf.cursor
        end

        with_g(pdf) do
          pdf.fill_color "FFFFFF"
          pdf.stroke_color palette[:border]
          pdf.fill_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, box_h, 12
          pdf.stroke_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, box_h, 12
        end

        pdf.bounding_box([ pdf.bounds.left + 20, start_y - 18 ],
                         width: pdf.bounds.width - 40,
                         height: box_h - 28) do
          qr_size = 96

          pdf.bounding_box([ 0, pdf.bounds.top ],
                           width: pdf.bounds.width - qr_size - 28,
                           height: 102) do
            pdf.fill_color palette[:brand_dark]
            pdf.text "Acceso a esta cita", size: 13, style: :bold

            pdf.move_down 8

            pdf.fill_color palette[:text_gray]
            pdf.text "Escanea el QR o abre la liga para consultar, cancelar o reprogramar esta cita.",
                     size: 10.5,
                     leading: 2

            pdf.move_down 8

            pdf.fill_color palette[:muted]
            pdf.text "Liga directa:", size: 8.5, style: :bold

            pdf.move_down 2

            pdf.formatted_text [
              {
                text: url,
                link: url,
                styles: [ :underline ],
                color: palette[:brand_dark]
              }
            ], size: 9
          end

          pdf.bounding_box([ pdf.bounds.right - qr_size, pdf.bounds.top ],
                           width: qr_size,
                           height: qr_size) do
            draw_qr(
              pdf,
              url,
              fg_hex: palette[:brand_dark],
              module_size: 2,
              quiet_zone: 3,
              move_after: false
            )
          end
        end

        pdf.move_cursor_to(start_y - box_h - 16)
      else
        pdf.fill_color "E63946"
        pdf.text "No se pudo generar el QR ni el enlace: falta token de la cita.", size: 9
        pdf.fill_color "000000"
      end
    end

    def draw_instructions(pdf)
      box_h = 104
      start_y = pdf.cursor

      if start_y - box_h < 54
        pdf.start_new_page
        start_y = pdf.cursor
      end

      with_g(pdf) do
        pdf.fill_color palette[:light_bg]
        pdf.stroke_color palette[:border]
        pdf.fill_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, box_h, 12
        pdf.stroke_rounded_rectangle [ pdf.bounds.left, start_y ], pdf.bounds.width, box_h, 12
      end

      pdf.bounding_box([ pdf.bounds.left + 20, start_y - 16 ],
                       width: pdf.bounds.width - 40,
                       height: box_h - 26) do
        pdf.fill_color palette[:brand_dark]
        pdf.text "Indicaciones", size: 13, style: :bold

        pdf.move_down 8

        pdf.fill_color palette[:text_gray]

        [
          "Presentarse 10 minutos antes de la hora programada.",
          "Llevar una identificación oficial.",
          "Presentar este comprobante al llegar.",
          "Conserva tu código único para cualquier aclaración."
        ].each do |item|
          pdf.text "- #{item}", size: 10, leading: 1.5
        end
      end

      pdf.move_cursor_to(start_y - box_h - 16)
    end

    def text_pair(pdf, label, value, label_size: 10, value_size: 12, bold_value: false)
      pdf.fill_color palette[:muted]
      pdf.text label.to_s.upcase, size: label_size, style: :bold

      pdf.move_down 2

      pdf.fill_color palette[:text]
      pdf.text safe_text(value),
               size: value_size,
               style: bold_value ? :bold : :normal,
               leading: 1

      pdf.move_down 11
    end

    # ---------- QR ----------
    def draw_qr(pdf, payload, fg_hex:, module_size: 3, quiet_zone: 2, move_after: true)
      begin
        require "rqrcode"
      rescue LoadError
        pdf.fill_color "E63946"
        pdf.text "Instala la gema `rqrcode` para generar el QR.", size: 9
        pdf.fill_color "000000"
        return
      end

      qrcode = RQRCode::QRCode.new(payload.to_s)
      matrix = qrcode.respond_to?(:modules) ? qrcode.modules : nil

      count =
        if qrcode.respond_to?(:module_count)
          qrcode.module_count
        elsif matrix
          matrix.length
        else
          qrcode.instance_variable_get(:@module_count).to_i
        end

      raise "Tamaño de QR inválido" if count <= 0

      module_size = module_size.to_i.positive? ? module_size.to_i : 3
      quiet_zone  = quiet_zone.to_i >= 0 ? quiet_zone.to_i : 2

      size_in_modules = count + quiet_zone * 2
      px = size_in_modules * module_size

      pdf.bounding_box([ pdf.bounds.left, pdf.cursor ], width: px, height: px) do
        start_y = pdf.bounds.top
        pdf.fill_color fg_hex

        count.times do |row|
          count.times do |col|
            dark =
              if qrcode.respond_to?(:dark?)
                qrcode.dark?(row, col)
              else
                matrix[row][col]
              end

            next unless dark

            x = (col + quiet_zone) * module_size
            y = start_y - (row + quiet_zone) * module_size

            pdf.fill_rectangle [ x, y ], module_size, module_size
          end
        end
      end

      pdf.move_down px + 6 if move_after
      pdf.fill_color "000000"
    rescue => e
      pdf.fill_color "E63946"
      pdf.text "Error al generar QR: #{e.class} - #{e.message}", size: 9
      pdf.fill_color "000000"
    end

    # ---------- footer ----------
    def draw_footer(pdf)
      pdf.number_pages "<page>/<total>",
                       at: [ pdf.bounds.right - 50, 0 ],
                       width: 50,
                       align: :right,
                       size: 9

      (1..pdf.page_count).each do |i|
        pdf.go_to_page(i)

        pdf.bounding_box([ pdf.bounds.left, 30 ], width: pdf.bounds.width, height: 30) do
          pdf.stroke_color palette[:border]
          pdf.stroke_horizontal_rule

          pdf.move_down 6

          pdf.fill_color palette[:text_gray]
          pdf.text "AMID - Comprobante de cita", size: 9, align: :center
          pdf.text "Presenta este documento al llegar a tu consulta.", size: 9, align: :center

          pdf.fill_color "000000"
        end
      end
    end

    # ---------- datos ----------
    def logo_available?
      @logo_path.present? && File.exist?(@logo_path.to_s)
    end

    def appointment_token
      return @a.token if @a.token.present?
      return unless @a.persisted?

      token = SecureRandom.hex(16)
      token = SecureRandom.hex(16) while Appointment.exists?(token: token)

      @a.update_column(:token, token)
      @a.token = token
    rescue
      nil
    end

    def appointment_start_text
      format_datetime(@a.start_date&.in_time_zone("America/Mexico_City"))
    rescue
      "N/A"
    end

    def format_datetime(value)
      return "N/A" if value.blank?

      I18n.l(value, format: :custom, locale: :es)
    rescue
      value.to_s
    end

    def appointment_url(token)
      defaults = Rails.application.routes.default_url_options

      host = defaults[:host].to_s
      protocol = defaults[:protocol].presence || "https"

      host = "localhost:3000" if host.blank?
      host = "#{protocol}://#{host}" unless host.start_with?("http://", "https://")

      "#{host}/appointments/#{token}/edit"
    end

    def safe_text(value)
      value.to_s.presence || "N/A"
    end
  end
end
