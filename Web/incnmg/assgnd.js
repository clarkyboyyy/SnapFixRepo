
document.addEventListener("DOMContentLoaded", function () {
    const storageKey = "snapfixTickets";
    const tbody = document.getElementById("assigned-ticket-body");
    const count = document.getElementById("assigned-ticket-count");

    const sampleTickets = {
        "SF-1024": {
            issue: "Road Damage",
            location: "BGC, Taguig",
            priority: "high",
            status: "pending",
            date: "October 24, 2026"
        },
        "SF-1025": {
            issue: "Broken Streetlight",
            location: "Makati City",
            priority: "medium",
            status: "in-progress",
            date: "October 24, 2026"
        },
        "SF-1026": {
            issue: "Garbage Collection",
            location: "Pasig City",
            priority: "low",
            status: "pending",
            date: "October 25, 2026"
        }
    };

    function renderTickets() {
        let savedTickets = {};

        try {
            savedTickets = JSON.parse(
                localStorage.getItem(storageKey)
            ) || {};
        } catch (error) {
            console.error("Could not load saved tickets:", error);
        }

        const tickets = Object.keys(sampleTickets).map(function (id) {
            return {
                id,
                ...sampleTickets[id],
                ...(savedTickets[id] || {})
            };
        });

        const assignedTickets = tickets.filter(function (ticket) {
            return ticket.status === "assigned" &&
                typeof ticket.department === "string" &&
                ticket.department.trim() !== "";
        });

        tbody.replaceChildren();

        assignedTickets.forEach(function (ticket) {
            const row = document.createElement("tr");

            const cells = [
                "#" + ticket.id,
                ticket.issue + " — " + ticket.location,
                ticket.priority.charAt(0).toUpperCase() +
                    ticket.priority.slice(1),
                ticket.status === "in-progress" ? "In Progress" :
                    ticket.status.charAt(0).toUpperCase() +
                    ticket.status.slice(1),
                ticket.department,
                ticket.date
            ];

            cells.forEach(function (value, index) {
                const cell = document.createElement("td");

                if (index === 2) {
                    const badge = document.createElement("span");
                    badge.className = "priority-badge " + ticket.priority;
                    badge.textContent = value;
                    cell.appendChild(badge);
                } else if (index === 3) {
                    const badge = document.createElement("span");
                    badge.className = "status-badge " + ticket.status;
                    badge.textContent = value;
                    cell.appendChild(badge);
                } else {
                    cell.textContent = value;
                }

                row.appendChild(cell);
            });

            const actionCell = document.createElement("td");
            const reviewLink = document.createElement("a");
            reviewLink.href = "../review/rev.html?id=" +    
              encodeURIComponent(ticket.id) +
                 "&from=assigned";
            reviewLink.className = "review-button";
            reviewLink.textContent = "Review";
            actionCell.appendChild(reviewLink);
            row.appendChild(actionCell);

            tbody.appendChild(row);
        });

        if (assignedTickets.length === 0) {
            const row = document.createElement("tr");
            const cell = document.createElement("td");

            cell.colSpan = 7;
            cell.textContent = "No assigned tickets found.";
            cell.style.textAlign = "center";
            cell.style.padding = "24px";

            row.appendChild(cell);
            tbody.appendChild(row);
        }

        count.textContent =
            "Showing " + assignedTickets.length + " assigned ticket(s)";
    }

    renderTickets();

    window.addEventListener("pageshow", renderTickets);
    window.addEventListener("storage", function (event) {
        if (event.key === storageKey) {
            renderTickets();
        }
    });
});
