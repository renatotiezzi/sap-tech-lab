@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic View - Deposito Tanque'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_S2M_Deposito_tanque
  /* ATC - Change T001L -> wrapper ZI_S2M_WRP_T001L_TANQUE */
  as select from ZI_S2M_WRP_T001L_TANQUE
{
  key werks         as Werks,
  key lgort         as Lgort,
      Tanque
}
where Tanque = 'T'
