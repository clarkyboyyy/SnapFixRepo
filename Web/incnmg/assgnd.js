document.addEventListener("DOMContentLoaded", function () {
    const storageKey = "snapfixTickets";
    const apiUrl = "http://localhost:5141/api/tickets";

    const tbody = document.getElementById("assigned-ticket-body");
    const countElement = document.getElementById("assigned-ticket-count");
    const incomingCount = document.getElementById("incoming-ticket-count");

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
                : parsedDate.toLocaleDateString("en-US", {
                    month: "long",
                    day: "numeric",
                    year: "numeric"
                });
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
        const assignedTickets = allTickets.filter(function (ticket) {
            return ticket.status === "In Progress" &&
                typeof ticket.department === "string" &&
                ticket.department.trim() !== "";
        });

        const pendingCount = allTickets.filter(function (ticket) {
            return ticket.status === "Submitted";
        }).length;

        incomingCount.textContent = pendingCount;

        tbody.replaceChildren();

        assignedTickets.forEach(function (ticket) {
            const row = document.createElement("tr");

            const idCell = document.createElement("td");
            idCell.textContent = "#" + ticket.id;

            const issueCell = document.createElement("td");
            issueCell.textContent = ticket.title + " — " + ticket.location;

            const statusCell = document.createElement("td");
            const statusBadge = document.createElement("span");

            statusBadge.className = `status-badge ${badgeClass(ticket.status)}`;
            statusBadge.textContent = `${ticket.status} • ${ticket.progress}%`;

            statusCell.appendChild(statusBadge);

            const departmentCell = document.createElement("td");
            departmentCell.textContent = ticket.department;

            const dateCell = document.createElement("td");
            dateCell.textContent = ticket.date;

            const actionCell = document.createElement("td");
            const reviewLink = document.createElement("a");

            reviewLink.href =
                "../review/rev.html?id=" +
                encodeURIComponent(ticket.id) +
                "&from=assigned";

            reviewLink.className = "review-button";
            reviewLink.textContent = "Review";

            actionCell.appendChild(reviewLink);

            row.append(
                idCell,
                issueCell,
                statusCell,
                departmentCell,
                dateCell,
                actionCell
            );

            tbody.appendChild(row);
        });

        if (assignedTickets.length === 0) {
            const row = document.createElement("tr");
            const cell = document.createElement("td");

            cell.colSpan = 6;
            cell.textContent = "No ongoing tickets found.";
            cell.style.textAlign = "center";
            cell.style.padding = "24px";

            row.appendChild(cell);
            tbody.appendChild(row);
        }

        countElement.textContent =
            "Showing " + assignedTickets.length + " ongoing ticket(s)";
    }

    async function loadTickets() {
        try {
            const response = await fetch(apiUrl);

            if (!response.ok) {
                throw new Error("API returned status " + response.status);
            }

            const data = await response.json();
            allTickets = (Array.isArray(data) ? data : []).map(
                (ticket) => normalizeTicket(ticket)
            );
        } catch (error) {
            console.error("Could not load API tickets:", error);

            const cached = getSavedTickets();
            allTickets = Object.entries(cached).map(([id, ticket]) =>
                normalizeTicket(ticket, id)
            );
        }

        renderTickets();
    }

    loadTickets();

    window.addEventListener("pageshow", loadTickets);

    // Admin edits in another tab or the review page show up without a reload.
    setInterval(loadTickets, 10000);
});
