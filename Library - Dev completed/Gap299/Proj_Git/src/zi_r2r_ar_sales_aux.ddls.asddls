@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR - Sales Data Resolver'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_R2R_AR_SALES_AUX
  as select from    I_OperationalAcctgDocItem as Doc

  //left outer join ZI_R2R_TVARV                  as TvarvLang      on  TvarvLang.Name = 'Z_R2R_AR_POSITION_LANG'
  //                                                                and TvarvLang.Type = 'P'

    left outer join ZI_R2R_AR_DOCTYPE_FLAG    as TvarvDocType   on TvarvDocType.AccountingDocumentType = Doc.AccountingDocumentType

    left outer join I_BillingDocument         as BillDoc        on  BillDoc.SoldToParty                 = Doc.Customer
                                                                and BillDoc.CompanyCode                 = Doc.CompanyCode
                                                                and BillDoc.FiscalYear                  = Doc.FiscalYear
                                                                and BillDoc.AccountingDocument          = Doc.AccountingDocument
                                                                and TvarvDocType.AccountingDocumentType is not null

    left outer join I_BillingDocumentItem     as BillItem       on BillItem.BillingDocument = BillDoc.BillingDocument

    left outer join I_CustomerSalesArea       as CustSales      on CustSales.Customer = Doc.Customer

    left outer join I_SalesDistrictText       as SalesDistTxt   on  SalesDistTxt.SalesDistrict = BillDoc.SalesDistrict
                                                                and SalesDistTxt.Language      = $session.system_language

    left outer join I_SalesOfficeText         as SalesOfficeTxt on  SalesOfficeTxt.Language    = $session.system_language // SalesOfficeTxt.SalesOffice = BillItem.SalesOffice
                                                                //and SalesOfficeTxt.Language    = $session.system_language



    left outer join I_SalesGroupText          as SalesGroupTxt  on  SalesGroupTxt.SalesGroup = BillItem.SalesGroup
                                                                and SalesGroupTxt.Language   = $session.system_language

    left outer join I_JournalEntry            as Journal        on  Journal.CompanyCode                 = Doc.CompanyCode
                                                                and Journal.AccountingDocument          = Doc.AccountingDocument
                                                                and Journal.FiscalYear                  = Doc.FiscalYear
                                                                and TvarvDocType.AccountingDocumentType is null

    left outer join tvv1t                     as FlagTxt        on  FlagTxt.kvgr1 = CustSales.AdditionalCustomerGroup1
                                                                and FlagTxt.spras = $session.system_language


    left outer join tvv2t                     as SegTxt         on  SegTxt.kvgr2 = CustSales.AdditionalCustomerGroup2
                                                                and SegTxt.spras = $session.system_language

{
  key Doc.CompanyCode                           as CompanyCode,
  key Doc.FiscalYear                            as FiscalYear,
  key Doc.AccountingDocument                    as AccountingDocument,
  key Doc.Customer                              as Customer,

      /* resolved outputs */
      max(
        case
          when TvarvDocType.AccountingDocumentType is not null then BillDoc.SalesDistrict
          else CustSales.SalesDistrict
        end
      )                                         as SalesRegion,

      max(
        case
          when TvarvDocType.AccountingDocumentType is not null then BillItem.SalesOffice
          else CustSales.SalesOffice
        end
      )                                         as SalesOffice,

      max(
        case
          when TvarvDocType.AccountingDocumentType is not null then BillItem.SalesGroup
          else CustSales.SalesGroup
        end
      )                                         as SalesTeam,
      //max( TvarvLang.Low )                       as lang,
      max( CustSales.AdditionalCustomerGroup1 ) as AdditionalCustomerGroup1,
      max( CustSales.AdditionalCustomerGroup2 ) as AdditionalCustomerGroup2,

      max( SalesDistTxt.SalesDistrictName )     as SalesRegionName,
      max( SalesOfficeTxt.SalesOfficeName )     as SalesOfficeName,
      max( SalesGroupTxt.SalesGroupName )       as SalesTeamName,

      max( FlagTxt.bezei )                      as AdditionalCustomerGroup1Name,
      max( SegTxt.bezei )                       as AdditionalCustomerGroup2Name

}
group by
  Doc.CompanyCode,
  Doc.FiscalYear,
  Doc.AccountingDocument,
  Doc.Customer;
