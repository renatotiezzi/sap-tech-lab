@EndUserText.label: 'Consumo - Monitoramento Descarga OIL'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName: 'TD Descarga',
  typeNamePlural: 'TDs Descarga',
  title: { type: #STANDARD, value: 'Shnumber' },
  description: { type: #STANDARD, value: 'StatusDescricao' }
}

define root view entity ZC_Q2C_MONI_DESCARGA
  provider contract transactional_query
  as projection on ZI_Q2C_MONI_DESCARGA as Base
{
      // Botao "Registrar chegada Veiculo" e' uma CUSTOM ACTION unica no app (manifest) que roteia
      // entre registrarChegadaCompra (com chave) e registrarChegadaRetorno (sem chave). Por isso
      // NAO usamos @UI #FOR_ACTION aqui (evita botoes duplicados na toolbar).
      @UI: { lineItem:       [ { position: 10, importance: #HIGH } ],
             selectionField: [ { position: 10 } ] }
      @EndUserText.label: 'Nº TD'
  key Shnumber,

      @UI: { lineItem:       [ { position: 20, importance: #HIGH } ],
             identification: [ { position: 20 } ],
             selectionField: [ { position: 20 } ] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_DeliveryDocumentStdVH', element: 'DeliveryDocument' } }]
      @EndUserText.label: 'Remessa'
  key DeliveryNumber,

      @UI: { lineItem:       [ { position: 30, importance: #MEDIUM } ],
             identification: [ { position: 30 } ] }
      @EndUserText.label: 'Item Remessa'
  key DeliveryItem,

      @UI: { lineItem:       [ { position: 40, importance: #LOW } ],
             identification: [ { position: 40 } ] }
      @EndUserText.label: 'Tipo TD'
      ShipmentType,

      @UI: { lineItem:       [ { position: 50, importance: #LOW } ],
             identification: [ { position: 50 } ],
             selectionField: [ { position: 50 } ] }
      @EndUserText.label: 'Status TD'
      ShipmentStatus,

      @UI: { selectionField: [ { position: 5 } ] }
      @Consumption.valueHelpDefinition: [{ entity:            { name: 'ZI_CA_DOMAIN_VALUE_HELP', element: 'DomainValueL' },
                                           additionalBinding: [ { localConstant: 'ZDOQ2C_DESC_STATUS', element: 'DomainName', usage: #FILTER } ] }]
      @EndUserText.label: 'Status'
      Status,

      @UI: { lineItem:       [ { position: 60, importance: #HIGH } ],
             identification: [ { position: 60 } ] }
      @EndUserText.label: 'Status Descrição'
      StatusDescricao,

      @UI: { lineItem:       [ { position: 70, importance: #MEDIUM } ],
             identification: [ { position: 70 } ],
             selectionField: [ { position: 70 } ] }
      @EndUserText.label: 'Tipo Processo'
      TipoProcesso,

      @UI: { identification: [ { position: 80 } ] }
      @EndUserText.label: 'Cliente'
      Kunnr,

      @UI: { identification: [ { position: 90 } ] }
      @EndUserText.label: 'Peso Bruto'
      Btgew,

      @UI: { identification: [ { position: 100 } ] }
      @EndUserText.label: 'Peso Líquido'
      Ntgew,
      HeaderWeightUnit,

      @UI: { lineItem:       [ { position: 80, importance: #HIGH } ],
             identification: [ { position: 110 } ],
             selectionField: [ { position: 80 } ] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_ProductStdVH', element: 'Product' } }]
      @EndUserText.label: 'Material'
      Matnr,

      @UI: { lineItem:       [ { position: 90, importance: #MEDIUM } ],
             identification: [ { position: 120 } ],
             selectionField: [ { position: 90 } ] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PlantStdVH', element: 'Plant' } }]
      @EndUserText.label: 'Centro'
      Werks,

      @UI: { lineItem:       [ { position: 100, importance: #MEDIUM } ],
             identification: [ { position: 130 } ] }
      @EndUserText.label: 'Quantidade'
      Lfimg,
      Meins,

      @UI: { lineItem:       [ { position: 110, importance: #LOW } ],
             identification: [ { position: 140 } ] }
      @EndUserText.label: 'Descrição Material'
      Arktx,

      @UI: { lineItem:       [ { position: 65, importance: #MEDIUM } ],
             identification: [ { position: 150 } ],
             selectionField: [ { position: 15 } ] }
      @EndUserText.label: 'Chave NF-e'
      ChaveNfe,

      @UI: { identification: [ { position: 160 } ] }
      @EndUserText.label: 'Nº NF'
      Nfnum,

      @UI: { identification: [ { position: 165 } ] }
      @EndUserText.label: 'Qtd NF-e'
      QtdeNfe,
      UmNfe,

      @UI: { lineItem:       [ { position: 120, importance: #LOW } ],
             identification: [ { position: 170 } ],
             selectionField: [ { position: 110 } ] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_BusinessPartnerVH', element: 'BusinessPartner' } }]
      @EndUserText.label: 'Fornecedor'
      Lifnr,

      @UI: { identification: [ { position: 180 } ] }
      @EndUserText.label: 'Nome Fornecedor'
      LifnrName,

      @UI: { identification: [ { position: 190 } ],
             selectionField: [ { position: 120 } ] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_InspectionLotStdVH', element: 'InspectionLot' } }]
      @EndUserText.label: 'Lote QM'
      LoteQm,

      @UI: { identification: [ { position: 200 } ],
             selectionField: [ { position: 130 } ] }
      @EndUserText.label: 'Decisão de Uso'
      DuQm,

      @UI: { lineItem:       [ { position: 130, importance: #LOW } ],
             identification: [ { position: 210 } ],
             selectionField: [ { position: 140 } ] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_BusinessPartnerVH', element: 'BusinessPartner' } }]
      @EndUserText.label: 'Transportadora'
      Carrier,

      @UI: { identification: [ { position: 220 } ] }
      @EndUserText.label: 'Placa Cavalo'
      Vehicle,

      @UI: { identification: [ { position: 225 } ] }
      @EndUserText.label: 'Placa Carreta'
      VehId,

      @UI: { identification: [ { position: 230 } ] }
      @EndUserText.label: 'Seq. Veículo'
      VeHnr,

      @UI: { lineItem:       [ { position: 140, importance: #LOW } ],
             identification: [ { position: 240 } ] }
      @EndUserText.label: 'Motorista'
      DriverName,

      @UI: { identification: [ { position: 250 } ] }
      @EndUserText.label: 'Cód. Motorista'
      DriverCode,

      @UI: { identification: [ { position: 260 } ] }
      @EndUserText.label: 'Depósito'
      Lgort,

      @UI: { identification: [ { position: 270 } ] }
      @EndUserText.label: 'Lote'
      Charg,

      @UI: { identification: [ { position: 280 } ] }
      @EndUserText.label: 'Criado em'
      Erdat,

      @UI: { identification: [ { position: 290 } ] }
      @EndUserText.label: 'Criado por'
      Ernam,

      /* Associação para edição/detalhe da persistência ZDESCARGA */
      ZDescarga
}
