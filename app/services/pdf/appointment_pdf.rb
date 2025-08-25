# app/services/pdf/appointment_pdf.rb
# frozen_string_literal: true

module Pdf
  class AppointmentPdf
    def initialize(appointment, logo_path:, brand_color: "3A86FF")
      @a          = appointment
      @logo_path  = logo_path
      @brand_hex  = hex(brand_color)
    end

    def status_key
      @appointment.status.to_s # "scheduled", "canceled_by_admin", etc.
    end

    def status_label
      I18n.t(
        "activerecord.attributes.appointment.statuses.#{status_key}",
        default: status_key.humanize
      )
    end

    def status_color
      case status_key
      when "scheduled"                         then hex("2BB673") # verde
      when "pending"                           then hex("F4B942") # ámbar (si existe en tu enum)
      when "canceled_by_admin", "canceled_by_client"
                                                then hex("E63946") # rojo
      else
        palette[:brand]
      end
    end


    def render
      Prawn::Document.new(page_size: "A4", margin: [ 90, 36, 36, 36 ]) do |pdf|
        setup_fonts(pdf)
        draw_header_band(pdf)
        draw_header(pdf)
        draw_main_card(pdf)
        draw_instructions(pdf)
        draw_link_and_qr(pdf)
        draw_footer(pdf)
      end.render
    end

    private

    # ---------- helpers de estilo/datos ----------
    def hex(v) v.to_s.delete("#").upcase end

    def palette
      @palette ||= {
        brand:     @brand_hex,
        light_bg:  hex("F5F7FB"),
        border:    hex("DDDEE3"),
        text_gray: hex("4A4A4A")
      }
    end

    def with_g(pdf)
      pdf.save_graphics_state
      yield
    ensure
      pdf.restore_graphics_state
    end

    def status_text
      I18n.t(
        "activerecord.attributes.appointment.statuses.#{@a.status}",
        default: @a.status.to_s.humanize
      )
    end

    def status_color
      status_text = I18n.t("activerecord.attributes.appointment.statuses")
      case status_text.downcase
      when "confirmada", "confirmado", "activa" then hex("2BB673")
      when "pendiente"                          then hex("F4B942")
      when "cancelada", "cancelado"             then hex("E63946")
      else palette[:brand]
      end
    end

    def text_pair(pdf, label, value, label_size: 10, value_size: 12, bold_value: false)
      pdf.fill_color palette[:text_gray]
      pdf.text label, size: label_size
      pdf.fill_color "000000"
      pdf.text((value.presence || "N/A"), size: value_size, style: (bold_value ? :bold : :normal))
      pdf.move_down 10
    end

    # ---------- secciones ----------
    def setup_fonts(pdf)
      begin
        pdf.font_families.update(
          "Inter" => {
            normal: Rails.root.join("app/assets/fonts/Inter-Regular.ttf"),
            bold:   Rails.root.join("app/assets/fonts/Inter-Bold.ttf"),
            medium: Rails.root.join("app/assets/fonts/Inter-Medium.ttf")
          }
        )
        pdf.font "Inter"
      rescue
        # usa default si no hay fuentes
      end
    end

    def draw_header_band(pdf)
      header_offset = 24
      with_g(pdf) do
        pdf.fill_color palette[:light_bg]
        pdf.fill_rounded_rectangle [ pdf.bounds.left, pdf.cursor + 50 - header_offset ], pdf.bounds.width, 80, 10
      end
      pdf.move_down header_offset
    end

    def draw_header(pdf)
      generated_at = I18n.l(Time.zone.now, format: :custom, locale: :es)
      pdf.bounding_box([ pdf.bounds.left + 12, pdf.cursor + 60 ], width: pdf.bounds.width - 24, height: 80) do
        if @logo_path.present? && File.exist?(@logo_path.to_s)
          pdf.bounding_box([ 0, pdf.bounds.top ], width: 140, height: 60) do
            with_g(pdf) { pdf.image @logo_path.to_s, fit: [ 120, 60 ] }
          end
        end

        pdf.fill_color palette[:brand]
        pdf.text_box "Detalles de la Cita", size: 22, style: :bold, at: [ 160, 58 ], width: 340
        pdf.fill_color palette[:text_gray]
        pdf.text_box "Generado el #{generated_at}", size: 10, at: [ 160, 34 ], width: 340

        # badge de estado, centrado vertical
        badge_w = 120
        bx      = pdf.bounds.width - badge_w
        by      = 58
        with_g(pdf) do
          pdf.fill_color status_color
          pdf.fill_rounded_rectangle [ bx, by ], badge_w, 22, 6
          pdf.fill_color "FFFFFF"
          pdf.bounding_box([ bx, by ], width: badge_w, height: 22) do
            pdf.text status_text.upcase, size: 10, style: :bold, align: :center, valign: :center
          end
        end
        pdf.fill_color "000000"
      end
      pdf.move_down 28
    end

    def draw_main_card(pdf)
      with_g(pdf) do
        pdf.fill_color palette[:light_bg]
        pdf.stroke_color palette[:border]
        pdf.fill_rounded_rectangle [ pdf.bounds.left, pdf.cursor ], pdf.bounds.width, 160, 10
        pdf.stroke_rounded_rectangle [ pdf.bounds.left, pdf.cursor ], pdf.bounds.width, 160, 10
      end
      pdf.move_down 12

      col_w = (pdf.bounds.width - 24) / 2.0

      # izquierda
      pdf.bounding_box([ pdf.bounds.left + 12, pdf.cursor ], width: col_w, height: 140) do
        text_pair(pdf, "Paciente",  @a.name, bold_value: true, value_size: 14)
        text_pair(pdf, "Doctor(a)", @a.doctor&.name)
        text_pair(pdf, "Paquete",   @a.package&.name)
      end

      # derecha
      start_time_str = begin
        I18n.l(@a.start_date.in_time_zone("America/Mexico_City"), format: :custom, locale: :es)
      rescue
        "N/A"
      end

      pdf.bounding_box([ pdf.bounds.left + 24 + col_w, pdf.cursor + 140 ], width: col_w, height: 140) do
        text_pair(pdf, "Fecha y hora", start_time_str)
        text_pair(pdf, "Teléfono",     @a.phone)
        text_pair(pdf, "Código único", @a.unique_code, bold_value: true)
      end

      pdf.move_down 22
    end

    def draw_instructions(pdf)
      pdf.fill_color palette[:brand]
      pdf.text "Indicaciones", size: 12, style: :bold
      pdf.fill_color "000000"
      pdf.move_down 6
      pdf.text "• Presentarse 10 minutos antes de la hora programada."
      pdf.text "• Llevar una identificación oficial y esta confirmación."
      pdf.text "• El código único puede utilizarse para cancelar o reprogramar su cita (24 h de anticipación)."
      pdf.text "• Si presenta síntomas el día de su cita, comuníquese para reprogramar."
      pdf.move_down 18
    end

    def draw_link_and_qr(pdf)
      host  = Rails.application.routes.default_url_options[:host] || "http://localhost:3000"
      host  = host.to_s
      host  = "https://#{host}" unless host.start_with?("http://", "https://")
      token = @a.token.to_s

      if token.present?
        url = "#{host}/appointments/#{token}/edit"
        pdf.text "Para cancelar o reprogramar su cita, use:"
        pdf.formatted_text [ { text: url, link: url, styles: [ :underline ] } ]
        pdf.move_down 12

        pdf.fill_color palette[:brand]
        pdf.text "QR de confirmación", size: 12, style: :bold
        pdf.fill_color "000000"
        draw_qr(pdf, url, fg_hex: palette[:brand], module_size: 3)
      else
        pdf.fill_color "E63946"
        pdf.text "⚠︎ No se pudo generar el QR ni el enlace: falta token de la cita.", size: 9
        pdf.fill_color "000000"
      end
    end

    def draw_qr(pdf, payload, fg_hex:, module_size: 3, quiet_zone: 2)
      begin
        require "rqrcode"
      rescue LoadError
        pdf.fill_color "E63946"
        pdf.text "⚠︎ Instala la gema `rqrcode` para generar el QR.", size: 9
        pdf.fill_color "000000"
        return
      end

      qrcode = RQRCode::QRCode.new(payload.to_s)

      matrix = qrcode.respond_to?(:modules) ? qrcode.modules : nil
      count  = if qrcode.respond_to?(:module_count)
                 qrcode.module_count
      elsif matrix
                 matrix.length
      else
                 (qrcode.instance_variable_get(:@module_count) || 0).to_i
      end
      raise "Tamaño de QR inválido" if count <= 0

      module_size = module_size.to_i > 0 ? module_size.to_i : 3
      quiet_zone  = quiet_zone.to_i  >= 0 ? quiet_zone.to_i  : 2

      size_in_modules = count + quiet_zone * 2
      px = size_in_modules * module_size

      pdf.bounding_box([ pdf.bounds.left, pdf.cursor ], width: px, height: px) do
        start_y = pdf.bounds.top
        pdf.fill_color fg_hex
        count.times do |row|
          count.times do |col|
            dark = if qrcode.respond_to?(:dark?)
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
      pdf.move_down px + 6
      pdf.fill_color "000000"
    rescue => e
      pdf.fill_color "E63946"
      pdf.text "Error al generar QR: #{e.class} — #{e.message}", size: 9
      pdf.fill_color "000000"
    end

    def draw_footer(pdf)
      pdf.number_pages "<page>/<total>", at: [ pdf.bounds.right - 50, 0 ], width: 50, align: :right, size: 9
      page_total = pdf.page_count
      (1..page_total).each do |i|
        pdf.go_to_page(i)
        pdf.bounding_box([ pdf.bounds.left, 30 ], width: pdf.bounds.width, height: 30) do
          pdf.stroke_color palette[:border]
          pdf.stroke_horizontal_rule
          pdf.move_down 6
          pdf.fill_color palette[:text_gray]
          pdf.text "Centro Médico — Tel. (55) 0000 0000 — soporte@centromedico.mx", size: 9, align: :center
          pdf.text "Dirección: Avenida Salud 123, CDMX — www.centromedico.mx",       size: 9, align: :center
          pdf.fill_color "000000"
        end
      end
    end
  end
end
