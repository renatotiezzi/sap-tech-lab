@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZI_R2R_AR_SALES_AUX - Texto'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_R2R_AR_SALES_AUX_TXT
  as select from    ZI_R2R_AR_SALES_AUX as A

    left outer join ZI_R2R_TVARV        as TvarvLang      on  TvarvLang.Name = 'Z_R2R_AR_POSITION_LANG'
                                                          and TvarvLang.Type = 'P'

    left outer join I_SalesDistrictText as SalesDistTxt   on  SalesDistTxt.SalesDistrict = A.SalesRegion
                                                          and SalesDistTxt.Language      = TvarvLang.Low

    left outer join I_SalesOfficeText   as SalesOfficeTxt on  SalesOfficeTxt.SalesOffice = A.SalesOffice
                                                          and SalesOfficeTxt.Language    = TvarvLang.Low

    left outer join I_SalesGroupText    as SalesGroupTxt  on  SalesGroupTxt.SalesGroup = A.SalesTeam
                                                          and SalesGroupTxt.Language   = TvarvLang.Low

    left outer join tvv1t               as FlagTxt        on  FlagTxt.kvgr1 = A.AdditionalCustomerGroup1
                                                          and FlagTxt.spras = TvarvLang.Low


    left outer join tvv2t               as SegTxt         on  SegTxt.kvgr2 = A.AdditionalCustomerGroup2
                                                          and SegTxt.spras = TvarvLang.Low

{
  key A.CompanyCode,
  key A.FiscalYear,
  key A.AccountingDocument,
  key A.Customer,

      A.SalesRegion,
      A.SalesOffice,
      A.SalesTeam,
      A.AdditionalCustomerGroup1,
      A.AdditionalCustomerGroup2,

      SalesDistTxt.SalesDistrictName as SalesRegionName,
      SalesOfficeTxt.SalesOfficeName as SalesOfficeName,
      SalesGroupTxt.SalesGroupName   as SalesTeamName,
      FlagTxt.bezei                  as AdditionalCustomerGroup1Name,
      SegTxt.bezei                   as AdditionalCustomerGroup2Name
}
