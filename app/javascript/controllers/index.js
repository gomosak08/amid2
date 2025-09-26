import { Application } from "@hotwired/stimulus"
const application = Application.start()

// registra los controllers que quieras
import DatePickerController from "./date_picker_controller"
application.register("date-picker", DatePickerController)

// (hello_controller viene por defecto; puedes dejarlo o quitarlo)
