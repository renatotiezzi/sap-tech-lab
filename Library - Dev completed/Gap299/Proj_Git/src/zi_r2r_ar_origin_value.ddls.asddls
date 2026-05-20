@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Search original value in levels'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_R2R_AR_ORIGIN_VALUE
  as select from I_OperationalAcctgDocItem as level0
  

  left outer join I_OperationalAcctgDocItem as level1 on  level1.CompanyCode            = level0.CompanyCode
                                                      and level1.AccountingDocument     = level0.InvoiceReference
                                                      and level1.FiscalYear             = level0.InvoiceReferenceFiscalYear //FOLLOWONDOCUMENTTYPE
                                                      and level1.AccountingDocumentItem = level0.InvoiceItemReference

  
  left outer join I_OperationalAcctgDocItem as level2 on  level2.CompanyCode            = level1.CompanyCode
                                                      and level2.AccountingDocument     = level1.InvoiceReference
                                                      and level2.FiscalYear             = level1.InvoiceReferenceFiscalYear //FOLLOWONDOCUMENTTYPE
                                                      and level2.AccountingDocumentItem = level1.InvoiceItemReference

 
  left outer join I_OperationalAcctgDocItem as level3 on  level3.CompanyCode            = level2.CompanyCode
                                                      and level3.AccountingDocument     = level2.InvoiceReference
                                                      and level3.FiscalYear             = level2.InvoiceReferenceFiscalYear //FOLLOWONDOCUMENTTYPE
                                                      and level3.AccountingDocumentItem = level2.InvoiceItemReference
{
  key level0.CompanyCode,
  key level0.AccountingDocument,
  key level0.FiscalYear,
  key level0.AccountingDocumentItem,
      level0.CompanyCodeCurrency as Currency,

  @Semantics.amount.currencyCode: 'Currency'
  case 
    when level3.AmountInCompanyCodeCurrency is not null then level3.AmountInCompanyCodeCurrency
    when level2.AmountInCompanyCodeCurrency is not null then level2.AmountInCompanyCodeCurrency
    when level1.AmountInCompanyCodeCurrency is not null then level1.AmountInCompanyCodeCurrency
    else level0.AmountInCompanyCodeCurrency
  end as OriginalInvoiceAmount
}
