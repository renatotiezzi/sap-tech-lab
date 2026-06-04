@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Transactional View - Process Order Component'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZR_S2M_PO_COMP_MONITOR
  as select from ZI_S2M_PO_COMP_MONITOR

  composition [0..*] of ZR_S2M_MATERIAIS_COMPATIVEIS as _Materiais
  association [0..1] to A_ProcessOrder on A_ProcessOrder.ProcessOrder = ZI_S2M_PO_COMP_MONITOR.ManufacturingOrder
   association [0..1] to I_MaterialText on I_MaterialText.Material = ZI_S2M_PO_COMP_MONITOR.material and I_MaterialText.Language = $session.system_language
{

  key ZI_S2M_PO_COMP_MONITOR.Reservation,
  key ZI_S2M_PO_COMP_MONITOR.ReservationItem,
  key ZI_S2M_PO_COMP_MONITOR.ReservationRecordType,
      ZI_S2M_PO_COMP_MONITOR.MaterialGroup,
      ZI_S2M_PO_COMP_MONITOR.material,
      ZI_S2M_PO_COMP_MONITOR.plant,
      ZI_S2M_PO_COMP_MONITOR.ManufacturingOrder,
      ZI_S2M_PO_COMP_MONITOR.orderoperationinternalid,
      ZI_S2M_PO_COMP_MONITOR.BaseUnit,
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      ZI_S2M_PO_COMP_MONITOR.RequiredQuantity,
      @Semantics.user.createdBy: true
      CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      _Materiais,
      A_ProcessOrder,
      I_MaterialText
}
