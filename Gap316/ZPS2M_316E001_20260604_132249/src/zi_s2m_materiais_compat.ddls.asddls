@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic View - Materiais Compatíveis'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_S2M_MATERIAIS_COMPAT
  as select from I_MasterRecipeMaterialAssgmt
    inner join   I_ProductionVersion          on  I_MasterRecipeMaterialAssgmt.Material               = I_ProductionVersion.Material
                                              and I_MasterRecipeMaterialAssgmt.Plant                  = I_ProductionVersion.Plant
                                              and I_MasterRecipeMaterialAssgmt.BillOfOperationsType   = I_ProductionVersion.BillOfOperationsType
                                              and I_MasterRecipeMaterialAssgmt.BillOfOperationsGroup  = I_ProductionVersion.BillOfOperationsGroup
                                              and I_MasterRecipeMaterialAssgmt.BillOfOperationsVariant = I_ProductionVersion.BillOfOperationsVariant
    inner join   R_BatchCharacteristicValueTP on I_ProductionVersion.Material = R_BatchCharacteristicValueTP.Material
    inner join   nsdm_e_mchb                  on  I_MasterRecipeMaterialAssgmt.Material = nsdm_e_mchb.matnr
                                              and I_MasterRecipeMaterialAssgmt.Plant    = nsdm_e_mchb.werks
                                              and R_BatchCharacteristicValueTP.Batch    = nsdm_e_mchb.charg
  association to I_Product as _Mara on $projection.Material = _Mara.Product
{
  key I_MasterRecipeMaterialAssgmt.Material,
  key I_MasterRecipeMaterialAssgmt.Plant                 as Centro,
  key I_MasterRecipeMaterialAssgmt.BillOfOperationsType,
  key I_MasterRecipeMaterialAssgmt.BillOfOperationsGroup as Grupo,
  key I_MasterRecipeMaterialAssgmt.BillOfOperationsVariant,
  key I_MasterRecipeMaterialAssgmt.BOOToMaterialInternalID,
  key I_MasterRecipeMaterialAssgmt.BOOMatlInternalVersionCounter,
      I_ProductionVersion.ProductionVersion,
      I_ProductionVersion.BillOfMaterialVariant,
      I_ProductionVersion.BillOfMaterialVariantUsage,
      R_BatchCharacteristicValueTP.CharcInternalID,
      R_BatchCharacteristicValueTP.CharcValue,
      R_BatchCharacteristicValueTP.Batch                 as Lote,
      I_ProductionVersion.ValidityEndDate                as Validade,
      nsdm_e_mchb.lgort                                  as Deposito,
      nsdm_e_mchb.charg,
      _Mara.BaseUnit                                     as meins,
      @Semantics.quantity.unitOfMeasure : 'meins'
      nsdm_e_mchb.clabs
}
where
  I_ProductionVersion.ProductionVersionIsLocked = ''
  and   I_ProductionVersion.ValidityEndDate           > $session.system_date
  and   R_BatchCharacteristicValueTP.ClassType             =  '023'
  and   nsdm_e_mchb.clabs                                  >  0
