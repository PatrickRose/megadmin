document.addEventListener("DOMContentLoaded", () => {

    const deleteStartButtons = document.querySelectorAll(".delete-initial");
    const cancelButton = document.getElementById("cancel-button");
    const deleteButton = document.getElementById("delete-button");
    const modal = document.getElementById("warning-popup-modal");
    const screenBackground = document.getElementById("dark-screen");
    const popupTitle = document.getElementById("popup-title");
    console.log(deleteStartButtons, cancelButton, deleteButton, modal, screenBackground, popupTitle);
    // Listeners are only active if all the necessary elements are present on the page
    if (deleteStartButtons && cancelButton && modal && deleteButton && screenBackground && popupTitle) {
        // Add a listener to each delete button on the page
        deleteStartButtons.forEach(el => el.addEventListener("click", event => {
            // eventID and specificID are used to specify the entry that needs to be deleted
            var eventID = event.currentTarget.getAttribute("data-event-id");
            var specificID = event.currentTarget.getAttribute("data-specific-id");
            var name = event.currentTarget.getAttribute("data-specific-name");
            var targetType = event.currentTarget.getAttribute("title");
            // targetType determines what the final url should look like, depending on what is being deleted
            if (targetType == "Delete Player") {
                popupTitle.innerText = `Remove ${name} from the event?`;
                deleteButton.setAttribute("href", `/organise/events/${eventID}/event_signups/${specificID}`);
            } else if (targetType == "Delete Organiser") {
                popupTitle.innerText = `Remove ${name} from the event?`;
                deleteButton.setAttribute("href", `/organise/events/${eventID}/event_organisers/${specificID}`);
            } else if (targetType == "Delete Event") {
                popupTitle.innerText = `Delete the event ${name}?`;
                deleteButton.setAttribute("href", `/organise/events/${eventID}`);
            } else if (targetType == "Delete Team") {
                popupTitle.innerText = `Delete the team ${name}?`;
                console.log(eventID);
                console.log(specificID);
                deleteButton.setAttribute("href", `/organise/events/${eventID}/teams/${specificID}`);
                console.log(deleteButton.getAttribute("href"));
            }
            deleteButton.setAttribute("data-method", "delete");
            deleteButton.setAttribute("rel", "nofollow");
            // Clicking one then opens the configured popup and dims the screen
            modal.style.display = "block";
            screenBackground.style.display = "block";
        }));

        deleteButton.addEventListener("click", () => {
            // Once delete is pressed, the popup closes
            modal.style.display = "none";
            screenBackground.style.display = "none";
        })
    
        cancelButton.addEventListener("click", () => {
            // If cancelled, the popup closes
            modal.style.display = "none";
            screenBackground.style.display = "none";
        });

        screenBackground.addEventListener("click", () => {
            // If the dimmed screen is clicked on, the popup closes
            modal.style.display = "none";
            screenBackground.style.display = "none";
        });
    }
});