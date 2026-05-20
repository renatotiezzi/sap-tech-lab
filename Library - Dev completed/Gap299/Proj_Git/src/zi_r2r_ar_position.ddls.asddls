@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Accounts Receivable Position'
@Metadata.ignorePropagatedAnnotations: true
//@Search.searchable: false
define view entity ZI_R2R_AR_POSITION
  with parameters
    p_status : abap.char(1) //,
  // p_item_cat : abap.char(1)
  as select from    I_OperationalAcctgDocItem     as Doc

    left outer join ZI_R2R_TVARV                  as TvarvLang      on  TvarvLang.Name = 'Z_R2R_AR_POSITION_LANG'
                                                                    and TvarvLang.Type = 'P'

  //  left outer join ZI_R2R_TVARV as TvarvDocType on TvarvDocType.Name = 'Z_R2R_AR_POSITION_DOCTYPE'
  //                                             and TvarvDocType.Type = 'S'

    left outer join ZI_R2R_AR_DOCTYPE_FLAG        as TvarvDocType   on TvarvDocType.AccountingDocumentType = Doc.AccountingDocumentType


    left outer join ZI_R2R_TVARV                  as TvarvFmPagto   on  TvarvFmPagto.Name = 'Z_R2R_AR_POSITION_FRMPAGTO'
                                                                    and TvarvFmPagto.Type = 'P'

    left outer join ZI_R2R_TVARV                  as TvarvFinAcc    on  TvarvFinAcc.Name = 'Z_R2R_AR_POSITION_FINANCIALACC'
                                                                    and TvarvFinAcc.Type = 'P'

    left outer join ZI_R2R_TVARV                  as TvarvKoart     on  TvarvKoart.Name = 'Z_R2R_AR_POSITION_KOART'
                                                                    and TvarvKoart.Type = 'P'

    left outer join bseg                          as Bseg           on  bseg.bukrs = Doc.CompanyCode
                                                                    and Bseg.belnr = Doc.AccountingDocument
                                                                    and Bseg.gjahr = Doc.FiscalYear
                                                                    and Bseg.buzei = Doc.AccountingDocumentItem
                                                                    and bseg.koart = TvarvKoart.Low

    left outer join I_Customer                    as Customer       on Customer.Customer = Doc.Customer

    left outer join I_CreditManagementBP          as Credit         on Credit.BusinessPartner = Doc.Customer

    left outer join I_CustomerCreditGroupText     as GrText         on  GrText.CreditAccountGroup = Credit.CreditAccountGroup
                                                                    and GrText.Language           = TvarvLang.Low

    left outer join I_CreditRiskClassText         as CredText       on  CredText.CreditRiskClass = Credit.CreditRiskClass
                                                                    and CredText.Language        = TvarvLang.Low


    left outer join I_Businesspartnertaxnumber    as TaxCNPJ        on  TaxCNPJ.BusinessPartner = Doc.Customer
                                                                    and TaxCNPJ.BPTaxType       = 'BR1'

    left outer join I_Businesspartnertaxnumber    as TaxCPF         on  TaxCPF.BusinessPartner = Doc.Customer
                                                                    and TaxCPF.BPTaxType       = 'BR2'

    left outer join I_BillingDocument             as BillDoc        on  BillDoc.SoldToParty                 = Doc.Customer
                                                                    and BillDoc.CompanyCode                 = Doc.CompanyCode
                                                                    and BillDoc.FiscalYear                  = Doc.FiscalYear
                                                                    and BillDoc.AccountingDocument          = Doc.AccountingDocument
                                                                    and TvarvDocType.AccountingDocumentType is not null

    left outer join I_BillingDocumentItem         as BillItem       on BillItem.BillingDocument = BillDoc.BillingDocument

    left outer join I_JournalEntry                as Journal        on  Journal.CompanyCode                 = Doc.CompanyCode
                                                                    and Journal.AccountingDocument          = Doc.AccountingDocument
                                                                    and Journal.FiscalYear                  = Doc.FiscalYear
                                                                    and TvarvDocType.AccountingDocumentType is null


    left outer join ZI_R2R_AR_SALES_AUX_TXT       as CustSales      on  CustSales.Customer           = Doc.Customer
                                                                    and CustSales.CompanyCode        = Doc.CompanyCode
                                                                    and CustSales.FiscalYear         = Doc.FiscalYear
                                                                    and CustSales.AccountingDocument = Doc.AccountingDocument

  //  left outer join I_CustomerSalesArea           as BandConce      on  BandConce.Customer            = Doc.Customer
  //and BandConce.SalesOrganization   = BillDoc.SalesOrganization
  //and BandConce.DistributionChannel = BillDoc.DistributionChannel
  //and BandConce.Division            = BillDoc.Division

    left outer join ZI_R2R_DUEDATEHISTORY         as History        on  History.CompanyCode        = Doc.CompanyCode
                                                                    and History.AccountingDocument = Doc.AccountingDocument
                                                                    and History.FiscalYear         = Doc.FiscalYear
                                                                    and History.DocumentItem       = Doc.AccountingDocumentItem

    left outer join I_DunningAreaText             as DuniText       on  DuniText.CompanyCode = Doc.CompanyCode
                                                                    and DuniText.DunningArea = Doc.DunningArea
                                                                    and DuniText.Language    = TvarvLang.Low

    left outer join I_PaymentBlockingReasonText   as PayBlock       on  PayBlock.PaymentBlockingReason = Doc.PaymentBlockingReason
                                                                    and PayBlock.Language              = TvarvLang.Low

    left outer join I_AccountingDocumentTypeText  as AccDocText     on  AccDocText.AccountingDocumentType = Doc.AccountingDocumentType
                                                                    and AccDocText.Language               = 'P'

    left outer join ZI_R2R_AR_ORIGIN_VALUE        as Origin         on  Origin.CompanyCode            = Doc.CompanyCode
                                                                    and Origin.AccountingDocument     = Doc.AccountingDocument
                                                                    and Origin.FiscalYear             = Doc.FiscalYear
                                                                    and Origin.AccountingDocumentItem = Doc.AccountingDocumentItem

    left outer join ZI_R2R_AR_POSITION_TXT_MIN    as ItemCatAux     on  ItemCatAux.CompanyCode        = Doc.CompanyCode
                                                                    and ItemCatAux.AccountingDocument = Doc.AccountingDocument
                                                                    and ItemCatAux.FiscalYear         = Doc.FiscalYear
                                                                    and ItemCatAux.DocumentItem       = Doc.AccountingDocumentItem

    left outer join ZI_R2R_ITEMCAT_VH             as ItemCatText    on ItemCatText.ItemCategory = ItemCatAux.ItemCategory


    left outer join I_BusinessPartnerCustomer     as BuPaCustomer   on BuPaCustomer.Customer = Doc.Customer

    left outer join I_DataExchInstructionKeysText as DtExIndtrutKey on  DtExIndtrutKey.DataExchangeInstructionKey = BuPaCustomer.DataExchangeInstructionKey
                                                                    and DtExIndtrutKey.Language                   = TvarvLang.Low
                                                                    and DtExIndtrutKey.BankCountryKey             = 'BR'
                                                                    and DtExIndtrutKey.PaymentMethod              = TvarvFmPagto.Low
{
  key Doc.CompanyCode                           as CompanyCode,
  key Doc.FiscalYear                            as FiscalYear,
  key Doc.AccountingDocument                    as AccountingDocument,
  key Doc.AccountingDocumentItem                as DocumentItem,
  key Doc.Customer                              as Customer,

      // New Fields - Spec V2
      Doc.Reference3IDByBusinessPartner         as Reference3IDByBusinessPartner,
      Doc.HouseBank                             as HOUSEBANK,
      Doc.FinancialAccountType                  as FinancialAccountType,
      Bseg.anfbn                                as ANFBN,
      Bseg.anfbj                                as ANFBJ,

      Customer.CustomerName                     as CustomerName,
      Customer.Region                           as Region,
      Customer.Country                          as Country,

      Credit.CreditAccountGroup                 as CreditAccountGroup,
      Credit.CreditRiskClass                    as CreditRiskClass,
      GrText.CreditAccountGroupName             as CreditAccountGroupName,
      CredText.CreditRiskClassName              as CreditRiskClassName,


      TaxCNPJ.BPTaxNumber                       as CNPJ,
      TaxCPF.BPTaxNumber                        as CPF,

      cast( case
        when TvarvDocType.AccountingDocumentType is not null then BillDoc.DocumentReferenceID
        else Journal.DocumentReferenceID
      end as xblnr1 )                           as DocumentReferenceID,

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


      Doc.DocumentDate                          as DocumentDate,

      case
        when History.OriginalValue is not initial then cast( History.OriginalValue as abap.dats )
        else Doc.NetDueDate
      end                                       as OriginalDueDate,

      case
        when History.CurrentValue is not initial then cast( History.CurrentValue as abap.dats )
        else Doc.NetDueDate
      end                                       as NetDueDate,

      Doc.DunningArea                           as DunningArea,

      case
      when Doc.DunningArea is initial
      then ''
      else DuniText.DunningAreaName
      end                                       as DunningAreaName,


      Doc.PaymentBlockingReason                 as PaymentBlock,

      case
        when Doc.PaymentBlockingReason is initial
        then ''
        else PayBlock.PaymentBlockingReasonName
      end                                       as PayBlockName,

      Doc.BusinessPlace                         as BusinessPlace,
      Doc.AccountingDocumentType                as AccDocType,
      AccDocText.AccountingDocumentTypeName     as AccDocTypeName,
      Doc.DocumentItemText                      as DocumentItemText,

      Doc.CompanyCodeCurrency                   as Currency,

      @Semantics: { amount : {currencyCode: 'Currency'} }
      Origin.OriginalInvoiceAmount              as OriginalAmount,

      @Semantics: { amount : {currencyCode: 'Currency'} }
      case
        when Doc.InvoiceReference is not initial and Doc.FollowOnDocumentType = 'V'
        then Doc.AmountInCompanyCodeCurrency
        else cast( 0 as abap.curr( 23, 2 ) )
      end                                       as ResidualAmount,

      Doc.DebitCreditCode                       as DebitCreditCode,
      Doc.PaymentMethod                         as PaymentMethod,
      Doc.ClearingJournalEntry                  as ClearingJournalEntry,
      Doc.ClearingDate                          as ClearingDate,

      BuPaCustomer.DataExchangeInstructionKey   as InstKey,
      DtExIndtrutKey.DataExchInstructionKeyName as DtExKeyName,

      Doc.SpecialGLCode,
      Doc.AccountingDocumentCategory,
      Doc.ClearingJournalEntryFiscalYear,

      ItemCatText.ItemCategory                  as ItemCategory,
      ItemCatText.ItemCategoryText              as ItemCategoryText



}
where
  (
    (
          $parameters.p_status     =  'A'
      and Doc.ClearingJournalEntry =  ''
    )
    or(
          $parameters.p_status     =  'C'
      and Doc.ClearingJournalEntry <> ''
    )
    or(
          $parameters.p_status     =  'T'
    )
  )

  and(
    (
          Doc.AccountingDocument   <> Doc.ClearingJournalEntry
    )
    or(
          Doc.AccountingDocument   =  Doc.ClearingJournalEntry
      and Doc.FiscalYear           <> Doc.ClearingJournalEntryFiscalYear
    )
  )

  and     Doc.FinancialAccountType =  TvarvFinAcc.Low;
