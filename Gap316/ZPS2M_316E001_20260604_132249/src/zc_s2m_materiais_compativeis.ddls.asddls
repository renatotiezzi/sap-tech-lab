@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection - Materiais Compativeis'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_S2M_MATERIAIS_COMPATIVEIS
  as projection on ZR_S2M_MATERIAIS_COMPATIVEIS
{

  key                     reservation,
  key                     ReservationItem,
  key                     ReservationRecordType,
  key                     material,
  key                     Centro,
  key                     billofoperationstype,
  key                     Grupo,
  key                     billofoperationsvariant,
  key                     bootomaterialinternalid,
  key                     boomatlinternalversioncounter,
  key                     Deposito,
  key                     Charg,
                          Productionversion,
                          Billofmaterialvariant,
                          Billofmaterialvariantusage,
                          Charcinternalid,
                          Charcinternalid2,
                          Charcinternalid3,
                          Charcvalue,
                          Validade,
                          @Semantics.quantity.unitOfMeasure: 'meins'
                          Quantidade,

                          ChargD,
                          @Semantics.quantity.unitOfMeasure: 'meins'
                          Clabs,
                          meins,
                          LastChangedAt,
                          /* Associations */
                          _Componente : redirected to parent ZC_S2M_PO_COMP_MONITOR
}
