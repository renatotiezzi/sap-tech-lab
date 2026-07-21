# ATC Priority-1 Refactoring Guide
## `ZCLQM_CONTROLE_BATELADA` – ABAP Cloud Compliance

---

## Table of Contents

1. [Overview](#overview)
2. [Finding Map – What Changed and Why](#finding-map)
3. [TVARVC → CL_SVARV](#1-tvarvc--cl_svarv)
4. [CAUFV → I_ManufacturingOrder](#2-caufv--i_manufacturingorder)
5. [QALS → I_InspectionLot](#3-qals--i_inspectionlot)
6. [QAVE → I_InspResultUsageDecision](#4-qave--i_inspresultusagedecision)
7. [QAPO / QAPP / Unreleased Table Types](#5-qapo--qapp--unreleased-table-types)
8. [CONSTANTS Type Fixes](#6-constants-type-fixes)
9. [SELECT Syntax (Open SQL Host Variables)](#7-select-syntax-open-sql-host-variables)
10. [IF_EX_QE_SAVE → BAdI](#8-if_ex_qe_save--badi)
11. [ZC_S2M_BATELADA BDEF – strict ( 2 )](#9-zc_s2m_batelada-bdef--strict--2-)
12. [Validation Checklist](#validation-checklist)
13. [Debugging Tips](#debugging-tips)

---

## Overview

All changes target **ATC Priority 1** findings raised by the SAP ABAP Test Cockpit
in a restricted language scope (ABAP Cloud / BTP ABAP Environment).

| File | Changes |
|------|---------|
| `src/ZCLQM_CONTROLE_BATELADA.abap` | 9× Open SQL, 4× TVARVC, 3× CAUFV, 5× QALS, 4× QAVE, QAPO/QAPP/unreleased types, CONSTANTS |
| `src/ZCL_IM_BD_S2M_QE_SAVE.abap` | IF_EX_QE_SAVE → BAdI, GET REFERENCE OF, SY-UCOMM |
| `src/ZC_S2M_BATELADA.bdef` | strict ( 2 ) activation |

---

## Finding Map

| # | ATC Message | Count | Root Cause | Fix |
|---|-------------|-------|------------|-----|
| 1 | Open SQL syntax (no host vars) | 9 | Old-style SELECT without `@` prefix | Add `@` to all host variables; use `INTO @DATA(...)` |
| 2 | TVARVC not released (BC-ABA-TO) | 4 | Direct `SELECT FROM tvarvc` | `CL_SVARV=>GET_VARIANTS_BY_SELOPT` |
| 3 | CAUFV not released (PP-SFC, CO) | 3 | Direct `SELECT FROM caufv` | CDS View `I_ManufacturingOrder` |
| 4 | QALS not released (QM-IM) | 5 | Direct `SELECT FROM qals` | CDS View `I_InspectionLot` |
| 5 | QAVE not released (QM-IM-UD) | 4 | Direct `SELECT FROM qave` | CDS View `I_InspResultUsageDecision` |
| 6 | QAPO not released (QM-IM-RR) | 5 | Method param `TYPE qapo` | Remove unused param; use generic `REF TO data` in container |
| 7 | QAPP not released (QM-IM) | 2 | Method param `TYPE qapp` | Remove unused param |
| 8 | Unreleased type refs | 4 | `TYPE qamkrtab / qasprtab / qasertab / qaklrtab` | Remove unused CHANGING params |
| 9 | IF_EX_QE_SAVE not released | 1 | Classic exit interface | Replace with `IF_BADI_INTERFACE` |
| 10 | BDEF not strict(2) | 1 | Missing `strict ( 2 )` declaration | Add `strict ( 2 )` to BDEF header |

---

## 1. TVARVC → CL_SVARV

### Why TVARVC is blocked

`TVARVC` belongs to component `BC-ABA-TO` (Basis – ABAP – Table Maintenance).
This component is **not released** for customer / partner development in
ABAP Cloud. Any `SELECT FROM tvarvc` raises an ATC Priority-1 finding.

### Before (4 occurrences)

```abap
" ❌ ATC Priority 1 – TVARVC not released
SELECT sign, opti, low, high
  FROM tvarvc
  INTO TABLE @DATA(lt_tvarv_zordembatelada)
 WHERE name = 'ZS2M126_BATTPOP'.
```

### After

```abap
" ✅ CL_SVARV is the released API for reading TVARVC selection options
DATA lt_selopt_auart TYPE rsds_selopt_t.
CL_SVARV=>GET_VARIANTS_BY_SELOPT(
  EXPORTING iv_name   = 'ZS2M126_BATTPOP'
  IMPORTING et_selopt = lt_selopt_auart ).

" lt_selopt_auart is range-compatible; use directly with IN operator:
IF ls_order-auart IN lt_selopt_auart.
  ...
ENDIF.
```

### Field mapping

| TVARVC field | rsds_selopt field | Notes |
|---|---|---|
| `sign` | `sign` | `S` / `I` / `E` |
| `opti` | `option` | `EQ`, `BT`, `CP`, … |
| `low` | `low` | `CHAR 45` – implicit conversion |
| `high` | `high` | `CHAR 45` – implicit conversion |

> **Note:** `rsds_selopt-low/high` are `CHAR 45`. ABAP performs implicit
> conversion when evaluating `lv_auart IN lt_selopt`. This is safe for
> short fixed-length fields like `AUART (CHAR 4)` and `WERKS_D (CHAR 4)`.

### Fallback (if CL_SVARV is not available in your release)

If your SAP release does not yet ship `CL_SVARV`, the ABAP-approved
alternative is to encapsulate the TVARVC access behind a local helper
method and suppress the individual finding with a justified pragma:

```abap
METHOD get_selopt.
  " ##SUPPRESS_ATC REASON: CL_SVARV not available in this release.
  "   Reading TVARVC via direct SELECT is the only available option.
  "   Tracked under incident INC-XXXXX for upgrade.
  SELECT sign, opti, low, high
    FROM tvarvc
    INTO CORRESPONDING FIELDS OF TABLE @rt_selopt
   WHERE name = @iv_variable_name
     AND type = 'S'.                                 "#EC CI_BYPASS
ENDMETHOD.
```

---

## 2. CAUFV → I_ManufacturingOrder

### Why CAUFV is blocked

`CAUFV` is a database view joining several CO/PP tables. Components
`PP-SFC` and `CO` are not released for direct SQL access in ABAP Cloud.

### Before (3 occurrences)

```abap
" ❌ ATC Priority 1 – CAUFV not released
SELECT SINGLE aufnr, stlnr, stlan, stlal, auart, werks
  FROM caufv
  INTO @DATA(ls_caufv)
 WHERE aufnr = @is_qals-aufnr.
```

### After

```abap
" ✅ I_ManufacturingOrder is released for ABAP Cloud (PP-SFC)
SELECT SINGLE
       manufacturingorder        AS aufnr,
       billofmaterial            AS stlnr,
       billofmaterialvariantusage AS stlan,
       billofmaterialvariant     AS stlal,
       manufacturingordertype    AS auart,
       plant                     AS werks
  FROM i_manufacturingorder
  INTO @DATA(ls_order)
 WHERE manufacturingorder = @is_qals-aufnr.
```

### Field mapping

| CAUFV | I_ManufacturingOrder | Type |
|---|---|---|
| `AUFNR` | `ManufacturingOrder` | `AUFNR` |
| `STLNR` | `BillOfMaterial` | `CHAR 8` |
| `STLAN` | `BillOfMaterialVariantUsage` | `CHAR 1` |
| `STLAL` | `BillOfMaterialVariant` | `CHAR 2` |
| `AUART` | `ManufacturingOrderType` | `CHAR 4` |
| `WERKS` | `Plant` | `WERKS_D` |
| `ERDAT` | `CreationDate` | `DATUM` |

> **Verify field names** in your SAP release using transaction `SEGW` or
> the ABAP Development Tools CDS source viewer for `I_ManufacturingOrder`.
> Field names are CDS annotations and may differ by release.

---

## 3. QALS → I_InspectionLot

### Why QALS is blocked

Table `QALS` belongs to component `QM-IM` (Quality Management – Inspection).
Not released for customer direct SQL access in ABAP Cloud.

### Before (5 occurrences – here the FAE example)

```abap
" ❌ ATC Priority 1 – QALS not released
SELECT prueflos, aufnr
  FROM qals
  INTO TABLE @DATA(lt_lista_lote_qm)
   FOR ALL ENTRIES IN @lt_lista_ordens_fae
 WHERE aufnr = @lt_lista_ordens_fae-aufnr
   AND art   = @gc_04.
```

### After

```abap
" ✅ I_InspectionLot is released for ABAP Cloud (QM-IM)
SELECT inspectionlot      AS prueflos,
       manufacturingorder AS aufnr
  FROM i_inspectionlot
  INTO TABLE @DATA(lt_lista_lote_qm)
   FOR ALL ENTRIES IN @lt_lista_ordens
 WHERE manufacturingorder  = @lt_lista_ordens-aufnr
   AND inspectionlotorigin = @gc_04.
```

### Field mapping

| QALS | I_InspectionLot | Notes |
|---|---|---|
| `PRUEFLOS` | `InspectionLot` | 12-char lot number |
| `AUFNR` | `ManufacturingOrder` | Linked production order |
| `ART` | `InspectionLotOrigin` | '04' = PP order-related |
| `MATNR` | `Material` | Material number |
| `WERK` | `Plant` | Plant |
| `ENSTEHDAT` | `InspectionLotCreationDate` | Creation date |

---

## 4. QAVE → I_InspResultUsageDecision

### Why QAVE is blocked

Table `QAVE` belongs to component `QM-IM-UD` (Usage Decision). Not released.

### Before (4 occurrences)

```abap
" ❌ ATC Priority 1 – QAVE not released
SELECT prueflos, kzart, zaehler
  FROM qave
  INTO TABLE @DATA(lt_qave_result)
   FOR ALL ENTRIES IN @lt_lista_lote_qm_fae
 WHERE prueflos   = @lt_lista_lote_qm_fae-prueflos
   AND vbewertung = @gc_a
   AND vdatum     IN @lt_interval_vdatum.
```

### After

```abap
" ✅ I_InspResultUsageDecision is released for ABAP Cloud (QM-IM-UD)
SELECT inspectionlot         AS prueflos,
       usagedecisioncategory AS kzart,
       usagedecisionitem     AS zaehler
  FROM i_inspresultusagedecision
  INTO TABLE @DATA(lt_qave_result)
   FOR ALL ENTRIES IN @lt_lista_lote_qm_fae
 WHERE inspectionlot           = @lt_lista_lote_qm_fae-prueflos
   AND qualinspresultvaluation = @gc_a
   AND usagedecisiondate       IN @lt_interval_vdatum.
```

### Field mapping

| QAVE | I_InspResultUsageDecision | Notes |
|---|---|---|
| `PRUEFLOS` | `InspectionLot` | Lot number |
| `VBEWERTUNG` | `QualInspResultValuation` | 'A' = Accepted |
| `VDATUM` | `UsageDecisionDate` | Decision date |
| `KZART` | `UsageDecisionCategory` | Decision category |
| `ZAEHLER` | `UsageDecisionItem` | Item counter |

---

## 5. QAPO / QAPP / Unreleased Table Types

### Problem

The original `check` and `save` methods declared parameters typed with
unreleased DDIC references:

```abap
" ❌ Unreleased type references in method signatures
METHODS check
  IMPORTING !is_qals TYPE qals         " → qals not released
  CHANGING
    !cs_qapo TYPE qapo                 " → qapo not released (QM-IM-RR)
    !cs_qapp TYPE qapp                 " → qapp not released (QM-IM)
    !ct_qamk TYPE qamkrtab             " → qamkrtab not released
    !ct_qasp TYPE qasprtab             " → qasprtab not released
    !ct_qase TYPE qasertab             " → qasertab not released
    !ct_qakl TYPE qaklrtab.            " → qaklrtab not released
```

### Analysis

None of these CHANGING parameters were **read or written** in the method
body. They existed only as pass-through parameters from the enhancement
framework. Keeping them added unreleased type dependencies with zero benefit.

### Fix

Remove all unused parameters and define a local type for `is_qals`:

```abap
" ✅ Only the fields actually consumed are declared in a local type
TYPES:
  BEGIN OF ty_qals_data,
    prueflos  TYPE c LENGTH 12,
    aufnr     TYPE aufnr,
    matnr     TYPE matnr,
    werk      TYPE werks_d,
    enstehdat TYPE datum,
  END OF ty_qals_data.

METHODS check
  IMPORTING !is_qals TYPE ty_qals_data
  EXPORTING !ev_saving_allowed TYPE c.
```

The public `ty_container` type retains `REF TO data` for all fields, so
the framework can still pass QAPO/QAPP data generically without ATC findings.

---

## 6. CONSTANTS Type Fixes

### Before

```abap
" ❌ References to unreleased DDIC type fields
CONSTANTS gc_04 TYPE qals-art       VALUE '04' ##NO_TEXT.
CONSTANTS gc_a  TYPE qave-vbewertung VALUE 'A'  ##NO_TEXT.
```

### After

```abap
" ✅ Literal type definitions – no DDIC type references
CONSTANTS gc_04 TYPE c LENGTH 2 VALUE '04' ##NO_TEXT.  " Inspection lot origin
CONSTANTS gc_a  TYPE c LENGTH 1 VALUE 'A'  ##NO_TEXT.  " Accepted valuation
```

---

## 7. SELECT Syntax (Open SQL Host Variables)

ABAP Cloud requires all host variables in Open SQL to be prefixed with `@`.
Inline declarations must use `@DATA(...)` or `@FINAL(...)`.

### Before (9 occurrences – example)

```abap
" ❌ Old syntax: no @ prefix, no INTO for COUNT
SELECT COUNT( * ) FROM ztbqmbatelada
  WHERE matnr = is_qals-matnr          " ← missing @
    AND werks = is_qals-werk.
IF sy-subrc IS INITIAL. ...            " ← COUNT always returns sy-subrc=0
```

### After

```abap
" ✅ Modern syntax: @ prefix, COUNT with INTO @DATA
SELECT COUNT(*) FROM ztbqmbatelada
  WHERE matnr = @is_qals-matnr
    AND werks = @is_qals-werk
    AND stlnr = @ls_order-stlnr
  INTO @DATA(lv_count).

IF lv_count > 0.  " ← checks actual row count
  ...
ENDIF.
```

> **Logic fix note:** The original `SELECT COUNT(*) ... IF sy-subrc IS INITIAL`
> pattern was also **logically incorrect**: `sy-subrc` after `SELECT COUNT(*)`
> is always `0` (the aggregate always returns one row). The correct check is
> against the returned count value (`lv_count > 0`).

---

## 8. IF_EX_QE_SAVE → BAdI

### Why IF_EX_QE_SAVE is blocked

`IF_EX_QE_SAVE` is the interface of classic function-module user exit
`EXIT_SAPLQE03_004` (Enhancement `QE0003`). Classic enhancement spots are
not released for ABAP Cloud.

### Migration Steps

1. **Find the BAdI** – In SE18 search for `BADI_QM` or `QM_RESULT` to locate
   the released BAdI that replaces EXIT_SAPLQE03_004 in your SAP release.
   Common candidates: `BADI_QM_RESULTS_SAVE`, `QM_RESULT_REC`.

2. **Change the class definition:**

   ```abap
   " ❌ Before
   CLASS zcl_im_bd_s2m_qe_save DEFINITION ...
     PUBLIC SECTION.
       INTERFACES if_ex_qe_save.        " ← classic exit, not released

   " ✅ After
   CLASS zcl_im_bd_s2m_qe_save DEFINITION ...
     PUBLIC SECTION.
       INTERFACES if_badi_interface.    " ← marks class as BAdI impl
       INTERFACES if_ex_badi_qm_results_save~before_save.  " ← BAdI interface
   ```

3. **Fix GET REFERENCE OF:**

   ```abap
   " ❌ Before (syntax not permitted in restricted scope)
   GET REFERENCE OF ls_batelada INTO DATA(lr_ref).

   " ✅ After
   DATA(lr_ref) = REF #( ls_batelada ).
   ```

4. **Fix SY-UCOMM:**

   ```abap
   " ❌ Before (SY-UCOMM not available in BAdI / Cloud context)
   IF sy-ucomm = 'SICH'.

   " ✅ After – action is passed explicitly by the BAdI framework
   IF iv_action = 'SAVE' OR iv_action = 'SICH'.
   ```

5. **Register the implementation** in SE19 (or ADT BAdI spot):
   BAdI name → your BAdI, Implementation class → `ZCL_IM_BD_S2M_QE_SAVE`.

---

## 9. ZC_S2M_BATELADA BDEF – strict ( 2 )

### Why strict ( 2 ) is required

ATC check **"Strict mode level 2 not active"** fires for RAP behavior
definitions that do not declare the strictest rule set. `strict ( 2 )` is
mandatory for new development in ABAP Cloud.

### Before

```abap
managed implementation in class zbp_c_s2m_batelada unique;
" ← no strict mode declared
define behavior for ZC_S2M_BATELADA ...
```

### After

```abap
managed implementation in class zbp_c_s2m_batelada unique;
strict ( 2 );          "← Added: activates all strict-mode checks
define behavior for ZC_S2M_BATELADA ...
```

### What strict ( 2 ) enforces

| Rule | Description |
|---|---|
| All features explicit | Every CRUD operation must be declared; no implicit defaults |
| Inline result for actions | `result [1] $self` or typed result required |
| No implicit table buffering bypass | Must declare `lock` and `authorization` explicitly |
| Enhanced syntax checks | Stricter CDS BDL parsing aligned with ABAP Cloud |

---

## Validation Checklist

After applying all changes, verify the following in your ABAP development environment:

- [ ] Run ATC on `ZCLQM_CONTROLE_BATELADA` – zero Priority-1 findings
- [ ] Run ATC on `ZCL_IM_BD_S2M_QE_SAVE` – zero Priority-1 findings
- [ ] Activate `ZC_S2M_BATELADA.bdef` – no syntax errors with `strict ( 2 )`
- [ ] Verify `I_ManufacturingOrder` field names in your SAP release (SE16N / ADT)
- [ ] Verify `I_InspectionLot` field names in your SAP release
- [ ] Verify `I_InspResultUsageDecision` field names in your SAP release
- [ ] Confirm `CL_SVARV=>GET_VARIANTS_BY_SELOPT` exists in your release (SE24)
- [ ] Confirm the BAdI name replacing `IF_EX_QE_SAVE` (SE18)
- [ ] Re-register `ZCL_IM_BD_S2M_QE_SAVE` in SE19 under the new BAdI
- [ ] Execute unit / integration tests for the `check` and `save` flows
- [ ] Verify `ZTBQMBATELADA` custom table is accessible and structure matches
- [ ] Verify `ZTTS2M_RQEVP` custom type exists and is accessible

---

## Debugging Tips

### check / save logic

| Scenario | Breakpoint / Check |
|---|---|
| Order not found | After `SELECT SINGLE FROM i_manufacturingorder` – inspect `sy-subrc` |
| TVARVC range empty | In `get_selopt` – inspect `rt_selopt` after `CL_SVARV` call |
| IN check fails | Inspect `ls_order-auart` vs `lt_selopt_auart` values |
| No inspection lots | After FAE SELECT from `i_inspectionlot` – check `lt_lista_lote_qm` |
| No usage decisions | After FAE SELECT from `i_inspresultusagedecision` – check `lt_qave_result` |
| MODIFY fails | Inspect `sy-subrc` after `MODIFY ztbqmbatelada` |

### Relevant transactions

| Transaction | Purpose |
|---|---|
| `SE16N` | Inspect ZTBQMBATELADA content |
| `SE18` | Browse BAdI definitions (find BAdI replacing IF_EX_QE_SAVE) |
| `SE19` | Register/inspect BAdI implementations |
| `SE24` | Inspect CL_SVARV methods and signature |
| `QA03` | Display inspection lot (replaces direct QALS read) |
| `CO03` | Display manufacturing order (replaces direct CAUFV read) |
| `SATC` | Run ATC checks |
| `SCMON` | Monitor custom code in ABAP Cloud context |

---

*Generated as part of ATC Priority-1 clean-up for ZCLQM_CONTROLE_BATELADA.*
*All CDS view field names should be verified against the target SAP release.*
