document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("signupForm");
    const password = document.getElementById("password");
    const confirmPassword = document.getElementById("confirmPassword");
    const fullName = document.getElementById("fullName"); 
    const email = document.getElementById("email");

    form.addEventListener("submit", async function(event) {
        event.preventDefault(); // Prevent form from refreshing the page
        confirmPassword.setCustomValidity("");

        // 1. Password validation
        if (password.value !== confirmPassword.value) {
            confirmPassword.setCustomValidity("Passwords do not match. Please try again.");
            confirmPassword.reportValidity();
            return;
        }
        
        const nameValue = fullName.value.trim();
        const emailValue = email.value.trim();
        const passwordValue = password.value;

        if (!nameValue || !emailValue || !passwordValue) {
            alert("Please fill in all fields.");
            return;
        }

        // 2. Send data to the C# Backend via Fetch
        try {
            const response = await fetch("http://localhost:5141/api/auth/register", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    email: emailValue,
                    password: passwordValue
                })
            });

            const data = await response.json();

            // 3. Handle the response from C#
            if (response.ok) {
                alert(data.message); // Should trigger "Account created successfully!"
                console.log("Success:", data);
                
                // Optional: redirect to login page automatically
                window.location.href = "../loginui/loginUI.html"; 
            } else {
                // If email already exists or validation fails
                alert(`Error: ${data.message}`); 
            }
        } catch (error) {
            console.error("Sign up error:", error);
            alert("Failed to connect to the server. Is your C# backend running?");
        }
    });

    // Clear validation warnings when user starts typing again
    confirmPassword.addEventListener("input", () => {
        confirmPassword.setCustomValidity("");
    });
    password.addEventListener("input", () => {
        confirmPassword.setCustomValidity("");
    });
});