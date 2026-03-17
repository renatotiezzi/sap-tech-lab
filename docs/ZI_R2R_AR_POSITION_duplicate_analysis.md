# Duplicate Row Analysis: ZI_R2R_AR_POSITION

**View:** `ZI_R2R_AR_POSITION`  
**Subject:** Accounts Receivable Position  
**Date of Analysis:** 2025-03-17  
**Severity:** Critical — multiple confirmed and probable sources of row multiplication

---

## Executive Summary

The CDS view `ZI_R2R_AR_POSITION` contains **3 confirmed high-severity** and **5 medium-severity** root causes of duplicate rows. The most critical are:

1. `I_BillingDocumentItem` (BillItem) — a 1:N join with **no fields selected**, guaranteed to multiply rows by the number of billing document items.
2. `ZI_R2R_DUEDATEHISTORY` (History) — a history table returning **one row per due-date change event** per document item.
3. `I_BillingDocument` (BillDoc) — joined on a **non-primary-key** condition (`AccountingDocument` is not the PK of the billing document entity).
4. Missing `to one` cardinality constraint on **all 25 joins** — the optimizer cannot protect against unexpected fan-out.

---

## Root Cause Breakdown

### 🔴 P1 — Confirmed Critical Duplicates

---

#### 1. `BillItem` — `I_BillingDocumentItem` (REMOVED in fix)

**Type:** 1:N — guaranteed row multiplication  
**Fields used in SELECT:** None  
**Root cause:**

```sql
-- The join multiplies every BillDoc row by the number of billing items:
left outer join I_BillingDocumentItem as BillItem
  on BillItem.BillingDocument = BillDoc.BillingDocument
```

A billing document (`I_BillingDocument`) always has **multiple items** — header, line items, tax lines, freight, etc. Joining on `BillingDocument` alone (without restricting to a single `BillingDocumentItem`) multiplies every upstream row by the item count.

**Combined with BillDoc fan-out**, the multiplication is: `N billing docs × M items per doc`.

**Worse:** Not a single field from `BillItem` appears in the SELECT clause. This join exists for no output reason and only destroys cardinality.

**Fix:** **Remove the join entirely.**

---

#### 2. `History` — `ZI_R2R_DUEDATEHISTORY` (converted to `to one`)

**Type:** 1:N — history table  
**Fields used in SELECT:** `History.OriginalValue`, `History.CurrentValue`  
**Root cause:**

```sql
left outer join ZI_R2R_DUEDATEHISTORY as History
  on  History.CompanyCode        = Doc.CompanyCode
  and History.AccountingDocument = Doc.AccountingDocument
  and History.FiscalYear         = Doc.FiscalYear
  and History.DocumentItem       = Doc.AccountingDocumentItem
```

A due date history view tracks **every change** to a due date per open item. For an AR item extended 5 times, this join returns 5 rows — multiplying the Doc row 5×.

The SELECT uses `History.OriginalValue` and `History.CurrentValue` in CASE expressions, which expects a single row. The intent is clearly to get the **latest** due date state, not all history records.

**Fix:** The underlying view `ZI_R2R_DUEDATEHISTORY` must be redesigned (if not already) to return only one row per `(CompanyCode, AccountingDocument, FiscalYear, DocumentItem)` — for example by using `MAX` aggregation or a `ROW_NUMBER() = 1` pattern. In this view, add `to one` to make the assumption explicit and enforce it at the CDS layer.

---

#### 3. `BillDoc` — `I_BillingDocument` (converted to `to one`)

**Type:** Potentially 1:N  
**Fields used in SELECT:** `BillDoc.DocumentReferenceID`  
**Root cause:**

```sql
left outer join I_BillingDocument as BillDoc
  on  BillDoc.SoldToParty        = Doc.Customer
  and BillDoc.CompanyCode        = Doc.CompanyCode
  and BillDoc.FiscalYear         = Doc.FiscalYear
  and BillDoc.AccountingDocument = Doc.AccountingDocument
  and TvarvDocType.AccountingDocumentType is not null
```

The primary key of `I_BillingDocument` is `BillingDocument`. The join condition uses `(SoldToParty, CompanyCode, FiscalYear, AccountingDocument)` — **none of which constitutes the PK**. `AccountingDocument` in VBRK is a reference field.

Edge cases where multiple billing documents reference the same FI document:
- Collective invoice reversals
- Debit/credit memo pairs referencing the same original FI document
- Brazilian NF-e reprocessing scenarios

**Fix:** Use `left outer to one join` and validate via:
```sql
SELECT AccountingDocument, CompanyCode, FiscalYear, COUNT(*)
FROM vbrk
GROUP BY AccountingDocument, CompanyCode, FiscalYear
HAVING COUNT(*) > 1
```

---

### 🟠 P2 — Likely Duplicates (Data-Dependent)

---

#### 4. `TaxCNPJ` / `TaxCPF` — `I_Businesspartnertaxnumber`

**Type:** Potentially 1:N  
**Root cause:**

