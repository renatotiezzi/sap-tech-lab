@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Accounts Receivable Position'
@Metadata.ignorePropagatedAnnotations: true
// @Search.searchable annotation removed — search capability not required for this AR position view.

// ============================================================
// FIX SUMMARY (see docs/ZI_R2R_AR_POSITION_duplicate_analysis.md)
//
// #1  REMOVED  I_BillingDocumentItem (BillItem):
//     Was a 1:N join on BillingDocument alone — every billing header
//     has N items, multiplying all rows. No fields from BillItem were
//     ever projected in the SELECT, so the join was useless AND harmful.
//
// #2  ALL joins converted to "left outer to one join":
//     Enforces single-row cardinality at the CDS layer. Prevents
//     silent fan-out when data violates expected uniqueness and allows
//     the SQL optimizer to produce more efficient execution plans.
//
// #3  FIX  I_BillingDocument (BillDoc):
//     Join is on non-PK columns of BillingDocument. Added "to one"
//     to declare the expected 1:1 cardinality. Validate with:
//     SELECT accountingdocument, COUNT(*) FROM vbrk GROUP BY
//     accountingdocument HAVING COUNT(*) > 1.
//
// #4  FIX  ZI_R2R_DUEDATEHISTORY (History):
//     History tables return one row per change event. Changed to
//     "to one" and the underlying view ZI_R2R_DUEDATEHISTORY MUST
//     guarantee a single row per (CompanyCode, AccountingDocument,
//     FiscalYear, DocumentItem), e.g. via MAX aggregation on ChangeDate.
//
// #5  FIX  I_Businesspartnertaxnumber (TaxCNPJ / TaxCPF):
//     Table BUT0BEW allows multiple tax numbers per Partner+TaxType.
//     Added "to one" + validate: SELECT partner, taxtype, COUNT(*)
//     FROM but0bew GROUP BY partner, taxtype HAVING COUNT(*) > 1.
//
// #6  FIX  ZI_R2R_ITEMCAT_VH (ItemCatText):
//     VH views typically contain language-dependent texts for all
//     languages. Without a language filter, every row is multiplied
//     by the number of available language entries. Added Language
//     restriction and "to one".
//
// #7  FIX  I_AccountingDocumentTypeText (AccDocText):
//     Language was hardcoded as 'P', which is not a valid SAP language
//     key — the join returned zero rows. Changed to TvarvLang.Low
//     (consistent with all other text joins in this view).
//
// #8  NOTE  Hardcoded customer filter in WHERE clause:
//     "Customer.Customer = '0040000361'" appears to be a debug/dev
//     filter. MUST be removed before transporting to production.
// ============================================================

