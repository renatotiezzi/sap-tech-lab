@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic View - Process Order Component Monitor'
define view entity ZI_S2M_ORDEM
  as select from I_MfgOrderComponentWithStatus
{
  key I_MfgOrderComponentWithStatus.Reservation,
  key I_MfgOrderComponentWithStatus.ReservationItem,
  key I_MfgOrderComponentWithStatus.ReservationRecordType,
      I_MfgOrderComponentWithStatus.MaterialGroup,
      I_MfgOrderComponentWithStatus.Material,
      I_MfgOrderComponentWithStatus.Plant,
      I_MfgOrderComponentWithStatus.ManufacturingOrder,
      I_MfgOrderComponentWithStatus.BaseUnit,
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      I_MfgOrderComponentWithStatus.RequiredQuantity,
      I_MfgOrderComponentWithStatus.Batch,
      OrderOperationInternalID,
      ManufacturingOrderSequence
}
