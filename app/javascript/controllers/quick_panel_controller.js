import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay", "toggle"]

  connect() {
    this.close()
    this.handleClickOutside = this.handleClickOutside.bind(this)
    this.handleEscape = this.handleEscape.bind(this)

    document.addEventListener("click", this.handleClickOutside)
    document.addEventListener("keydown", this.handleEscape)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    document.removeEventListener("keydown", this.handleEscape)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.panelTarget.classList.remove("quick-panel-enter")
    this.panelTarget.classList.add("quick-panel-open")
    this.overlayTarget.classList.remove("hidden")
    this.toggleTargets.forEach(btn => btn.setAttribute("aria-expanded", "true"))
  }

  close() {
    if (!this.hasPanelTarget || !this.hasOverlayTarget) return

    this.panelTarget.classList.remove("quick-panel-open")
    this.panelTarget.classList.add("quick-panel-enter")
    this.overlayTarget.classList.add("hidden")
    this.toggleTargets.forEach(btn => btn.setAttribute("aria-expanded", "false"))
  }

  isOpen() {
    return this.panelTarget.classList.contains("quick-panel-open")
  }

  closeFromOverlay(event) {
    event.preventDefault()
    this.close()
  }

  handleClickOutside(event) {
    if (!this.hasPanelTarget) return
    if (!this.isOpen()) return

    const clickedInsidePanel = this.panelTarget.contains(event.target)
    const clickedToggle = this.toggleTargets.some(btn => btn.contains(event.target))

    if (!clickedInsidePanel && !clickedToggle) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") this.close()
  }
}