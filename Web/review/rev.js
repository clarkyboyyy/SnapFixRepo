
document.addEventListener("DOMContentLoaded", function () {

    // --------------------------------
    // TICKET AND PAGE INFORMATION
    // --------------------------------

    const params = new URLSearchParams(window.location.search);
    const ticketId = params.get("id") || "SF-1024";
    const fromAssigned = params.get("from") === "assigned";

    const storageKey = "snapfixTickets";

    // Backend conversation routes.
    // These are proposed routes and must be implemented by the backend developer.
    const messagesApiUrl =
        `http://localhost:5141/api/tickets/${encodeURIComponent(ticketId)}/messages`;

    // --------------------------------
    // SIDEBAR AND BREADCRUMB
    // --------------------------------

    if (fromAssigned) {
        document.getElementById("assigned-link")?.classList.add("active");
    } else {
        document.getElementById("incoming-link")?.classList.add("active");
    }

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

    // --------------------------------
    // SAMPLE TICKETS
    // --------------------------------

    const sampleTickets = {
        "SF-1024": {
            issue: "Road Damage",
            location: "BGC, Taguig",
            status: "pending",
            date: "October 24, 2026",
            description:
                "A damaged road surface has been reported. Please inspect the location and arrange the necessary repairs."
        },

        "SF-1025": {
            issue: "Broken Streetlight",
            location: "Makati City",
            status: "ongoing",
            date: "October 24, 2026",
            description:
                "A broken streetlight has been reported. Please inspect the streetlight and arrange maintenance."
        },

        "SF-1026": {
            issue: "Garbage Collection",
            location: "Pasig City",
            status: "pending",
            date: "October 25, 2026",
            description:
                "A garbage collection issue has been reported. Please check the location and arrange collection."
        }
    };

    // --------------------------------
    // LOAD SAVED TICKET INFORMATION
    // --------------------------------

    function getSavedTickets() {
        try {
            return JSON.parse(localStorage.getItem(storageKey)) || {};
        } catch (error) {
            console.error("Could not read saved tickets:", error);
            return {};
        }
    }

    let savedTickets = getSavedTickets();

    const ticket = {
        ...(sampleTickets[ticketId] || sampleTickets["SF-1024"]),
        ...(savedTickets[ticketId] || {})
    };

    // Support older status values already saved in localStorage.
    function normalizeStatus(value) {
        const status = String(value || "pending")
            .toLowerCase()
            .replace(/\s+/g, "-");

        if (
            status === "assigned" ||
            status === "in-progress" ||
            status === "in progress" ||
            status === "ongoing"
        ) {
            return "ongoing";
        }

        return "pending";
    }

    ticket.status = normalizeStatus(ticket.status);

    // --------------------------------
    // HTML ELEMENTS
    // --------------------------------

    const elements = {
        ticketId: document.getElementById("ticket-id"),
        issue: document.getElementById("issue-title"),
        location: document.getElementById("issue-location"),
        date: document.getElementById("date-submitted"),
        description: document.getElementById("issue-description"),

        displayStatus: document.getElementById("display-status"),

        status: document.getElementById("ticket-status"),
        department: document.getElementById("ticket-department"),
        notes: document.getElementById("admin-notes"),

        assignment: document.getElementById("current-assignment"),

        form: document.getElementById("review-form"),
        message: document.getElementById("form-message"),
        assignButton: document.getElementById("assign-button"),

        conversation: document.getElementById("conversation-messages"),
        conversationNotice: document.getElementById("conversation-notice"),
        messageForm: document.getElementById("message-form"),
        messageInput: document.getElementById("message-input")
    };

    // --------------------------------
    // STATUS DISPLAY
    // --------------------------------

    function formatStatus(value) {
        return value === "ongoing" ? "Ongoing" : "Pending";
    }

    function updateStatusBadge() {
        elements.displayStatus.textContent = formatStatus(ticket.status);

        elements.displayStatus.className =
            `status-badge ${ticket.status}`;
    }

    // --------------------------------
    // DISPLAY TICKET
    // --------------------------------

    function renderTicket() {
        elements.ticketId.textContent = `#${ticketId}`;
        elements.issue.textContent = ticket.issue || "No Title";
        elements.location.textContent = ticket.location || "Unknown";
        elements.date.textContent = ticket.date || "Date unavailable";
        elements.description.textContent =
            ticket.description || "No description provided.";

        elements.status.value = ticket.status;
        elements.department.value = ticket.department || "";
        elements.notes.value = ticket.notes || "";

        elements.assignment.textContent =
            ticket.department || "Not assigned";

        updateStatusBadge();
    }

    // --------------------------------
    // FORM MESSAGE
    // --------------------------------

    function showMessage(message, type) {
        elements.message.textContent = message;
        elements.message.className = `form-message ${type}`;
    }

    // --------------------------------
    // SAVE TICKET
    // --------------------------------

    function saveTicket() {

        const selectedStatus = elements.status.value;
        const selectedDepartment = elements.department.value;

        // A department is required for Ongoing tickets.
        if (selectedStatus === "ongoing" && !selectedDepartment) {
            showMessage(
                "Please select a department before setting the ticket to Ongoing.",
                "error"
            );

            elements.department.focus();
            return false;
        }

        ticket.status = selectedStatus;
        ticket.department = selectedDepartment;
        ticket.notes = elements.notes.value.trim();

        savedTickets = getSavedTickets();
        savedTickets[ticketId] = ticket;

        try {
            localStorage.setItem(storageKey, JSON.stringify(savedTickets));

            renderTicket();

            return true;

        } catch (error) {
            console.error("Could not save ticket:", error);

            showMessage(
                "Could not save changes in this browser.",
                "error"
            );

            return false;
        }
    }

    // --------------------------------
    // SAVE CHANGES BUTTON
    // --------------------------------

    elements.form.addEventListener("submit", function (event) {
        event.preventDefault();

        if (saveTicket()) {
            showMessage(
                "Ticket changes saved successfully. Return to the ticket list to see its updated status.",
                "success"
            );
        }
    });

    // --------------------------------
    // ASSIGN TICKET BUTTON
    // --------------------------------

    elements.assignButton.addEventListener("click", function () {

        if (!elements.department.value) {
            showMessage(
                "Please select a department first.",
                "error"
            );

            elements.department.focus();
            return;
        }

        elements.status.value = "ongoing";

        if (saveTicket()) {
            showMessage(
                `Ticket is now Ongoing and assigned to ${ticket.department}.`,
                "success"
            );
        }
    });

    // --------------------------------
    // CONVERSATION DISPLAY
    // --------------------------------

    function displayConversationMessage(message) {

        const messageBox = document.createElement("div");
        messageBox.className = "conversation-message";

        const sender = document.createElement("strong");
        sender.textContent =
            message.senderRole || message.sender || "User";

        const content = document.createElement("p");
        content.textContent =
            message.content || message.message || "";

        const timestamp = document.createElement("small");

        if (message.sentAt || message.createdAt || message.timestamp) {
            const date = new Date(
                message.sentAt || message.createdAt || message.timestamp
            );

            timestamp.textContent = isNaN(date.getTime())
                ? ""
                : date.toLocaleString();
        }

        messageBox.appendChild(sender);
        messageBox.appendChild(content);
        messageBox.appendChild(timestamp);

        elements.conversation.appendChild(messageBox);
    }

    function showConversationNotice(message) {
        elements.conversation.innerHTML = "";

        const notice = document.createElement("p");
        notice.className = "conversation-notice";
        notice.textContent = message;

        elements.conversation.appendChild(notice);
    }

    // --------------------------------
    // LOAD CONVERSATION FROM BACKEND
    // --------------------------------

    async function loadConversation() {

        showConversationNotice("Loading conversation...");

        try {
            const response = await fetch(messagesApiUrl);

            if (!response.ok) {
                throw new Error("Conversation service is unavailable.");
            }

            const messages = await response.json();

            elements.conversation.innerHTML = "";

            if (!Array.isArray(messages) || messages.length === 0) {
                showConversationNotice(
                    "No messages yet. You can start the conversation."
                );
                return;
            }

            messages.forEach(displayConversationMessage);

        } catch (error) {
            console.error("Could not load conversation:", error);

            showConversationNotice(
                "Conversation is not connected yet. The backend messaging API needs to be implemented."
            );
        }
    }

    // --------------------------------
    // SEND MESSAGE TO BACKEND
    // --------------------------------

    elements.messageForm.addEventListener("submit", async function (event) {
        event.preventDefault();

        const messageContent = elements.messageInput.value.trim();

        if (!messageContent) {
            return;
        }

        const sendButton = document.getElementById("send-message-button");

        sendButton.disabled = true;

        try {
            const response = await fetch(messagesApiUrl, {
                method: "POST",

                headers: {
                    "Content-Type": "application/json"
                },

                body: JSON.stringify({
                    content: messageContent
                })
            });

            if (!response.ok) {
                throw new Error("Message could not be sent.");
            }

            elements.messageInput.value = "";

            await loadConversation();

        } catch (error) {
            console.error("Could not send message:", error);

            showConversationNotice(
                "Message not sent. The backend messaging API is not available yet."
            );

        } finally {
            sendButton.disabled = false;
        }
    });

    // --------------------------------
    // INITIALIZE PAGE
    // --------------------------------

    renderTicket();
    loadConversation();

});
