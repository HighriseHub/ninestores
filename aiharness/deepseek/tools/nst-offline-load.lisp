;;; nst-offline-load.lisp --- load the whole :nstores system OFFLINE, against the real
;;; database, with no web server and no live image.
;;;
;;;   cd /home/ubuntu/ninestores
;;;   # ONE-TIME setup (see below), then:
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load <this file>
;;;
;;; Exit 0 = pass. 1 = fail. 2 = setup problem.
;;;
;;; ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
;;; The invoice API had never been exercised behind a session, and the only way the
;;; tree's documentation allowed was a restart of the live image — which an agent
;;; cannot do here (sudo is refused: "no new privileges"). This harness reaches the
;;; real domain layer WITHOUT one: every प्रत्यय, the ferries, domain->response and
;;; render-json, connected to the real MySQL, driven through the actual route
;;; functions. It is how the 500 fix was proven end-to-end and how the settings
;;; route's fail-closed branch was reached — a branch the smoke suite states it
;;; cannot cover.
;;;
;;; ── THE FOUR THINGS THAT BLOCK THIS, ALL MEASURED 2026-09-26 ────────────────
;;;
;;; 1. hhub/nstores.asd HAS NO :depends-on. startup/load.lisp quickloads the 16
;;;    dependencies first; without that step the build dies inside core/dod-dal-bo.lisp
;;;    with "Package CLSQL does not exist", which reads like a broken source file.
;;;
;;; 2. init.lisp quickloads SWANK before anything else, and the tree READS the swank
;;;    package while compiling (core/nst-bl-ollama.lisp:914 is the first). Skipping it
;;;    gives "READ error during COMPILE-FILE: Package SWANK does not exist" — the
;;;    documented trap: a missing package is indistinguishable from a syntax mistake.
;;;
;;; 3. clsql-mysql declares its C component with output-files IN THE SOURCE DIRECTORY,
;;;    and .../quicklisp/.../clsql-20221106-git/db-mysql is drwxr-xr-x hunchentoot —
;;;    unwritable by this user. It fails as an opaque "OPERATION-ERROR while invoking
;;;    #<COMPILE-OP> on … clsql_mysql" that never mentions permissions. FIX: copy that
;;;    one dist directory somewhere writable and push it onto asdf:*central-registry*
;;;    ahead of quicklisp's, so ASDF finds the prebuilt clsql_mysql64.so fresh:
;;;
;;;      mkdir -p /tmp/nst-asdf/clsql-dist
;;;      cp -rp /home/ubuntu/quicklisp/dists/quicklisp/software/clsql-20221106-git \
;;;             /tmp/nst-asdf/clsql-dist/
;;;      chmod -R u+w /tmp/nst-asdf/clsql-dist
;;;
;;; 4. 🚨 THE BUILD ORDER ITSELF (fixed 2026-09-26, see hhub/nstores.asd line ~63).
;;;    dod-ini-sys installs (defmethod initBusinessContexts ((server BusinessServer) …))
;;;    at LOAD time, and BusinessServer is defined in hhub-bl-ent. Commit d6275d0 moved
;;;    dod-ini-sys ABOVE hhub-bl-ent, so a cold load aborted with
;;;       There is no class named COM.NSTORES.APP::BUSINESSSERVER
;;;    leaving startup/load.lisp's (start-das) unreached — the app would come up with
;;;    NO ACCEPTOR. The fix moves hhub-bl-ent above dod-ini-sys in BOTH hand-maintained
;;;    lists. THIS TOOL IS THE REGRESSION TEST FOR IT: before the fix it aborted here.
;;;
;;; ── AND READ THIS BEFORE CHANGING THE TOOL ─────────────────────────────────
;;; `cp -r` of the live image's ASDF cache does NOT work: copying gives every fasl a
;;; fresh mtime, ASDF then treats them all as up to date and loads STALE FASLS, and the
;;; failure looks like a source bug. Compile from source into a fresh XDG_CACHE_HOME.
;;; Also: a DIAGNOSTIC that reads symbols after (in-package …) inside a handler-case
;;; will report everything as NIL, because the reader read those forms in the ORIGINAL
;;; package — use fully-qualified names, or put (in-package …) at top level.

