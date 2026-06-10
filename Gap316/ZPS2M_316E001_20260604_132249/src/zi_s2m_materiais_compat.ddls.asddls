@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic View - Materiais Compatíveis'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_S2M_MATERIAIS_COMPAT
  as select from I_MasterRecipeMaterialAssgmt
    inner join   ZI_S2M_PRODUCTIONVERSION     on  I_MasterRecipeMaterialAssgmt.Material              = ZI_S2M_PRODUCTIONVERSION.Material
                                              and I_MasterRecipeMaterialAssgmt.Plant                 = ZI_S2M_PRODUCTIONVERSION.Plant
                                              and I_MasterRecipeMaterialAssgmt.BillOfOperationsGroup = ZI_S2M_PRODUCTIONVERSION.Grupo
    inner join   R_BatchCharacteristicValueTP on  ZI_S2M_PRODUCTIONVERSION.Material                 = R_BatchCharacteristicValueTP.Material
    /* V1 baseline - remover hardcode de IDs via descricao da caracteristica */
    inner join   I_ClfnCharcDesc              on  R_BatchCharacteristicValueTP.CharcInternalID = I_ClfnCharcDesc.CharcInternalID
                                              and I_ClfnCharcDesc.Language                    = 'P'
                                              and I_ClfnCharcDesc.CharcDescription            = 'Grp Receita Mestre'
                                              and I_ClfnCharcDesc.ValidityStartDate           <= $session.system_date
                                              and I_ClfnCharcDesc.ValidityEndDate             >= $session.system_date
                                              and I_ClfnCharcDesc.IsDeleted                   = ''
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
      ZI_S2M_PRODUCTIONVERSION.ProductionVersion,
      ZI_S2M_PRODUCTIONVERSION.BillOfMaterialVariant,
      ZI_S2M_PRODUCTIONVERSION.BillOfMaterialVariantUsage,
      R_BatchCharacteristicValueTP.CharcInternalID,
      R_BatchCharacteristicValueTP.CharcValue,
      R_BatchCharacteristicValueTP.Batch                 as Lote,
      ZI_S2M_PRODUCTIONVERSION.ValidityEndDate           as Validade,
      nsdm_e_mchb.lgort                                  as Deposito,
      nsdm_e_mchb.charg,
      _Mara.BaseUnit                                     as meins,
      @Semantics.quantity.unitOfMeasure : 'meins'
      nsdm_e_mchb.clabs
}
where
  (
        ZI_S2M_PRODUCTIONVERSION.sub                       <> 'DES'
    and ZI_S2M_PRODUCTIONVERSION.sub                       <> 'REP'
    and ZI_S2M_PRODUCTIONVERSION.sub                       <> 'REM'
    and ZI_S2M_PRODUCTIONVERSION.sub                       <> 'GRA'
  )
  and   ZI_S2M_PRODUCTIONVERSION.ProductionVersionIsLocked =  ''
  and   ZI_S2M_PRODUCTIONVERSION.ValidityEndDate           > $session.system_date
  and   R_BatchCharacteristicValueTP.ClassType             =  '023'
  /* V05 - Sem hardcode: garantir consistencia do grupo pela semantica da caracteristica */
  and   R_BatchCharacteristicValueTP.CharcValue            =  I_MasterRecipeMaterialAssgmt.BillOfOperationsGroup
  and   nsdm_e_mchb.clabs                                  >  0
