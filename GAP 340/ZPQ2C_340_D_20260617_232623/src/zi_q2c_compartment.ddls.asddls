@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TD Quantity Item for Material on Vehicle'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_Q2C_Compartment
  as select from oigsvmq
{
  key shnumber  as Shnumber,
  key mat_itm   as MatItm,
  key qty_itm   as QtyItm,
      td_action as TdAction,
      shitem    as Shitem,
      posnr     as Posnr,
      tpu_nr    as TpuNr,
      seq_nmbr  as SeqNmbr,
      veh_nr    as VehNr,
      trqty     as Trqty,
      truom     as Truom,
      qty_vol   as QtyVol,
      qty_wgt   as QtyWgt,
      matnr     as Matnr,
      werks     as Werks,
      lgort     as Lgort,
      charg     as Charg,
      bwtar     as Bwtar,
      hpm_itm   as HpmItm,
      his_itm   as HisItm,
      qty_itm_c as QtyItmC,
      reas_code as ReasCode,
      cre_name  as CreName,
      cre_date  as CreDate,
      cre_time  as CreTime,
      cha_name  as ChaName,
      cha_date  as ChaDate,
      cha_time  as ChaTime
}
