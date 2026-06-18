@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic - Consolidado Standard Descarga'
define view entity ZR_Q2C_MONI_BASE
  as select distinct from I_BulkShipmentItem  as ShpItem

    inner join              ZI_Q2C_MATQTY       as MatQty
      on  MatQty.Shnumber = ShpItem.BulkShipment
      and MatQty.Shitem   = ShpItem.BulkShipmentItem

    // NF-e de SAIDA (transferencia entre centros): item de NF cujo doc-origem e a remessa do TD.
    // reftyp 'LI' = remessa (Lieferung). Clean core: views liberadas I_BR_NFItem / I_BR_NFElectronic_C.
    left outer join         I_BR_NFItem         as NfSaida
      on  NfSaida.BR_NFSourceDocumentNumber = ShpItem.BulkShipmentUndrlgDocument
      and NfSaida.BR_NFSourceDocumentItem   = MatQty.DeliveryItem
      and NfSaida.BR_NFSourceDocumentType   = 'LI'

    left outer join         I_BR_NFElectronic_C as NfSaidaEle
      on  NfSaidaEle.BR_NotaFiscal = NfSaida.BR_NotaFiscal

  association [1..1] to ZR_Q2C_VALIDSHIPMENT   as _Shipment       on  $projection.Shnumber = _Shipment.ShipmentNumber

  association [1..1] to ZZ1_TVARVC_Q2C         as _CboDoc         on  _CboDoc.LOW  = ShpItem.SDDocumentCategory
                                                                  and _CboDoc.NAME = 'ZTD_DOCTYP'

  association [0..1] to I_DeliveryDocument     as _DeliveryHeader on  $projection.DeliveryNumber = _DeliveryHeader.DeliveryDocument

  association [0..1] to I_DeliveryDocumentItem as _DeliveryItem   on  $projection.DeliveryNumber = _DeliveryItem.DeliveryDocument
                                                                  and $projection.DeliveryItem   = _DeliveryItem.DeliveryDocumentItem

  association [0..1] to I_BulkShipmentVehicle  as _Vehicle        on  $projection.Shnumber = _Vehicle.BulkShipment

  association [0..1] to ZI_Q2C_DRIVER_NAME     as _Driver         on  $projection.Shnumber = _Driver.shnumber

  association [0..1] to ZI_Q2C_AllocatedMat    as _AllocatedMat   on  $projection.Shnumber = _AllocatedMat.Shnumber
                                                                  and $projection.MatItm   = _AllocatedMat.MatItm

  association [0..*] to ZI_Q2C_Compartment     as _Compartment    on  $projection.Shnumber  = _Compartment.Shnumber
                                                                  and $projection.MatItm    = _Compartment.MatItm
                                                                  and _Compartment.TdAction = '1'

  association [0..1] to ZI_Q2C_DESCARGA        as _Descarga       on  $projection.Shnumber       = _Descarga.Shnumber
                                                                  and $projection.DeliveryNumber = _Descarga.Remessa
                                                                  and $projection.DeliveryItem   = _Descarga.ItemRemessa

  association [0..1] to edobrincoming          as _Edoc           on  _Edoc.delnum = $projection.DeliveryNumber
{
  key ShpItem.BulkShipment               as Shnumber,
  key ShpItem.BulkShipmentUndrlgDocument as DeliveryNumber, // EF: LIPS-VBELN
  key MatQty.DeliveryItem                as DeliveryItem,   // EF: LIPS-VBELP (via OIGSVMQ.posnr)
      ShpItem.BulkShipmentItem           as Shitem,
      ShpItem.SDDocumentCategory,

      MatQty.MatItm,                                        // item de material (OIGSVMQ.mat_itm)

      _Shipment.ShipmentType,
      _Shipment.ShipmentStatus, // EF: OIGSSF

      _DeliveryItem.Material,                               // EF: MATNR
      _DeliveryItem.Plant,                                  // EF: WERKS
      @Semantics.quantity.unitOfMeasure: 'DeliveryUnit'
      _DeliveryItem.ActualDeliveryQuantity as DeliveryQty,  // EF: LFIMG
      _DeliveryItem.DeliveryQuantityUnit   as DeliveryUnit, // EF: VRKME

      coalesce( _Descarga.Status, '00' )   as Status,

      _Edoc.accesskey                      as ChaveAcesso,
      // Chave de acesso da NF-e de SAIDA (44 dig) montada pela view standard. Vazia = nao e transferencia.
      NfSaidaEle.BR_NFeAccessKey           as ChaveSaida,

      _Vehicle,
      _AllocatedMat,
      _Compartment,
      _Shipment,
      _DeliveryHeader,
      _DeliveryItem,
      _Driver
}
where
      _Shipment.ShipmentNumber is not null
  and _CboDoc.LOW              is not null

