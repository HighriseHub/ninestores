;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026March-create-procure-ai-entity-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_ENTITY"
     "-- =============================================================================
-- DOD_PROCURE — AI Native B2B Procurement Platform
-- Database Schema — 15 Tables
-- Philosophy: Events + Facts + Signals + Policies + Skills
-- =============================================================================

-- =============================================================================
-- GROUP 1: FACT
-- What exists and what is known about it
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_ENTITY
-- The anchor table. Every actor in the system — customer, vendor, product,
-- subscription, location, employee, contract.
-- No attributes here. Attributes live in DOD_PROCURE_ENTITY_FACT.
-- This table exists only so other tables have something to join to.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_ENTITY (
  ROW_ID MEDIUMINT NOT NULL, 
  ENTITY_ID       VARCHAR(100)  NOT NULL,
  -- Human-readable identity: CUST-ACME-001, VEND-A-001, PROD-SUGAR-25KG
  -- SUB-BAKERY-SUGAR-001, LOC-PUNE-MAIN, EMP-007

  ENTITY_TYPE     VARCHAR(50)   NOT NULL,
  -- CUSTOMER, VENDOR, PRODUCT, SUBSCRIPTION, LOCATION,
  -- EMPLOYEE, CONTRACT, CATEGORY, SKILL_ENTITY
  -- Not an enum — new types cost zero schema change

  TENANT_ID       MEDIUMINT     NOT NULL,

  CREATED         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  INDEX idx_type_tenant (ENTITY_TYPE, TENANT_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))


