@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Ponte item remessa/material OIGSVMQ'
define view entity ZI_Q2C_MATQTY
  as select from ZI_Q2C_Compartment
{
  key Shnumber     as Shnumber,
  key Shitem       as Shitem,
  key Posnr        as DeliveryItem,
      min( MatItm ) as MatItm      // material principal (menor mat_itm)
}
group by
  Shnumber,
  Shitem,
  Posnr
