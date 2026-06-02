;;; nst-dal-pincodes.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(clsql:def-view-class dod-india-pincodes ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :column "row_id"
    :type integer
    :initarg :row-id)
   
   (pincode
    :column "pincode"
    :type integer
    :initarg :pincode)
   
   (office-name
    :column "officename"
    :type (string 100)
    :initarg :office-name)
   
   (office-type
    :column "officetype"
    :type (string 10)
    :initarg :office-type)
   
   (delivery
    :column "delivery"
    :type (string 50)
    :initarg :delivery)
   
   (district
    :column "district"
    :type (string 100)
    :initarg :district)
   
   (state-name
    :column "statename"
    :type (string 100)
    :initarg :state-name)
   
   (division-name
    :column "divisionname"
    :type (string 100)
    :initarg :division-name)
   
   (region-name
    :column "regionname"
    :type (string 100)
    :initarg :region-name)
   
   (circle-name
    :column "circlename"
    :type (string 100)
    :initarg :circle-name)
   
   (latitude
    :column "latitude"
    :type double-float ; Maps from decimal(8,6)
    :initarg :latitude)
   
   (longitude
    :column "longitude"
    :type double-float ; Maps from decimal(9,6)
    :initarg :longitude))
  (:base-table "DOD_INDIA_PINCODES"))
