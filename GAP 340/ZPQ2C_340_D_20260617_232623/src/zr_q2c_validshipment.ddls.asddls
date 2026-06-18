@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TDs  com SHTYPE Válidos'
define view entity ZR_Q2C_VALIDSHIPMENT
  as select from I_BulkShipmentHeader as Shipment
    inner join   ZZ1_TVARVC_Q2C       as Cbo on  Cbo.LOW  = Shipment.BulkShipmentType
                                             and Cbo.NAME = 'ZTD_TIPOS_TD_DESCARGA'
{
  key Shipment.BulkShipment       as ShipmentNumber, 
      Shipment.BulkShipmentType   as ShipmentType,   
      Shipment.TransportationPlanningPoint,          
      Shipment.BulkShipmentStatus as ShipmentStatus 
}
