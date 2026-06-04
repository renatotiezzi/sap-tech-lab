@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic View - Process Order Component Monitor'
define view entity ZI_S2M_PO_COMP_MONITOR
  as select from ztbs2m_ordem
    inner join   ZR_S2M_ORDEM on  ztbs2m_ordem.reservation             = ZR_S2M_ORDEM.Reservation
                              and ztbs2m_ordem.reservation_item        = ZR_S2M_ORDEM.ReservationItem
                              and ztbs2m_ordem.reservation_record_type = ZR_S2M_ORDEM.ReservationRecordType
{
      
  key  ztbs2m_ordem.reservation             as Reservation,
  key  ztbs2m_ordem.reservation_item        as ReservationItem,
  key  ztbs2m_ordem.reservation_record_type as ReservationRecordType,
       ztbs2m_ordem.material_group          as MaterialGroup,
       ztbs2m_ordem.material,
       ztbs2m_ordem.plant,
       ztbs2m_ordem.manufacturing_order     as ManufacturingOrder,
       ztbs2m_ordem.orderoperationinternalid,
       ZR_S2M_ORDEM.BaseUnit,
       @Semantics.quantity.unitOfMeasure: 'BaseUnit'
       ZR_S2M_ORDEM.RequiredQuantity,
       @Semantics.user.createdBy: true
       ztbs2m_ordem.created_by              as CreatedBy,
       @Semantics.systemDateTime.createdAt: true
       ztbs2m_ordem.created_at              as CreatedAt,
       @Semantics.user.localInstanceLastChangedBy: true
       ztbs2m_ordem.local_last_changed_by   as LocalLastChangedBy,
       @Semantics.systemDateTime.localInstanceLastChangedAt: true
       ztbs2m_ordem.local_last_changed_at   as LocalLastChangedAt,
       @Semantics.systemDateTime.lastChangedAt: true
       ztbs2m_ordem.last_changed_at         as LastChangedAt

}
