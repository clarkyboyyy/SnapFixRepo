document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("signupForm");
    const password = document.getElementById("password");
    const confirmPassword = document.getElementById("confirmPassword");

    form.addEventListener("submit", function(event) {
        // Clear previous custom validity
        confirmPassword.setCustomValidity("");

        // Check if passwords match
        if (password.value !== confirmPassword.value) {
            // Prevent form submission
            event.preventDefault();
            
            // Set error and show built-in browser validation popup
            confirmPassword.setCustomValidity("Passwords do not match. Please try again.");
            confirmPassword.reportValidity();
        } else {
            // Optional: Handle the successful form submission (e.g., API call)
            event.preventDefault(); // Remove this line if you want the form to actually submit/reload
            console.log("Form successfully validated! Data ready to be sent.");
            alert("Account creation simulated successfully!");
        }
    });

    // Clear the error message when the user starts typing again
    confirmPassword.addEventListener("input", () => {
        confirmPassword.setCustomValidity("");
    });
    password.addEventListener("input", () => {
        confirmPassword.setCustomValidity("");
    });
});