(function () {
    const storageKey = "snapfixStaff";

    function readProfile() {
        try {
            return JSON.parse(localStorage.getItem(storageKey)) || null;
        } catch (error) {
            return null;
        }
    }

    function initialsFor(name) {
        const source = String(name || "").trim();

        if (!source) return "SF";

        const words = source.split(/\s+/).filter(Boolean);

        if (words.length >= 2) {
            return (words[0][0] + words[words.length - 1][0]).toUpperCase();
        }

        return source.slice(0, 2).toUpperCase();
    }

    function hydrate() {
        const profile = readProfile();
        const fullName = profile && profile.fullName ? profile.fullName.trim() : "";
        const email = profile && profile.email ? profile.email.trim() : "";

        const displayName = fullName || email || "Staff account";
        const detail = fullName && email ? email : (email ? "Signed in" : "Not signed in");

        document.querySelectorAll("[data-profile-name]").forEach((element) => {
            element.textContent = displayName;
        });

        document.querySelectorAll("[data-profile-detail]").forEach((element) => {
            element.textContent = detail;
        });

        document.querySelectorAll("[data-profile-avatar]").forEach((element) => {
            element.textContent = initialsFor(fullName || email);
        });
    }

    function bindSignOut() {
        document.querySelectorAll("[data-sign-out]").forEach((button) => {
            button.addEventListener("click", () => {
                localStorage.removeItem("jwtToken");
                localStorage.removeItem("snapfixStaff");
                window.location.href = "../loginui/loginUI.html";
            });
        });
    }

    function init() {
        hydrate();
        bindSignOut();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
