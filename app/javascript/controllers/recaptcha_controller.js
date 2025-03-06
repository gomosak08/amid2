import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["recaptchaToken"];

  connect() {
    console.log("✅ reCAPTCHA Stimulus Controller Loaded");
  }

  submit(event) {
    event.preventDefault(); // Stop form submission

    console.log("🛠 reCAPTCHA: Executing grecaptcha...");

    const siteKey = this.element.dataset.recaptchaSiteKey; // Get site key

    if (!siteKey) {
      console.error("❌ reCAPTCHA Error: Site key is missing!");
      return;
    }

    grecaptcha.ready(() => {
      grecaptcha.execute(siteKey, { action: "submit" })
        .then((token) => {
          console.log("✅ reCAPTCHA Token Generated:", token);
          this.recaptchaTokenTarget.value = token;

          setTimeout(() => {
            this.element.submit(); // ✅ Submit the form after token is set
          }, 500);
        })
        .catch((error) => {
          console.error("❌ reCAPTCHA Execution Error:", error);
        });
    });
  }
}
