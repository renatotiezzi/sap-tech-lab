@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Wrapper Z - T001L Tanque (ATC V04)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_S2M_WRP_T001L_TANQUE
  as select from t001l
{
  key werks         as Werks,
  key lgort         as Lgort,
      oib_tnkassign as TankAssignment
}
