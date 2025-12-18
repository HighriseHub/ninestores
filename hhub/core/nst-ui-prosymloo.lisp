;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-ui-prosymloo.lisp came from Project Symbol Lookup
(in-package :nstores)

(defun get-project-symbols (system-name)
  "Collects ALL defined symbols (internal and external functions, macros, and classes) 
   from the project's packages."
  (let ((symbols '())
        ;; Now we rely on the hardcoded package name from packages.lisp
        (project-packages (list (find-package :com.nstores.app)))) 
    (unless (first project-packages)
      (error "Project package :COM.NSTORES.APP not found. Ensure the system is loaded."))
    (dolist (pkg project-packages)
      (do-symbols (s pkg)
        ;; Check 1: Is the symbol defined as a function, macro, or class?
        (when (or (fboundp s) (find-class s nil))
          ;; Check 2: Does the symbol belong to this package? 
          ;; This is the critical filter to exclude symbols from dependencies (like :CL or :ASDF)
          (when (eq (symbol-package s) pkg) 
            (push s symbols)))))
    (remove-duplicates symbols)))

(defun get-project-packages (system-name)
  "Returns a list containing the single main package for the :NSTORES system, 
   based on the packages.lisp file."
  (declare (ignore system-name)) ; Ignore the system-name argument as the package is hardcoded
  (let ((pkg (find-package :com.nstores.app)))
    (if pkg
        (list pkg)
        (error "The main project package :COM.NSTORES.APP is not defined or loaded!"))))

;; --- Helper 1: Loading Old Keywords ---

(defun load-old-data-and-keywords (output-file)
  "Loads existing lookup data (if file exists) and returns a hash table
   mapping symbol names to their preserved keywords (the 5th element)."
  (let ((old-data-ht (make-hash-table :test 'equal)))
    (when (probe-file output-file)
      (let ((*function-lookup-table* nil)) ; Define a local variable for load to bind to
        (handler-case
            (progn
              ;; The file contains (defun function-lookup-table () (function (lambda () '(...))))
              (load output-file :verbose nil)
              ;; After loading, call the function defined in the file to get the list
              (let ((old-data (funcall (function-lookup-table)))) 
                (dolist (entry old-data)
                  ;; Entry is (NAME TYPE FILE DOC KEYWORDS)
                  (setf (gethash (first entry) old-data-ht) 
                        (fifth entry))))) ; <--- KEYWORDS are the fifth element
          (error (e)
            (warn "Error loading existing lookup data from ~A: ~A. Keywords not preserved." 
                  output-file e)))))
    old-data-ht))

;; --- Helper 2: Writing the Final File (Uses your exact format) ---

(defun write-final-lookup-file (output-file new-data)
  "Writes the collected and merged symbol data to the file in the specified function format."
  (with-open-file (s output-file 
                     :direction :output 
                     :if-exists :supersede
                     :if-does-not-exist :create)
    ;; Start the DEFUN and the lambda closure structure
    (format s "(defun function-lookup-table () (function (lambda () ~%  '(")
    ;; Write all entries
    (dolist (entry (nreverse new-data))
      (format s "~%    ~S" entry))
    ;; Close the lambda, the function, and the data list
    (format s "))))~%"))
  (format t "~&Lookup file ~A successfully generated and keywords preserved, including internal symbols.~%" output-file))

;; --- Main Function: Orchestrator ---

(defun generate-lookup-file (system-name output-file)
  "Generates the symbol lookup data file by collecting all symbols, merging old keywords, 
   and writing the data in a compiled function format."
  (let* ((symbols (get-project-symbols system-name))
         (old-data-ht (load-old-data-and-keywords output-file))
         (new-data '()))
    ;; --- Step 1: Generate New Data and Merge Keywords ---
    (dolist (s symbols)
      (let* ((name (symbol-name s))
             (type (get-symbol-type s))
             (file (get-symbol-file s)) ; Uses your SWANK-based implementation
             (doc (get-symbol-doc s type))
             ;; Retrieve the existing keywords or default to empty string
             (keywords (gethash name old-data-ht ""))) 
        ;; Pushing data in the order: NAME, TYPE, FILE, DOC, KEYWORDS
        (push (list name type file doc keywords) new-data)))
    ;; --- Step 2: Write the New File ---
    (write-final-lookup-file output-file new-data)))

(defun get-symbol-type (s)
  "Determines the type of the given symbol S."
  (cond
    ;; 1. Functions and Macros
    ((fboundp s)
     (cond
       ((macro-function s) "MACRO")
       ((typep (fdefinition s) 'generic-function) "GENERIC-FUNCTION")
       (t "FUNCTION")))
    
    ;; 2. Classes
    ((find-class s nil) "CLASS")
    
    ;; 3. Constants and Variables (less useful for lookup, but complete)
    ((boundp s)
     (cond
       ((constantp s) "CONSTANT")
       (t "VARIABLE")))
    
    (t "UNKNOWN")))

(defun get-symbol-doc (s type)
  "Retrieves the documentation string for symbol S based on its determined TYPE."
  (let ((doc-type 
          (cond 
            ((string-equal type "FUNCTION") 'function)
            ((string-equal type "GENERIC-FUNCTION") 'function)
            ((string-equal type "MACRO") 'function)
            ((string-equal type "CLASS") 'type)
            ((string-equal type "CONSTANT") 'variable)
            ((string-equal type "VARIABLE") 'variable)
            (t nil))))
    
    (if doc-type
        ;; DOCUMENTATION returns NIL if no docstring exists
        (or (documentation s doc-type) "") 
        "")))

;; You MUST define or import a function similar to this:
;; This is a conceptual function as the real implementation depends on your CL flavor.


(defun get-symbol-file (s)
  "Finds the file path where the symbol S is defined using SWANK:FIND-DEFINITIONS-FOR-EMACS.
   Returns the pathname string or an empty string if not found."
  (handler-case
      (let* ((swank-package (find-package :swank))
             (find-defs-symbol (when swank-package
                                 (find-symbol (string '#:find-definitions-for-emacs) swank-package)))
             (symbol-name (string-downcase (symbol-name s)))) ; SWANK usually expects lowercase string
        (cond
          ;; Check if SWANK is loaded and the specific function exists
          ((and swank-package find-defs-symbol (fboundp find-defs-symbol))
           ;; Call the SWANK function with the symbol's name as a string
           ;; Result structure: ( (NAME-STRING LOCATION-PLIST ...) ... )
           (let ((def-list (funcall find-defs-symbol symbol-name)))
             (when (and (listp def-list) (first def-list))
               ;; The location information is the second element of the first definition entry
               ;; Entry structure: ("(DEFUN...)" (:LOCATION ...) (:POSITION ...) ...)
               (let* ((first-definition (first def-list))
                      (location-plist (second first-definition))) ; This is the (:LOCATION (:FILE ...)) structure
                 ;; Traverse the property list (plist) to find the :FILE value
                 (when (and location-plist (listp location-plist) (eq (first location-plist) :location))
                   (let* ((location-details (second location-plist)) ; This is the (:FILE "/path/...") structure
                          (file-path (second location-details)))
		     file-path))))))
	             ;; Fallback if SWANK function is not available
          (t
           (warn "SWANK:FIND-DEFINITIONS-FOR-EMACS is not available. Source file location not found for ~A." s) "")))
    ;; Catch any errors during the introspection process
    (error (e)
      (warn "Error finding source for ~A: ~A" s e))))

(defun create-widgets-for-project-symbols-lookup-page (modelfunc)
  "Widget Factory: Calls the widget with the model data."
  (multiple-value-bind (jsondata) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:h2 "Lisp Project Symbol Lookup")
		       (:div :class "form-group"
			     (:label :for "symbol-input" "Search Symbol Name:")
			     (:input :type "text" :id "symbol-input" :class "form-control" :placeholder "Start typing a symbol name...")
			     (:small :class "form-text text-muted" "e.g., customer-profile, dod-bl, nst-dal"))
		       (:div :class "mt-4"
			     (:h4 "Search Results")
			     (:div :id "result-count" :class "text-muted" "Showing 0 results.")
			     (:div :id "results-output" 
				   (:table :class "table table-striped table-sm"
					   (:thead
					    (:tr
					     (:th "Name")
					     (:th "Type")
					     (:th "File Location")
					     (:th "Keywords")))
					   (:tbody :id "results-tbody"))))))))
	  (widget2 (function (lambda ()
		   (cl-who:with-html-output (*standard-output* nil) 
		     ;; --- JavaScript for Client-Side Filtering ---
		     (:script
      (cl-who:str
        (format nil "
          const lookupData = ~A;
          const tableBody = document.getElementById('results-tbody');
          const searchInput = document.getElementById('symbol-input');
          const resultCount = document.getElementById('result-count');

          function escapeHtml(text) {
              const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '\"': '&quot;', \"'\": '&#039;' };
              return text.replace(/[&<>\"']/g, (m) => map[m]);
          }

          function renderRow(entry) {
            // Entry format: [Name, Type, File, Docstring, Keywords]
            const name = escapeHtml(entry[0]);
            const type = escapeHtml(entry[1]);
            const file = escapeHtml(entry[2]);
            const keywords = escapeHtml(entry[4]);
            
            const fileLink = file ? `<a href=\"#\" title=\"${file}\">${file.split('/').pop()}</a>` : 'N/A';
            
            return `
              <tr>
                <td><strong>${name}</strong></td>
                <td><span class=\"badge bg-secondary\">${type}</span></td>
                <td>${fileLink}</td>
                <td>${keywords}</td>
              </tr>`;
          }

          function filterSymbols() {
              const query = searchInput.value.toUpperCase();
              let resultsHtml = '';
              let count = 0;

              for (const entry of lookupData) {
                  const name = entry[0];
                  const keywords = entry[4]; // Keywords are the 5th element (index 4)
                  
                  // Check 1: Ignore empty query.
                  if (query.length > 0) {
                      
                      const nameMatch = name.toUpperCase().includes(query);
                      const keywordMatch = keywords.toUpperCase().includes(query);

                      // Check 2: Match if the query is anywhere in the Name OR the Keywords
                      if (nameMatch || keywordMatch) { 
                          resultsHtml += renderRow(entry);
                          count++;
                      }
                  }
              }

              tableBody.innerHTML = resultsHtml;
              resultCount.textContent = `Showing ${count} results.`;
          }

          searchInput.addEventListener('input', filterSymbols);
          filterSymbols(); // Initial call to show empty table/count
        " jsondata))))))))
    (list widget1 widget2))))

;; You can define these in the same package as your other UI functions (e.g., :com.nstores.app)

(defun create-model-for-project-symbols-lookup-page ()
  "Model: Prepares the lookup data for the view."
  ;; Assumes *function-lookup-table* is loaded from lookup-data.lisp
  (let ((jsondata (json:encode-json-to-string (funcall (function-lookup-table)))))
     (function (lambda ()
       (values jsondata)))))



(defun com-hhub-controller-project-symbols-lookup-page ()
  "Controller: Renders the symbol lookup page."
  (with-mvc-ui-page  "Symbol Lookup" #'create-model-for-project-symbols-lookup-page #'create-widgets-for-project-symbols-lookup-page :role :superadmin))
