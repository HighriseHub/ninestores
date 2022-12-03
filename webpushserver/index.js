/**
1;95;0c * Created by pawan deshpande on 16-Aug-2019 
 */
let express = require("express");
let webPush = require("web-push");
let atob = require("atob");
let bodyParser = require("body-parser");
let util = require("util");

let app = express();

let subscribers = [];

let VAPID_SUBJECT = process.env.VAPID_SUBJECT;
let VAPID_PUBLIC_KEY =  process.env.VAPID_PUBLIC_KEY; 
let VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY; 

const options = {
  // 1 hour in seconds.
  TTL: 60 * 60
};

//Auth secret used to authentication notification requests.
let AUTH_SECRET = "highrisehub1234"; //process.env.AUTH_SECRET;

if (!VAPID_SUBJECT) {
  return console.error("VAPID_SUBJECT environment variable not found.");
} else if (!VAPID_PUBLIC_KEY) {
  return console.error("VAPID_PUBLIC_KEY environment variable not found.");
} else if (!VAPID_PRIVATE_KEY) {
  return console.error("VAPID_PRIVATE_KEY environment variable not found.");
} else if (!AUTH_SECRET) {
  return console.error("AUTH_SECRET environment variable not found.");
}

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

webPush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

app.use(express.static("static"));

app.get("/push/status", function(req, res) {
  res.send("HighriseHub Browser Push Notification Server Running!");
});


app.get("/push/notify/user", function(req, res) {
    if (req.get("auth-secret") != AUTH_SECRET) {
    console.log("Missing or incorrect auth-secret header. Rejecting request.");
    return res.sendStatus(401);
  }

    let endpoint = req.query.endpoint; 
    let publicKey = req.query.publicKey; 
    let auth = req.query.auth;
    
    let pushSubscription = {
	endpoint: endpoint,
	keys: {
	    p256dh: publicKey,
	    auth: auth
	}
    };
    
    subscribers.push(pushSubscription);      
    
    let message = req.query.message || `Welcome to HighriseHub!`;
    let clickTarget = req.query.clickTarget || `http://www.highrisehub.com`;
    let title = req.query.title || `Push notification received!`;

  subscribers.forEach(pushSubscription => {
    //Can be anything you want. No specific structure necessary.
    let payload = JSON.stringify({
      message: message,
      clickTarget: clickTarget,
      title: title
    });

    webPush
      .sendNotification(pushSubscription, payload, options)
      .then(response => {
        console.log("Status : " + util.inspect(response.statusCode));
        console.log("Headers : " + JSON.stringify(response.headers));
        console.log("Body : " + JSON.stringify(response.body));
      })
      .catch(error => {
        console.log("Status : " + util.inspect(error.statusCode));
        console.log("Headers : " + JSON.stringify(error.headers));
        console.log("Body : " + JSON.stringify(error.body));
      });
  });

    subscribers.pop(); 
  res.send("Notification sent!");
});

/*

app.get("/push/notify/all", function(req, res) {
  if (req.get("auth-secret") != AUTH_SECRET) {
    console.log("Missing or incorrect auth-secret header. Rejecting request.");
    return res.sendStatus(401);
  }

    let message = req.query.message || `Welcome to HighriseHub!`;
    let clickTarget = req.query.clickTarget || `http://www.highrisehub.com`;
    let title = req.query.title || `Push notification received!`;

  subscribers.forEach(pushSubscription => {
    //Can be anything you want. No specific structure necessary.
    let payload = JSON.stringify({
      message: message,
      clickTarget: clickTarget,
      title: title
    });

    webPush
      .sendNotification(pushSubscription, payload, options)
      .then(response => {
        console.log("Status : " + util.inspect(response.statusCode));
        console.log("Headers : " + JSON.stringify(response.headers));
        console.log("Body : " + JSON.stringify(response.body));
      })
      .catch(error => {
        console.log("Status : " + util.inspect(error.statusCode));
        console.log("Headers : " + JSON.stringify(error.headers));
        console.log("Body : " + JSON.stringify(error.body));
      });
  });

  res.send("Notification sent!");
});


app.post("/subscribe", function(req, res) {
  let endpoint = req.body["notificationEndPoint"];
  let publicKey = req.body["publicKey"];
  let auth = req.body["auth"];

  let pushSubscription = {
    endpoint: endpoint,
    keys: {
      p256dh: publicKey,
      auth: auth
    }
  };
  console.log(
    "Received subscription request " + JSON.stringify(pushSubscription)
  );
  subscribers.push(pushSubscription);
  res.header("Access-Control-Allow-Origin", "*");
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept"
  );

  res.send("Subscription accepted!");
});

app.post("/unsubscribe", function(req, res) {
  let endpoint = req.body["notificationEndPoint"];

  subscribers = subscribers.filter(subscriber => {
    endpoint == subscriber.endpoint;
  });
  console.log("subscription removal request for " + endpoint);
  res.header("Access-Control-Allow-Origin", "*");
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept"
  );

  res.send("Subscription removed!");
});
*/

let PORT = 4345;
app.listen(PORT, function() {
  console.log(`push_server listening on port ${PORT}!`);
});
