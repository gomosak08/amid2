document.addEventListener("DOMContentLoaded", () => {
    const form = document.querySelector("#availability_form");
  
    if (form) {
      form.addEventListener("change", (event) => {
        if (event.target.name === "doctor_id" || event.target.name === "appointment_date") {
          form.requestSubmit(); // Triggers a Turbo frame reload
        }
      });
    }
  });