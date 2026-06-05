@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Transaction View - Materiais Compativeis'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_S2M_MATERIAIS_COMPATIVEIS
  as select distinct from ZI_S2M_MATERIAIS_COMPATIVEIS
  association to parent ZR_S2M_PO_COMP_MONITOR as _Componente on  $projection.reservation           = _Componente.Reservation
                                                              and $projection.ReservationItem       = _Componente.ReservationItem
                                                              and $projection.ReservationRecordType = _Componente.ReservationRecordType
{
  key reservation,
  key ReservationItem,
  key ReservationRecordType,
  key material,
  key Centro,
  key billofoperationstype,
  key Grupo,
  key billofoperationsvariant,
  key bootomaterialinternalid,
  key boomatlinternalversioncounter,
  key Deposito,
  key Charg,
      Productionversion,
      Billofmaterialvariant,
      Billofmaterialvariantusage,
      Charcinternalid,
      Charcinternalid2,
      Charcinternalid3,
      Charcvalue,
      Validade,
      ChargD,
      @Semantics.quantity.unitOfMeasure: 'meins'
      Quantidade,
      @Semantics.quantity.unitOfMeasure: 'meins'
      Clabs,
      meins,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      /* RTiezzi: nome do material substituto */
      MaterialName,
      /* Associations */
      _Componente
}
