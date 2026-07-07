# Gap 265 - Implementation Guide V2 (DDIC only)

## Criar ou ajustar

- `ZTQ2C_PCS_DET_D`
  - Ajustar chave para `MANDT + SHNUMBER + REMESSA + ITEM_REMESSA`.
  - Manter `ORDERNUM` como nao-chave.
  - Confirmar `TRKINTWT` e `TRKFNLWT` como `NUMC(5)`.
  - Manter `STARTTME` e `ENDTIME` como `CHAR(17)`.

- `ZTQ2C_PCS_ITM_D`
  - Ajustar chave para `MANDT + SHNUMBER + REMESSA + ITEM_REMESSA + SEQNO`.
  - Manter `SORDRNM` como nao-chave.

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