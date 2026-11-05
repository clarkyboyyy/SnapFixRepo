document.addEventListener("DOMContentLoaded", function () {

    // --------------------------------
    // TICKET AND PAGE INFORMATION
    // --------------------------------

    const params = new URLSearchParams(window.location.search);
    const ticketId = params.get("id") || "SF-1024";
    const fromAssigned = params.get("from") === "assigned";

    const storageKey = "snapfixTickets";
    const API_BASE_URL = "http://localhost:5141";
    
    // Set active ticket ID dynamically from URL parameter
    let activeTicketId = ticketId;

    // Backend conversation route
    const messagesApiUrl = `${API_BASE_URL}/api/messages/${activeTicketId}`;

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
    // SAMPLE TICKETS FALLBACK
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

    // Initial fallback placeholder while loading
    let ticket = savedTickets[ticketId] || sampleTickets[ticketId] || {
        issue: "Loading ticket...",
        location: "Loading...",
        status: "pending",
        date: "Loading...",
        description: "Fetching ticket details..."
    };

    // Helper to normalize and render ticket data
    function applyTicketData(rawTicket) {
        const normalizedDate = rawTicket.date || rawTicket.dateSubmitted || rawTicket.DateSubmitted || "Date unavailable";
        
        ticket = {
            issue: rawTicket.issue || rawTicket.title || rawTicket.Title || "No Title",
            location: rawTicket.location || rawTicket.Location || "Unknown",
            status: normalizeStatus(rawTicket.status || rawTicket.Status),
            date: normalizedDate,
            description: rawTicket.description || rawTicket.Description || "No description provided.",
            department: rawTicket.department || rawTicket.Department || "",
            notes: rawTicket.notes || "",
            ...(savedTickets[ticketId] || {}) // LocalStorage overrides take priority
        };
        renderTicket();
    }

    // If it's already in sample tickets or localStorage, render immediately
    if (savedTickets[ticketId] || sampleTickets[ticketId]) {
        applyTicketData(ticket);
    } else {
        // Fetch all tickets from backend API and find the matching one
        fetch(`${API_BASE_URL}/api/tickets`)
            .then(res => {
                if (!res.ok) throw new Error("Failed to fetch tickets list");
                return res.json();
            })
            .then(data => {
                const ticketsArray = Array.isArray(data) ? data : (data.tickets || []);
                const found = ticketsArray.find(t => {
                    const tid = String(t.id ?? t.Id ?? t.ticketId ?? t.TicketId ?? "");
                    return tid === ticketId;
                });

                if (found) {
                    applyTicketData(found);
                } else {
                    // Fallback if not found anywhere
                    ticket = {
                        issue: "Ticket Not Found",
                        location: "Unknown",
                        status: "pending",
                        date: "N/A",
                        description: `Could not find ticket ID #${ticketId} in database.`
                    };
                    renderTicket();
                }
            })
            .catch(err => {
                console.error("Error loading ticket from API:", err);
                ticket.issue = "Error Loading Ticket";
                ticket.description = "Could not connect to backend tickets API.";
                renderTicket();
            });
    }

    // Support older status values saved in localStorage
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
        if (!elements.displayStatus) return;
        elements.displayStatus.textContent = formatStatus(ticket.status);
        elements.displayStatus.className = `status-badge ${ticket.status}`;
    }

    // --------------------------------
    // DISPLAY TICKET
    // --------------------------------

    function renderTicket() {
        if (elements.ticketId) elements.ticketId.textContent = `#${ticketId}`;
        if (elements.issue) elements.issue.textContent = ticket.issue || "No Title";
        if (elements.location) elements.location.textContent = ticket.location || "Unknown";
        if (elements.date) elements.date.textContent = ticket.date || "Date unavailable";
        if (elements.description) elements.description.textContent = ticket.description || "No description provided.";

        if (elements.status) elements.status.value = ticket.status;
        if (elements.department) elements.department.value = ticket.department || "";
        if (elements.notes) elements.notes.value = ticket.notes || "";

        if (elements.assignment) elements.assignment.textContent = ticket.department || "Not assigned";

        updateStatusBadge();
    }

    // --------------------------------
    // FORM MESSAGE
    // --------------------------------

    function showMessage(msg, type) {
        if (!elements.message) return;
        elements.message.textContent = msg;
        elements.message.className = `form-message ${type}`;
    }

    // --------------------------------
    // SAVE TICKET
    // --------------------------------

    function saveTicket() {
        const selectedStatus = elements.status ? elements.status.value : "pending";
        const selectedDepartment = elements.department ? elements.department.value : "";

        if (selectedStatus === "ongoing" && !selectedDepartment) {
            showMessage("Please select a department before setting the ticket to Ongoing.", "error");
            if (elements.department) elements.department.focus();
            return false;
        }

        ticket.status = selectedStatus;
        ticket.department = selectedDepartment;
        ticket.notes = elements.notes ? elements.notes.value.trim() : "";

        savedTickets = getSavedTickets();
        savedTickets[ticketId] = ticket;

        try {
            localStorage.setItem(storageKey, JSON.stringify(savedTickets));
            renderTicket();
            return true;
        } catch (error) {
            console.error("Could not save ticket:", error);
            showMessage("Could not save changes in this browser.", "error");
            return false;
        }
    }

    // --------------------------------
    // SAVE CHANGES BUTTON
    // --------------------------------

    if (elements.form) {
        elements.form.addEventListener("submit", function (event) {
            event.preventDefault();
            if (saveTicket()) {
                showMessage("Ticket changes saved successfully. Return to the ticket list to see its updated status.", "success");
            }
        });
    }

    // --------------------------------
    // ASSIGN TICKET BUTTON
    // --------------------------------

    if (elements.assignButton) {
        elements.assignButton.addEventListener("click", function () {
            if (!elements.department || !elements.department.value) {
                showMessage("Please select a department first.", "error");
                if (elements.department) elements.department.focus();
                return;
            }

            if (elements.status) elements.status.value = "ongoing";

            if (saveTicket()) {
                showMessage(`Ticket is now Ongoing and assigned to ${ticket.department}.`, "success");
            }
        });
    }

    // --------------------------------
    // CONVERSATION DISPLAY
    // --------------------------------

    function displayConversationMessage(msg) {
        if (!elements.conversation) return;

        const messageBox = document.createElement("div");
        messageBox.className = "conversation-message";

        const sender = document.createElement("strong");
        sender.textContent = msg.senderType || msg.sender || "User";

        const content = document.createElement("p");
        content.textContent = msg.message || msg.content || "";

        const timestamp = document.createElement("small");
        const timestampValue = msg.dateSent || msg.sentAt || msg.createdAt || msg.timestamp;
        
        if (timestampValue) {
            const date = new Date(timestampValue);
            timestamp.textContent = isNaN(date.getTime()) ? "" : date.toLocaleString();
        }

        messageBox.appendChild(sender);
        messageBox.appendChild(content);
        messageBox.appendChild(timestamp);

        elements.conversation.appendChild(messageBox);
    }

    function showConversationNotice(messageText) {
        if (!elements.conversation) return;
        elements.conversation.innerHTML = "";

        const notice = document.createElement("p");
        notice.className = "conversation-notice";
        notice.textContent = messageText;

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
            if (!elements.conversation) return;
            elements.conversation.innerHTML = "";

            if (!Array.isArray(messages) || messages.length === 0) {
                showConversationNotice("No messages yet. You can start the conversation.");
                return;
            }

            messages.forEach(displayConversationMessage);

        } catch (error) {
            console.error("Could not load conversation:", error);
            showConversationNotice("Conversation is not connected yet. The backend messaging API needs to be implemented.");
        }
    }

    // --------------------------------
    // SEND MESSAGE TO BACKEND
    // --------------------------------

    if (elements.messageForm) {
        elements.messageForm.addEventListener("submit", async function (event) {
            event.preventDefault();

            const messageContent = elements.messageInput ? elements.messageInput.value.trim() : "";
            if (!messageContent) return;

            const sendButton = document.getElementById("send-message-button");
            if (sendButton) sendButton.disabled = true;

            try {
                const postUrl = `${API_BASE_URL}/api/messages`;

                const response = await fetch(postUrl, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        ticketId: activeTicketId,
                        senderType: "admin",
                        message: messageContent
                    })
                });

                if (!response.ok) {
                    throw new Error("Message could not be sent.");
                }

                if (elements.messageInput) elements.messageInput.value = "";
                await loadConversation();

            } catch (error) {
                console.error("Could not send message:", error);
                showConversationNotice("Message not sent. The backend messaging API is not available yet.");
            } finally {
                if (sendButton) sendButton.disabled = false;
            }
        });
    }

    // --------------------------------
    // INITIALIZE PAGE
    // --------------------------------

    renderTicket();
    loadConversation();

});