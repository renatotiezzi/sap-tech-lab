@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS for TVARV'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_R2R_TVARV as select from tvarvc

{

key name as Name,
key type as Type,
key numb as Numb,
sign as Sign,
opti as Opti,
low as Low,
high as High
    
}
