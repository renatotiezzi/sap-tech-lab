@Metadata.layer: #CUSTOMER
@Metadata.allowExtensions: true
annotate entity ZC_S2M_MATERIAIS_COMPATIVEIS
{

  /* V05 - Customizações de UI: campos não relevantes para usuário final */

  /* Ocultar campos técnicos desnecessários */
  @UI.hidden: true
  Grupo;

  @UI.hidden: true
  Productionversion;

  @UI.hidden: true
  Validade;

  @UI.hidden: true
  boomatlinternalversioncounter;

  /* Renomear e posicionar campo de característica */
  @Semantics.label: 'Grupo de Receita Mestre'
  Charcvalue;

  /* Ocultar IDs internos de características */
  @UI.hidden: true
  Charcinternalid;

  @UI.hidden: true
  Charcinternalid2;

  @UI.hidden: true
  Charcinternalid3;

  /* Ocultar outros campos técnicos de controle */
  @UI.hidden: true
  Billofmaterialvariant;

  @UI.hidden: true
  Billofmaterialvariantusage;

  @UI.hidden: true
  bootomaterialinternalid;

  @UI.hidden: true
  LastChangedAt;

}
