/**
1;95;0c * Created by Nine Stores on 09-Jun-2023 
March 4, 2025 - Modified the file upload to support customers, vendors, tenants and objects like orders, settings, products, etc. 
*/


import express from 'express';
import fs from 'fs';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { ListObjectsV2Command, DeleteObjectsCommand } from "@aws-sdk/client-s3";

import dotenv from 'dotenv';

dotenv.config();

const app = express();
const AUTH_SECRET = "ntstores1234"; //process.env.AUTH_SECRET;
const localfilePath = "/data/www/public/img/";


const s3 = new S3Client({
   region: process.env.AWS_REGION,
   credentials: {
   accessKeyId: process.env.AWS_S3_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_S3_SECRET_ACCESS_KEY
  },
});


app.get("/file/awss3v3/status", function(req, res) {
  res.send("Nine Stores AWS SDK V3 - S3 File Server Running!");
});

app.get('/file/awss3v3/upload', async (req, res) => {
  const now = new Date();
  const date = now.toDateString();
  const time = now.toTimeString();

  if (req.get('auth-secret') !== AUTH_SECRET) {
    console.log('Missing or incorrect auth-secret header. Rejecting request.');
    return res.status(401).send('Unauthorized');
  }

  const { tenantid, vendorid, customerid, objectname, objectid, uuid, filename, type } = req.query;

  if (!tenantid || !objectname || !objectid || !uuid || !filename || !type) {
    console.log('Missing required query parameters. Rejecting request.');
    return res.status(400).send('Bad Request: Missing required parameters');
  }

  if (!['customer', 'vendor'].includes(type.toLowerCase())) {
    console.log(`Invalid type: ${type}. Rejecting request.`);
    return res.status(400).send('Bad Request: Invalid type');
  }

  if (type.toLowerCase() === 'vendor' && !vendorid) {
    console.log('Missing vendorid for type=vendor. Rejecting request.');
    return res.status(400).send('Bad Request: Missing vendorid');
  }

  if (type.toLowerCase() === 'customer' && !customerid) {
    console.log('Missing customerid for type=customer. Rejecting request.');
    return res.status(400).send('Bad Request: Missing customerid');
  }

  const validObjectNames = ['ord', 'prd', 'cfg'];
  if (!validObjectNames.includes(objectname.toLowerCase())) {
    console.log(`Invalid objectname: ${objectname}. Rejecting request.`);
    return res.status(400).send('Bad Request: Invalid objectname');
  }

  let s3filePath;
  if (type.toLowerCase() === 'vendor') {
    s3filePath = `${tenantid}/vnd/${vendorid}/${objectname.toUpperCase()}/${objectid}/${uuid}`;
  } else {
    s3filePath = `${tenantid}/cust/${customerid}/${objectname.toUpperCase()}/${objectid}/${uuid}`;
  }

  console.log(`File upload path: ${s3filePath}`);

  const localfilename = localfilePath + filename;
  let fileContent;
  try {
    fileContent = fs.readFileSync(localfilename);
  } catch (err) {
    console.error(`Error reading file: ${localfilename}`, err);
    return res.status(500).send('Internal Server Error: Unable to read file');
  }

  const putCommand = new PutObjectCommand({
    Bucket: process.env.AWS_S3_BUCKET,
    Key: s3filePath,
    Body: fileContent,
  });

  try {
    await s3.send(putCommand);
    const fileUrl = `https://${process.env.AWS_S3_BUCKET}.s3.${process.env.AWS_REGION}.amazonaws.com/${s3filePath}`;
    console.log(`${date} ${time}: File uploaded successfully. ${fileUrl}`);
    res.send(fileUrl);
  } catch (err) {
    console.error(`Error uploading file to S3: ${err.message}`);
    res.status(500).send('Internal Server Error: Unable to upload file');
  }
});



// DELETE endpoint example
app.delete('/file/awss3v3/deletefiles', async (req, res) => {
  const now = new Date();
  const date = now.toDateString();
  const time = now.toTimeString();

  // Validate auth-secret header
  if (req.get('auth-secret') !== AUTH_SECRET) {
    console.log('Missing or incorrect auth-secret header. Rejecting request.');
    return res.status(401).send('Unauthorized');
  }

  // Extract query parameters
  const { tenantid, vendorid, customerid, objectname, objectid, type } = req.query;

  if (!tenantid || !objectname || !objectid || !type) {
    console.log('Missing required query parameters. Rejecting request.');
    return res.status(400).send('Bad Request: Missing required parameters');
  }

  if (!['customer', 'vendor'].includes(type.toLowerCase())) {
    console.log(`Invalid type: ${type}. Rejecting request.`);
    return res.status(400).send('Bad Request: Invalid type');
  }

  if (type.toLowerCase() === 'vendor' && !vendorid) {
    console.log('Missing vendorid for type=vendor. Rejecting request.');
    return res.status(400).send('Bad Request: Missing vendorid');
  }

  if (type.toLowerCase() === 'customer' && !customerid) {
    console.log('Missing customerid for type=customer. Rejecting request.');
    return res.status(400).send('Bad Request: Missing customerid');
  }

  const validObjectNames = ['ord', 'prd', 'cfg'];
  if (!validObjectNames.includes(objectname.toLowerCase())) {
    console.log(`Invalid objectname: ${objectname}. Rejecting request.`);
    return res.status(400).send('Bad Request: Invalid objectname');
  }

  // Build the S3 prefix path
  let s3Prefix;
  if (type.toLowerCase() === 'vendor') {
    s3Prefix = `${tenantid}/vnd/${vendorid}/${objectname.toUpperCase()}/${objectid}`;
  } else {
    s3Prefix = `${tenantid}/cust/${customerid}/${objectname.toUpperCase()}/${objectid}`;
  }

  console.log(`Attempting to delete files under path: ${s3Prefix}`);

  try {
    // Step 1: List objects under the prefix
    const listCommand = new ListObjectsV2Command({
      Bucket: process.env.AWS_S3_BUCKET,
      Prefix: s3Prefix,
    });

    const listResponse = await s3.send(listCommand);
    console.log('Files to be deleted are : ' + listResponse);

    if (!listResponse.Contents || listResponse.Contents.length === 0) {
      console.log('No files found to delete.');
      return res.status(404).send('No files found at specified path');
    }

    // Step 2: Prepare and send delete request
    const objectsToDelete = listResponse.Contents.map(obj => ({ Key: obj.Key }));

    const deleteCommand = new DeleteObjectsCommand({
      Bucket: process.env.AWS_S3_BUCKET,
      Delete: {
        Objects: objectsToDelete,
        Quiet: false,
      },
    });

    const deleteResponse = await s3.send(deleteCommand);
    console.log(`${date} ${time}: Deleted files:`, deleteResponse.Deleted);

    res.send({
      message: 'Files deleted successfully',
      deleted: deleteResponse.Deleted,
    });

  } catch (err) {
    console.error(`Error deleting files from S3: ${err.message}`);
    res.status(500).send('Internal Server Error: Unable to delete files');
  }
});

app.listen(4301, () => console.log('File server listening on PORT 4301'));
