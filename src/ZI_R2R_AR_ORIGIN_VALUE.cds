@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Original Invoice Value - Chain Walk'
@Metadata.ignorePropagatedAnnotations: true

// =====================================================================================
// View   : ZI_R2R_AR_ORIGIN_VALUE
// Purpose: Resolves the original invoice amount for any accounting document item by
//          following the invoice-reference chain (BSEG-REBZG / REBZJ / REBZZ) back
//          to the root original invoice, and returns that root document's amount in
//          company code currency.
//
// Spec requirement (chain-walk logic):
//   1. Start from the given document item
//      (CompanyCode / AccountingDocument / FiscalYear / AccountingDocumentItem).
//   2. Perform a SELECT on I_OperationalAcctgDocItem using the invoice reference fields
//      as the new key:
//        Empresa          → CompanyCode         (unchanged)
//        Lançamento cont. → AccountingDocument  = InvoiceReference         (BSEG-REBZG)
//        Exercício        → FiscalYear          = InvoiceReferenceFiscalYear (BSEG-REBZJ)
//        Item             → AccountingDocumentItem = InvoiceItemReference   (BSEG-REBZZ)
//   3. On the newly found record, check whether the reference fields are filled AND
//      FollowOnDocumentType = 'V' (BSEG-REBZT):
//        - If ANY reference field is EMPTY, or FollowOnDocumentType ≠ 'V'
//          → this record is the root original invoice
//          → OriginalInvoiceAmount = AmountInCompanyCodeCurrency (BSEG-DMBTR) of THIS record.
//        - If ALL reference fields are FILLED AND FollowOnDocumentType = 'V'
//          → repeat step 2 with the new values found.
//   4. Repeat until the stop condition is reached.
//      OriginalInvoiceAmount = AmountInCompanyCodeCurrency of the LAST SELECT performed.
//
// Implementation note:
//   CDS views do not support procedural loops; the chain walk is implemented as a
//   series of up to four LEFT OUTER JOINs on I_OperationalAcctgDocItem (L0 → L4).
//   This covers all real-world SAP residual-item chains (typically 1-2 hops deep).
//   The CASE expression selects the amount from the first level in the chain where the
//   stop condition is met (reference fields empty or FollowOnDocumentType ≠ 'V').
//
// Field mapping at each hop:
//   Level L0 : the document item supplied by the caller (anchor)
//   Level L1 : document pointed to by L0's reference fields (hop 1)
//   Level L2 : document pointed to by L1's reference fields (hop 2)
//   Level L3 : document pointed to by L2's reference fields (hop 3)
//   Level L4 : document pointed to by L3's reference fields (hop 4 / safety ceiling)
//
// Consumer: ZI_R2R_AR_POSITION (left outer join aliased as "Origin")
//   Origin.CompanyCode            = Doc.CompanyCode
//   Origin.AccountingDocument     = Doc.AccountingDocument
//   Origin.FiscalYear             = Doc.FiscalYear
//   Origin.AccountingDocumentItem = Doc.AccountingDocumentItem
//   → used as: Origin.OriginalInvoiceAmount as OriginalAmount
// =====================================================================================

define view entity ZI_R2R_AR_ORIGIN_VALUE
  as select from I_OperationalAcctgDocItem as L0

    // -----------------------------------------------------------------------------------
    // Hop 1  (spec step 2, first iteration)
    // SELECT on I_OperationalAcctgDocItem WHERE:
    //   CompanyCode            = L0.CompanyCode               (Empresa - unchanged)
    //   AccountingDocument     = L0.InvoiceReference          (Lançamento cont. ← REBZG)
    //   FiscalYear             = L0.InvoiceReferenceFiscalYear (Exercício       ← REBZJ)
    //   AccountingDocumentItem = L0.InvoiceItemReference      (Item             ← REBZZ)
    // -----------------------------------------------------------------------------------
    left outer join I_OperationalAcctgDocItem as L1
      on  L1.CompanyCode            = L0.CompanyCode
      and L1.AccountingDocument     = L0.InvoiceReference
      and L1.FiscalYear             = L0.InvoiceReferenceFiscalYear
      and L1.AccountingDocumentItem = L0.InvoiceItemReference

    // -----------------------------------------------------------------------------------
    // Hop 2  (spec step 2, second iteration — only reached when L0 was a residual item)
    // SELECT on I_OperationalAcctgDocItem WHERE:
    //   CompanyCode            = L1.CompanyCode
    //   AccountingDocument     = L1.InvoiceReference
    //   FiscalYear             = L1.InvoiceReferenceFiscalYear
    //   AccountingDocumentItem = L1.InvoiceItemReference
    // -----------------------------------------------------------------------------------
    left outer join I_OperationalAcctgDocItem as L2
      on  L2.CompanyCode            = L1.CompanyCode
      and L2.AccountingDocument     = L1.InvoiceReference
      and L2.FiscalYear             = L1.InvoiceReferenceFiscalYear
      and L2.AccountingDocumentItem = L1.InvoiceItemReference

    // -----------------------------------------------------------------------------------
    // Hop 3  (spec step 2, third iteration)
    // -----------------------------------------------------------------------------------
    left outer join I_OperationalAcctgDocItem as L3
      on  L3.CompanyCode            = L2.CompanyCode
      and L3.AccountingDocument     = L2.InvoiceReference
      and L3.FiscalYear             = L2.InvoiceReferenceFiscalYear
      and L3.AccountingDocumentItem = L2.InvoiceItemReference

    // -----------------------------------------------------------------------------------
    // Hop 4  (spec step 2, fourth iteration — safety ceiling)
    // -----------------------------------------------------------------------------------
    left outer join I_OperationalAcctgDocItem as L4
      on  L4.CompanyCode            = L3.CompanyCode
      and L4.AccountingDocument     = L3.InvoiceReference
      and L4.FiscalYear             = L3.InvoiceReferenceFiscalYear
      and L4.AccountingDocumentItem = L3.InvoiceItemReference

