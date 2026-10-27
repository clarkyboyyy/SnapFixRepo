
document.addEventListener("DOMContentLoaded", function () {
    const searchInput = document.getElementById("ticket-search");
    const statusFilter = document.getElementById("status-filter");
    const priorityFilter = document.getElementById("priority-filter");
    const table = document.querySelector(".ticket-table");
    const tableBody = table?.querySelector("tbody");
    const tableHeaders = table?.querySelectorAll("thead th");

    if (!searchInput || !statusFilter || !priorityFilter || !tableBody) {
        console.error("Ticket table elements were not found. Check your HTML IDs and classes.");
        return;
    }

    const storageKey = "snapfixTickets";

    // Keep the original rows and identify each ticket by its SF number.
    const rows = Array.from(tableBody.querySelectorAll("tr"));

    function getTicketId(row) {
        return row.textContent.match(/SF-\d+/)?.[0] || null;
    }

    // Load saved changes from the Review Ticket page.
    function loadSavedTicketChanges() {
        let savedTickets = {};

        try {
            savedTickets = JSON.parse(localStorage.getItem(storageKey)) || {};
        } catch (error) {
            console.error("Could not read saved tickets:", error);
        }

        rows.forEach(function (row) {
            const ticketId = getTicketId(row);
            const ticket = ticketId ? savedTickets[ticketId] : null;

            if (!ticket) return;

            const statusBadge = row.querySelector(".status-badge");
            const priorityBadge = row.querySelector(".priority-badge");
            const departmentCell = row.querySelector(".department-cell");

            if (departmentCell) {
             departmentCell.textContent =
             ticket.department && ticket.department.trim()
            ? ticket.department
            : "Not Assigned";
}

            if (statusBadge && ticket.status) {
                const status = ticket.status.toLowerCase();

                const statusLabels = {
                    "pending": "Pending",
                    "assigned": "Assigned",
                    "in-progress": "In Progress",
                    "resolved": "Resolved",
                    
                };

                statusBadge.textContent = statusLabels[status] || ticket.status;
                statusBadge.className = "status-badge " + status;
            }

            if (priorityBadge && ticket.priority) {
                const priority = ticket.priority.toLowerCase();

                priorityBadge.textContent =
                    priority.charAt(0).toUpperCase() + priority.slice(1);

                priorityBadge.className = "priority-badge " + priority;
            }
        });
    }

    loadSavedTicketChanges();

    // Create a message for when no tickets match.
    const emptyRow = document.createElement("tr");
    emptyRow.innerHTML = `
        <td colspan="6" style="text-align: center; padding: 24px;">
            No tickets found.
        </td>
    `;
    emptyRow.hidden = true;
    tableBody.appendChild(emptyRow);

    // Add a live result count.
    const resultCount = document.createElement("p");
    resultCount.className = "ticket-result-count";
    resultCount.style.margin = "12px 0";
    resultCount.style.fontSize = "13px";

    const footer = document.querySelector(".table-footer");

    if (footer) {
        footer.prepend(resultCount);
    } else {
        table.parentElement.appendChild(resultCount);
    }

    // Search and filter tickets using the updated badge values.
    function filterTickets() {
        const searchText = searchInput.value.trim().toLowerCase();
        const selectedStatus = statusFilter.value.toLowerCase();
        const selectedPriority = priorityFilter.value.toLowerCase();

        let visibleCount = 0;

        rows.forEach(function (row) {
            const rowText = row.textContent.toLowerCase();
            const statusBadge = row.querySelector(".status-badge");
            const priorityBadge = row.querySelector(".priority-badge");

            const ticketStatus = statusBadge
                ? Array.from(statusBadge.classList).find(
                    name => name !== "status-badge"
                ) || ""
                : "";

            const ticketPriority = priorityBadge
                ? Array.from(priorityBadge.classList).find(
                    name => name !== "priority-badge"
                ) || ""
                : "";

            const matchesSearch = rowText.includes(searchText);

            const matchesStatus =
                selectedStatus === "" ||
                ticketStatus === selectedStatus;

            const matchesPriority =
                selectedPriority === "" ||
                ticketPriority === selectedPriority;

            const isVisible =
                matchesSearch && matchesStatus && matchesPriority;

            row.hidden = !isVisible;

            if (isVisible) visibleCount++;
        });

        emptyRow.hidden = visibleCount !== 0;
        resultCount.textContent =
            `Showing ${visibleCount} of ${rows.length} tickets`;
    }

    searchInput.addEventListener("input", filterTickets);
    statusFilter.addEventListener("change", filterTickets);
    priorityFilter.addEventListener("change", filterTickets);

    // Make table headings sortable.
    const sortDirections = {};

    if (tableHeaders) {
        tableHeaders.forEach(function (header, columnIndex) {
            header.style.cursor = "pointer";
            header.title = "Click to sort";

            header.addEventListener("click", function () {
                const ascending = sortDirections[columnIndex] !== true;
                sortDirections[columnIndex] = ascending;

                const sortedRows = [...rows].sort(function (a, b) {
                    const cellA = a.cells[columnIndex]?.textContent.trim() || "";
                    const cellB = b.cells[columnIndex]?.textContent.trim() || "";

                    let comparison;

                    if (columnIndex === 4) {
                        comparison =
                            (Date.parse(cellA) || 0) -
                            (Date.parse(cellB) || 0);
                    } else if (columnIndex === 2) {
                        const priorityOrder = {
                            high: 3,
                            medium: 2,
                            low: 1
                        };

                        comparison =
                            (priorityOrder[cellA.toLowerCase()] || 0) -
                            (priorityOrder[cellB.toLowerCase()] || 0);
                    } else {
                        comparison = cellA.localeCompare(
                            cellB,
                            undefined,
                            { numeric: true, sensitivity: "base" }
                        );
                    }

                    return ascending ? comparison : -comparison;
                });

                sortedRows.forEach(row => tableBody.appendChild(row));
                tableBody.appendChild(emptyRow);
                filterTickets();
            });
        });
    }

    // Initial result count.
    filterTickets();

    // Refresh ticket values if another page updates localStorage.
    window.addEventListener("pageshow", function () {
        loadSavedTicketChanges();
        filterTickets();
    });

    window.addEventListener("storage", function (event) {
        if (event.key === storageKey) {
            loadSavedTicketChanges();
            filterTickets();
        }
    });
});
