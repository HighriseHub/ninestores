;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(clsql:def-view-class dod-currncy ()
  ((country 
    :accessor country
    :type (string 100)
    :initarg :country)

   (currency
    :accessor currency
    :type (string 20)
    :initarg :currency)

   (code
    :accessor code
    :type (string 10)
    :initarg :code)

   (curr-symbol
    :accessor curr-symbol
    :type (string 5)
    :initarg :curr-symbol))
      
  (:BASE-TABLE dod_currency))


(defun get-currency-fontawesome-map ()
  (let ((curr-fa-symbols (list (list "INR" "fa-solid fa-indian-rupee-sign")
			       (list "USD" "fa-solid fa-dollar-sign")))
	(ht (make-hash-table :test 'equal)))
    (loop for curr in curr-fa-symbols do
      (setf (gethash (car curr) ht) (second curr)))
    ht))

         
    

(defun get-currency-html-symbol-map ()
  (let ((curr-html-symbols (list (list "AED" "&#1583;.&#1573;")
				 (list "AFN"  "&#65;&#102;")
				 (list "ALL"  "&#76;&#101;&#107;")
				 (list "AMD"  "&#1380;")
				 (list "ANG"  "&#402;")
				 (list "AOA"  "&#75;&#122;")
				 (list "ARS"  "&#36;")
				 (list "AUD"  "&#36;")
				 (list "AWG"  "&#402;")
				 (list "AZN"  "&#8380;")
				 (list "BAM"  "&#75;&#77;")
				 (list "BBD"  "&#36;")
				 (list "BDT"  "&#2547;")
				 (list "BGN"  "&#1083;&#1074;")
				 (list "BHD"  ".&#1583;.&#1576;")
				 (list "BIF"  "&#70;&#66;&#117;")
				 (list "BMD"  "&#36;")
				 (list 	"BND"  "&#36;")
				 (list 	"BOB"  "&#36;&#98;")
				 (list 	"BRL"  "&#82;&#36;")
				 (list 	"BSD"  "&#36;")
				 (list 	"BTN"  "&#78;&#117;&#46;")
				 (list 	"BWP"  "&#80;")
				 (list 	"BYR"  "&#112;&#46;")
				 (list 	"BZD"  "&#66;&#90;&#36;")
				 (list 	"CAD"  "&#36;")
				 (list 	"CDF"  "&#70;&#67;")
				 (list 	"CF"  "&#67;&#72;&#70;")
				 (list 	"CLF"  "&#85;&#70;")
				 (list 	"CLP"  "&#36;")
				 (list 	"CNY"  "&#165;")
				 (list 	"COP"  "&#36;")
				 (list 	"CRC"  "&#8353;")
				 (list 	"CUP"  "&#8396;")
				 (list 	"CVE"  "&#36;")
				 (list 	"CZK"  "&#75;&#269;")
				 (list 	"DJF"  "&#70;&#100;&#106;")
				 (list 	"DKK"  "&#107;&#114;")
				 (list 	"DOP"  "&#82;&#68;&#36;")
				 (list 	"DZD"  "&#1583;&#1580;")
				 (list 	"EGP"  "E&#163;")
				 (list 	"ETB"  "&#66;&#114;")
				 (list 	"EUR"  "&#8364;")
				 (list 	"FJD"  "&#36;")
				 (list 	"FKP"  "&#163;")
				 (list 	"GBP"  "&#163;")
				 (list 	"GEL"  "&#4314;")
				 (list 	"GHS"  "&#162;")
				 (list 	"GIP"  "&#163;" )
				 (list 	"GMD"  "&#68;") 
				 (list 	"GNF"  "&#70;&#71;") 
				 (list 	"GTQ"  "&#81;" )
				 (list 	"GYD"  "&#36;")
				 (list 	"HKD"  "&#36;")
				 (list 	"HNL"  "&#76;")
				 (list 	"HRK"  "&#107;&#110;")
				 (list 	"HTG"  "&#71;") 
				 (list 	"HUF"  "&#70;&#116;")
				 (list 	"IDR"  "&#82;&#112;")
				 (list 	"ILS"  "&#8362;")
				 (list 	"INR"  "&#8377;")
				 (list 	"IQD"  "&#1593;.&#1583;") 
				 (list 	"IRR"  "&#65020;")
				 (list 	"ISK"  "&#107;&#114;")
				 (list 	"JEP"  "&#163;")
				 (list 	"JMD"  "&#74;&#36;")
				 (list 	"JOD"  "&#74;&#68;") 
				 (list 	"JPY"  "&#165;")
				 (list 	"KES"  "&#75;&#83;&#104;") 
				 (list 	"KGS"  "&#1083;&#1074;")
				 (list 	"KHR"  "&#6107;")
				 (list 	"KMF"  "&#67;&#70;") 
				 (list 	"KPW"  "&#8361;")
				 (list 	"KRW"  "&#8361;")
				 (list 	"KWD"  "&#1583;.&#1603;") 
				 (list 	"KYD"  "&#36;")
				 (list 	"KZT"  "&#8376;")
				 (list 	"LAK"  "&#8365;")
				 (list 	"LBP"  "&#163;")
				 (list 	"LKR"  "&#8360;")
				 (list 	"LRD"  "&#36;")
				 (list 	"LSL"  "&#76;") 
				 (list 	"LTL"  "&#76;&#116;")
				 (list 	"LVL"  "&#76;&#115;")
				 (list 	"LYD"  "&#1604;.&#1583;") 
				 (list 	"MAD"  "&#1583;.&#1605;.")
				 (list 	"MDL"  "&#76;")
				 (list 	"MGA"  "&#65;&#114;") 
				 (list 	"MKD"  "&#1076;&#1077;&#1085;")
				 (list 	"MMK"  "&#75;")
				 (list 	"MNT"  "&#8366;")
				 (list 	"MOP"  "&#77;&#79;&#80;&#36;") 
				 (list 	"MRO"  "&#85;&#77;") 
				 (list 	"MUR"  "&#8360;") 
				 (list 	"MVR"  ".&#1923;") 
				 (list 	"MWK"  "&#77;&#75;")
				 (list 	"MXN"  "&#36;")
				 (list 	"MYR"  "&#82;&#77;")
				 (list 	"MZN"  "&#77;&#84;")
				 (list 	"NAD"  "&#36;")
				 (list 	"NGN"  "&#8358;")
				 (list 	"NIO"  "&#67;&#36;")
				 (list 	"NOK"  "&#107;&#114;")
				 (list 	"NPR"  "&#8360;")
				 (list 	"NZD"  "&#36;")
				 (list 	"OMR"  "&#65020;")
				 (list 	"PAB"  "&#66;&#47;&#46;")
				 (list 	"PEN"  "&#83;&#47;&#46;")
				 (list 	"PGK"  "&#75;") 
				 (list 	"PHP"  "&#8369;")
				 (list 	"PKR"  "&#8360;")
				 (list 	"PLN"  "&#122;&#322;")
				 (list 	"PYG"  "&#71;&#115;")
				 (list 	"QAR"  "&#65020;")
				 (list 	"RON"  "&#108;&#101;&#105;")
				 (list 	"RSD"  "&#1044;&#1080;&#1085;&#46;")
				 (list 	"RUB"  "&#8381;")
				 (list 	"RWF"  "&#1585;.&#1587;")
				 (list 	"SAR"  "&#65020;")
				 (list 	"SBD"  "&#36;")
				 (list 	"SCR"  "&#8360;")
				 (list 	"SDG"  "&#163;") 
				 (list 	"SEK"  "&#107;&#114;")
				 (list 	"SGD"  "&#36;")
				 (list 	"SHP"  "&#163;")
				 (list 	"SLL"  "&#76;&#101;") 
				 (list 	"SOS"  "&#83;")
				 (list 	"SRD"  "&#36;")
				 (list 	"STD"  "&#68;&#98;") 
				 (list 	"SVC"  "&#36;")
				 (list 	"SYP"  "&#163;")
				 (list 	"SZL"  "&#76;") 
				 (list 	"THB"  "&#3647;")
				 (list 	"TJS"  "&#84;&#74;&#83;")
				 (list 	"TMT"  "&#109;")
				 (list 	"TND"  "&#1583;.&#1578;")
				 (list 	"TOP"  "&#84;&#36;")
				 (list 	"TRY"  "&#x20BA;") 
				 (list 	"TTD"  "&#36;")
				 (list 	"TWD"  "&#78;&#84;&#36;")
				 (list 	"TZS"  "&#84;&#83;&#104;")
				 (list 	"UAH"  "&#8372;")
				 (list 	"UGX"  "&#85;&#83;&#104;")
				 (list 	"USD"  "&#36;")
				 (list 	"UYU"  "&#36;&#85;")
				 (list 	"UZS"  "&#1083;&#1074;")
				 (list 	"VEF"  "&#66;&#115;")
				 (list 	"VND"  "&#8363;")
				 (list 	"VUV"  "&#86;&#84;")
				 (list 	"WST"  "&#87;&#83;&#36;")
				 (list 	"XAF"  "&#70;&#67;&#70;&#65;")
				 (list 	"XCD"  "&#36;")
				 (list 	"XDR"  "&#83;&#68;&#82;")
				 (list 	"XOF"  "&#70;&#67;&#70;&#65;")
				 (list 	"XPF"  "&#70;")
				 (list 	"YER"  "&#65020;")
				 (list 	"ZAR"  "&#82;")
				 (list 	"ZMK"  "&#90;&#75;") 
				 (list 	"ZWL"  "&#90;&#36;")))
			   (ht (make-hash-table :test 'equal)))
    (loop for curr in curr-html-symbols do
      (setf (gethash (car curr) ht) (second curr)))
    ht))


(defun get-system-UOM-map ()
  "Returns hash table mapping UOM codes to (description gst-uqc).
   Supports both international UOMs and GST-compliant UQC codes.
   
   Usage:
   (gethash \"PCS\" ht) → (\"Piece\" \"NOS\")
   (gethash \"LTR\" ht) → (\"Litres\" \"LTR\")
   
   First element: User-friendly description
   Second element: GST UQC code for GSTR-1 compliance"
  
  (let ((uom-map 
         (list
          ;; ========================================
          ;; GST-COMPLIANT UQC CODES (Primary)
          ;; ========================================
          
          ;; Most Common Units
          (list "NOS" "Numbers/Pieces" "NOS")
          (list "KGS" "Kilograms" "KGS")
          (list "LTR" "Litres" "LTR")
          (list "MTR" "Metres" "MTR")
          (list "BOX" "Box" "BOX")
          (list "PAC" "Packs" "PAC")
          (list "BTL" "Bottles" "BTL")
          (list "BAG" "Bags" "BAG")
          (list "SET" "Sets" "SET")
          
          ;; Weight Units (GST)
          (list "GMS" "Grams" "GMS")
          (list "MTS" "Metric Tons" "MTS")
          (list "QTL" "Quintals (100 kg)" "QTL")
          (list "TON" "Tonnes" "TON")
          
          ;; Volume Units (GST)
          (list "MLT" "Millilitres" "MLT")
          (list "KLR" "Kilolitres" "KLR")
          (list "CBM" "Cubic Metres" "CBM")
          (list "CCM" "Cubic Centimetres" "CCM")
          
          ;; Length Units (GST)
          (list "CMS" "Centimetres" "CMS")
          (list "KME" "Kilometres" "KME")
          (list "YDS" "Yards" "YDS")
          (list "GYD" "Gross Yards" "GYD")
          
          ;; Area Units (GST)
          (list "SQM" "Square Metres" "SQM")
          (list "SQF" "Square Feet" "SQF")
          (list "SQY" "Square Yards" "SQY")
          
          ;; Packaging Units (GST)
          (list "CTN" "Cartons" "CTN")
          (list "CAN" "Cans" "CAN")
          (list "TUB" "Tubes" "TUB")
          (list "ROL" "Rolls" "ROL")
          (list "BDL" "Bundles" "BDL")
          (list "BAL" "Bales" "BAL")
          (list "DRM" "Drums" "DRM")
          
          ;; Quantity Units (GST)
          (list "DOZ" "Dozens (12)" "DOZ")
          (list "GRS" "Gross (144)" "GRS")
          (list "GGR" "Great Gross (1728)" "GGR")
          (list "TGM" "Ten Gross (1440)" "TGM")
          (list "THD" "Thousands" "THD")
          (list "PRS" "Pairs" "PRS")
          (list "BUN" "Bunches" "BUN")
          
          ;; Specialized Units (GST)
          (list "TBS" "Tablets" "TBS")
          (list "UGS" "US Gallons" "UGS")
          (list "UNT" "Units" "UNT")
          (list "BOU" "Billion Units" "BOU")
          (list "BKL" "Buckles" "BKL")
          
          ;; Other (GST)
          (list "OTH" "Others" "OTH")
          
          ;; ========================================
          ;; INTERNATIONAL/LEGACY CODES (Mapped to GST)
          ;; ========================================
          
          ;; Common Aliases → NOS
          (list "PCS" "Pieces" "NOS")
          (list "EA" "Each" "NOS")
          (list "Nos" "Numbers" "NOS")
          (list "PIECE" "Piece" "NOS")
          (list "PIECES" "Pieces" "NOS")
          (list "UNIT" "Unit" "NOS")
          (list "UNITS" "Units" "NOS")
          
          ;; Weight Aliases → KGS/GMS
          (list "Kg" "Kilogram" "KGS")
          (list "KG" "Kilogram" "KGS")
          (list "KILOGRAM" "Kilogram" "KGS")
          (list "KILOGRAMS" "Kilograms" "KGS")
          (list "GM" "Gram" "GMS")
          (list "GRAM" "Gram" "GMS")
          (list "GRAMS" "Grams" "GMS")
          (list "MG" "Milligram" "GMS")
          (list "MICROG" "Microgram" "GMS")
          (list "DECAG" "Decagram" "GMS")
          (list "HECTOG" "Hectogram" "GMS")
          
          ;; Volume Aliases → LTR/MLT
          (list "LITER" "Liter" "LTR")
          (list "LITRE" "Litre" "LTR")
          (list "LITRES" "Litres" "LTR")
          (list "LITERS" "Liters" "LTR")
          (list "MIL" "Milliliter" "MLT")
          (list "ML" "Milliliter" "MLT")
          (list "MILLILITER" "Milliliter" "MLT")
          (list "DCL" "Deciliter" "MLT")
          (list "DL" "Deciliter" "MLT")
          (list "HL" "Hectoliter" "KLR")
          
          ;; Length Aliases → MTR/CMS/KME
          (list "METER" "Meter" "MTR")
          (list "METRE" "Metre" "MTR")
          (list "METERS" "Meters" "MTR")
          (list "METRES" "Metres" "MTR")
          (list "CM" "Centimeter" "CMS")
          (list "CENTIMETER" "Centimeter" "CMS")
          (list "MM" "Millimeter" "CMS")
          (list "MILLIMETER" "Millimeter" "CMS")
          (list "CUBICMM" "Cubic Millimeter" "CCM")
          (list "KM" "Kilometer" "KME")
          (list "KILOMETER" "Kilometer" "KME")
          (list "YD" "Yard" "YDS")
          (list "YARD" "Yard" "YDS")
          
          ;; Area Aliases
          (list "SQCM" "Square Centimeter" "SQM")
          (list "HA" "Hectare" "SQM")
          
          ;; Weight (Heavy) Aliases
          (list "MT" "Metric Ton" "MTS")
          (list "TONNE" "Tonne" "MTS")
          (list "QUINTAL" "Quintal" "QTL")
          
          ;; Packaging Aliases
          (list "BOXES" "Boxes" "BOX")
          (list "PACK" "Pack" "PAC")
          (list "ROLL" "Roll" "ROL")
          (list "ROLLS" "Rolls" "ROL")
          (list "CARTON" "Carton" "CTN")
          (list "TUBE" "Tube" "TUB")
          (list "DRUM" "Drum" "DRM")
          (list "BALE" "Bale" "BAL")
          (list "BOTTLE" "Bottle" "BTL")
          (list "REEL" "Reel" "ROL")
          (list "SACK" "Sack" "BAG")
          (list "CONTAINER" "Container" "BOX")
          
          ;; Quantity Aliases
          (list "DOZEN" "Dozen" "DOZ")
          (list "PAIR" "Pair" "PRS")
          (list "THOU" "Thousand" "THD")
          (list "THOUSAND" "Thousand" "THD")
          (list "HUN" "Hundred" "OTH")
          
          ;; Volume (Other) Aliases
          (list "CC" "Cubic Centimeter" "CCM")
          (list "CUM" "Cubic Meter" "CBM")
          (list "CUFT" "Cubic Foot" "CBM")
          (list "GAL" "Gallon" "UGS")
          (list "GALLON" "Gallon" "UGS")
          (list "MGAL" "Milligallon" "MLT")
          
          ;; Pharma/Medical
          (list "STRIP" "Strip" "NOS")
          (list "BLISTER" "Blister Pack" "NOS")
          (list "VIAL" "Vial" "NOS")
          (list "AMP" "Ampoule" "NOS")
          
          ;; Industrial
          (list "BARREL" "Barrel" "DRM")
          (list "CASK" "Cask" "DRM")
          (list "TANK" "Tank" "UNT")
          (list "BLOCK" "Block" "NOS")
          (list "PLT" "Plate" "NOS")
          (list "SHEET" "Sheet" "NOS")
          (list "CYL" "Cylinder" "NOS")
          
          ;; ========================================
          ;; IMPERIAL/NON-GST UNITS (Fallback to OTH)
          ;; ========================================
          
          ;; Imperial Weight
          (list "LB" "Pound" "OTH")
          (list "LBS" "Pounds" "OTH")
          (list "LBSF" "Pound-Force" "OTH")
          (list "OZ" "Ounce" "OTH")
          (list "ST" "Stone" "OTH")
          (list "CWT" "Hundredweight" "OTH")
          (list "GR" "Grain" "OTH")
          (list "DR" "Dram" "OTH")
          (list "CT" "Carat" "OTH")
          (list "MLB" "Mega Pound" "OTH")
          
          ;; Imperial Length
          (list "IN" "Inch" "OTH")
          (list "FT" "Foot" "OTH")
          (list "SQIN" "Square Inch" "OTH")
          (list "ACRE" "Acre" "OTH")
          
          ;; Imperial Volume
          (list "QT" "Quart" "OTH")
          (list "PT" "Pint" "OTH")
          (list "CUP" "Cup" "OTH")
          (list "TBSP" "Tablespoon" "OTH")
          (list "TSP" "Teaspoon" "OTH")
          
          ;; Energy/Power (Not for product UOM)
          (list "KWH" "Kilowatt-Hour" "OTH")
          (list "MW" "Megawatt" "OTH")
          (list "JOULE" "Joule" "OTH")
          (list "CAL" "Calorie" "OTH")
          (list "KCAL" "Kilocalorie" "OTH")
          (list "BTU" "British Thermal Unit" "OTH")
          (list "THERM" "Therm" "OTH")
          (list "N" "Newton" "OTH")
          
          ;; Time (Not for product UOM)
          (list "NANOSEC" "Nanosecond" "OTH")
          (list "MICROSEC" "Microsecond" "OTH")
          (list "MILLISEC" "Millisecond" "OTH")
          (list "SEC" "Second" "OTH")
          (list "MIN" "Minute" "OTH")
          (list "HR" "Hour" "OTH")
          (list "DAY" "Day" "OTH")
          (list "WK" "Week" "OTH")
          (list "MO" "Month" "OTH")
          (list "YR" "Year" "OTH")
          (list "DECADE" "Decade" "OTH")
          (list "CENTURY" "Century" "OTH")
          
          ;; Other Non-Standard
          (list "JAR" "Jar" "OTH")
          (list "CASE" "Case" "OTH")
          (list "PALLET" "Pallet" "OTH")
          (list "TRAY" "Tray" "OTH")
          (list "SHRINK" "Shrink Wrap" "OTH")
          ))
        (ht (make-hash-table :test 'equalp))) ; Case-insensitive
    
    ;; Populate hash table: code → (description gst-uqc)
    (loop for (code desc gst-uqc) in uom-map
          do (setf (gethash code ht) (list desc gst-uqc)))
    ht))

;; Helper functions
(defun get-uom-description (uom-code)
  "Get user-friendly description for a UOM code."
  (let* ((ht (get-system-UOM-map))
         (entry (gethash uom-code ht)))
    (when entry (first entry))))

(defun get-gst-uqc (uom-code)
  "Get GST-compliant UQC code for any UOM code."
  (let* ((ht (get-system-UOM-map))
         (entry (gethash uom-code ht)))
    (if entry 
        (second entry)
        "OTH"))) ; Default to Others if not found

(defun get-all-gst-uqc-codes ()
  "Get list of pure GST UQC codes only (not aliases)."
  '("NOS" "KGS" "LTR" "MTR" "BOX" "PAC" "BTL" "BAG" "SET"
    "GMS" "MTS" "QTL" "TON" "MLT" "KLR" "CBM" "CCM"
    "CMS" "KME" "YDS" "GYD" "SQM" "SQF" "SQY"
    "CTN" "CAN" "TUB" "ROL" "BDL" "BAL" "DRM"
    "DOZ" "GRS" "GGR" "TGM" "THD" "PRS" "BUN"
    "TBS" "UGS" "UNT" "BOU" "BKL" "OTH"))

(defun is-gst-compliant-uqc-p (code)
  "Check if code is a pure GST UQC (not an alias)."
  (member (string-upcase code) (get-all-gst-uqc-codes) :test #'string=))

;; Usage examples
(defun example-usage ()
  ;; Get description
  (get-uom-description "PCS")     ; → "Pieces"
  (get-uom-description "LTR")     ; → "Litres"
  
  ;; Get GST UQC mapping
  (get-gst-uqc "PCS")            ; → "NOS"
  (get-gst-uqc "LTR")            ; → "LTR"
  (get-gst-uqc "Kg")             ; → "KGS"
  (get-gst-uqc "BOTTLE")         ; → "BTL"
  (get-gst-uqc "UNKNOWN")        ; → "OTH"
  
  ;; Check if pure GST code
  (is-gst-compliant-uqc-p "NOS") ; → T
  (is-gst-compliant-uqc-p "PCS") ; → NIL (it's an alias)
  (is-gst-compliant-uqc-p "LTR") ; → T
  )

;; Database migration helper
(defun migrate-uom-to-uqc-for-product (product)
  "Migrate product's unit_of_measure to GST-compliant UQC.
   Keeps original UOM for display, adds UQC for GST compliance."
  (let ((current-uom (slot-value product 'unit-of-measure))
        (gst-uqc (get-gst-uqc (slot-value product 'unit-of-measure))))
    
    ;; If already a pure GST code, keep it
    (if (is-gst-compliant-uqc-p current-uom)
        (setf (slot-value product 'uqc) current-uom)
        ;; Otherwise map to GST equivalent
        (setf (slot-value product 'uqc) gst-uqc))
    
    (format t "Product: ~A | UOM: ~A → UQC: ~A~%"
            (slot-value product 'prd-name)
            current-uom
            (slot-value product 'uqc))))

;; SQL migration query
(defun generate-uqc-migration-sql ()
  "Generate SQL to populate UQC field from unit_of_measure."
  "UPDATE DOD_PRD_MASTER 
   SET UQC = CASE
     -- Pure GST codes (keep as-is)
     WHEN UPPER(unit_of_measure) IN ('NOS', 'KGS', 'LTR', 'MTR', 'BOX', 'PAC', 'BTL', 'BAG', 'SET') 
       THEN UPPER(unit_of_measure)
     
     -- Common aliases
     WHEN UPPER(unit_of_measure) IN ('PCS', 'EA', 'PIECE', 'PIECES', 'UNIT', 'UNITS', 'Nos') 
       THEN 'NOS'
     WHEN UPPER(unit_of_measure) IN ('KG', 'Kg', 'KILOGRAM', 'KILOGRAMS') 
       THEN 'KGS'
     WHEN UPPER(unit_of_measure) IN ('GM', 'GRAM', 'GRAMS') 
       THEN 'GMS'
     WHEN UPPER(unit_of_measure) IN ('LITER', 'LITRE', 'LITRES', 'LITERS') 
       THEN 'LTR'
     WHEN UPPER(unit_of_measure) IN ('MIL', 'ML', 'MILLILITER') 
       THEN 'MLT'
     WHEN UPPER(unit_of_measure) IN ('METER', 'METRE', 'METERS', 'METRES') 
       THEN 'MTR'
     WHEN UPPER(unit_of_measure) IN ('CM', 'CENTIMETER') 
       THEN 'CMS'
     WHEN UPPER(unit_of_measure) IN ('BOTTLE', 'BOTTLES') 
       THEN 'BTL'
     WHEN UPPER(unit_of_measure) IN ('PACK', 'PACKS') 
       THEN 'PAC'
     WHEN UPPER(unit_of_measure) IN ('CARTON', 'CARTONS') 
       THEN 'CTN'
     WHEN UPPER(unit_of_measure) IN ('TUBE', 'TUBES') 
       THEN 'TUB'
     WHEN UPPER(unit_of_measure) IN ('DOZEN', 'DOZENS') 
       THEN 'DOZ'
     WHEN UPPER(unit_of_measure) IN ('MT', 'TONNE', 'TONNES') 
       THEN 'MTS'
     WHEN UPPER(unit_of_measure) IN ('ROLL', 'ROLLS') 
       THEN 'ROL'
     
     -- Fallback
     ELSE 'OTH'
   END
   WHERE UQC IS NULL;")

