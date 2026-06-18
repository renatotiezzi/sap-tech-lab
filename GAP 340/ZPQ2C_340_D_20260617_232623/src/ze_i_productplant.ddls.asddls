@AbapCatalog.sqlViewAppendName: 'ZEIPRODUCTPLANT'
@EndUserText.label: 'Extension View I_ProductPlant'
@VDM.viewExtension:true
extend view I_ProductPlant with ZE_I_ProductPlant
{
    Plant.umrsl
}
