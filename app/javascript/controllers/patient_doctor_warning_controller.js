import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  confirmChange(event) {
    const select = event.currentTarget
    const preferredDoctorId = select.dataset.patientDoctorWarningPreferredDoctorIdValue

    if (!preferredDoctorId || !select.value || select.value === preferredDoctorId) return

    const preferredOption = Array.from(select.options).find((option) => option.value === preferredDoctorId)
    const preferredName = preferredOption?.text || "tu médico habitual"
    const selectedName = select.selectedOptions[0]?.text || "otro médico"

    const ok = window.confirm(
      `Estás cambiando de ${preferredName} a ${selectedName}. ¿Deseas continuar con este médico para la cita?`
    )

    if (!ok) {
      select.value = preferredDoctorId
      select.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }
}
