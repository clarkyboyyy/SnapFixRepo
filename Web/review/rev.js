
document.addEventListener("DOMContentLoaded", function () {

    // --------------------------------
    // TICKET AND PAGE INFORMATION
    // --------------------------------

    const params = new URLSearchParams(window.location.search);
    const ticketId = params.get("id") || "SF-1024";
    const fromAssigned = params.get("from") === "assigned";

    const storageKey = "snapfixTickets";
    const API_BASE_URL = "http://localhost:5141";

    const ticketApiUrl =
        `${API_BASE_URL}/api/tickets/${encodeURIComponent(ticketId)}`;

    const messagesApiUrl =
        `${API_BASE_URL}/api/messages/${encodeURIComponent(ticketId)}`;

    // Sidebar navigation
    if (fromAssigned) {
        document.getElementById("assigned-link")?.classList.add("active");
    } else {
        document.getElementById("incoming-link")?.classList.add("active");
    }

    // Breadcrumb and back button
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
            id: "SF-1024",
            title: "Road Damage",
            location: "BGC, Taguig",
            status: "Pending",
            dateSubmitted: "October 24, 2026",
            description:
                "A damaged road surface has been reported. Please inspect the location and arrange the necessary repairs."
        },

        "SF-1025": {
            id: "SF-1025",
            title: "Broken Streetlight",
            location: "Makati City",
            status: "Ongoing",
            dateSubmitted: "October 24, 2026",
            description:
                "A broken streetlight has been reported. Please inspect the streetlight and arrange maintenance."
        },

        "SF-1026": {
            id: "SF-1026",
            title: "Garbage Collection",
            location: "Pasig City",
            status: "Pending",
            dateSubmitted: "October 25, 2026",
            description:
                "A garbage collection issue has been reported. Please check the location and arrange collection."
        }
    };

    function getSavedTickets() {
        try {
            return JSON.parse(localStorage.getItem(storageKey)) || {};
        } catch (error) {
            console.error("Could not read saved tickets:", error);
            return {};
        }
    }

    let ticket = null;

    // --------------------------------
    // NORMALIZATION
    // --------------------------------

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

    function formatDate(value) {
        if (!value) return "Date unavailable";

        const date = new Date(value);

        return isNaN(date.getTime())
            ? value
            : date.toLocaleDateString("en-US", {
                month: "long",
                day: "numeric",
                year: "numeric"
            });
    }

    function normalizeTicket(rawTicket) {
        const progressValue = Number(rawTicket.progress);

        return {
            id: String(
                rawTicket.id ??
                rawTicket.Id ??
                rawTicket.ticketId ??
                ticketId
            ),

            issue:
                rawTicket.title ||
                rawTicket.Title ||
                rawTicket.issue ||
                "No Title",

            location:
                rawTicket.location ||
                rawTicket.Location ||
                "Unknown",

            status: normalizeStatus(
                rawTicket.status || rawTicket.Status
            ),

            date: formatDate(
                rawTicket.dateSubmitted ||
                rawTicket.DateSubmitted ||
                rawTicket.createdAt ||
                rawTicket.created_at ||
                rawTicket.date ||
                rawTicket.date_submitted
            ),

            description:
                rawTicket.description ||
                rawTicket.Description ||
                "No description provided.",

            department:
                rawTicket.assignedDepartment ||
                rawTicket.assigned_department ||
                rawTicket.department ||
                "",

            notes:
                rawTicket.adminNotes ||
                rawTicket.admin_notes ||
                rawTicket.notes ||
                "",

            progress: Number.isFinite(progressValue)
                ? Math.min(100, Math.max(0, progressValue))
                : 0,

            // Citizen-attached photo fields
            photoUrl:
                rawTicket.photoUrl ||
                rawTicket.photo_url ||
                "",

            photoPath:
                rawTicket.photoPath ||
                rawTicket.photo_path ||
                ""
        };
    }

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
        progress: document.getElementById("ticket-progress"),
        progressNote: document.getElementById("progress-note"),

        assignment: document.getElementById("current-assignment"),

        form: document.getElementById("review-form"),
        message: document.getElementById("form-message"),
        assignButton: document.getElementById("assign-button"),

        // Photo elements
        photo: document.getElementById("ticket-photo"),
        photoPlaceholder: document.getElementById("photo-placeholder"),
        photoMessage: document.getElementById("photo-message"),

        // Conversation elements
        conversation: document.getElementById("conversation-messages"),
        messageForm: document.getElementById("message-form"),
        messageInput: document.getElementById("message-input")
    };

    // --------------------------------
    // PHOTO DISPLAY
    // --------------------------------

    function showPhotoPlaceholder(message) {
        if (elements.photo) {
            elements.photo.hidden = true;
            elements.photo.removeAttribute("src");
        }

        if (elements.photoPlaceholder) {
            elements.photoPlaceholder.hidden = false;
        }

        if (elements.photoMessage) {
            elements.photoMessage.textContent = message;
        }
    }

    function renderPhoto() {
        if (!elements.photo || !elements.photoPlaceholder) return;

        const photoUrl = String(ticket?.photoUrl || "").trim();
        const photoPath = String(ticket?.photoPath || "").trim();

        // A local path from the citizen's phone cannot be loaded
        // by the admin's browser.
        if (!photoUrl) {
            if (photoPath) {
                showPhotoPlaceholder(
                    "Photo path found, but no online photo URL is available."
                );
            } else {
                showPhotoPlaceholder("No photo attached");
            }

            return;
        }

        let imageUrl;

        try {
            // Supports both absolute URLs and backend-relative paths.
            imageUrl = new URL(photoUrl, API_BASE_URL).href;
        } catch (error) {
            console.error("Invalid photo URL:", error);
            showPhotoPlaceholder("Invalid photo URL");
            return;
        }

        elements.photo.onload = function () {
            elements.photo.hidden = false;
            elements.photoPlaceholder.hidden = true;
        };

        elements.photo.onerror = function () {
            showPhotoPlaceholder("Photo could not be loaded");
        };

        elements.photoPlaceholder.hidden = false;

        if (elements.photoMessage) {
            elements.photoMessage.textContent = "Loading photo...";
        }

        elements.photo.hidden = true;
        elements.photo.src = imageUrl;
    }

    // --------------------------------
    // RENDER TICKET
    // --------------------------------

    function renderTicket() {
        if (!ticket) return;

        if (elements.ticketId) {
            elements.ticketId.textContent = `#${ticketId}`;
        }

        if (elements.issue) {
            elements.issue.textContent = ticket.issue || "No Title";
        }

        if (elements.location) {
            elements.location.textContent = ticket.location || "Unknown";
        }

        if (elements.date) {
            elements.date.textContent = ticket.date || "Date unavailable";
        }

        if (elements.description) {
            elements.description.textContent =
                ticket.description || "No description provided.";
        }

        if (elements.status) {
            elements.status.value = ticket.status;
        }

        if (elements.department) {
            elements.department.value = ticket.department || "";
        }

        if (elements.notes) {
            elements.notes.value = ticket.notes || "";
        }

        if (elements.progress) {
            elements.progress.value = String(ticket.progress || 0);
        }

        if (elements.assignment) {
            elements.assignment.textContent =
                ticket.department || "Not assigned";
        }

        if (elements.displayStatus) {
            elements.displayStatus.textContent = ticket.status;
            elements.displayStatus.className =
                `status-badge ${badgeClass(ticket.status)}`;
        }

        // Display the citizen's attached photo
        renderPhoto();
    }

    function showMessage(msg, type) {
        if (!elements.message) return;

        elements.message.textContent = msg;
        elements.message.className = `form-message ${type}`;
    }

    // --------------------------------
    // LOAD TICKET
    // --------------------------------

    async function loadTicket() {
        try {
            const response = await fetch(ticketApiUrl);

            if (response.status === 404) {
                const cached =
                    getSavedTickets()[ticketId] ||
                    sampleTickets[ticketId];

                if (cached) {
                    ticket = normalizeTicket(cached);
                    renderTicket();

                    showMessage(
                        `Ticket #${ticketId} is not in the database; showing the local copy.`,
                        "error"
                    );

                    return;
                }

                ticket = normalizeTicket({
                    id: ticketId,
                    title: "Ticket Not Found",
                    location: "Unknown",
                    description:
                        `Could not find ticket ID #${ticketId} in the database.`,
                    status: "Submitted"
                });

                renderTicket();
                return;
            }

            if (!response.ok) {
                throw new Error(`API returned status ${response.status}`);
            }

            const rawTicket = await response.json();

            ticket = normalizeTicket(rawTicket);
            renderTicket();

        } catch (error) {
            console.error("Could not load ticket from API:", error);

            const cached =
                getSavedTickets()[ticketId] ||
                sampleTickets[ticketId];

            if (cached) {
                ticket = normalizeTicket(cached);
                renderTicket();
            }

            showMessage(
                "Could not reach the backend. Changes cannot be saved right now.",
                "error"
            );
        }
    }

    // --------------------------------
    // SAVE TICKET
    // --------------------------------

    async function saveTicket() {
        if (!ticket) return false;

        const selectedStatus = elements.status
            ? elements.status.value
            : "Submitted";

        const selectedDepartment = elements.department
            ? elements.department.value.trim()
            : "";

        const progressValue = elements.progress
            ? Number(elements.progress.value)
            : 0;

        if (
            (selectedStatus === "In Progress" ||
             selectedStatus === "Resolved") &&
            !selectedDepartment
        ) {
            showMessage(
                "Please select a department before moving the ticket forward.",
                "error"
            );

            if (elements.department) elements.department.focus();

            return false;
        }

        if (
            !Number.isFinite(progressValue) ||
            progressValue < 0 ||
            progressValue > 100
        ) {
            showMessage(
                "Progress must be a number between 0 and 100.",
                "error"
            );

            if (elements.progress) elements.progress.focus();

            return false;
        }

        const note = elements.progressNote
            ? elements.progressNote.value.trim()
            : "";

        try {
            const response = await fetch(ticketApiUrl, {
                method: "PUT",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    status: selectedStatus,
                    assignedDepartment: selectedDepartment,
                    adminNotes: elements.notes
                        ? elements.notes.value.trim()
                        : "",
                    progress: progressValue,
                    note: note || null
                })
            });

            if (!response.ok) {
                throw new Error(`API returned status ${response.status}`);
            }

            const rawUpdatedTicket = await response.json();

            // Preserve photo fields if the PUT response does not include them.
            ticket = normalizeTicket({
                ...ticket,
                ...rawUpdatedTicket
            });

            renderTicket();

            if (elements.progressNote) {
                elements.progressNote.value = "";
            }

            // Cache the confirmed server state.
            try {
                const savedTickets = getSavedTickets();

                savedTickets[ticketId] = ticket;

                localStorage.setItem(
                    storageKey,
                    JSON.stringify(savedTickets)
                );

            } catch (error) {
                console.warn(
                    "Could not cache the ticket locally:",
                    error
                );
            }

            showMessage(
                "Ticket saved. The citizen app will pick this up within a few seconds.",
                "success"
            );

            return true;

        } catch (error) {
            console.error("Could not save ticket:", error);

            showMessage(
                "Could not save to the backend. The ticket was not changed.",
                "error"
            );

            return false;
        }
    }

    if (elements.form) {
        elements.form.addEventListener("submit", async function (event) {
            event.preventDefault();
            await saveTicket();
        });
    }

    // --------------------------------
    // ASSIGN TICKET
    // --------------------------------

    if (elements.assignButton) {
        elements.assignButton.addEventListener("click", async function () {

            if (
                !elements.department ||
                !elements.department.value.trim()
            ) {
                showMessage(
                    "Please select a department first.",
                    "error"
                );

                if (elements.department) {
                    elements.department.focus();
                }

                return;
            }

            if (elements.status) {
                elements.status.value = "In Progress";
            }

            if (
                elements.progress &&
                Number(elements.progress.value) === 0
            ) {
                elements.progress.value = "10";
            }

            if (await saveTicket()) {
                showMessage(
                    `Ticket is now In Progress and assigned to ${ticket.department}.`,
                    "success"
                );
            }
        });
    }

    // --------------------------------
    // CONVERSATION
    // --------------------------------

    function senderLabel(senderType) {
        return String(senderType || "").toLowerCase() === "admin"
            ? "Admin"
            : "Citizen";
    }

    function displayConversationMessage(msg) {
        if (!elements.conversation) return;

        const messageBox = document.createElement("div");
        messageBox.className = "conversation-message";

        const sender = document.createElement("strong");

        sender.textContent = senderLabel(
            msg.senderType || msg.sender_type
        );

        const content = document.createElement("p");

        content.textContent = msg.message || msg.content || "";

        const timestamp = document.createElement("small");

        const timestampValue =
            msg.dateSent ||
            msg.date_sent ||
            msg.createdAt ||
            msg.timestamp;

        if (timestampValue) {
            const date = new Date(timestampValue);

            timestamp.textContent = isNaN(date.getTime())
                ? ""
                : date.toLocaleString();
        }

        messageBox.append(sender, content, timestamp);

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

    let conversationLoaded = false;

    async function loadConversation() {

        if (!conversationLoaded) {
            showConversationNotice("Loading conversation...");
        }

        try {
            const response = await fetch(messagesApiUrl);

            if (!response.ok) {
                throw new Error("Conversation service is unavailable.");
            }

            const messages = await response.json();

            if (!elements.conversation) return;

            elements.conversation.innerHTML = "";
            conversationLoaded = true;

            if (!Array.isArray(messages) || messages.length === 0) {
                showConversationNotice(
                    "No messages yet. You can start the conversation."
                );

                return;
            }

            messages.forEach(displayConversationMessage);

            elements.conversation.scrollTop =
                elements.conversation.scrollHeight;

        } catch (error) {
            console.error("Could not load conversation:", error);

            if (!conversationLoaded) {
                showConversationNotice(
                    "Conversation is unavailable. Check that the backend is running."
                );
            }
        }
    }

    // --------------------------------
    // SEND MESSAGE
    // --------------------------------

    if (elements.messageForm) {
        elements.messageForm.addEventListener("submit", async function (event) {
            event.preventDefault();

            const messageContent = elements.messageInput
                ? elements.messageInput.value.trim()
                : "";

            if (!messageContent) return;

            const sendButton =
                document.getElementById("send-message-button");

            if (sendButton) {
                sendButton.disabled = true;
            }

            try {
                const response = await fetch(
                    `${API_BASE_URL}/api/messages`,
                    {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify({
                            ticketId: ticketId,
                            senderType: "admin",
                            message: messageContent
                        })
                    }
                );

                if (!response.ok) {
                    throw new Error("Message could not be sent.");
                }

                if (elements.messageInput) {
                    elements.messageInput.value = "";
                }

                await loadConversation();

            } catch (error) {
                console.error("Could not send message:", error);

                showConversationNotice(
                    "Message not sent. Check that the backend is running."
                );

            } finally {
                if (sendButton) {
                    sendButton.disabled = false;
                }
            }
        });
    }

    // --------------------------------
    // INITIALIZE
    // --------------------------------

    const cachedTicket =
        getSavedTickets()[ticketId] ||
        sampleTickets[ticketId];

    if (cachedTicket) {
        ticket = normalizeTicket(cachedTicket);
        renderTicket();
    }

    loadTicket();
    loadConversation();

    // Refresh conversation so admin can see citizen replies.
    setInterval(loadConversation, 4000);

    window.addEventListener("storage", function (event) {
        if (event.key === storageKey) {
            loadTicket();
        }
    });

});
