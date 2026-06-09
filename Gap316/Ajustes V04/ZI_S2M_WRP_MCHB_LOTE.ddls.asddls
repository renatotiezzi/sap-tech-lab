@AbapCatalog.sqlViewName: 'ZS2MWRPMCHBLT'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Wrapper MCHB Lote V04'
define view ZI_S2M_WRP_MCHB_LOTE
  as select from mchb
{
  key matnr as Material,
  key werks as Plant,
  key lgort as StorageLocation,
  key charg as Batch,
      clabs as SaldoLivre
}
