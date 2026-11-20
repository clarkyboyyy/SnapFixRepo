
document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');

    const createdEmail = new URLSearchParams(window.location.search).get('email');

    if (createdEmail) {
        document.getElementById('email').value = createdEmail;
    }

    // Show / Hide Password
    document.querySelectorAll('.toggle-password').forEach((button) => {
        button.addEventListener('click', () => {
            const input = document.getElementById(button.dataset.target);

            if (!input) return;

            const show = input.type === 'password';

            input.type = show ? 'text' : 'password';
            button.textContent = show ? 'Hide' : 'Show';
            button.setAttribute('aria-pressed', String(show));
            button.setAttribute('aria-label', show ? 'Hide password' : 'Show password');

            input.focus();
        });
    });

    if (loginForm) {
        loginForm.addEventListener('submit', async function(event) {
            event.preventDefault();

            const email = document.getElementById('email').value.trim();
            const password = document.getElementById('password').value;

            await loginUser(email, password);
        });
    }
});


async function loginUser(email, password) {
    try {
        const response = await fetch('http://localhost:5141/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email: email, password: password })
        });

        const data = await response.json();

        if (response.ok) {
            console.log("Logged in successfully!", data.token);

            localStorage.setItem("jwtToken", data.token);

            localStorage.setItem("snapFixStaff", JSON.stringify({
                id: data.id,
                fullName: data.fullName,
                email: data.email,
                role: data.role
            }));

            window.location.href = "../incnmg/tckts.html";

        } else {
            console.error("Login failed:", data.message);
            alert("Login failed: " + data.message);
        }

    } catch (error) {
        console.error("Connection error:", error);
        alert("Cannot connect to server. Is your C# back-end running?");
    }
}
