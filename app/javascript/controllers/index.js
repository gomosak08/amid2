import { application } from "./application"

import RecaptchaController from "./recaptcha_controller"
import ToggleDescriptionController from "./toggle_description_controller"
import DatePickerController from "./date_picker_controller"
import DoctorCalendarController from "./doctor_calendar_controller"
import AvailabilityGuardController from "./availability_guard_controller"
import BlockPickerController from "./block_picker_controller"

application.register("recaptcha", RecaptchaController)
application.register("toggle-description", ToggleDescriptionController)
application.register("date-picker", DatePickerController)
application.register("doctor-calendar", DoctorCalendarController)
application.register("availability-guard", AvailabilityGuardController)
application.register("block-picker", BlockPickerController)