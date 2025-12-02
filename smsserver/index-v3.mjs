/**
 * Converted to AWS SDK for JavaScript v3 (ESM syntax)
 * File: index-v3.mjs
 * * UPDATED to include current date and time in console logs.
 */

import express from 'express';
import * as dotenv from 'dotenv';
dotenv.config();

import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

const app = express();

const snsClient = new SNSClient({
    region: process.env.AWS_REGION
});

// Helper function to get a standardized timestamp
const getTimestamp = () => {
    return new Date().toISOString();
};

// --- Routes ---

app.get("/sms/status", (req, res) => {
    const timestamp = getTimestamp();
    console.log(`[${timestamp}] SMS Status Check: HighriseHub AWS SNS SMS Server Running! (v3 - ESM)`);
    res.send("Nine Stores AWS SNS SMS Server Running! (v3 - ESM)");
});

app.get('/sms/sendsms', async (req, res) => {
    const timestamp = getTimestamp();
    const message = req.query.message;
    const number = req.query.number;

    console.log(`[${timestamp}] --- NEW SMS REQUEST ---`);
    console.log(`[${timestamp}] Message = "${message}"`);
    console.log(`[${timestamp}] Number = "+91${number}"`);

    const params = {
        'Message': message,
        'PhoneNumber': "+91" + number,
        'MessageAttributes': {
            'AWS.SNS.SMS.SenderID': {
                DataType: 'String',
                StringValue: process.env.SENDERID
            },
            'AWS.MM.SMS.TemplateId': {
                DataType: 'String',
                StringValue: process.env.TEMPLATEID
            },
            'AWS.MM.SMS.EntityId': {
                DataType: 'String',
                StringValue: process.env.ENTITYID
            },
            'AWS.SNS.SMS.SMSType': {
                DataType: 'String',
                StringValue: 'Transactional'
            }
        }
    };

    const command = new PublishCommand(params);

    try {
        const data = await snsClient.send(command);

        console.log(`[${timestamp}] SUCCESS: MessageID is ${data.MessageId}`);
        console.log(`[${timestamp}] -------------------------`);
        res.end();
    } catch (err) {
        console.error(`[${timestamp}] ERROR: SMS sending failed.`);
        console.error(err, err.stack);
        console.log(`[${timestamp}] -------------------------`);
        res.status(500).send("SMS sending failed: " + err.message); 
    }
});

// --- Server Start ---

const PORT = 4300;
app.listen(PORT, () => console.log(`[${getTimestamp()}] SMS Service Listening on PORT ${PORT}`));
