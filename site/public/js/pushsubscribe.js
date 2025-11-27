// --- EXISTING CONFIGURATION (Keep these as they are for backward compatibility) ---
var subscribeurl =
  "hhubvendsavepushsubscription";
var unsubscribeurl =
  "hhubvendremovepushsubscription";

var getvendsubscriptionurl = "hhubvendgetpushsubscription";

// Vapid public key.
var applicationServerPublicKey =
  "BBjBF5eKGs32lJVJ5DHaco9jRzIqwzKXhVdIaekVzx3_LW6KlLTsguiN3J2Tb3VQF1dJl8gLyubwCttsr_xu5jU";

var serviceWorkerName = "/js/serviceworker.js";

var isSubscribed = false;
var swRegistration = null;

// --- INITIALIZATION AND EVENT HANDLERS ---

$(document).ready(function() {
  // 1. INITIALIZE SERVICE WORKER IMMEDIATELY
  // This is the best practice: register the SW on page load, not on button click.
  initialiseServiceWorker();

  // Button handler for removing subscription from the server only (as per original code)
  $("#btnPushSubscriptionRemoveFromServer").click(function(e) {
    e.preventDefault();
    // Endpoint is nil here because we delete the push notification for the logged in vendor.
    removeSubscriptionFromServer("");
    console.log("Removing the push subscription from server");
  });

  // 2. REVISED PUSH NOTIFICATIONS TOGGLE LOGIC
  $("#btnPushNotifications").click(function(event) {
    event.preventDefault(); // Stop default action

    if (swRegistration === null) {
      console.log("Service Worker not yet registered. Please try again in a moment.");
      return;
    }

    // First, ensure notification permission is granted.
    Notification.requestPermission().then(function(status) {
      if (status !== "granted") {
        console.log("Permission denied or dismissed");
        disableAndSetBtnMessage("Notification permission denied");
        return;
      }

      console.log("Permission granted. Toggling subscription...");

      // Toggle logic: The button click now cleanly handles subscribe or unsubscribe.
      if (isSubscribed) {
        unsubscribe();
      } else {
        subscribe();
      }
    });
  });
});

// --- CORE FUNCTIONS (Minimal changes for compatibility) ---

function initialiseServiceWorker() {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker
      .register(serviceWorkerName)
      .then(handleSWRegistration)
      .catch(function(error) {
        console.error("Service Worker registration failed:", error);
        disableAndSetBtnMessage("SW registration failed");
      });
  } else {
    console.log("Service workers aren't supported in this browser.");
    disableAndSetBtnMessage("Service workers unsupported");
  }
}

function handleSWRegistration(reg) {
  if (reg.installing) {
    console.log("Service worker installing");
  } else if (reg.waiting) {
    console.log("Service worker installed");
  } else if (reg.active) {
    console.log("Service worker active");
  }

  swRegistration = reg;
  // Now that the SW is registered, we can check the initial state.
  initialiseState(reg);
}

// Once the service worker is registered set the initial state
function initialiseState(reg) {
  // Are Notifications supported in the service worker?
  if (!reg.showNotification) {
    console.log("Notifications aren't supported on service workers.");
    disableAndSetBtnMessage("Notifications unsupported");
    return;
  }

  // Check if push messaging is supported
  if (!("PushManager" in window)) {
    console.log("Push messaging isn't supported.");
    disableAndSetBtnMessage("Push messaging unsupported");
    return;
  }

  // Check the stored server subscription against the browser subscription
  checkPushSubscription();
}

// ... existing functions ...

/**
 * Checks for subscription in the browser and verifies its presence in the backend DB.
 * Populates the new Status UI table and panel.
 */
/**
 * Executes the full 4-state lifecycle check and updates the UI.
 * This function determines the current state (Synced, Browser Only, Backend Only, Clean)
 * and sets the appropriate UI elements and button actions.
 */
