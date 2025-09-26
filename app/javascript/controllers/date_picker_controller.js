// app/javascript/controllers/date_picker_controller.js
import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { Spanish } from "flatpickr/dist/l10n/es.js"

export default class extends Controller {
  static targets = ["input", "label", "card", "panel", "anchor"]

  connect() {
    this._outside = this._onOutsideClick.bind(this)
    // Listener en burbujeo (NO en captura) para no interferir con el click de abrir
    document.addEventListener("click", this._outside)
  }

  disconnect() {
    document.removeEventListener("click", this._outside)
    this.inputTarget?._flatpickr?.destroy?.()
  }

  // Abre/cierra el panel del calendario
  toggle(e) {
    e?.preventDefault()
    if (this.panelTarget.classList.contains("hidden")) {
      this.#ensureCalendar()
      this.showPanel()
    } else {
      this.hidePanel()
    }
  }

  showPanel() {
    this.panelTarget.classList.remove("hidden")
    this.cardTarget.setAttribute("aria-expanded", "true")
    // opcional scroll
    // this.panelTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }

  hidePanel() {
    this.panelTarget.classList.add("hidden")
    this.cardTarget.setAttribute("aria-expanded", "false")
  }

  // Al elegir fecha: actualiza label y cierra
  onChange = (dates) => {
    const d = dates?.[0]
    if (d && this.hasLabelTarget) {
      this.labelTarget.textContent = d.toLocaleDateString("es-MX", {
        day: "2-digit", month: "2-digit", year: "numeric"
      })
    }
    this.hidePanel()
  }

  // Inicializa flatpickr inline solo una vez
  #ensureCalendar() {
    if (!this.inputTarget?._flatpickr) {
      flatpickr(this.inputTarget, {
        inline: true,
        appendTo: this.anchorTarget,  // render dentro del contenedor oculto
        clickOpens: false,
        dateFormat: "Y-m-d",
        defaultDate: this.inputTarget.value || undefined,
        minDate: "today",
        locale: Spanish,
        onChange: this.onChange,
      })
    }
  }

  // Cierra si hacen click fuera de la barra o del panel
  _onOutsideClick(evt) {
    if (!this.element.contains(evt.target)) return
    const insideCard = this.cardTarget.contains(evt.target)
    const insidePanel = this.panelTarget.contains(evt.target)
    if (!insideCard && !insidePanel) this.hidePanel()
  }
}
