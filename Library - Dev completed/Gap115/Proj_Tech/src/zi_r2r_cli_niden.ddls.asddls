@AbapCatalog.viewEnhancementCategory: [#NONE]
@EndUserText.label: 'Geração de créditos arq.'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_R2R_CLI_NIDEN
  as select from ztbr2r_cli_niden
{
  key bankstatementshortid          as BankStatementShortId,
  key bankstatement                 as BankStatement,
  key bankstatementitemdescription2 as BankStatementItemDescription2,

      bankstatementdate             as BankStatementDate,
      businesspartnername           as BusinessPartnerName,
      name1                         as Name1,
      housebank                     as HouseBank,
      housebankaccount              as HouseBankAccount,
      bankinternalid                as BankInternalId,
      bankaccount                   as BankAccount,

      currency                      as Currency,
      @Semantics.amount.currencyCode: 'Currency'
      amountintransactioncurrency   as AmountInTransactionCurrency
}
