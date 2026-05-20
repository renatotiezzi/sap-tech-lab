@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'history of due date'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_R2R_DUEDATEHISTORY 
 as select from I_ChangeDocumentItem
{
// A chave da tabela no Change Document é: Mandante(3) + Empresa(4) + Doc(10) + Ano(4) + Item(3)
  key substring(ChangeDocTableKey, 4, 4)  as CompanyCode,
  key substring(ChangeDocTableKey, 8, 10) as AccountingDocument,
  key substring(ChangeDocTableKey, 18, 4) as FiscalYear,
  key substring(ChangeDocTableKey, 22, 3) as DocumentItem,

  // Pega o valor mais antigo (Original) de todos os logs
  min(ChangeDocPreviousFieldValue)        as OriginalValue,
  
  // Pega o valor mais novo (Atual) de todos os logs
  max(ChangeDocNewFieldValue)             as CurrentValue
  }
  where
      ChangeDocObjectClass           = 'BELEG'
  and DatabaseTable                  = 'BSEG'
  and ChangeDocDatabaseTableField    = 'ZFBDT'
group by
  ChangeDocTableKey
