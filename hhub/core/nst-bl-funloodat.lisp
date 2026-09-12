(in-package :nstores)

(defun function-lookup-table () (function (lambda () 
  '(
    ("WITH-HTML-COLLAPSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CLEAR-MEMOIZE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Clear the hash table from a memo function." "" NIL)
    ("MAKE-DOMAIN-CTX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("CTX-ROUTE-KEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("HHUB-UNKNOWN" "CLASS" "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for logical database results (non-fatal)." "" NIL)
    ("GETEXCEPTIONSTR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("GET-FUNCTION-DOCSTRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Returns the live documentation string of FUNCTION-NAME from the image.
   Use to verify the docstring remains accurate after refactoring, and to spot functions lacking one."
     "" NIL)
    ("COM-HHUB-POLICY-CUST-EDIT-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COMMIT-REFACTORING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Writes *last-refactored-code* to disk and hot-loads it into the image.
   If FUNCTION-SYMBOL is omitted, uses *last-refactored-target* from the last session.

   Usage:
     (commit-refactoring)                         ; uses last session's target
     (commit-refactoring 'my-fn)                  ; explicit symbol
     (commit-refactoring 'create-model-for-updatewarehouse)"
     "" NIL)
    ("SYNCOBJECTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("HHUB-BUSINESS-ADAPTER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("JSONVIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXVENDORCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("MAKE-LAZY" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "" NIL)
    ("BO-CONTRADICTORY-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is contradictory." "" NIL)
    ("HHUB-RANDOM-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CTX-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("DISPATCH-TOOL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Resolves :action to its registered tool and calls it.
   Single-arg tools receive :target only.
   Two-arg tools (define-tool with content-arg) also receive :content."
     "" NIL)
    ("RESTORE-DELETED-AUTH-POLICY-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CTX-ADAPTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("DOREADALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("CTX-REQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("MEMO" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Return a memo-function of fn." "" NIL)
    ("BIND-GENERATED-ROW-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "The ONLY copy-back from a freshly-inserted dbobj to its domain
   entity. Every make method calls this — not an inline slot-value
   setf — so the narrowing is enforced at one call site, not N."
     "" NIL)
    ("NST-VIEW-CONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("GET-CURRENCY-FONTAWESOME-SYMBOL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-POLICY-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("META" "MACRO" "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Alist is passed already quoted by the caller.
   Stored directly — no transformation needed."
     "" NIL)
    ("NST-RESPONSE-NIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("GETBUSINESSSERVICEMETHOD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CURRENT-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY/MM/DD format" "" NIL)
    ("HHUB-ABAC-URI-MISMATCH-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when the DB transaction URI and the browser request URI do not match."
     "" NIL)
    ("HHUB-GET-CACHED-AUTH-POLICIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("GET-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DOMAIN->RESPONSE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Reverse ferry: Tree 1 result → Tree 2 nst-response-model.
    entity is the ONLY dispatching argument that may be nst-domain-entity.
    Returns an nst-response-model — never the entity itself.
    The entity does not cross into Ring 4 (UI/HTTP) directly."
     "" NIL)
    ("BO-KNOWLEDGE-TIMESTAMP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("RESTORE-DELETED-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("WITH-STANDARD-PAGE-TEMPLATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("REFACTORING-PRESSURE-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Budget pressure text tuned for the refactoring pipeline: escalates as the
   step budget drains, and nudges toward completion once source and type are in."
     "" NIL)
    ("%DEFUN-DELIMITER-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "T when CHAR may sit immediately before or after the `defun' token of a valid
   header. NIL means the token is really part of a longer symbol such as
   `my-defun-helper', which must not be treated as a definition."
     "" NIL)
    ("VIEW-CLASSES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CREATEALLVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Converts the ResponseModel to ViewModel" "" NIL)
    ("WITH-MVC-UI-COMPONENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ATTRIBUTE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("BUILD-DOMAIN-CTX-FROM-REQUEST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "ASSUMPTION FLAGGED ABOVE: signature matches make-domain-ctx as
   recalled from memory, not re-verified against Document 3/5 this
   session. tenant-id MUST come from session (get-login-company or
   equivalent), NEVER from client params directly — this is the
   नियम-1 boundary; verify the actual key your session layer uses
   before trusting this line in production."
     "" NIL)
    ("WITH-HTML-CARD" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "A HTML Bootstrap 5.x card generator macro." "" NIL)
    ("CTX-OUTPUT-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("VIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" ""
     NIL)
    ("GET-DATEOBJ-FROM-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-CONTROLLER-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Controller: Renders the symbol lookup page." "" NIL)
    ("COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("GET-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("BO-UNKNOWN-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is unknown." "" NIL)
    ("PROCESSUPDATEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Update method" "" NIL)
    ("CHECK-EXPORTED-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Checks whether FUNCTION-NAME is exported from its package (part of the public API).
   Exported symbols must have their signatures preserved exactly — callers outside this package depend on them."
     "" NIL)
    ("DELETE!" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "लोप प्रत्यय — soft-delete. Sets deleted-state to \"Y\". Never a
    hard DELETE — नियम-2 already blocks all further verbs on the
    result; physical removal is not this project's concern."
     "" NIL)
    ("CREATE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DOD-GET-VIEW-MODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Return the persisted tile/table preference for SESSION-KEY, or DEFAULT
when unset/invalid. Accepted modes are the strings \"tile\" and \"table\"."
     "" NIL)
    ("READ-DEFUN-ARGLIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Returns the lambda list of the FIRST (defun FUNCTION-NAME ...) in CONTENT, or
   NIL when it cannot be determined. Reads the on-disk source rather than
   introspecting the image, which stays correct even when an earlier
   build-image-time redefinition shadows the definition being edited."
     "" NIL)
    ("DOWNLOADHTMLFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CREATEWHATSAPPLINKWITHMESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("LAZY-NTH" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("COPY-KAARAKA-REF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-ISSUSPENDED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("DESTROY-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-SUBSCRIPTION-PLAN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("PRESENTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("BUSINESSOBJECTNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("HTML-RANGE-CONTROL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-PINCODE-API-RESULT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Simulates the external API call and maps its output to a 4-valued truth value."
     "" NIL)
    ("WITH-HTML-FORM" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CTX-VIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GANA-PACKAGE-FOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Returns the गण package (keyword) that owns verb-symbol.
    [STRUCTURAL/LEGAL]: an unregistered verb reaching this function
    means a verb was invoked without being declared in Document 1's
    grammar — this is treated as an error, not a silent no-op, because
    silently returning nil here would make the ferry dispatch into
    nothing and fail confusingly three lines later instead of failing
    clearly at the actual point of the grammar violation."
     "" NIL)
    ("WITH-DB-CALL-LIST" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Execute DB-FORM expecting a list result and return a BO-KNOWLEDGE instance.

   DB-FORM    — any CLSQL SELECT expression that returns a flat list.
   SOURCE     — provenance string for the bo-knowledge instance.
   PK-EXTRACTOR — optional one-arg function (lambda (row) ...) that
                  returns the primary-key value for each row.  When
                  supplied, the result list is scanned for duplicate
                  PKs; any duplicate promotes truth to :C.

   TCUF semantics:
     :T — non-empty list returned with no duplicate PKs
     :F — nil or empty list (no matching records exist)
     :C — duplicate PKs detected in result list
     :U — any error during execution of DB-FORM"
     "" NIL)
    ("CTX-VIEW" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("BACKUP-FILE-TIMESTAMPED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Copies FILE-PATH to a timestamped sibling named FILE~YYYYMMDD-HHMMSS.
   That suffix is already git-ignored via the existing `*.*~' rule, so backups
   never pollute the working tree.

   Returns (values backup-pathname :ok) when the original was copied, and
   (values nil :failed) when the copy could not be made — in which case the
   caller must NOT overwrite the original."
     "" NIL)
    ("HHUB-INIT-NETWORK-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("REQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COLUMN-TYPE-EQUALS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("SETCOMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Set the Company" ""
     NIL)
    ("HANDLE-ADD-TO-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "The application service layer function that orchestrates the boundary check."
     "" NIL)
    ("ACTOR-LOCK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("SELECT-ABAC-SUBJECT-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("DISCOVERSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "discover a business service based on the service-code" "" NIL)
    ("EXTERNAL-INVENTORY-CHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Mocks an inventory microservice call. Must return payload and status." ""
     NIL)
    ("GET-SYSTEM-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("RENDER-UI-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("TCUF-VALUE-CHECKER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Adapter function that performs the simple, deterministic T/F check." ""
     NIL)
    ("RM-ROW-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Shared helper — every verb needing row-id extracts it the same way.
   NOT a new abstraction layer, just avoiding six copies of one getf."
     "" NIL)
    ("BO-KNOWLEDGE-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("BUSINESSSERVICES-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("LAZY-NULL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "" NIL)
    ("AFTER-DISPATCH-HOOK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("MYSQL-NOW+DAYS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("HHUB-INIT-BUSINESS-FUNCTION-REGISTRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("REFACTORING-COMPLETE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Signalled when the agent delivers a completed refactoring.
                   Caught by the agent loop to terminate cleanly with the result string."
     "" NIL)
    ("CREATE-WIDGETS-FOR-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Widget Factory: Calls the widget with the model data." "" NIL)
    ("MIN-ITEM" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("GENERATE-AGENT-PROMPT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Builds the agent system prompt directly from the live tool registry.
   Always in sync with what is implemented — no separate schema to maintain."
     "" NIL)
    ("MY-NOT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Implements the logical NOT operator for FDE logic." "" NIL)
    ("COLLECT-ABAC-ATTRIBUTES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("RENDER-UI-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Render a component by invoking its renderer with MODELFUNC.
Returns a list of widget outputs."
     "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXPRODCATGCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("COPY-BUSINESSOBJECT-TO-DBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Syncs the dbobject and the domainobject" "" NIL)
    ("GET-FUNCTION-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Returns whether FUNCTION-NAME is a FUNCTION, GENERIC-FUNCTION, MACRO, or UNBOUND.
   Call early — macros and generic functions require fundamentally different refactoring strategies."
     "" NIL)
    ("EVALUATE-CHECKOUT-READINESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Evaluates the final checkout decision based on multiple FDE truth values."
     "" NIL)
    ("ABAC-REQUEST-URI" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-BULK-PRODUCT-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DOREAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("ACTIVE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("WITH-HTML-TABLE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("TEST-EXTRACT-DOMAIN-INITARGS-IGNORES-UNKNOWN-KEYS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "A key in rm.params that entity-class does not declare as an initarg
   must be silently dropped, not passed through to make-instance.
   STUB: rm.params contains :bogus-field \"x\", assert absent from result."
     "" NIL)
    ("JSCRIPT-DISPLAYSUCCESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DEFINE-GANA-VERBS" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Self-registering — called once near the top of each proc.GANA
   package file, right after that package's defpackage form.
   Keeps verb→गण ownership declared in the same file as the verbs
   themselves, so the two can never silently drift apart."
     "" NIL)
    ("SEARCH-IN-HASHTABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DOD-AUTH-ATTR-LOOKUP" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("DOD-AUTH-POLICY-ATTR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("WITH-DB-READ-ONE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "SELECT-one boundary macro for CLSQL via DBAdapterService.db-fetch.

   Calls (db-fetch DBAS ROW-ID), inspects the returned list length,
   and returns a BO-KNOWLEDGE instance."
     "" NIL)
    ("COM-HHUB-POLICY-COMPADMIN-UPDATEDETAILS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WITH-NST-DB-DELETE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "SOFT-DELETE boundary macro, no DBAdapterService holder. Writes
   ONLY deleted-state via clsql:update-record-from-slot — narrower
   than with-nst-db-create/update's full-instance write, deliberately,
   so a delete can't clobber concurrent changes to other columns.
   BODY must set (deleted-state dbobj) to \"Y\" and return dbobj.
   :F = PRE-FLIGHT found zero live rows, ALLOW-IDEMPOTENT nil (caller
   expected a live row; it's gone — a real failure to report, not
   silently swallowed). :T/:already-absent = same zero-row case,
   ALLOW-IDEMPOTENT t (cleanup/expiry flows: desired state already
   holds). :C = PRE-FLIGHT found >1 live rows — only reachable if
   PRE-FLIGHT queries a non-unique key; unreachable for row-id-keyed
   deletes like nst-whs's. :U = any error, logged."
     "" NIL)
    ("HHUB-INIT-BUSINESS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("INSERT-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp"
     "Insert a transaction row (and, if its governing policy does not exist yet,
   insert that policy too). Idempotent on transaction NAME.

   Either pass :policy-id (the AUTH_POLICY_ID you already know) or pass
   :policy-name, :policy-description, :policy-func to have the policy created
   implicitly and linked.

  Returns the transaction ROW_ID (existing or freshly inserted)."
     "" NIL)
    ("?EXISTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "प्रत्यभिज्ञा प्रत्यय — existence check, Belnap-returning (:T/:F/
    :U/:C). lookup-value's meaning is entity-specific and documented
    per method — usually the primary id, but for uniqueness checks
    (GSTIN, phone, email) it is whatever field must be unique."
     "" NIL)
    ("COM-HHUB-POLICY-SUSPEND-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-HT-VAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CHECK&ENCRYPT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("TEST-GANA-PACKAGE-FOR-RESOLVES-JUNCTION-ENTITY-VERBS-CORRECTLY"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "nst-inv is a triple-junction entity. Verify gana-package-for routes
   correctly per VERB, not per entity:
     (gana-package-for 'invoice)      → :proc.finance
     (gana-package-for 'reconcile-2b) → :proc.tax
     (gana-package-for 'approve)      → :proc.governance
   All three verbs act on the SAME entity class (nst-inv) but resolve
   to three DIFFERENT गण packages. This is the bug the original ferry
   had — entity-class alone could never have produced this."
     "" NIL)
    ("DOD-CONTROLLER-PASSWORD-RESET-MAIL-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-SYSTEM-AUTH-POLICIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CURRENT-TIME-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current time  as a string in HH:MM:SS  format" "" NIL)
    ("FIND-SIMILAR-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Searches the project function index for names structurally similar to FUNCTION-NAME.
   Detects existing utilities the target may be reimplementing — eliminates duplication."
     "" NIL)
    ("REQUESTMODEL-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("ACTOR-MAX-QUEUE-SIZE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("DBADAPTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WITH-KNOWLEDGE-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("SAFE-READ-FROM-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Attempts to read a Lisp expression from a string, returning a default value if parsing fails."
     "" NIL)
    ("COM-HHUB-POLICY-CREATE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("MODAL-DIALOG-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("PARSE-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a date string of the form \"DD/MM/YYYY\" and return the 
corresponding universal time."
     "" NIL)
    ("CTX-CONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CONVERT-NUMBER-TO-WORDS-INR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CAD-PRODUCT-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("RENDER-HTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Post-ferry outbound encoding, HTML. response dispatches the method:
    a single nst-boundary-object (or its subclass), a LIST of them, or a
    response-model Belnap sentinel. Returns an HTML string. Same multiple-
    dispatch contract as render-json — response determines both
    cardinality and entity type."
     "" NIL)
    ("JSONDATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DOMAIN-CTX-OVERRIDE-REASON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("WITH-MVC-UI-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-MODAL-DIALOG-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CONFLODIS2-RENDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Ring-4 dṛś: encode RESPONSE using the adhara render contract.
   Lists are composed element-wise here (the dispatcher stays aggregate-agnostic;
   no per-aggregate LIST method is required). Each element is normalised through
   conflodis2-json-text / conflodis2-html-fragment, because the render methods it
   calls are allowed to return either text or a Lisp structure."
     "" NIL)
    ("GET-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("WITH-NST-ERROR-BOUNDARY" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("ATTRIBUTE-TYPE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("SELECT-AUTH-ATTR-BY-KEY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("GET-SYSTEM-ABAC-ATTRIBUTES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("VIEWMODELCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WITH-NO-NAVBAR-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DISPLAY-CSV-AS-HTML-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-CURRENCY-FONTAWESOME-SYMBOLS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CREATE-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("HHUB-DATABASE-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for logical database results (non-fatal)." "" NIL)
    ("IPADRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("FIND-ACTION-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Resolve ROUTE-KEY to its action-route, or signal a clear grammar error.
   An unknown route is a Ring-3 registration mistake — fail loudly, never
   silently no-op (same discipline as gana-package-for)."
     "" NIL)
    ("NST-ENTITY-UNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Belnap :U sentinel. [LEGAL: callers MUST treat this as 'cannot proceed',
    never as 'assume false' or 'assume true'.]"
     "" NIL)
    ("FIND-OUTBOUND-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CHECK-NULL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Safely checks if VALUE is null and signals an error if it is.
   
   Parameters:
   - VALUE: The value to check for null
   - ERROR-MESSAGE: Optional custom error message (default: 'Null value encountered')
   - ERROR-TYPE: Optional error type (default: 'null-value-error)
   
   Returns:
   - The original value if not null
   - Signals an error if value is null
   
   Example usage:
   (check-null some-value \"Expected non-null value for calculation\")"
     "" NIL)
    ("COM-HHUB-POLICY-GST-HSN-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PERSIST-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("TOOL-FIND-FUNCTION-METADATA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Searches the function lookup dataset for a matching function or generic-function.
   Accepts symbols or strings (case-insensitive). Returns (values plist foundp)."
     "" NIL)
    ("RUN-AUTONOMOUS-TASK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Manages the agent loop, reading raw LLM strings directly into live Lisp S-expressions."
     "" NIL)
    ("ACTOR-BEHAVIOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("SETEXCEPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Set the Exception for the Database Adapter Service" "" NIL)
    ("CURRENT-DATE-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("SAFE-READ-ALIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Safely reads an alist from STRING. Strips common LLM markdown artifacts before parsing."
     "" NIL)
    ("AUDIT-LEVEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("WITH-DB-CREATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "INSERT boundary macro for CLSQL via DBAdapterService.db-save.

   Returns a BO-KNOWLEDGE instance.  Status-clauses (:T ...) (:F ...) 
   (:U ...) (:C ...) are optional; if omitted the bo-knowledge is 
   returned and you can branch with WITH-BO-KNOWLEDGE-CHECK."
     "" NIL)
    ("HHUB-GET-CACHED-BUS-OBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("BO-KNOWLEDGE-TRUTH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("GET-PROJECT-SYMBOLS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Collects ALL defined symbols (internal and external functions, macros, and classes) 
   from the project's packages."
     "" NIL)
    ("ROUTE-OP->METHOD-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Extract operation from keyword like :customer/read and compute method name."
     "" NIL)
    ("COM-HHUB-POLICY-CUSTOMER-ADDRESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("AGENT-CALL-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Renders the ALREADY CALLED list from COMPLETED-TOOLS." "" NIL)
    ("UPDATE-INVOICE-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read, modify, and save YAML settings." "" NIL)
    ("OLLAMA-GENERATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("NST-GET-CACHED-INVOICE-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("WITH-CATCH-FILE-UPLOAD-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("LIST-SIBLING-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Lists all other defun/defmacro/defgeneric forms in the same source file as FUNCTION-NAME.
   Reveals available utilities and project naming conventions the refactored code should follow."
     "" NIL)
    ("CURRENT-YEAR-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "" NIL)
    ("LIST-FILE-GLOBALS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Lists all defparameter and defvar forms in the same source file as FUNCTION-NAME.
   Shows what global state the function may be reading or mutating — important context for refactoring."
     "" NIL)
    ("HHUB-FUNCTION-MEMOIZE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("TEXT-EDITOR-CONTROL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("VIEWMODELNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-UPDATE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("KAARAKA-REF" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "A typed reference used by recipient/source below (and any future
   kāraka-valued field). Deliberately NOT a raw cons cell — printable,
   type-checkable at the REPL, extensible without breaking callers.
   ASCII name: kaaraka-ref, not kāraka-ref — see typing-convention
   discussion; double-a spells the long ā without a diacritic."
     "" NIL)
    ("COM-HHUB-POLICY-DELETE-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DELETEBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Delete the business object repository" "" NIL)
    ("NST-GET-CACHED-PRODUCT-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("HHUB-NO-RESULT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when a DB query returns zero rows." "" NIL)
    ("START-DAS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("EXTRACT-DEFUN-REGIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Scans CONTENT for complete top-level (defun FUNCTION-NAME ...) forms using
   string-, comment- and character-literal-aware parenthesis matching, and
   returns a list of (values start end) cons cells in file order.

   Unlike a substring search this cannot be fooled by a nested defun, a mention
   inside a docstring, or a match in a comment, and it finds EVERY definition of
   FUNCTION-NAME rather than only the first."
     "" NIL)
    ("CREATE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("WRITE-YAML-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Write a Lisp data structure to a YAML file." "" NIL)
    ("PARAMS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("GET-SYSTEM-ABAC-SUBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("WRITE-FILE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Rewrites FILE-PATH with CONTENT, preserving the original file mode." ""
     NIL)
    ("GET-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("PRINT-VENDOR-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("NST-GET-CACHED-WAREHOUSE-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CREATE-MODEL-WITHNILDATA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOMAIN-CTX-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("CREATED-AT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-NUMBER" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GENERATE-DESCRIPTIVE-FILENAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("ENSURE-NOT-NULL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("LAZY-CAR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("VIEWUNKNOWN" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "" "" NIL)
    ("WITH-STANDARD-ADMIN-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("NST-BOUNDARY-OBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "ROOT of ALL boundary/adapter objects. NEVER inherits from
    nst-domain-entity — that inheritance would recreate the exact
    vulnerability this document exists to close.

    NEVER accepted as the primary dispatching argument by any proc.GANA
    or proc.bs method. Exists ONLY between HTTP/UI/CLI and the domain
    grammar. Dies at the Adapter boundary — the लोप principle, now
    structural rather than conventional."
     "" NIL)
    ("BUSINESSSERVER" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("AGENT-LOG-BLOCK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Renders LIST of session-log lines with a head-truncated preview of each."
     "" NIL)
    ("SELECT-USER-ROLE-BY-USERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("WELCOMEMESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ROUTE-TAGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("TAKE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" ""
     NIL)
    ("HHUB-CONTROLLER-CREATE-WHATSAPP-LINK-WITH-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DELETE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("OLLAMA-CHAT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("WITH-STANDARD-ADMIN-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ROUTE-METADATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("NST-RESPONSE-UNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("HHUBSENDMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CTX-REQUESTMODEL-PARAMS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GET-SYMBOL-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Finds the file path where the symbol S is defined using SWANK:FIND-DEFINITIONS-FOR-EMACS.
   Returns the pathname string or an empty string if not found."
     "" NIL)
    ("BUSINESSOBJECTUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("TEST-EXTRACT-DOMAIN-INITARGS-STRIPS-ALL-RESERVED-FIELDS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Every symbol in *reserved-initargs* must be absent from the result,
   regardless of what rm.params contains.
   STUB: build rm.params containing all five reserved keys plus one
   legitimate key, assert only the legitimate key survives."
     "" NIL)
    ("BO-KNOWLEDGE-PAYLOAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("SELECT-ROLE-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("WITH-NST-DB-UPDATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "UPDATE boundary macro, no DBAdapterService holder. BODY performs
   the raw CLSQL write and must return dbobj as its last form.
   :F = PRE-FLIGHT found zero rows (target gone — real, expected,
   not an error). :C = PRE-FLIGHT found >1 rows (ambiguous unique
   key — refuse to mutate, don't guess which row). :T = write
   succeeded. :U = any error during pre-flight or write, logged.
   Without :pre-flight, :F/:C can never be produced — caller must
   have already confirmed existence some other way (see nst-whs's
   !update, which pre-fetches instead of using this parameter)."
     "" NIL)
    ("CTX-RESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-1" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("FIND-CALLER-NAME-FROM-BACKTRACE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Uses string parsing on SBCL's LIST-BACKTRACE to find the 
   symbol name of the function that called the DB adapter."
     "" NIL)
    ("DB-FETCH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch the DBObject by row-id" "" NIL)
    ("USERSESSIONOBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DOMAIN-CTX-RECIPIENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-DELETE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GETBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch the Business Object from repository." "" NIL)
    ("BO-KNOWLEDGE->BOUNDARY-RESULT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return a boundary-style list like (TRUTH PAYLOAD SOURCE...)." "" NIL)
    ("RESET-PASSWORD-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CUSTOMER-INVOICES-LISTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("ROUTE-ACTION-VERB" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("SUBMITFORMEVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("UPDATE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CAD-LOGIN-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("OLLAMA-LISP-HELP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Enhanced interactive help helper. If :look-up-fn is passed, it extracts the
   live runtime system documentation string directly from the running Lisp image."
     "" NIL)
    ("INIT-HHUBPLATFORM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-PASSWORD-RESET-TOKEN-EXPIRED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CREATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("REFACTORING-ON-COMPLETE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Completion extractor for the refactoring pipeline. Handles both delivery
   conventions: :content . :delivered (code in raw text) and a parsed string."
     "" NIL)
    ("LAZY-FIND-IF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SHOW-INVOICE-CONFIRM-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-RESET-PASSWORD-INSTANCE-BY-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("ADAPTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("GET-COMPILE-WARNINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Compiles the source file containing FUNCTION-NAME and collects warnings and notes.
   Does not modify the file. Use to identify latent issues to address proactively during refactoring."
     "" NIL)
    ("PING-RESPONSE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CAD-LOGIN-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("UPDATE-RESET-PASSWORD-INSTANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("LAZY-CONS" "MACRO" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("TEST-COUNTER-ACTOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp"
     "Test the lifecycle and behavior of the counter actor using standard assert."
     "" NIL)
    ("NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CONCAT-STRINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-8" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ROUTE-REQUIRED-ROLES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-PRDSUBS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("PROCESSREADALLREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Read method" "" NIL)
    ("ROUND-TO-2-DECIMAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Standard rounding to 2 decimal places." "" NIL)
    ("%LOG-DB-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Append a DB error to the business-functions log file." "" NIL)
    ("CURRENT-YEAR-STRING++" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "" NIL)
    ("SELECT-BUS-TRANS-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("MY-OR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Implements the logical OR operator for FDE logic.
   (Based on the join operation of the Truth lattice.)"
     "" NIL)
    ("POLICY-ATTR-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("MAKE-PRESENTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Returns a presenter instance for this request." "" NIL)
    ("COM-HHUB-POLICY-CREATE-ATTRIBUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("NST-SHIPPING-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("DOD-USER-ROLES" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("GET-UNIX-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("NST-GET-CACHED-ORDER-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("ERROR-MESSAGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("HAS-PERMISSION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp"
     "Policy Enforcement Point (PEP).
   Returns (list returnvalue exceptionstr), where returnvalue is T/NIL,
   and exceptionstr is a user-facing error string or NIL on success."
     "" NIL)
    ("CREATE-DIGEST-MD5" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-4" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DISPLAY-CUSTOMER-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CONFLODIS2-JSON-TEXT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "One render-json RESULT → one JSON text.
   The render-json contract in this tree is SPLIT: per-ENTITY methods return a
   Lisp structure (e.g. WarehouseResponseModel → an alist), while per-LIST and
   sentinel methods return already-encoded text. The dispatcher must emit ONE
   document, so encode only what is not already text — interpolating a Lisp
   structure into a JSON array with ~A would emit Lisp syntax, not JSON."
     "" NIL)
    ("COM-HHUB-ATTRIBUTE-CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("CREATEBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Create a business context" "" NIL)
    ("GETBUSINESSSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("GET-VENDOR-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DELETEBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes a business context" "" NIL)
    ("PERMISSION-CHECKER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("KILL-THREADS-BY-PREFIX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Kills all threads whose names start with PREFIX." "" NIL)
    ("HHUB-EXECUTE-NETWORK-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("GETREQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("ROUTE-OUTPUT-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("WITH-HTML-FORM-HAVING-SUBMIT-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("STOP-DAS" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp"
     "" "" NIL)
    ("ACTOR-QUEUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("WITH-STANDARD-CUSTOMER-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("LOOKUP-METADATA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Confirms FUNCTION-NAME exists in the project index. Returns metadata plist with name, type, and file path."
     "" NIL)
    ("NST-DOMAIN-ENTITY" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "ROOT of ALL domain entities. Every nst-pr, nst-ord, nst-inv, nst-whs,
    nst-apr, nst-vnd — every entity from Document 2's शिवसूत्र — descends
    from here and ONLY from here.

    proc.pravesh, proc.yojana, proc.kraya, proc.purti, proc.vitta, proc.kara,
    proc.shasana, proc.bhandara generic methods NEVER specialize on anything
    outside this subtree for their primary (entity) argument.

    This class NEVER inherits from BusinessObject (existing hhub-bl-ent.lisp).
    This class NEVER inherits from RequestModel/ResponseModel/ViewModel.
    This is Shiva — inert without the verb (Shakti) that acts upon it."
     "" NIL)
    ("DOMAIN-CTX-SOURCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("WITH-BO-KNOWLEDGE-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
     "" NIL)
    ("NST-LOAD-EMAIL-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DOUPDATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("VIEWCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("UNIVERSAL-TO-UNIX-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DESCRIPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("SHARETEXTORURLONCLICK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-COMPADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("HHUBSENDMAIL-TEST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ACTOR-MESSAGE-COUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("METADATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("INR-TO-WORDS-ANUSTHUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CALL-CONTEXT-READ" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-CURRENCY-HTML-SYMBOLS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("BUSINESSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WITH-ENTITY-UPDATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-POLICY-CREATE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CHECK-NIYAM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("HHUB-REGISTER-BUSINESS-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("WITH-ENTITY-READ" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("%LOG-CRUD-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Append a structured DB error to the business-functions log file." "" NIL)
    ("COM-HHUB-ATTRIBUTE-CUST-EDIT-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("ATTR-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-PRODCATG-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("LLM-GENERATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Unified generation dispatcher. Supports real-time REPL stream echo
   via the :stream T parameter for local Ollama models."
     "" NIL)
    ("CREATEMODELFORTRANSACTIONTOPOLICYLINKPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("OPERATION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GETBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Searches the business context by name" "" NIL)
    ("GENERATE-ENTITY-TLA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generate a unique 3-letter acronym (TLA) from an entity name like 'order header'."
     "" NIL)
    ("BUSTRANS-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("SUBMITSEARCHFORM2EVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Generate JS for second search with redundancy prevention" "" NIL)
    ("WITH-HTML-DROPDOWN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-DATE-STRING-MYSQL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD-MM-YYYY format." "" NIL)
    ("WITH-MVC-REDIRECT-UI" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ENUMERATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "दर्शन प्रत्यय — list within tenant scope. नियम-1 applies to the
    SCOPE filter here (WHERE tenant_id = ctx.tenant), not to each
    returned row individually — the row-level check is redundant
    once the query itself is tenant-scoped correctly."
     "" NIL)
    ("ACTOR-ROLE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("SUBMITFILEUPLOADEVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOCREATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("TODAY-LOG-FILE-PATH" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp" "" "" NIL)
    ("UNSAFE-SQL-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("MAKE-BO-KNOWLEDGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Create a bo-knowledge instance. PROVENANCE may be a single value or a list."
     "" NIL)
    ("WITH-ENTITY-CREATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("TRANSACTION-TYPE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("SELECT-ALL-INDIA-PINCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp" "" "" NIL)
    ("BUSOBJ-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("REFACTORING-NEXT-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Step prompt for the refactoring pipeline: pins :target and applies pressure."
     "" NIL)
    ("DOD-CONTROLLER-PASSWORD-RESET-MAIL-LINK-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ACTOR-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("USER-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("ROUTE-ACTIVE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-ROLES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("PERSIST-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("BUSINESSOBJECTREPOSITORY" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("REFACTOR-LIVE-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Drives the multi-tool refactoring agent loop for FUNCTION-SYMBOL via DeepSeek.

   :max-steps  — step budget (default 10; raise for complex functions)
   :hint       — optional developer guidance injected into the first prompt.
   :model      — provider target string (default \"deepseek\").

   Examples:
     (refactor-live-function 'apply-file-refactor-and-load)
     (refactor-live-function 'llm-generate
                             :hint \"unify the deepseek and ollama branches\")
     (refactor-live-function 'create-model-for-updatewarehouse :max-steps 10
                             :hint \"extract hunchentoot:parameter collection into a helper\")

   Time gate: on WEEKENDS (Sat/Sun IST) this always runs. On weekdays it is
   blocked outside the DeepSeek off-peak windows (09:30-11:30 / 15:30-06:30 IST).
   Returns the refactored defun string on success, NIL on failure."
     "" NIL)
    ("HHUB-ABAC-URI-MISSING-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when the transaction exists but has no URI registered in the DB."
     "" NIL)
    ("GET-USER-ROLES.ROLE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("REPORT-META-COVERAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Prints a simple coverage report after generation." "" NIL)
    ("KAARAKA-REF-ENTITY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("WITH-NST-DEBUGGER" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Debugger-centric NST execution boundary.
     - Development  : drop into debugger (full SLIME stack)
     - Staging      : log full stacktrace + re-signal
     - Production   : log sanitized + signal business condition"
     "" NIL)
    ("ERROR-VALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-ORDER-CANCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("MIGRATE-2025JUN-DOD-ORDER-SCHEMA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("DOD-CONTROLLER-ADD-TRANSACTION-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("HHUB-JSON-BODY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("AUTH-POLICY-ID-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp"
     "Return the ROW_ID of the LIVE policy named NAME, or NIL." "" NIL)
    ("MAKE-REQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Create requestmodel instance for a route from ctx-requestmodel-params."
     "" NIL)
    ("WITH-STANDARD-PAGE-TEMPLATE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CONFLODIS2-ACTOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "कर्ता — the agent performing the action (user object or role name)." ""
     NIL)
    ("FIND-PINCODE-DETAILS-FROM-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp" "" "" NIL)
    ("GET-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("ROUTE-VERSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("WITH-HTML-EMAIL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-SYSTEM-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("LOCATE-SOURCE-VIA-SWANK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Leverages SLIME's backend to programmatically find a symbol's definition source.
   Returns (values file-path character-position) or (values nil nil)."
     "" NIL)
    ("%GIT-OBJECT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Returns the git object id of FILE-PATH's current on-disk content, or NIL when
   the file is not tracked or git is unavailable. Recorded in the backup so a
   restore is a single `git show` even if the backup itself is later lost."
     "" NIL)
    ("BUSINESSSESSIONS-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("BUSINESSCONTEXTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("ROUTE-PING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Diagnostic action verb: proves the two-tier path is wired." "" NIL)
    ("BO-MERGE*" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Merge multiple bo-knowledge objects (fold left using bo-merge)." "" NIL)
    ("INIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Set the domain object of the ResponseModel " "" NIL)
    ("WRITE-FINAL-LOOKUP-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Writes collected and merged symbol data.
   Entry format: (NAME TYPE FILE DOC KEYWORDS META-PLIST)"
     "" NIL)
    ("COM-HHUB-ATTRIBUTE-CUSTOMER-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("GET-SYMBOL-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Determines the type of the given symbol S." "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-FLATRATESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("MERGE-KNOWLEDGE*" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("ALIST-GET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Gets value from ALIST by KEY using case-insensitive string comparison."
     "" NIL)
    ("WITH-DB-DELETE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "SOFT-DELETE boundary macro for CLSQL via DBAdapterService.db-delete.

   db-delete (inherited from DBAdapterService) sets DELETED_STATE to
   'Y' on the dbobject and calls clsql:update-record-from-slot.
   No hard DELETE is ever issued against the database.

   Caller responsibilities BEFORE this macro:
     1. (setcompany dbas company)   ; set tenant context
     2. Ensure dbobject is loaded   ; db-delete needs a populated dbobject

   PRE-FLIGHT (strongly recommended) — a CLSQL SELECT expression that
   returns a list of LIVE rows (DELETED_STATE = 'N') matching the delete
   target.  Drives :F and :C detection.

   ALLOW-IDEMPOTENT (default NIL) — when T, a pre-flight returning 0
   live rows is promoted to :T with payload :already-absent.  Use for
   cleanup jobs and token-expiry flows where you only assert 'this
   record must not be live', not 'I must be the one who deleted it'.

   Returns a BO-KNOWLEDGE instance.  Use WITH-BO-KNOWLEDGE-CHECK to
   branch on the result.  BODY is unused and reserved for future use."
     "" NIL)
    ("BUS-TRANSACTION-INSERTED-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp"
     "Non-nil if a live (not soft-deleted) transaction with NAME exists." ""
     NIL)
    ("HHUB-ABAC-TRANSACTION-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when the PEP cannot find the named transaction in the cache." ""
     NIL)
    ("EXCEPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("TAGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("BO-MERGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Merge two bo-knowledge instances under Belnap knowledge ordering." "" NIL)
    ("APPLY-MIGRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("DELETEBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes the BusinessObject from the BusinessObjectRepository" "" NIL)
    ("HHUB-GET-CACHED-TRANSACTIONS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("GET-BUS-OBJ-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("WITH-NST-DB-CREATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "INSERT boundary macro, no DBAdapterService holder. BODY performs
   the raw CLSQL write and must return the dbobj as its last form —
   caller does the row-id copy-back (bind-generated-row-id), not
   this macro. :T=success/payload=dbobj. :F=confirmed DB-level
   constraint rejection (row never written). :U=any other error,
   logged. :C=optional caller-supplied PRE-FLIGHT form found rows
   (stale-cache race, short-circuits before BODY ever runs)."
     "" NIL)
    ("HTML-BACK-BUTTON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-12" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COPY-HASH-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("NST-API-INTERNAL-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("URI-PREFIX-BOUNDARY-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-TEXTAREA" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("TEST-DOMAIN-ENTITY-NEVER-INHERITS-BOUNDARY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Structural check: nst-domain-entity subtree and nst-boundary-object
   subtree must never intersect below standard-object."
     "" NIL)
    ("PERSIST-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("GET-DATE-FROM-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WITH-ENTITY-READALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("NST-LOAD-CUSTOMER-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("SELECT-AUTH-POLICY-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("WITH-DB-READ-ALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "SELECT-many boundary macro for CLSQL via DBAdapterService.db-fetch-all.

   PK-EXTRACTOR (optional) — a one-arg function (lambda (bo) ...) that
   returns the primary-key value for a row in the result list.  When
   supplied, the list is scanned for duplicates; any duplicate promotes
   status to :C.

   Returns a BO-KNOWLEDGE instance.  Payload on :T is the list returned
   by db-fetch-all (typically a list of CLSQL view-class instances)."
     "" NIL)
    ("CONSTRAINT-MESSAGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("GETBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Get the business session" "" NIL)
    ("GET-AUTH-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("GENERATE-SKU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generate an SKU from product information by taking 2 chars from each word.
  
  Arguments:
  - PRODUCT-NAME: String (e.g., \"Organic Apples\")
  - DESCRIPTION: String or NIL (e.g., \"Red Delicious\")
  - QTY-PER-UNIT: Number (e.g., 1, 100, 2.5)
  - UNIT-OF-MEASURE: String (e.g., \"KG\", \"G\", \"L\")
  
  Returns:
  - A generated SKU string in format NN-DD-QTY-UOM-RANDOM
    Where NN is from product name words, DD from description words
  "
     "" NIL)
    ("GET-SYSTEM-BUS-OBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("HHUB-WEBPUSH-SUBSCRIPTION-EXISTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("PRESENTER-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("RESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("NL-TO-SQL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("LAZY" "MACRO" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" "" NIL)
    ("WITH-HTML-DIV-ROW-FLUID" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DB-CONSTRAINT-VIOLATION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Signal this (or a subclass) from your DB adapter when a constraint
    violation occurs (duplicate key, NOT NULL, FK violation, check
    constraint, etc.).  with-db-create will map this to :F."
     "" NIL)
    ("DB-SAVE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Savte the domianobject to the database" "" NIL)
    ("KNOWLEDGE-JOIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Combines knowledge states from two sources (union of knowledge)." "" NIL)
    ("DOD-AUTH-POLICY" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("TEST-EXTRACT-DOMAIN-INITARGS-STRIPS-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "[LEGAL/SECURITY] A client-supplied :tenant-id in rm.params must
   NEVER survive into the returned initargs. This is the नियम-1 bypass
   this function exists to close — test it explicitly, not incidentally.
   STUB: build rm with params containing (:tenant-id 99 :wname \"X\"),
   call extract-domain-initargs, assert :tenant-id absent from result,
   assert :wname present."
     "" NIL)
    ("ROUTE-AUDIT-LEVEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("ROUTE-TENANT-OVERRIDES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-ADD-PRODUCT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("EXTRACT-DOMAIN-INITARGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Reads rm's params (a plist), filters against entity-class's own
    declared initargs via CLOS MOP introspection, and returns ONLY the
    initargs entity-class actually declares, MINUS *reserved-initargs*.

    MOP-driven deliberately: no per-entity mapping function is hand-
    written anywhere. A new entity (nst-pr, nst-rfq, whatever comes
    after Warehouse) needs ZERO changes to this function — it works
    for any nst-domain-entity subclass the moment the class exists.

    This function IS where लोप actually happens: rm's transport-shaped
    params go in, a plain initargs plist matching the domain class's
    own slots comes out. rm itself is discarded by the caller
    immediately after this returns."
     "" NIL)
    ("WITH-NST-ERROR-HANDLER" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("DELETE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-6" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CALL-CONTEXT-DELETE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("MY-AND" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("CREATERESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a responsemodel from businessobject" "" NIL)
    ("COM-HHUB-POLICY-CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-BULK-PRODUCT-COUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SADMIN-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("MIGRATE-2025SEP-ORDERITEM-UPGRADE-SGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("TEST-FERRY-DISCARDS-REQUEST-MODEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "request->dispatch must not retain rm beyond the call.
   STUB: use a weak-pointer or manual GC check to confirm rm is
   collectible immediately after request->dispatch returns."
     "" NIL)
    ("APPLY-FILE-REFACTOR-AND-LOAD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Validated, reversible splice of FUNCTION-SYMBOL's definition in FILE-PATH.

   Order of operations — the on-disk source is never the first thing to break:
     1. validate  NEW-CODE-STRING actually defines FUNCTION-SYMBOL
     2. locate    every top-level (defun FUNCTION-SYMBOL ...) in the file
     3. guard     the argument list against the one on disk (see below)
     4. back up   the original to FILE~YYYYMMDD-HHMMSS
     5. write     the spliced source
     6. compile   the written file to a temporary .fasl
     7. roll back to the backup if compilation failed, then return FAILURE
     8. load      the verified .fasl and confirm the symbol is fbound

   :allow-signature-change — skip the argument-list guard, for intentional
      interface changes. Default NIL: required, optional, rest and keyword
      arguments must match the disk source exactly, because every caller in the
      project was compiled against the old signature. Redefining a function to
      return a DIFFERENT SHAPE usually does not need this flag — the lambda list
      (parameter structure) need not change to change the return value.
   :want-backup — set NIL to skip the backup copy. Not recommended.

   Returns a SUCCESS/FAILURE string; FAILURE leaves both the file and the running
   image as they were."
     "" NIL)
    ("HHUB-CONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when multiple inconsistent results were found." "" NIL)
    ("COUNTER-BEHAVIOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("EXECUTE-AGENT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Maps an alist structural command format from the agent directly to execution routines.
   Kept alongside dispatch-tool for use by run-autonomous-task."
     "" NIL)
    ("NST-API-TIMEOUT-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("WITH-HHUB-TRANSACTION" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Policy Enforcement Point. If permission granted and URI matches, evaluate BODY.
     Otherwise, redirect and abort the request.
     URI anomalies raise hhub-abac-uri-* conditions; they are caught here and
     converted into a permission-denied redirect (fail-closed deny), so this
     macro never returns normally on a deny."
     "" NIL)
    ("COM-HHUB-POLICY-SEARCH-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("ACTOR-PRIORITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("IST-VALID-CODING-TIME-P" "FUNCTION" "nst-bl-ollama.lisp"
     "Predicate: returns T when the refactoring agent may run.

     Weekends (Saturday and Sunday, IST): always allowed — no window check.
     Weekdays: only inside a DeepSeek off-peak window.
       Window 1: 09:30 – 11:30 IST
       Window 2: 15:30 – 06:30 IST (crosses midnight)

   The argument is a UNIVERSAL-TIME integer (UTC). The weekday is therefore
   derived from the IST-shifted time, not from the UTC time — at 20:00 UTC on
   Friday it is already Saturday in IST, and the weekend rule must apply.

   Note: DECODE-UNIVERSAL-TIME numbers the weekdays 0=Monday .. 6=Sunday, so
   Saturday is 5 and Sunday is 6. The comparison must be against numbers."
     "" NIL)
    ("COM-HHUB-POLICY-CAD-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DOMAIN-CTX-CHANNEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("ROUTE-CHANNEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("AGENT-PREVIEW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Head-truncates STRING to WIDTH with an ellipsis, for progress echo." ""
     NIL)
    ("ADDBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a new BusinessObjectRepository and returns the instance" "" NIL)
    ("ENCRYPT" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("WITH-HTML-DIV-ROW" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("TEST-NIYAM-FIRES-ON-DOMAIN-ENTITY-NOT-BOUNDARY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "check-niyam :before must apply to nst-whs (domain) and must NOT
   have an applicable method for nst-view-model (boundary)."
     "" NIL)
    ("CREATECIPHERSALT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("HHUB-METHOD-NOT-FOUND" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("DOD-INDIA-PINCODES" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-dal-pincodes.lisp" "" "" NIL)
    ("RM-UNKNOWN-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-INVOICE-PAID-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DECRYPT" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("NST-ACTOR" "CLASS" "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp"
     "Class representing an actor with message queue and behavior." "" NIL)
    ("MODAL-DIALOG" "MACRO" "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "" "" NIL)
    ("%DEFUN-TOKEN-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "T when a case-insensitive \"defun\" token, delimited on both sides, begins at
   POSITION in STRING."
     "" NIL)
    ("GENERATE-LISP-FILENAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generates the Lisp file name like nst-dal-odt.lisp from 'order details' and 'dal'."
     "" NIL)
    ("CALL-CONTEXT-READALL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("WITH-NON-NULL-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "A specialized version of WITH-BOUNDARY-CHECK for deterministic null checks.
   If the value-form is non-NIL (Status :T), the BODY is executed with the value 
   bound to the variable PAYLOAD.
   If the value-form is NIL (Status :F), the macro returns an explicit :VALUE-MISSING 
   signal immediately."
     "" NIL)
    ("MAKE-OTP-STORE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp" "" "" NIL)
    ("MEMOIZEKEYFUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/memoize.lisp" "" "" NIL)
    ("UI-LIST-POLICIES-FOR-LINKING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("LAZY-NIL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("PRINT-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Do Service implementation for a Business Service. Takes in the BusinessSession and input params and returns back output params and exceptions if any."
     "" NIL)
    ("GET-BUS-TRAN-POLICY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("HASHCALCULATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("GET-PROJECT-PACKAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Returns a list containing the single main package for the :NSTORES system, 
   based on the packages.lisp file."
     "" NIL)
    ("BO-SAFE-PAYLOAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return payload only when truth is :T; otherwise NIL." "" NIL)
    ("COM-HHUB-POLICY-VENDOR-ORDER-SETFULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CURRENT-DATE-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY-MM-DD format" "" NIL)
    ("DISPATCH-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Dispatch a route with optional request metadata for ABAC/auditing.
   
   Parameters:
     route-key       - Route identifier (e.g., :warehouse/create)
     raw-params      - Request model parameters
     trans-func-name - Transaction function name for auditing
     output-type     - Output format (json, html, etc.)
     request-uri     - Optional request URI (auto-detected from Hunchentoot if nil)"
     "" NIL)
    ("DOD-CONTROLLER-TRANS-TO-POLICY-LINK-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-ABAC-SUBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("WITH-VEND-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("RESTORE-DELETED-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("HHUB-GEN-GLOBALLY-CACHED-LISTS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("ACTOR-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-ROLE-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("GET-TIME-STRING-FROM-DATEOBJ" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current time  as a string in HH:MM:SS  format" "" NIL)
    ("TENANT-OVERRIDES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("DISPATCH-ROUTE2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "THE ENTRY POINT. Ring-3 inbound action → Ring-2/3 action verb → Ring-1 verbs.

   ROUTE-KEY        a route-* symbol, e.g. 'ROUTE-ORDER
   RAW-PARAMS       the inbound payload (a plist) — carries ALL params, for all
                    entities the action needs. Never carries a trusted tenant.
   TRANS-FUNC-NAME  audit/ABAC transaction name (used by the transaction seam)
   OUTPUT-TYPE      :json / :html (defaults to the route's own)
   REQUEST-URI      kept for boundary/audit compatibility
   RAW              return response model(s) instead of rendered output"
     "" NIL)
    ("BUSINESS-OBJECTS-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("HHUB-ABAC-URI-ABSENT-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when the request params carry no \"uri\" key (caller defect)." ""
     NIL)
    ("HHUB-BUSINESS-FUNCTION-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-GST-HSN-CODES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("ATTR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" ""
     "" NIL)
    ("ENTITY-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("URI-PREFIX-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("RETURN-JSON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CREATE-DOMAIN-ENTITY-FROM-TEMPLATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generates domain code for UI, BL, and DAL by replacing placeholders in templates."
     "" NIL)
    ("HHUB-REGISTER-NETWORK-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DEEPSEEK-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Determines if the requested model belongs to the DeepSeek platform ecosystem."
     "" NIL)
    ("SESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DOD-CONTROLLER-POLICY-SEARCH-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("FETCH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "स्मरण प्रत्यय — recall by identity. Returns either a real entity
    instance or an nst-entity-nil/nst-entity-unknown/nst-entity-
    contradiction sentinel (Section 1) — never a bare CL nil, so
    callers always have a Belnap-inspectable domain object back."
     "" NIL)
    ("GENERATE-SKU-ANUSTHUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("RESPONSEMODELUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("GENERATEHASHKEY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("NST-LOAD-WAREHOUSE-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("MASK-OTP" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp"
     "" "" NIL)
    ("WITH-STANDARD-COMPADMIN-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DISPLAYSTOREPICKUPWIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("LOGIAMHERE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("GETBUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "gets the domain object" "" NIL)
    ("NST-GENERIC-LOGIN-WITH-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HAS-PERMISSION1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("WITH-STANDARD-VENDOR-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-ABAC-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for all ABAC Policy Enforcement Point failures." "" NIL)
    ("RESPONSEMODELCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WITH-CUSTOMER-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("TABLE-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("PROCESSCREATEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Create method" "" NIL)
    ("REFRESHIAMSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("EXTRACT-HTML-BETWEEN-MARKETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-ABAC-URI-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for URI verification failures in the PEP." "" NIL)
    ("SELECT-BUS-TRANS-BY-TRANS-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("GENERATE-BRANCH-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generate a validated Git branch name: scope/type/id-desc." "" NIL)
    ("WITH-HTML-DIV-COL-10" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DB-FETCH-ALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch records by company" "" NIL)
    ("DELETE-AUTH-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("KAARAKA-REF-ENTITY-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-PRDBULKUPLOAD-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("DOMAIN-CTX-ACTOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("GET-APPLIED-MIGRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("DISPLAY-AS-TILES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("KNOWLEDGE-MEET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Intersection of knowledge (common certainty)." "" NIL)
    ("REGISTER-ACTION-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Register (or replace) an action route. Returns ROUTE-KEY.
   ACTION-VERB defaults to ROUTE-KEY itself, so the common case is a one-liner:
     (register-action-route 'route-order)"
     "" NIL)
    ("GET-UNIVERSAL-TIME-FROM-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("MEMOIZE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Replace fn-name's global definition with a memoized version." "" NIL)
    ("CURRENT-DATE-STRING-DDMMYYYY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD-MM-YYYY format" "" NIL)
    ("WITH-CUST-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("INITBUSINESSCONTEXTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp"
     "This generic function will initialize the business contexts for the business server"
     "" NIL)
    ("COM-HHUB-POLICY-CUSTOMER&VENDOR-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("START-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("CREATEVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Converts the ResponseModel to ViewModel" "" NIL)
    ("LIST-CALLERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Lists all functions that call FUNCTION-NAME across the loaded image.
   High caller count means interface changes carry proportional risk — call before any signature modification."
     "" NIL)
    ("VERSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("RESOLVE-VIEW-FOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("COLUMN-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("VM-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("CONFLODIS2-LOGIN-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "The acting login company OBJECT (vendor → customer → user role track).
   Returns nil outside a logged-in session."
     "" NIL)
    ("RESTORE-DELETED-RESET-PASSWORD-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("WITH-HTML-SUBMIT-BUTTON" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ACTOR-STATEFUL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("CREATE-DIGEST-SHA1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("GET-SYSTEM-CURRENCIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("ATTRINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("SUBMITSEARCHFORM1EVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Generate JS for second search with redundancy prevention" "" NIL)
    ("WITH-STANDARD-CUSTOMER-PAGE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-MAX-OF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("INIT-GST-INVOICE-TERMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("ACTOR-CONDITION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("QLISP" "MACRO" "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Surgical REPL prompter interface. Captures raw Common Lisp forms without
   requiring manual text quote wrapping or escaping nested string tokens."
     "" NIL)
    ("NST-VIEW-MODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Presentation-ready shape — HTML/JSON rendering input." "" NIL)
    ("NST-ENTITY-NIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Belnap :F sentinel. A domain fact: this entity does not exist." "" NIL)
    ("MAKE-INR-MANTRA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("LAZY-MAPCAR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "" NIL)
    ("GET-SYSTEM-BUS-TRANSACTIONS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("DOD-ROLES" "CLASS" "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp"
     "" "" NIL)
    ("ACTOR-THREAD-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("AUTH-POLICY-INSERTED-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp"
     "Non-nil if a live (not soft-deleted) policy with NAME exists." "" NIL)
    ("WHATSAPP-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("!UPDATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "!state प्रत्यय — entity is an EXISTING instance here, not a class
    symbol. GUARDRAIL 2 still holds: entity first, ctx before &rest."
     "" NIL)
    ("LOG-CRITICAL-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Logs a critical error, automatically including the function that initiated the DB call."
     "" NIL)
    ("DELETE-AUTH-POLICIE-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("REFACTORING-RESULT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("DOD-CONTROLLER-INVALID-EMAIL-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DISPLAY-AS-TILES-OR-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Render LISTDATA as tiles (MODE \"tile\") or as a table (MODE \"table\") so
callers can offer one dataset in both layouts. TILE-DISPLAY-FUNC renders one
tile, TILE-CSS-CLASS sizes it inside the all-products flex container, and the
table view is built by display-as-table using TABLE-HEADER and
ROW-DISPLAY-FUNC (ROW-ARGS are passed through). Returns the HTML string."
     "" NIL)
    ("NEW-TRANSACTION-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-UPDATE-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-RESET-PASSWORD-INSTANCE-BY-TOKEN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("UPDATE-USER-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("CREATE-USER-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("ROUTE-FEATURE-FLAGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("FOREIGN-KEY-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("ABAC-SUBJECT-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-CUSTOMER-ORDER-CUTOFF-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("ROUTE-PERMISSION-CHECKER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("NST-ENTITY-CONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Belnap :C sentinel. Two sources disagree — human review required." "" NIL)
    ("TEST-REQUESTMODEL-REJECTED-BY-DOMAIN-VERB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Any proc.GANA verb called with an nst-request-model as first arg
   must signal no-applicable-method — not silently succeed."
     "" NIL)
    ("NST-LOAD-CORE-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("WITH-HHUB-PEP" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-STOREPICKUP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("GET-BUS-OBJECT-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("UPDATED-AT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("DELETE-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-RESTORE-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-CIPHER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("GET-SOURCE-CODE-REFLECTIVE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Reflectively pulls the complete raw source code of FUNCTION-SYMBOL using Swank."
     "" NIL)
    ("WITH-DB-CALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("TEST-COMPLETE-IMMUNITY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Walks every domain package's exported generic functions.
   FAILS if any method specializer is nst-boundary-object or a subclass.
   Run this in CI after every commit touching proc.* packages."
     "" NIL)
    ("DOD-SET-VIEW-MODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Persist MODE (\"tile\" or \"table\") for SESSION-KEY. Invalid modes fall
back to \"tile\"."
     "" NIL)
    ("DELETE-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-UPDATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("HHUB-READ-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("HTMLVIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "" NIL)
    ("DOD-CONTROLLER-NEW-COMPANY-REGISTRATION-EMAIL-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-SYMBOL-DOC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Retrieves the documentation string for symbol S based on its determined TYPE."
     "" NIL)
    ("JSCRIPT-DISPLAYERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("MIGRATE-2025MAY-ADD-PRODUCT-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("DELETED-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("ROUTE-KEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("NST-LOAD-INVOICE-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("MIGRATE-2025AUG-ORDERITEM-UPGRADE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("CREATED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("TEST-CTX-IS-STRUCT-NOT-DISPATCHABLE-CLASS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "domain-ctx must remain a struct — never converted to a CLOS class
   that could accidentally become a dispatch target for the entity
   position in a proc.GANA verb signature."
     "" NIL)
    ("NST-VIEW-NIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("WITH-CATCH-SUBMIT-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CTX-PRESENTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("SELECT-AUTH-POLICY-ATTR-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("MAKE-UI-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "Create a component.
NAME is a keyword identifier.
RENDERER-FN is a function that takes MODELFUNC and returns a list of widgets."
     "" NIL)
    ("GET-HT-VALUES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-UPDATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-CURRENTPRODCATGCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("TAKE-ALL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("CASE-TRUTH" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "A specialized CASE macro for logic values." "" NIL)
    ("DODELETE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("BO-ADD-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return a new bo-knowledge with SOURCE added to provenance (non-destructive)."
     "" NIL)
    ("PARSE-DATE-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a date string of the form \"YYYY-MM-DD\" and return the 
corresponding universal time."
     "" NIL)
    ("COM-HHUB-POLICY-CREATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("MERGE-KNOWLEDGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Merges two boundary results of the form (STATUS PAYLOAD)
   according to Belnap knowledge ordering.
   Returns a new (STATUS PAYLOAD) pair."
     "" NIL)
    ("WITH-COMPADMIN-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("TEST-GANA-PACKAGE-FOR-ERRORS-ON-UNREGISTERED-VERB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "An unregistered verb symbol must signal a clear error, not return
   nil and let the ferry fail three lines later with a confusing
   find-symbol-on-nil error.
   STUB: (gana-package-for 'not-a-real-verb) → error, not nil."
     "" NIL)
    ("WITH-HTML-INPUT-PASSWORD" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-ROLE-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("MAKE-KAARAKA-REF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("COPY-DBOBJECT-TO-BUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Syncs the DBobject to BusinessObject" "" NIL)
    ("BOREPOSITORIES-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SHOW-INVOICES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("RESPONSEMODELNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("INITBUSINESSSERVICES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Initialise the Business Services" "" NIL)
    ("FORCE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" ""
     NIL)
    ("RENDERHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Takes the viewmodel and converts into HTML" "" NIL)
    ("VIEWMODELUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CTX-TRANS-FUNC-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("INSERT-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp"
     "Insert a policy row unless one with NAME already exists.
   Returns the policy ROW_ID (existing or freshly inserted)."
     "" NIL)
    ("PERSIST-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("SELECT-AUTH-POLICY-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DEFAULT-NEXT-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Task-agnostic step prompt: state the target, what has been tried, and the
   last observation. Works for any tool-using objective."
     "" NIL)
    ("GET-BUS-TRAN-ABAC-SUBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("SELECT-BUS-TRANS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("VIEWNIL" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "" NIL)
    ("GETRESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("MYSQL-NOW" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("COM-HHUB-POLICY-READ-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PROCESSRESPONSE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for converting the business object into a responsemodel "
     "" NIL)
    ("DOD-BUS-OBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CREATE-RESPONSE-FROM-DOMAIN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Polymorphic response creation" "" NIL)
    ("BUSINESSOBJECTCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-FREESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("NST-LOAD-VENDOR-TABLES-STRUCTURE-FOR-AGENTIC-AI" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("UPDATE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("PROCESSREADREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Read method" "" NIL)
    ("RENDER-JSON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Post-ferry outbound encoding, JSON. response dispatches the method:
    a single nst-boundary-object (or its subclass), a LIST of them, or a
    response-model Belnap sentinel. Returns the JSON text (a string).
    Multiple dispatch: response carries BOTH cardinality and entity type;
    CLOS resolves both — no if/else over types in method bodies."
     "" NIL)
    ("BO-MERGE-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return merged provenance list (deduped)" "" NIL)
    ("DELETEBUSINESSSERVER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("WITH-STANDARD-VENDOR-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DISPLAY-SEARCH-RESULTS-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-HTML-SEARCH-FORM" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("BUSINESSSESSION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CRUD-OP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GET-ALL-INDIA-PINCODES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp"
     "Returns a hash table where each pincode is a unique key, 
   ignoring sub-office distinctions."
     "" NIL)
    ("NST-LOAD-ORDER-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("MERGE-PAYLOADS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Merge two payloads intelligently.
   If both are equal, return one.
   If one is NIL, return the other.
   If they differ, return a list of both to mark conflict."
     "" NIL)
    ("TOKEN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-TEXT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DELETEBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes the business session on a given key" "" NIL)
    ("ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("DOD-PASSWORD-RESET" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("WITH-BOUNDARY-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
     "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-MAXPRODUCTCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("SELECT-AUTH-POLICY-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("REGISTER-OUTBOUND-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Registers an outbound adapter route in *outbound-route-registry*.

Arguments:
  route-key                 - Required keyword (e.g. :customer/read)
  crud-op                   - :create :read :update :delete (optional)
  description               - Optional human description
  active                    - Whether route is active (default T)
  default-outbound-adapters - List of default output formats (e.g. '(json))
  adapter-selector          - Function(route ctx) -> list of output formats
  tags                      - Arbitrary tagging info
  version                   - Version number
  metadata                  - Extensible alist for future fields

Returns:
  The created outbound-adapter-route object."
     "" NIL)
    ("ACTION->RESPONSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Reverse boundary: domain result → nst-response-model (or a list of them).
   Accepts a single entity, a LIST (enumerate/assembly), a Belnap domain
   sentinel, or a ready-made response model (pass-through)."
     "" NIL)
    ("ABAC-DB-URI" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("LOAD-OLD-DATA-AND-KEYWORDS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Loads existing lookup data and returns a hash table mapping symbol 
   names to (keywords . meta-plist) — preserving both old slots."
     "" NIL)
    ("CALL-CONTEXT-UPDATE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("RENDERJSONALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders a list as JSON" "" NIL)
    ("REQUIRED-ROLES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("LIST-CALLEES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Lists all functions called BY FUNCTION-NAME.
   Reveals dependencies, heavy or redundant calls, and consolidation opportunities."
     "" NIL)
    ("ACTION-ROUTE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "An ACTION ROUTE. Entity-agnostic by construction: it names the action verb
    (route-*), not a business object. Multi-entity assembly happens INSIDE the
    action verb via several Tier-1 ferries."
     "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-ISSUSPENDED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CAD-PRODUCT-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("POLICY-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DISPLAY-COMPADMIN-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ADAPTER-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("NST-VIEW-UNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("GETBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Get the Business object repository" "" NIL)
    ("WITH-VENDOR-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("PROCESSREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for initializaing the BusinessService and calling its doService method. It then creates an instance of outboundwebservice"
     "" NIL)
    ("READ-SOURCE-FROM-SWANK-LOCATION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Reads the complete S-expression form from FILE-PATH starting at Swank POSITION."
     "" NIL)
    ("COM-HHUB-POLICY-SHOW-INVOICE-PAYMENT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("EMIT-AUDIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SADMIN-CREATE-USERS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GENERATEPDF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SEARCH-GST-HSN-CODES-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WITH-STANDARD-PAGE-TEMPLATE-WITH-SIDEBAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("SELECT-ROLE-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("AVERAGE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("SAFE-NL-TO-SQL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("MAKE-ACTION-DOMAIN-CTX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Build the कारक passenger for an action dispatch.
   कर्म is NOT here — it is the action verb's own argument (Guardrail 2).
   संप्रदान/अपादान are read from the payload when the action is directed at /
   drawn from another party; they are NOT tenant-scoped by नियम-1."
     "" NIL)
    ("BO-KNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("FUNCTION-LOOKUP-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-funloodat.lisp" "" "" NIL)
    ("COUNT-SOURCE-COMPLEXITY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Measures structural complexity of FUNCTION-NAME: total cons form count, maximum nesting depth,
   and let-binding block count. Use to calibrate how aggressively to decompose into helpers."
     "" NIL)
    ("UPDATE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("GET-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CTX-REQUEST-URI" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("ACTIVE-FLG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("BUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WITH-STANDARD-CUSTOMER-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("BUSINESSOBJECT-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CREATE-VIEWMODEL-FROM-RESPONSE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Polymorphic viewmodel creation - only for READ operations" "" NIL)
    ("HHUB-GET-CACHED-GST-SAC-CODES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("COPY-DOMAIN-CTX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-CUST-ORDER-PAYMENT-MODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("DOD-CONTROLLER-TRANS-TO-POLICY-LINK-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("USER-ROLES-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-WALLETS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("UNIX-TO-UNIVERSAL-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DB-DELETE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Delete the dbobject in the database" "" NIL)
    ("SEND-MESSAGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("CREATEWIDGETSFORTRANSACTIONTOPOLICYLINKPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("TRANSFERKNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Transfer BO knowledge from one adapter-layer object to another." "" NIL)
    ("WITH-STANDARD-VENDOR-PAGE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("INDEX-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CONFLODIS2-HTML-FRAGMENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "One render-html RESULT → one fragment. NIL means the method WROTE directly
   to *standard-output* (e.g. display-warehouse-row in nst-ui-warehouse.lisp)
   and has nothing to return — PRINCing that NIL into the output would emit the
   four letters N-I-L as markup."
     "" NIL)
    ("NST-GET-CACHED-VENDOR-TABLES-STRUCTURE-FOR-AGENTIC-AI" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("RENDER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders the viewmodel as View" "" NIL)
    ("ROUTE-DESCRIPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("INIT-GST-STATECODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("BEFORE-DISPATCH-HOOK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("WITH-STANDARD-PAGE-TEMPLATE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("NST-GET-CACHED-VENDOR-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("STOP-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("CREATE-MD5-FROM-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Takes a list of strings, joins them with commas, and returns the MD5 digest."
     "" NIL)
    ("PERSIST-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ATTRIBUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PROCESS-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("%DETECT-DUPLICATE-PKS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Return T if PK-EXTRACTOR applied to ROWS yields any duplicate values." ""
     NIL)
    ("CONVERT-NUMBER-TO-WORDS-USD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("START-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("RUN-ALL-ADHARA-TESTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("CALL-WITH-ACTION-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Default: no wrapper. Replace/bind to integrate ABAC + with-hhub-transaction."
     "" NIL)
    ("MAKE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "सृजन प्रत्यय — crystallizes a new entity instance.
    [LEGAL] Any GSTIN-bearing entity (nst-whs, nst-vnd, ...) MUST run
    a ?exists uniqueness check as a :before method BEFORE construction
    completes — see the nst-whs example below. :U from that check
    MUST abort; only a confirmed :F (not found) permits creation."
     "" NIL)
    ("HHUB-EXECUTE-BUSINESS-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("SELECT-AUTH-ATTR-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("RENDERTILEVIEWHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders a list as tiles" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-SHIPPING-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("GET-DATESTR-FROM-OBJ-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY-MM-DD format." "" NIL)
    ("OUTBOUND-ADAPTER-ROUTE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-ABAC-ATTRIBUTES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("MAKE-CALL-CONTEXT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Create a call context with optional request metadata.
   If request metadata is not provided, attempts to get from Hunchentoot or uses defaults."
     "" NIL)
    ("CURRENT-YEAR-STRING--" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "" NIL)
    ("CLEAR-CHAT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Flushes the local conversation memory frame clean." "" NIL)
    ("ESTIMATE-REFERENCE-COUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Counts occurrences of FUNCTION-NAME across all project source files in the index.
   High count = high blast radius. Use to decide how conservative to be with interface changes."
     "" NIL)
    ("DISPLAY-AS-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-WRITE-FILE-FOR-CSS-INLINING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-GENERICREDIRECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ACTOR-LAST-ACTIVE-AT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("NST-RESPONSE-MODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Domain result reshaped for outbound transport." "" NIL)
    ("WITH-DB-UPDATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "UPDATE boundary macro for CLSQL via DBAdapterService.db-save.

   Caller responsibilities BEFORE this macro:
     1. (init dbas updated-bo)                     ; attach updated BO
     2. (setcompany dbas company)                  ; set tenant context
     3. (copy-businessobject-to-dbobject dbas)     ; flush new values to DB row

   PRE-FLIGHT (strongly recommended) — a CLSQL SELECT expression that
   returns a list of rows matching the update target.  Drives :F and :C
   detection.  Without it, :F cannot be produced because CLSQL does not
   return rows-affected from db-save.

   Returns a BO-KNOWLEDGE instance.  Use WITH-BO-KNOWLEDGE-CHECK to
   branch on the result.  BODY is unused and reserved for future use."
     "" NIL)
    ("ROLE-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("GENERATE-LOOKUP-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp" "" "" NIL)
    ("TENANT-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("GETALLBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch all Business objects from the repository" "" NIL)
    ("GET-TOTAL-OF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DISPLAY-VENDOR-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DELETE-RESET-PASSWORD-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-EXTERNALSHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("WITH-HTML-PANEL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-NST-DB-READ-ALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "BODY returns a list (possibly empty) of dbobjs. :T = non-empty
   list. :F = empty list — a real, expected result (no matches),
   not an error. :C = PK-EXTRACTOR supplied and finds a duplicate
   PK across the returned rows — a data-integrity signal, not a
   query-syntax one; investigate the table, don't just retry.
   :U = any error, logged."
     "" NIL)
    ("READ-SOURCE-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Retrieves the complete live source code of FUNCTION-NAME from the running Lisp image via Swank."
     "" NIL)
    ("GET-SYSTEM-ROLES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("DELETE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("REPLACE-DEFUN-BLOCKS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Returns CONTENT with each (start . end) span in REGIONS replaced by NEW-CODE.
   Every region is rewritten, so a function defined more than once in the file
   cannot be left half-updated."
     "" NIL)
    ("REFACTORING-TARGET" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("GET-USER-ROLES.USER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("GET-VARIABLE-VALUE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Returns the current runtime value of a global variable by name. Call this after list-file-globals reveals a variable the function uses — never assume a variable's structure without reading its value first."
     "" NIL)
    ("GETVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("PROCESSDELETEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Delete method" "" NIL)
    ("MAKE-REFACTORING-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Builds the AGENT-POLICY that turns RUN-AGENT-LOOP into the refactoring agent.
   Fresh per call so :tracked-state does not leak between sessions."
     "" NIL)
    ("DISPATCH-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Run the action verb for ROUTE, then reverse-ferry and render.
   :RAW T returns the response model(s) instead of the rendered string
   (useful for UI/widget callers)."
     "" NIL)
    ("COM-HHUB-POLICY-VENDOR-PROD-SHIP-INFOADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WITH-HTML-CUSTOM-CHECKBOX" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-CURRENCIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DELETE-RESET-PASSWORD-INSTANCES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("DELETE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("BUSINESSCONTEXT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("SETDBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Set the DBObject" ""
     NIL)
    ("EMAIL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("CREATEBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a business session and returns the newly created session" "" NIL)
    ("WITH-HTML-DIV-COL-3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("EXTRACT-FUNCTION-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Pulls the last word/symbol name out of the user prompt string." "" NIL)
    ("BO-KNOWLEDGE-SUMMARY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("INITBUSINESSSERVER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("BUSINESSOBJECTS-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WITH-HTML-ACCORDION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("BO-KNOWN-FALSE-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is known false." "" NIL)
    ("HHUB-LOG-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("GET-CURRENCY-HTML-SYMBOL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SADMIN-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("EXTRACT-ALL-DEFUN-BLOCKS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Scans TEXT for all top-level (defun ...) forms using paren counting.
   Robust to unescaped quotes inside docstrings — works even when the Lisp
   reader fails. Returns a single string with all blocks, or NIL if none found."
     "" NIL)
    ("GET-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD/MM/YYYY format." "" NIL)
    ("CRM-DB-CONNECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("TEST-EXTRACT-DOMAIN-INITARGS-NEEDS-ZERO-CHANGES-FOR-NEW-ENTITY"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Structural test: define a throwaway nst-domain-entity subclass with
   a novel slot, verify extract-domain-initargs handles it correctly
   with NO code changes to extract-domain-initargs itself. This is
   the MOP-driven guarantee — confirm it holds, don't just assert it."
     "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXCUSTOMERCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("NST-LOAD-PRODUCT-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("NST-GET-CACHED-CUSTOMER-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("LINK-BUS-TRANSACTION-TO-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-TEXT-READONLY" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ACTOR-CREATED-AT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-HIDDEN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DEFINE-TOOL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Defines a Lisp function, registers it as an agent tool, and attaches its
   documentation to the symbol plist. Optional CONTENT-ARG enables two-argument
   tools that receive both :target and :content from the agent's alist."
     "" NIL)
    ("PREVIEW-LINE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Head-truncates STRING to WIDTH characters, appending an ellipsis when cut."
     "" NIL)
    ("LAZY-CDR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-CODORDERS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("ATTRIBUTE-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DEFUN-SOURCE-MATCHES-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "T when STRING defines FUNCTION-NAME. Used to reject spliced code that defines
   some other function — the classic way an automated edit silently discards the
   only definition of the target."
     "" NIL)
    ("DOD-BUS-TRANSACTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("SAVE-AND-COMPILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Writes the refactored code for FUNCTION-NAME to its source file and hot-loads it into the running image. Call this as the second-to-last step, immediately before complete. Pass the full refactored (defun ...) block(s) as :content."
     "" NIL)
    ("PARSE-TIME-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("PAISE-TO-RUPEES-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DOMAIN-CTX" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Passenger struct — travels through EVERY proc.GANA and proc.bs call as
   the last argument. Carries context WITHOUT carrying boundary-tree
   baggage across into the domain tree.

   GUARDRAIL 2 anchor: every domain verb signature is (entity ... ctx).
   ctx is always LAST. It is never the entity. It is never dispatched on.

   कारक (kāraka) coverage — six classical semantic roles, five carried
   here; the sixth (कर्म/karma, 'the object acted upon') is deliberately
   NOT a ctx field — it is always the verb's own first argument (the
   entity), per Guardrail 2. Putting karma on ctx would let it drift
   out of dispatch position, which is exactly the discipline Guardrail
   2 exists to prevent.

     actor     — कर्ता (kartā), the agent performing the action
                 (:human/:ai-agent/:scheduled-job + id)
     tenant    — अधिकरण (adhikaraṇa), tenant/company context
     channel   — करण (karaṇa), the instrument
                 (:http/:grpc/:event-bus/:cli/:scheduler)
     recipient — संप्रदान (sampradāna), 'for whom' — who the effect is
                 directed at: an approver being routed to, a vendor
                 being notified, a customer an invoice is issued to.
                 nil, ONE kaaraka-ref, or a LIST of kaaraka-ref for
                 fan-out (e.g. a notification going to several usr).
     source    — अपादान (apādāna), 'from which' — point of origin:
                 the budget funding a pr, the warehouse stock is drawn
                 from, the vendor an RFQ is sourced from. nil or ONE
                 kaaraka-ref.

   PROVENANCE NOTE — do not conflate with bo-knowledge provenance:
     recipient/source here are BUSINESS-SEMANTIC facts about the WORLD
     (which entity is the source/recipient). bo-knowledge provenance
     (BO-ADD-PROVENANCE, BO-MERGE-PROVENANCE — nst-bl-beltrusys.lisp,
     both EXISTING) is an EPISTEMIC fact — which boundary call/system
     told us something, used for Belnap :C conflict-merge tracking.
     Two different layers, same word 'source' in casual English —
     keep them distinct in code and in conversation.

     Composition rule: a recipient/source value MAY have been resolved
     via an uncertain boundary call (e.g. 'which vendor fulfils this
     RFQ' from an external catalog). That call's own bo-knowledge and
     provenance are checked and resolved to :T BEFORE this struct is
     built. domain-ctx NEVER carries a :U-tainted kaaraka-ref — if
     source/recipient resolution comes back :U, ctx construction
     itself must abort rather than proceed with an uncertain value.
     [LEGAL: an uncertain recipient for a GST-relevant notification —
     e.g. self-invoice routing under RCM — is the same class of risk
     as any other :U-on-GST-verb case; abort, do not guess.]

   NIYAM EXEMPTION — recipient/source are NOT covered by नियम-1's
   strict tenant-equality check. A vendor recipient legitimately
   belongs to a DIFFERENT tenant than the acting company — cross-
   tenant reference is the normal case for vnd/quot/rfq kāraka-refs,
   not a violation. नियम-1 continues to apply, unmodified, to the
   VERB'S OWN entity argument only."
     "" NIL)
    ("ROLE-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("SELECT-AUTH-ATTRS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("REQUEST->DISPATCH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "THE FERRY. The only sanctioned crossing from Tree 2 (nst-request-model)
    to Tree 1 (nst-domain-entity subclass).

    request-model DIES here. Its slots are read ONCE to build entity
    initargs. The request-model instance itself is never returned, never
    stored, never passed to any proc.GANA or proc.bs method. Only the
    extracted primitive values survive the crossing — exactly as लोप
    (Document 4) elides an intermediate form that the next operation
    does not need to see directly.

    GUARDRAIL 2: the entity constructed here becomes the FIRST argument
    to whatever proc.GANA verb is dispatched. ctx remains LAST."
     "" NIL)
    ("NST-REQUEST-MODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp"
     "Raw inbound parameters, still shaped by the transport (Layer 2/3
    from the communication-modes discussion). Never touches proc.GANA.
    Consumed entirely by request→dispatch (Section 4) and discarded."
     "" NIL)
    ("ADDBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Reads the params and create a new BusinessObject. Return the newly created BusinessObject"
     "" NIL)
    ("PRINT-THREAD-INFO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("RENDER-UI-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("SUBMITSEARCHFORM3EVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-MVC-BINARY-FILE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("MAX-ITEM" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("NST-RESPONSE-CONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("SELECT-BUS-OBJECT-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("HTMLDATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CALL-CONTEXT-CREATE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("NULL-VALUE-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("ROUTE-REQUEST-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp" "" "" NIL)
    ("WITH-CAD-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("BO-KNOWN-TRUE-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is known true." "" NIL)
    ("LIST-GENERIC-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "If FUNCTION-NAME is a generic function, lists all its methods with their specializers.
   Required reading before refactoring any generic function — changing the primary definition affects all dispatch paths."
     "" NIL)
    ("BO-KNOWLEDGE-FROM-BOUNDARY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Convert boundary-result (list or values) into a bo-knowledge instance.
   boundary-result is expected like (TRUTH PAYLOAD &optional SOURCE ...)."
     "" NIL)
    ("DOMAIN-CTX-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("PARSE-OLLAMA-NDJSON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Parses Ollama's NDJSON stream response. If PRINT-STREAM is T,
   it echoes chunks to the REPL in real-time while accumulating the full text string."
     "" NIL)
    ("RESTORE-DELETED-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("LAZY-MAPCAN" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "" NIL)
    ("SELECT-BUS-TRANS-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("PROCESS-MESSAGES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("GET-BUS-TRAN-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("CTX-DOMAIN-OBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("RESPONSEHASHCHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("PROCESSRESPONSELIST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for converting the business objects into a responsemodel list "
     "" NIL)
    ("FEATURE-FLAGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("UPDATE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CREATE-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Model: Prepares the lookup data for the view.
   Now includes the 6th meta-plist slot serialized as JSON."
     "" NIL)
    ("NST-LOAD-VENDOR-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CREATE-RESET-PASSWORD-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("MIGRATE-2025MAY-ADD-DISCOUNT-COLUMN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("DELETE-THREADS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("BOUNDARY-RESULT->BO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Wrapper around bo-knowledge-from-boundary that normalizes payload provenance if payload is itself a bo-knowledge or plist."
     "" NIL)
    ("ACTOR-THREAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("INIT-HTTPSERVER-WITHSSL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CREATE-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("RM-CONFLICTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("FIND-PINCODE-DETAILS-FROM-DB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp" "" "" NIL)
    ("GET-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("READ-YAML-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a YAML file and return its parsed content." "" NIL)
    ("GET-FUNCTION-ARGLIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Returns the live argument list of FUNCTION-NAME. An empty list means zero arguments — correct and expected for no-arg functions. Do not reinvestigate."
     "" NIL)
    ("PERSIST-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("MAKE-UI-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-HTML-CHECKBOX" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("MAKE-ADAPTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Create adapter instance for route. Override as needed." "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-TABLERATESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-PUBLISH-ACCOUNT-EXTURL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("ROLE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-rol.lisp" "" "" NIL)
    ("CTX-BO-KNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("WITH-STANDARD-COMPADMIN-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("BUILD-PINCODE-CACHE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp"
     "Satisfies Anusthup Chanda: 32 Words" "" NIL)
    ("VENDORSESSIONOBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-BULK-PRODUCTS-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WITH-OPR-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("RENDERLISTVIEWHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Renders a list view"
     "" NIL)
    ("WITH-NO-NAVBAR-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATEWHATSAPPLINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DISPLAY-SUPERADMIN-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-READALL-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("ACTOR-STATE-CLEAN-CALLBACK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("DOD-VIEW-MODE-TOGGLE-LINKS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Return a Bootstrap button-group with Tiles/Table links that switch to
CURRENT-MODE's counterpart. Each link appends VIEW-PARAM=<mode> to BASE-HREF
(the server reads that parameter and persists the choice via
dod-set-view-mode). The active mode is highlighted. Returns the HTML string."
     "" NIL)
    ("SEED-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("MAKE-VIEW" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Returns a view instance for this request." "" NIL)
    ("CONFLODIS2-SESSION-VALUE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Session read that tolerates a non-HTTP caller (REPL/tests) → nil." "" NIL)
    ("KAARAKA-REF-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp" "" "" NIL)
    ("RUN-AGENT-LOOP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp"
     "Objective-driven tool-using agent loop. Carries the control flow only; all
   task-specific behaviour comes from POLICY (see MAKE-REFACTORING-POLICY).

   POLICY is a plist:
     :name              short string used in the session banner
     :system-prompt     system prompt string
     :initial-message   (lambda (target hint) ...) -> first prompt string
     :tracked-state     (lambda (action result state) ...) -> updated state plist.
                        Only needed by policies whose prompt builder wants
                        derived state (the refactoring policy tracks whether a
                        clean source retrieval has happened).
     :next-message      (lambda (target action result context-log completed-tools
                                 steps-left state) ...) -> next prompt string
     :done-p            (lambda (action) ...) -> T when ACTION terminates the run
     :on-complete       (lambda (raw-output action-content) ...) -> final result
     :completion-marker substring searched for in RAW-OUTPUT on the rescue path,
                        used when the alist failed to parse but the model clearly
                        signalled completion in prose
     :completion-signal (lambda (result target) ...) -> condition initargs

   TARGET is (format nil \"~A\" objective), upper-cased.

   Returns the policy's completed result, or NIL when the step budget is
   exhausted or a parse failure cannot be rescued."
     "" NIL)
    ("NST-GET-CACHED-EMAIL-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CONFLODIS2-JSON-OUTPUT-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "True when OUTPUT-TYPE selects JSON (accepts :json / 'json / \"json\")."
     "" NIL)
    ("DB-NOT-FOUND" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Optionally signal from a DB adapter when a required record is
    definitively absent.  Treated as :F in read/update/delete macros."
     "" NIL)
    ("VIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CALL-CONTEXT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("DBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CHECK-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("RENDERJSON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Takes the viewmodel and converts into JSON" "" NIL)
    ("DEFUN-MEMO" "MACRO" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Define a memoized function." "" NIL)
    ("DOD-ABAC-SUBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("NST-GET-CACHED-CORE-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("GET-ABAC-SUBJECT-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("DISPATCH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Runs pipeline + outbound adapter selection." "" NIL)
    ("MAKE-UI-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-TEXT-HIDDEN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("LIST-ACTION-ROUTES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis2.lisp"
     "Diagnostic — all registered action route keys." "" NIL)))))
