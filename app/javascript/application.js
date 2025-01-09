import Rails from "@rails/ujs";

import "@hotwired/turbo-rails";
//import "./app/assets/stylesheets/application.tailwind.css";
//import "../../js/appointments_controller";
//import "../../js/validation";
//import "./controllers/auto_submit";
//import "./controllers/appointments";
import "./controllers/appointment.js";
//enableAutoSubmit("available_times_form", "auto-submit");
Rails.start();
Turbolinks.start()
ActiveStorage.start()