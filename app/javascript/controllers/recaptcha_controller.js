// app/javascript/controllers/recaptcha_controller.js
import { Controller } from "@hotwired/stimulus"

// Un solo hook: submit->recaptcha#onSubmit
// Candado anti doble envío con dataset, funciona incluso si hay dos instancias.
export default class extends Controller {
  static values = { siteKey: String }

  async onSubmit(event) {
    // ⛔ Si ya estamos enviando, NO vuelvas a enviar
    if (this.element.dataset.recaptchaLock === "1") {
      event.preventDefault()
      return
    }

    event.preventDefault()
    this.element.dataset.recaptchaLock = "1" // 🔒 activa candado
    this.toggleSubmitDisabled(true)

    try {
      const token = await this.getTokenWithTimeout(5000)
      if (!token) {
        console.warn("reCAPTCHA: no se obtuvo token")
        this.toggleSubmitDisabled(false)
        this.element.dataset.recaptchaLock = "" // 🔓 libera candado para reintentar
        return
      }

      // Inyecta/actualiza el hidden
      let input = this.element.querySelector('input[name="recaptcha_token"]')
      if (!input) {
        input = document.createElement("input")
        input.type = "hidden"
        input.name = "recaptcha_token"
        this.element.appendChild(input)
      }
      input.value = token

      // Submit nativo: NO dispara otro evento submit (no re-entra)
      this.element.submit()
      // no limpies el candado aquí: ya vamos a navegar
    } catch (e) {
      console.error("reCAPTCHA error:", e)
      this.toggleSubmitDisabled(false)
      this.element.dataset.recaptchaLock = "" // 🔓 libera para reintento si falló
    }
  }

  toggleSubmitDisabled(disabled) {
    const btn = this.element.querySelector('[type="submit"]')
    if (!btn) return
    btn.disabled = disabled
    if (disabled) {
      btn.dataset.originalText = btn.innerHTML
      btn.innerHTML = "Enviando..."
    } else {
      if (btn.dataset.originalText) btn.innerHTML = btn.dataset.originalText
    }
  }

  async getTokenWithTimeout(ms) {
    const ready = await this.ensureRecaptchaReady(ms)
    if (!ready) return null
    try {
      return await grecaptcha.execute(this.siteKeyValue, { action: "appointment_create" })
    } catch {
      return null
    }
  }

  ensureRecaptchaReady(timeoutMs = 5000) {
    return new Promise((resolve) => {
      const start = Date.now()
      const tick = () => {
        if (window.grecaptcha && grecaptcha.execute) return resolve(true)
        if (Date.now() - start >= timeoutMs) return resolve(false)
        setTimeout(tick, 50)
      }
      tick()
    })
  }
}
