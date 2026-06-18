@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TD Material Allocated to a Shipment'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_Q2C_AllocatedMat
  as select from oigsm
{
  key shnumber as Shnumber,
  key mat_itm  as MatItm,
      matnr    as Matnr,
      werks    as Werks,
      stlty    as Stlty,
      stlnr    as Stlnr,
      lgort    as Lgort,
      charg    as Charg,
      bwtar    as Bwtar,
      transf   as Transf,
      glqty    as Glqty,
      xblnr    as Xblnr,
      qty_itm  as QtyItm,
      hpm_itm  as HpmItm,
      cre_name as CreName,
      cre_date as CreDate,
      cre_time as CreTime,
      cha_name as ChaName,
      cha_date as ChaDate,
      cha_time as ChaTime
}
