import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["resultsSection", "notice", "submitWrapper"]

  connect() {
    console.log("availability-guard conectado")
  }

  invalidate() {
    console.log("invalidate ejecutado")

    const results =
      this.hasResultsSectionTarget
        ? this.resultsSectionTarget
        : this.element.querySelector('[data-availability-guard-target="resultsSection"]')

    const notice =
      this.hasNoticeTarget
        ? this.noticeTarget
        : this.element.querySelector('[data-availability-guard-target="notice"]')

    const submitWrapper =
      this.hasSubmitWrapperTarget
        ? this.submitWrapperTarget
        : this.element.querySelector('[data-availability-guard-target="submitWrapper"]')

    console.log({ results, notice, submitWrapper })

    if (results) {
      results.remove()
    }

    if (notice) {
      notice.classList.remove("border-amber-200", "bg-amber-50", "text-amber-800")
      notice.classList.add("border-red-200", "bg-red-50", "text-red-700")
      notice.textContent = "Cambiaste el doctor o la fecha. Debes verificar la disponibilidad nuevamente."
    }

    if (submitWrapper) {
      submitWrapper.classList.remove("hidden")
    }
  }
}