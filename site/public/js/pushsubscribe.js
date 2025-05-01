// === Push Notification URLs ===
var subscribeurl = "hhubvendsavepushsubscription";
var unsubscribeurl = "hhubvendremovepushsubscription";
var getvendsubscriptionurl = "hhubvendgetpushsubscription";

// === VAPID Public Key ===
var applicationServerPublicKey = "BBjBF5eKGs32lJVJ5DHaco9jRzIqwzKXhVdIaekVzx3_LW6KlLTsguiN3J2Tb3VQF1dJl8gLyubwCttsr_xu5jU";

// === Service Worker ===
var serviceWorkerName = "/js/serviceworker.js";

var isSubscribed = false;
var swRegistration = null;

// === Document Ready ===
$(document).ready(function () {
  // Remove push subscription
  $("#btnPushSubscriptionRemoveFromServer").click(function (e) {
    e.preventDefault();
    removeSubscriptionFromServer(""); // Server uses session to identify vendor
    console.log("Removing the push subscription from server");
  });

  // Handle push subscription toggle
  $("#btnPushNotifications").click(function (event) {
    if (Notification.permission === "granted") {
      initialiseServiceWorker();
      isSubscribed ? unsubscribe() : subscribe();
    } else {
      Notification.requestPermission().then(function (status) {
        if (status === "granted") {
          console.log("Permission granted");
          initialiseServiceWorker();
          subscribe();
        } else {
          console.log("Notification permission denied");
          disableAndSetBtnMessage("Notification permission denied");
        }
      });
    }
  });

  // Auto-initialize if already granted
  if (Notification.permission === "granted") {
    initialiseServiceWorker();
  }
});

// === Initialize Service Worker ===
function initialiseServiceWorker() {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker
      .register(serviceWorkerName)
      .then(handleSWRegistration)
      .catch(function (error) {
        console.error("Service Worker registration failed:", error);
        disableAndSetBtnMessage("SW registration failed");
      });
  } else {
    console.log("Service workers not supported");
    disableAndSetBtnMessage("Service workers unsupported");
  }
}

// === Handle SW Registration ===
function handleSWRegistration(reg) {
  console.log("Service Worker status:", reg.installing ? "installing" : reg.waiting ? "installed" : "active");
  swRegistration = reg;
  initialiseState(reg);
}

// === Check Push Subscription State ===
function initialiseState(reg) {
  if (!reg.showNotification) {
    console.log("Notifications unsupported on service workers");
    disableAndSetBtnMessage("Notifications unsupported");
    return;
  }

  if (!("PushManager" in window)) {
    console.log("Push messaging unsupported");
    disableAndSetBtnMessage("Push messaging unsupported");
    return;
  }

  checkPushSubscription();
}

// === Check Server and Local Push Subscription ===
function checkPushSubscription() {
  $.getJSON(getvendsubscriptionurl)
    .done(function (data) {
      if (data.success === 1 && Array.isArray(data.result)) {
        navigator.serviceWorker.ready.then(function (reg) {
          reg.pushManager.getSubscription().then(function (subscription) {
            if (!subscription) {
              console.log("Not yet subscribed to Push");
              isSubscribed = false;
              makeButtonSubscribable();
              return;
            }

            const matched = data.result.some(item => item.endpoint === subscription.endpoint);
            isSubscribed = matched;
            matched ? makeButtonUnsubscribable() : makeButtonSubscribable();
          }).catch(function (err) {
            console.log("Error during getSubscription()", err);
          });
        });
      }
    })
    .fail(function (jqXHR) {
      console.error("Failed to fetch push subscription", jqXHR.responseText);
    });
}

// === Subscribe ===
function subscribe() {
  navigator.serviceWorker.ready.then(function (reg) {
    const subscribeParams = {
      userVisibleOnly: true,
      applicationServerKey: urlB64ToUint8Array(applicationServerPublicKey)
    };

    reg.pushManager.subscribe(subscribeParams)
      .then(function (subscription) {
        const endpoint = subscription.endpoint;
        const expTime = subscription.expirationTime;
        const key = subscription.getKey("p256dh");
        const auth = subscription.getKey("auth");

        sendSubscriptionToServer(endpoint, key, auth);
        isSubscribed = true;
        makeButtonUnsubscribable();

        if (expTime) {
          console.log("Subscription expires at:", new Date(expTime));
        }
        console.log("Subscribed endpoint:", endpoint);
      })
      .catch(function (e) {
        console.error("Unable to subscribe to push.", e);
      });
  });
}

// === Unsubscribe ===
function unsubscribe() {
  navigator.serviceWorker.ready.then(function (reg) {
    reg.pushManager.getSubscription()
      .then(function (subscription) {
        if (!subscription) {
          console.log("No active subscription");
          return;
        }

        const endpoint = subscription.endpoint;
        return subscription.unsubscribe().then(function () {
          removeSubscriptionFromServer(endpoint);
          console.log("User unsubscribed:", endpoint);
          isSubscribed = false;
          makeButtonSubscribable();
        });
      })
      .catch(function (error) {
        console.error("Error during unsubscribe:", error);
      });
  });
}

// === Send Subscription to Server ===
function sendSubscriptionToServer(endpoint, key, auth) {
  const encodedKey = btoa(String.fromCharCode.apply(null, new Uint8Array(key)));
  const encodedAuth = btoa(String.fromCharCode.apply(null, new Uint8Array(auth)));
  const hunchentoot = getCookie("hunchentoot-session");

  $.ajax({
    type: "POST",
    url: subscribeurl + "?hunchentoot-session=" + hunchentoot,
    data: {
      publicKey: encodedKey,
      auth: encodedAuth,
      notificationEndPoint: endpoint
    },
    dataType: "json",
    success: function (response) {
      console.log("Subscribed successfully!", response);
    },
    error: function (xhr) {
      console.error("Error sending subscription to server", xhr.responseText);
    }
  });
}

// === Remove Subscription from Server ===
function removeSubscriptionFromServer(endpoint) {
  $.ajax({
    type: "POST",
    url: unsubscribeurl,
    data: { notificationEndPoint: endpoint },
    dataType: "json",
    success: function (response) {
      console.log("Unsubscribed successfully!", response);
    },
    error: function (xhr) {
      console.error("Error removing subscription from server", xhr.responseText);
    }
  });
}

// === Utility: Get Cookie ===
function getCookie(k) {
  const v = document.cookie.match('(^|;) ?' + k + '=([^;]*)(;|$)');
  return v ? v[2] : null;
}

// === UI Helpers ===
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
  $("#btnPushNotifications").addClass("btn-primary").removeClass("btn-danger");
}

function makeButtonUnsubscribable() {
  enableAndSetBtnMessage("Unsubscribe from push notifications");
  $("#btnPushNotifications").addClass("btn-danger").removeClass("btn-primary");
}

function setBtnMessage(message) {
  $("#btnPushNotifications").text(message);
}

// === Utility: VAPID Key Conversion ===
function urlB64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}
