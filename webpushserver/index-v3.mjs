/**
   1;95;0c * Created by HighriseHub on 16-Aug-2019
   Updated to AWS SDK V3 - May 2025. 
 */
// push-server.mjs
import express from 'express';
import bodyParser from 'body-parser';
import webPush from 'web-push';
import atob from 'atob';
import dotenv from 'dotenv';
import { inspect } from 'util';

dotenv.config();

const app = express();
let subscribers = [];

const VAPID_SUBJECT = process.env.VAPID_SUBJECT;
const VAPID_PUBLIC_KEY = process.env.VAPID_PUBLIC_KEY;
const VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY;
const AUTH_SECRET = process.env.AUTH_SECRET || "highrisehub1234";
const PORT = process.env.PORT || 4345;

const options = {
  TTL: 60 * 60 // 1 hour
};

if (!VAPID_SUBJECT || !VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY || !AUTH_SECRET) {
  console.error("Missing required environment variables.");
  process.exit(1);
}

webPush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("static"));

// Health Check
app.get("/push/status", (req, res) => {
  res.send("HighriseHub Browser Push Notification Server Running!");
});

// Send push to a single user
app.get("/push/notify/user", async (req, res) => {
  if (req.get("auth-secret") !== AUTH_SECRET) {
    console.warn("Unauthorized access attempt.");
    return res.sendStatus(401);
  }

  const {
    endpoint,
    publicKey,
    auth,
    message = "Welcome to Nine Stores!",
    clickTarget = "https://www.ninestores.in",
    title = "Push notification received!"
  } = req.query;

  const pushSubscription = {
    endpoint,
    keys: {
      p256dh: publicKey,
      auth
    }
  };

  subscribers.push(pushSubscription);

  const payload = JSON.stringify({ message, clickTarget, title });

  for (const sub of subscribers) {
    try {
      const response = await webPush.sendNotification(sub, payload, options);
      console.log("Push sent. Status:", inspect(response.statusCode));
    } catch (error) {
      console.error("Push failed. Error:", inspect(error));
    }
  }

  subscribers.pop(); // temporary push
  res.send("Notification sent!");
});

// Subscribe
app.post("/subscribe", (req, res) => {
  const { notificationEndPoint, publicKey, auth } = req.body;

  const pushSubscription = {
    endpoint: notificationEndPoint,
    keys: {
      p256dh: publicKey,
      auth
    }
  };

  console.log("New subscription:", JSON.stringify(pushSubscription));
  subscribers.push(pushSubscription);

  res.setHeader("Access-Control-Allow-Origin", "*");
  res.send("Subscription accepted!");
});

// Unsubscribe
app.post("/unsubscribe", (req, res) => {
  const { notificationEndPoint } = req.body;

  subscribers = subscribers.filter(s => s.endpoint !== notificationEndPoint);
  console.log(`Unsubscribed: ${notificationEndPoint}`);

  res.setHeader("Access-Control-Allow-Origin", "*");
  res.send("Subscription removed!");
});

app.listen(PORT, () => {
  console.log(`push_server listening on port ${PORT}`);
});
