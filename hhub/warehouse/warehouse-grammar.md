RADICAL: whs (warehouse — supply location entity)
गण: Reference entity (stable master data)
     Valid प्रत्यय: make fetch list !update ?exists ×(soft-delete)
     Invalid प्रत्यय: →xx !state history ∑

STATES (अवस्था):
  :active → :deleted (soft delete only, no hard delete)

INVARIANTS (नित्य — cannot be overridden):
  1. wname is non-null, non-empty
  2. wgstin is unique per tenant (GST compliance)
  3. company is non-null (tenant isolation)
  4. wstate is a valid Indian state code
  5. wpin is a valid 6-digit PIN

DOMAIN INTENT (the type that crosses the boundary):
  whs-intent: wname wgstin wphone waltphone waddr1 waddr2
              wcity wstate wpin wemail wmanager company

COMPOUND NAMES (समास analysis):
  warehouse-gstin      → षष्ठी तत्पुरुष (GSTIN OF warehouse)
  warehouse-manager    → षष्ठी तत्पुरुष (manager OF warehouse)
  create-warehouse     → NOT a compound — verb+noun, rename to whs:make

OPERATIONS (क्रिया with प्रत्यय):
  proc.whs:make     → create warehouse
  proc.whs:fetch    → retrieve one
  proc.whs:list     → retrieve all for tenant
  proc.whs:!update  → modify warehouse
  proc.whs:?exists  → predicate check
  proc.whs:×        → soft delete (sets :deleted state)

PACKAGE = ACTIVE DOMAIN CONTEXT:
  proc.whs:make      = create a warehouse
  proc.whs:fetch     = get warehouse by id
  proc.whs:list      = list all warehouses for tenant