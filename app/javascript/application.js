// Hotwire
import "@hotwired/turbo-rails"

// Stimulus: usa la app ya creada
import { application } from "./controllers/application"

// Active Storage
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// Controllers propios
import RecaptchaController from "./controllers/recaptcha_controller"
import ToggleDescriptionController from "./controllers/toggle_description_controller"
// Si tienes otros como "./controllers/appointment", impórtalos aquí:
import "./controllers/appointment"

// Registra en **la misma** app
application.register("recaptcha", RecaptchaController)
application.register("toggle-description", ToggleDescriptionController)

// Flatpickr (opcional)
import flatpickr from "flatpickr"
import { Spanish } from "flatpickr/dist/l10n/es.js"

document.addEventListener("turbo:load", () => {
  flatpickr(".datepicker", { locale: Spanish, dateFormat: "Y-m-d" })
})
