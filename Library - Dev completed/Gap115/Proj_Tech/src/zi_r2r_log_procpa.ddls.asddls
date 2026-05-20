@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GAP115 - PA Process Log (Interface)'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_R2R_LOG_PROCPA
  as select from ztr2r_log_procpa
{
      /* Keys */
  key bukrs    as CompanyCode,
  key belnr    as AccountingDocument,
  key gjahr    as FiscalYear,


      kunnr    as Customer,
      bldat    as DocumentDate,
      budat    as PostingDate,

      waers    as Currency,
      @Semantics.amount.currencyCode: 'Currency'
      dmbtr    as Amount,

      zuonr    as Assignment,
      vbeln    as SalesDocument,

      mensagem as Message,
      status   as Status


}
