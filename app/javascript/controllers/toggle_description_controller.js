// app/javascript/controllers/toggle_description_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["description"]

  toggle() {
    this.descriptionTarget.classList.toggle("hidden")
  }
}
