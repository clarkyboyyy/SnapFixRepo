
const apiUrl = "http://localhost:5141/api/auth/register";

document.addEventListener("DOMContentLoaded", () => {
    const createForm = document.getElementById("createForm");
    const fullNameInput = document.getElementById("fullName");
    const emailInput = document.getElementById("email");

    // Allow letters and spaces only while typing.
    if (fullNameInput) {
        fullNameInput.addEventListener("input", () => {
            fullNameInput.value = fullNameInput.value.replace(/[^A-Za-z ]/g, "");           

   if (emailInput) {
    emailInput.addEventListener("input", () => {
        emailInput.value = emailInput.value.replace(
            /[^A-Za-z0-9._%+-@]/g,
            ""
        );
    });
}
        });
    }

    document.querySelectorAll(".toggle-password").forEach((button) => {
        button.addEventListener("click", () => {
            const input = document.getElementById(button.dataset.target);

            if (!input) return;

            const show = input.type === "password";

            input.type = show ? "text" : "password";
            button.textContent = show ? "Hide" : "Show";
            button.setAttribute("aria-pressed", String(show));
            button.setAttribute("aria-label", show ? "Hide password" : "Show password");
            input.focus();
        });
    });

    if (createForm) {
        createForm.addEventListener("submit", async function (event) {
            event.preventDefault();

            const fullName = fullNameInput.value.trim();
            const email = document.getElementById("email").value.trim();
            const password = document.getElementById("password").value;
            const confirmPassword = document.getElementById("confirmPassword").value;

            if (!fullName) {
                showMessage("Full name is required.", "error");
                return;
            }

            if (!/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(email)) {
              showMessage("Please enter a valid email address.", "error");
              return;
            }

            // Final validation before sending data to the server.
            if (!/^[A-Za-z]+(?: [A-Za-z]+)*$/.test(fullName)) {
                showMessage("Full name must contain letters and spaces only.", "error");
                return;
            }

            if (password !== confirmPassword) {
                showMessage("Passwords do not match.", "error");
                return;
            }

            if (!/^(?=.*[A-Z])(?=.*\d).{8,}$/.test(password)) {
                showMessage("Password must be at least 8 characters and include one uppercase letter and one number.", "error");
                return;
            }

            await createAccount({ fullName, email, password });
        });
    }
});

async function createAccount(account) {
    const button = document.getElementById("create-button");

    button.disabled = true;
    showMessage("Creating your account…", "info");

    try {
        const response = await fetch(apiUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(account)
        });

        const data = await response.json().catch(() => ({}));

        if (response.status === 201) {
            showMessage("Account created. Taking you to the log in page…", "success");

            setTimeout(() => {
                window.location.href = "loginUI.html?email=" + encodeURIComponent(data.email || account.email);
            }, 1200);

            return;
        }

        if (response.status === 409) {
            showMessage(data.message || "An account with this email already exists.", "error");
            return;
        }

        showMessage(firstValidationError(data) || data.message || "Could not create the account. Try again.", "error");

    } catch (error) {
        console.error("Connection error:", error);
        showMessage("Cannot connect to the server. Is your C# back-end running?", "error");

    } finally {
        button.disabled = false;
    }
}

function firstValidationError(data) {
    if (!data || !data.errors) return "";

    const fieldErrors = Object.values(data.errors);
    return fieldErrors.length > 0 && fieldErrors[0].length > 0 ? fieldErrors[0][0] : "";
}

function showMessage(text, type) {
    const message = document.getElementById("form-message");

    message.textContent = text;
    message.className = "form-message is-visible is-" + type;
}
