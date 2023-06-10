/**
1;95;0c * Created by HighriseHub on 09-Jun-2023 
*/

const fs = require('fs');
const express = require('express');
const app = express();
require('dotenv').config();

var AWS = require('aws-sdk');

const s3 = new AWS.S3({
    accessKeyId: process.env.AWS_S3_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_S3_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION
})

//Auth secret used to authentication notification requests.
let AUTH_SECRET = "highrisehub1234"; //process.env.AUTH_SECRET;

// Set region
//AWS.config.update({region: process.env.AWS_REGION});
//var credentials = new AWS.SharedIniFileCredentials({profile: 'default'});
//AWS.config.credentials = credentials;
const filePath = "/data/www/public/img/temp/";


app.get("/file/status", function(req, res) {
  res.send("HighriseHub AWS S3 File Server Running!");
});



app.get('/file/upload', (req, res) => {

    if (req.get("auth-secret") != AUTH_SECRET) {
	console.log("Missing or incorrect auth-secret header. Rejecting request.");
	return res.sendStatus(401);
    }

    const fileName = filePath + req.query.filename;
    console.log("fileName = " + fileName);
    
    // Read content from the file
    const fileContent = fs.readFileSync(fileName);

    // Setting up S3 upload parameters
    const params = {
        Bucket: 'com.hhub.storage.resources',
        Key: req.query.filename, // File name you want to save as in S3
        Body: fileContent
    };

    // Uploading files to the bucket
    s3.upload(params, function(err, data) {
        if (err) {
            throw err;
        }
        console.log(`File uploaded successfully. ${data.Location}`);
	res.send(`${data.Location}`);
    });

});

app.listen(4301, () => console.log('File server listening on PORT 4301'));
