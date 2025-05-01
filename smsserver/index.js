/**
1;95;0c * Created by HighriseHub on 06-Jan-2021 
Updated the SMS HEADER in Nov 2024.
Updated to AWS SDK V3 in May 2025. 
*/

const express = require('express');
const app = express();
require('dotenv').config();

const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

// Create SNS client
const snsClient = new SNSClient({ region: process.env.AWS_REGION });

app.get("/sms/status", function(req, res) {
  res.send("Nine Stores AWS SNS SMS Server Running!");
});

app.get('/sms/sendsms', async (req, res) => {
    const message = req.query.message;
    const number = req.query.number;

    console.log("Message = " + message);
    console.log("Number = " + number);

    const params = {
        Message: message,
        PhoneNumber: "+91" + number,
        MessageAttributes: {
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

    try {
        const command = new PublishCommand(params);
        const data = await snsClient.send(command);
        console.log("MessageID is " + data.MessageId);
        res.send(`Message sent with ID: ${data.MessageId}`);
    } catch (err) {
        console.error(err);
        res.status(500).send("Failed to send SMS");
    }
});

app.listen(4300, () => console.log('SMS Service Listening on PORT 4300'));

 

