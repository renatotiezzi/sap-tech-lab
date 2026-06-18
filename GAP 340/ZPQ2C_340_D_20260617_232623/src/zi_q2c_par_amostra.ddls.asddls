@EndUserText.label: 'Param - Registrar Amostra'
define abstract entity ZI_Q2C_PAR_AMOSTRA
{
  @Semantics.quantity.unitOfMeasure: 'umAmostra'
  qtdAmostra      : abap.quan(13,3);
  umAmostra       : abap.unit(3);
  lgortAmostra    : abap.char(4);
  compartimento   : abap.char(10);
  pontoAmostragem : abap.char(20);
  densidadeNfe    : oib_tdich;
}
