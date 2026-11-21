
document.addEventListener("DOMContentLoaded", function () {
    const storageKey = "snapfixTickets";
    const apiUrl = "http://localhost:5141/api/tickets";

    const tbody = document.getElementById("ticketTable");
    const searchInput = document.getElementById("ticket-search");
    const countElement = document.getElementById("ticket-result-count");
    const sidebarCount = document.getElementById("incoming-ticket-count");

    const sampleTickets = [];

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

        const parsedDate = rawDate ? new Date(rawDate) : null;
        const dateObj =
            parsedDate && !isNaN(parsedDate.getTime()) ? parsedDate : null;

        let date = "Date unavailable";

        if (rawDate) {
            date = dateObj
                ? dateObj.toLocaleDateString("en-US", {
                    month: "long",
                    day: "numeric",
                    year: "numeric"
                })
                : rawDate;
        }

        return {
            ...ticket,
            id,
            issue: ticket.issue || ticket.title || ticket.Title || "No Title",
            description: ticket.description || ticket.Description || "",
            location: ticket.location || ticket.Location || "Unknown",
            status: normalizeStatus(ticket.status || ticket.Status),
            date,
            dateObj,
            category: ticket.category || ticket.Category || "Others",
            department: ticket.department || ticket.Department || ""
        };
    }

    function pad(value) {
        return String(value).padStart(2, "0");
    }

    // Common date spellings so "nov 21", "11/21/2026" and "2026-11-21"
    // all find the same ticket.
    function searchableDate(dateObj) {
        if (!dateObj) return "";

        const year = dateObj.getFullYear();
        const monthIndex = dateObj.getMonth();
        const day = dateObj.getDate();
        const monthLong = dateObj.toLocaleDateString("en-US", { month: "long" });
        const monthShort = dateObj.toLocaleDateString("en-US", { month: "short" });

        return [
            `${monthLong} ${day}, ${year}`,
            `${monthShort} ${day}, ${year}`,
            `${monthLong} ${day} ${year}`,
            `${monthShort} ${day} ${year}`,
            `${year}-${pad(monthIndex + 1)}-${pad(day)}`,
            `${monthIndex + 1}/${day}/${year}`,
            `${pad(monthIndex + 1)}/${pad(day)}/${year}`,
            `${day}/${monthIndex + 1}/${year}`,
            `${pad(day)}/${pad(monthIndex + 1)}/${year}`
        ].join(" ");
    }

    const MONTH_WORDS = [
        "january", "jan", "february", "feb", "march", "mar", "april", "apr",
        "may", "june", "jun", "july", "jul", "august", "aug", "september",
        "sept", "sep", "october", "oct", "november", "nov", "december", "dec"
    ];

    function searchableText(ticket) {
        const text = [
            ticket.id,
            ticket.issue,
            ticket.description,
            ticket.category,
            ticket.location,
            ticket.status,
            ticket.department,
            searchableDate(ticket.dateObj)
        ].join(" ").toLowerCase();

        // "streetlight" should also match "street light".
        return text + " " + text.replace(/[^a-z0-9]+/g, "");
    }

    // API data is loaded first, then local saved changes override it.
    function getTicketsWithSavedChanges(sourceTickets) {
        const savedTickets = getSavedTickets();
        const ticketMap = new Map();

        sourceTickets.forEach(function (sourceTicket) {
            const ticket = normalizeTicket(sourceTicket);

            if (ticket.id) {
                ticketMap.set(ticket.id, ticket);
            }
        });

        // Include saved tickets and apply their latest changes.
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
        const searchTokens = searchInput.value
            .trim()
            .toLowerCase()
            .split(/\s+/)
            .filter(Boolean);

        const hasMonthWord = searchTokens.some(function (token) {
            return MONTH_WORDS.includes(token);
        });

        // A day/year next to a month name ("nov 21", "november 2026")
        // belongs to the date, so it cannot match digits inside a ticket ID.
        const dateTokens = [];
        const textTokens = [];

        searchTokens.forEach(function (token) {
            if (
                MONTH_WORDS.includes(token) ||
                (hasMonthWord && /^\d{1,4}$/.test(token))
            ) {
                dateTokens.push(token);
            } else {
                textTokens.push(token);
            }
        });

        const incomingTickets = allTickets.filter(function (ticket) {
            return ticket.status === "pending";
        });

        // Every word must appear somewhere in the ticket's details,
        // so "streetlight pundi" and "nov 21" both narrow the list.
        const visibleTickets = incomingTickets.filter(function (ticket) {
            if (searchTokens.length === 0) return true;

            const haystack = searchableText(ticket);
            const dateHaystack = searchableDate(ticket.dateObj).toLowerCase();

            return (
                textTokens.every(function (token) {
                    return haystack.includes(token);
                }) &&
                dateTokens.every(function (token) {
                    return dateHaystack.includes(token);
                })
            );
        });

        tbody.replaceChildren();

        visibleTickets.forEach(function (ticket) {
            const row = document.createElement("tr");

            const idCell = document.createElement("td");
            idCell.textContent = "#" + ticket.id;

            const issueCell = document.createElement("td");

            const issueTitle = document.createElement("strong");
            issueTitle.textContent = ticket.issue;

            const description = document.createElement("br");
            const descriptionText = document.createElement("small");
            descriptionText.textContent = ticket.description;

            issueCell.append(issueTitle, description, descriptionText);

            const categoryCell = document.createElement("td");
            categoryCell.textContent = ticket.category || "Others";

            const locationCell = document.createElement("td");
            locationCell.textContent = ticket.location;

            const dateCell = document.createElement("td");
            dateCell.textContent = ticket.date;

            const statusCell = document.createElement("td");
            const statusBadge = document.createElement("span");

            statusBadge.className = "status-badge pending";
            statusBadge.textContent = "Pending";

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
                categoryCell,
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

            cell.colSpan = 7;
            cell.textContent = "No pending tickets found.";
            cell.style.textAlign = "center";
            cell.style.padding = "24px";

            row.appendChild(cell);
            tbody.appendChild(row);
        }

        countElement.textContent =
            `Showing ${visibleTickets.length} of ${incomingTickets.length} pending tickets`;

        sidebarCount.textContent = incomingTickets.length;
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

    searchInput.addEventListener("input", renderTickets);

    window.addEventListener("pageshow", loadTickets);

    window.addEventListener("storage", function (event) {
        if (event.key === storageKey) {
            loadTickets();
        }
    });

    loadTickets();
});