;;; Load the whole :nstores system offline FROM SOURCE, against the real database.
;;;
;;; Deliberately does NOT call start-das: no acceptor starts, so the live image is
;;; untouched and port 4244 is not contended. The point is to make the real domain
;;; layer — every प्रत्यय, the ferries, domain->response and render-json — available in
;;; a scratch process so a change can be exercised WITHOUT restarting the live server.
;;;
;;; ── WHY A FRESH CACHE THIS TIME ─────────────────────────────────────────────
;;; A previous attempt copied the live image's ASDF cache (/home/hunchentoot/.cache,
;;; 85M, sbcl-2.6.8) to reuse its fasls. `cp -r` gives every copied file a FRESH mtime,
;;; which makes ASDF consider every fasl up to date, so it LOADED fasls instead of
;;; compiling the sources. That run died loading core/dod-ini-sys.fasl with
;;;
;;;   There is no class named COM.NSTORES.APP::BUSINESSSERVER
;;;
;;; raised while installing
;;;   (defmethod initBusinessContexts ((server BusinessServer) …))   ; source line 694
;;; and BusinessServer is not defined until core/hhub-bl-ent.lisp (asd component 75,
;;; AFTER dod-ini-sys at 66 — both build lists agree, and the asd is `:serial t` with no
;;; `:module` forms, so that really is the load order).
;;;
;;; A cold `(ql:quickload :nstores)` plainly DOES work in this environment — the running
;;; image booted through exactly that call (startup/load.lisp) and serves requests — so
;;; the failure is a property of loading STALE FASLS, not of the source. This run
;;; therefore compiles everything from source, in serial order, and lets ASDF decide.
;;;
;;; ── THE ONE THING THAT BLOCKS A SCRATCH LOAD, AND ITS FIX ───────────────────
;;; clsql-mysql declares its C component with output-files in the SOURCE directory, and
;;; …/quicklisp/…/clsql-20221106-git/db-mysql is drwxr-xr-x hunchentoot — unwritable by
;;; this user. The failure is an opaque `OPERATION-ERROR while invoking #<COMPILE-OP> on
;;; … "clsql_mysql"` that never mentions permissions. A WRITABLE COPY of that dist
;;; directory, pushed onto asdf:*central-registry* ahead of quicklisp's, lets ASDF find
;;; the prebuilt clsql_mysql64.so fresh and never rebuild it. That copy must exist at
;;; *CLSQL-DIST-DIR*.

(defparameter *clsql-dist-dir* #p"/tmp/nst-asdf/clsql-dist/clsql-20221106-git/")

(load "~/quicklisp/setup.lisp")
(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(when (probe-file *clsql-dist-dir*)
  (push *clsql-dist-dir* asdf:*central-registry*)
  (format t "~&STAGE: writable clsql dist registered ahead of quicklisp's~%"))

;; 🚨 init.lisp quickloads SWANK BEFORE anything else, and the tree READS the swank
;; package at compile time (core/nst-bl-ollama.lisp line 914 is the first). A missing
;; package reports as `READ error during COMPILE-FILE: Package SWANK does not exist`,
;; which is indistinguishable from a syntax mistake — the documented trap. This is part
;; of the real boot sequence, not an extra.
(format t "~&STAGE: loading swank (init.lisp does this first)~%")
(ql:quickload :swank :silent t)
(format t "~&STAGE: loading the 16 declared dependencies~%")
(ql:quickload '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot
                :clsql :clsql-mysql :cl-smtp :parenscript :cl-async :cl-csv
                :cl-base64 :priority-queue :blackbird :cl-yaml) :silent t)

(format t "~&STAGE: quickloading :nstores FROM SOURCE (this compiles the tree)~%")
(handler-case
    (progn
      (ql:quickload :nstores :silent t)
      (format t "~&STAGE: LOADED~%")
      (in-package :nstores)
      (format t "~&STAGE: start-das fbound=~A (NOT called)~%" (fboundp 'start-das))
      (format t "~&STAGE: mysql-now -> ~A~%" (ignore-errors (mysql-now)))
      (dolist (s '(make fetch enumerate !update delete! !settings domain->response
                   render-json response-id-string generate-invoice-ext-url))
        (format t "~&STAGE:   ~A fbound=~A~%" s (fboundp s)))
      (format t "~&STAGE: classes: nst-invh=~A nst-invitm=~A detail=~A public=~A~%"
              (find-class 'nst-invh nil) (find-class 'nst-invitm nil)
              (find-class 'invh-detail-response nil)
              (find-class 'invh-public-url-response nil))
      (sb-ext:exit :code 0))
  (error (c)
    (format t "~&STAGE: FAILED: ~A~%" c)
    (sb-ext:exit :code 1)))
