console.log("script loaded correct"); // Debug log

document.addEventListener("DOMContentLoaded", function() {
  console.log("DOMContentLoaded event fired"); // Confirm this event is working

  // Elements for doctor and date selection
  const doctorSelect = document.getElementById("doctor_select");
  const dateField = document.getElementById("date_field");

  // Elements for available time selection and hidden appointment time field
  const timeSelect = document.getElementById("available_time_select");
  const hiddenTimeField = document.querySelector("input[name='appointment[appointment_time]']");

  // Function to trigger form submission
  function updateAvailableTimes() {
    console.log("Form is being submitted"); // Debug log
    document.getElementById("availability_form").requestSubmit();
  }

  // Attach event listeners for doctor and date fields
  if (doctorSelect && dateField) {
    doctorSelect.addEventListener("change", () => {
      console.log("Doctor changed"); // Debug log
      updateAvailableTimes();
    });
    dateField.addEventListener("change", () => {
      console.log("Date changed"); // Debug log
      updateAvailableTimes();
    });
  }

  // Attach event listener to time select dropdown to update hidden time field
  if (timeSelect && hiddenTimeField) {
    timeSelect.addEventListener("change", function() {
      console.log("Time selected:", timeSelect.value); // Debug log for selected time
      hiddenTimeField.value = timeSelect.value; // Update hidden field with selected time
    });
  }
});