Underlying table `BUT0BEW` has key `(PARTNER, TAXTYPE, TAXNUM)`. This means a business partner **can have multiple tax numbers of the same type** (BR1 = CNPJ, BR2 = CPF). In practice Brazilian tax data is usually clean, but the schema permits duplicates. Any BP with more than one BR1 entry multiplies every row.

**Fix:** Use `left outer to one join`. Validate via:
```sql
SELECT PARTNER, TAXTYPE, COUNT(*) FROM but0bew
WHERE TAXTYPE IN ('BR1','BR2')
GROUP BY PARTNER, TAXTYPE HAVING COUNT(*) > 1
```

---

#### 5. `ItemCatText` — `ZI_R2R_ITEMCAT_VH` (missing language filter)

**Type:** 1:N if the VH view contains language-dependent texts  
**Root cause:**

```sql
-- Missing language restriction:
left outer join ZI_R2R_ITEMCAT_VH as ItemCatText
  on ItemCatText.ItemCategory = ItemCatAux.ItemCategory
```

VH (value help) views often expose texts for **all languages**. Without `AND ItemCatText.Language = TvarvLang.Low`, the join returns one row per available language, multiplying every result row by the number of translated language entries.

**Fix:**
```sql
left outer to one join ZI_R2R_ITEMCAT_VH as ItemCatText
  on  ItemCatText.ItemCategory = ItemCatAux.ItemCategory
  and ItemCatText.Language     = TvarvLang.Low  -- Add language restriction
```

---

#### 6. `AccDocText` — `I_AccountingDocumentTypeText` (invalid language code)

**Type:** Bug — incorrect constant, returns zero rows  
**Root cause:**

```sql
-- BUG: Language 'P' is not a valid SAP language key
and AccDocText.Language = 'P'
```

All other text table joins use `TvarvLang.Low` for the language. This join uses the hardcoded string `'P'`, which is not a valid SAP language ISO code. The valid key for Portuguese is `'PT'` (ISO) or the SAP internal code. This results in **zero rows matching**, so `AccDocText.AccountingDocumentTypeName` is always NULL.

**Fix:** Replace `'P'` with `TvarvLang.Low`:
```sql
and AccDocText.Language = TvarvLang.Low
```

---

### 🟡 P3 — Custom Views Requiring Verification

| Alias | View | Risk | Action Required |
|-------|------|------|----------------|
| `CustSales` | `ZI_R2R_AR_SALES_AUX_TXT` | Medium | Verify uniqueness on `(Customer, CompanyCode, FiscalYear, AccountingDocument)` |
| `Origin` | `ZI_R2R_AR_ORIGIN_VALUE` | Medium | Verify uniqueness on `(CompanyCode, AccountingDocument, FiscalYear, AccountingDocumentItem)` |
| `ItemCatAux` | `ZI_R2R_AR_POSITION_TXT_MIN` | Medium | Verify uniqueness on `(CompanyCode, AccountingDocument, FiscalYear, DocumentItem)` |
| `TvarvDocType` | `ZI_R2R_AR_DOCTYPE_FLAG` | Medium | Verify `AccountingDocumentType` is the sole unique key |

---

### 🟢 P4 — Missing Cardinality Annotations (All 1:1 joins)

The following joins are logically 1:1 but lack `to one` cardinality constraints. This does not currently cause duplicates (assuming clean data), but:
- Prevents the SQL optimizer from applying optimal join strategies
- Leaves the view vulnerable to future data quality issues
- Violates the SAP CDS best practice of documenting join cardinality

**All text joins and master data joins should use `left outer to one join`.**

Affected aliases: `TvarvLang`, `TvarvDocType`, `TvarvFmPagto`, `TvarvFinAcc`, `TvarvKoart`, `Customer`, `Credit`, `GrText`, `CredText`, `Journal`, `DuniText`, `PayBlock`, `AccDocText`, `BuPaCustomer`, `DtExIndtrutKey`, `CustSales`, `Origin`, `ItemCatAux`, `ItemCatText`, `BillDoc`, `TaxCNPJ`, `TaxCPF`, `History`

---

## Complete Priority Summary

