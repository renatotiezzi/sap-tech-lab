
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Status'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_R2R_STATUS_VH 
 as select from dd07l
  inner join dd07t
    on  dd07t.domname    = dd07l.domname
    and dd07t.domvalue_l = dd07l.domvalue_l
    and dd07t.ddlanguage = $session.system_language
{
  @UI.textArrangement: #TEXT_ONLY
  @ObjectModel.text.element: ['StatusText']
  key cast( dd07l.domvalue_l as zde_r2r_status_doc ) as Status,
  cast( dd07t.ddtext as abap.char(60) ) as StatusText
}
where dd07l.domname  = 'ZDO_R2R_STATUS_DOC'
  and dd07l.as4local = 'A'
 