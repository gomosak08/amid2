import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { Spanish } from "flatpickr/dist/l10n/es.js"

export default class extends Controller {
  static targets = ["input", "label", "panel", "anchor", "card"]

  connect() {
    if (!this.hasAnchorTarget || !this.hasInputTarget) return

    this.flatpickr = flatpickr(this.anchorTarget, {
      inline: true,
      locale: Spanish,
      defaultDate: this.inputTarget.value || new Date(),
      minDate: "today",
      dateFormat: "Y-m-d",
      disableMobile: true,
      clickOpens: false,
      allowInput: false,
      monthSelectorType: "static",
      onChange: this.onChange.bind(this),
      onReady: () => {
        this.updateLabel(this.inputTarget.value)
      }
    })

    this.boundOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.boundOutsideClick)
  }

  disconnect() {
    if (this.flatpickr) this.flatpickr.destroy()
    if (this.boundOutsideClick) {
      document.removeEventListener("click", this.boundOutsideClick)
    }
  }

  toggle(event) {
    event.preventDefault()

    if (this.panelTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.cardTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.cardTarget.setAttribute("aria-expanded", "false")
  }

  onChange(selectedDates, dateStr) {
    this.inputTarget.value = dateStr
    this.updateLabel(dateStr)

    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))

    this.close()
  }

  updateLabel(value) {
    if (!value) return

    const parts = value.split("-")
    if (parts.length !== 3) {
      this.labelTarget.textContent = value
      return
    }

    const [year, month, day] = parts
    this.labelTarget.textContent = `${day}/${month}/${year}`
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}