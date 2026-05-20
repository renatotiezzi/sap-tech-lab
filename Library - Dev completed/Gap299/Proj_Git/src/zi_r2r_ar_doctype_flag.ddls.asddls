@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Position - SD DocTypes (TVARV)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_R2R_AR_DOCTYPE_FLAG
  as select from ZI_R2R_TVARV as T
{
  key T.Low as AccountingDocumentType
}
where T.Name = 'Z_R2R_AR_POSITION_DOCTYPE'
  and T.Type = 'S';
