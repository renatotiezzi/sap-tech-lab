@EndUserText.label: 'GAP115 - Action Payload PA'
define abstract entity ZAE_R2R_LOG_PROCPA_ACT
{
  key CompanyCode        : bukrs;
  key AccountingDocument : belnr_d;
  key FiscalYear         : gjahr;

  Customer               : kunnr;
  DocumentDate           : bldat;
  PostingDate            : budat;

  Currency               : waers;
  @Semantics.amount.currencyCode: 'Currency'
  Amount                 : dmbtr;

  Assignment             : dzuonr;
  SalesDocument          : vbeln_va;

  Message                : abap.char(255);
  Status                 : zer2r_msg_status;
}