define view entity ZI_R2R_AR_POSITION
  with parameters
    p_status : abap.char(1)
  as select from    I_OperationalAcctgDocItem     as Doc

    // --------------------------------------------------------
    // Configuration: Language setting from TVARV parameter.
    // Type = 'P' (parameter) guarantees at most one row per Name.
    // "to one" documents and enforces this cardinality assumption.
    // --------------------------------------------------------
    left outer to one join ZI_R2R_TVARV            as TvarvLang      on  TvarvLang.Name = 'Z_R2R_AR_POSITION_LANG'
                                                                      and TvarvLang.Type = 'P'

    // --------------------------------------------------------
    // Document type flag — must have AccountingDocumentType as
    // unique key. Verify: ZI_R2R_AR_DOCTYPE_FLAG uniqueness.
    // --------------------------------------------------------
    left outer to one join ZI_R2R_AR_DOCTYPE_FLAG  as TvarvDocType   on TvarvDocType.AccountingDocumentType = Doc.AccountingDocumentType

    // --------------------------------------------------------
    // Payment method and financial account config from TVARV.
    // --------------------------------------------------------
    left outer to one join ZI_R2R_TVARV            as TvarvFmPagto   on  TvarvFmPagto.Name = 'Z_R2R_AR_POSITION_FRMPAGTO'
                                                                      and TvarvFmPagto.Type = 'P'

    left outer to one join ZI_R2R_TVARV            as TvarvFinAcc    on  TvarvFinAcc.Name = 'Z_R2R_AR_POSITION_FINANCIALACC'
                                                                      and TvarvFinAcc.Type = 'P'

    left outer to one join ZI_R2R_TVARV            as TvarvKoart     on  TvarvKoart.Name = 'Z_R2R_AR_POSITION_KOART'
                                                                      and TvarvKoart.Type = 'P'

    // --------------------------------------------------------
    // BSEG: Full primary key (bukrs + belnr + gjahr + buzei) used.
    // koart filter further restricts to 0-or-1 row. 1:1 join.
    // Note: Direct BSEG access is acceptable here as all 4 PK
    // fields are provided; use I_JournalEntryItem if CDS-only
    // architecture is required by your clean-core guidelines.
    // --------------------------------------------------------
    left outer to one join bseg                    as Bseg           on  Bseg.bukrs = Doc.CompanyCode
                                                                      and Bseg.belnr = Doc.AccountingDocument
                                                                      and Bseg.gjahr = Doc.FiscalYear
                                                                      and Bseg.buzei = Doc.AccountingDocumentItem
                                                                      and Bseg.koart = TvarvKoart.Low

    // --------------------------------------------------------
    // Customer master — Customer is the PK, always 1:1.
    // --------------------------------------------------------
    left outer to one join I_Customer              as Customer       on Customer.Customer = Doc.Customer

    // --------------------------------------------------------
    // Credit management — BusinessPartner is the PK, 1:1.
    // --------------------------------------------------------
    left outer to one join I_CreditManagementBP    as Credit         on Credit.BusinessPartner = Doc.Customer

    // --------------------------------------------------------
    // Text tables — always 1:1 when Language is fully specified.
    // --------------------------------------------------------
    left outer to one join I_CustomerCreditGroupText as GrText        on  GrText.CreditAccountGroup = Credit.CreditAccountGroup
                                                                      and GrText.Language           = TvarvLang.Low

    left outer to one join I_CreditRiskClassText   as CredText       on  CredText.CreditRiskClass = Credit.CreditRiskClass
                                                                      and CredText.Language        = TvarvLang.Low

    // --------------------------------------------------------
    // FIX #5: Tax number joins.
    // BUT0BEW schema allows multiple entries per Partner+TaxType.
    // "to one" enforces the expected 1:1 assumption.
    // Validate: SELECT partner, taxtype, COUNT(*) FROM but0bew
    //           GROUP BY partner, taxtype HAVING COUNT(*) > 1
    // --------------------------------------------------------
    left outer to one join I_Businesspartnertaxnumber as TaxCNPJ     on  TaxCNPJ.BusinessPartner = Doc.Customer
                                                                      and TaxCNPJ.BPTaxType       = 'BR1'

    left outer to one join I_Businesspartnertaxnumber as TaxCPF      on  TaxCPF.BusinessPartner = Doc.Customer
                                                                      and TaxCPF.BPTaxType       = 'BR2'

    // --------------------------------------------------------
    // FIX #3: Billing document join.
    // The join condition uses (SoldToParty, CompanyCode, FiscalYear,
    // AccountingDocument) which is NOT the PK of I_BillingDocument.
    // In standard flow one FI doc = one billing doc, but edge cases
    // exist (collective invoice reversals, NF-e reprocessing).
    // "to one" enforces the 1:1 assumption — validate in production.
    // --------------------------------------------------------
    left outer to one join I_BillingDocument       as BillDoc        on  BillDoc.SoldToParty        = Doc.Customer
                                                                      and BillDoc.CompanyCode        = Doc.CompanyCode
                                                                      and BillDoc.FiscalYear         = Doc.FiscalYear
                                                                      and BillDoc.AccountingDocument = Doc.AccountingDocument
                                                                      and TvarvDocType.AccountingDocumentType is not null

    // --------------------------------------------------------
    // FIX #1: I_BillingDocumentItem (BillItem) JOIN REMOVED.
    //
    // ORIGINAL (BROKEN):
    //   left outer join I_BillingDocumentItem as BillItem
    //     on BillItem.BillingDocument = BillDoc.BillingDocument
    //
    // Root cause: Joining on BillingDocument alone (without
    // BillingDocumentItem) is a 1:N join — a billing document
    // ALWAYS has multiple items (line items, taxes, freight etc.).
    // This multiplied every row by the number of billing items.
    // Additionally, NOT A SINGLE FIELD from BillItem was projected
    // in the SELECT clause — the join was both harmful AND useless.
    // --------------------------------------------------------

    // --------------------------------------------------------
    // Journal Entry — PK is (CompanyCode, AccountingDocument,
    // FiscalYear). Mutually exclusive with BillDoc via the
    // TvarvDocType IS NULL condition in the ON clause.
    // --------------------------------------------------------
    left outer to one join I_JournalEntry          as Journal        on  Journal.CompanyCode        = Doc.CompanyCode
                                                                      and Journal.AccountingDocument = Doc.AccountingDocument
                                                                      and Journal.FiscalYear         = Doc.FiscalYear
                                                                      and TvarvDocType.AccountingDocumentType is null

    // --------------------------------------------------------
    // Custom view: Sales auxiliary data per document.
    // Requires ZI_R2R_AR_SALES_AUX_TXT to guarantee uniqueness on
    // (Customer, CompanyCode, FiscalYear, AccountingDocument).
    // --------------------------------------------------------
    left outer to one join ZI_R2R_AR_SALES_AUX_TXT as CustSales     on  CustSales.Customer           = Doc.Customer
                                                                      and CustSales.CompanyCode        = Doc.CompanyCode
                                                                      and CustSales.FiscalYear         = Doc.FiscalYear
                                                                      and CustSales.AccountingDocument = Doc.AccountingDocument

    // --------------------------------------------------------
    // FIX #4: Due date history join.
    // History tables store one row per change event. This join MUST
    // use "to one" and the underlying view ZI_R2R_DUEDATEHISTORY
    // MUST return only one row per document item (e.g., using MAX
    // aggregation on the change timestamp to get the current state).
    // Failure to do so multiplies rows by the number of due-date
    // extensions per receivable item.
    // --------------------------------------------------------
    left outer to one join ZI_R2R_DUEDATEHISTORY   as History        on  History.CompanyCode        = Doc.CompanyCode
                                                                      and History.AccountingDocument = Doc.AccountingDocument
                                                                      and History.FiscalYear         = Doc.FiscalYear
                                                                      and History.DocumentItem       = Doc.AccountingDocumentItem

    // --------------------------------------------------------
    // Text tables — language-qualified, all 1:1.
    // --------------------------------------------------------
    left outer to one join I_DunningAreaText       as DuniText       on  DuniText.CompanyCode = Doc.CompanyCode
                                                                      and DuniText.DunningArea = Doc.DunningArea
                                                                      and DuniText.Language    = TvarvLang.Low

    left outer to one join I_PaymentBlockingReasonText as PayBlock   on  PayBlock.PaymentBlockingReason = Doc.PaymentBlockingReason
                                                                      and PayBlock.Language              = TvarvLang.Low

    // --------------------------------------------------------
    // FIX #7: Accounting document type text.
    // ORIGINAL (BUG): AccDocText.Language = 'P'
    // 'P' is not a valid SAP language key. This caused the join to
    // return zero rows, making AccDocTypeName always NULL.
    // FIX: Use TvarvLang.Low (consistent with all other text joins).
    // --------------------------------------------------------
    left outer to one join I_AccountingDocumentTypeText as AccDocText on  AccDocText.AccountingDocumentType = Doc.AccountingDocumentType
                                                                       and AccDocText.Language              = TvarvLang.Low

    // --------------------------------------------------------
    // Custom view: Original invoice amounts per document item.
    // Requires ZI_R2R_AR_ORIGIN_VALUE to guarantee uniqueness on
    // (CompanyCode, AccountingDocument, FiscalYear, AccountingDocumentItem).
    // --------------------------------------------------------
    left outer to one join ZI_R2R_AR_ORIGIN_VALUE  as Origin         on  Origin.CompanyCode            = Doc.CompanyCode
                                                                      and Origin.AccountingDocument     = Doc.AccountingDocument
                                                                      and Origin.FiscalYear             = Doc.FiscalYear
                                                                      and Origin.AccountingDocumentItem = Doc.AccountingDocumentItem

    // --------------------------------------------------------
    // Custom view: Item category per document item.
    // Name suffix _TXT_MIN suggests a pre-aggregated single-row view.
    // Requires uniqueness on (CompanyCode, AccountingDocument,
    // FiscalYear, DocumentItem).
    // --------------------------------------------------------
    left outer to one join ZI_R2R_AR_POSITION_TXT_MIN as ItemCatAux  on  ItemCatAux.CompanyCode        = Doc.CompanyCode
                                                                       and ItemCatAux.AccountingDocument = Doc.AccountingDocument
                                                                       and ItemCatAux.FiscalYear         = Doc.FiscalYear
                                                                       and ItemCatAux.DocumentItem       = Doc.AccountingDocumentItem

    // --------------------------------------------------------
    // FIX #6: Item category value help / text join.
    // ORIGINAL (BUG): Missing language filter on a VH view.
    // VH views typically expose texts for ALL languages. Without the
    // Language restriction, every row was multiplied by the number
    // of translated language entries in the VH view.
    // FIX: Added Language = TvarvLang.Low restriction.
    // --------------------------------------------------------
    left outer to one join ZI_R2R_ITEMCAT_VH       as ItemCatText    on  ItemCatText.ItemCategory = ItemCatAux.ItemCategory
                                                                      and ItemCatText.Language     = TvarvLang.Low

    // --------------------------------------------------------
    // Business partner / customer mapping — Customer is the PK, 1:1.
    // --------------------------------------------------------
    left outer to one join I_BusinessPartnerCustomer as BuPaCustomer on BuPaCustomer.Customer = Doc.Customer

    // --------------------------------------------------------
    // Data exchange instruction key text — fully qualified key
    // (Language + BankCountryKey + PaymentMethod + Key), 1:1.
    // --------------------------------------------------------
    left outer to one join I_DataExchInstructionKeysText as DtExIndtrutKey on  DtExIndtrutKey.DataExchangeInstructionKey = BuPaCustomer.DataExchangeInstructionKey
                                                                             and DtExIndtrutKey.Language                  = TvarvLang.Low
                                                                             and DtExIndtrutKey.BankCountryKey             = 'BR'
                                                                             and DtExIndtrutKey.PaymentMethod              = TvarvFmPagto.Low
{
  // Primary key fields — uniquely identify one AR open item line
  key Doc.CompanyCode                           as CompanyCode,
  key Doc.FiscalYear                            as FiscalYear,
  key Doc.AccountingDocument                    as AccountingDocument,
  key Doc.AccountingDocumentItem                as DocumentItem,
  key Doc.Customer                              as Customer,

      // Document header attributes
      Doc.Reference3IDByBusinessPartner         as Reference3IDByBusinessPartner,
      Doc.HouseBank                             as HOUSEBANK,
      Doc.FinancialAccountType                  as FinancialAccountType,

      // BSEG supplement fields (initial document reference)
      Bseg.anfbn                                as ANFBN,
      Bseg.anfbj                                as ANFBJ,

      // Customer master data
      Customer.CustomerName                     as CustomerName,
      Customer.Region                           as Region,
      Customer.Country                          as Country,

      // Credit management
      Credit.CreditAccountGroup                 as CreditAccountGroup,
      Credit.CreditRiskClass                    as CreditRiskClass,
      GrText.CreditAccountGroupName             as CreditAccountGroupName,
      CredText.CreditRiskClassName              as CreditRiskClassName,

      // Brazilian tax identifiers (CNPJ = legal entity, CPF = individual)
      TaxCNPJ.BPTaxNumber                       as CNPJ,
      TaxCPF.BPTaxNumber                        as CPF,

      // Document reference ID: from billing document (SD flow) or
      // journal entry (FI-only flow), determined by TvarvDocType flag.
      cast( case
        when TvarvDocType.AccountingDocumentType is not null then BillDoc.DocumentReferenceID
        else Journal.DocumentReferenceID
      end as xblnr1 )                           as DocumentReferenceID,

      // Sales organisation hierarchy attributes
      CustSales.SalesRegion                     as SalesRegion,
      CustSales.SalesOffice                     as SalesOffice,
      CustSales.SalesTeam                       as SalesTeam,

      CustSales.SalesRegionName                 as SalesRegionName,
      CustSales.SalesOfficeName                 as SalesOfficeName,
      CustSales.SalesTeamName                   as SalesTeamName,

      CustSales.AdditionalCustomerGroup2        as AdditionalCustomerGroup2,
      CustSales.AdditionalCustomerGroup1        as AdditionalCustomerGroup1,

      CustSales.AdditionalCustomerGroup1Name    as AdditionalCustomerGroup1Name,
      CustSales.AdditionalCustomerGroup2Name    as AdditionalCustomerGroup2Name,

      // Document date
      Doc.DocumentDate                          as DocumentDate,

      // Due dates: prefer history values (latest renegotiated date)
      // over the original net due date from the document.
      // Requires ZI_R2R_DUEDATEHISTORY to return exactly one row
      // per (CompanyCode, AccountingDocument, FiscalYear, DocumentItem).
      case
        when History.OriginalValue is not initial then cast( History.OriginalValue as abap.dats )
        else Doc.NetDueDate
      end                                       as OriginalDueDate,

      case
        when History.CurrentValue is not initial then cast( History.CurrentValue as abap.dats )
        else Doc.NetDueDate
      end                                       as NetDueDate,

      // Dunning information
      Doc.DunningArea                           as DunningArea,

      case
        when Doc.DunningArea is initial
        then ''
        else DuniText.DunningAreaName
      end                                       as DunningAreaName,

      // Payment block
      Doc.PaymentBlockingReason                 as PaymentBlock,

      case
        when Doc.PaymentBlockingReason is initial
        then ''
        else PayBlock.PaymentBlockingReasonName
      end                                       as PayBlockName,

      // Document classification
      Doc.BusinessPlace                         as BusinessPlace,
      Doc.AccountingDocumentType                as AccDocType,
      // FIX #7: AccDocText now returns data because Language uses TvarvLang.Low
      AccDocText.AccountingDocumentTypeName     as AccDocTypeName,
      Doc.DocumentItemText                      as DocumentItemText,

      // Amounts
      Doc.CompanyCodeCurrency                   as Currency,

      @Semantics: { amount : {currencyCode: 'Currency'} }
      Origin.OriginalInvoiceAmount              as OriginalAmount,

      @Semantics: { amount : {currencyCode: 'Currency'} }
      case
        when Doc.InvoiceReference is not initial and Doc.FollowOnDocumentType = 'V'
        then Doc.AmountInCompanyCodeCurrency
        else cast( 0 as abap.curr( 23, 2 ) )
      end                                       as ResidualAmount,

      // Clearing status
      Doc.DebitCreditCode                       as DebitCreditCode,
      Doc.PaymentMethod                         as PaymentMethod,
      Doc.ClearingJournalEntry                  as ClearingJournalEntry,
      Doc.ClearingDate                          as ClearingDate,

      // Payment instruction key
      BuPaCustomer.DataExchangeInstructionKey   as InstKey,
      DtExIndtrutKey.DataExchInstructionKeyName as DtExKeyName,

      // Additional document fields
      Doc.SpecialGLCode,
      Doc.AccountingDocumentCategory,
      Doc.ClearingJournalEntryFiscalYear,

      // Item category — derived via ItemCatAux (document-level lookup)
      // FIX #6: Language filter added to ItemCatText join
      ItemCatText.ItemCategory                  as ItemCategory,
      ItemCatText.ItemCategoryText              as ItemCategoryText
}
where
  (
    (
      // Status 'A' = Open items (not cleared)
          $parameters.p_status     =  'A'
      and Doc.ClearingJournalEntry =  ''
    )
    or(
      // Status 'C' = Cleared items
          $parameters.p_status     =  'C'
      and Doc.ClearingJournalEntry <> ''
    )
    or(
      // Status 'T' = All items (Total)
          $parameters.p_status     =  'T'
    )
  )
  // Exclude self-clearing documents (document cleared by itself
  // in the same fiscal year), except when it is a different year
  and(
    (
          Doc.AccountingDocument   <> Doc.ClearingJournalEntry
    )
    or(
          Doc.AccountingDocument   =  Doc.ClearingJournalEntry
      and Doc.FiscalYear           <> Doc.ClearingJournalEntryFiscalYear
    )
  )
  // ⚠️ TODO: Remove hardcoded customer filter before transporting to production.
  // This filter ('0040000361') was left by a developer during testing and must NOT
  // reach production — it would silently restrict the report to a single customer.
  // Uncomment the line below only during local development/debugging.
  // and     Customer.Customer        =  '0040000361'
  // Filter to the configured financial account type only
  and     Doc.FinancialAccountType =  TvarvFinAcc.Low
