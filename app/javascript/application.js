// Core Rails and Stimulus setup
// import { Turbo } from "@hotwired/turbo-rails";
import { Application } from "@hotwired/stimulus";
//import Rails from "@rails/ujs";
import * as ActiveStorage from "@rails/activestorage";

// Start Rails and ActiveStorage
Rails.start();
ActiveStorage.start();
import * as Turbo from "@hotwired/turbo-rails"
// Stimulus controllers
import ToggleDescriptionController from "./controllers/toggle_description_controller";
import RecaptchaController from "./controllers/recaptcha_controller";
import "./controllers/appointment.js";

// Initialize Stimulus
window.Stimulus = Application.start();
Stimulus.register("toggle-description", ToggleDescriptionController);
Stimulus.register("recaptcha", RecaptchaController);

// Flatpickr datepicker with Spanish locale
import flatpickr from "flatpickr";
import { Spanish } from "flatpickr/dist/l10n/es.js";

document.addEventListener("turbo:load", () => {
  flatpickr(".datepicker", {
    locale: Spanish,
    dateFormat: "Y-m-d",
  });
});
