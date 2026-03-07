import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["description"]

  toggle() {
    if (!this.hasDescriptionTarget) return
    this.descriptionTarget.classList.toggle("is-open")
  }
}