{
  // Keys: the STARTING document item (anchor — matched by ZI_R2R_AR_POSITION)
  key L0.CompanyCode            as CompanyCode,
  key L0.AccountingDocument     as AccountingDocument,
  key L0.FiscalYear             as FiscalYear,
  key L0.AccountingDocumentItem as AccountingDocumentItem,

      // ---------------------------------------------------------------------------------
      // Field : OriginalInvoiceAmount
      // Purpose: Amount in company code currency of the ROOT original invoice found by
      //          walking the residual-item chain to its end.
      //
      // Spec stop condition (checked at each level):
      //   InvoiceReference is initial
      //   OR InvoiceReferenceFiscalYear is initial
      //   OR InvoiceItemReference       is initial
      //   OR FollowOnDocumentType       <> 'V'
      //   → this level IS the root original invoice → take its AmountInCompanyCodeCurrency.
      //
      // CASE branches (first matching branch wins):
      //   WHEN L0 stop condition → L0 is the original  → L0.AmountInCompanyCodeCurrency
      //   WHEN L1 stop condition → L1 is the original  → L1.AmountInCompanyCodeCurrency
      //   WHEN L2 stop condition → L2 is the original  → L2.AmountInCompanyCodeCurrency
      //   WHEN L3 stop condition → L3 is the original  → L3.AmountInCompanyCodeCurrency
      //   ELSE                   → L4 is the ceiling   → L4.AmountInCompanyCodeCurrency
      //                            (coalesce guards against data inconsistency)
      // ---------------------------------------------------------------------------------
      @Semantics: { amount : {currencyCode: 'Currency'} }
      case
        // Stop at L0: L0 itself is the root original invoice (no invoice reference chain).
        // Spec: "Se os campos estiverem vazios, Montante recebe AmountInCompanyCodeCurrency
        //        deste último select."
        when L0.InvoiceReference           is initial
          or L0.InvoiceReferenceFiscalYear is initial
          or L0.InvoiceItemReference       is initial
          or L0.FollowOnDocumentType       <> 'V'
        then L0.AmountInCompanyCodeCurrency

        // Stop at L1: L0 was a residual; L1 is the root.
        when L1.InvoiceReference           is initial
          or L1.InvoiceReferenceFiscalYear is initial
          or L1.InvoiceItemReference       is initial
          or L1.FollowOnDocumentType       <> 'V'
        then coalesce( L1.AmountInCompanyCodeCurrency, L0.AmountInCompanyCodeCurrency )

        // Stop at L2: L1 was also a residual; L2 is the root.
        // coalesce falls back to L0 (not L1) because L1 was already confirmed as a
        // residual item (non-root) by the previous WHEN branch.
        when L2.InvoiceReference           is initial
          or L2.InvoiceReferenceFiscalYear is initial
          or L2.InvoiceItemReference       is initial
          or L2.FollowOnDocumentType       <> 'V'
        then coalesce( L2.AmountInCompanyCodeCurrency, L0.AmountInCompanyCodeCurrency )

        // Stop at L3: L2 was also a residual; L3 is the root.
        when L3.InvoiceReference           is initial
          or L3.InvoiceReferenceFiscalYear is initial
          or L3.InvoiceItemReference       is initial
          or L3.FollowOnDocumentType       <> 'V'
        then coalesce( L3.AmountInCompanyCodeCurrency, L2.AmountInCompanyCodeCurrency )

        // Safety ceiling (hop 4): take L4's amount; fall back up the chain if NULL.
        else coalesce( L4.AmountInCompanyCodeCurrency,
                       L3.AmountInCompanyCodeCurrency,
                       L2.AmountInCompanyCodeCurrency,
                       L1.AmountInCompanyCodeCurrency,
                       L0.AmountInCompanyCodeCurrency )
      end                       as OriginalInvoiceAmount,

      L0.CompanyCodeCurrency    as Currency
}
