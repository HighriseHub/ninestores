;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
;;(clsql:file-enable-sql-reader-syntax)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Create class dod-order-details-track
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(clsql:def-view-class dod-order-items-track ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   
(item-id
    :accessor odtk-order-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer
    :initarg :order-id)


(status 
    :accessor odtk-status
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 3)
    :initarg :status)


(updated-by
    :accessor odtk-updated-by
    :TYPE (string 70)
    :INITARG updated-by)   


 (remarks
    :ACCESSOR odtk-remarks 
    :type (string 70)
    :initarg :remarks)


    (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR order-track-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET nil)))

   
  (:BASE-TABLE dod_order_track))
