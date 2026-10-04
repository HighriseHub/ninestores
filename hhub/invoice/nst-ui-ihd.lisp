;;; nst-ui-ihd.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun render-tax-summary-html (breakdown)
  "Generates the HTML table for the GST breakdown with a Grand Total row."
  (let ((sorted-entries (get-sorted-summary breakdown))
        (interstate (interstate-p breakdown))
        ;; Initialize accumulators for the footer
        (total-taxable 0)
        (total-cgst 0)
        (total-sgst 0)
        (total-igst 0))
    (function (lambda ()
      (cl-who:with-html-output-to-string (s nil :prologue nil :indent t)
	(:div :class "gst-breakdown-container" :style "margin-top: 20px;"
              (:table :class "gst-table" :style "width:100%; border-collapse: collapse; font-size: 12px;" :border "1"
		      (:thead
		       (:tr :style "background-color: #f2f2f2;"
			    (:th "HSN/SAC")
			    (:th "Taxable Value")
			    (if interstate
				(cl-who:htm (:th "IGST Rate") (:th "IGST Amount"))
				(cl-who:htm (:th "CGST Rate") (:th "CGST Amount")
					    (:th "SGST Rate") (:th "SGST Amount")))
			    (:th "Total Tax")))
		      (:tbody
		       (dolist (entry sorted-entries)
			 (let ((row-tax (+ (cgst-amount entry) (sgst-amount entry) (igst-amount entry))))
			   ;; Increment totals
			   (incf total-taxable (taxable-value entry))
			   (incf total-cgst    (cgst-amount entry))
			   (incf total-sgst    (sgst-amount entry))
			   (incf total-igst    (igst-amount entry))
			   (cl-who:htm
			    (:tr
			     (:td (cl-who:str (hsn-code entry)))
			     (:td :align "right" (cl-who:fmt "~,2F" (taxable-value entry)))
			     (if interstate
				 (cl-who:htm 
				  (:td :align "center" (cl-who:fmt "~A%"  (igst-rate entry)))
				  (:td :align "right" (cl-who:fmt "~,2F"  (igst-amount entry))))
				 (cl-who:htm
				  (:td :align "center" (cl-who:fmt "~A%" (cgst-rate entry)))
				  (:td :align "right" (cl-who:fmt "~,2F" (cgst-amount entry)))
				  (:td :align "center" (cl-who:fmt "~A%" (sgst-rate entry)))
				  (:td :align "right" (cl-who:fmt "~,2F" (sgst-amount entry)))))
			     (:td :align "right" (cl-who:fmt "~,2F" row-tax)))))))
		      ;; Grand Total Footer
		      (:tfoot
		       (:tr :style "font-weight: bold; background-color: #eee;"
			    (:td "Total")
			    (:td :align "right" (cl-who:fmt "~,2F" total-taxable))
			    (if interstate
				(cl-who:htm 
				 (:td "") ; Empty Rate cell
				 (:td :align "right" (cl-who:fmt "~,2F" total-igst)))
				(cl-who:htm
				 (:td "") (:td :align "right" (cl-who:fmt "~,2F"  total-cgst))
				 (:td "") (:td :align "right" (cl-who:fmt "~,2F"  total-sgst))))
			    (:td :align "right" 
				 (cl-who:fmt "~,2F" (+ total-cgst total-sgst total-igst))))))))))))



