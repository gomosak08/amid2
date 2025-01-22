class AppointmentPdfGenerator
    def initialize(appointment)
      @appointment = appointment
    end
  
    def generate
      Prawn::Document.new do |pdf|
        # Add a title
        pdf.text "Detalles de la Cita", size: 24, style: :bold, align: :center
        pdf.move_down 20
  
        # Add appointment details
        pdf.text "Nombre: #{@appointment.name || 'N/A'}", size: 12
        pdf.text "Doctor: #{@appointment.doctor&.name || 'N/A'}", size: 12
        pdf.text "Paquete: #{@appointment.package&.name || 'N/A'}", size: 12
        pdf.text "Fecha de la Cita: #{I18n.l(@appointment.start_date, format: :custom, locale: :es) rescue 'N/A'}", size: 12
        pdf.text "Estado: #{@appointment.status || 'N/A'}", size: 12
        pdf.text "Teléfono: #{@appointment.phone || 'N/A'}", size: 12
        pdf.text "Codigo Unico: #{@appointment.unique_code || 'N/A'}", size: 12
        pdf.text "El codigo unico puede utilizarse para cancelar su cita, porfavor cancelar al menos 24 horas antes de su cita"
  
        pdf.move_down 20
        pdf.text "Generado el #{I18n.l(Time.zone.now, format: :custom, locale: :es)}", size: 10, align: :right
      end.render
    end
  end
  