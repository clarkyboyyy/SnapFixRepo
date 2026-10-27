
document.addEventListener("DOMContentLoaded", function () {
    const params = new URLSearchParams(window.location.search);
    const ticketId = params.get("id") || "SF-1024";
    const fromAssigned = params.get("from") === "assigned";

    // Highlight the correct sidebar link
    if (fromAssigned) {
        document.getElementById("assigned-link")?.classList.add("active");
    } else {
        document.getElementById("incoming-link")?.classList.add("active");
    }

    // Set the breadcrumb and back button based on the source page
    const sourceBreadcrumb = document.getElementById("source-breadcrumb");
    const backLink = document.getElementById("back-link");

    if (fromAssigned) {
        if (sourceBreadcrumb) {
            sourceBreadcrumb.href = "../incnmg/assgnd.html";
            sourceBreadcrumb.textContent = "Assigned Tickets";
        }

        if (backLink) {
            backLink.href = "../incnmg/assgnd.html";
            backLink.innerHTML = "&larr; Back to Assigned Tickets";
        }
    }

    const sampleTickets = {
        "SF-1024": {
            issue: "Road Damage",
            location: "BGC, Taguig",
            priority: "high",
            status: "pending",
            date: "October 24, 2026",
            description:
                "A damaged road surface has been reported. Please inspect the location and arrange the necessary repairs."
        },
        "SF-1025": {
            issue: "Broken Streetlight",
            location: "Makati City",
            priority: "medium",
            status: "in-progress",
            date: "October 24, 2026",
            description:
                "A broken streetlight has been reported. Please inspect the streetlight and arrange maintenance."
        },
        "SF-1026": {
            issue: "Garbage Collection",
            location: "Pasig City",
            priority: "low",
            status: "pending",
            date: "October 25, 2026",
            description:
                "A garbage collection issue has been reported. Please check the location and arrange collection."
        }
    };

    const storageKey = "snapfixTickets";
    let savedTickets = {};

    try {
        savedTickets = JSON.parse(localStorage.getItem(storageKey)) || {};
    } catch (error) {
        savedTickets = {};
    }

    const ticket = {
        ...(sampleTickets[ticketId] || sampleTickets["SF-1024"]),
        ...(savedTickets[ticketId] || {})
    };

    const elements = {
        ticketId: document.getElementById("ticket-id"),
        issue: document.getElementById("issue-title"),
        location: document.getElementById("issue-location"),
        date: document.getElementById("date-submitted"),
        description: document.getElementById("issue-description"),
        displayStatus: document.getElementById("display-status"),
        displayPriority: document.getElementById("display-priority"),
        status: document.getElementById("ticket-status"),
        priority: document.getElementById("ticket-priority"),
        department: document.getElementById("ticket-department"),
        notes: document.getElementById("admin-notes"),
        assignment: document.getElementById("current-assignment"),
        form: document.getElementById("review-form"),
        message: document.getElementById("form-message"),
        assignButton: document.getElementById("assign-button")
    };

    function formatStatus(value) {
        return {
            "pending": "Pending",
            "assigned": "Assigned",
            "in-progress": "In Progress",
            "resolved": "Resolved"
        }[value] || value;
    }

    function formatPriority(value) {
        return value.charAt(0).toUpperCase() + value.slice(1);
    }

    function updateBadge(element, value, type) {
        element.textContent =
            type === "status" ? formatStatus(value) : formatPriority(value);

        element.className = `${type}-badge ${value}`;
    }

    function renderTicket() {
        elements.ticketId.textContent = `#${ticketId}`;
        elements.issue.textContent = ticket.issue;
        elements.location.textContent = ticket.location;
        elements.date.textContent = ticket.date;
        elements.description.textContent = ticket.description;

        elements.status.value = ticket.status;
        elements.priority.value = ticket.priority;
        elements.department.value = ticket.department || "";
        elements.notes.value = ticket.notes || "";

        elements.assignment.textContent =
            ticket.department || "Not assigned";

        updateBadge(elements.displayStatus, ticket.status, "status");
        updateBadge(elements.displayPriority, ticket.priority, "priority");
    }

    function showMessage(message, type) {
        elements.message.textContent = message;
        elements.message.className = `form-message ${type}`;
    }

    function saveTicket() {
        ticket.status = elements.status.value;
        ticket.priority = elements.priority.value;
        ticket.department = elements.department.value;
        ticket.notes = elements.notes.value.trim();

        savedTickets[ticketId] = ticket;

        try {
            localStorage.setItem(storageKey, JSON.stringify(savedTickets));
            renderTicket();
            return true;
        } catch (error) {
            showMessage(
                "Could not save changes in this browser. Check browser storage settings.",
                "error"
            );
            return false;
        }
    }

    elements.form.addEventListener("submit", function (event) {
        event.preventDefault();

        if (!elements.department.value) {
            showMessage(
                "Please select a department before saving.",
                "error"
            );
            elements.department.focus();
            return;
        }

        if (saveTicket()) {
            showMessage("Ticket changes saved successfully.", "success");
        }
    });

    elements.assignButton.addEventListener("click", function () {
        if (!elements.department.value) {
            showMessage("Please select a department first.", "error");
            elements.department.focus();
            return;
        }

        // Automatically set the status to Assigned
        elements.status.value = "assigned";
        ticket.status = "assigned";

        if (saveTicket()) {
            showMessage(
                `Ticket assigned to ${ticket.department}.`,
                "success"
            );
        }
    });

    renderTicket();
});
