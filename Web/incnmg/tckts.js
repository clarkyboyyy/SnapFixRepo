document.addEventListener("DOMContentLoaded", function () {
    const storageKey = "snapfixTickets";
    const apiUrl = "http://localhost:5141/api/tickets";

    const tbody = document.getElementById("ticketTable");
    const searchInput = document.getElementById("ticket-search");
    const countElement = document.getElementById("ticket-result-count");
    const sidebarCount = document.getElementById("incoming-ticket-count");

    let allTickets = [];

    function getSavedTickets() {
        try {
            return JSON.parse(localStorage.getItem(storageKey)) || {};
        } catch (error) {
            console.error("Could not read saved tickets:", error);
            return {};
        }
    }

    // The API, the dashboard, and the Flutter app all use these three values.
    function normalizeStatus(value) {
        const status = String(value || "")
            .trim()
            .toLowerCase()
            .replace(/[_-]/g, " ")
            .replace(/\s+/g, " ");

        if (
            status === "ongoing" ||
            status === "in progress" ||
            status === "inprogress" ||
            status === "assigned" ||
            status === "working"
        ) {
            return "In Progress";
        }

        if (
            status === "resolved" ||
            status === "closed" ||
            status === "completed" ||
            status === "done"
        ) {
            return "Resolved";
        }

        return "Submitted";
    }

    function badgeClass(status) {
        if (status === "In Progress") return "in-progress";
        if (status === "Resolved") return "resolved";
        return "pending";
    }

    function normalizeTicket(ticket, fallbackId = "") {
        const id = String(
            ticket.id ??
            ticket.Id ??
            ticket.ticketId ??
            ticket.TicketId ??
            fallbackId
        );

        const rawDate =
            ticket.dateSubmitted ||
            ticket.DateSubmitted ||
            ticket.date ||
            ticket.date_submitted;

        let date = "Date unavailable";

        if (rawDate) {
            const parsedDate = new Date(rawDate);
            date = isNaN(parsedDate.getTime())
                ? rawDate
                : parsedDate.toLocaleDateString();
        }

        const progressValue = Number(ticket.progress);

        return {
            ...ticket,
            id,
            title: ticket.title || ticket.Title || ticket.issue || "No Title",
            description: ticket.description || ticket.Description || "",
            location: ticket.location || ticket.Location || "Unknown",
            status: normalizeStatus(ticket.status || ticket.Status),
            date,
            department:
                ticket.assignedDepartment ||
                ticket.assigned_department ||
                ticket.department ||
                "",
            progress: Number.isFinite(progressValue) ? progressValue : 0
        };
    }

    function renderTickets() {
        const searchText = searchInput.value.trim().toLowerCase();

        const incomingTickets = allTickets.filter(function (ticket) {
            return ticket.status === "Submitted";
        });

        const visibleTickets = incomingTickets.filter(function (ticket) {
            const id = ticket.id.toLowerCase();
            const title = ticket.title.toLowerCase();
            const loc = ticket.location.toLowerCase();

            return (
                id.includes(searchText) ||
                title.includes(searchText) ||
                loc.includes(searchText)
            );
        });

        tbody.replaceChildren();

        visibleTickets.forEach(function (ticket) {
            const row = document.createElement("tr");

            const idCell = document.createElement("td");
            idCell.textContent = "#" + ticket.id;

            const issueCell = document.createElement("td");
            const issueTitle = document.createElement("strong");
            issueTitle.textContent = ticket.title;

            const description = document.createElement("br");
            const descriptionText = document.createElement("small");
            descriptionText.textContent = ticket.description;

            issueCell.append(issueTitle, description, descriptionText);

            const locationCell = document.createElement("td");
            locationCell.textContent = ticket.location;

            const dateCell = document.createElement("td");
            const rawDate = ticket.dateSubmitted || ticket.date;
            const parsedDate = new Date(rawDate);
            dateCell.textContent = isNaN(parsedDate.getTime())
                ? (rawDate || "Date unavailable")
                : parsedDate.toLocaleDateString() + " " +
                  parsedDate.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

            const statusCell = document.createElement("td");
            const statusBadge = document.createElement("span");

            statusBadge.className = `status-badge ${badgeClass(ticket.status)}`;
            statusBadge.textContent = ticket.status;
            statusCell.appendChild(statusBadge);

            const actionCell = document.createElement("td");
            const reviewLink = document.createElement("a");

            reviewLink.href =
                "../review/rev.html?id=" + encodeURIComponent(ticket.id);
            reviewLink.className = "review-button";
            reviewLink.textContent = "Review";

            actionCell.appendChild(reviewLink);

            row.append(
                idCell,
                issueCell,
                locationCell,
                dateCell,
                statusCell,
                actionCell
            );

            tbody.appendChild(row);
        });

        if (visibleTickets.length === 0) {
            const row = document.createElement("tr");
            const cell = document.createElement("td");

            cell.colSpan = 6;
            cell.textContent = "No submitted tickets found.";
            cell.style.textAlign = "center";
            cell.style.padding = "24px";

            row.appendChild(cell);
            tbody.appendChild(row);
        }

        countElement.textContent =
            `Showing ${visibleTickets.length} of ${incomingTickets.length} submitted tickets`;

        sidebarCount.textContent = incomingTickets.length;
    }

    async function loadTickets() {
        try {
            const response = await fetch(apiUrl);

            if (!response.ok) {
                throw new Error(`API returned status ${response.status}`);
            }

            const tickets = await response.json();
            allTickets = (Array.isArray(tickets) ? tickets : []).map(
                (ticket) => normalizeTicket(ticket)
            );

            // Refreshes the offline cache written by the review page too.
            try {
                const cache = {};
                allTickets.forEach((ticket) => {
                    cache[ticket.id] = ticket;
                });
                localStorage.setItem(storageKey, JSON.stringify(cache));
            } catch (error) {
                console.warn("Could not cache tickets locally:", error);
            }
        } catch (error) {
            console.error("Could not load API tickets:", error);

            const cached = getSavedTickets();
            allTickets = Object.entries(cached).map(([id, ticket]) =>
                normalizeTicket(ticket, id)
            );
        }

        renderTickets();
    }

    searchInput.addEventListener("input", renderTickets);

    window.addEventListener("pageshow", loadTickets);

    // New submissions arrive from the citizen app without a page reload.
    setInterval(loadTickets, 10000);

    loadTickets();
});
