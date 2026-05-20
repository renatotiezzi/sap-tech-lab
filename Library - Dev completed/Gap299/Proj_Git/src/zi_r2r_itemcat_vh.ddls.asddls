@AbapCatalog.sqlViewName: 'ZARITCATVH'
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help para Categoria do Item'
@ObjectModel.resultSet.sizeCategory: #XS 
@Metadata.ignorePropagatedAnnotations: true
define view ZI_R2R_ITEMCAT_VH

  as select from dd07l
  inner join dd07t
    on  dd07t.domname    = dd07l.domname
    and dd07t.domvalue_l = dd07l.domvalue_l
    and dd07t.ddlanguage = $session.system_language

{

  @UI.textArrangement: #TEXT_ONLY
  @ObjectModel.text.element: ['ItemCategoryText']
  key cast( dd07l.domvalue_l as zde_r2r_item_category ) as ItemCategory,
  cast( dd07t.ddtext as abap.char(60) ) as ItemCategoryText
  
}

where dd07l.domname  = 'ZDO_R2R_ITEM_CATEGORY'
  and dd07l.as4local = 'A'

 