| # | Join Alias | Source View | Risk Level | Cause | Fix |
|---|-----------|------------|-----------|-------|-----|
| 1 | `BillItem` | `I_BillingDocumentItem` | 🔴 **HIGH** | 1:N, no fields in SELECT | **Remove join** |
| 2 | `History` | `ZI_R2R_DUEDATEHISTORY` | 🔴 **HIGH** | 1:N history table | `to one` + redesign underlying view |
| 3 | `BillDoc` | `I_BillingDocument` | 🔴 **HIGH** | Join not on PK | `to one` + validate data |
| 4 | `TaxCNPJ` | `I_Businesspartnertaxnumber` | 🟠 **MEDIUM** | Schema allows 1:N | `to one` + validate data |
| 5 | `TaxCPF` | `I_Businesspartnertaxnumber` | 🟠 **MEDIUM** | Schema allows 1:N | `to one` + validate data |
| 6 | `ItemCatText` | `ZI_R2R_ITEMCAT_VH` | 🟠 **MEDIUM** | Missing language filter | Add language filter + `to one` |
| 7 | `AccDocText` | `I_AccountingDocumentTypeText` | 🟠 **MEDIUM** | Invalid language code `'P'` | Replace with `TvarvLang.Low` |
| 8 | `CustSales` | `ZI_R2R_AR_SALES_AUX_TXT` | 🟡 **REVIEW** | Unknown cardinality | Verify + `to one` |
| 9 | `Origin` | `ZI_R2R_AR_ORIGIN_VALUE` | 🟡 **REVIEW** | Unknown cardinality | Verify + `to one` |
| 10 | `ItemCatAux` | `ZI_R2R_AR_POSITION_TXT_MIN` | 🟡 **REVIEW** | Unknown cardinality | Verify + `to one` |
| 11 | `TvarvDocType` | `ZI_R2R_AR_DOCTYPE_FLAG` | 🟡 **REVIEW** | Unknown cardinality | Verify + `to one` |
| 12–25 | All others | Various | 🟢 **LOW** | Missing `to one` annotation | Add `to one` |

---

## Fix Pattern Reference

### Pattern 1: Remove useless 1:N join

```cds
-- BEFORE: multiplies rows, no fields used
left outer join I_BillingDocumentItem as BillItem
  on BillItem.BillingDocument = BillDoc.BillingDocument

-- AFTER: removed completely
-- (no replacement — BillItem fields were never in SELECT)
```

### Pattern 2: Enforce single-row cardinality

```cds
-- BEFORE: no cardinality hint, vulnerable to fan-out
left outer join I_DunningAreaText as DuniText
  on  DuniText.CompanyCode = Doc.CompanyCode
  and DuniText.DunningArea = Doc.DunningArea
  and DuniText.Language    = TvarvLang.Low

-- AFTER: cardinality enforced
left outer to one join I_DunningAreaText as DuniText
  on  DuniText.CompanyCode = Doc.CompanyCode
  and DuniText.DunningArea = Doc.DunningArea
  and DuniText.Language    = TvarvLang.Low
```

### Pattern 3: Fix missing language filter (VH views)

```cds
-- BEFORE: returns all languages, multiplies rows
left outer join ZI_R2R_ITEMCAT_VH as ItemCatText
  on ItemCatText.ItemCategory = ItemCatAux.ItemCategory

-- AFTER: language-qualified + single row
left outer to one join ZI_R2R_ITEMCAT_VH as ItemCatText
  on  ItemCatText.ItemCategory = ItemCatAux.ItemCategory
  and ItemCatText.Language     = TvarvLang.Low
```

### Pattern 4: Fix wrong constant

```cds
-- BEFORE: 'P' is not a valid SAP language key — returns zero rows
and AccDocText.Language = 'P'

-- AFTER: uses dynamic language variable
and AccDocText.Language = TvarvLang.Low
```

---

## Debugging Recommendations

To confirm duplicates at runtime before and after the fix:

```abap
" Check for duplicates in result set:
SELECT CompanyCode, FiscalYear, AccountingDocument, AccountingDocumentItem,
       COUNT(*) AS row_count
  FROM ZI_R2R_AR_POSITION( p_status = 'T' )
  GROUP BY CompanyCode, FiscalYear, AccountingDocument, AccountingDocumentItem
  HAVING COUNT(*) > 1
  ORDER BY row_count DESCENDING
  INTO TABLE @DATA(lt_dupes).

" Validate BillingDocumentItem fan-out:
SELECT vbrk~vbeln, COUNT(*) AS item_count
  FROM vbrk INNER JOIN vbrp ON vbrk~vbeln = vbrp~vbeln
  WHERE vbrk~bukrs = '<CompanyCode>'
  GROUP BY vbrk~vbeln
  HAVING COUNT(*) > 1.

" Validate due date history cardinality:
SELECT bukrs, belnr, gjahr, buzei, COUNT(*) AS history_rows
  FROM <history_table>
  GROUP BY bukrs, belnr, gjahr, buzei
  HAVING COUNT(*) > 1.
```

**Relevant SAP tables for debugging:**
- `BKPF` / `BSEG` — FI document header/items
- `VBRK` / `VBRP` — Billing document header/items
- `BUT0BEW` — Business partner tax numbers
- `T001F` — Payment blocking reasons
- `TVARVC` — Table of variants / config parameters (backing `ZI_R2R_TVARV`)

---

## Additional Note: Hardcoded Customer Filter

The following line in the WHERE clause appears to be a **development/debug filter** left accidentally in the view:

```cds
and Customer.Customer = '0040000361'
```

A production CDS view for AR Positions should not hardcode a customer number. This filter restricts the view to a single customer and must be removed before transport to production.

---

*Analysis produced by SAP ABAP technical review. Refer to corrected view `ZI_R2R_AR_POSITION.ddls.asddls` for the applied fixes.*
