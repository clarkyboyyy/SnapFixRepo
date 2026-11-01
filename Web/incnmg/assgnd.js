
document.addEventListener("DOMContentLoaded", function () {
    const storageKey = "snapfixTickets";
    const apiUrl = "http://localhost:5141/api/tickets";

    const tbody = document.getElementById("assigned-ticket-body");
    const countElement = document.getElementById("assigned-ticket-count");
    const incomingCount = document.getElementById("incoming-ticket-count");

    const sampleTickets = [
        {
            id: "SF-1024",
            issue: "Road Damage",
            location: "BGC, Taguig",
            status: "pending",
            date: "October 24, 2026"
        },
        {
            id: "SF-1025",
            issue: "Broken Streetlight",
            location: "Makati City",
            status: "ongoing",
            department: "Street Lighting",
            date: "October 24, 2026"
        },
        {
            id: "SF-1026",
            issue: "Garbage Collection",
            location: "Pasig City",
            status: "pending",
            date: "October 25, 2026"
        }
    ];

    let allTickets = [];

    function getSavedTickets() {
        try {
            return JSON.parse(localStorage.getItem(storageKey)) || {};
        } catch (error) {
            console.error("Could not read saved tickets:", error);
            return {};
        }
    }

    function normalizeStatus(status) {
        const value = String(status || "pending")
            .toLowerCase()
            .replace(/\s+/g, "-");

        if (
            value === "assigned" ||
            value === "in-progress"
        ) {
            return "ongoing";
        }

        return value === "ongoing" ? "ongoing" : "pending";
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
            ticket.date ||
            ticket.dateSubmitted ||
            ticket.DateSubmitted ||
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

        return {
            ...ticket,
            id,
            issue: ticket.issue || ticket.title || ticket.Title || "No Title",
            description: ticket.description || ticket.Description || "",
            location: ticket.location || ticket.Location || "Unknown",
            status: normalizeStatus(ticket.status || ticket.Status),
            date,
            department: ticket.department || ticket.Department || ""
        };
    }

    function getTicketsWithSavedChanges(sourceTickets) {
        const savedTickets = getSavedTickets();
        const ticketMap = new Map();

        sourceTickets.forEach(function (sourceTicket) {
            const ticket = normalizeTicket(sourceTicket);

            if (ticket.id) {
                ticketMap.set(ticket.id, ticket);
            }
        });

        Object.entries(savedTickets).forEach(function ([savedId, savedTicket]) {
            const ticket = normalizeTicket(savedTicket, savedId);
            const existingTicket = ticketMap.get(ticket.id) || {};

            ticketMap.set(ticket.id, {
                ...existingTicket,
                ...ticket,
                id: ticket.id,
                status: normalizeStatus(savedTicket.status || ticket.status)
            });
        });

        return Array.from(ticketMap.values());
    }

    function renderTickets() {
        const assignedTickets = allTickets.filter(function (ticket) {
            return ticket.status === "ongoing" &&
                typeof ticket.department === "string" &&
                ticket.department.trim() !== "";
        });

        const pendingCount = allTickets.filter(function (ticket) {
            return ticket.status === "pending";
        }).length;

        incomingCount.textContent = pendingCount;

        tbody.replaceChildren();

        assignedTickets.forEach(function (ticket) {
            const row = document.createElement("tr");

            const idCell = document.createElement("td");
            idCell.textContent = "#" + ticket.id;

            const issueCell = document.createElement("td");
            issueCell.textContent =
                ticket.issue + " — " + ticket.location;

            const statusCell = document.createElement("td");
            const statusBadge = document.createElement("span");

            statusBadge.className = "status-badge ongoing";
            statusBadge.textContent = "Ongoing";

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

            allTickets = getTicketsWithSavedChanges(
                Array.isArray(data) && data.length > 0
                    ? data
                    : sampleTickets
            );

        } catch (error) {
            console.error("Could not load API tickets:", error);

            allTickets = getTicketsWithSavedChanges(sampleTickets);
        }

        renderTickets();
    }

    loadTickets();

    window.addEventListener("pageshow", loadTickets);

    window.addEventListener("storage", function (event) {
        if (event.key === storageKey) {
            loadTickets();
        }
    });
});
