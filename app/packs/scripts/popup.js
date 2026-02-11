document.addEventListener("DOMContentLoaded", () => {

    const openButton = document.getElementById("open-popup");
    const closeButton = document.getElementById("close-popup");
    const sendButton = document.getElementById("send-button");
    const modal = document.getElementById("popup-modal");
    const screenBackground = document.getElementById("dark-screen");
    const publishButton = document.getElementById("publish-button");

    if (openButton && closeButton && modal && sendButton && screenBackground) {
        // Pressing the send email button in the popup hides the popup
        sendButton.addEventListener("click", () => {
            modal.style.display = "none";
            screenBackground.style.display = "none";
        })

        openButton.addEventListener("click", () => {
            // Pressing the open button displays the popup
            modal.style.display = "block";
            screenBackground.style.display = "block";
        });
    
        closeButton.addEventListener("click", () => {
            // The close button hides the popup
            modal.style.display = "none";
            screenBackground.style.display = "none";
        });

        screenBackground.addEventListener("click", () => {
            modal.style.display = "none";
            screenBackground.style.display = "none";
        });
    }

    // Popup when publishing draft event
    if (openButton && closeButton && publishButton && screenBackground && modal) { 
        console.log("on draft event");  // && modal && publishButton && screenBackground
        // Pressing the send email button in the popup hides the popup
        openButton.addEventListener("click", () => {
            // Pressing the open button displays the popup
            modal.style.display = "block";
            screenBackground.style.display = "block";
        });
    
        closeButton.addEventListener("click", () => {
            // The close button hides the popup
            modal.style.display = "none";
            screenBackground.style.display = "none";
        });

        screenBackground.addEventListener("click", () => {
            modal.style.display = "none";
            screenBackground.style.display = "none";
        });
    }
});
