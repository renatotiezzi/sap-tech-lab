@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'Wrapper MCHB Lote V04'
define view entity ZI_S2M_WRP_MCHB_LOTE
  /* ATC - Wrapper for direct DDIC access MCHB */
  as select from mchb
{
  key matnr as Material,
  key werks as Plant,
  key lgort as StorageLocation,
  key charg as Batch,
  /* V7 - RTIEZZI - DEF174 - INICIO - Expõe saldo real do lote para validacao em tempo real */
      clabs as Clabs
  /* V7 - RTIEZZI - DEF174 - FIM - Expõe saldo real do lote para validacao em tempo real */
}