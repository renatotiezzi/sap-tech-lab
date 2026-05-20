@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Accounts Receivable Position'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: false
define view entity ZC_R2R_AR_POSITION
  with parameters
    @EndUserText.label: 'Status'
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_R2R_STATUS_VH', element: 'Status' } }]
    p_status : char1

  //@Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_R2R_ITEMCAT_VH', element: 'ItemCategory' } }]
  //p_item_cat : zde_r2r_item_category

  as select from ZI_R2R_AR_POSITION(p_status:   $parameters.p_status
                 //p_item_cat: $parameters.p_item_cat
                 )
{
  key CompanyCode,
  key FiscalYear,

  key AccountingDocument,
  key DocumentItem,

  key Customer,

      // New Fields - Spec V2
      Reference3IDByBusinessPartner,
      HOUSEBANK,
      FinancialAccountType,
      ANFBN,
      ANFBJ,
      //

      //ItemCategory,
      ItemCategoryText,
      CustomerName,
      Region,
      Country,
      CreditAccountGroup,
      CreditRiskClass,
      CreditAccountGroupName,
      CreditRiskClassName,
      CNPJ,
      CPF,
      DocumentReferenceID,
      SalesRegion,
      SalesRegionName,
      SalesOffice,
      SalesOfficeName,
      SalesTeam,
      SalesTeamName,
      AdditionalCustomerGroup2,
      AdditionalCustomerGroup2Name,
      AdditionalCustomerGroup1,
      AdditionalCustomerGroup1Name,
      DocumentDate,
      OriginalDueDate,
      NetDueDate,
      DunningArea,
      DunningAreaName,
      PaymentBlock,
      PayBlockName,
      BusinessPlace,
      AccDocType,
      AccDocTypeName,
      DocumentItemText,
      Currency,
      @Semantics: { amount : {currencyCode: 'Currency'} }
      OriginalAmount,
      @Semantics: { amount : {currencyCode: 'Currency'} }
      ResidualAmount,
      DebitCreditCode,
      PaymentMethod,
      ClearingJournalEntry,
      ClearingDate,
      // 37 - Dias de Atraso (Campo Virtual)
      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_R2R_CALC_DAYS'
      cast(0 as abap.int4) as DaysOverdue,
      InstKey,
      DtExKeyName,
      SpecialGLCode,
      AccountingDocumentCategory,
      ClearingJournalEntryFiscalYear
}
