;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defclass CustomerAdapter (AdapterService)
  ())

(defclass CustomerDBService (DBAdapterService)
  ())

(defclass CustomerPresenter (PresenterService)
  ())

(defclass CustomerService (BusinessService)
  ())
(defclass CustomerHTMLView (HTMLView)
  ())

(defclass CustomerAddressJSONView (JSONView)
  ())
(defclass CustomerViewModel (ViewModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (password
    :initarg :password
    :accessor password)
   (salt
    :initarg :salt
    :accessor salt)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
   (company
    :initarg :company
    :accessor company)))




(defclass CustomerResponseModel (ResponseModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
   (company
    :initarg :company
    :accessor company)))
   

(defclass CustomerRequestModel (RequestModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (password
    :initarg :password
    :accessor password)
   (salt
    :initarg :salt
    :accessor salt)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
   (company
    :initarg :company
    :accessor company)))


(defclass CustomerSearchRequestModel (CustomerRequestModel)
  ())

(defclass Customer (BusinessObject)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (password
    :initarg :password
    :accessor password)
   (salt
    :initarg :salt
    :accessor salt)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
    (company
    :initarg :company
    :accessor company)))




