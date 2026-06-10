@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic View - Materiais Compatíveis'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_S2M_MATERIAIS_COMPATIVEIS
  as select from ztbs2m_mat_compa
    left outer join ZI_S2M_Deposito_tanque as _DepositoTanque on  _DepositoTanque.Lgort = ztbs2m_mat_compa.deposito
                                                                and _DepositoTanque.Werks = ztbs2m_mat_compa.centro
  association to I_Product as _Mara on $projection.material = _Mara.Product
{
  key   ztbs2m_mat_compa.reservation,
  key   ztbs2m_mat_compa.reservation_item           as ReservationItem,
  key   ztbs2m_mat_compa.reservation_record_type    as ReservationRecordType,
  key   ztbs2m_mat_compa.material,
  key   ztbs2m_mat_compa.centro                     as Centro,
  key   ztbs2m_mat_compa.billofoperationstype,
  key   ztbs2m_mat_compa.grupo                      as Grupo,
  key   ztbs2m_mat_compa.billofoperationsvariant,
  key   ztbs2m_mat_compa.bootomaterialinternalid,
  key   ztbs2m_mat_compa.boomatlinternalversioncounter,
  key   ztbs2m_mat_compa.deposito                   as Deposito,
  key   ztbs2m_mat_compa.charg                      as Charg,
        ztbs2m_mat_compa.productionversion          as Productionversion,
        ztbs2m_mat_compa.billofmaterialvariant      as Billofmaterialvariant,
        ztbs2m_mat_compa.billofmaterialvariantusage as Billofmaterialvariantusage,
        ztbs2m_mat_compa.charcinternalid            as Charcinternalid,
        ztbs2m_mat_compa.charcinternalid2           as Charcinternalid2,
        ztbs2m_mat_compa.charcinternalid3           as Charcinternalid3,
        ztbs2m_mat_compa.charcvalue                 as Charcvalue,
        ztbs2m_mat_compa.validade                   as Validade,
        @Semantics.quantity.unitOfMeasure: 'meins'
        ztbs2m_mat_compa.quantidade                 as Quantidade,
        ztbs2m_mat_compa.charg_d                    as ChargD,
        @Semantics.quantity.unitOfMeasure: 'meins'
        ztbs2m_mat_compa.clabs                      as Clabs,
        @Semantics.systemDateTime.lastChangedAt: true
        ztbs2m_mat_compa.last_changed_at            as LastChangedAt,
        _Mara.BaseUnit                              as meins
}
