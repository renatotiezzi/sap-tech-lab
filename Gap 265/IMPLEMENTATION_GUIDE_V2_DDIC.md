# Gap 265 - Implementation Guide V2 (DDIC only)

## Criar ou ajustar

- `ZTQ2C_PCS_DET_D`
  - Ajustar chave para `MANDT + DELIVERY + PCSITEM`.
  - `DELIVERY` representa a remessa funcional.
  - `PCSITEM` representa o item da remessa funcional.
  - `SEQ_NMBR` representa a sequencia tecnica do header.
  - Manter `ORDERNUM` como nao-chave.
  - Confirmar `TRKINTWT` e `TRKFNLWT` como `NUMC(5)`.
  - Manter `STARTTME` e `ENDTIME` como `CHAR(17)`.

- `ZTQ2C_PCS_ITM_D`
  - Ajustar chave para `MANDT + VBELN + PCSITEM`.
  - `VBELN` representa a remessa funcional.
  - `PCSITEM` representa o item funcional da remessa.
  - Manter `SORDRNM` como nao-chave.
  - `TDITEM` representa a sequencia funcional do lacre.

- `ZTBQ2C_DESCGRALOG`
  - Manter como log tecnico da Descarga.

## Reutilizar sem recriar

- `ZTBQ2C_CTRL_PCS`
- DTELs de `objetos_comuns` que ja existem para a Descarga

## Nao entra aqui

- Classes
- Job / runner
- Logica de arquivo
- Mensagens
- Qualquer objeto legado de Carga ou nomes antigos como `ZDESCARGA_INTERFACE_PCS`