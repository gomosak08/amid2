import { Turbo } from "@hotwired/turbo-rails";
import { Application } from "@hotwired/stimulus";
import RecaptchaController from "./controllers/recaptcha_controller";

import Rails from "@rails/ujs";
import * as ActiveStorage from "@rails/activestorage";

<<<<<<< HEAD
import "@hotwired/turbo-rails";
//import "./app/assets/stylesheets/application.tailwind.css";
//import "../../js/appointments_controller";
//import "../../js/validation";
//import "./controllers/auto_submit";
//import "./controllers/appointments";
import "./controllers/appointment.js";
//enableAutoSubmit("available_times_form", "auto-submit");
import * as ActiveStorage from "@rails/activestorage"
Rails.start();
//Turbolinks.start()
ActiveStorage.start()
import flatpickr from "flatpickr";
import { Spanish } from "flatpickr/dist/l10n/es.js";

document.addEventListener("turbo:load", () => {
  flatpickr(".datepicker", {
    locale: Spanish,
    dateFormat: "Y-m-d",
  });
});


// app/javascript/application.js
import { Application } from "@hotwired/stimulus"
import ToggleDescriptionController from "./controllers/toggle_description_controller"


window.Stimulus = Application.start()
Stimulus.register("toggle-description", ToggleDescriptionController)
=======
Rails.start();
Turbo.start();
ActiveStorage.start();

const application = Application.start();
application.register("recaptcha", RecaptchaController);
>>>>>>> 60c8d19144261bbab1690c0d31987c5de2bf2991