function checkPushSubscription() {
    clearAllUI(); 
    $("#btnPushSubscriptionRemoveFromServer").hide(); // Hide cleanup button by default
    updateSyncStatusPanel('Checking browser and backend subscription...', 'info');

    navigator.serviceWorker.ready.then(function(reg) {
        reg.pushManager.getSubscription()
            .then(function(browserSubscription) {
                const browserEndpoint = browserSubscription ? browserSubscription.endpoint : null;
                browserSubscriptionEndpoint = browserEndpoint; // Store globally

                // BROWSER UI UPDATES
                const browserExpiryTimestamp = browserSubscription ? browserSubscription.expirationTime : null;
                const browserExpiryDisplay = browserExpiryTimestamp ? 
                    new Date(browserExpiryTimestamp).toLocaleString() : 
                    (browserSubscription ? 'Never' : 'N/A');

                if (browserSubscription) {
                    updateUICell('browser-state', 'Present', true);
                    updateUICell('browser-endpoint', 'Exists', true);
                    updateUICell('browser-expiry', browserExpiryDisplay, null);
                    isSubscribed = true;
                } else {
                    updateUICell('browser-state', 'Absent', false);
                    updateUICell('browser-endpoint', 'None', false);
                    updateUICell('browser-expiry', browserExpiryDisplay, false); 
                    isSubscribed = false;
                }

                // FETCH SERVER STATE
                $.getJSON(getvendsubscriptionurl, function(data) {
                    let hasBackendRecord = false;
                    let backendSubscription = null;
                    
                    if (data.success == 1 && data.result && data.result.length > 0) {
                        // Check if ANY backend record exists (for showing the Force Remove button)
                        hasBackendRecord = true; 
                        // Check if a record matches the current browser endpoint (for sync status)
                        backendSubscription = data.result.find(item => item.endpoint === browserEndpoint);
                    }
                    
                    // BACKEND UI UPDATES
                    if (backendSubscription) {
                        const backendExpiryTimestamp = backendSubscription.expirationTime; 
                        const backendExpiryDisplay = backendExpiryTimestamp ? 
                             new Date(backendExpiryTimestamp).toLocaleString() : 'Non-Expiring';
                             
                        updateUICell('backend-state', 'Present', true);
                        updateUICell('backend-endpoint', 'Exists', true);
                        updateUICell('backend-expiry', backendExpiryDisplay, null);
                    } else {
                        updateUICell('backend-state', 'Absent', false);
                        updateUICell('backend-endpoint', 'None', false);
                        updateUICell('backend-expiry', 'N/A', false);
                    }

                    // --- LIFECYCLE STATE DETERMINATION AND UI ACTION ---
                    
                    if (browserSubscription && backendSubscription) {
                        // State 2: Synced & Active (Both present)
                        makeButtonUnsubscribable(); 
                        updateSyncStatusPanel('Status: **Synced & Active**. Notifications are ON.', 'success');

                    } else if (!browserSubscription && !backendSubscription) {
                        // State 1: Unsubscribed (Clean) (Both absent)
                        makeButtonSubscribable();
                        updateSyncStatusPanel('Status: **Clean State**. No subscription is active.', 'info');
                        
                    } else if (browserSubscription && !backendSubscription) {
                        // State 3: Browser Only (Mismatch)
                        isSubscribed = false; // Treat as unsubscribed for toggle logic
                        makeButtonNeedsSync(); 
                        updateSyncStatusPanel('⚠️ **Mismatch: Browser Only**. Click "Re-sync" to save the subscription to the backend.', 'warning');
                        
                    } else if (!browserSubscription && backendSubscription) {
                        // State 4: Backend Only (Mismatch)
                        isSubscribed = false; // Treat as unsubscribed for toggle logic
                        makeButtonDisabledConflict(); 
                        updateSyncStatusPanel('🚨 **Mismatch: Backend Only**. Subscription removed from browser but not backend. Use "Force Remove" button to clean up.', 'danger');
                        $("#btnPushSubscriptionRemoveFromServer").show(); // Show cleanup button
                    }

                }).fail(function(jqxhr) {
                    console.log("Get Vendor Subscription - Failed: " + jqxhr.responseText);
                    updateSyncStatusPanel('Error contacting backend to verify status.', 'danger');
                    // Fallback to warning if browser has subscription, otherwise clean subscribe state
                    if (browserSubscription) { makeButtonNeedsSync(); } else { makeButtonSubscribable(); }
                });

            })
            .catch(function(err) {
                console.log("Error during getSubscription()", err);
                updateSyncStatusPanel('Fatal error checking browser subscription. Push not functional.', 'danger');
                disableAndSetBtnMessage("Fatal Error");
            });
    });
}



function subscribe() {
  navigator.serviceWorker.ready.then(function(reg) {
    var subscribeParams = {
      userVisibleOnly: true
    };
    var applicationServerKey = urlB64ToUint8Array(applicationServerPublicKey);
    subscribeParams.applicationServerKey = applicationServerKey;

    reg.pushManager
      .subscribe(subscribeParams)
      .then(function(subscription) {
        // Send the new subscription to the server
        var endpoint = subscription.endpoint;
        var key = subscription.getKey("p256dh");
        var auth = subscription.getKey("auth");
        
        // --- NEW: Capture Expiration Time ---
        var expTime = subscription.expirationTime; 
        
        // Pass all required data to the server function
        sendSubscriptionToServer(endpoint, key, auth, expTime); 

        // Update local state and UI to unsubscribable (RED)
        isSubscribed = true;
        makeButtonUnsubscribable();
        console.log("Successfully subscribed and sent to server.");
      })
      .catch(function(e) {
        console.log("Unable to subscribe to push.", e);
        makeButtonSubscribable();
      });
  });
}

