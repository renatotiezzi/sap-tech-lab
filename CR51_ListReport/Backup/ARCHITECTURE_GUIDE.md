# CR51 — Architecture Guide: RAP Object Map

## Overview

This solution implements two independent OData services built on the same RAP Business Object (BO).

- **Admin Service** (`ZSB_Q2C_MGR`) — full CRUD, no UI, used by developers / support
- **App Service** (`ZSB_Q2C_MGR_APP`) — read-only + Reprocess/Cancel actions, consumed by Fiori Elements

---

## Architecture Diagram

```
DB Tables
  ztbq2c_arq_mgr (root)
  ztbq2c_log_mgr (child 1:1)
        │
        ▼
  ┌─────────────────────────────────────┐
  │  ZI Layer (Business Object)         │
  │  ZI_Q2C_ARQ_MGR  ─── ZI_Q2C_LOG_MGR│
  │  BDEF managed + actions             │
  │  ZBP_I_Q2C_ARQ_MGR (handler)        │
  │       └── ZCL_Q2C_CPI_CALLER        │
  └────────────┬──────────────┬─────────┘
               │              │
               ▼              ▼
  ┌────────────────┐  ┌───────────────────────┐
  │  ZC Layer      │  │  ZC_APP Layer         │
  │  Admin CRUD    │  │  Fiori Reprocessamento│
  │  ZC_Q2C_ARQ +  │  │  ZC_Q2C_ARQ_APP +    │
  │  ZC_Q2C_LOG    │  │  ZC_Q2C_LOG_APP       │
  └───────┬────────┘  └──────────┬────────────┘
          │                      │
          ▼                      ▼
  ZSD_Q2C_MGR            ZSD_Q2C_MGR_APP
          │                      │
          ▼                      ▼
  ZSB_Q2C_MGR            ZSB_Q2C_MGR_APP
  (Admin OData V4)        (Fiori OData V4)
                                 │
                          MDE (DDLX annotations)
                                 │
                                 ▼
                         Fiori Elements
                         List Report + Actions
```

---

## Object Map by Group

### SHARED — Base Layer (ZI) → folder `CR51/`

These objects are **common to both services**. They define the Business Object, persistence, and all behavior logic.
Never expose ZI objects directly to a service — always go through a ZC projection.

| Object | Type | File | Description |
|--------|------|------|-------------|
| `ZI_Q2C_ARQ_MGR` | CDS Root View Entity | `CR51/ZI_Q2C_ARQ_MGR.ddls.txt` | Root BO. Maps `ztbq2c_arq_mgr`. Defines composition to `_Log`. |
| `ZI_Q2C_LOG_MGR` | CDS View Entity (child) | `CR51/ZI_Q2C_LOG_MGR.ddls.txt` | Child BO. Maps `ztbq2c_log_mgr`. Parent association `_Arq`. |
| `ZI_Q2C_ARQ_MGR` | BDEF (managed) | `CR51/ZI_Q2C_ARQ_MGR.bdef.txt` | Defines `create/update/delete`, actions `Reprocess`/`Cancel`, determination `set_admin_fields`, lock/auth master. |
| `ZBP_I_Q2C_ARQ_MGR` | Behavior Pool (global class) | `CR51/ZBP_I_Q2C_ARQ_MGR.clas.txt` | Handler class. Abstract final. FOR BEHAVIOR OF `zi_q2c_arq_mgr`. |
| `ZBP_I_Q2C_ARQ_MGR` CCIMP | Local class in behavior pool | `CR51/ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt` | Contains: `lhc_arq_mgr` (actions + determination), `lhc_log_mgr` (determination), `upsert_log` (private helper). |
| `ZCL_Q2C_CPI_CALLER` | Service class | `CR51/ZCL_Q2C_CPI_CALLER.clas.txt` | HTTP caller for CPI integration. Called directly from behavior pool actions. |

---

### ADMIN SERVICE — ZC Layer → folder `CR51_SVR/`

Objects used exclusively by the **Admin OData service** (`ZSB_Q2C_MGR`).
Purpose: direct data maintenance by support/developers, no UI restrictions.