(defun migrate-2026March-create-procure-ai-entity-fact-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_ENTITY-FACT"
"
-- -----------------------------------------------------------------------------
-- DOD_PROCURE_ENTITY_FACT
-- Every attribute of every entity — name, price, GSTIN, address, preference,
-- contracted price, schedule, credit limit, reliability score.
-- Versioned via VALID_FROM / VALID_TO. Sourced. Confidence-scored.
-- Replaces: CUSTOMER_PROFILE, VENDOR_PROFILE, PRODUCT, CATEGORY,
--           ADDRESS, SETTINGS, CONFIGURATION tables.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_ENTITY_FACT (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,

  ENTITY_ID       VARCHAR(100)  NOT NULL,
  TENANT_ID       MEDIUMINT     NOT NULL,

  -- What fact is this?
  FACT_KEY        VARCHAR(200)  NOT NULL,
  -- \"name\", \"email\", \"phone\", \"gstin\", \"pan\",
  -- \"contracted_price\", \"credit_limit\", \"reorder_point\",
  -- \"preferred_vendor\", \"invoice_frequency\", \"schedule_days\",
  -- \"signal_time\", \"deliver_by_time\", \"on_failure\",
  -- \"quantity_tolerance_pct\", \"valid_from\", \"valid_to\"

  -- The fact value — always stored as text, cast on read
  FACT_VAL        TEXT          NOT NULL,

  FACT_TYPE       VARCHAR(20)   NOT NULL DEFAULT 'string',
  -- string, number, date, json, boolean, embedding

  -- Where did this fact come from?
  SOURCE_TYPE     VARCHAR(30)   NOT NULL,
  -- HUMAN_ENTERED    → user typed it
  -- AI_EXTRACTED     → LLM read a document and extracted it
  -- AI_INFERRED      → system inferred from behaviour patterns
  -- API_SYNC         → came from an external system (HR, ERP)
  -- OBSERVATION      → derived from DOD_PROCURE_TRACE_EVENT patterns
  -- SYSTEM           → computed by the platform itself

  -- How confident are we this fact is accurate?
  CONFIDENCE      DECIMAL(5,4)  NOT NULL DEFAULT 1.0000,
  -- 1.0000 = human entered, certain
  -- 0.9500 = extracted from verified document
  -- 0.8000 = inferred from 10+ observations
  -- 0.6000 = inferred from 3 observations
  -- 0.4000 = single observation, uncertain

  -- Temporal validity — full fact history preserved
  VALID_FROM      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  VALID_TO        TIMESTAMP     NULL DEFAULT NULL,
  -- NULL = currently true
  -- Non-null = this fact changed, historical record preserved

  -- Who or what asserted this fact
  ASSERTED_BY     VARCHAR(100)  NULL DEFAULT NULL,
  -- user ID, agent name, system process name

  CREATED         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  INDEX idx_entity_key_current (ENTITY_ID, FACT_KEY, VALID_TO),
  INDEX idx_entity_tenant      (ENTITY_ID, TENANT_ID),
  INDEX idx_fact_key_tenant    (FACT_KEY, TENANT_ID),
  INDEX idx_source_confidence  (SOURCE_TYPE, CONFIDENCE),
  INDEX idx_valid_from         (VALID_FROM)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-commerce-event-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_COMMERCE_EVENT"
"

-- =============================================================================
-- GROUP 2: EVENT
-- Everything that happens
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_COMMERCE_EVENT
-- Every commerce occurrence on a thread — intent expressed, order confirmed,
-- invoice generated, payment received, subscription triggered, delivery
-- fulfilled. Immutable. Append-only. The source of truth.
-- Replaces: ORDER, ORDER_ITEMS, VENDOR_ORDERS, INVOICE, PAYMENT,
--           SUBSCRIPTION_EVENT, AUDIT_LOG, STATUS_HISTORY tables.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_COMMERCE_EVENT (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,
  TENANT_ID       MEDIUMINT     NOT NULL,

  -- Thread identity — all events for one commercial relationship share this
  -- One thread spans the full lifecycle: intent → order → invoice → payment
  THREAD_ID       VARCHAR(100)  NOT NULL,
  -- \"TXN-ACME-20260317-001\"       → spot order
  -- \"SUB-BAKERY-SUGAR-001-THREAD\" → subscription (never closes)
  -- \"QUOTE-TECHCORP-Q-2026-042\"   → quotation thread

  -- Thread type — determines lifecycle behaviour
  THREAD_TYPE     VARCHAR(30)   NOT NULL DEFAULT 'SPOT_ORDER',
  -- SPOT_ORDER    → one-time purchase, closes on payment
  -- SUBSCRIPTION  → standing order, closes on cancellation
  -- QUOTATION     → RFQ thread, closes on acceptance or expiry
  -- RETURN        → return/refund thread

  -- What happened?
  EVENT_TYPE      VARCHAR(100)  NOT NULL,
  -- CUSTOMER SIDE:
  --   INTENT_EXPRESSED, INTENT_STRUCTURED, INTENT_CLARIFIED,
  --   PRODUCT_MATCHED, VENDOR_SELECTED, ORDER_PROPOSED,
  --   ORDER_CONFIRMED, ORDER_AMENDED, ORDER_CANCELLED
  -- VENDOR SIDE:
  --   VENDOR_ORDER_SENT, ORDER_ACKNOWLEDGED,
  --   FULFILLMENT_STARTED, ORDER_FULFILLED, ORDER_PARTIAL,
  --   ORDER_REJECTED, FALLBACK_TRIGGERED
  -- FINANCIAL:
  --   INVOICE_GENERATED, INVOICE_AMENDED, INVOICE_SENT,
  --   PAYMENT_INITIATED, PAYMENT_RECEIVED, PAYMENT_PARTIAL,
  --   PAYMENT_FAILED, CREDIT_NOTE_RAISED, ADVANCE_RECEIVED,
  --   ADVANCE_APPLIED, INVOICE_OVERDUE
  -- SUBSCRIPTION:
  --   SUBSCRIPTION_CREATED, SUBSCRIPTION_ACTIVATED,
  --   SUBSCRIPTION_DELIVERY_TRIGGERED, SUBSCRIPTION_DELIVERY_FULFILLED,
  --   SUBSCRIPTION_DELIVERY_PARTIAL, SUBSCRIPTION_DELIVERY_FAILED,
  --   SUBSCRIPTION_PAUSED, SUBSCRIPTION_RESUMED,
  --   SUBSCRIPTION_INVOICE_CONSOLIDATED, SUBSCRIPTION_CANCELLED
  -- COMPLIANCE:
  --   DOCUMENT_GENERATED, TAX_REPORT_GENERATED,
  --   ITC_RECONCILED, E_INVOICE_GENERATED
  -- COMMUNICATION:
  --   COMMUNICATION_SENT, REMINDER_SENT
  -- SYSTEM:
  --   THREAD_CLOSED

  -- Who triggered this event?
  ACTOR_TYPE      VARCHAR(30)   NOT NULL,
  -- CUSTOMER, VENDOR, AGENT, SYSTEM, HUMAN_APPROVER, SCHEDULER

  ACTOR_ID        VARCHAR(100)  NOT NULL,
  -- User ID, agent name, scheduler name

  -- The full structured payload — shape varies by EVENT_TYPE
  PAYLOAD         JSON          NOT NULL,

  -- Human + AI readable narrative of what happened
  NARRATIVE       TEXT          NULL DEFAULT NULL,

  -- Parent event — for branching (returns, amendments, partial fulfillments)
  PARENT_EVENT_ID BIGINT        NULL DEFAULT NULL,

  -- Links to the agent intelligence pipeline that drove this event
  SIGNAL_ID       BIGINT        NULL DEFAULT NULL,
  ACTION_ID       BIGINT        NULL DEFAULT NULL,

  -- Immutable timestamp — never updated
  CREATED         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  INDEX idx_thread_created    (THREAD_ID, CREATED),
  INDEX idx_thread_type_event (THREAD_ID, EVENT_TYPE),
  INDEX idx_event_type_tenant (EVENT_TYPE, TENANT_ID, CREATED),
  INDEX idx_actor             (ACTOR_TYPE, ACTOR_ID, CREATED),
  INDEX idx_signal            (SIGNAL_ID),
  INDEX idx_action            (ACTION_ID),
  INDEX idx_tenant_created    (TENANT_ID, CREATED)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-commerce-state-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_COMMERCE_STATE"
"
-- -----------------------------------------------------------------------------
-- DOD_PROCURE_COMMERCE_STATE
-- Current state derived from DOD_PROCURE_COMMERCE_EVENT.
-- Performance optimisation only — NOT the source of truth.
-- Can always be dropped and rebuilt by replaying COMMERCE_EVENT.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_COMMERCE_STATE (
  THREAD_ID       VARCHAR(100)  NOT NULL,
  TENANT_ID       MEDIUMINT     NOT NULL,

  THREAD_TYPE     VARCHAR(30)   NOT NULL DEFAULT 'SPOT_ORDER',

  -- Current status derived from latest events
  CURRENT_STATUS  VARCHAR(50)   NOT NULL,
  -- INTENT_RECEIVED, STRUCTURED, PENDING_MATCH, VENDOR_SELECTED,
  -- PENDING_CONFIRMATION, CONFIRMED, TRANSMITTED, ACKNOWLEDGED,
  -- FULFILLMENT_IN_PROGRESS, PARTIAL, FULFILLED,
  -- INVOICED, PAYMENT_PENDING, PARTIALLY_PAID, PAID,
  -- OVERDUE, CANCELLED, CLOSED,
  -- ACTIVE (subscription), PAUSED (subscription)

  -- Denormalised for fast reads — derived from events, not source of truth
  CUSTOMER_ID     VARCHAR(100)  NULL DEFAULT NULL,
  VENDOR_IDS      JSON          NULL DEFAULT NULL,
  -- [\"VEND-A-001\", \"VEND-B-001\"] for multi-vendor orders

  TOTAL_VALUE     DECIMAL(15,2) NULL DEFAULT NULL,
  -- Accumulates with each fulfilled delivery for subscriptions

  LINE_ITEM_COUNT INT           NULL DEFAULT 0,
  -- For subscriptions: deliveries in current invoice period

  LATEST_ETA      DATE          NULL DEFAULT NULL,

  -- When was this state last computed from events?
  COMPUTED_AT     TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,

  -- Total events in this thread — health indicator
  EVENT_COUNT     INT           NOT NULL DEFAULT 0,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (THREAD_ID, TENANT_ID),
  INDEX idx_status_tenant   (CURRENT_STATUS, TENANT_ID),
  INDEX idx_customer_status (CUSTOMER_ID, CURRENT_STATUS),
  INDEX idx_thread_type     (THREAD_TYPE, CURRENT_STATUS, TENANT_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-signal-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_SIGNAL"
"
-- =============================================================================
-- GROUP 3: SIGNAL
-- What needs attention
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_SIGNAL
-- Structured, classified signal ready for the agent pipeline.
-- Emitted by scouts, promoted from CHAT_SIGNAL, or raised by schedulers.
-- The perception layer — what the colony pays attention to.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_SIGNAL (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,

  -- What kind of signal is this?
  SIGNAL_TYPE     VARCHAR(100)  NOT NULL,
  -- NEW_JOINER, INVENTORY_LOW, DEVICE_UNDER_REPAIR,
  -- CONTRACT_EXPIRING, BUDGET_THRESHOLD, VENDOR_PRICE_CHANGE,
  -- DELIVERY_DELAYED, APPROVAL_STALE, INVOICE_OVERDUE_APPROACHING,
  -- INVOICE_OVERDUE, TAX_FILING_DUE, ADVANCE_EXPIRING,
  -- SUBSCRIPTION_DELIVERY_DUE, ANTICIPATED_BULK_DEMAND,
  -- CONSUMER_DEMAND (simulation), CUSTOM

  -- What entity triggered it?
  ENTITY_TYPE     VARCHAR(50)   NOT NULL,
  -- PRODUCT, VENDOR, CUSTOMER, CONTRACT, BUDGET,
  -- EMPLOYEE, SUBSCRIPTION, ASSET

  ENTITY_ID       VARCHAR(100)  NOT NULL,

  -- The raw observed fact — shape varies by SIGNAL_TYPE
  OBSERVED_VALUE  JSON          NOT NULL,
  -- INVENTORY_LOW: {sku, current_stock, reorder_point, days_remaining}
  -- NEW_JOINER: {count, roles, start_date, department, location}
  -- INVOICE_OVERDUE: {invoice_ref, days_overdue, amount, customer_id}

  -- How confident are we this signal is meaningful?
  CONFIDENCE      DECIMAL(5,4)  NOT NULL DEFAULT 1.0000,
  -- 1.0 = certain (scheduled subscription delivery)
  -- 0.9 = strong (inventory threshold crossed)
  -- 0.7 = probable (pattern-based inference)
  -- 0.5 = weak (accumulated from chat signals)

  -- Has this signal been acted on?
  STATUS          VARCHAR(20)   NOT NULL DEFAULT 'NEW',
  -- NEW → EVALUATED → ACTED → IGNORED → SNOOZED → EXPIRED

  -- Which agent evaluated this signal?
  EVALUATED_BY    VARCHAR(100)  NULL DEFAULT NULL,
  EVALUATED_AT    TIMESTAMP     NULL DEFAULT NULL,

  -- Link to action taken (populated after planning)
  ACTION_ID       BIGINT        NULL DEFAULT NULL,

  -- Which scout emitted this signal?
  SCOUT_TYPE      VARCHAR(100)  NULL DEFAULT NULL,
  -- INVENTORY-SCOUT, HR-SCOUT, IT-HELPDESK-SCOUT,
  -- SUBSCRIPTION-SCOUT, CHAT-SIGNAL-ENGINE, VENDOR-API-SCOUT

  SCOUT_ID        VARCHAR(100)  NULL DEFAULT NULL,

  TENANT_ID       MEDIUMINT     NULL DEFAULT NULL,

  CREATED         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED         TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  INDEX idx_type_status     (SIGNAL_TYPE, STATUS),
  INDEX idx_entity          (ENTITY_TYPE, ENTITY_ID),
  INDEX idx_tenant_new      (TENANT_ID, STATUS, CREATED),
  INDEX idx_confidence      (CONFIDENCE, STATUS),
  INDEX idx_action          (ACTION_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-chat-signal-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_CHAT_SIGNAL"
"
-- -----------------------------------------------------------------------------
-- DOD_PROCURE_CHAT_SIGNAL
-- Raw conversational input classified and accumulated.
-- Weak signals accumulate here until threshold is met, then promote to
-- DOD_PROCURE_SIGNAL. Strong transaction intents promote immediately.
-- Also updates DOD_PROCURE_ENTITY_FACT directly for context enrichment.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_CHAT_SIGNAL (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,
  TENANT_ID       MEDIUMINT     NOT NULL,

  -- Who said it
  ENTITY_ID       VARCHAR(100)  NOT NULL,
  -- The customer, vendor, or employee who typed the message
  ENTITY_TYPE     VARCHAR(30)   NOT NULL,
  -- CUSTOMER, VENDOR, EMPLOYEE

  -- The raw message — preserved forever for audit and reanalysis
  RAW_MESSAGE     TEXT          NOT NULL,

  -- Channel the message arrived on
  CHANNEL         VARCHAR(30)   NOT NULL DEFAULT 'CHAT',
  -- CHAT, EMAIL, VOICE, SMS, WHATSAPP

  -- What the LLM understood this message to be
  CLASSIFICATION  VARCHAR(30)   NOT NULL,
  -- TRANSACTION_INTENT  → wants to buy/order something now
  -- WEAK_SIGNAL         → observation, plan, complaint, preference
  -- CONTEXT_UPDATE      → updating profile facts
  -- QUERY               → asking about order status, invoice, etc.
  -- SOCIAL              → greeting, thanks, off-topic

  -- Structured extraction from the message
  EXTRACTED       JSON          NOT NULL,
  -- Shape varies by CLASSIFICATION:
  -- TRANSACTION_INTENT: {products, quantities, vendor_pref, timeline}
  -- WEAK_SIGNAL: {signal_type, entities, implied_timeframe, implied_need}
  -- CONTEXT_UPDATE: {fact_key, fact_value}
  -- QUERY: {query_type, entity_ref, time_range}

  -- For WEAK_SIGNAL specifically
  SIGNAL_TYPE     VARCHAR(100)  NULL DEFAULT NULL,
  -- TEAM_GROWTH, BUDGET_INCREASE, PRODUCT_INTEREST,
  -- VENDOR_DISSATISFACTION, UPCOMING_PROJECT,
  -- SEASONAL_DEMAND, TECHNOLOGY_CHANGE, PAYMENT_DIFFICULTY,
  -- OFFICE_EXPANSION

  IMPLIED_TIMEFRAME VARCHAR(50) NULL DEFAULT NULL,
  -- IMMEDIATE, WITHIN_7_DAYS, WITHIN_30_DAYS,
  -- WITHIN_QUARTER, WITHIN_6_MONTHS, NEXT_YEAR, UNSPECIFIED

  -- How confident is the LLM about this classification and extraction?
  CONFIDENCE      DECIMAL(5,4)  NOT NULL,

  -- Accumulation state
  STATUS          VARCHAR(20)   NOT NULL DEFAULT 'NEW',
  -- NEW → ACCUMULATING → PROMOTED → EXPIRED → IGNORED → ACTED_DIRECT

  -- Grouping key — related weak signals share this
  -- All signals about the same topic from the same entity in the same period
  ACCUMULATION_GROUP VARCHAR(200) NULL DEFAULT NULL,
  -- \"TEAM_GROWTH:CUST-ACME-001:2026-Q1\"
  -- \"PRODUCT_INTEREST:CUST-BAKERY-001:SUGAR:2026-H1\"

  -- If promoted, which DOD_PROCURE_SIGNAL did this contribute to?
  SIGNAL_ID       BIGINT        NULL DEFAULT NULL,

  -- If acted directly (TRANSACTION_INTENT), which commerce thread?
  THREAD_ID       VARCHAR(100)  NULL DEFAULT NULL,

  -- Signals expire if they never accumulate enough to act on
  EXPIRES_AT      TIMESTAMP     NULL DEFAULT NULL,

  CREATED         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED         TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  INDEX idx_entity_signal     (ENTITY_ID, SIGNAL_TYPE, STATUS),
  INDEX idx_accumulation      (ACCUMULATION_GROUP, STATUS),
  INDEX idx_tenant_new        (TENANT_ID, STATUS, CREATED),
  INDEX idx_classification    (CLASSIFICATION, TENANT_ID),
  INDEX idx_signal_ref        (SIGNAL_ID),
  INDEX idx_expires           (EXPIRES_AT, STATUS)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-signal-route-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_SIGNAL_ROUTE"
"

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_SIGNAL_ROUTE
-- Which agent handles which signal type.
-- Written once by humans. Read by the coordinator actor on every signal.
-- The routing table — the waggle dance decoder.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_SIGNAL_ROUTE (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,

  -- Signal type this route handles
  SIGNAL_TYPE     VARCHAR(100)  NOT NULL,

  -- Which agent is responsible
  AGENT_NAME      VARCHAR(100)  NOT NULL,
  -- ONBOARDING-AGENT, PROCUREMENT-AGENT, CONTRACT-RENEWAL-AGENT,
  -- BUDGET-ALERT-AGENT, ESCALATION-AGENT, NUDGE-AGENT,
  -- NUMBER-SUPPLY-AGENT (simulation), BILLING-AGENT

  -- Which DOD_PROCURE_SKILL should the agent use (if known)
  -- NULL means compose fresh workflow
  SKILL_ID        BIGINT        NULL DEFAULT NULL,

  -- Priority — lower number = higher priority
  PRIORITY        TINYINT       NOT NULL DEFAULT 5,
  -- 1 = critical (delivery failure, payment overdue)
  -- 3 = high (new joiner, inventory low)
  -- 5 = medium (contract expiring, budget threshold)
  -- 8 = low (nudge, reminder)

  -- Additional routing conditions evaluated at runtime
  CONDITIONS      JSON          NULL DEFAULT NULL,
  -- {\"min_confidence\": 0.7, \"also_watch\": \"DEVICE_UNDER_REPAIR\",
  --  \"correlate_by\": \"device_type\", \"window_hours\": 24,
  --  \"combine_demand\": true}

  ENABLED         CHAR(1)       NOT NULL DEFAULT 'Y',

  TENANT_ID       MEDIUMINT     NULL DEFAULT NULL,
  -- NULL = platform default, non-null = tenant-specific override

  CREATED         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED         TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  UNIQUE KEY uq_signal_agent_tenant (SIGNAL_TYPE, AGENT_NAME, TENANT_ID),
  INDEX idx_signal_enabled   (SIGNAL_TYPE, ENABLED),
  INDEX idx_priority         (PRIORITY, ENABLED),
  INDEX idx_skill            (SKILL_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-policy-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_AI_POLICY"
"
-- =============================================================================
-- GROUP 4: POLICY
-- What is allowed
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_AI_POLICY
-- Declarative rules governing autonomous action.
-- Auto-approve conditions, approval thresholds, blocked actions,
-- escalation paths. Written once, enforced everywhere.
-- Replaces: entitlement systems, configuration portals, feature flags,
--           permission matrices, provisioning systems.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_AI_POLICY (
  ROW_ID              BIGINT        NOT NULL AUTO_INCREMENT,

  POLICY_CODE         VARCHAR(100)  NOT NULL,
  -- \"AUTO-APPROVE-STANDARD-REORDER\"
  -- \"REQUIRE-APPROVAL-HIGH-VALUE\"
  -- \"BLOCK-NEW-VENDOR-AUTO-ORDER\"
  -- \"AUTO-EXECUTE-ACTIVE-SUBSCRIPTION\"
  -- \"ESCALATE-OVERDUE-INVOICE\"

  POLICY_TYPE         VARCHAR(50)   NOT NULL,
  -- AUTO_APPROVE     → execute without human
  -- REQUIRE_APPROVAL → route to approver
  -- BLOCK            → hard stop, raise exception
  -- NOTIFY_ONLY      → act but also notify a human
  -- ESCALATE         → route to senior approver

  -- What this policy governs
  APPLIES_TO_SIGNAL   VARCHAR(100)  NULL DEFAULT NULL,
  -- Signal type that triggers evaluation

  APPLIES_TO_ACTION   VARCHAR(100)  NULL DEFAULT NULL,
  -- Action type that this policy constrains

  -- The conditions as evaluable JSON rules
  -- Evaluated at runtime against the planned action context
  CONDITIONS          JSON          NOT NULL,
  -- {\"max_value\": 500000,
  --  \"vendor_reliability_min\": 0.85,
  --  \"budget_available\": true,
  --  \"item_category\": \"standard\",
  --  \"roles_allowed\": [\"procurement-manager\"],
  --  \"min_value\": 500001}

  -- What happens when conditions are met
  OUTCOME             JSON          NOT NULL,
  -- {\"action\": \"EXECUTE\", \"notify\": []}
  -- {\"action\": \"ROUTE_TO_APPROVER\",
  --  \"approver_role\": \"procurement-manager\",
  --  \"escalate_after_hours\": 4}
  -- {\"action\": \"BLOCK\",
  --  \"reason\": \"New vendor requires manual onboarding first\"}

  -- Evaluation order — lower number evaluated first
  PRIORITY            TINYINT       NOT NULL DEFAULT 5,

  ENABLED             CHAR(1)       NOT NULL DEFAULT 'Y',

  -- Human-readable explanation for audit purposes
  DESCRIPTION         TEXT          NULL DEFAULT NULL,

  TENANT_ID           MEDIUMINT     NULL DEFAULT NULL,
  -- NULL = platform default, non-null = tenant-specific policy

  CREATED             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED             TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP
                      ON UPDATE CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  UNIQUE KEY uq_policy_code_tenant (POLICY_CODE, TENANT_ID),
  INDEX idx_signal_type    (APPLIES_TO_SIGNAL, ENABLED),
  INDEX idx_action_type    (APPLIES_TO_ACTION, ENABLED),
  INDEX idx_priority       (PRIORITY, ENABLED),
  INDEX idx_type_tenant    (POLICY_TYPE, TENANT_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-exception-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_AI_EXCEPTION"
"
-- =============================================================================
-- GROUP 5: EXCEPTION
-- What needs a human
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_EXCEPTION
-- Every decision that reached a policy boundary and needs human judgment.
-- The human inbox. Should be mostly empty in a healthy, well-tuned system.
-- Presents context, reasoning, and options. SLA-tracked. Escalation-aware.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_AI_EXCEPTION (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,

  -- Which planned action triggered this exception
  ACTION_ID       BIGINT        NOT NULL,

  -- Why is this in front of a human?
  EXCEPTION_TYPE  VARCHAR(100)  NOT NULL,
  -- APPROVAL_REQUIRED        → value exceeds auto-approve limit
  -- AMBIGUOUS_SIGNAL         → LLM confidence below threshold
  -- POLICY_CONFLICT          → two policies contradict
  -- LOW_CONFIDENCE_PREDICTION → Bayesian model uncertain
  -- BUDGET_EXCEEDED          → order would exceed budget
  -- NEW_VENDOR               → first-time vendor, needs review
  -- FALLBACK_FAILED          → preferred AND fallback vendor failed
  -- SUBSCRIPTION_DELIVERY_FAILED → both vendors unable to fulfill
  -- SALES_OPPORTUNITY        → proactive: agent detected opportunity
  -- INVOICE_OVERDUE          → requires human escalation decision

  -- Human-readable explanation — generated by agent, not template
  -- Contains: what happened, why it needs attention, supporting evidence,
  --           predicted outcome of each option, urgency indicators
  EXCEPTION_TEXT  TEXT          NOT NULL,

  -- Available choices presented to the human
  OPTIONS         JSON          NOT NULL,
  -- [{\"label\": \"Approve — place order with VendorA\",
  --   \"action\": \"APPROVE\",
  --   \"consequence\": \"PO raised immediately, delivery March 19\"},
  --  {\"label\": \"Modify quantity\",
  --   \"action\": \"EDIT\",
  --   \"consequence\": \"Opens modification form\"},
  --  {\"label\": \"Reject\",
  --   \"action\": \"REJECT\",
  --   \"consequence\": \"Action cancelled, signal marked ignored\"}]

  -- Human response
  RESOLVED_BY     VARCHAR(100)  NULL DEFAULT NULL,
  RESOLVED_AT     TIMESTAMP     NULL DEFAULT NULL,
  RESOLUTION      VARCHAR(50)   NULL DEFAULT NULL,
  -- APPROVED, REJECTED, EDITED, SNOOZED, REDIRECTED, ESCALATED

  RESOLUTION_DATA JSON          NULL DEFAULT NULL,
  -- Any modifications the human made before approving

  -- SLA tracking
  SLA_HOURS       TINYINT       NOT NULL DEFAULT 24,
  -- Time allowed before escalation

  ESCALATED       CHAR(1)       NOT NULL DEFAULT 'N',
  ESCALATED_TO    VARCHAR(100)  NULL DEFAULT NULL,
  ESCALATED_AT    TIMESTAMP     NULL DEFAULT NULL,

  -- Link to the signal that started this chain
  SIGNAL_ID       BIGINT        NULL DEFAULT NULL,

  TENANT_ID       MEDIUMINT     NULL DEFAULT NULL,

  CREATED         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED         TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  INDEX idx_action          (ACTION_ID),
  INDEX idx_unresolved      (RESOLVED_AT, TENANT_ID),
  INDEX idx_sla_check       (CREATED, SLA_HOURS, ESCALATED),
  INDEX idx_type_tenant     (EXCEPTION_TYPE, TENANT_ID),
  INDEX idx_signal          (SIGNAL_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-skill-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_AI_SKILL"
"

-- =============================================================================
-- GROUP 6: SKILL
-- What the system knows how to do
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_SKILL
-- Proven workflows promoted from DOD_PROCURE_PLANNED_ACTION after N successful
-- executions. Parameterised scripts. The system's procedural memory.
-- Grows automatically as the system operates. Replaces: microservices, plugins,
-- custom integration code, explicit scenario programming.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_AI_SKILL (
  ROW_ID              BIGINT        NOT NULL AUTO_INCREMENT,

  SKILL_CODE          VARCHAR(100)  NOT NULL,
  -- \"SUPPLY-NUMBERS-ABOVE-THRESHOLD\"   (simulation)
  -- \"DAILY-COMMODITY-REORDER\"          (bakery sugar)
  -- \"NEW-JOINER-LAPTOP-PROCUREMENT\"
  -- \"CONTRACT-RENEWAL-30-DAY\"
  -- \"INVOICE-OVERDUE-REMINDER\"
  -- \"VENDOR-SELECTION-RELIABILITY\"

  SKILL_NAME          VARCHAR(200)  NOT NULL,
  DESCRIPTION         TEXT          NULL DEFAULT NULL,

  -- What signal pattern triggers this skill
  TRIGGER_SIGNAL_TYPE VARCHAR(100)  NOT NULL,

  -- Conditions that must match for this skill to be selected
  TRIGGER_CONDITIONS  JSON          NULL DEFAULT NULL,
  -- {\"preference_type\": \"above_threshold\", \"quantity_max\": 20}
  -- {\"entity_type\": \"EMPLOYEE\", \"role_in\": [\"engineer\",\"developer\"]}

  -- The proven parameterised workflow script
  -- Same format as DOD_PROCURE_PLANNED_ACTION.ACTION_SCRIPT
  -- But with {{variable}} placeholders instead of literal values
  SKILL_SCRIPT        JSON          NOT NULL,
  -- [{\"step\": 1,
  --   \"function\": \"FETCH-NUMBERS-FROM-PRODUCER\",
  --   \"inputs\": {\"producer_id\": \"{{best_producer}}\",
  --              \"quantity\": \"{{quantity_plus_one}}\",
  --              \"min_value\": \"{{preference_threshold}}\"},
  --   \"outputs\": {\"binds-as\": \"raw_numbers\"},
  --   \"purpose\": \"Get numbers from best producer\"},
  --  ...]

  -- Quality evidence — why this was promoted
  PROMOTED_FROM_ACTION_IDS JSON     NULL DEFAULT NULL,
  -- [401, 523, 687, 891, 1024] — action IDs that proved this works

  -- How many times this skill ran successfully before promotion
  PROMOTED_AT_N       INT           NULL DEFAULT NULL,

  -- Live performance tracking
  SUCCESS_COUNT       INT           NOT NULL DEFAULT 0,
  FAILURE_COUNT       INT           NOT NULL DEFAULT 0,
  LAST_USED           TIMESTAMP     NULL DEFAULT NULL,
  AVG_EXECUTION_MS    INT           NULL DEFAULT NULL,

  -- Computed: SUCCESS_COUNT / (SUCCESS_COUNT + FAILURE_COUNT)
  -- Updated by trigger or application after each use
  SUCCESS_RATE        DECIMAL(5,4)  NULL DEFAULT NULL,

  -- Lifecycle
  STATUS              VARCHAR(20)   NOT NULL DEFAULT 'DRAFT',
  -- DRAFT → VALIDATED → ACTIVE → DEGRADED → RETIRED
  -- DEGRADED: failure rate rising, needs human review
  -- RETIRED: superseded by better skill version

  -- Who approved this skill for production use
  APPROVED_BY         VARCHAR(100)  NULL DEFAULT NULL,
  APPROVED_AT         TIMESTAMP     NULL DEFAULT NULL,

  TENANT_ID           MEDIUMINT     NULL DEFAULT NULL,
  -- NULL = platform skill available to all tenants
  -- Non-null = tenant-specific learned skill

  CREATED             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED             TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP
                      ON UPDATE CURRENT_TIMESTAMP,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  UNIQUE KEY uq_skill_code_tenant (SKILL_CODE, TENANT_ID),
  INDEX idx_trigger_status  (TRIGGER_SIGNAL_TYPE, STATUS),
  INDEX idx_success_rate    (SUCCESS_RATE, STATUS),
  INDEX idx_tenant_active   (TENANT_ID, STATUS),
  INDEX idx_last_used       (LAST_USED)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-agent-context-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_AI_AGENT_CONTEXT"
"

-- =============================================================================
-- GROUP 7: SUPPORTING INTELLIGENCE
-- The reasoning infrastructure
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_AGENT_CONTEXT
-- Working memory assembled per agent run.
-- Everything the agent needs packed into one JSON object before it acts.
-- Token-counted. Trimming-aware. Per-run observability.
-- Lets you debug exactly what context each agent had when it decided.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_AI_AGENT_CONTEXT (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,

  -- Unique per agent execution thread
  RUN_ID          VARCHAR(100)  NOT NULL,
  -- \"RUN-ONBOARD-20260317-001\"
  -- \"RUN-SUPPLY-20260317-001\"

  AGENT_NAME      VARCHAR(100)  NOT NULL,
  -- \"ONBOARDING-AGENT\", \"NUMBER-SUPPLY-AGENT\", \"BILLING-AGENT\"

  -- Which signal triggered this run
  SIGNAL_ID       BIGINT        NOT NULL,

  -- Which action was planned in this run (populated after planning)
  ACTION_ID       BIGINT        NULL DEFAULT NULL,

  -- Everything the agent assembled for this run
  -- Sources: signal data, prediction output, entity facts,
  --          vendor context, relevant functions, policy snapshot
  CONTEXT_DATA    JSON          NOT NULL,

  -- Token budget tracking — critical for LLM context window management
  TOKEN_COUNT     INT           NOT NULL DEFAULT 0,

  -- Was context trimmed to fit the LLM window?
  TRIMMED         CHAR(1)       NOT NULL DEFAULT 'N',
  -- If Y, agent made decision with reduced information
  -- Track these — high TRIMMED rate means context assembly needs tuning

  TRIMMED_FIELDS  JSON          NULL DEFAULT NULL,
  -- Which fields were dropped: [\"vendor_history\", \"full_function_list\"]

  -- Run lifecycle
  STARTED_AT      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  COMPLETED_AT    TIMESTAMP     NULL DEFAULT NULL,

  -- Did this run produce a planned action or fail?
  RUN_STATUS      VARCHAR(20)   NOT NULL DEFAULT 'IN_PROGRESS',
  -- IN_PROGRESS, COMPLETED, FAILED, TIMED_OUT

  TENANT_ID       MEDIUMINT     NULL DEFAULT NULL,
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  UNIQUE KEY uq_run_id (RUN_ID),
  INDEX idx_agent_run     (AGENT_NAME, STARTED_AT),
  INDEX idx_signal        (SIGNAL_ID),
  INDEX idx_action        (ACTION_ID),
  INDEX idx_trimmed       (TRIMMED, TENANT_ID),
  INDEX idx_tenant_status (TENANT_ID, RUN_STATUS, STARTED_AT)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-prediction-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_AI_PREDICTION"
"
-- -----------------------------------------------------------------------------
-- DOD_PROCURE_PREDICTION
-- Output of the Bayesian reasoning layer.
-- Vendor selection, quantity optimisation, demand forecasting,
-- producer matching, risk scoring.
-- Outcome recorded after execution for model accuracy tracking.
-- The prediction ledger — your system learns from its own track record.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_AI_PREDICTION (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,

  -- Which signal triggered this prediction
  SIGNAL_ID       BIGINT        NOT NULL,

  PREDICTION_TYPE VARCHAR(100)  NOT NULL,
  -- PROCUREMENT_DEMAND     → what and how much to buy
  -- PRODUCER_SELECTION     → which producer/vendor to use
  -- VENDOR_RELIABILITY     → probability of on-time delivery
  -- REORDER_QUANTITY       → optimal quantity to order
  -- DELIVERY_RISK          → probability of delivery failure
  -- APPROVAL_LIKELIHOOD    → probability human will approve
  -- BUDGET_EXHAUSTION_DATE → when will budget run out
  -- ANTICIPATED_BULK_DEMAND → future demand inferred from signals

  -- The actual prediction
  PREDICTED_VALUE JSON          NOT NULL,
  -- Shape varies by PREDICTION_TYPE
  -- PROCUREMENT_DEMAND: {total_units, recommended_vendor, recommended_sku,
  --                      unit_price, total_value, urgency, required_by,
  --                      latest_order_by, reasoning}
  -- PRODUCER_SELECTION: {recommended_producer, score, hit_rate,
  --                      quantity_to_request, fallback, confidence}

  -- Statistical confidence from the Bayesian model
  CONFIDENCE      DECIMAL(5,4)  NOT NULL,
  -- Derived from Beta distribution sample size and posterior parameters

  -- Which model(s) produced this prediction
  MODEL_USED      VARCHAR(200)  NOT NULL,
  -- \"BETA-BINOMIAL-VENDOR + DEMAND-HISTORY-90D\"
  -- \"BETA-BINOMIAL-PRODUCER + RANGE-PREFERENCE-HISTORY\"

  -- Outcome — filled in after execution for model learning
  OUTCOME_VALUE   JSON          NULL DEFAULT NULL,
  -- What actually happened vs what was predicted

  OUTCOME_AT      TIMESTAMP     NULL DEFAULT NULL,

  -- How accurate was the prediction? 0.0 = wrong, 1.0 = perfect
  ACCURACY_SCORE  DECIMAL(5,4)  NULL DEFAULT NULL,

  TENANT_ID       MEDIUMINT     NULL DEFAULT NULL,

  CREATED         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
   DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  INDEX idx_signal          (SIGNAL_ID),
  INDEX idx_type_confidence (PREDICTION_TYPE, CONFIDENCE),
  INDEX idx_model           (MODEL_USED(100)),
  INDEX idx_accuracy        (ACCURACY_SCORE),
  INDEX idx_tenant_created  (TENANT_ID, CREATED),
  INDEX idx_outcome_pending (OUTCOME_AT, TENANT_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-planned-action-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_AI_PLANNED_ACTION"
"

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_PLANNED_ACTION
-- The composed workflow script before execution.
-- Produced by the LLM composer (novel scenario) or retrieved from
-- DOD_PROCURE_SKILL (proven scenario). Carries approval state, execution
-- state, and result. The bridge between intelligence and execution.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_AI_PLANNED_ACTION (
  ROW_ID              BIGINT        NOT NULL AUTO_INCREMENT,

  -- Which signal and prediction drove this action
  SIGNAL_ID           BIGINT        NOT NULL,
  PREDICTION_ID       BIGINT        NULL DEFAULT NULL,

  -- If a skill was used, which one?
  -- NULL = composed fresh by LLM (novel scenario)
  SKILL_ID            BIGINT        NULL DEFAULT NULL,

  -- Which run assembled this action
  RUN_ID              VARCHAR(100)  NULL DEFAULT NULL,

  -- What type of action is this?
  ACTION_TYPE         VARCHAR(100)  NOT NULL,
  -- CREATE_PURCHASE_ORDER, ACQUIRE_AND_DELIVER_NUMBERS,
  -- SEND_PAYMENT_REMINDER, GENERATE_INVOICE,
  -- RENEW_CONTRACT, ONBOARD_NEW_JOINER,
  -- TRIGGER_SUBSCRIPTION_DELIVERY

  -- The composed or retrieved workflow script
  -- Array of function calls with wired inputs/outputs
  ACTION_SCRIPT       JSON          NOT NULL,
  -- [{\"step\": 1,
  --   \"function\": \"FETCH-VENDOR-PRICING\",
  --   \"inputs\": {\"vendor_id\": \"VendorA\", \"sku\": \"MBP-M3\", \"qty\": 7},
  --   \"outputs\": {\"binds-as\": \"confirmed_price\"},
  --   \"purpose\": \"Confirm live price before committing\"},
  --  {\"step\": 2, ...}]

  -- Execution state
  STATUS              VARCHAR(20)   NOT NULL DEFAULT 'PLANNED',
  -- PLANNED → POLICY_CHECK → APPROVED → EXECUTING
  -- → COMPLETED | FAILED | CANCELLED | BLOCKED

  -- Does this need human approval before execution?
  APPROVAL_REQUIRED   CHAR(1)       NOT NULL DEFAULT 'N',
  APPROVAL_REASON     VARCHAR(500)  NULL DEFAULT NULL,
  -- \"Order value ₹13,12,500 exceeds auto-approve limit of ₹5,00,000\"

  APPROVED_BY         VARCHAR(100)  NULL DEFAULT NULL,
  APPROVED_AT         TIMESTAMP     NULL DEFAULT NULL,

  -- Execution result — populated after execution completes
  RESULT              JSON          NULL DEFAULT NULL,
  -- {success: true, outputs: {...}, execution_ms: 43}

  EXECUTED_AT         TIMESTAMP     NULL DEFAULT NULL,
  EXECUTED_BY         VARCHAR(100)  NULL DEFAULT NULL,
  -- Agent name that executed this

  -- Compensating transaction script — for rollback on failure
  COMPENSATING_SCRIPT JSON          NULL DEFAULT NULL,

  TENANT_ID           MEDIUMINT     NULL DEFAULT NULL,

  CREATED             TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED             TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP
                      ON UPDATE CURRENT_TIMESTAMP,
   DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  INDEX idx_signal          (SIGNAL_ID),
  INDEX idx_prediction      (PREDICTION_ID),
  INDEX idx_skill           (SKILL_ID),
  INDEX idx_run             (RUN_ID),
  INDEX idx_status_approval (STATUS, APPROVAL_REQUIRED),
  INDEX idx_tenant_pending  (TENANT_ID, STATUS),
  INDEX idx_action_type     (ACTION_TYPE, STATUS)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-procure-ai-symentic-index-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROCURE_AI_SYMENTIC_INDEX"
"
-- =============================================================================
-- GROUP 8: SEARCH
-- Finding things by meaning, not by exact match
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DOD_PROCURE_SEMANTIC_INDEX
-- Vector embeddings for every entity and fact.
-- Enables intent-based search — find products by description,
-- match vendors by capability, segment customers by behaviour.
-- Replaces: category hierarchies, faceted filters, Elasticsearch,
--           full-text search infrastructure.
-- -----------------------------------------------------------------------------
CREATE TABLE DOD_PROCURE_AI_SEMANTIC_INDEX (
  ROW_ID          BIGINT        NOT NULL AUTO_INCREMENT,
  TENANT_ID       MEDIUMINT     NOT NULL,

  -- What is being indexed?
  ENTITY_ID       VARCHAR(100)  NOT NULL,
  ENTITY_TYPE     VARCHAR(50)   NOT NULL,
  -- PRODUCT, VENDOR, CUSTOMER, SKILL, FUNCTION

  -- The text that was embedded
  -- Concatenation of key facts about this entity
  SOURCE_TEXT     TEXT          NOT NULL,
  -- PRODUCT:  \"MacBook Pro M3 32GB laptop developer high performance Apple\"
  -- VENDOR:   \"Apple authorised reseller Mumbai reliable premium electronics\"
  -- CUSTOMER: \"engineering team enterprise buyer regular high-value bulk orders\"
  -- SKILL:    \"daily commodity reorder subscription sugar flour wheat bulk\"

  -- The embedding vector stored as JSON array of floats
  -- For production: use pgvector column type or separate vector store
  -- For MySQL: JSON array enables basic similarity computation
  EMBEDDING       JSON          NOT NULL,
  -- [0.0234, -0.1823, 0.0912, ...] (1536 floats for ada-002)

  -- Embedding model used — important for invalidation when model changes
  MODEL_VERSION   VARCHAR(100)  NOT NULL DEFAULT 'text-embedding-ada-002',

  -- When was this embedding generated?
  -- Embeddings become stale when source facts change significantly
  GENERATED_AT    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Should this embedding be regenerated?
  STALE           CHAR(1)       NOT NULL DEFAULT 'N',
  -- Set to Y when significant ENTITY_FACT changes occur
  -- Background job regenerates stale embeddings nightly
  DELETED_STATE     CHAR(1) DEFAULT NULL,
  PRIMARY KEY (ROW_ID),
  UNIQUE KEY uq_entity_model (ENTITY_ID, ENTITY_TYPE, MODEL_VERSION, TENANT_ID),
  INDEX idx_entity      (ENTITY_ID, ENTITY_TYPE),
  INDEX idx_type_tenant (ENTITY_TYPE, TENANT_ID),
  INDEX idx_stale       (STALE, TENANT_ID),
  INDEX idx_generated   (GENERATED_AT)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- SUMMARY
-- =============================================================================
-- 15 tables. 5 primitives. Complete B2B procurement platform.
--
-- FACT:      DOD_PROCURE_ENTITY, DOD_PROCURE_ENTITY_FACT
-- EVENT:     DOD_PROCURE_COMMERCE_EVENT, DOD_PROCURE_COMMERCE_STATE,
--            DOD_PROCURE_TRACE_EVENT
-- SIGNAL:    DOD_PROCURE_SIGNAL, DOD_PROCURE_CHAT_SIGNAL,
--            DOD_PROCURE_SIGNAL_ROUTE
-- POLICY:    DOD_PROCURE_POLICY
-- EXCEPTION: DOD_PROCURE_EXCEPTION
-- SKILL:     DOD_PROCURE_SKILL
-- INTEL:     DOD_PROCURE_AGENT_CONTEXT, DOD_PROCURE_PREDICTION,
--            DOD_PROCURE_PLANNED_ACTION
-- SEARCH:    DOD_PROCURE_SEMANTIC_INDEX
--
-- WHAT IS NOT HERE (and why):
-- No CUSTOMER table      → DOD_PROCURE_ENTITY (type=CUSTOMER)
-- No VENDOR table        → DOD_PROCURE_ENTITY (type=VENDOR)
-- No PRODUCT table       → DOD_PROCURE_ENTITY (type=PRODUCT)
-- No CATEGORY table      → DOD_PROCURE_ENTITY_FACT (key=category)
-- No ORDER table         → DOD_PROCURE_COMMERCE_EVENT thread
-- No ORDER_ITEMS table   → DOD_PROCURE_COMMERCE_EVENT payload
-- No INVOICE table       → DOD_PROCURE_COMMERCE_EVENT (INVOICE_GENERATED)
-- No SUBSCRIPTION table  → DOD_PROCURE_ENTITY_FACT rows
-- No AUDIT_LOG table     → DOD_PROCURE_TRACE_EVENT is the audit log
-- No PERMISSIONS table   → DOD_PROCURE_POLICY
-- No FEATURE_FLAGS table → DOD_PROCURE_POLICY
-- =============================================================================")))



(defun migrate-2026March-insert-seed-data-to-ai-tables ()
  (handler-case
      (progn
        (clsql:execute-command
	 "-- Insert a test vendor entity
INSERT INTO DOD_PROCURE_ENTITY VALUES
('VEND-TEST-001', 'VENDOR', 42, NOW());")

	(clsql:execute-command "-- Insert initial facts for this vendor
INSERT INTO DOD_PROCURE_ENTITY_FACT
(ENTITY_ID, TENANT_ID, FACT_KEY, FACT_VAL, FACT_TYPE,
 SOURCE_TYPE, CONFIDENCE, VALID_FROM, VALID_TO)
VALUES
('VEND-TEST-001', 42,
 'com.nst.vendor.identity.name',
 'Acme Supplies Pvt Ltd',
 'string', 'HUMAN_ENTERED', 1.0, NOW(), NULL),

('VEND-TEST-001', 42,
 'com.nst.vendor.identity.email',
 'old@acme.com',
 'string', 'HUMAN_ENTERED', 1.0, NOW(), NULL),

('VEND-TEST-001', 42,
 'com.nst.vendor.tax.gstin',
 '27AAPFU0000F1ZV',
 'string', 'HUMAN_ENTERED', 1.0, NOW(), NULL);")

	(clsql:execute-command "

-- Insert the routing rule
INSERT INTO DOD_PROCURE_SIGNAL_ROUTE
(SIGNAL_TYPE, AGENT_NAME, PRIORITY, ENABLED, TENANT_ID)
VALUES
('CONTEXT_UPDATE', 'PROFILE-UPDATE-AGENT', 3, 'Y', 42),
('TRANSACTION_INTENT', 'PROCUREMENT-AGENT', 1, 'Y', 42),
('WEAK_SIGNAL', 'INTELLIGENCE-AGENT', 5, 'Y', 42);")

	(clsql:execute-command
	 "INSERT INTO DOD_PROCURE_AI_POLICY
(POLICY_CODE, POLICY_TYPE,
 APPLIES_TO_SIGNAL, APPLIES_TO_ACTION,
 CONDITIONS, OUTCOME, PRIORITY, ENABLED, TENANT_ID)
VALUES
('AUTO-APPROVE-PROFILE-UPDATE',
 'AUTO_APPROVE',
 'CONTEXT_UPDATE',
 'UPDATE_ENTITY_FACT',
 '{\"actor_type\": \"VENDOR\",
   \"updating_own_profile\": true,
   \"max_facts_per_update\": 10}',
 '{\"action\": \"EXECUTE\", \"notify\": []}',
 3, 'Y', 42);"))
	(clsql:sql-database-error (e)
      (format t "~%Migration error: ~A" e))))
     
