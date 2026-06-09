@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'Wrapper MCHB Lote V04'
define view entity ZI_S2M_WRP_MCHB_LOTE
  as select from mchb
{
  key matnr as Material,
  key werks as Plant,
  key lgort as StorageLocation,
  key charg as Batch
}
