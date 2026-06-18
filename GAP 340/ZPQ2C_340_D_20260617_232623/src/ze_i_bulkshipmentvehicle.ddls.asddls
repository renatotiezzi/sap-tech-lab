@AbapCatalog.sqlViewAppendName: 'ZEIBULKSHIPMENTV'
@EndUserText.label: 'Extension View I_BulkShipmentVehicle'
@VDM.viewExtension:true
extend view I_BulkShipmentVehicle with ZE_I_BulkShipmentVehicle
{

  oigsv.veh_id as VehId

}
