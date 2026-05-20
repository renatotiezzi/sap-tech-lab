@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Clientes Não Identificados no SAP'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: false
define view entity ZC_R2R_CLI_NIDEN
  as select from ZI_R2R_CLI_NIDEN
{
  /* Keys (per EF: campos com *) */
  key BankStatementShortId,
  key BankStatement,
  key BankStatementItemDescription2,

  /* Columns */
      BankStatementDate,
      BusinessPartnerName,
      Name1,
      HouseBank,
      HouseBankAccount,
      BankInternalId,
      BankAccount,

      Currency,

      @Semantics: { amount: { currencyCode: 'Currency' } }
      AmountInTransactionCurrency
}