| Object | Type | File | Description |
|--------|------|------|-------------|
| `ZC_Q2C_ARQ_MGR` | CDS Root Projection View | `CR51_SVR/ZC_Q2C_ARQ_MGR.ddls.txt` | Projection of `ZI_Q2C_ARQ_MGR`. `provider contract transactional_query`. Redirects `_Log` to `ZC_Q2C_LOG_MGR`. |
| `ZC_Q2C_LOG_MGR` | CDS Projection View (child) | `CR51_SVR/ZC_Q2C_LOG_MGR.ddls.txt` | Projection of `ZI_Q2C_LOG_MGR`. No `provider contract`. Redirects `_Arq` to `ZC_Q2C_ARQ_MGR`. |
| `ZC_Q2C_ARQ_MGR` | BDEF (projection) | `CR51_SVR/ZC_Q2C_ARQ_MGR.bdef.txt` | Exposes: `use create; use update; use delete; use association _Log { create; }`. No actions. |
| `ZSD_Q2C_MGR` | Service Definition | `CR51_SVR/ZSD_Q2C_MGR.srvd.txt` | Exposes `ZC_Q2C_ARQ_MGR as ArqMgr` + `ZC_Q2C_LOG_MGR as LogMgr`. |
| `ZSB_Q2C_MGR` | Service Binding (OData V4 UI) | `CR51_SVR/ZSB_Q2C_MGR.srvb.txt` *(reference only)* | Must be created manually in ADT. Requires Publish. |

---

### APP SERVICE — ZC_APP Layer → folder `CR51_APP/`

Objects used exclusively by the **Fiori Elements app** (`ZSB_Q2C_MGR_APP`).
Purpose: reprocessamento workflow — list records, trigger Reprocess or Cancel actions.

| Object | Type | File | Description |
|--------|------|------|-------------|
| `ZC_Q2C_ARQ_MGR_APP` | CDS Root Projection View | `CR51_APP/ZC_Q2C_ARQ_MGR_APP.ddls.txt` | Projection of `ZI_Q2C_ARQ_MGR`. `provider contract transactional_query`. Redirects `_Log` to `ZC_Q2C_LOG_MGR_APP`. |
| `ZC_Q2C_LOG_MGR_APP` | CDS Projection View (child) | `CR51_APP/ZC_Q2C_LOG_MGR_APP.ddls.txt` | Projection of `ZI_Q2C_LOG_MGR`. No `provider contract`. Read-only. |
| `ZC_Q2C_ARQ_MGR_APP` | BDEF (projection) | `CR51_APP/ZC_Q2C_ARQ_MGR_APP.bdef.txt` | Exposes: `use association _Log; use action Reprocess; use action Cancel`. Read-only (no create/update/delete). |
| `ZC_Q2C_ARQ_MGR_APP_MDE` | Metadata Extension (DDLX) | `CR51_APP/ZC_Q2C_ARQ_MGR_APP_MDE.ddlx.txt` | Fiori UI annotations: `@UI.lineItem`, `@UI.facet`, `@UI.selectionField`, action buttons Reprocess/Cancel. |
| `ZC_Q2C_LOG_MGR_APP_MDE` | Metadata Extension (DDLX) | `CR51_APP/ZC_Q2C_LOG_MGR_APP_MDE.ddlx.txt` | UI annotations for Log child: columns Etapa, Mensagem, IdRef, Datum. |
| `ZSD_Q2C_MGR_APP` | Service Definition | `CR51_APP/ZSD_Q2C_MGR_APP.srvd.txt` | Exposes `ZC_Q2C_ARQ_MGR_APP as ArqMgrApp` + `ZC_Q2C_LOG_MGR_APP as LogMgrApp`. |
| `ZSB_Q2C_MGR_APP` | Service Binding (OData V4 UI) | `CR51_APP/ZSB_Q2C_MGR_APP.srvb.txt` *(reference only)* | Must be created manually in ADT. Requires Publish. Entry point for Fiori launchpad. |

---

### AUXILIARY — Standalone Classes → folder `CR51/`

| Object | Type | File | Description |
|--------|------|------|-------------|
| `ZCL_Q2C_REPROCESS_ACTION` | Service class | `CR51/ZCL_Q2C_REPROCESS_ACTION.clas.txt` | Standalone reprocessamento logic for use **outside RAP** (jobs, programs). Not used by the Fiori app. |

---

## Key Architecture Rules

1. **ZI is the single source of truth.** All logic (actions, determinations, field control) lives in the ZI BDEF and its behavior pool. ZC projections only select what to expose.

2. **Two projections = two contracts.** `ZC` (admin) and `ZC_APP` (app) exist because the consumers have different needs. If you had only one consumer, you'd use a single projection.

3. **UI annotations belong in DDLX, not in CDS.** Business annotations (`@ObjectModel`, `@Search`) go in the projection view. Visual annotations (`@UI.lineItem`, `@UI.facet`) go in the Metadata Extension.

4. **Actions are defined once in ZI BDEF.** The projection BDEF only uses `use action Reprocess` — it does not redefine the logic.

5. **Service Bindings cannot be stored as source files.** `ZSB_Q2C_MGR` and `ZSB_Q2C_MGR_APP` must be created and published manually in ADT. The `.srvb.txt` files in this repo are reference documents only.

6. **`ZBP_I_Q2C_ARQ_MGR_APP` does not exist in SAP.** The behavior pool for both services is the same class: `ZBP_I_Q2C_ARQ_MGR`. There is no separate handler for the APP projection.