function unsubscribe() {
  navigator.serviceWorker.ready.then(function(reg) {
    reg.pushManager.getSubscription().then(function(subscription) {
      if (!subscription) {
        console.log("Cannot unsubscribe: No active subscription found in browser.");
        return;
      }

      var endpoint = subscription.endpoint;

      // 1. Unsubscribe from the Push Service (browser)
      return subscription.unsubscribe().then(function() {
        // 2. Remove subscription from the server
        removeSubscriptionFromServer(endpoint);
        console.log("User is unsubscribed from push service and server remove requested.");

        // 3. Update local state and UI
        isSubscribed = false;
        makeButtonSubscribable();
      });

    }).catch(function(error) {
      console.log("Error getting or unsubscribing from subscription:", error);
    });
  });
}

// --- UTILITY/SERVER FUNCTIONS (Unchanged for compatibility) ---

function getCookie(k) {
  var v = document.cookie.match('(^|;) ?' + k + '=([^;]*)(;|$)');
  return v ? v[2] : null
}

function sendSubscriptionToServer(endpoint, key, auth, expirationTime) {
  var encodedKey = btoa(String.fromCharCode.apply(null, new Uint8Array(key)));
  var encodedAuth = btoa(String.fromCharCode.apply(null, new Uint8Array(auth)));
  var hunchentoot = getCookie("hunchentoot-session");
  var currentSubscribeUrl = subscribeurl + "?hunchentoot-session=" + hunchentoot;

  $.ajax({
    type: "POST",
    url: currentSubscribeUrl,
    data: {
      publicKey: encodedKey,
      auth: encodedAuth,
      notificationEndPoint: endpoint,
      // --- NEW: Pass expirationTime to the backend ---
      expirationTime: expirationTime // This will be null or a timestamp
    },
    success: function(response) {
      console.log("Subscribed successfully! " + JSON.stringify(response));
      // Re-verify state after successful server update
      checkPushSubscription(); 
    },
    dataType: "json"
  });
}

function removeSubscriptionFromServer(endpoint) {
  $.ajax({
    type: "POST",
    url: unsubscribeurl,
    data: {
      notificationEndPoint: endpoint
    },
    success: function(response) {
      console.log("Unsubscribed successfully! " + JSON.stringify(response));
    },
    dataType: "json"
  });
}

function disableAndSetBtnMessage(message) {
  setBtnMessage(message);
  $("#btnPushNotifications").attr("disabled", "disabled");
}

function enableAndSetBtnMessage(message) {
  setBtnMessage(message);
  $("#btnPushNotifications").removeAttr("disabled");
}

function makeButtonSubscribable() {
  enableAndSetBtnMessage("Subscribe to push notifications");
  $("#btnPushNotifications")
    .addClass("btn-primary")
    .removeClass("btn-danger");
}

function makeButtonUnsubscribable() {
  enableAndSetBtnMessage("Unsubscribe from push notifications");
  $("#btnPushNotifications")
    .addClass("btn-danger")
    .removeClass("btn-primary");
}

function setBtnMessage(message) {
  $("#btnPushNotifications").text(message);
}

function urlB64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, "+")
    .replace(/_/g, "/");

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (var i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}


// Function to update a single cell in the status table
function updateUICell(id, content, isSuccess) {
    var element = $("#" + id);
    element.text(content);
    element.removeClass('text-success text-danger text-warning');
    
    if (isSuccess === true) {
        element.addClass('text-success');
    } else if (isSuccess === false) {
        element.addClass('text-danger');
    } else if (isSuccess === 'warning') {
        element.addClass('text-warning');
    }
}

// Function to update the main sync status panel
function updateSyncStatusPanel(message, type) {
    var panel = $("#sync-status-panel");
    panel.removeClass('alert-info alert-success alert-warning alert-danger');
    
    if (type === 'success') {
        panel.addClass('alert-success');
    } else if (type === 'warning') {
        panel.addClass('alert-warning');
    } else if (type === 'danger') {
        panel.addClass('alert-danger');
    } else {
        panel.addClass('alert-info');
    }
    
    $("#current-sync-message").text(message);
}

// Function to clear all table details
function clearAllUI() {
    updateUICell('browser-state', 'N/A', null);
    updateUICell('backend-state', 'N/A', null);
    updateUICell('browser-endpoint', 'N/A', null);
    updateUICell('backend-endpoint', 'N/A', null);
    updateUICell('browser-expiry', 'N/A', null);
    updateUICell('backend-expiry', 'N/A', null);
}
