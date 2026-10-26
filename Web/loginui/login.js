document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    
    if (loginForm) {
        loginForm.addEventListener('submit', async function(event) {
            event.preventDefault(); // Stops the page snap
            
            const email = document.getElementById('email').value;
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
            
            // Save the token for the next page
            localStorage.setItem("jwtToken", data.token);
            
            // Redirect to the tickets page
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