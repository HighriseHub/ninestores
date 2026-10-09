;;; nst-model-widget-check.lisp — a page's MODEL and its WIDGETS must agree about the values between them.
;;;
;;;   cd /home/ubuntu/ninestores
;;;   sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-model-widget-check.lisp
;;;
;;; Exit 0 = every pair agrees (or only harmless unused returns remain). 1 = a page-breaking finding,
;;; named with its file and its suffix. 2 = usage.
;;;
;;; ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
;;; A page in this tree is a PAIR of functions:
;;;
;;;     (defun create-model-for-X ...)      returns (values A B C ...) inside its lambda
;;;     (defun create-widgets-for-X ...)    (multiple-value-bind (A B C ...) (funcall modelfunc) ...)
;;;
;;; The widgets are a SEPARATE FUNCTION: they see only what the model RETURNS. A model-local used in the
;;; widgets is an UNBOUND-VARIABLE, which means the reader is happy (so nst-preflight passes), the
;;; compiler is happy (it is a free variable, not a syntax error, so a clean build passes), every other
;;; offline tool is happy (none of them RENDERS a page) — and the customer gets a 500. That is exactly
;;; how COM.NSTORES.APP::DELIVERY-DISPLAY was found: bound in the model, used in the widgets, never
;;; returned, and the payment page threw UNBOUND-VARIABLE at render.
;;;
;;; WHAT IT CHECKS: for every create-MODEL-for-X / create-WIDGETS-for-X pair, the symbols of the model's
;;; LAST (values …) against the widgets' FIRST (multiple-value-bind (…). It reports values the model
;;; returns that the widgets never bind (harmless, usually dead — listed with --verbose) and, the one
;;; that breaks a page, variables the widgets BIND that the model does NOT return.
;;;
;;; ── IT SCANS TEXT, DELIBERATELY, AND NEEDS NO IMAGE ─────────────────────────
;;; Like the python3 tool it replaces, this is a TEXTUAL scan: paren/string/comment-aware spans, but no
;;; `read` — so it needs no build, no database, no clsql, no ASDF cache, and it cannot be taken down by
;;; an unreadable form in a file it is merely looking at. It is a heuristic, and it is deliberately
;;; FILE-LOCAL (a model in one file and its widgets in another are not paired). Both limits are the
;;; price of running in a second; the three findings it has produced were all real, and each was a page
;;; that 500s.
;;;
;;; PORTED FROM python3 (2026-10-09) and checked against it on the same tree: same 103 pairs, same
;;; findings. The port keeps the original's heuristics exactly, including the textual (values …) search
;;; and the case-sensitive operator names, so the two agree.

(defparameter *model-prefix* "create-model-for-")
(defparameter *widgets-prefix* "create-widgets-for-")

(defun check-whitespace-p (ch)
  (member ch '(#\Space #\Tab #\Newline #\Return #\Page) :test #'char=))

