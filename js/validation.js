console.log("script loaded correct for validation"); // Debug log


document.addEventListener("DOMContentLoaded", function() {
    const form = document.getElementById("appointment_form");
    const submitButton = document.getElementById("submit_button");
  
    const requiredFields = ["appointment_name", "appointment_age", "appointment_sex"];
    const optionalFields = ["email_field", "phone_field"];
  
    // Function to check if at least one of email or phone is filled
    function checkOptionalFields() {
      const emailField = document.getElementById("email_field");
      const phoneField = document.getElementById("phone_field");
  
      const emailValue = emailField ? emailField.value.trim() : "";
      const phoneValue = phoneField ? phoneField.value.trim() : "";
  
      console.log("Email:", emailValue, "Phone:", phoneValue);
      return emailValue !== "" || phoneValue !== "";
    }
  
    // Function to validate all required fields
    function validateForm() {
      console.log("Validating form...");
      let allRequiredFieldsFilled = true;
  
      requiredFields.forEach(function(fieldId) {
        const fieldElement = document.getElementById(fieldId);
        if (!fieldElement) {
          console.log(`Field with id ${fieldId} not found`);
          allRequiredFieldsFilled = false;
          return;
        }
        if (fieldElement.value.trim() === "") {
          console.log(`Field ${fieldId} is empty`);
          allRequiredFieldsFilled = false;
        }
      });
  
      // Enable the button if all required fields and at least one optional field are filled
      const optionalFieldsFilled = checkOptionalFields();
      console.log("All required fields filled:", allRequiredFieldsFilled, "Optional fields filled:", optionalFieldsFilled);
  
      submitButton.disabled = !(allRequiredFieldsFilled && optionalFieldsFilled);
      console.log("Submit button disabled:", submitButton.disabled);
    }
  
    // Add event listeners to all form fields
    requiredFields.concat(optionalFields).forEach(function(fieldId) {
      const fieldElement = document.getElementById(fieldId);
      if (fieldElement) {
        fieldElement.addEventListener("input", validateForm);
      } else {
        console.log(`Field with id ${fieldId} not found in the form`);
      }
    });
  
    // Initial validation check in case fields are pre-filled
    validateForm();
  });
  