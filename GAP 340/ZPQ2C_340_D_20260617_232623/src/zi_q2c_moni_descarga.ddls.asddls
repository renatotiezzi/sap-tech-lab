@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface - Monitoramento Descarga OIL'
@Metadata.allowExtensions: true
define root view entity ZI_Q2C_MONI_DESCARGA
  as select distinct from ZR_Q2C_MONI_BASE as Base

  association [0..1] to ZI_Q2C_DESCARGA as ZDescarga on  $projection.Shnumber       = ZDescarga.Shnumber
                                                     and $projection.DeliveryNumber = ZDescarga.Remessa
                                                     and $projection.DeliveryItem   = ZDescarga.ItemRemessa

  association [0..1] to zi_ca_domain_value_help as _StatusText on  _StatusText.DomainName   = 'ZDOQ2C_DESC_STATUS'
                                                              and _StatusText.DomainValueL = Base.Status
{
  key Base.Shnumber,
  key Base.DeliveryNumber, // EF: LIPS-VBELN
  key Base.DeliveryItem,   // EF: LIPS-VBELP
      Base.ShipmentType,   // EF: SHTYPE
      Base.ShipmentStatus, // EF: OIGSSF

      Base.Status,

      _StatusText.DomeValueText                   as StatusDescricao,

      Base._DeliveryHeader.ShipToParty            as Kunnr,
      @Semantics.quantity.unitOfMeasure: 'HeaderWeightUnit'
      Base._DeliveryHeader.HeaderGrossWeight      as Btgew,
      @Semantics.quantity.unitOfMeasure: 'HeaderWeightUnit'
      Base._DeliveryHeader.HeaderNetWeight        as Ntgew,
      Base._DeliveryHeader.HeaderWeightUnit, // EF: GEWEI

      Base._DeliveryItem.Material                 as Matnr,
      Base._DeliveryItem.Plant                    as Werks,
      @Semantics.quantity.unitOfMeasure: 'Meins'
      Base._DeliveryItem.ActualDeliveryQuantity   as Lfimg,
      Base._DeliveryItem.DeliveryQuantityUnit     as Meins,
      Base._DeliveryItem.DeliveryDocumentItemText as Arktx,


      ZDescarga.TipoProcesso,
      coalesce( ZDescarga.ChaveNfe, coalesce( Base.ChaveSaida, Base.ChaveAcesso ) ) as ChaveNfe,
      ZDescarga.Nfnum,
      @Semantics.quantity.unitOfMeasure: 'UmNfe'
      ZDescarga.QtdeNfe,
      ZDescarga.UmNfe,
      ZDescarga.Lifnr,
      ZDescarga.LifnrName,

      ZDescarga.LoteQm,   // EF 5.1: filtro P_QALS (QALS-PRUEFLOS)
      ZDescarga.DuQm,     // EF 5.1: filtro R_UD_CODE (QALS-STAT35 / Decisao de Uso)



      Base._Vehicle.TransportationVehicle         as Vehicle,
      Base._Vehicle.BulkShipmentVehicleSequence   as VeHnr,
      Base._Vehicle.VehId,
      Base._Vehicle.BulkShipmentCarrier           as Carrier,

      Base._Driver.DriverCode,
      Base._Driver.DriverName,

      Base._AllocatedMat.Lgort,
      Base._AllocatedMat.Charg,

      //-- Compartimento (TpuNr/SeqNmbr/Trqty) REMOVIDO da listagem principal:
      //   _Compartment é [0..*] e multiplicaria o item de remessa por N compartimentos.
      //   Disponível via navegação Base._Compartment para tela de detalhe.

      ZDescarga.Erdat,
      ZDescarga.Ernam,

      ZDescarga
}
