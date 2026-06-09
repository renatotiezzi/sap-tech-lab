@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'Wrapper T001L Tanque V04'
define view entity ZI_S2M_WRP_T001L_TANQUE
  /* ATC - Wrapper for direct DDIC access T001L */
  as select from t001l
{
  key werks         as Werks,
  key lgort         as Lgort,
      oib_tnkassign as Tanque
}