(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun render-invoice-settings-menu ()
    (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)
      (:div :class "offcanvas offcanvas-end" :tabindex"-1" :id "idInvoiceSettingsOffCanvas" :aria-labelledby "idInvoiceSettingsOffCanvasLabel" :style  "background: rgb(222,228,255);
background: linear-gradient(171deg, rgba(222,228,255,1) 0%, rgba(224,236,255,1) 100%); "
	    (:div :class "offcanvas-header"
		  (:img :src "/img/logo.png" :alt "" :width "32" :height "32" :class "rounded-circle me-2")
		  (:h5 :class "offcanvas-title" :id "idInvoiceSettingsOffCanvasLabel" "Invoice Settings")
		  (:button :type "button" :class "btn-close btn-close" :data-bs-dismiss "offcanvas" :aria-label "Close"))
	    (:div :class "offcanvas-body"
		  (:ul :class "nav nav-tabs flex-column mb-auto"
		       (:li :class "nav-item"
			    (:a :href "displayinvoices"
				(:i :class "fa-solid fa-house")  "&nbsp;&nbsp;Invoices"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " General Invoice Settings"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " Design & Branding"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " Payment & Sharing"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " Notifications & Alerts"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " Advanced Settings"))
		       
		       (:li :class "nav-item"
			    (:a :href "/hhub/hhubvendorupitransactions"  :class "nav-link link-body-e mphasis"
				(:i :class "fa-solid fa-gear")  " Customer Management"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/hhubvendmycustomers" :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear") " Reporting & Analytics"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear") " Security"))))))))


(defun com-hhub-transaction-invoice-settings-page ()
  (with-vend-session-check
    (with-mvc-ui-page "Invoice Settings Page" #'create-model-for-invoicesettingspage #'create-widgets-for-invoicesettingspage :role :vendor)))

(defun create-model-for-invoicesettingspage ()
  (let* ((vinvsettings (hunchentoot:session-value :login-vendor-invoice-settings))
	 (printsettings (cdr (assoc 'invoice-print-settings vinvsettings :test 'equal)))
	 (vinvsettingshtml (funcall (nst-get-cached-invoice-template-func :templatenum 14)))
	 (idinvsettings (format nil "idvinvsettings~A" (gensym))))

    ;; the template takes the logo block first (its own form) and the print settings form second
    (setf vinvsettingshtml (format nil vinvsettingshtml
				   (invoiceprintsettingslogowidgethtml printsettings)
				   (invoiceprintsettingswidgethtml printsettings)))
    (function (lambda ()
      (values idinvsettings vinvsettingshtml)))))

(defun create-widgets-for-invoicesettingspage (modelfunc)
  (multiple-value-bind (idinvsettings vinvsettingshtml) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-catch-submit-event idinvsettings
			 (cl-who:str vinvsettingshtml)))))))
      (list widget1))))



(defun invoiceprintsettingentry (settings keyname)
  :documentation "The (key . value) cons for KEYNAME in an invoice settings alist. Keys are matched on their name with hyphens removed, because the shipped *invoice-settings* defaults use plain symbols (logo-path) while a vendor's settings saved from the settings page round-trip through JSON and come back as hyphen-less keywords (:LOGOPATH)."
  (let ((wanted (remove #\- (string-upcase keyname))))
    (assoc wanted settings
	   :test (lambda (name key)
		   (and (symbolp key) (string= name (remove #\- (symbol-name key))))))))

(defun invoiceprintsettingvalue (printsettings keyname)
  :documentation "Value of KEYNAME in an invoice settings alist, see invoiceprintsettingentry. The shipped defaults are written as (key value) lists while saved settings are (key . value) pairs, so a single element list is unwrapped to the value it carries. A single element section such as ((:LOGOPATH . \"...\")) carries a cons or a keyword and is returned as it is, otherwise reading a section that happens to hold one entry would return the entry instead of the section."
  (let ((value (cdr (invoiceprintsettingentry printsettings keyname))))
    (if (and (consp value) (null (cdr value))
	     (atom (car value)) (not (keywordp (car value))))
	(car value)
	;;else
	value)))

(defun nst-get-vendor-invoiceprintsettings (&optional vendor)
  :documentation "The invoice-print-settings alist of VENDOR, falling back to the shipped *invoice-settings* defaults."
  (let* ((vendor (or vendor (get-login-vendor)))
	 (settingsstr (and vendor (slot-value vendor 'invoice-settings)))
	 (settings (if (and settingsstr (> (length settingsstr) 0))
		       (read-from-string settingsstr)
		       ;;else
		       *invoice-settings*)))
    (or (cdr (assoc 'invoice-print-settings settings :test 'equal))
	(cdr (assoc 'invoice-print-settings *invoice-settings* :test 'equal)))))

(defun nst-invoice-logo-url (logopath)
  :documentation "URL the invoice logo is served from : an absolute URL is used as it is, a site relative path is prefixed with *siteurl*, and an empty value falls back to the site logo."
  (let ((logo (if (and (stringp logopath) (> (length logopath) 0)) logopath *HHUBDEFAULTLOGOIMG*)))
    (if (cl-ppcre:scan "^https?://" logo)
	logo
	;;else
	(format nil "~A~A" *siteurl* logo))))

(defun nst-invoice-logo-image-tag (logopath)
  :documentation "An <img> tag for the vendor's invoice logo, see nst-invoice-logo-url."
  (format nil "<img src=\"~A\" alt=\"Logo\" style=\"max-height: 80px; max-width: 100%;\" />" (nst-invoice-logo-url logopath)))

(defun nst-vendor-logo-objectid-from-url (logourl vendor-id tenant-id)
  :documentation "The S3 object id of a previously uploaded vendor logo, parsed out of the URL the node file server returned, or NIL when LOGOURL is not an upload of this vendor. The file server keys vendor uploads as <tenantid>/vnd/<vendorid>/CFG/<objectid>/<uuid>."
  (let ((segments (and (stringp logourl) (cl-ppcre:split "/" logourl))))
    (if (and segments (> (length segments) 8)
	     (string= (nth 4 segments) "vnd")
	     (string= (nth 3 segments) (format nil "~A" tenant-id))
	     (string= (nth 5 segments) (format nil "~A" vendor-id))
	     (string= (nth 6 segments) "CFG"))
	(nth 7 segments))))

(defun nst-upload-vendor-logo (file-name vendor-id tenant-id previouslogourl)
  :documentation "Uploads FILE-NAME to the vendor's area of the S3 bucket the file server is configured with, and returns the URL to store, or NIL when the upload did not succeed. objectname has to stay CFG (the file server only accepts ord, prd and cfg) and the object id is vendor scoped and unique per upload, so the logo already in use survives a failed upload. The superseded object is deleted only after the new upload has been confirmed."
  (if *HHUBUSELOCALSTORFORRES*
      ;; local storage mode : the file already sits in the public image directory
      (format nil "/img/~A" file-name)
      ;;else upload to S3 through the node file server
      (let ((objectid (format nil "vlogo-~A-~A" vendor-id (get-universal-time))))
	(multiple-value-bind (body status)
	    (vendor-upload-file-s3bucket file-name "CFG" objectid vendor-id tenant-id)
	  (if (and status (<= 200 status 299))
	      (let ((logourl (if (stringp body) body (map 'string #'code-char body))))
		(let ((previousobjectid (nst-vendor-logo-objectid-from-url previouslogourl vendor-id tenant-id)))
		  (if (and previousobjectid (not (string= previousobjectid objectid)))
		      (handler-case (vendor-delete-files-s3bucket "CFG" previousobjectid vendor-id tenant-id)
			(error (e) (hhub-log-message (format nil "could not delete the superseded invoice logo ~A of vendor ~A : ~A~%" previouslogourl vendor-id e))))))
		logourl)
	      ;;else the response body is an error message, never a logo location
	      (progn
		(hhub-log-message (format nil "invoice logo upload failed for vendor ~A : status ~A response ~A~%" vendor-id status body))
		nil))))))

(defun nst-vendor-invoicesettings (&optional vendor)
  :documentation "The VENDOR's stored invoice settings alist, or a copy of the shipped *invoice-settings* defaults when the vendor has none. The copy is what keeps a save from mutating the shared default that every other vendor falls back to."
  (let* ((vendor (or vendor (get-login-vendor)))
	 (settingsstr (and vendor (slot-value vendor 'invoice-settings))))
    (if (and settingsstr (stringp settingsstr) (> (length settingsstr) 0))
	(read-from-string settingsstr)
	;;else
	(copy-tree *invoice-settings*))))

(defun nst-set-invoiceprintsetting (printsettings sectionname keyname value)
  :documentation "Sets SECTIONNAME.KEYNAME to VALUE in a print settings alist, creating the section or the entry when the alist does not carry it yet. Returns the print settings."
  (let ((section (invoiceprintsettingentry printsettings sectionname)))
    (if section
	(let ((entry (invoiceprintsettingentry (cdr section) keyname)))
	  (if entry
	      (setf (cdr entry) value)
	      ;;else
	      (setf (cdr section) (acons (intern (string-upcase keyname) :keyword) value (cdr section)))))
	;;else
	(push (cons (intern (string-upcase sectionname) :keyword)
		    (list (cons (intern (string-upcase keyname) :keyword) value)))
	      printsettings))
    printsettings))

(defun nst-save-vendor-invoiceprintsetting (sectionname keyname value &optional vendor)
  :documentation "Persists one invoice print setting for VENDOR in the vendor row and the session, leaving the other settings as they are."
  (let* ((vendor (or vendor (get-login-vendor)))
	 (settings (nst-vendor-invoicesettings vendor))
	 (printsettings (or (cdr (assoc 'invoice-print-settings settings :test 'equal))
			    (copy-tree (cdr (assoc 'invoice-print-settings *invoice-settings* :test 'equal)))))
	 (section (assoc 'invoice-print-settings settings :test 'equal)))
    (setf printsettings (nst-set-invoiceprintsetting printsettings sectionname keyname value))
    (if section
	(setf (cdr section) printsettings)
	;;else
	(push (cons 'invoice-print-settings printsettings) settings))
    (setf (slot-value vendor 'invoice-settings) (write-to-string settings :readably t))
    (setf (hunchentoot:session-value :login-vendor-invoice-settings) settings)
    (update-vendor-details vendor)
    value))

(defun nst-get-vendor-invoicetemplatenum (&optional vendor)
  :documentation "Invoice template number the VENDOR chose in the invoice settings page. Falls back to *NST-GSTINVOICE-DEFAULTTEMPLATENUM* when the vendor never chose one, and validates the stored value against *NST-GSTINVOICE-TEMPLATES-HT* so a stale number can never be handed to nst-get-cached-invoice-template-func."
  (let* ((printsettings (nst-get-vendor-invoiceprintsettings vendor))
	 (stored (invoiceprintsettingvalue printsettings "DEFAULTINVOICETEMPLATENUM"))
	 (storedstr (if stored (format nil "~A" stored))))
    (if (and storedstr (gethash storedstr *NST-GSTINVOICE-TEMPLATES-HT*))
	(parse-integer storedstr)
	;;else
	*NST-GSTINVOICE-DEFAULTTEMPLATENUM*)))

(defun invoiceprintsettingslogowidgethtml (printsettings)
  :documentation "The invoice logo block. It renders its own form (the upload dialog) above the print settings form, because a file input cannot be posted through the ajax serialize() path the settings form uses - and a form must not be nested inside another form."
  (let ((logopath (invoiceprintsettingvalue (invoiceprintsettingvalue printsettings "HEADER") "LOGOPATH")))
    (cl-who:with-html-output-to-string (*standard-output* nil)
      (:div :class "mb-3"
	    (:label :class "form-label" "Invoice Logo")
	    (:div :class "mt-2" :data-bs-toggle "tooltip" :title "Upload Invoice Logo"
		  (:a :href "#" :data-bs-toggle "modal" :data-bs-target "#nstinvoicelogoupload-modal"
		      (:i :class "fa-solid fa-upload"))
		  ;; an absolute URL is what the upload stores, anything else is the shipped default
		  (if (and (stringp logopath) (> (length logopath) 0))
		      (cl-who:htm
		       (if (cl-ppcre:scan "^https?://" logopath)
			   (cl-who:htm (:span :class "badge bg-success ms-2" "Uploaded"))
			   ;;else
			   (cl-who:htm (:span :class "badge bg-secondary ms-2" "Current logo"))))
		      ;;else
		      (cl-who:htm (:span :class "form-text text-muted ms-2" "No logo uploaded yet - the site logo is used."))))
	    (if (and (stringp logopath) (> (length logopath) 0))
		(cl-who:htm
		 (:img :src (nst-invoice-logo-url logopath) :alt "Logo"
		       :style "max-height: 60px; max-width: 100%; display: block; margin-top: 4px;")
		 (:div :class "form-text" :style "word-break: break-all;" (cl-who:str logopath))))
	    (modal-dialog-v2 "nstinvoicelogoupload-modal" "Upload Invoice Logo" (nst-invoice-logo-upload-dialog-html))))))

(defun invoiceprintsettingswidgethtml (printsettings)
  (let ((papersize-ht (make-hash-table :test 'equal))
	(orientation-ht (make-hash-table :test 'equal))
	(papersize (cdr (assoc :DEFAULTPAPERSIZE printsettings :test 'equal)))
	(orientation (cdr (assoc :ORIENTATION printsettings :test 'equal)))
	(fontsize (cdr (assoc :FONTSIZE printsettings :test 'equal)))
	(margintop (cdr (assoc :TOP (cdr (assoc :MARGIN printsettings :test 'equal)))))
	(marginbottom (cdr (assoc :BOTTOM (cdr (assoc :MARGIN printsettings :test 'equal)))))
	(marginleft (cdr (assoc :LEFT (cdr (assoc :MARGIN printsettings :test 'equal)))))
	(marginright (cdr (assoc :RIGHT (cdr (assoc :MARGIN printsettings :test 'equal)))))
	(headerenable (cdr (assoc :ENABLE (cdr (assoc :HEADER printsettings :test 'equal)))))
	(headertext (cdr (assoc :TEXT (cdr (assoc :HEADER printsettings :test 'equal)))))
	(headerlogopath (invoiceprintsettingvalue (invoiceprintsettingvalue printsettings "HEADER") "LOGOPATH"))
	(footerenable (cdr (assoc :ENABLE (cdr (assoc :FOOTER printsettings :test 'equal)))))
	(footertext (cdr (assoc :TEXT (cdr (assoc :FOOTER printsettings :test 'equal)))))
	(watermarkenable (cdr (assoc :ENABLE (cdr (assoc :WATERMARK printsettings :test 'equal)))))
	(watermarktext (cdr (assoc :TEXT (cdr (assoc :WATERMARK printsettings :test 'equal)))))
	(invoicetemplatenum (or (invoiceprintsettingvalue printsettings "DEFAULTINVOICETEMPLATENUM")
				*NST-GSTINVOICE-DEFAULTTEMPLATENUM*)))
	
    
    (setf (gethash "A4" papersize-ht) "A4")
    (setf (gethash "Letter" papersize-ht) "Letter")
    (setf (gethash "Legal" papersize-ht) "Legal")
    (setf (gethash "Portrait" orientation-ht) "Portrait")
    (setf (gethash "Landscape" orientation-ht) "Landscape")
    
    (cl-who:with-html-output-to-string (*standard-output* nil)
      ;;<!-- Default Invoice Template -->
      (:div :class "mb-3"
	    (:label :for "iddefaultinvoicetemplatenum" :class "form-label" "Default Invoice Template")
	    (with-html-dropdown "defaultinvoicetemplatenum" *NST-GSTINVOICE-TEMPLATES-HT* (format nil "~A" invoicetemplatenum)))

      ;;<!-- Default Paper Size -->
      (:div :class "mb-3"
	    (:label :for "defaultpapersize" :class "form-label" "Default Paper Size")
	    (with-html-dropdown "defaultpapersize" papersize-ht papersize))

      ;; orientation
          (:div :class "mb-3"
		(:label :for "orientation" :class "form-label" "Orientation")
		(with-html-dropdown "orientation" orientation-ht orientation))
      ;; Fontsize
      (:div :class "mb-3"
	    (:label :for "fontsize" :class "form-label" "Font Size")
	    (:input :type "number" :class "form-control" :id "fontsize" :value fontsize))

      ;; Margins
      
      (:div :class "mb-3"
	    (:label :class "form-label" "Margins (in cm)")
	    (:div :class "row g-2"
		  (:div :class "col" 
			(:label :for "margintop" :class "form-label" "Top")
			(:input :type "text" :class "form-control" :id "margintop" :value margintop))
		  (:div :class "col" 
			(:label :for "marginbottom" :class "form-label" "Bottom")
			(:input :type "text" :class "form-control" :id "marginbottom" :value marginbottom))
		  (:div :class "col" 
			(:label :for "marginleft" :class "form-label" "Left")
			(:input :type "text" :class "form-control" :id "marginleft" :value marginleft))
		  (:div :class "col" 
			(:label :for "marginright" :class "form-label" "Right")
			(:input :type "text" :class "form-control" :id "marginright" :value marginright))))
      ;; Header
      (:div :class "mb-3"
	    (:label :class "form-label" "Header")
      	    (:div :class "form-check form-switch"
		  (if headerenable
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "headerenable" :checked  T))
		      ;;else
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "headerenable")))
		       
		  (:label :class "form-check-label" :for "headerenable" "Enable Header"))
	    (:div :class "mt-2"
		  (:label :for "headertext" :class "form-label" "Header Text")
		  (:input :type "text" :class "form-control" :id "headertext" :value headertext))
	    ;; The logo lives in its own form, rendered above this one by
	    ;; invoiceprintsettingslogowidgethtml. This form only carries the URL, so that the
	    ;; settings payload the browser submits contains the logo chosen in the dialog.
	    (:div :class "mt-2"
		  (:label :for "headerlogopath" :class "form-label" "Logo Path")
		  (:input :type "hidden" :name "headerlogopath" :id "headerlogopath" :value (or headerlogopath ""))
		  (:div :class "form-text text-muted" "Use the Invoice Logo upload above to set or replace it.")))
      ;; Footer
      (:div :class "mb-3"
	    (:label :class "form-label" "Footer")
      	    (:div :class "form-check form-switch"
		  (if footerenable
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "footerenable" :checked  T))
		      ;;else
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "footerenable")))
		  (:div :class "mt-2"
		  (:label :for "footertext" :class "form-label" "Footer Text")
		  (:input :type "text" :class "form-control" :id "footertext" :value footertext))))
      ;; Watermark
      (:div :class "mb-3"
	    (:label :class "form-label" "Watermark")
      	    (:div :class "form-check form-switch"
		  (if watermarkenable
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "watermarkenable" :checked  T))
		      ;;else
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "watermarkenable")))
		  (:div :class "mt-2"
		  (:label :for "watermarktext" :class "form-label" "Watermark Text")
		  (:input :type "text" :class "form-control" :id "watermarktext" :value watermarktext))))
      )))

(defun nst-invoice-logo-upload-dialog-html ()
  :documentation "The invoice logo upload form shown in a modal dialog on the settings page. It posts to its own transaction as multipart through submitfileuploadevent, because the ajax serialize() path used by the other forms drops file inputs."
  (with-catch-file-upload-event "nstinvoicelogoupload"
    (with-html-form "nstinvoicelogouploadform" "vuploadinvoicelogoaction"
      (:div :class "form-group"
	    (:label :for "idnstlogofileupldctrl" "Select the invoice logo (PNG or JPEG, under 1 MB)")
	    (:input :id "idnstlogofileupldctrl" :class "form-control" :name "headerlogopath" :type "file"))
      (:div :class "form-group"
	    (:button :id "btnnstlogoupload" :class "btn btn-lg btn-primary btn-block" :type "submit" "Upload Logo")))))

(defun com-hhub-transaction-vendor-upload-invoice-logo-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui #'create-model-for-vuploadinvoicelogo #'create-widgets-for-genericredirect)))

(defun create-model-for-vuploadinvoicelogo ()
  :documentation "Uploads the invoice logo the vendor picked in the settings dialog. This is the only place the logo is sent to S3 : the settings save itself never uploads."
  (let* ((vendor (get-login-vendor))
	 (vendor-id (get-login-vendor-id))
	 (tenant-id (get-login-vendor-tenant-id))
	 (logoparams (hunchentoot:post-parameter "headerlogopath"))
	 (tempfilewithpath (first logoparams))
	 (file-name (if tempfilewithpath (process-file logoparams *HHUBRESOURCESDIR*)))
	 (previouslogourl (invoiceprintsettingvalue
			   (invoiceprintsettingvalue (nst-get-vendor-invoiceprintsettings vendor) "HEADER")
			   "LOGOPATH"))
	 (uploadedlogourl (if tempfilewithpath
			      (nst-upload-vendor-logo file-name vendor-id tenant-id previouslogourl)))
	 (redirecturl "/hhub/vinvoicesettingspage"))
    (if uploadedlogourl
	;; store the new logo straight away, so the settings page comes back carrying it and a save
	;; that follows cannot lose it
	(nst-save-vendor-invoiceprintsetting "HEADER" "LOGOPATH" uploadedlogourl vendor)
	;;else
	(hhub-log-message (format nil "invoice logo upload produced no logo for vendor ~A (uploaded file ~A)~%" vendor-id file-name)))
    (function (lambda ()
      (values redirecturl)))))

(defun com-hhub-transaction-save-invoice-print-settings-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui #'create-model-for-invoiceprintsettingsaction #'create-widgets-for-genericredirect)))

(defun create-model-for-invoiceprintsettingsaction ()
  (let* ((vendor (get-login-vendor))
	 (vendor-id (get-login-vendor-id))
	 (tenant-id (get-login-vendor-tenant-id))
	 (printsettings (hunchentoot:parameter "vinvprintsettings"))
	 ;; the settings form carries its payload in this hidden field; the page's saveSettings()
	 ;; fills it. An empty payload means that never happened, so decode only a real payload
	 ;; instead of letting cl-json signal end-of-file on an empty stream.
	 (json-response (if (and printsettings (> (length printsettings) 0))
			    (handler-case (with-input-from-string (stream printsettings) (cl-json:decode-json stream))
			      (error (e)
				(hhub-log-message (format nil "could not decode vinvprintsettings payload for vendor ~A: ~A~%" vendor-id e))
				nil))
			    ;; else
			    (progn
			      (hhub-log-message (format nil "invoice print settings save called without a vinvprintsettings payload for vendor ~A~%" vendor-id))
			      nil)))
	 (redirecturl "/hhub/vinvoicesettingspage"))
    (if (null json-response)
	;; nothing to save : go back to the settings page with the stored settings untouched
	(function (lambda ()
	  (values redirecturl)))
	;; else
	(progn
	  ;; The logo is uploaded by the settings dialog through vuploadinvoicelogoaction, so this
	  ;; request only stores the URL the page carries in its headerlogopath field. When the page
	  ;; carries none, the logo already stored is kept rather than wiped.
	  (let* ((storedsettings (nst-vendor-invoicesettings vendor))
		 (storedprintsettings (or (cdr (assoc 'invoice-print-settings storedsettings :test 'equal))
					  (copy-tree (cdr (assoc 'invoice-print-settings *invoice-settings* :test 'equal)))))
		 (postedlogourl (invoiceprintsettingvalue (invoiceprintsettingvalue json-response "HEADER") "LOGOPATH"))
		 (storedlogourl (invoiceprintsettingvalue (invoiceprintsettingvalue storedprintsettings "HEADER") "LOGOPATH"))
		 (logotostore (if (and (stringp postedlogourl) (> (length postedlogourl) 0)
				       (not (cl-ppcre:scan "fakepath" postedlogourl)))
				  postedlogourl
				  ;;else keep the logo already stored
				  (or storedlogourl "")))
		 (section (assoc 'invoice-print-settings storedsettings :test 'equal)))
	    (setf json-response (nst-set-invoiceprintsetting json-response "HEADER" "LOGOPATH" logotostore))
	    (if section
		(setf (cdr section) json-response)
		;;else
		(push (cons 'invoice-print-settings json-response) storedsettings))
	    (setf (slot-value vendor 'invoice-settings) (write-to-string storedsettings :readably t))
	    (setf (hunchentoot:session-value :login-vendor-invoice-settings) storedsettings)
	    (update-vendor-details vendor))
	  (function (lambda ()
	    (values redirecturl)))))))





(defun com-hhub-transaction-copy-invoice ()
  )

(defun com-hhub-transaction-download-invoice()
  (with-vend-session-check
    (with-mvc-redirect-ui #'create-model-for-downloadinvoice #'create-widgets-for-genericredirect)))

(defun create-model-for-downloadinvoice ()
  (let* ((sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (invnum (slot-value sessioninvheader 'invnum))
	 ;; Minted here rather than read from EXTERNAL_URL : the stored link carries no
	 ;; render marker AND is five minutes old at best, so the fetch would come back
	 ;; with either the password prompt or an expiry page instead of the invoice.
	 (external-url (generate-invoice-ext-url invnum (get-login-vendor) (get-login-vendor-company) :render t))
	 (htmlfile (downloadhtmlfile external-url))
	 (pdffileurl (format nil "~A/img/temp/~A" *siteurl* (generatepdf htmlfile invnum))))
    (function (lambda ()
      (values pdffileurl)))))



(defun com-hhub-transaction-send-invoice-email ()
  (with-vend-session-check
    (with-mvc-redirect-ui #'create-model-for-sendinvoiceemail #'create-widgets-for-genericredirect)))

(defun invoice-pdf-attachment (sessioninvkey)
  :description "Builds the invoice PDF for the email attachment and returns it as a one-element attachment list. Rendered from the invoice's own public page, the same way the vendor download does, so the attachment the customer receives and the page they can open are the same document. Signals a business error when the PDF cannot be produced : a mail the vendor asked to carry an invoice must not go out without one."
  (handler-case
      (let* ((sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	     (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	     (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	     (invnum (slot-value sessioninvheader 'invnum))
	     ;; :RENDER T — this fetch is the server itself, and the customer is not
	     ;; there to answer a password. Without the marker the attachment is a PDF
	     ;; of the password form. It is never handed to a browser.
	     (external-url (generate-invoice-ext-url invnum (get-login-vendor) (get-login-vendor-company) :render t))
	     (htmlfile (downloadhtmlfile external-url))
	     (pdfpath (format nil "~A/temp/~A" *HHUBRESOURCESDIR* (generatepdf htmlfile invnum))))
	;; make-attachment rather than the bare pathname: generatepdf names the file
	;; <invnum><universal-time>.pdf, and that is not a name to send a customer.
	(list (cl-smtp:make-attachment pdfpath :name (format nil "Invoice-~A.pdf" invnum))))
    (hhub-external-command-failed (condition)
      (hhub-log-message (format nil "invoice email attachment for session invoice ~A failed: ~A~%"
				sessioninvkey condition))
      (error 'hhub-business-function-error
	     :errstring (format nil "The invoice PDF could not be generated, so the email was NOT sent: ~A"
				condition)))))

(defun create-model-for-sendinvoiceemail ()
  (let* ((sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (to (hunchentoot:parameter "invoiceto"))
	 (subject (hunchentoot:parameter "draftinvoicesubject"))
	 (emailbody (hunchentoot:parameter "draftinvoiceemailbody"))
	 ;; the page's checkbox : jQuery .serialize() sends it only when it is ticked
	 (attachinvoicepdf (hunchentoot:parameter "attachinvoicepdf"))
	 (attachment (if attachinvoicepdf (invoice-pdf-attachment sessioninvkey) nil))
	 (redirecturl (format nil "/hhub/editinvoicepage?invnum=~A" sessioninvkey)))
    ;; the send runs on the shared email actor : the request redirects without waiting for SMTP
    (send-email-async to subject emailbody attachment)
    (function (lambda ()
      (values redirecturl)))))

(defun com-hhub-transaction-edit-invoice-email ()
  (with-vend-session-check
    (with-mvc-ui-page "Invoice Email" #'create-model-for-displayinvoiceemail #'create-widgets-for-displayinvoiceemail :role :vendor)))

(defun create-model-for-displayinvoiceemail ()
  (let* ((templatenum (parse-integer (hunchentoot:parameter "templatenum")))
	 (invoicetemplate (funcall (nst-get-cached-invoice-template-func :templatenum templatenum)))
	 (company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (address (slot-value vendor 'address))
	 (phone (slot-value vendor 'phone))
	 (email (slot-value vendor 'email))
	 (vendorname (slot-value vendor 'name))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))   
	 (sessioninvcustomer (slot-value sessioninvoice 'Customer))
	 (invnum (slot-value sessioninvheader 'invnum))
	 (invdate (get-date-string (slot-value sessioninvheader 'invdate)))
	 ;; ⚠ MINTED, NOT READ FROM EXTERNAL_URL. The column holds the link minted when the
	 ;; invoice was SAVED, and a public link now lives five minutes — so the email body
	 ;; was carrying an expired one and the customer's click answered "the link expired"
	 ;; no matter how promptly they opened the mail. NO :RENDER HERE, deliberately: this
	 ;; one goes to a browser and must still ask for the password.
	 (external-url (generate-invoice-ext-url invnum vendor company))
	 (companyname (slot-value company 'name))
	 (customername (slot-value sessioninvcustomer 'name))
	 (totalvaluewithgst (format nil "~d" (calculate-invoice-totalaftertax sessioninvitems)))
	 (totalvaluewithoutgst (format nil "~d" (calculate-invoice-totalbeforetax sessioninvitems)))
	 (to (slot-value sessioninvcustomer 'email))
	 (idtextarea (format nil "~Atextarea" (gensym "hhub")))
	 (charcountid1 (format nil "idchcount~A" (hhub-random-token 3)))
	 (subject "Test Invoice")
	 (logo-url (format nil "~A~A" *siteurl* *HHUBDEFAULTLOGOIMG*))
	 (contact-information (format nil "~A~C~C, ~A~C~C, ~A~C~C" address #\return #\linefeed phone #\return #\linefeed email #\return #\linefeed)))


    (case templatenum
      (1 (setf subject (format nil "Proforma/Draft Invoice for Your Review ~A" invnum)))
      (2 (setf subject (format nil "Payment Reminder for Your Invoice ~A" invnum)))
      (3 (setf subject (format nil "Overdue Payment Reminder for Your Invoice ~A" invnum)))
      (4 (setf subject (format nil "Thank You for Payment of Invoice ~A" invnum)))
      (5 (setf subject (format nil "Invoice ~A has been Shipped" invnum)))
      (6 (setf subject (format nil "Invoice ~A has been Cancelled!" invnum)))
      (7 (setf subject (format nil "Invoice ~A has been Refunded!" invnum))))
      
    
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Number%" invoicetemplate (or invnum "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Date%" invoicetemplate (or invdate "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Company Name%" invoicetemplate (or companyname "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Customer Name%" invoicetemplate (or customername "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total Amount without GST%" invoicetemplate (or totalvaluewithoutgst "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total Amount with GST%" invoicetemplate (or totalvaluewithgst "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Your Name%" invoicetemplate (or vendorname "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%INVOICE_LINK%" invoicetemplate (or external-url "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%LOGO_URL%" invoicetemplate (or logo-url "")))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Contact Information%" invoicetemplate (or contact-information "")))
    
    (function (lambda ()
      (values invoicetemplate to subject idtextarea charcountid1 sessioninvkey)))))

(defun create-widgets-for-displayinvoiceemail (modelfunc)
  (multiple-value-bind (draftemailtext to subject idtextarea charcountid1 sessioninvkey) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (with-html-div-col-8 :align "center"
			   (:br)
			   (:h2 (cl-who:str subject))))
		       (with-html-div-row
			 (with-html-div-col-2 "")
			 (with-html-div-col-8
			   (:img :class "profile-img" :src "/img/logo.png" :alt "")
			   (with-html-form-having-submit-event "nstdraftinvoiceemailform" "invoicemailaction"
			     (with-html-input-text-hidden "sessioninvkey" sessioninvkey) 
			     (:div :class "panel panel-default"
				   (:div :class "panel-heading" "From: support@ninestores.in"
					 (:div :class "panel-body"
					       ;;Panel content
					       (:div :class "form-group"
						     (:input :class "form-control" :name "invoiceto" :maxlength "90"  :value to :placeholder "Business Email Address " :type "email" :data-error "Invalid Email Address" :required T ))
					       (:div :class "form-group"
						     (:input :class "form-control" :name "draftinvoicesubject" :maxlength "100"  :value subject :placeholder "Subject " :type "text" :required T  ))
					       (:div  :class "form-group"
						      (:label :for idtextarea "Enter Email Text")
						      (text-editor-control idtextarea draftemailtext))
					       (:div :class "form-floating"
						     (:textarea :class "form-control" :placeholder "Enter email text" :id idtextarea :name "draftinvoiceemailbody"  :style "height: 200px" :onkeyup (format nil "countChar(~A.id, this, 5000)" charcountid1) (cl-who:str (format nil "~A" draftemailtext))))
					       (:div :class "form-group" :id charcountid1 )
					       (:div :class "form-group"
						     (:label "By clicking submit, you consent to allow Nine Stores to store and process the personal information submitted above to provide you the content requested. We will not share your information with other companies."))
					       (:div :class "form-group"
						     (:div :class "form-check"
							   ;; ticked by default : the customer should get their
							   ;; invoice unless the vendor deliberately unticks it,
							   ;; and the public page carries a download button anyway.
							   (:input :class "form-check-input" :type "checkbox" :name "attachinvoicepdf" :id "idattachinvoicepdf" :value "true" :checked "checked")
							   (:label :class "form-check-label" :for "idattachinvoicepdf" "Attach the invoice PDF")))
					       (:div :class "form-group"
						     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Send"))))))))
		       (:div  :class "hhub-footer" (hhub-html-page-footer)))))))
    (list widget1))))

;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE PUBLIC INVOICE LINK — a SIGNED, EXPIRING capability
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; WHAT THIS REPLACED, AND WHY IT MATTERED. The key used to be nothing but
;;; `base64("tenant-id,invnum,vendor-id\n<tenant>,<invnum>,<vendor>")` — structured,
;;; predictable, UNSIGNED, with no expiry and no password. Anyone holding one link could
;;; decode the format and mint the key for ANY invoice in ANY tenant, which is a BOLA
;;; bypass wearing the costume of a capability URL (OWASP API1:2023). The rendered PDF
;;; was the same story: a static file under /img/temp/ named from the invoice number and
;;; universal time.
;;;
;;; TWO THINGS MAKE THE EXPIRY MEAN ANYTHING, and neither is optional:
;;;
;;;   1. THE PAYLOAD IS SIGNED. An expiry inside plain base64 is decoration — an
;;;      attacker re-encodes a later timestamp. The signature is HMAC-SHA256 over the
;;;      exact payload bytes, keyed with THE VENDOR'S OWN SALT, so a token minted for
;;;      one vendor cannot be forged for another and the expiry cannot be edited.
;;;      (DOD_VEND_PROFILE.PAYMENT_API_SALT would be the natural key, but it is EMPTY on
;;;      all fifteen rows; SALT is present on every row and never leaves the system —
;;;      the vendor response allowlist excludes it.)
;;;   2. THE PASSWORD CHECK IS RATE LIMITED — see *invoice-ext-max-attempts*. Four digits
;;;      is 10,000 combinations, so unthrottled the password is theatre. The digits are the
;;;      CUSTOMER's own phone number (2026-10-03; the vendor's until then), which is the
;;;      one value the link's intended reader has and a passer-by does not.
;;;
;;; ⚠ MINTING FAILS CLOSED. A vendor with no SALT cannot have a signed link, and minting
;;; one with a shared fallback key would recreate exactly the forgeability this removes.
;;;
;;; THE LIFETIME IS SHORT ON PURPOSE (5 minutes, agreed 2026-09-26). Every consumer mints
;;; on demand and uses the link immediately — the invoice EMAIL renders its PDF attachment
;;; server-side straight away, and the public page's own download button reuses the key it
;;; arrived with. **A STORED external-url therefore goes stale within five minutes**, which
;;; is the intended trade: a link that cannot be forwarded later is the point.

(defparameter *invoice-ext-link-lifetime-seconds* 300
  "How long a public invoice link stays valid. FIVE MINUTES, by decision of 2026-09-26.
   Short because the link carries a customer's GST invoice to whoever holds it.")

(defparameter *invoice-ext-max-attempts* 5
  "Password attempts allowed per token before it is refused. See the note above: without
   this the 4-digit password is brute-forceable by hand, let alone by script.")

;;; ── THE RENDER TOKEN: THE PDF PIPELINE MUST NOT MEET THE PASSWORD WALL ──────
;;;
;;; 🚨 WHAT WENT WRONG WITHOUT THIS, AND IT BROKE EVERY PDF IN THE SYSTEM. The PDF
;;; pipeline renders an invoice by FETCHING ITS OWN PUBLIC PAGE — generate-invoice-ext-url
;;; → downloadhtmlfile (wget) → generatepdf (wkhtmltopdf). wget is a browser with no
;;; session, no cookie and nobody to type a password, so once the page acquired its
;;; password gate (2026-09-26) the fetch came back with THE PASSWORD PROMPT and
;;; wkhtmltopdf faithfully rendered THAT: the emailed attachment, the vendor's own
;;; Download button and the API's /download all became a PDF of a four-digit form —
;;; and, because the prompt lands inside the customer's page, the form sat on top of
;;; the invoice content rather than replacing it. The gate was doing its job on a
;;; caller that is not a customer at all.
;;;
;;; WHY THE MARKER IS INSIDE THE SIGNED PAYLOAD. The fetch makes an outbound round
;;; trip to *siteurl* — possibly ANOTHER deployment of this same code — so the
;;; exemption cannot live in this process's memory: only something the bytes
;;; themselves prove travels. A query parameter (`&render=1`) would be the obvious
;;; shortcut and would hand every customer a password bypass by typing six characters;
;;; a fifth field covered by the same HMAC-SHA256 cannot be added, removed or forged
;;; without the vendor's SALT.
;;;
;;; ⚠ IT IS STILL A BEARER CAPABILITY, AND THE HONEST SCOPE OF IT IS THIS: a render
;;; token opens an invoice with no password, so it must never be handed to a browser,
;;; stored in a column, or put in an email. It is minted by SERVER-SIDE callers only,
;;; for a fetch that happens milliseconds later — see the four call sites, all of which
;;; either own a vendor session (the vendor UI download, the email attachment, the API
;;; route) or reuse a token the customer has already unlocked (the public download
;;; button, which fetches the key it arrived with and NOT a re-minted one).
(defparameter invoice-ext-render-marker "1"
  "The fifth signed field marking a token as a SERVER-SIDE RENDER token: the password gate
   is skipped for it. Not a public value — see the note above.")

(defun invoice-ext-b64-encode (string)
  "STRING → URL-SAFE base64 with the padding stripped.

   🚨 URL-SAFE IS NOT COSMETIC. Standard base64 emits `+` and `/`, and the link is built
   by plain FORMAT with no percent-encoding — so a payload whose base64 happened to
   contain them would be mangled by the query string. `+` in particular arrives as a
   SPACE. The old key got away with it only because this CSV's base64 happened to use
   neither.

   🚨 AND THE RESULT IS NOT LOWERCASED. This function was written with a STRING-DOWNCASE
   around it, which is FATAL: base64 is CASE-SENSITIVE, so `g` and `G` are different
   sextets. Measured 2026-09-26 — the payload
   `tenant-id,...,3959000000` came back from decode as line noise, and because the
   signature is computed over the DECODED payload, EVERY minted link failed verification
   with `the link is malformed`. Hex may be folded; base64 may not. The case-folding
   belongs on the SIGNATURE (hex, genuinely case-insensitive), and now lives only there."
  (substitute #\- #\+ (substitute #\_ #\/ (string-trim "=" (cl-base64:string-to-base64-string string)))))

(defun invoice-ext-b64-decode (string)
  "URL-safe base64 back to STRING, restoring the padding that was stripped."
  (let* ((std (substitute #\+ #\- (substitute #\/ #\_ string)))
         (pad (mod (- 4 (mod (length std) 4)) 4)))
    (cl-base64:base64-string-to-string (concatenate 'string std (make-string pad :initial-element #\=)))))

(defun invoice-ext-key-payload (invnum vendor company expires-at &optional render)
  "The signed payload. The header line and the first three fields are UNCHANGED from the
   original format so existing readers that take nth 0/1/2 keep working; the expiry is
   APPENDED as the fourth, and — only for a SERVER-SIDE RENDER token — a fifth field
   carrying the marker \"1\". See INVOICE-EXT-RENDER-MARKER for what that marker is and
   why it is inside the signed bytes rather than a query parameter."
  (format nil "tenant-id,invnum,vendor-id,expires-at~C~A,~A,~A,~A~A"
          #\linefeed
          (slot-value company 'row-id) invnum (slot-value vendor 'row-id) expires-at
          (if render (format nil ",~A" invoice-ext-render-marker) "")))

(defun invoice-ext-key-signature (payload vendor)
  "HEX HMAC-SHA256 of PAYLOAD under VENDOR's own SALT, or NIL when the vendor has none."
  (let ((key (and vendor (ignore-errors (slot-value vendor 'salt)))))
    (when (and key (plusp (length key)))
      (let ((mac (ironclad:make-hmac (ironclad:ascii-string-to-byte-array key) :sha256)))
        ;; ⚠ UPDATE-HMAC *DECLARES* ITS SEQUENCE AS A SIMPLE OCTET VECTOR — a string
        ;; is not accepted, and there is no `:hmac` digest name to pass to
        ;; DIGEST-SEQUENCE. This is the only HMAC in the tree, and it is easy to get
        ;; wrong twice over, which is why it is spelled out at length.
        (ironclad:update-hmac mac (ironclad:ascii-string-to-byte-array payload))
        (string-downcase (ironclad:byte-array-to-hex-string (ironclad:hmac-digest mac)))))))

(defun invoice-ext-key-of-url (url)
  "The token out of a public invoice URL, or NIL. The one place that knows where `key=` is."
  (let ((i (and (stringp url) (search "key=" url))))
    (and i (subseq url (+ i 4)))))

(defun invoice-ext-url-status (url &optional (now (get-universal-time)))
  "Can a customer still open URL? → :VALID, :EXPIRED or :UNUSABLE. THE VENDOR'S VIEW.

   🔑 WHY THIS EXISTS. DOD_INVOICE_HEADER.EXTERNAL_URL is a STORED link and a link now lives
   five minutes, so by the time a vendor copies it the only person who finds out it is dead
   is the customer — the vendor pastes it into WhatsApp, the customer answers 'this link is
   expired', and the vendor had no way to know beforehand. This answers that question FROM
   THE LINK ITSELF: it decodes the payload the link carries and compares the expiry inside it
   to the clock. No row read, no SALT, no signature check.

   ⚠ IT IS A DISPLAY CHECK, NOT AN AUTHORISATION ONE, AND MUST NEVER BE USED AS A GATE. It
   does not verify the HMAC (that needs the vendor's SALT and a row) and says nothing about
   whether the invoice still exists. The gate is INVOICE-EXT-KEY-PARSE.

   :UNUSABLE IS NOT 'EXPIRED', AND THE DIFFERENCE IS REAL: it means the link carries no
   usable expiry at all — empty, hand-trimmed, or one of the LEGACY unsigned
   base64(\"tenant,invnum,vendor\") links, which have no expiry field and which the verifier
   refuses with 'the link is malformed'. Measured 2026-10-03: the only two non-empty
   EXTERNAL_URL values in tenant 2 are exactly that legacy shape (rows 35 and 30), so this
   arm is not hypothetical. A vendor holding one is not waiting for a refresh, they are
   holding a link that has never worked since the signature landed."
  (let* ((key (invoice-ext-key-of-url url))
         (dot (and key (position #\. key :from-end t)))
         (payload (and dot (ignore-errors (invoice-ext-b64-decode (subseq key 0 dot)))))
         (fields (and payload (ignore-errors
                               (first (cl-csv:read-csv payload :skip-first-p t :map-fn #'identity)))))
         (expires (and fields (ignore-errors
                               (parse-integer (or (nth 3 fields) "") :junk-allowed nil)))))
    (cond ((null expires) :unusable)
          ((< expires now) :expired)
          (t :valid))))

(defun invoice-ext-url-share-title (status)
  "The popover title for the vendor's share icon: what the link is, and — when it is dead —
   what to do about it. PRESS NEXT IS THE ACTUAL BUTTON LABEL on the edit page
   (editinvoicewidget-section4, which posts updateinvoiceaction), so the instruction names
   the control the vendor is looking at.

   ⚠ IT NAMES THE STATE IN WORDS, NOT ONLY IN RED. The colour is the signal the vendor asked
   for, but colour alone is invisible to a colour-blind vendor and to anyone reading a
   screenshot, and this is the difference between a shared link working and a customer
   discovering it does not."
  (case status
    (:valid "Share LIVE Invoice Link")
    (:expired "Share link has EXPIRED — press NEXT to issue a fresh link")
    (t "Share link is not usable — press NEXT to issue a fresh link")))

(defun invoice-ext-public-url (key)
  "The public page URL carrying KEY. Split out so a caller that already HOLDS a verified
   key (the customer's own download button) can fetch THAT token rather than minting a
   second one — which is what the password gate is keyed by."
  (format nil "~A/hhub/displayinvoicepublic?key=~A" *siteurl* key))

(defun generate-invoice-ext-url (invnum vendor company &key render)
  :description "The public, signed, expiring invoice link. See the section note above."
  (let* ((expires-at (+ (get-universal-time) *invoice-ext-link-lifetime-seconds*))
         (payload (invoice-ext-key-payload invnum vendor company expires-at render))
         (signature (invoice-ext-key-signature payload vendor)))
    (when (null signature)
      ;; FAIL CLOSED — see the note. A link nobody can verify is the vulnerability.
      (error "Refusing to mint a public invoice link: vendor ~A has no SALT to sign it with."
             (ignore-errors (slot-value vendor 'row-id))))
    (invoice-ext-public-url (format nil "~A.~A" (invoice-ext-b64-encode payload) signature))))

(defun invoice-ext-key-parse (key)
  "KEY → (values PLIST REASON). PLIST carries :tenant-id :invnum :vendor-id :vendor
   :company :expires-at, or is NIL with REASON saying which check failed.

   ⚠ EVERY FAILURE IS A REASON, NOT A SILENT NIL: an expired link, a forged signature and
   a malformed key are different facts and the page says which one it is — a customer told
   'expired' can ask for a fresh link, while one told 'invalid' cannot act at all."
  (flet ((why (reason) (values nil reason)))
    ;; A request with no `key` at all is just a customer who trimmed the URL, and
    ;; POSITION would signal on NIL rather than answer. Guard before anything else.
    (when (or (null key) (not (stringp key)) (zerop (length key)))
      (return-from invoice-ext-key-parse (why "no link was supplied")))
    (let* ((dot (position #\. key :from-end t))
           (b64 (and dot (subseq key 0 dot)))
           (given (and dot (subseq key (1+ dot)))))
      (when (or (null dot) (< dot 1) (null given) (zerop (length given)))
        (return-from invoice-ext-key-parse (why "the link is malformed")))
      (let ((payload (handler-case (invoice-ext-b64-decode b64)
                       (error () nil))))
        (when (null payload)
          (return-from invoice-ext-key-parse (why "the link is malformed")))
        (let* ((fields (ignore-errors
                        (first (cl-csv:read-csv payload :skip-first-p t
                                                :map-fn #'(lambda (row) row)))))
               (tenant-id (nth 0 fields)) (invnum (nth 1 fields))
               (vendor-id (nth 2 fields)) (expires-at (nth 3 fields)))
          (unless (and tenant-id invnum vendor-id expires-at)
            (return-from invoice-ext-key-parse (why "the link is malformed")))
          (let ((vendor (ignore-errors (select-vendor-by-id vendor-id)))
                (company (ignore-errors (select-company-by-id tenant-id))))
            (unless (and vendor company)
              (return-from invoice-ext-key-parse (why "the link names a vendor or tenant that no longer exists")))
            (let ((expected (invoice-ext-key-signature payload vendor)))
              (unless (and expected (constant-time-string= expected given))
                ;; FORGED, or minted before a salt rotation. Deliberately not distinguished.
                (return-from invoice-ext-key-parse (why "the link is not one this system issued"))))
            ;; 🚨 THE VALUES FORM IS INSIDE THIS LET ON PURPOSE. It was originally a
            ;; sibling, one level out, which left EXPIRES unbound exactly when everything
            ;; else had passed — so a perfectly valid key signalled UNBOUND-VARIABLE
            ;; instead of opening the invoice. Caught by the offline harness on
            ;; 2026-09-26; the compiler only offered a style-warning.
            (let ((expires (ignore-errors (parse-integer expires-at :junk-allowed nil))))
              (unless expires
                (return-from invoice-ext-key-parse (why "the link is malformed")))
              (when (< expires (get-universal-time))
                (return-from invoice-ext-key-parse
                  (why (format nil "the link expired (it is valid for ~A seconds)"
                               *invoice-ext-link-lifetime-seconds*))))
              (values (list :tenant-id tenant-id :invnum invnum :vendor-id vendor-id
                            :vendor vendor :company company :expires-at expires
                            ;; A fifth field makes this a SERVER-SIDE RENDER token: the
                            ;; page skips the password for it. It is covered by the
                            ;; signature checked above, so it cannot be appended by a
                            ;; customer — a hand-edited payload fails :SIGNATURE, not
                            ;; the gate.
                            :render (equal invoice-ext-render-marker (nth 4 fields)))
                      nil))))))))

;;; ── THE PASSWORD GATE ───────────────────────────────────────────────────────
;;;
;;; The link carries the invoice; the PASSWORD is the last four digits of THE CUSTOMER's
;;; registered phone number. It protects against the ordinary accident — a forwarded,
;;; shoulder-surfed or mis-delivered link — and NOT against a determined attacker, and it
;;; is better to say that here than to pretend otherwise:
;;;
;;;   • FOUR DIGITS IS 10,000 COMBINATIONS. Unthrottled that is seconds of work, so the
;;;     attempt limit is the only thing that makes this password mean anything.
;;;   • THE CUSTOMER ALREADY KNOWS THE NUMBER, WHICH IS THE POINT. It was the VENDOR's
;;;     phone until 2026-10-03 and that was the wrong party: the vendor's number is on
;;;     every invoice they issue, printed on the page being protected and quoted to every
;;;     customer, so the one person who was NOT protected from a forwarded link was the
;;;     invoice's own addressee. The customer's number is the one thing the link's intended
;;;     reader has and a passer-by does not. The password is still a SPEED BUMP; the
;;;     FIVE-MINUTE EXPIRY is the control.
;;;
;;; The check is server-side and keyed by the token, so a customer cannot mark themselves
;;; as authorised, and the whole state dies with the token.
;;;
;;; ⚠ LOCKING A TOKEN IS ALSO A DENIAL OF SERVICE. Five wrong guesses stop the LEGITIMATE
;;; customer too, and an attacker who can reach the link can spend them. That is
;;; tolerable ONLY because the link is dead in five minutes anyway; if the lifetime is
;;; ever lengthened, this trade must be revisited rather than assumed.

(defvar *invoice-ext-gate-table* (make-hash-table :test 'equal)
  "Token key → (:attempts N :unlocked BOOL :at UNIVERSAL-TIME).

   IN MEMORY ON PURPOSE. The state is worth nothing once the token expires, and writing
   it to the database would outlive the link it protects — an unlocked row for an expired
   token is a liability, not a record.")

(defvar *invoice-ext-gate-lock* (bt:make-lock "ninestores-invoice-ext-public-gate")
  "Hunchentoot serves requests on many threads and this table is shared, so every read
   and write goes through this lock.")

(defun invoice-ext-four-digits (value)
  "The LAST FOUR DIGITS of VALUE, or NIL when there are fewer than four.

   ⚠ BOTH SIDES ARE NORMALISED THE SAME WAY, and both sides take the LAST four. So a
   customer whose stored phone is `+91 99999 99990` and a customer who types the whole
   number both resolve to `9990`, while a customer who types 9990 also matches. Picking
   the last four rather than the first four is what makes both spellings work."
  (let* ((s (and value (format nil "~A" value)))
         (d (and s (remove-if-not #'digit-char-p s))))
    (when (and d (>= (length d) 4))
      (subseq d (- (length d) 4)))))

(defun invoice-ext-password-digits (customer)
  "The expected password for CUSTOMER: the last four digits of its phone number.

   NIL MEANS THE PAGE MUST REFUSE — a gate with no expected value is not a gate, and an
   unsigned fallback there would be worse than no password at all.

   ⚠ IT TAKES THE PERSON, NOT THE INVOICE, so a caller must resolve the invoice's customer
   first — see INVOICE-EXT-CUSTOMER-OF-INVOICE. Handing it the VENDOR (as this did until
   2026-10-03) silently reinstates the wrong party rather than failing, which is why the
   signature names the argument."
  (invoice-ext-four-digits (ignore-errors (phone customer))))

(defun invoice-ext-customer-of-invoice (invnum company)
  "The customer the invoice INVNUM in COMPANY was billed to, or NIL.

   🔑 THE PASSWORD IS THE CUSTOMER'S, SO THE GATE MUST KNOW WHO THE CUSTOMER IS — and this
   is the ONE row read the gate is allowed, because by the time it runs the key has ALREADY
   been signature-verified and expiry-checked: the invoice it names is the one the caller
   was given, and nothing is rendered from this read.

   IT READS EXACTLY WHAT THE PAGE ITSELF READS: the header by invnum + tenant, then the
   customer by its CUSTID (nst-bl-ihd.lisp DOREAD does the same two reads to fill the
   `customer` slot the template prints). So a customer the page can bill is a customer the
   gate can ask a password of.

   ⚠ IT FAILS CLOSED ON AN INACTIVE OR SOFT-DELETED CUSTOMER: SELECT-CUSTOMER-BY-ID wants
   ACTIVE_FLAG='Y' and DELETED_STATE='N'. Deliberately the stricter read — an invoice whose
   customer row has been deactivated is refused rather than opened with no password — and
   measured harmless on 2026-10-03: all 25 live customer rows are 'Y'/'N'. If a real
   deployment ever deactivates a customer who still has invoices to open, this is the line
   that stops them, and the message the page shows says so.

   🚨 DO NOT USE THE `customer` JOIN SLOT HERE. dod-invoice-header declares one on
   CUSTID (:DB-KIND :JOIN), but SELECT-INVOICE-HEADER-BY-INVNUM is :FLATP T and never
   resolves a join — the slot comes back NIL and the gate would refuse every link. Read
   CUSTID and select."
  (let ((header (ignore-errors (select-invoice-header-by-invnum invnum company))))
    (and header
         (ignore-errors (select-customer-by-id (slot-value header 'custid) company)))))

(defun invoice-ext-gate-sweep (now)
  "Forget tokens that can no longer be presented. Called with the lock held."
  (let ((cutoff (- now (* 2 *invoice-ext-link-lifetime-seconds*))))
    (maphash (lambda (k v)
	       (when (< (getf v :at now) cutoff) (remhash k *invoice-ext-gate-table*)))
	     *invoice-ext-gate-table*)))

(defun invoice-ext-authorise (key expected submitted is-post)
  "May KEY show the invoice? Returns (values STATE REASON ATTEMPTS-LEFT) where STATE is
   :granted, :prompt (a password is still needed) or :locked (attempts exhausted).

   🔑 SUBMITTED AND IS-POST ARE ARGUMENTS, NOT READS OF THE LIVE REQUEST. That keeps this
   function pure enough to drive offline from a test harness — the alternative reads
   HUNCHENTOOT:PARAMETER inside, which cannot be called anywhere except during a request.
   The caller does the HTTP; this does the decision.

   ONLY A POST CARRYING A PASSWORD SPENDS AN ATTEMPT. A GET never does, so an attacker
   cannot exhaust the limit — and lock out the real customer — by simply reloading the
   page, which is exactly what a naive `bump on every request` would allow."
  (let ((now (get-universal-time)))
    (bt:with-lock-held (*invoice-ext-gate-lock*)
      (invoice-ext-gate-sweep now)
      (let* ((entry (gethash key *invoice-ext-gate-table*))
	     (attempts (getf entry :attempts 0))
	     (unlocked (getf entry :unlocked nil)))
	(flet ((remember (n open)
		 (setf (gethash key *invoice-ext-gate-table*)
		       (list :attempts n :unlocked open :at now))))
	  (cond
	    ;; Already proved. Re-posting a wrong password after success must NOT revoke it,
	    ;; or a customer who fumbles a second tab loses the page they are reading.
	    (unlocked (values :granted nil (- *invoice-ext-max-attempts* attempts)))
	    ((>= attempts *invoice-ext-max-attempts*)
	     (values :locked "too many incorrect attempts on this link" 0))
	    ;; A BLANK SUBMISSION IS NOT A GUESS. An empty form field is a customer who
	    ;; pressed the button without typing; counting it would punish one mis-click
	    ;; several times over, and an attacker gains nothing by sending "" because it
	    ;; can never match. Everything non-blank counts, junk included.
	    ((and is-post submitted (plusp (length submitted)))
	     (let ((given (invoice-ext-four-digits submitted)))
	       (if (and given (constant-time-string= given expected))
		   (progn (remember attempts t)
			  (values :granted nil (- *invoice-ext-max-attempts* attempts)))
		   ;; A wrong guess is recorded whether or not it even LOOKED like four
		   ;; digits: otherwise a script sending junk would never trip the limit,
		   ;; and tripping the limit is the whole defence.
		   (let ((n (1+ attempts)))
		     (remember n nil)
		     (if (>= n *invoice-ext-max-attempts*)
			 (values :locked "too many incorrect attempts on this link" 0)
			 (values :prompt "that password is not correct"
				 (- *invoice-ext-max-attempts* n)))))))
	    (t (values :prompt nil (- *invoice-ext-max-attempts* attempts)))))))))


(defun invoice-ext-authorise-grant (grant rawkey expected submitted is-post)
  "The gate decision for an ALREADY VERIFIED key: (values STATE REASON ATTEMPTS-LEFT).

   🔑 THE RENDER SHORT-CIRCUIT LIVES HERE, IN A PURE FUNCTION, SO IT CAN BE PROVED OFFLINE.
   A SERVER-SIDE RENDER token is granted without a password, and every other token goes to
   INVOICE-EXT-AUTHORISE unchanged. The bug this exists to prevent — a PDF of the password
   form emailed to a customer — was invisible precisely because the decision was inlined
   in a page model that needs a live HTTP request to run at all.

   ⚠ GRANT IS NOT A PARAMETER THE CALLER MAY INVENT. It is what INVOICE-EXT-KEY-PARSE
   returned, and only a signature-verified key carries :RENDER. Nothing else may pass a
   list with :RENDER T in it."
  (if (getf grant :render)
      (values :granted nil *invoice-ext-max-attempts*)
      (invoice-ext-authorise rawkey expected submitted is-post)))

(defun invoice-ext-password-prompt-thunk (key reason attempts-left)
  "The form that asks for the password, in the same thunk shape the page's model returns.

   THE KEY RIDES IN THE FORM'S ACTION, so the POST comes back to this same page with the
   same token and no hidden field can be edited to point at another invoice. The password
   travels in the POST BODY, never the query string — a password in a URL lands in access
   logs, browser history and the Referer header of whatever the customer clicks next."
  (function
   (lambda ()
     (values
      (cl-who:with-html-output-to-string (s nil)
	(:div :class "container mt-4" :style "max-width: 460px;"
	      (:h4 "This invoice is protected")
	      ;; The CUSTOMER's number, and it says so: the reader is being asked for their
	      ;; own, and a prompt naming the vendor would have them typing the wrong four
	      ;; digits — which spends an attempt and can lock the link.
	      (:p "Enter the last 4 digits of the phone number this invoice was billed to.")
	      ;; ⚠ CL-WHO CONVERTS TAG FORMS ONLY IN A BODY POSITION. Inside WHEN it treats
	      ;; (:div …) as ordinary Lisp — "The function :DIV is undefined" at runtime —
	      ;; so each conditional block is wrapped in CL-WHO:HTM. Measured, not assumed.
	      (when reason
		(cl-who:htm
		 (:div :class "alert alert-danger" (cl-who:str (format nil "~@(~A~)." reason)))))
	      (when (and attempts-left (plusp attempts-left))
		(cl-who:htm
		 (:p :class "text-muted"
		     (cl-who:str (format nil "~D attempt~:P remaining." attempts-left)))))
	      (:form :method "POST"
		     :action (format nil "/hhub/displayinvoicepublic?key=~A" key)
		     (:div :class "mb-3"
			   (:input :type "password" :name "password" :id "hhubinvoicepassword"
				   :class "form-control form-control-lg text-center"
				   :inputmode "numeric" :pattern "[0-9]*"
				   :maxlength "4" :autocomplete "off"
				   :required "required" :placeholder "4 digits"))
		     (:button :type "submit" :class "btn btn-primary w-100"
			      "View invoice"))))
      nil nil))))

(defun create-model-for-displayinvoicepublic ()
  ;; ⚠ THE KEY IS VERIFIED BEFORE A SINGLE ROW IS READ. Until now this function took the
  ;; base64 at face value, decoded a tenant and an invoice number out of it and fetched
  ;; them — so a hand-built key read any tenant's invoice, and a nil vendor came back as a
  ;; 500 (the "MISSING-SLOT INVNUM" failure this page has been throwing since at least
  ;; 2026-05-23). INVOICE-EXT-KEY-PARSE checks the signature and the expiry, and its
  ;; failure branch replaces the 500 with a sentence a customer can act on.
  (multiple-value-bind (grant reason)
      (invoice-ext-key-parse (hunchentoot:parameter "key"))
    (unless grant
      (return-from create-model-for-displayinvoicepublic
	;; Same shape as the success path — a thunk of three values — so the widget code
	;; below needs no special case, and the reason reaches the customer as text.
	(function (lambda () (values nil nil reason)))))
    ;; ── AND THEN THE PASSWORD ──────────────────────────────────────────────
    ;; Verified key first, password second: a forged or expired link is refused without
    ;; ever consulting, or spending an attempt on, a password.
    (let* ((rawkey (hunchentoot:parameter "key"))
	   ;; A render token (see INVOICE-EXT-RENDER-MARKER) needs no phone number and no
	   ;; password: it was minted by our own server-side code and signed with the same
	   ;; key, and the caller at the other end is the PDF pipeline, not a customer.
	   (render (getf grant :render))
	   ;; ── THE PASSWORD IS THE CUSTOMER'S, NOT THE VENDOR'S (2026-10-03) ──────
	   ;; Which means the gate resolves the invoice's own customer before it can ask
	   ;; for anything. That read is safe here: the key has already been verified.
	   ;; ⚠ AND A RENDER TOKEN SKIPS THE LOOKUP ENTIRELY, not merely its answer: the PDF
	   ;; pipeline must not depend on the customer row resolving — a deactivated customer
	   ;; must not be able to stop an invoice being rendered for the vendor who owns it.
	   (expected (unless render
		       (invoice-ext-password-digits
			(invoice-ext-customer-of-invoice (getf grant :invnum)
							 (getf grant :company))))))
      ;; ⚠ A GATE WITH NO EXPECTED VALUE IS NOT A GATE, so an invoice whose customer has no
      ;; phone on record must be refused rather than let through — unless the token is a
      ;; render token, which never consults the password at all.
      (unless (or render expected)
	(return-from create-model-for-displayinvoicepublic
	  (function (lambda ()
	    (values nil nil "the customer this invoice was billed to has no phone number on record, so this invoice cannot be protected")))))
      (multiple-value-bind (state why left)
	  (invoice-ext-authorise-grant grant rawkey expected
				       (hunchentoot:parameter "password")
				       (eq (hunchentoot:request-method*) :post))
	(case state
	  (:granted nil)
	  (:locked (return-from create-model-for-displayinvoicepublic
		     (function (lambda () (values nil nil why)))))
	  (t (return-from create-model-for-displayinvoicepublic
	       (invoice-ext-password-prompt-thunk rawkey why left))))))
  (let* ((parambase64 (hunchentoot:parameter "key"))
	 (invnum (getf grant :invnum))
	 (vendor (getf grant :vendor))
	 (company (getf grant :company))
	 ;; the vendor's own choice from the invoice settings page, defaulted
	 (invoicetemplate (funcall (nst-get-cached-invoice-template-func :templatenum (nst-get-vendor-invoicetemplatenum vendor))))
	 (hrequestmodel (make-instance 'InvoiceHeaderRequestModel
				      :invnum invnum
				      :company company))
	 (headeradapter (make-instance 'InvoiceHeaderAdapter))
	 (invheader (processreadrequest headeradapter hrequestmodel))
         (invnum (slot-value invheader 'invnum))
	 (irequestmodel (make-instance 'InvoiceItemRequestModel
				       :company company
				       :invoiceheader invheader))
	 (itemsadapter (make-instance 'InvoiceItemAdapter))
	 (invoiceitems (processreadallrequest itemsadapter irequestmodel))
	 (tax-breakdown (generate-gst-tax-breakdown invheader invoiceitems))
	 (invoiceitemshtmlfunc (generate-invoice-items-rows-public invoiceitems invoicetemplate))
	 (invoicetaxbreakdownfunc (render-tax-summary-html tax-breakdown))
	 (totalvalue (calculate-invoice-totalaftertax invoiceitems))
	 (currency (get-account-currency company))
	 (qrcodepath (format nil "~A/img~A" *siteurl* (generateqrcodeforvendor vendor "ABC" invnum totalvalue)))
	 ;; The key is passed straight back, exactly as this page received it, so the download
	 ;; route decodes the same value this model just decoded. Nothing is re-derived here.
	 ;; ⚠ AND ON A RENDER TOKEN THE BUTTON IS SUPPRESSED ENTIRELY: wkhtmltopdf rewrites a
	 ;; relative href into an ABSOLUTE one, so leaving it in would print a live,
	 ;; password-free render URL INSIDE the very PDF that gets emailed to the customer.
	 ;; There is no button to offer anyway — the reader is already holding the document.
	 (downloadurl (unless (getf grant :render)
			(format nil "/hhub/publicinvoicepdf?key=~A" parambase64))))
    (setf invoicetemplate (remove-invoice-item-markers-from-template invoicetemplate))
    (setf invoicetemplate (funcall (invoicetemplatefill invoicetemplate invheader invoiceitems invoiceitemshtmlfunc invoicetaxbreakdownfunc qrcodepath currency vendor)))
    (function (lambda ()
      (values  invoicetemplate downloadurl nil))))))

(defun create-widgets-for-displayinvoicepublic (modelfunc)
  (multiple-value-bind ( invoicetemplate downloadurl reason) (funcall modelfunc)
    ;; REASON is non-nil only when the key failed to verify. The download button is
    ;; deliberately NOT rendered in that case: it would lead to a PDF that either cannot be
    ;; built or, worse, could be built for the wrong invoice. Nothing is fetched here.
    (if reason
	(let ((widget1 (function (lambda ()
			  (cl-who:with-html-output (*standard-output* nil)
			    (:div :class "alert alert-warning mt-3"
				  (:h4 :class "alert-heading" "This invoice link cannot be opened")
				  (:p (cl-who:str (format nil "~@(~A~)." reason)))
				  (:p :class "mb-0 text-muted"
				      "Ask the vendor to send you a fresh link.")))))))
	  (list widget1))
	(let* ((widget1 (function (lambda ()
			  (cl-who:with-html-output (*standard-output* nil)
			    ;; The customer's own copy. The vendor may or may not have attached it to
			    ;; the email they received, so the page always offers one.
			    ;; DOWNLOADURL IS NIL WHILE THE PAGE IS STILL ASKING FOR THE
			    ;; PASSWORD, and an <a href=""> there would be a button that
			    ;; does nothing. The button appears only once there is an invoice.
			    (when downloadurl
			      (cl-who:htm
			       (:div :class "text-end mb-2"
				     (:a :class "btn btn-primary" :href downloadurl
					 (:i :class "fa-solid fa-file-arrow-down")
					 " Download Invoice PDF"))))
			    (:hr :style "border-top: 2px dashed gray;")
			    (cl-who:str invoicetemplate))))))
	  (list widget1)))))

;; ── The customer's copy of the PDF ──────────────────────────────────────────
;; Public twin of the vendor's create-model-for-downloadinvoice. A customer has no vendor session,
;; so the invoice is identified by the same base64 key the public page carries, and the PDF is
;; rendered when the button is actually clicked rather than on every page view.
;;
;; The route is /hhub/publicinvoicepdf and NOT /hhub/downloadinvoicepublic on purpose : the
;; dispatchers are matched in the order they appear in hunchentoot:*dispatch-table*, and the
;; existing ^/hhub/downloadinvoice pattern is an unanchored prefix, so a customer hitting
;; /hhub/downloadinvoicepublic would be caught by the VENDOR route first and bounced to the vendor
;; login. /hhub/publicinvoicepdf collides with none of the 250 registered patterns.
(defun create-model-for-invoice-public-pdf-url ()
  :description "Renders the public invoice page to a PDF and returns its URL. Signals when the render fails."
  ;; VERIFIED THE SAME WAY THE PAGE IS. This route is reachable directly, so leaving it
  ;; unverified would hand back any invoice's PDF to a hand-built key — the page's check
  ;; would be decoration.
  (multiple-value-bind (grant reason) (invoice-ext-key-parse (hunchentoot:parameter "key"))
    (unless grant
      (error "Refusing to render the public invoice PDF: ~A." reason))
    (let* ((invnum (getf grant :invnum))
	   ;; 🚨 THE ARRIVING KEY IS FETCHED, NOT A RE-MINTED ONE, AND THAT IS THE FIX.
	   ;; This used to mint a fresh link: same invoice, same signature, DIFFERENT
	   ;; token — and the gate's unlocked state is keyed BY THE TOKEN, so the server's
	   ;; own fetch arrived as a stranger and got the password prompt rendered into
	   ;; the customer's PDF. Fetching the key the customer actually unlocked means the
	   ;; gate answers :granted to the server exactly as it did to them. It also keeps
	   ;; the fail-closed property: reached WITHOUT the password, this renders the
	   ;; prompt page, so a hand-built key leaks nothing.
	   (external-url (invoice-ext-public-url (hunchentoot:parameter "key")))
	   (htmlfile (downloadhtmlfile external-url))
	   (pdffileurl (format nil "~A/img/temp/~A" *siteurl* (generatepdf htmlfile invnum))))
      pdffileurl)))

(defun com-hhub-transaction-invoice-public-pdf ()
  :description "Serves the invoice PDF to a customer reading the public invoice page. No session check : the key is the authorisation, the same as the page itself."
  (hunchentoot:redirect (create-model-for-invoice-public-pdf-url)))

(defun invoicetemplatefill (invoicetemplate invheader invoiceitems invoiceitemshtmlfunc  invoicetaxbreakdownfunc qrcodepath currency vendor) 
  (function (lambda ()
    (progn
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vendor Name%" invoicetemplate (nst-slot-str vendor 'name)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vendor Address%" invoicetemplate (nst-slot-str vendor 'address)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vendor Phone%" invoicetemplate (nst-slot-str vendor 'phone)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vendor Email%" invoicetemplate (nst-slot-str vendor 'email)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vendor GST%" invoicetemplate (nst-slot-str vendor 'gstnumber)))
      ;; template header / footer / logo, all driven by the vendor's invoice print settings.
      ;; "enable" gates the text only : the logo is controlled by the logo path alone.
      (let* ((printsettings (nst-get-vendor-invoiceprintsettings vendor))
	     (headersettings (invoiceprintsettingvalue printsettings "HEADER"))
	     (footersettings (invoiceprintsettingvalue printsettings "FOOTER"))
	     (headertext (if (invoiceprintsettingvalue headersettings "ENABLE")
			     (or (invoiceprintsettingvalue headersettings "TEXT") "")
			     ;;else
			     ""))
	     (footertext (if (invoiceprintsettingvalue footersettings "ENABLE")
			     (or (invoiceprintsettingvalue footersettings "TEXT") "")
			     ;;else
			     ""))
	     (logoimage (nst-invoice-logo-image-tag (invoiceprintsettingvalue headersettings "LOGOPATH"))))
	(setf invoicetemplate (cl-ppcre:regex-replace-all "%Template Logo Image%" invoicetemplate logoimage))
	(setf invoicetemplate (cl-ppcre:regex-replace-all "%Template Header%" invoicetemplate headertext))
	(setf invoicetemplate (cl-ppcre:regex-replace-all "%Template Footer%" invoicetemplate footertext))))

    (with-slots (row-id invnum invdate customer  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear status vendor company) invheader
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Number%" invoicetemplate (or invnum "")))
      ;;(setf invoicetemplate (cl-ppcre:regex-replace-all "%Order Number%" invoicetemplate ordernum))
      ;;(setf invoicetemplate (cl-ppcre:regex-replace-all "%Order Date%" invoicetemplate orderdate))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Date%" invoicetemplate (or (get-date-string invdate) "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Status%" invoicetemplate (or status "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Date of Supply%" invoicetemplate ""))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%State Code%" invoicetemplate (or (gethash statecode *NSTGSTSTATECODES-HT*) "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Place of Supply%" invoicetemplate (or (gethash placeofsupply *NSTGSTSTATECODES-HT*) "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Reverse Charge%" invoicetemplate (or revcharge "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vehicle Number%" invoicetemplate (or vnum "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Transportation Mode%" invoicetemplate (or transmode "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Billed To%" invoicetemplate (nst-slot-str customer 'name)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Shipped To%" invoicetemplate (nst-slot-str customer 'name)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Billed to Address%" invoicetemplate (or billaddr "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Shipped to Address%" invoicetemplate (or shipaddr "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Billed to GSTIN%" invoicetemplate (or custgstin "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Shipped to GSTIN%" invoicetemplate (or custgstin "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Billed to State%" invoicetemplate (or (gethash statecode *NSTGSTSTATECODES-HT*) "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Shipped to State%" invoicetemplate (or (gethash statecode *NSTGSTSTATECODES-HT*) "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%UPI_IMAGE_URL%" invoicetemplate (or qrcodepath "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total in Words%" invoicetemplate (convert-number-to-words-INR (calculate-invoice-totalaftertax invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total Value%" invoicetemplate (format nil "~A" (calculate-invoice-totalaftertax invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total Value before GST/TAX%" invoicetemplate (format nil "~A" (calculate-invoice-totalbeforetax invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total After Tax%" invoicetemplate (format nil "~A ~A" (get-currency-html-symbol currency) (calculate-invoice-totalaftertax invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Tax Amount%" invoicetemplate (format nil "~A" (calculate-invoice-totalgst invheader invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Add CGST%" invoicetemplate (format nil "~A" (calculate-invoice-totalcgst invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Add SGST%" invoicetemplate (format nil "~A" (calculate-invoice-totalsgst invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Add IGST%" invoicetemplate (format nil "~A" (calculate-invoice-totaligst invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Terms and Conditions%" invoicetemplate (or tnc "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Authorised Signatory%" invoicetemplate (or authsign "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Financial Year%" invoicetemplate (or finyear "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Company Name%" invoicetemplate (nst-slot-str company 'name)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Bank IFSC Code%" invoicetemplate (or bankifsccode "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Bank Account Number%" invoicetemplate (or bankaccnum "")))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%GST on Reverse Charge%" invoicetemplate (or revcharge ""))))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Items Rows%" invoicetemplate (funcall invoiceitemshtmlfunc)))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%GST Tax Breakdown%" invoicetemplate (funcall invoicetaxbreakdownfunc)))
      invoicetemplate)))
      

(defun com-hhub-transaction-display-invoice-public ()
    (with-mvc-ui-page "Display Invoice Public" #'create-model-for-displayinvoicepublic #'create-widgets-for-displayinvoicepublic :role :vendor))

;;;;;;;;;;;;;;;;;;;;;;;; INVOICE EMAIL OPTIONS MENU ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun invoice-email-options-menu (status sessioninvkey)
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "dropdown"  
	      (:button :id "idinvoiceemailmenu" :class "btn  dropdown-toggle" :type "button" :data-bs-toggle "dropdown" :aria-expanded "false"
		       (:i :class "fa-regular fa-envelope"))
	      (:ul :class "dropdown-menu" :aria-labelledby "idinvoiceemailmenu" 
		   (:li (:h6 :class "dropdown-header" "Send Invoice Email Options"))
		   (if (equal status "DRAFT")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=1" sessioninvkey) (:i :class "fa-regular fa-pen-to-square") "&nbsp;Draft/Proforma Invoice")))
		       ;;else
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-regular fa-pen-to-square") "&nbsp;Draft/Proforma Invoice"))))
		   (:li (:hr :class "dropdown-divider"))
		   (if (equal status "PENDINGPAYMENT")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=2" sessioninvkey) (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Payment Reminder"))
			(:li 
		    (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=3" sessioninvkey) (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Overdue Payment Reminder")))
		       ;;else
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Payment Reminder")
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Overdue Payment Reminder"))))
		   (if (equal status "PAID")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=4" sessioninvkey) (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Paid Invoice")))
		       ;;else
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Paid Invoice"))))
		   (:li (:hr :class "dropdown-divider"))
		   (if (equal status "SHIPPED")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=5" sessioninvkey) (:i :class "fa-solid fa-truck-fast") "&nbsp;Shipped Invoice")))
		       ;;else
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-truck-fast") "&nbsp;Shipped Invoice"))))
		   
		   (if (equal status "CANCELLED")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=6" sessioninvkey) (:i :class "fa-solid fa-xmark") "&nbsp;Cancelled Invoice")))
		       ;;else
		       (cl-who:htm
			(:li
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-xmark") "&nbsp;Cancelled Invoice"))))
		   (if (equal status "REFUNDED")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=7" sessioninvkey) (:i :class "fa-solid fa-arrow-rotate-left") "&nbsp;Returned/Refunded Invoice")))
		       ;;else
		       (cl-who:htm
			(:li
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-arrow-rotate-left") "&nbsp;Returned/Refunded Invoice"))))
		   ))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;; INVOICE ACTION MENU ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun invoice-header-actions-menu (external-url status sessioninvkey customer)
  (let ((phone (slot-value customer 'phone))
	;; ── THE VENDOR'S OWN VIEW OF THE SHAREABLE LINK ───────────────────────────
	;; Bound OUT HERE, not inside the cl-who form: cl-who converts tag forms only in a
	;; body position and does NOT recurse into a `let`, so a binding placed inside the
	;; markup would break the tags around it (the same trap as (:div …) inside `when`).
	;; The stored link is only five minutes old at best, so this is usually :EXPIRED —
	;; which is exactly the fact the vendor had no way of seeing.
	(linkstatus (invoice-ext-url-status external-url)))
    (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row :style "border-radius: 5px;background-color:#e6f0ff; border-bottom: solid 1px; margin: 15px; padding: 5px; height: 30px; font-size: 1rem;"
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Print Invoice"
	(:a :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) :onclick (format nil "window.open(this.href).print(); return false;") (:i :class "fa-solid fa-print")))
      (with-html-div-col-1
	(invoice-email-options-menu status sessioninvkey))
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Duplicate Invoice"
	(:a :href "#"  (:i :class "fa-regular fa-clone")))
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Download Invoice PDF"
	(with-html-form-having-submit-event "invoicedownloadform" "downloadinvoice"
	  (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
	  (:button :class "btn" :type "submit" :id "iddownloadinvoicebtn" (:i :class "fa-regular fa-file-pdf"))))
      (if external-url
	  (cl-who:htm
	   ;; RED WHEN THE LINK CANNOT BE OPENED, normal colour once NEXT has re-issued it.
	   ;; `text-danger` is the tree's own idiom (dod-ui-cus.lisp, dod-ui-prd.lisp).
	   (with-html-div-col-1  :data-bs-toggle "popover" :title (invoice-ext-url-share-title linkstatus)
	     (:a :href "#" :OnClick (parenscript:ps (copy-to-clipboard (parenscript:lisp external-url)))
		(:i :class (if (eq linkstatus :valid)
			       "fa-solid fa-link"
			       "fa-solid fa-link text-danger")))))
	  ;;else
	  (cl-who:htm
	   (with-html-div-col-1 "&nbsp;")))
      
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Customer WhatsApp" 
	(:a :target "_blank" :style "font-weight: bold; font-size: 1.2rem !important;"  :href (format nil "createwhatsapplinkwithmessage?phone=~A&message=Hi" phone)  (:i :class "fa-brands fa-whatsapp")))
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-2 :align "right" :data-bs-toggle "popover" :title "DELETE INVOICE!" 
	(:a :onclick "return DeleteConfirm();"  :href "#" (:i :class "fa-solid fa-trash-can")))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ALL INVOICES ACTION MENU ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun invoices-actions-menu (sessioninvkey)
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row :style "border-radius: 5px;background-color:#e6f0ff; border-bottom: solid 1px; margin: 15px; padding: 5px; height: 30px; font-size: 1rem;"
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Print Invoice"
	(:a :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) :onclick (format nil "window.open(this.href).print(); return false;") (:i :class "fa-solid fa-print")))
      (with-html-div-col-1 :data-bs-toggle "popover" :title "GSTR1 JSON"
	(:a :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) :onclick (format nil "window.open(this.href).print(); return false;") (:img :src  "/img/json-file-icon.png"  :height "22" :width "22" :alt "checkout")))
      
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-2 :align "right" :data-bs-toggle "popover" :title "Settings"
	(:a :href (format nil "vinvoicesettingspage?sessioninvkey=~A" sessioninvkey) (:i :class "fa-solid fa-gear"))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;; INVOICE PAID ACTION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun com-hhub-transaction-invoice-paid-action ()
  (with-vend-session-check ;; delete if not needed. 
    (let ((uri (with-mvc-redirect-ui #'create-model-for-invoicepaidaction #'create-widgets-for-genericredirect)))
      (format nil "~A" uri))))

(defun create-model-for-invoicepaidaction ()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (status (hunchentoot:parameter "status"))
	 (productlist (hhub-get-cached-vendor-products))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (invoiceitems (slot-value sessioninvoice 'InvoiceItems))
	 (totalvalue (calculate-invoice-totalaftertax invoiceitems))
	 (totalinwords (convert-number-to-words-INR totalvalue))
	 (invnum (slot-value sessioninvheader 'invnum))
	 (requestmodel (make-instance 'InvoiceHeaderStatusRequestModel
					 :invnum invnum
					 :status status
					 :payment-status status
					 :totalvalue totalvalue
					 :totalinwords totalinwords
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (redirectlocation  (format nil "/hhub/displayinvoices"))
	 (params nil))
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-invoice-paid-action" params
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (when sessioninvoice
	      (setf (slot-value sessioninvoice 'invoiceheader) domainobj)
	      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
	      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
	      (updateinvoiceitemsstockinventory productlist invoiceitems vendor company))
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getexceptionstr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))

(defun updateinvoiceitemsstockinventory (products invoiceitems vendor company)
  (mapcar (lambda (item)
	    (let* ((prd-id (slot-value item 'prd-id))
		   (qty (slot-value item 'qty))
		   (prd (search-item-in-list 'row-id prd-id products)))
	      (if prd (update-stock-inventory prd qty)))) invoiceitems)
  ;; reset the vendor order functions
  (dod-reset-vendor-products-functions vendor company))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;; SHOW THE INVOICE PAYMENT PAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun com-hhub-transaction-show-invoice-payment-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Invoice Payment Page" #'create-model-for-showinvoicepaymentpage #'create-widgets-for-showinvoicepaymentpage :role :vendor )))

(defun create-model-for-showinvoicepaymentpage ()
  (let* ((company (get-login-vendor-company))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (status (hunchentoot:parameter "status"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (invoiceheader (slot-value sessioninvoice 'invoiceheader))
	 (invnum (slot-value invoiceheader 'invnum))
	 (invoiceitems (slot-value sessioninvoice 'InvoiceItems))
	 (totalvalue (calculate-invoice-totalaftertax invoiceitems))
	 (requestmodel (make-instance 'InvoiceHeaderStatusRequestModel
					 :invnum invnum
					 :status status
					 :payment-status "PENDING"
					 :totalvalue totalvalue
					 :company company))
	 (headeradapter (make-instance 'InvoiceHeaderAdapter))
	 (params nil))
    
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-show-invoice-payment-page" params
      (handler-case 
      (let ((domainobj (ProcessUpdateRequest headeradapter requestmodel)))
	(when sessioninvoice
	  (setf (slot-value sessioninvoice 'invoiceheader) domainobj)
	  (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
	  (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht))	   
	(function (lambda ()
	  (values sessioninvkey totalvalue invnum))))
	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getexceptionstr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))

(defun create-widgets-for-showinvoicepaymentpage (modelfunc)
  (multiple-value-bind (sessioninvkey totalvalue invnum) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      )))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (with-html-div-col-4
			    (:h5 :class "no-print" "Invoice Payment - Step 5:")
			    (:a :class "btn btn-primary btn-lg" :role "button" :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) :onclick (format nil "window.open(this.href).print(); return false;")   "Print&nbsp;&nbsp;"(:i :class "fa-solid fa-print")))
			  (with-html-div-col-4
			    (:a :role "button" :class "btn btn-lg btn-primary btn-block no-print" :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) "Previous"))
			  (with-html-div-col-4
			    (with-html-form-having-submit-event "form-invoicepaidaction"  "vinvoicepaidaction" 
			      (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
			      (with-html-input-text-hidden "status" "PAID")
			      (:button :class "btn btn-lg btn-primary btn-block no-print" :type "submit" "FINISH"))))))))
      (widget3 (function (lambda ()
		 (cl-who:with-html-output (*standard-output* nil)
		   (display-invoice-payment-widget totalvalue))))))
      (list widget1 widget2 widget3))))

(defun display-invoice-payment-widget ( amountdue)
  (let ((filecontent (funcall (nst-get-cached-invoice-template-func :templatenum 8))))
    (setf filecontent (format nil filecontent amountdue amountdue))
    (cl-who:with-html-output (*standard-output* nil)
      (cl-who:str filecontent))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;; SHOW THE INVOICE FINAL PAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun com-hhub-transaction-show-invoice-confirm-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Invoice Confirm Page" #'create-model-for-showinvoiceconfirmpage #'create-widgets-for-showinvoiceconfirmpage :role :vendor )))

(defun remove-invoice-item-markers-from-template (invoicetemplate)
  ;; Clean the invoice item markers from original template
  (let* ((row-regex "(?s)<!--ROW_SNIPPET_BEGIN-->(.*?)<!--ROW_SNIPPET_END-->")
         (row-sub-template (cl-ppcre:register-groups-bind (snippet) (row-regex invoicetemplate) snippet)))
    (setf invoicetemplate (cl-ppcre:regex-replace-all row-sub-template invoicetemplate ""))
    invoicetemplate))

(defun create-model-for-showinvoiceconfirmpage ()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvtaxbreakdown (slot-value sessioninvoice 'invoicetaxbreakdown))
	 (context-id (slot-value sessioninvheader 'context-id)) 
	 (hrequestmodel (make-instance 'InvoiceHeaderContextIDRequestModel
				      :context-id context-id
				      :company company))
	 (headeradapter (make-instance 'InvoiceHeaderAdapter))
	 (invheader (processreadrequest headeradapter hrequestmodel))
         (invnum (slot-value invheader 'invnum))
	 (status (slot-value invheader 'status))
	 (irequestmodel (make-instance 'InvoiceItemRequestModel
				       :company company
				       :invoiceheader invheader))
	 (itemsadapter (make-instance 'InvoiceItemAdapter))
	 (sessioninvitems (processreadallrequest itemsadapter irequestmodel))
	 (totalvalue (calculate-invoice-totalaftertax sessioninvitems))
	 (qrcodepath (format nil "~A/img~A" *siteurl* (generateqrcodeforvendor vendor "ABC" invnum totalvalue)))
	 (templatenum (let* ((reqtemplatenum (hunchentoot:parameter "templatenum"))
			     (reqtemplatenum-int (and reqtemplatenum (parse-integer reqtemplatenum :junk-allowed t)))
			     (reqtemplatenum-str (and reqtemplatenum-int (format nil "~A" reqtemplatenum-int))))
			(if (and reqtemplatenum-str (gethash reqtemplatenum-str *NST-GSTINVOICE-TEMPLATES-HT*))
			    reqtemplatenum-int
			    ;; else
			    (nst-get-vendor-invoicetemplatenum vendor))))
	 (invoicetemplate (funcall (nst-get-cached-invoice-template-func :templatenum templatenum)))
	 (invoiceitemshtmlfunc (generate-invoice-items-rows  sessioninvitems (if (equal status "PAID") T NIL) sessioninvkey invoicetemplate))
	 (invoicetaxbreakdownfunc (render-tax-summary-html sessioninvtaxbreakdown))
	 ;;(invoiceitemshtmlfunc (invoicetemplatefillitemrows sessioninvitems (if (equal status "PAID") T NIL) sessioninvkey))
	 (currency (get-account-currency company))
	 (params nil))
 
    (setf invoicetemplate (remove-invoice-item-markers-from-template invoicetemplate))
    ;; every selectable template gets the same 4-Eye Review Mode control bar
    (if *NST-INVOICE-REVIEWCONTROLS-HTML*
	(setf invoicetemplate (concatenate 'string *NST-INVOICE-REVIEWCONTROLS-HTML* invoicetemplate)))
    (setf invoicetemplate (funcall (invoicetemplatefill invoicetemplate invheader sessioninvitems invoiceitemshtmlfunc invoicetaxbreakdownfunc qrcodepath currency vendor)))
    (setf (slot-value sessioninvoice 'InvoiceItems) sessioninvitems)
    (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
    (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)	   
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    
    (with-hhub-transaction "com-hhub-transaction-show-invoice-confirm-page" params 
      (function (lambda ()
	(values sessioninvkey invnum  invoicetemplate templatenum))))))


(defun create-widgets-for-showinvoiceconfirmpage (modelfunc)
  (multiple-value-bind (sessioninvkey  invnum  invoicetemplate templatenum) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(:form :method "GET" :action "/hhub/vshowinvoiceconfirmpage" :class "no-print"
			  (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
			  (:div :class "form-group"
				(:label :for "idtemplatenum" "Invoice Template")
				(with-html-dropdown "templatenum" *NST-GSTINVOICE-TEMPLATES-HT* (format nil "~A" templatenum) "this.form.submit();")))))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (with-html-div-col-4 "")
			  (with-html-div-col-4
			    (:a :role "button" :class "btn btn-lg btn-primary btn-block no-print" :href (format nil "vproductsforinvoicepage?sessioninvkey=~A" sessioninvkey) "Previous"))
			  (with-html-div-col-4
			    (with-html-form  (format nil "form-invoicepaymentpage")  "vinvoicepaymentpage" 
			      (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
			      (with-html-input-text-hidden "invnum" invnum)
			      (with-html-input-text-hidden "status" "PENDINGPAYMENT")
			      (:button :class "btn btn-lg btn-primary btn-block no-print" :type "submit" "NEXT"))))
			(:br)))))
	   (widget3 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-catch-submit-event "idinvoiceconfirmpage2"
			  (cl-who:str invoicetemplate)))))))
	   (list widget1 widget2 widget3))))
	

(defun calculate-invoice-totalbeforetax (invoiceitems)
  (fround (reduce #'+ (mapcar (lambda (item) (slot-value item 'taxablevalue)) invoiceitems))))

(defun calculate-invoice-totalaftertax (invoiceitems)
  (fround (reduce #'+ (mapcar (lambda (item)
					    (let* ((cgstamt (slot-value item 'cgstamt))
						   (sgstamt (slot-value item 'sgstamt))
						   (igstamt (slot-value item 'igstamt))
						   (taxablevalue (slot-value item 'taxablevalue)))
					      (+ taxablevalue sgstamt cgstamt igstamt))) invoiceitems))))



(meta calculate-invoice-totalcgst
  '((:description . "Calculates total CGST amount for an invoice by summing CGST across all line items")
    (:domain      . :invoice)
    (:category    . :calculation)
    (:tags        . (:tax :cgst :invoice :totals))
    (:inputs      . (((:name . invoiceitems) (:type . list)  (:required . t)   (:source . :parameter))))
    (:outputs     . (((:name . total-cgst) (:type . decimal) (:binds-as . :cgst-amount))))
    (:reads       . (:invoice-line-items))
    (:writes      . nil)
    (:throws      . nil)
    (:pure        . nil)
    (:cost        . :low)))

(defun calculate-invoice-totalcgst (invoiceitems)
 (reduce #'+ (mapcar (lambda (item) (slot-value item 'cgstamt)) invoiceitems)))

(meta calculate-invoice-totalsgst
  '((:description . "Calculates total SGST amount for an invoice by summing SGST across all line items")
    (:domain      . :invoice)
    (:category    . :calculation)
    (:tags        . (:tax :sgst :invoice :totals))
    (:inputs      . (((:name . invoiceitems) (:type . list)  (:required . t)   (:source . :parameter))))
    (:outputs     . (((:name . total-sgst) (:type . decimal) (:binds-as . :sgst-amount))))
    (:reads       . (:invoiceitems))
    (:writes      . nil)
    (:throws      . nil)
    (:pure        . nil)
    (:cost        . :low)))

(defun calculate-invoice-totalsgst (invoiceitems)
 (reduce #'+ (mapcar (lambda (item) (slot-value item 'sgstamt)) invoiceitems)))

(meta calculate-invoice-totaligst
  '((:description . "Calculates total IGST amount for an invoice by summing IGST across all line items")
    (:domain      . :invoice)
    (:category    . :calculation)
    (:tags        . (:tax :igst :invoice :totals))
    (:inputs      . (((:name . invoiceitems) (:type . list)  (:required . t)   (:source . :parameter))))
    (:outputs     . (((:name . total-igst) (:type . decimal) (:binds-as . :igst-amount))))
    (:reads       . (:invoiceitems))
    (:writes      . nil)
    (:throws      . nil)
    (:pure        . nil)
    (:cost        . :low)))

(defun calculate-invoice-totaligst (invoiceitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'igstamt)) invoiceitems)))


(meta calculate-invoice-totalgst
  '((:description . "Calculates total GST amount for an invoice by summing GST across all line items")
    (:domain      . :invoice)
    (:category    . :calculation)
    (:tags        . (:tax :gst :invoice :totals))
    (:inputs      . (((:name . invoiceitems) (:type . list)  (:required . t)   (:source . :parameter))))
    (:outputs     . (((:name . total-gst) (:type . decimal) (:binds-as . :gst-amount))))
    (:reads       . (:invoiceitems))
    (:writes      . nil)
    (:throws      . nil)
    (:pure        . nil)
    (:cost        . :low)))

(defun calculate-invoice-totalgst (invoiceheader invoiceitems)
  (let ((placeofsupply (slot-value invoiceheader 'placeofsupply))
	(statecode (slot-value invoiceheader 'statecode)))
    (if (equal placeofsupply statecode)
	(fround (+ (calculate-invoice-totalcgst invoiceitems) (calculate-invoice-totalsgst invoiceitems)))
	;;else
	(fround (calculate-invoice-totaligst invoiceitems)))))

(defun display-invoice-confirm-page-widget (invoiceheader invoiceitems qrcodepath sessioninvkey)
  (with-slots (row-id invnum invdate customer  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear status vendor company) invoiceheader
    (cl-who:with-html-output (*standard-output* nil)
      (:style "table {width: 100%; border-collapse: collapse;} table.center {margin-left: auto; margin-right: auto;} table, th, td {border: 0.5px dashed grey;} th, td { padding: 1px; text-align: left;} td img{ display: block; margin-left: auto; margin-right: auto; } ")
      (:table 
       (:thead
	(:tr 
	 (:th :colspan "2" "TAX INVOICE")
	 (:th :colspan "3" "Original For Recipient")
	 (:th :colspan "3" "Duplicate for Supplier")
	 (:th :colspan "3" "Triplicate for Supplier")))
	   (:tbody
	    (:tr
	     (:td :colspan "2" "Invoice No. :")
	     (:td :colspan "2" (cl-who:str invnum))
	     (:td :colspan "2" "Status: ")
	     (:td :colspan "2" (cl-who:str status))
	     (if (not (equal transmode "NA"))
		 (cl-who:htm 
		  (:td :colspan "2" "Transportation Mode:")
		  (:td :colspan "1" (cl-who:str transmode))
		  (:td :colspan "2" "Vehicle Number :")
		  (:td :colspan "1" (cl-who:str vnum)))))
	    (:tr
	     (:td :colspan "2" "Invoice Date:")
	     (:td :colspan "2" (cl-who:str (get-date-string invdate)))
	     (:td :colspan "2" "Date of Supply :")
	     (:td :colspan "2" "Place of Supply :")
	     (:td :colspan "2" (cl-who:str (gethash placeofsupply *NSTGSTSTATECODES-HT*)))
	     (:td :colspan "2" "State Code:")
	     (:td :colspan "2" (cl-who:str (gethash statecode *NSTGSTSTATECODES-HT*))))
	    (:tr
	     (:th :colspan "5" "Details of Receiver / Billed to:")
	     (:th :colspan "5" "Details of Consignee / Shipped to:"))
	    (:tr
	     (:td :colspan "2" "Name :")
	     (:td :colspan "3" (cl-who:str (slot-value customer 'name)))
	     (:td :colspan "2" "Name :")
	     (:td :colspan "3" (cl-who:str (slot-value customer 'name))))
	    (:tr
	     (:td :colspan "2" "Address :")
	     (:td :colspan "3" (cl-who:str billaddr))
	     (:td :colspan "2" "Address :")
	     (:td :colspan "3" (cl-who:str shipaddr)))
	    (:tr
	     (:td :colspan "2" "GSTIN :")
	     (:td :colspan "3" (cl-who:str custgstin))
	     (:td :colspan "2" "GSTIN :")
	     (:td :colspan "3" (cl-who:str custgstin)))
	    (:tr
	     (:td :colspan "2" "State :")
	     (:td :colspan "3" (cl-who:str (gethash statecode *NSTGSTSTATECODES-HT*)))
	     (:td :colspan "2" "State :")
	     (:td :colspan "3" (cl-who:str (gethash statecode *NSTGSTSTATECODES-HT*))))
	    (:tr
	     (:th "Sr. No")
	     (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) (list "Name of Product/Service" "HSN/SAC" "Qty Per Unit" "Qty" "Rate"  "Less: Discount%" "Taxable Value" "CGST" "SGST" "IGST" "Total" "Action")))
	    (let ((incr (let ((count 0)) (lambda () (incf count)))))
	      (mapcar (lambda (item)
			(cl-who:htm (:tr (:td (cl-who:str (funcall incr))) (display-invoice-item-row item (if (equal status "PAID") T NIL) sessioninvkey))))  invoiceitems))
	    ;;<!-- Repeat <tr> as needed for more items -->
	    (:tr
	     (:td :colspan "3" "Total :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalaftertax invoiceitems)))
	     (:td :colspan "7"))
	    (:tr
	     (:td :colspan "3" "Total Invoice Amount in Words:")
	     (:td :colspan "3" (cl-who:str (convert-number-to-words-INR (calculate-invoice-totalaftertax invoiceitems))))
	     (:td :colspan "7"))
	    (:tr
	     (:td :colspan "7" "Bank Details :")
	     (:td :colspan "3" "Total Amount Before Tax :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalbeforetax invoiceitems))))
	    (:tr
	     (:td :colspan "3" "Bank Account Number:")
	     (:td :colspan "4" (cl-who:str bankaccnum))
	     (:td :colspan "3" "Add : CGST :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalcgst invoiceitems))))
	    (:tr
	     (:td :colspan "2" "Bank Branch IFSC :")
	     (:td :colspan "5" (cl-who:str bankifsccode))
	     (:td :colspan "3" "Add : SGST :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalsgst invoiceitems))))
	    (:tr
	     (:td :rowspan "6" :colspan "7" (:img :style "width: 150px; height: 150px;" :src qrcodepath (:span "Pay By UPI")))
	     (:td :colspan "3" "Add : IGST :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totaligst invoiceitems))))
	    (:tr
	     (:td :colspan "3" "Tax Amount : GST :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalgst invoiceheader invoiceitems))))
	    (:tr
	     (:td :colspan "3" "Total Amount After Tax :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalaftertax invoiceitems))))
	    (:tr
	     (:td :colspan "3" "GST Payable on Reverse Charge :")
	     (:td :colspan "3" (cl-who:str revcharge)))
	    (:tr
	     (:td :colspan "4" "Certified that the particulars given above are true and correct.")
	     (:td :colspan "2" "(Authorized Signatory)"))
	    (:tr
	     (:td :colspan "6" "For, [Company Name]"))
	    (:tr
	     (:td :colspan "13" "Terms and Conditions :"))
	    (:tr
	     (:td :colspan "13" (cl-who:str tnc))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;; ADD PRODUCT TO CART TO CREATE AN INVOICE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun com-hhub-transaction-add-product-to-invoice-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Add Product To Invoice" #'create-model-for-addprdtoinvoice #'create-widgets-for-addprdtoinvoice :role :vendor )))

(defun create-model-for-addprdtoinvoice ()
  (let* ((sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (invnum (slot-value sessioninvheader 'invnum))
	 (headerstatus (slot-value sessioninvheader 'status))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (sessioninvproducts (slot-value sessioninvoice 'invoiceproducts))
	 (products (hhub-get-cached-active-vendor-products)))
    (function (lambda ()
      (values products sessioninvitems sessioninvproducts  headerstatus sessioninvkey invnum)))))

(defun create-widgets-for-addprdtoinvoice (modelfunc)
  (multiple-value-bind (products sessioninvitems sessioninvproducts headerstatus sessioninvkey invnum) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
				(:span "Create Invoice - Step 3:")))))))
	   (widget2 (function (lambda ()
		      (if (or (equal headerstatus "PAID")
			      (equal headerstatus "SHIPPED")
			      (equal headerstatus "CANCELLED")
			      (equal headerstatus "REFUNDED"))
			  (cl-who:with-html-output (*standard-output* nil)
			    (:h2 (cl-who:str (format nil "INVOICE IS ~A" headerstatus))))
			    ;;else
			  (cl-who:with-html-output (*standard-output* nil)
			    (with-html-div-row
			      (with-html-div-col-4 
				(with-html-search-form "idsearchproduct" "searchproduct" "idtxtsearchproduct" "txtsearchproduct" "vsearchproductforinvoice" "onkeyupsearchform1event();" "Product Name"
				  (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
				  (submitsearchform1event-js "#idtxtsearchproduct" "#vendorproductsearchforinvoiceresult" )))
			      (with-html-div-col-4
				(with-html-form-having-submit-event  "barcodescanform" "vaddtocartusingbarcode"
				  ;; here we would like to auto focus on the barcode textbox to input the next barcode upon page reload.
				  (with-html-input-text "barcodeinput" "Product Barcode/UPC/EAN" "Enter Barcode/UPC/EAN" "" NIL "" 1 :autofocus "autofocus")
				  (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
				  (:input :type "submit" :style "display: none;")))
			      (with-html-div-col-4
				    (:a :href (format nil "/hhub/vshowinvoiceconfirmpage?sessioninvkey=~A&templatenum=~A" sessioninvkey (nst-get-vendor-invoicetemplatenum)) 
					(:img :src  "/img/checkoutimage.png"  :height "100" :width "350" :alt "checkout"))))
			    (:h2 "Cart Items")
			    (cl-who:str (display-as-table (list "" "Name" "Qty Per Unit" "Price" "" "Discount" "In Cart") sessioninvproducts  'display-product-in-invoice-row sessioninvkey sessioninvitems))
			    (:h2 "Products")
			    (:div :id "vendorproductsearchforinvoiceresult"  :class "container-fluid"
				  (cl-who:str (display-as-table (list "" "Name" "Qty Per Unit" "Price" "" "Discount" "Action") products  'display-add-product-to-invoice-row sessioninvkey sessioninvitems))))))))
	   (widget3 (function (lambda ()
		      (submitformevent-js "#vendorproductsearchforinvoiceresult")))))
      (list widget1 widget2 widget3))))
	   
(defun display-add-product-to-invoice-row (product &rest arguments)
  (let* ((sessioninvkey (first (first arguments)))
	 (sessioninvitems (second (first arguments)))
	 (prd-id (slot-value product 'row-id))
	 ;;(qtyincart 0)
	 (prdincart-p (prdinlist-p prd-id sessioninvitems))
	 (prdname (slot-value product 'prd-name))
	 (prd-name (subseq prdname 0 (min 20 (length prdname))))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (company (get-login-vendor-company))
	 (current-price (slot-value product 'current-price))
	 (current-discount (slot-value product 'current-discount))
	 (ppricing (select-product-pricing-by-product-id prd-id company))
	 (pcurr (if ppricing (slot-value ppricing 'currency))))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (render-single-product-image prd-name imageslst images-str "50" "50"))
      (:td  :height "10px" (cl-who:str prd-name))
      (:td  :height "10px" (cl-who:str qty-per-unit))
      (:td  :height "10px" (cl-who:str current-price))
      (:td  :height "10px" (cl-who:str pcurr))
      (:td  :height "10px" (cl-who:str (if current-discount current-discount "NIL")))
      (:td  :height "10px"
	    (if  prdincart-p
		 (cl-who:htm (:a :class "btn btn-sm btn-success" :role "button"  :onclick "return false;" :href (format nil "javascript:void(0);")(:i :class "fa-solid fa-check")))
		 ;; else 
		 (if (and units-in-stock (> units-in-stock 0))
		     (cl-who:htm
		      (:div :class "form-group product-details"
			    (:button :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id) :type "button" :class "add-to-cart-btn" :data-bs-toggle "modal" :data-bs-target (format nil "#producteditqty-modal~A" prd-id) (:i :class "fa-solid fa-cart-shopping") "&nbsp;Add To Cart")
			    (modal-dialog-v2 (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (vproduct-qty-add-for-invoice-html product ppricing sessioninvkey))))			
		     ;; else
		     (cl-who:htm
		      (:div :class "col-6" 
			    (:h5 (:span :class "label label-danger" "Out Of Stock"))))))))))

(defun display-product-in-invoice-row (product &rest arguments)
  (let* ((sessioninvkey (first (first arguments)))
	 (sessioninvitems (second (first arguments)))
	 (prd-id (slot-value product 'row-id))
	 ;;(qtyincart 0)
	 (prdincart-p (prdinlist-p prd-id sessioninvitems))
	 (itemincart (if prdincart-p (search-item-in-list 'prd-id prd-id sessioninvitems) nil))
	 (qtyincart (if itemincart (slot-value itemincart 'qty)))
	 (prdname (slot-value product 'prd-name))
	 (prd-name (subseq prdname 0 (min 20 (length prdname))))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (company (get-login-vendor-company))
	 (price (slot-value product 'current-price))
	 (ppricing (select-product-pricing-by-product-id prd-id company))
	 (pprice (if ppricing (slot-value ppricing 'price)))
	 (pdiscount (if ppricing (slot-value ppricing 'discount)))
	 (pcurr (if ppricing (slot-value ppricing 'currency))))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (render-single-product-image prd-name imageslst images-str "30" "30"))
      (:td  :height "10px" (cl-who:str prd-name))
      (:td  :height "10px" (cl-who:str qty-per-unit))
      (:td  :height "10px" (cl-who:str (if ppricing pprice price)))
      (:td  :height "10px" (cl-who:str pcurr))
      (:td  :height "10px" (cl-who:str (if pdiscount pdiscount "NIL")))
      (:td  :height "10px"
	    (if  prdincart-p
		 (cl-who:htm  (:h4 (:span :class "badge rounded-pill bg-info" (cl-who:str (format nil "~A" qtyincart)))))
		 ;; else 
		 (if (and units-in-stock (> units-in-stock 0))
		     (cl-who:htm
		      (:div :class "form-group"
			    (:button :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id) :type "button" :class "add-to-cart-btn" :data-bs-toggle "modal" :data-bs-target (format nil "#producteditqty-modal~A" prd-id) (:i :class "fa-solid fa-cart-shopping") "&nbsp;Add To Cart")
			    (modal-dialog-v2 (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (vproduct-qty-add-for-invoice-html product ppricing sessioninvkey))))			
		     ;; else
		     (cl-who:htm
		      (:div :class "col-6" 
			    (:h5 (:span :class "label label-danger" "Out Of Stock"))))))))))


(defun vproduct-qty-add-for-invoice-html (product product-pricing sessioninvkey)
  (let* ((prd-id (slot-value product 'row-id))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (prd-name (slot-value product 'prd-name))
	 (hsn-code (slot-value product 'hsn-code)))
	
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-form  (format nil "form-addproduct~A" prd-id)  "vaddtocartforinvoice" 
      (with-html-input-text-hidden "prd-id" prd-id)
      (:p :class "product-name"  (cl-who:str prd-name))
      (:p :class "product-hsn-code" "HSN Code: " (cl-who:str hsn-code))
      (:a :href (format nil "prddetailsforcust?id=~A" prd-id) 
	  (render-single-product-image prd-name imageslst images-str "100" "83"))      
      (product-price-with-discount-widget product product-pricing)
      ;; Qty increment and decrement control.
      (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
      (html-range-control "prdqty" prd-id "1" (max (mod units-in-stock 20) 10) "1" "1")
      (:div :class "form-group" 
	    (:input :type "submit"  :class "btn btn-primary" :value "Add To Cart"))))))

(defun com-hhub-transaction-search-product-for-invoice-action ()
  (with-vend-session-check
    (let* ((company (get-login-vendor-company))
	   (name (hunchentoot:parameter "txtsearchproduct"))
	   (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	   (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	   (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	   (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	   (products (search-products (format nil "%~A%" name) company)))
      (if (> (length products) 0)
	  (cl-who:with-html-output (*standard-output* nil)
	    (cl-who:str (display-as-table (list "" "Name"  "Qty Per Unit" "Price" "" "Discount" "Action") products  'display-add-product-to-invoice-row sessioninvkey sessioninvitems)))
	  ;; else
	  (cl-who:with-html-output (*standard-output* nil)
	    (:h3 (cl-who:str "No Records Found")))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ADD TO CART BY VENDOR FOR INVOICE GENERATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun create-model-for-vendaddtocartforinvoice ()
  (let* ((company (get-login-vendor-company))
	 (prd-id (parse-integer (hunchentoot:parameter "prd-id")))
	 (prdqty (parse-integer (hunchentoot:parameter "prdqty")))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (sessioninvproducts (slot-value sessioninvoice 'invoiceproducts))
	 (sessioninvtaxbreakdown (slot-value sessioninvoice 'invoicetaxbreakdown))
	 (context-id (slot-value sessioninvheader 'context-id))
	 (customer (slot-value sessioninvoice 'customer))
	 (productlist (hhub-get-cached-vendor-products))
	 (product (search-item-in-list 'row-id prd-id productlist))
	 (gstvalues (get-gstvalues-for-product product))
	 (current-price (slot-value product 'current-price))
	 (current-discount (slot-value product 'current-discount))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (unit-of-measure (slot-value product 'unit-of-measure))
	 (pname (slot-value product 'prd-name))
	 (prd-name (subseq pname 0 (min 30 (length pname))))
	 (hsncode (slot-value product 'hsn-code))
	 (taxablevalue (- (* prdqty current-price) (if current-discount (/ (* prdqty  current-price current-discount) 100) 0.00)))
	 (placeofsupply (slot-value sessioninvheader 'placeofsupply))
	 (statecode (slot-value sessioninvheader 'statecode))
	 (intrastate (if (equal statecode placeofsupply) T NIL))
	 (interstate (if (equal statecode placeofsupply) NIL T)) 
	 (cgstrate (if gstvalues (first gstvalues) 0.00)) 
	 (cgstamt (if intrastate (/ ( * taxablevalue cgstrate) 100) 0.00))
	 (sgstrate (if gstvalues (second gstvalues) 0.00))
	 (sgstamt (if intrastate (/ (* sgstrate taxablevalue) 100) 0.00))
	 (igstrate (if gstvalues (third gstvalues) 0.00)) 
	 (igstamt (if interstate (/ (* igstrate taxablevalue) 100) 0.00))
	 (totalitemval (+ taxablevalue (if intrastate (+ cgstamt sgstamt) igstamt)))
	 (vendor (product-vendor product))
	 (wallet (get-cust-wallet-by-vendor customer vendor company))
	 (ihdadapter (make-instance 'InvoiceHeaderAdapter))
	 (ihdrequestmodel (make-instance 'InvoiceHeaderContextIDRequestModel
					 :context-id context-id
					 :company company))
	 (invheader (ProcessReadRequest ihdadapter ihdrequestmodel))
	 (redirectlocation (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A" sessioninvkey))
	 (invitmrequestmodel (make-instance 'InvoiceItemRequestModel
					 :InvoiceHeader invheader
					 :prd-id prd-id
					 :prddesc prd-name
					 :hsncode hsncode
					 :qty prdqty
					 :uom (format nil "~A ~A" qty-per-unit unit-of-measure)
					 :price current-price
					 :discount current-discount
					 :taxablevalue taxablevalue
					 :cgstrate cgstrate
					 :cgstamt cgstamt
					 :sgstrate sgstrate
					 :sgstamt sgstamt
					 :igstrate igstrate
					 :igstamt igstamt
					 :company company
					 :totalitemval totalitemval))
	 (invitmadapter (make-instance 'InvoiceItemAdapter))
	 (InvoiceItem (ProcessCreateRequest invitmadapter invitmrequestmodel)))
    ;;(logiamhere (format nil "Adding invoice item to cart ~A" InvoiceItem)) 
    (add-item-to-tax-breakdown sessioninvtaxbreakdown InvoiceItem)
    (unless wallet (create-wallet customer vendor company))
    (when (and wallet (> prdqty 0) sessioninvoice)
      (setf (slot-value sessioninvoice 'InvoiceItems) (append sessioninvitems (list invoiceitem)))
      (setf (slot-value sessioninvoice 'invoiceproducts) (append sessioninvproducts (list product)))
      (setf (slot-value sessioninvoice 'invoicetaxbreakdown) sessioninvtaxbreakdown)
      ;;(setf (hhub-get-cached-vendor-products) (remove product productlist))
      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
      (function (lambda ()
	(values redirectlocation))))))


(defun com-hhub-transaction-vendor-addtocart-for-invoice-action ()
  :documentation "This function is responsible for adding the product and product quantity to the shopping cart."
  (with-vend-session-check
    (with-mvc-redirect-ui #'create-model-for-vendaddtocartforinvoice #'create-widgets-for-genericredirect)))
    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ADD TO CART USING BARCODE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun create-model-for-vendaddtocartusingbarcode ()
  (let* ((company (get-login-vendor-company))
	 (barcode (hunchentoot:parameter "barcodeinput"))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (sessioninvproducts (slot-value sessioninvoice 'invoiceproducts))
	 (context-id (slot-value sessioninvheader 'context-id))
	 (customer (slot-value sessioninvoice 'customer))
	 (productlist (hhub-get-cached-vendor-products))
	 (product (search-item-in-list 'upc barcode productlist))
	 (prd-id (slot-value product 'row-id))
	 (itemincart (if (iteminlist-p 'prd-id prd-id sessioninvitems) (search-item-in-list 'prd-id prd-id sessioninvitems)))
	 (newqty (if itemincart (+ (slot-value itemincart 'qty) 1) 1))
	 (gstvalues (get-gstvalues-for-product product))
	 (current-price (slot-value product 'current-price))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (pname (slot-value product 'prd-name))
	 (prd-name (subseq pname 0 (min 30 (length pname))))
	 (hsncode (slot-value product 'hsn-code))
	 (product-pricing (select-product-pricing-by-product-id prd-id company))
	 (prd-discount (if product-pricing (slot-value product-pricing 'discount) nil))
	 (taxablevalue (- (* newqty current-price) (if prd-discount (/ (* newqty current-price prd-discount) 100) 0.00)))
	 (placeofsupply (slot-value sessioninvheader 'placeofsupply))
	 (statecode (slot-value sessioninvheader 'statecode))
	 (intrastate (if (equal statecode placeofsupply) T NIL))
	 (interstate (if (equal statecode placeofsupply) NIL T)) 
	 (cgstrate (if gstvalues (first gstvalues) 0.00)) 
	 (cgstamt (if intrastate (/ ( * taxablevalue cgstrate) 100) 0.00))
	 (sgstrate (if gstvalues (second gstvalues) 0.00))
	 (sgstamt (if intrastate (/ (* sgstrate taxablevalue) 100) 0.00))
	 (igstrate (if gstvalues (third gstvalues) 0.00)) 
	 (igstamt (if interstate (/ (* igstrate taxablevalue) 100) 0.00))
	 (totalitemval (+ taxablevalue (if intrastate (+ cgstamt sgstamt) igstamt)))
	 (vendor (product-vendor product))
	 (wallet (get-cust-wallet-by-vendor customer vendor company))
	 (ihdadapter (make-instance 'InvoiceHeaderAdapter))
	 (ihdrequestmodel (make-instance 'InvoiceHeaderContextIDRequestModel
					 :context-id context-id
					 :company company))
	 (invheader (ProcessReadRequest ihdadapter ihdrequestmodel))
	 (redirectlocation (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A" sessioninvkey))
	 (invitmrequestmodel (make-instance 'InvoiceItemRequestModel
					 :InvoiceHeader invheader
					 :prd-id prd-id
					 :prddesc prd-name
					 :hsncode hsncode
					 :qty newqty
					 :uom qty-per-unit
					 :price current-price
					 :discount prd-discount
					 :taxablevalue taxablevalue
					 :cgstrate cgstrate
					 :cgstamt cgstamt
					 :sgstrate sgstrate
					 :sgstamt sgstamt
					 :igstrate igstrate
					 :igstamt igstamt
					 :company company
					 :totalitemval totalitemval
					 :status "PENDING"))
	 (invitmadapter (make-instance 'InvoiceItemAdapter))
	 (InvoiceItem (if itemincart (ProcessUpdateRequest invitmadapter invitmrequestmodel) (ProcessCreateRequest invitmadapter invitmrequestmodel))))
		    
    (unless wallet (create-wallet customer vendor company))
    (when (and wallet sessioninvoice)
      (when  itemincart
	;; if updated an item using barcode then, we need to replace the current item
	(setf sessioninvitems (remove itemincart sessioninvitems))
	(setf sessioninvproducts (remove product sessioninvproducts)))
	;;(setf (hunchentoot:session-value :login-prd-cache) (remove product productlist)))
      ;; if created an item using barcode use this 
      (setf (slot-value sessioninvoice 'InvoiceItems) (append sessioninvitems (list invoiceitem)))
      (setf (slot-value sessioninvoice 'invoiceproducts) (append sessioninvproducts (list product)))
      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
      (function (lambda ()
	(values redirectlocation))))))

(defun create-widgets-for-vendaddtocartusingbarcode (modelfunc)
 (funcall #'create-widgets-for-genericredirect modelfunc))


(defun com-hhub-transaction-vendor-addtocart-using-barcode-action ()
  :documentation "This function is responsible for adding the product and product quantity to the shopping cart."
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui #'create-model-for-vendaddtocartusingbarcode #'create-widgets-for-vendaddtocartusingbarcode)))
      (format nil "~A" uri))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



(defun com-hhub-transaction-add-customer-to-invoice-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Add Customer To Invoice" #'create-model-for-addcusttoinvoice #'create-widgets-for-addcusttoinvoice :role  :vendor )))

(defun create-model-for-addcusttoinvoice()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (guestcustomer (select-guest-customer company))
	 (guestcustid (slot-value guestcustomer 'row-id))
	 (mycustomers (select-customers-for-vendor vendor company)))
    (function (lambda ()
      (values mycustomers guestcustid)))))

(defun create-widgets-for-addcusttoinvoice (modelfunc)
  (multiple-value-bind (mycustomers guestcustid) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
				(:span "Create Invoice - Step 1: ")
				(:h2 "Select Customer (Optional)"))
			  (:div :class "col-xs-3 col-sm-3 col-md-3 col-lg-3"
				(:button :type "button" :class "btn btn-lg btn-primary btn-block" :data-bs-toggle "modal" :data-bs-target (format nil "#vendorcreatecustomer-modal") (:i :class "fa-solid fa-user") "&nbsp;Add Customer")
				(modal-dialog-v2 (format nil "vendorcreatecustomer-modal")  "Create Customer" (vendor-create-update-customer-dialog nil)))
			  (:div :class "col-xs-3 col-sm-3 col-md-3 col-lg-3 form-group"
				(with-html-form (format nil "invoicecreateforcust~A" guestcustid) "editinvoicepage"
				  (with-html-input-text-hidden "mode" "create")
				  (with-html-input-text-hidden "custid" guestcustid)
				  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "NEXT"))))))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"    
				(with-html-search-form "idsearchmycustomerbyname" "searchmycustomer" "idtxtsearchcustomername" "txtsearchcustomername" "vsearchcustbyname" "onkeyupsearchform1event();" "Customer Name"
				  (submitsearchform1event-js "#idtxtsearchcustomername" "#vendormycustomerssearchresult" )))
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"    
				(with-html-search-form "idsearchmycustomerbyphone" "searchmycustomer" "idtxtsearchcustomerphone" "txtsearchcustomerphone" "vsearchcustbyphone" "onkeyupsearchform2event();" "Customer Phone"
				  (submitsearchform2event-js "#idtxtsearchcustomerphone" "#vendormycustomerssearchresult" ))))
			(:div :id "vendormycustomerssearchresult"  :class "container-fluid"
			      (cl-who:str (display-as-table (list "Name" "Phone" "Action") mycustomers 'display-add-customer-to-invoice-row))))))))
      (list widget1 widget2))))

(defun display-add-customer-to-invoice-row (customer &rest arguments)
  (declare (ignore arguments))
  (let* ((cust-id (slot-value customer 'row-id))
	 (cust-phone (slot-value customer 'phone))
	 (cust-name (slot-value customer 'name)))
    (with-slots (name phone address) customer
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str cust-name))
	(:td  :height "10px" (cl-who:str cust-phone))
	(:td  :height "10px"
	      (with-html-form (format nil "invoicecreateforcust~A" cust-id) "editinvoicepage"
		(with-html-input-text-hidden "mode" "create")
		(with-html-input-text-hidden "custid" cust-id)
		(:div :class "form-group"
			  (:button :class "btn btn-sm btn-info" :type "submit" (:i :class "fa-solid fa-user-plus" :aria-hidden "true") "&nbsp;Create Invoice&nbsp;"))))))))
	  ;;    (:a :href (format nil "/hhub/editinvoicepage?mode=create&custid=~A" cust-id) :alt "Select Customer" (:i :class "fa-solid fa-user-plus" :aria-hidden "true")))))))

	 


(defun InvoiceHeader-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input" :class "col-3"
		(with-html-search-form "idsyssearchInvoiceHeader" "syssearchInvoiceHeader" "idInvoiceHeaderlivesearch" "InvoiceHeaderlivesearch" "searchinvoicesaction" "onkeyupsearchform1event();" "Search By Invoice Number. Type 3 letters..."
		  (submitsearchform1event-js "#idInvoiceHeaderlivesearch" "#InvoiceHeaderlivesearchresult"))))))

(defun com-hhub-transaction-show-invoices-page ()
  :description "This is a show list page for all the InvoiceHeader entities"
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "InvoiceHeader" #'create-model-for-showInvoiceHeader #'create-widgets-for-showInvoiceHeader :role  :vendor )))

(defun create-model-for-showInvoiceHeader ()
  :description "This is a model function which will create a model to show InvoiceHeader entities"
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (presenterobj (make-instance 'InvoiceHeaderPresenter))
	 (requestmodelobj (make-instance 'InvoiceHeaderRequestModel
					 :vendor vendor 
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceHeaderHTMLView))
	 (params nil))

    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-show-invoices-page" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))

(defun create-widgets-for-showInvoiceHeader (modelfunc)
 :description "This is the view/widget function for show InvoiceHeader entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (InvoiceHeader-search-html)
		       (:hr)))))
	  (widget2 (function (lambda ()
		     (invoices-actions-menu  nil))))
	  (widget3 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :id "InvoiceHeaderlivesearchresult" 
			     (with-html-div-row
			       (with-html-div-col-3
				 (:a :href "/hhub/addcusttoinvoice" :role "button" :class "btn btn-lg btn-primary btn-block" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
			       (with-html-div-col-6 "")
			       (with-html-div-col-3 :align "right"
				 (:span :class "badge bg-info" (:h5 (cl-who:str (format nil "~A" (length viewallmodel)))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget4 (function (lambda ()
		     (render-invoice-settings-menu)))))
      (list widget1 widget2 widget3 widget4))))

(defun create-widgets-for-updateInvoiceHeader (modelfunc)
:description "This is a widgets function for update InvoiceHeader entity"      
  (funcall #'create-widgets-for-genericredirect modelfunc))


(defmethod RenderListViewHTML ((htmlview InvoiceHeaderHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for InvoiceHeader entities, which will display each InvoiceHeader entity in a row"
  (when viewmodellist
    (display-as-table (list "Invoice Number" "Date" "Customer Name" "Status" "Total Value" "Action") viewmodellist 'display-InvoiceHeader-row)))

(defun create-model-for-searchInvoiceHeader ()
  :description "This is a model function for search InvoiceHeader entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "InvoiceHeaderlivesearch"))
	 (vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (presenterobj (make-instance 'InvoiceHeaderPresenter))
	 (requestmodelobj (make-instance 'InvoiceHeaderSearchRequestModel
						 :invnum search-clause
						 :vendor vendor 
						 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceHeaderHTMLView))
	 (params nil))

    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-invoice-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))

(defun create-widgets-for-searchInvoiceHeader (modelfunc)
  :description "This is a widget function for search InvoiceHeader entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (with-html-div-col-3
			   (:a :href "/hhub/addcusttoinvoice" :role "button" :class "btn btn-lg btn-primary btn-block" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
			 (with-html-div-col-6 "")
			 (with-html-div-col-3 :align "right"
			   (:span :class "badge bg-info" (:h5 (cl-who:str (format nil "~A" (length viewallmodel)))))))
		       (:hr)
		       (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
      (list widget1))))

(defun com-hhub-transaction-search-invoice-action ()
  :description "This is a MVC function to search action for InvoiceHeader entities/entity" 
  (let* ((modelfunc (funcall #'create-model-for-searchInvoiceHeader))
	 (widgets (funcall #'create-widgets-for-searchInvoiceHeader modelfunc)))
    (display-search-results-with-widgets widgets)))

(defun create-model-for-updateInvoiceHeader ()
  :description "This is a model function for update InvoiceHeader entity"
  (let* ((invnum (hunchentoot:parameter "invnum"))
	 (invdate (get-date-from-string (hunchentoot:parameter "invdate")))
	 (custid (hunchentoot:parameter "custid"))
	 (custname (hunchentoot:parameter "custname"))
	 (custaddr (hunchentoot:parameter "custaddr"))
	 (custgstin (hunchentoot:parameter "custgstin"))
	 (statecode (hunchentoot:parameter "statecode"))
	 (billaddr (hunchentoot:parameter "billaddr"))
	 (shipaddr (hunchentoot:parameter "shipaddr"))
	 (placeofsupply (hunchentoot:parameter "placeofsupply"))
	 (revcharge (hunchentoot:parameter "revcharge"))
	 (transmode (hunchentoot:parameter "transmode"))
	 (vnum (hunchentoot:parameter "vnum"))
	 (totalvalue (float (with-input-from-string (in (hunchentoot:parameter "totalvalue"))
		     (read in))))
	 (totalinwords (hunchentoot:parameter "totalinwords"))
	 (bankaccnum (hunchentoot:parameter "bankaccnum"))
	 (bankifsccode (hunchentoot:parameter "bankifsccode"))
	 (tnc (hunchentoot:parameter "tnc"))
	 (authsign (hunchentoot:parameter "authsign"))
	 (finyear (hunchentoot:parameter "finyear"))
	 (status (hunchentoot:parameter "status"))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (company (get-login-vendor-company)) ;; or get ABAC subject specific login company function. 
	 (customer (select-customer-by-id custid company))
	 (vendor (get-login-vendor))
	 (external-url (generate-invoice-ext-url invnum vendor company)) 
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
					 :invnum invnum
					 :invdate invdate
					 :customer customer
					 :custid custid
					 :custname custname
					 :custaddr custaddr
					 :custgstin custgstin
					 :statecode statecode
					 :billaddr billaddr
					 :shipaddr shipaddr
					 :placeofsupply placeofsupply
					 :revcharge revcharge
					 :transmode transmode
					 :vnum vnum
					 :totalvalue totalvalue
					 :totalinwords totalinwords
					 :bankaccnum bankaccnum
					 :bankifsccode bankifsccode
					 :tnc tnc
					 :authsign authsign
					 :finyear finyear
					 :external-url external-url
					 :status status
					 :vendor vendor
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (redirectlocation  (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A" invnum))
	 (params nil))
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-invoice-action" params 
      (handler-case 
	  (let* ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (when sessioninvoice
	      (setf (slot-value sessioninvoice 'invoiceheader) domainobj)
	      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
	      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht))	   
	    (function (lambda ()
	      (values redirectlocation domainobj))))

	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getexceptionstr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))


		 

(defun com-hhub-transaction-create-invoice-action()
  :description "This is a MVC function for create InvoiceHeader entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-createInvoiceHeader #'create-widgets-for-createInvoiceHeader)))
      (format nil "~A" url))))

(defun create-widgets-for-createInvoiceHeader (modelfunc)
  :description "This is a create widget function for InvoiceHeader entity"
  (funcall #'create-widgets-for-genericredirect modelfunc))

(defun create-model-for-createInvoiceHeader ()
  :description "This is a create model function for creating a InvoiceHeader entity"
  (let* ((invdate (get-date-from-string (hunchentoot:parameter "invdate")))
	 (company (get-login-vendor-company))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (context-id (hunchentoot:parameter "context-id"))
	 (custid (hunchentoot:parameter "custid"))
	 (customer (select-customer-by-id custid company))
	 (custaddr (hunchentoot:parameter "custaddr"))
	 (custgstin (hunchentoot:parameter "custgstin"))
	 (statecode (hunchentoot:parameter "statecode"))
	 (billaddr (hunchentoot:parameter "billaddr"))
	 (shipaddr (hunchentoot:parameter "shipaddr"))
	 (placeofsupply (hunchentoot:parameter "placeofsupply"))
	 (revcharge (hunchentoot:parameter "revcharge"))
	 (transmode (hunchentoot:parameter "transmode"))
	 (vnum (hunchentoot:parameter "vnum"))
	 (totalvalue (float (with-input-from-string (in (hunchentoot:parameter "totalvalue"))
		     (read in))))
	 (totalinwords (hunchentoot:parameter "totalinwords"))
	 (bankaccnum (hunchentoot:parameter "bankaccnum"))
	 (bankifsccode (hunchentoot:parameter "bankifsccode"))
	 (tnc (hunchentoot:parameter "tnc"))
	 (authsign (hunchentoot:parameter "authsign"))
	 (finyear (hunchentoot:parameter "finyear"))
	 (company (get-login-vendor-company)) ;; or get ABAC subject specific login company function.
	 (vendor (get-login-vendor))
	 (vname (get-login-vendor-name))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
				      :context-id context-id
				      :invnum sessioninvkey
				      :invdate invdate
				      :customer customer
				      :vendor vendor
				      :custaddr custaddr
				      :custgstin custgstin
				      :statecode statecode
				      :billaddr billaddr
				      :shipaddr shipaddr
				      :placeofsupply placeofsupply
				      :revcharge revcharge
				      :transmode transmode
				      :vnum vnum
				      :totalvalue totalvalue
				      :totalinwords totalinwords
				      :bankaccnum bankaccnum
				      :bankifsccode bankifsccode
				      :tnc tnc
				      :authsign (if authsign authsign vname)
				      :finyear finyear
				      :external-url ""
				      :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (hrequestmodel (make-instance 'InvoiceHeaderContextIDRequestModel
				      :context-id context-id
				      :company company))
	 (redirectlocation  (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A"  sessioninvkey))
	 (params nil))
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-invoice-action" params 
      (handler-case 
	  (let* ((createdobj (ProcessCreateRequest adapterobj requestmodel))
		 ;; as soon as we create a invoice header object, we would like to read it as well
		 ;; this will pull in the row-id from database and also the invoice number. 
		 (domainobj (ProcessReadRequest adapterobj hrequestmodel))
		 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
		 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht)))
	    ;;  (logiamhere (format nil "~A" sessioninvoices-ht))
	    ;; (logiamhere (format nil "~A" sessioninvoice))
	    ;;  (logiamhere (format nil "session invoice customer is ~A" (slot-value (slot-value sessioninvoice 'customer) 'name)))
	    ;; set the InvoiceHeader context for the invoice being created and add to the session invoice. 
	    (when (and createdobj sessioninvoice)
	      (setf (slot-value sessioninvoice 'invoiceheader) domainobj)
	      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
	      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht))
	    
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getExceptionStr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))





(defun com-hhub-transaction-create-InvoiceHeader-dialog (&optional domainobj)
  :description "This function creates a dialog to create InvoiceHeader entity"
  (let* ((invnum  (if domainobj (slot-value domainobj 'invnum)))
	 (invdate  (if domainobj (get-date-string (slot-value domainobj 'invdate))))
	 (custaddr  (if domainobj (slot-value domainobj 'custaddr)))
	 (custgstin  (if domainobj (slot-value domainobj 'custgstin)))
	 (statecode  (if domainobj (slot-value domainobj 'statecode)))
	 (billaddr  (if domainobj (slot-value domainobj 'billaddr)))
	 (shipaddr  (if domainobj (slot-value domainobj 'shipaddr)))
	 (placeofsupply  (if domainobj (slot-value domainobj 'placeofsupply)))
	 (revcharge  (if domainobj (slot-value domainobj 'revcharge)))
	 (transmode  (if domainobj (slot-value domainobj 'transmode)))
	 (vnum  (if domainobj (slot-value domainobj 'vnum)))
	 (totalvalue  (if domainobj (slot-value domainobj 'totalvalue)))
	 (totalinwords  (if domainobj (slot-value domainobj 'totalinwords)))
	 (bankaccnum  (if domainobj (slot-value domainobj 'bankaccnum)))
	 (bankifsccode  (if domainobj (slot-value domainobj 'bankifsccode)))
	 (tnc  (if domainobj (slot-value domainobj 'tnc)))
	 (authsign  (if domainobj (slot-value domainobj 'authsign))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addInvoiceHeader~A" invnum)  (if domainobj "updateinvoiceaction" "createinvoiceaction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "invnum" :maxlength "20"  :value  invnum :placeholder "Invoice Number (max 20 characters) " :type "text" :readonly t))
		    
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value invdate :placeholder "invdate"  :name "invdate" ))
		    
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value custaddr :placeholder "custaddr"  :name "custaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value custgstin :placeholder "custgstin"  :name "custgstin" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value statecode :placeholder "statecode"  :name "statecode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value billaddr :placeholder "billaddr"  :name "billaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipaddr :placeholder "shipaddr"  :name "shipaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value placeofsupply :placeholder "placeofsupply"  :name "placeofsupply" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value revcharge :placeholder "revcharge"  :name "revcharge" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value transmode :placeholder "transmode"  :name "transmode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value vnum :placeholder "vnum"  :name "vnum" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value totalvalue :placeholder "totalvalue"  :name "totalvalue" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value totalinwords :placeholder "totalinwords"  :name "totalinwords" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value bankaccnum :placeholder "bankaccnum"  :name "bankaccnum" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value bankifsccode :placeholder "bankifsccode"  :name "bankifsccode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value tnc :placeholder "tnc"  :name "tnc" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value authsign :placeholder "authsign"  :name "authsign" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))


(defun vendor-create-update-customer-dialog (&optional customer)
  :description "This function creates a dialog to create InvoiceHeader entity"
  (let* ((firstname (when customer (slot-value customer 'firstname)))
	 (lastname (when customer (slot-value customer 'lastname)))
	 (phone (when customer (slot-value customer 'phone )))
	 (email (when customer (slot-value customer 'email)))
	 (address (when customer (slot-value customer 'address))))
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-form-having-submit-event "form-vendorcreatecustomer"  "vendorcreatecustomer"
	(with-html-input-text "firstname" "First Name" "First Name" firstname  nil "Enter First Name" 1)
	(with-html-input-text "lastname" "Last Name" "Last Name" lastname  nil "Enter Last Name" 2)
	(with-html-input-text "phone" "Phone" "Phone" phone nil "Enter Phone Number" 3)
	(with-html-input-text "email" "Email" "Email" email nil "Enter Email" 4)
	(with-html-input-textarea "address" address  "Address" "Address" nil "Enter Address" 6 3)
	(:div :class "form-group"
	      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))
		    

(defun com-hhub-transaction-vendor-create-customer-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui #'create-model-for-vendorcreatecustomer #'create-widgets-for-vendorcreatecustomer)))

(defun create-model-for-vendorcreatecustomer ()
  (let* ((vendor (get-login-vendor))
	 (fname (hunchentoot:parameter "firstname"))
	 (lname (hunchentoot:parameter "lastname"))
	 (cphone (hunchentoot:parameter "phone"))
	 (cemail (hunchentoot:parameter "email"))
	 (caddress (hunchentoot:parameter "address"))
	 (cname (format nil "~A ~A" fname lname))
	 (company (get-login-vendor-company))
	 (customer (select-customer-by-phone cphone company))
	 (password (hhub-random-password 8))
	 (salt (createciphersalt))
	 (encryptedpass (check&encrypt password password salt))
	 (redirectlocation "/hhub/addcusttoinvoice"))
    ;; Create customer scenario
    (unless customer
      ;; Step 1 - Create a new customer 
      (create-customer cname caddress cphone cemail nil encryptedpass salt nil nil nil company)
      ;; Step 2 - create wallet for this new customer. 
      (let ((newcustomer (select-customer-by-phone cphone company)))
	(create-wallet newcustomer vendor company)))
    
    (when customer 
      (with-slots (firstname lastname name email phone address) customer
	(setf firstname fname)
	(setf lastname lname)
	(setf name cname)
	(setf email cemail)
	(setf phone cphone)
	(setf address caddress))
      (clsql:update-records-from-instance customer))
    (function (lambda ()
      redirectlocation))))
      
(defun create-widgets-for-vendorcreatecustomer (modelfunc)
  :description "This is a widgets function for create/update customer by vendor"      
  (funcall #'create-widgets-for-genericredirect modelfunc))
  
(defun display-InvoiceHeader-row (viewmodel &rest arguments)
  (declare (ignore arguments ))
  (with-slots (invnum invdate customer status totalvalue) viewmodel
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str  invnum))
      (:td  :height "10px" (cl-who:str (get-date-string invdate)))
      (:td  :height "10px" (cl-who:str (slot-value customer 'name)))
      (:td  :height "10px" (cl-who:str status))
      (:td  :height "10px" (cl-who:str totalvalue))
      (:td  :height "10px" (:a :href (format nil "/hhub/editinvoicepage?invnum=~A" invnum) :alt "Edit Invoice" (:i :class "fa-solid fa-pencil"))))))

	


(defun com-hhub-transaction-update-invoice-action()
  :description "This is the MVC function to update action for InvoiceHeader entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-updateInvoiceHeader #'create-widgets-for-updateInvoiceHeader)))
      (format nil "~A" url))))


(defun com-hhub-transaction-edit-invoice-header-page()
  :description "This is the MVC function to show invoice header page"
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Edit Invoice" #'create-model-for-editinvoiceheaderpage #'create-widgets-for-editinvoiceheaderpage :role :vendor)))

(defun create-model-for-editinvoiceheaderpage ()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (custid (hunchentoot:parameter "custid"))
	 (inum (hunchentoot:parameter "invnum"))
	 (mode (hunchentoot:parameter "mode"))
	 (finyear (current-year-string))
	 (adapter (make-instance 'InvoiceHeaderAdapter))
	 (itmadapter (make-instance 'InvoiceItemAdapter))
	 (customer (if custid (select-customer-by-id custid company)))
	 (custaddress (if customer (slot-value customer 'address)))
	 (busobj (make-instance 'InvoiceHeader
				:context-id (format nil "~A" (uuid:make-v1-uuid))
				:company company
				:vendor vendor
				:customer customer
				:custaddr custaddress 
				:finyear finyear
				:external-url ""
				:status "DRAFT"
				:placeofsupply *NSTGSTBUSINESSSTATE*
				:statecode *NSTGSTBUSINESSSTATE*
				:tnc *NSTGSTINVOICETERMS*
				:authsign (get-login-vendor-name)
				:revcharge "No"))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
				      :invnum inum
				      :company company))
	 (invoiceobj (if inum (ProcessReadRequest adapter requestmodel) busobj))
	 (invitemreqmodel (make-instance 'InvoiceItemRequestModel
					 :invoiceheader invoiceobj
					 :company company))
	 (invitems (if inum (ProcessReadAllRequest itmadapter invitemreqmodel) '()))  
	 
	 ;; When we are creating a new invoice, we would like to save it in the session with context of
	 ;; customer, invoice header and invoice items. Here we start with adding the customer context. 
	 ;; 🚨 HHUB-RANDOM-TOKEN, NOT HHUB-RANDOM-PASSWORD. This key is carried in a redirect
	 ;; QUERY STRING and in a hidden FORM FIELD, then looked up in this session's hash — so
	 ;; it must be URL- and form-safe. RANDOM-PASSWORD's alphabet contains & # % + ? . [ ]
	 ;; (it is symbol-rich ON PURPOSE, for password complexity), which silently mangled
	 ;; the key: GETHASH missed and the next page died with "the slot INVOICEHEADER is
	 ;; missing from the object NIL". See the note on HHUB-RANDOM-TOKEN.
	 (sessioninvkey (if inum inum (format nil "NST000~A" (hhub-random-token 10))))
	 (newsessioninvoice (make-instance 'SessionInvoice))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht)))

    ;;(logiamhere (format nil "status of invoice header is ~A" (slot-value invoiceobj 'status)))
	   ;; set the customer context for the invoice being created and add to the session invoice. 
    (setf (slot-value newsessioninvoice 'customer) (customer invoiceobj))
    (setf (slot-value newsessioninvoice 'InvoiceItems) invitems)
    (setf (slot-value newsessioninvoice 'invoiceproducts) '())
    (setf (slot-value newsessioninvoice 'InvoiceHeader) invoiceobj)
    (setf (slot-value newsessioninvoice 'invoicetaxbreakdown) (generate-gst-tax-breakdown invoiceobj invitems))
    (setf (gethash sessioninvkey sessioninvoices-ht) newsessioninvoice)
    (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
  (with-slots (context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status customer ) invoiceobj
    (function (lambda()
      (values context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status customer  mode sessioninvkey))))))


(defun create-widgets-for-editinvoiceheaderpage (modelfunc)
  (multiple-value-bind (context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status customer  mode sessioninvkey) (funcall modelfunc)
    (let* ((widget1 (editinvoicewidget-section1 sessioninvkey context-id invnum invdate  custgstin finyear status customer))
	   (widget2 (editinvoicewidget-section2 custaddr billaddr shipaddr))
	   (widget3 (editinvoicewidget-section3 statecode placeofsupply revcharge transmode vnum totalvalue totalinwords))
	   (widget4 (editinvoicewidget-section4 bankaccnum bankifsccode tnc authsign))
	   (widget5 (function (lambda ()
		      (invoice-header-actions-menu external-url status sessioninvkey customer))))  
	   (widget5 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(funcall widget5)
			(:span "Create Invoice - Step 2: ")
			(:span (cl-who:str sessioninvkey))
			(:h2 "Fill Invoice Details For")
			(with-html-form-having-submit-event "form-updateinvoiceheader"  (if (equal mode "create") "createinvoiceaction" "updateinvoiceaction")
			  (with-html-div-row
			    (with-html-div-col-3
			      (funcall widget1))
			    (with-html-div-col-3
			      (funcall widget2))
			    (with-html-div-col-3
			      (funcall widget3))
			    (with-html-div-col-3
			      (funcall widget4)))))))))
      (list widget5))))


(defun editinvoicewidget-section1 (sessioninvkey context-id invnum invdate  custgstin finyear status customer)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-token 3)))
	  (idinvoicedate (format nil "idinvoicedate~A" (gensym)))
	  (finyear-ht (make-hash-table :test 'equal))
	  (status-ht (make-hash-table :test 'equal)))
      
      (setf (gethash (current-year-string--) finyear-ht) (current-year-string--))
      (setf (gethash (current-year-string) finyear-ht) (current-year-string))
      (setf (gethash (current-year-string++) finyear-ht) (current-year-string++))
      (setf (gethash "DRAFT" status-ht) "DRAFT")
      (setf (gethash "PENDINGPAYMENT" status-ht) "PENDINGPAYMENT")
      (setf (gethash "PAID" status-ht) "PAID")
      (setf (gethash "SHIPPED" status-ht) "SHIPPED")
      (setf (gethash "CANCELLED" status-ht) "CANCELLED")
      (setf (gethash "REFUNDED" status-ht) "REFUNDED")
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
	      (with-html-input-text-hidden "context-id" context-id)
	      (with-html-input-text-hidden "custid" (cl-who:str (slot-value customer 'row-id)))
	      (with-html-input-text-hidden "custname" (cl-who:str (slot-value customer 'name)))
	      (:h3 (:span (cl-who:str (slot-value customer 'name))))
	      (:h3 (:span (cl-who:str (slot-value customer 'phone)))))
	(:div :class "form-group"
	    (:label :for "finyear" "Financial Year")
	    (with-html-dropdown "finyear" finyear-ht finyear))
	(:div :class "form-group"
	      (:label :for "status" "Status")
	      (with-html-dropdown "status" status-ht status))
	(:div :class "form-group"
	      (:label :for "invnum" "Invoice Number")
	      (:input :class "form-control" :name "invnum" :maxlength "20"  :value  invnum :placeholder "Invoice Number (max 20 characters) " :type "text" :readonly t))
	(:div :class "form-group"
	      (:label :for idinvoicedate "Invoice Date - Click To Change" )
	      (:input :class "form-control" :name "invdate" :id idinvoicedate :placeholder  "Invoice Date"  :type "text" :value (get-date-string invdate)))
	
	(:div :class "form-group"
	      (:label :for "idcustgstin" "Customer GST Number")
	      (:input :id "idcustgstin" :class "form-control" :type "text" :value custgstin :onkeyup (format nil "countChar(~A.id, this, 15)" charcountid1) :placeholder "Customer GST Number"  :name "custgstin" )
	      (:div :class "form-group" :id charcountid1))
	(:script (cl-who:str (format nil "$(document).ready(
        function() {    
        $('#~A').datepicker({dateFormat: 'dd/mm/yy', minDate: 0} ).attr('readonly', 'true'); 
        }
);" idinvoicedate))))))))

(defun editinvoicewidget-section2 (custaddr billaddr shipaddr)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-token 3)))
	  (charcountid2 (format nil "idchcount~A" (hhub-random-token 3)))
	  (charcountid3 (format nil "idchcount~A" (hhub-random-token 3))))
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (:label :for "custaddr" "Customer Address")
	      (:textarea :class "form-control" :name "custaddr"  :placeholder "Enter Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid1) (cl-who:str (format nil "~A" custaddr)))
	      (:div :class "form-group" :id charcountid1))
	(:div :class "form-group"
	      (:label :for "billaddr" "Billing Address")
	      (:textarea :class "form-control" :name "billaddr"  :placeholder "Enter Billing Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid2) (cl-who:str (format nil "~A" billaddr)))
	      (:div :class "form-group" :id charcountid2 ))
	(:div :class "form-group"
	      (:label :for "shipaddr" "Shipping Address")
	      (:textarea :class "form-control" :name "shipaddr"  :placeholder "Enter Shipping Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid3) (cl-who:str (format nil "~A" shipaddr)))
	      (:div :class "form-group" :id charcountid3)))))))
  

(defun editinvoicewidget-section3 (statecode placeofsupply revcharge transmode vnum totalvalue totalinwords)
  (function (lambda ()
    (let ((revcharge-ht (make-hash-table :test 'equal))
	  (transmode-ht (make-hash-table :test 'equal))
	  (placeofsupply-ht (make-hash-table :test 'equal)))
      
      (setf (gethash "Yes" revcharge-ht) "Yes") 
      (setf (gethash "No" revcharge-ht) "No")
      (setf (gethash "NA" transmode-ht) "Not Applicable")
      (setf (gethash "Road" transmode-ht) "Road")
      (setf (gethash "Rail" transmode-ht) "Rail")
      (setf (gethash "Air" transmode-ht) "Air")
      (setf (gethash "Ship/Waterways" transmode-ht) "Ship/Waterways")
      (setf (gethash "INTRASTATE" placeofsupply-ht) "Intra-State (CGST + SGST)")
      (setf (gethash "INTERSTATE"  placeofsupply-ht) "Inter-State (IGST)")

      (unless statecode (setf statecode *NSTGSTBUSINESSSTATE*))
      
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (:label :for "statecode" "Select State")
	      (with-html-dropdown "statecode" *NSTGSTSTATECODES-HT* statecode))
	(:div :class "form-group"
	      (:label :for "placeofsupply" "Place Of Supply")
	      (with-html-dropdown "placeofsupply" *NSTGSTSTATECODES-HT* placeofsupply))
	;;(with-html-dropdown "placeofsupply" placeofsupply-ht placeofsupply))
	(:div :class "form-group"
	      (:label :for "revcharge" "Reverse Charge")
	      (with-html-dropdown "revcharge" revcharge-ht revcharge))
	(:div :class "form-group"
	      (:label :for "transmode" "Transport Mode")
	      (with-html-dropdown "transmode" transmode-ht transmode))
	(:div :class "form-group"
	      (:label :for "vnum" "Vehicle Number")
	      (:input :class "form-control" :type "text" :value vnum :placeholder "Vehicle Number"  :name "vnum" ))
	(:div :class "form-group" :style "display:none;"
	      (:label :for "totalvalue" "Total Value")
	      (:input :class "form-control" :type "text" :value totalvalue :placeholder "Total Value"  :name "totalvalue" ))
	(:div :class "form-group" :style "display:none;"
	      (:label :for "totalinwords" "Total In Words")
	      (:input :class "form-control" :type "text" :value totalinwords :placeholder "Total In Words"  :name "totalinwords" )))))))

(defun editinvoicewidget-section4 (bankaccnum bankifsccode tnc authsign)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-token 3))))
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "NEXT"))
	(:div :class "form-group"
	      (:label :for "bankaccnum" "Bank Account Number")
	      (:input :class "form-control" :type "text" :value bankaccnum :placeholder "bankaccnum"  :name "bankaccnum" ))
	(:div :class "form-group"
	      (:label :for "bankifsccode" "Bank IFSC Code")
	      (:input :class "form-control" :type "text" :value bankifsccode :placeholder "bankifsccode"  :name "bankifsccode" ))
	(:div :class "form-group"
	      (:label :for "tnc" "Invoice Terms")
	      (:textarea :class "form-control" :name "tnc"  :placeholder "Enter Invoice Terms (Max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 1000)" charcountid1) (cl-who:str (format nil "~A" tnc)))
	      (:div :class "form-group" :id charcountid1 ))
        (:div :class "form-group"
	    (:label :for "invnum" "Authorised Signatory")
	    (:input :class "form-control" :type "text" :value authsign :placeholder "authsign"  :name "authsign" )))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
