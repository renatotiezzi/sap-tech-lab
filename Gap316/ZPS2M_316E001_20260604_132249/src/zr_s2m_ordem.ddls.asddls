@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Transactional View - Process Order Component'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZR_S2M_ORDEM
  as select from ZI_S2M_ORDEM
    inner join   I_MfgOrderStatus on ZI_S2M_ORDEM.ManufacturingOrder = I_MfgOrderStatus.ManufacturingOrder
    inner join I_Product on ZI_S2M_ORDEM.Material = I_Product.Product
    and I_Product.ZZ1_Gr_aproveitamento_PRD != '0'
{
  key ZI_S2M_ORDEM.Reservation,
  key ZI_S2M_ORDEM.ReservationItem,
  key ZI_S2M_ORDEM.ReservationRecordType,
      ZI_S2M_ORDEM.MaterialGroup,
      ZI_S2M_ORDEM.Material,
      ZI_S2M_ORDEM.Plant,
      ZI_S2M_ORDEM.ManufacturingOrder,
      ZI_S2M_ORDEM.OrderOperationInternalID,
      ZI_S2M_ORDEM.ManufacturingOrderSequence,
      ZI_S2M_ORDEM.BaseUnit,
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      ZI_S2M_ORDEM.RequiredQuantity

}
where
  I_MfgOrderStatus.OrderIsCreated = 'X'
