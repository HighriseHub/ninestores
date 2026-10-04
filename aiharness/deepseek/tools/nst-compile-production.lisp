;;; nst-compile-production.lisp --- run the TREE'S OWN build driver, offline.
;;;
;;;   cd /home/ubuntu/ninestores
;;;   XDG_CACHE_HOME=$PWD/.asdf-cache sbcl --noinform --non-interactive \
;;;     --load aiharness/deepseek/tools/nst-compile-production.lisp
;;;
;;; Exit 0 = pass. 1 = the build failed. 2 = setup problem.
;;;
;;; ── WHY THIS EXISTS (S15's AC (a)) ──────────────────────────────────────────
;;; S15's acceptance criterion is "`(compile-production)` reports Failed: 0, with
;;; only the expected cross-file style-warnings". That is the tree's own driver
;;; (hhub/package/compile.lisp), and running it against the LIVE image is FORBIDDEN:
;;; an in-image `load` that errors parks the worker in the debugger holding SBCL's
;;; PCL global mutex, after which nothing in that process can define a class again
;;; and only a restart recovers — destroying every session (build-and-load-CONTEXT §9).
;;;
;;; So the driver runs in a THROWAWAY SBCL: it cannot touch the server. Two further
;;; properties make this a real test rather than a weaker one:
;;;
;;;   * the driver's incremental gate reads PROJECT-LOCAL .fasl files (beside the
;;;     sources), never the ASDF cache — and the server loads from the ASDF cache
;;;     (compile-harness-CONTEXT §7). So this run cannot change what the server
;;;     serves, in either direction.
;;;   * `compile-hhub-files` catches errors PER FILE and records them (never
;;;     signals), so "Failed: 0" has to be READ from `*last-compilation-stats*` —
;;;     the summary also omits `Skipped` and prints `Success Rate: 0.0%` for a
;;;     healthy all-fresh run (compile-harness-CONTEXT §3). The invariant that
;;;     decides pass from catastrophe is:
;;;
;;;         compiled + skipped + failed = total-files
;;;
;;; ── THE FOUR THINGS THAT BLOCK A SCRATCH BUILD (measured; see nst-offline-load.lisp)
;;; 1. hhub/nstores.asd has no :depends-on — the 16 dependencies must be quickloaded
;;;    first, or the build dies inside core/dod-dal-bo.lisp with "Package CLSQL does
;;;    not exist", which reads like a broken source file.
;;; 2. init.lisp quickloads SWANK first and the tree READS the swank package at compile
;;;    time (core/nst-bl-ollama.lisp is the first) — skipping it gives a READ error
;;;    that is indistinguishable from a syntax mistake.
;;; 3. clsql-mysql declares its C component with output-files IN THE SOURCE DIRECTORY,
;;;    which is unwritable here. A writable copy pushed onto asdf:*central-registry*
;;;    ahead of quicklisp's is required (see the one-time setup in nst-offline-load.lisp).
;;; 4. The tree is full of clsql `[= …]` reader syntax — hence :clsql in the quickload
;;;    list. Without it the reader answers "Package [ does not exist".

