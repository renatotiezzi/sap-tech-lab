@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Wrapper Z - MCHB Lote/Deposito (ATC V04)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_S2M_WRP_MCHB_LOTE
  as select from mchb
{
  key matnr as Material,
  key werks as Plant,
  key lgort as StorageLocation,
  key charg as Batch,
      clabs as UnrestrictedUseStock
}
