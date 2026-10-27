// 1. Initialize Supabase Client (Removed /rest/v1/)
const supabaseUrl = 'https://oymklmxvcftvrinjqryx.supabase.co'; 
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im95bWtsbXh2Y2Z0dnJpbmpxcnl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwNjQ2NTMsImV4cCI6MjEwODY0MDY1M30.-5CEbJ1k8bRiWzEQCfGb8ANzTfwF3SccbbQZNau3kBc'; 
const supabaseClient = supabase.createClient(supabaseUrl, supabaseKey);

document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("signupForm");
    const password = document.getElementById("password");
    const confirmPassword = document.getElementById("confirmPassword");
    
    const fullName = document.getElementById("fullName"); 
    const email = document.getElementById("email");

    form.addEventListener("submit", async function(event) {
        confirmPassword.setCustomValidity("");

        if (password.value !== confirmPassword.value) {
            event.preventDefault();
            
            confirmPassword.setCustomValidity("Passwords do not match. Please try again.");
            confirmPassword.reportValidity();
        } else {
            event.preventDefault(); 
            
            const nameValue = fullName.value.trim();
            const emailValue = email.value.trim();
            const passwordValue = password.value;

            if (!nameValue || !emailValue || !passwordValue) {
                alert("Please fill in all fields.");
                return;
            }

            // Call Supabase auth.signUp using supabaseClient!
            const { data, error } = await supabaseClient.auth.signUp({
                email: emailValue,
                password: passwordValue,
                options: {
                    data: {
                        full_name: nameValue,
                    },
                },
            });

            if (error) {
                alert(`Error: ${error.message}`);
                console.error("Sign up error:", error);
            } else {
                alert("Account created successfully!");
                console.log("User data:", data);
            }
        }
    });

    confirmPassword.addEventListener("input", () => {
        confirmPassword.setCustomValidity("");
    });
    password.addEventListener("input", () => {
        confirmPassword.setCustomValidity("");
    });
});