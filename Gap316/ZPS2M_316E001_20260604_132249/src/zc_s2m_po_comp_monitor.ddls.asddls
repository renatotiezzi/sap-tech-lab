@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection - Process Order Componente Monitor'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_S2M_PO_COMP_MONITOR
  provider contract transactional_query
  as projection on ZR_S2M_PO_COMP_MONITOR

{

  key     Reservation,
  key     ReservationItem,
  key     ReservationRecordType,
          @ObjectModel: {
           virtualElement: true,
           virtualElementCalculatedBy: 'ABAP:ZCLS2M_MAT_CARACT_CALC',
           filter.transformedBy: 'ABAP:ZCLS2M_MAT_CARACT_CALC'
           }
          @UI.hidden: true
  virtual UpdateTable : abap.char(255),
          MaterialGroup,
          material,
          I_MaterialText.MaterialName,
          plant,
          ManufacturingOrder,
          orderoperationinternalid,
          BaseUnit,
          @Semantics.quantity.unitOfMeasure: 'BaseUnit'
          RequiredQuantity,
          LastChangedAt,
          A_ProcessOrder.Material as MaterialOrdem,
          A_ProcessOrder.MaterialName as MaterialOrdemName,

          _Materiais : redirected to composition child ZC_S2M_MATERIAIS_COMPATIVEIS

}
