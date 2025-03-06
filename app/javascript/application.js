import { Turbo } from "@hotwired/turbo-rails";
import { Application } from "@hotwired/stimulus";
import RecaptchaController from "./controllers/recaptcha_controller";

import Rails from "@rails/ujs";
import * as ActiveStorage from "@rails/activestorage";

Rails.start();
Turbo.start();
ActiveStorage.start();

const application = Application.start();
application.register("recaptcha", RecaptchaController);
