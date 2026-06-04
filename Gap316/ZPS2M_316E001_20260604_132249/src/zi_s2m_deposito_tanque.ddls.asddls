@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic View - Deposito Tanque'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_S2M_Deposito_tanque
  as select from t001l
{
  key werks         as Werks,
  key lgort         as Lgort,
      oib_tnkassign as Tanque
}
where oib_tnkassign = 'T'
