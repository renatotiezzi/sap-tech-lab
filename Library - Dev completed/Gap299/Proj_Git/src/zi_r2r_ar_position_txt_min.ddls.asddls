@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Position - Keys + ItemCategory'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: false
define view entity ZI_R2R_AR_POSITION_TXT_MIN
  as select from I_OperationalAcctgDocItem as Doc
{
  key Doc.CompanyCode            as CompanyCode,
  key Doc.FiscalYear             as FiscalYear,
  key Doc.AccountingDocument     as AccountingDocument,
  key Doc.AccountingDocumentItem as DocumentItem,
  key Doc.Customer               as Customer,

      cast(
        case
          when Doc.AccountingDocumentCategory = 'S' then 'M'
          when Doc.SpecialGLCode <> '' and Doc.AccountingDocumentCategory = '' then 'R'
          when Doc.SpecialGLCode = ''  and Doc.AccountingDocumentCategory = '' then 'N'
          else ''
        end as zde_r2r_item_category
      )                          as ItemCategory
}
where
  (
          Doc.AccountingDocument <> Doc.ClearingJournalEntry
    or(
          Doc.AccountingDocument =  Doc.ClearingJournalEntry
      and Doc.FiscalYear         <> Doc.ClearingJournalEntryFiscalYear
    )
  );
