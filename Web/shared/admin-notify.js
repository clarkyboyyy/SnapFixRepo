// Top banner when a citizen files a new report from the mobile app.
(function () {
    const API = "http://localhost:5141";
    const SEEN_KEY = "snapfixAdminSeenTickets";
    const POLL_MS = 20000;

    const SELF = new URL(document.currentScript.src);
    const REVIEW_PAGE = new URL("../review/rev.html", SELF).href;

    const seen = new Set(JSON.parse(localStorage.getItem(SEEN_KEY) || "[]"));
    let seeded = localStorage.getItem(SEEN_KEY) !== null;

    function save() {
        localStorage.setItem(SEEN_KEY, JSON.stringify([...seen].slice(-500)));
    }

    function banner(ticket) {
        document.getElementById("admin-notify-banner")?.remove();

        const el = document.createElement("div");
        el.id = "admin-notify-banner";
        el.style.cssText =
            "position:fixed;top:16px;left:50%;transform:translateX(-50%);" +
            "z-index:9999;background:#fff;border-left:4px solid #EC2D6E;" +
            "border-radius:10px;box-shadow:0 8px 24px rgba(0,0,0,.18);" +
            "padding:14px 18px;display:flex;gap:14px;align-items:center;" +
            "max-width:520px;font:14px/1.45 system-ui,sans-serif";

        const text = document.createElement("div");
        const strong = document.createElement("strong");
        strong.textContent = "New report received";
        text.append(strong, document.createElement("br"));
        text.append(
            `${ticket.title || "Untitled"} — ${ticket.location || "Unknown location"}`
        );

        const view = document.createElement("a");
        view.href = `${REVIEW_PAGE}?id=${encodeURIComponent(ticket.id)}`;
        view.textContent = "View";
        view.style.cssText = "color:#EC2D6E;font-weight:600;text-decoration:none";

        const dismiss = document.createElement("button");
        dismiss.type = "button";
        dismiss.textContent = "Dismiss";
        dismiss.style.cssText =
            "border:0;background:none;color:#777;cursor:pointer;font:inherit";
        dismiss.onclick = () => el.remove();

        el.append(text, view, dismiss);
        document.body.appendChild(el);
        setTimeout(() => el.remove(), 12000);
    }

    async function poll() {
        try {
            const res = await fetch(`${API}/api/tickets`);
            if (!res.ok) return;
            const tickets = await res.json();
            if (!Array.isArray(tickets)) return;

            const fresh = [];
            for (const t of tickets) {
                const id = String(t.id ?? t.Id ?? "");
                if (!id) continue;
                if (!seen.has(id)) {
                    seen.add(id);
                    if (seeded) fresh.push(t);
                }
            }
            save();

            // First successful poll is the baseline: never pop for old tickets.
            if (!seeded) {
                seeded = true;
                return;
            }

            if (fresh.length === 1) {
                banner(fresh[0]);
            } else if (fresh.length > 1) {
                banner({ title: `${fresh.length} new reports`, location: "" });
            }
        } catch (_) {
            // Backend down; try again on the next tick.
        }
    }

    poll();
    setInterval(poll, POLL_MS);
})();
