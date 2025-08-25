import { Application } from "@hotwired/stimulus"

export const application = Application.start()

// Opcional para debug
application.debug = false

// Útil si quieres acceder en consola
window.Stimulus = application
