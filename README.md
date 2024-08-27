This repository contains the common lisp source code for E-Commerce Stores, Digital Marketplaces. You can create your own e-commerce SAAS application where you can host your customers. Your site will provide e-commerce store building capabilities for Individual Sellers/Social groups/Small communities who want to buy/sell goods and services. Some of the salient features of this project are as under. 
There are two kinds of people involved in this marketplace. The Customers and Vendors. It has got all the features of e-commerce marketplace such as 

* Order Management & Fulfillment
* Product Subscriptions 
* Product listings, Product Discounts, Bundled Products (coming soon...)
* Basic Inventory control with Stock Management. 
* Warehouses (coming soon...) 
* Order Management for Vendors.
* Product Management for Vendors. 
* Multiple Vendors per order. 
* Vendors have access to multiple groups/communities.
* Shipping support - Free Shipping, 3rd Party Shipping providers support (iThinkLogistics), Flat rate & zone wise shipping rates and in store pickup. 
* Customer have access to multiple groups/communities. (coming soon...)  
* Standalone Vendor support. Using this feature, you can promote online selling for your own website. Visitors from your website will be forwarded to www.ninestores.in to create orders, make payments. You can copy the source code from this repository and create your own Digital Marketplace. 
* Payment modes supported are Online Payment using Payment Gateway, Cash On Demand and Prepaid Wallet and UPI payments. (For Indian Subcontinent Customers) 
* Progressive Web Application. 
* Browser Push Notification for Vendors. 
* SMS One Time Password - OTP for 2 Factor Authentication.   
* Support for Tag based or Attribute Based Access Control (ABAC) only for System Administrators.
* UI is built using Bootstrap 5.3 framework. 
* For a detailed list of features please visit https://www.ninestores.in/pricing

** How to setup the repository. **
* Procure a Ubuntu 20.02 server on Hyperscalers like AWS, GCP or MSFT Azure. 
* Hardware Requirements: A Medium speed server with 8 GB RAM and 100 GB Secondary storage. 
* We have hosted our site on AWS. You would need these AWS Services: EC2 for Compute, SES for Sending Email, SNS for sending SMS. (SMS sending in Indian subcontinent must be done in collaboration with VI https://www.vilpower.in/. This process is explained in details at AWS documentation https://docs.aws.amazon.com/sns/latest/dg/channels-sms-senderid-india.html. Will cost Rs.5900/per year with VI for registration.) 
* Install SBCL on Ubuntu 20.02. 
* Install Mysql 8.0
* Install C-compiler using sudo apt-get install build-essentials
* Install libmysqlclient if you want to run as a load balancing node in addition to the main server node. sudo apt-get install libmysqlclient. 
* Install libuv as we use async IO operations. sudo apt-get install libuv1-dev. 
* Install PM2 (Process Manager 2). sudo npm install pm2 -g. 
* Install Node.js for sending SMS, Webpush Notifications, S3 Bucket : sudo apt-get install nodejs, sudo apt-get install npm
* Install qrencode - sudo apt-get install qrencode 
* Install Quicklisp
* Setup Slime for using emacs as in IDE for lisp programming. 
* Load the load.lisp file, which will download all the necessary common lisp libraries and also compile them. 
* Start the website using (start-das) command. 