(defparameter *clsql-dist-dir* #p"/tmp/nst-asdf/clsql-dist/clsql-20221106-git/")
(defparameter *setup-failed* nil)

(load "~/quicklisp/setup.lisp")
(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(if (probe-file *clsql-dist-dir*)
    (progn
      (push *clsql-dist-dir* asdf:*central-registry*)
      (format t "~&STAGE: writable clsql dist registered ahead of quicklisp's~%"))
    (progn
      (setf *setup-failed* t)
      (format t "~&STAGE: SETUP PROBLEM — *clsql-dist-dir* missing: ~A~%" *clsql-dist-dir*)
      (format t "~&STAGE: run the one-time setup quoted in nst-offline-load.lisp:~%")
      (format t "~&STAGE:   mkdir -p /tmp/nst-asdf/clsql-dist~%")
      (format t "~&STAGE:   cp -rp /home/ubuntu/quicklisp/dists/quicklisp/software/clsql-20221106-git /tmp/nst-asdf/clsql-dist/~%")
      (format t "~&STAGE:   chmod -R u+w /tmp/nst-asdf/clsql-dist~%")))

(when (and (not *setup-failed*)
           (handler-case (progn (ql:quickload :swank :silent t)
                                (ql:quickload '(:uuid :secure-random :drakma :cl-json :cl-who
                                                :hunchentoot :clsql :clsql-mysql :cl-smtp
                                                :parenscript :cl-async :cl-csv :cl-base64
                                                :priority-queue :blackbird :cl-yaml)
                                              :silent t)
                                t)
                         (error (c)
                           (setf *setup-failed* t)
                           (format t "~&STAGE: SETUP PROBLEM — dependencies: ~A~%" c)
                           nil)))
  (format t "~&STAGE: dependencies loaded~%")
  (handler-case
      (progn
        ;; ── THE PRECONDITION, AND WHY IT IS NOT OPTIONAL ─────────────────────
        ;; The AC is "`(compile-production)` reports Failed: 0", and the human runs
        ;; that in the LIVE image — where :nstores is ALREADY LOADED before the
        ;; driver is called. So the driver's job there is: load 148 project-local
        ;; .fasl files, recompile the stale one, load it. It is NOT a cold bootstrap,
        ;; and this tool must reproduce the real precondition or it measures a
        ;; different thing.
        ;;
        ;; ⚠ AND THIS FORM IS ONE TOP-LEVEL FORM ON PURPOSE. The reader reads a whole
        ;; top-level form BEFORE any of it is evaluated, so a symbol in a package that
        ;; the load itself creates — `com.nstores.app::anything` — is a READ error and
        ;; kills the tool before the first STAGE line, with a backtrace pointing at the
        ;; loader rather than at the symbol. (Measured 2026-10-04, on the first version
        ;; of this file.) Anything read after the load goes in a SEPARATE top-level
        ;; form, or is looked up at runtime with `find-symbol`.
        (format t "~&STAGE: quickloading :nstores FROM SOURCE (the live image's precondition)~%")
        (ql:quickload :nstores :silent t)
        (format t "~&STAGE: :nstores loaded~%")
        ;; Loading the driver has no build side effects (compile-harness-CONTEXT §6):
        ;; it defines the list, the gate and the entry points, and nothing else.
        (load "hhub/package/compile.lisp")
        (format t "~&STAGE: driver loaded; get-hhub-file-list -> ~D files~%"
                (length (get-hhub-file-list)))
        (format t "~&STAGE: calling (compile-production) — incremental, no optimize-code~%")
        (compile-production)
        (let* ((stats *last-compilation-stats*)
               (total (compilation-stats-total-files stats))
               (compiled (compilation-stats-compiled stats))
               (skipped (compilation-stats-skipped stats))
               (failed (compilation-stats-failed stats))
               (accounted (+ compiled skipped failed))
               (issues (compilation-stats-warning-details stats))
               (failed-files (compilation-stats-failed-files stats)))
          (format t "~&~%=== S15 (a) — compile-production, measured from the stats struct ===~%")
          (format t "~&  Total Files    : ~D~%" total)
          (format t "~&  Compiled       : ~D~%" compiled)
          (format t "~&  Skipped (fresh): ~D~%" skipped)
          (format t "~&  Failed         : ~D~%" failed)
          (format t "~&  Warnings       : ~D~%" (compilation-stats-warnings stats))
          (format t "~&  Style Warnings : ~D~%" (compilation-stats-style-warnings stats))
          (format t "~&  Compiler Notes : ~D~%" (compilation-stats-notes stats))
          (format t "~&  compiled+skipped+failed = ~D (must equal Total Files)~%" accounted)
          (format t "~&  FILES WITH ISSUES: ~D~%" (length issues))
          (dolist (item (reverse issues))
            (format t "~&    . ~A~%" (car item)))
          (when failed-files
            (format t "~&  FAILED FILES:~%")
            (dolist (f (reverse failed-files))
              (format t "~&    ! ~A~%" f)))
          (format t "~&~%=== S15 (a) VERDICT: ~A ===~%"
                  (cond ((plusp failed) "FAIL (a file did not compile)")
                        ((/= accounted total) "FAIL (the counts do not account for every file)")
                        (t "PASS (Failed: 0, every file accounted for)")))
          (sb-ext:exit :code (if (and (zerop failed) (= accounted total)) 0 1))))
    (error (c)
      (format t "~&STAGE: the driver signalled: ~A~%" c)
      (sb-ext:exit :code 1))))

(when *setup-failed*
  (format t "~&STAGE: FAILED — setup, not the tree~%")
  (sb-ext:exit :code 2))
