/**
1;95;0c * Created by HighriseHub on 06-Jan-2021 
*/
const express = require('express');
const app = express();
require('dotenv').config();

var AWS = require('aws-sdk');
// Set region
AWS.config.update({region: process.env.AWS_REGION});
//var credentials = new AWS.SharedIniFileCredentials({profile: 'default'});
//AWS.config.credentials = credentials;


app.get("/sms/status", function(req, res) {
  res.send("HighriseHub AWS SNS SMS Server Running!");
});



app.get('/sms/sendsms', (req, res) => {

    console.log("Message = " + req.query.message);
    console.log("Number = " + req.query.number);

    var params = {
        'Message': req.query.message,
        'PhoneNumber': "+91" + req.query.number,
	'MessageAttributes': {
            'AWS.SNS.SMS.SenderID': {
                DataType: 'String',
                StringValue: 'HIGHUB'
            },
	    'AWS.SNS.SMS.SMSType' : {
		DataType : 'String',
		StringValue: 'Transactional'
            }
	    
	}
    };
    
    var publishTextPromise = new AWS.SNS({ apiVersion: '2010-03-31' }).publish(params).promise();

    publishTextPromise.then(
	function(data) {
	    console.log("MessageID is " + data.MessageId);
	    res.end();
	}).catch(
	    function(err) {
		console.error(err, err.stack);
		res.end();
	    });    
});

app.listen(4300, () => console.log('SMS Service Listening on PORT 4300'));