(defun check-search-ci (needle haystack &optional (start 0))
  "`search` with char-equal, which is what the tool's case-insensitive (defun …) scan needs."
  (search needle haystack :start2 start :test #'char-equal))

(defun check-form-span (text start)
  "The substring of the form beginning at START, respecting strings, character escapes and line comments.
   The loop's own return is the ANSWER: falling through to the tail would hand back the rest of the file."
  (let ((depth 0) (i start) (n (length text)) (in-str nil) (esc nil))
    (or (loop while (< i n) do
          (let ((ch (char text i)))
            (cond
              (in-str (cond (esc (setf esc nil))
                            ((char= ch #\\) (setf esc t))
                            ((char= ch #\") (setf in-str nil))))
              ((char= ch #\") (setf in-str t))
              ((char= ch #\;)
               ;; land ON the newline: the next iteration must not count it as anything but whitespace
               (let ((j (position #\Newline text :start i)))
                 (setf i (if j (1- j) n))))
              ((char= ch #\() (incf depth))
              ((char= ch #\)) (decf depth)
               (when (zerop depth) (return (subseq text start (1+ i)))))))
          (incf i))
        (subseq text start n))))

(defun check-value-symbol-p (token)
  "A value symbol: not a keyword, not a lambda-list marker, and not the `values` operator itself
   (a nested `(values …)` produced a literal \"values\" finding until this check existed)."
  (and (plusp (length token))
       (not (char= (char token 0) #\:))
       (not (char= (char token 0) #\&))
       (not (string= token "values"))))

(defun check-symbols-in-list (form)
  "The bare symbols of a (values A B C) / (A B C) list, ignoring keywords and nested forms."
  (let ((inner (subseq form 1 (1- (length form))))
        (out nil) (depth 0) (token (make-string-output-stream)))
    (flet ((flush ()
             (let ((tok (get-output-stream-string token)))
               (when (check-value-symbol-p tok) (push tok out)))))
      (loop for ch across inner do
        (cond ((char= ch #\() (incf depth))
              ((char= ch #\)) (decf depth))
              ;; a nested form's characters never reach the token, and its closing paren is swallowed
              ((and (zerop depth) (check-whitespace-p ch)) (flush))
              ((zerop depth) (write-char ch token))))
      (flush))
    (nreverse out)))

(defun check-model-values (body)
  "The symbol list of the LAST (values …) in the model: :NONE when the model has no such form. An EMPTY
   list is a real answer — (values) with nothing in it — and must not be confused with its absence."
  (let ((pos nil) (i 0) (n (length body)))
    (loop for j = (search "(values" body :start2 i)
          while j do
          (let ((k (+ j (length "(values"))))
            ;; \b: the next character must not continue the word
            (when (or (>= k n)
                      (not (or (alphanumericp (char body k)) (char= (char body k) #\_))))
              (setf pos j)))
          (setf i (+ j (length "(values"))))
    (if pos (check-symbols-in-list (check-form-span body pos)) :none)))

(defun check-widget-bindings (body)
  "The symbol list of the widgets' FIRST (multiple-value-bind (…): :NONE when there is no such form.
   An EMPTY bind list is a real answer — the widgets take nothing from the model — not an absence."
  (let ((j (search "(multiple-value-bind" body)))
    (if (null j)
        :none
        (let ((k (+ j (length "(multiple-value-bind")))
              (n (length body)))
          (loop while (and (< k n) (check-whitespace-p (char body k))) do (incf k))
          (if (and (< k n) (char= (char body k) #\())
              (check-symbols-in-list (check-form-span body k))
              :none)))))

(defun check-defun-pairs (text)
  "Every create-model-for-X / create-widgets-for-X defined in TEXT as an alist (SUFFIX . ((KIND . BODY)))."
  (let ((seen (make-hash-table :test #'equal))
        (i 0) (n (length text)))
    (loop for j = (check-search-ci "(defun" text i)
          while j do
          (setf i (+ j (length "(defun")))
          (let ((k i))
            (loop while (and (< k n) (check-whitespace-p (char text k))) do (incf k))
            (let ((end (or (position-if (lambda (c) (or (check-whitespace-p c) (char= c #\()))
                                        text :start k)
                           n)))
              (let* ((name (subseq text k end))
                     (suffix (cond ((and (> (length name) (length *model-prefix*))
                                         (string-equal *model-prefix* name :end2 (length *model-prefix*)))
                                    (cons "model" (subseq name (length *model-prefix*))))
                                   ((and (> (length name) (length *widgets-prefix*))
                                         (string-equal *widgets-prefix* name :end2 (length *widgets-prefix*)))
                                    (cons "widgets" (subseq name (length *widgets-prefix*)))))))
                (when suffix
                  (let* ((key (string-downcase (cdr suffix)))
                         (entry (gethash key seen)))
                    (setf (getf entry (intern (string-upcase (car suffix)) :keyword))
                          (check-form-span text j))
                    (setf (gethash key seen) entry)))))))
    (loop for key being the hash-keys of seen using (hash-value entry)
          collect (cons key entry))))

(defun check-lisp-files-under (target)
  "Every .lisp file of TARGET: the file itself, or the tree beneath it. :NONE when TARGET is neither —
   which is NOT the same as a directory that simply holds no .lisp file (that is an empty list, and the
   vacuity check downstream is what speaks to it). A directory probes as a pathname with no NAME."
  (let ((path (probe-file target)))
    (cond
      ((null path) :none)
      ((null (pathname-name path)) (directory (merge-pathnames "**/*.lisp" path)))
      (t (list path)))))

(defun check-read-text (path)
  "The file as text. UTF-8, falling back to latin-1 — the scan must not die on one bad byte."
  (let ((octets (with-open-file (in path :element-type '(unsigned-byte 8))
                  (let ((buf (make-array (file-length in) :element-type '(unsigned-byte 8))))
                    (read-sequence buf in)
                    buf))))
    (handler-case (sb-ext:octets-to-string octets :external-format :utf-8)
      (error () (sb-ext:octets-to-string octets :external-format :iso-8859-1)))))

(defun model-widget-check (targets &optional verbose)
  "Returns 0 when no page-breaking finding was seen, 1 when one was, 2 for an unusable argument."
  (let ((files nil))
    (dolist (target targets)
      (let ((found (check-lisp-files-under target)))
        (if (eq found :none)
            (progn (format *error-output* "usage: sbcl --load nst-model-widget-check.lisp [file-or-dir ...]~%")
                   (return-from model-widget-check 2))
            (setf files (append files found)))))
    (setf files (sort (remove-if (lambda (f)
                                   (let ((name (file-namestring f)))
                                     (or (char= (char name 0) #\#) (char= (char name (1- (length name))) #\~))))
                                 files)
                      #'string< :key #'namestring))
    (let ((pairs 0) (findings 0) (warnings 0))
      (dolist (f files)
        (let ((text (check-read-text f)))
          (dolist (entry (sort (check-defun-pairs text) #'string< :key #'car))
            (let ((model (getf (cdr entry) :model))
                  (widgets (getf (cdr entry) :widgets)))
              (when (and model widgets)
                (incf pairs)
                (let ((vals (check-model-values model))
                      (binds (check-widget-bindings widgets)))
                  (if (or (eq vals :none) (eq binds :none))
                      (format t "  SKIP ~A:~A — no (values …) or no (multiple-value-bind …)~%"
                              f (car entry))
                      (let ((missing (remove-if (lambda (v) (member v binds :test #'string=)) vals))
                            (unbound (remove-if (lambda (b) (member b vals :test #'string=)) binds)))
                        (when unbound
                          (incf findings)
                          (format t "  🚨 ~A: ~A~%" f (car entry))
                          (format t "        the widgets bind these but the model does NOT return them: ~A~%"
                                  unbound)
                          (format t "        (a widget using one of the model-locals of that name is an UNBOUND-VARIABLE at render)~%"))
                        (when missing
                          (incf warnings)
                          (when verbose
                            (format t "  ⚠  ~A: ~A — model returns, widgets ignore: ~A~%"
                                    f (car entry) missing)))))))))))
      (format t "=== model/widget pairs checked: ~D, page-breaking findings: ~D, harmless unused returns: ~D (--verbose to list them) ===~%"
              pairs findings warnings)
      ;; a silent empty result is a FAIL, not a pass: this check asserts it FOUND its inputs
      (when (zerop pairs)
        (format t "FAIL: no create-model-for-X / create-widgets-for-X pair was found at all — the scan looked in the wrong place~%")
        (return-from model-widget-check 1))
      (if (plusp findings) 1 0))))

(let* ((argv (rest sb-ext:*posix-argv*))
       (verbose (member "--verbose" argv :test #'string=))
       (targets (remove "--verbose" argv :test #'string=)))
  (sb-ext:exit :code (model-widget-check (or targets '("hhub")) verbose)))
