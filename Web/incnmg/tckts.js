
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
        const searchText = searchInput.value.trim().toLowerCase();

        // FIX 1: Handle case sensitivity for "Pending" status
        const incomingTickets = allTickets.filter(function (ticket) {
            return ticket.status && ticket.status.toLowerCase() === "pending";
        });

        const visibleTickets = incomingTickets.filter(function (ticket) {
            // FIX 2: Safely read 'title' instead of 'issue'
            const id = ticket.id ? ticket.id.toLowerCase() : "";
            const title = ticket.title ? ticket.title.toLowerCase() : "";
            const loc = ticket.location ? ticket.location.toLowerCase() : "";

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
            // Mapping to the correct property from C#
            issueTitle.textContent = ticket.title; 

            const description = document.createElement("br");
            const descriptionText = document.createElement("small");
            descriptionText.textContent = ticket.description;

            issueCell.append(issueTitle, description, descriptionText);

            const locationCell = document.createElement("td");
            locationCell.textContent = ticket.location;

            const dateCell = document.createElement("td");
            // FIX 3: Map to 'dateSubmitted' and format it for the dashboard
            const rawDate = ticket.dateSubmitted ? new Date(ticket.dateSubmitted) : new Date();
            dateCell.textContent = rawDate.toLocaleDateString() + ' ' + rawDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

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
    const response = await fetch('http://localhost:5141/api/tickets');
    
    if (!response.ok) {
      throw new Error(`API returned status ${response.status}`);
    }
    
    const tickets = await response.json();
    
    // THE MISSING LINK: Save the downloaded data to your global list!
    allTickets = tickets; 
    
    // Now render the table (it will use the newly populated allTickets array)
    renderTickets(); 
    
  } catch (error) {
    console.error("Could not load API tickets:", error);
  }
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
