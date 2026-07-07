# Gap 265 - Implementation Guide V2 (DDIC only)

## Objetivo

Este documento lista somente o que precisa ser ajustado no Dicionario de Dados para o Gap 265 de Descarga.

Nao inclui refatoracao de classe, runner, job, logica de negocio ou validacao funcional fora do DDIC.

## Leitura base

- EF: [EF_GAP_265_DESCARGA.md](../EF_GAP_265_DESCARGA.md)
- Persistencia e retorno: [inbound/ztq2c_pcs_det_d.tabl.xml](inbound/ztq2c_pcs_det_d.tabl.xml), [inbound/ztq2c_pcs_itm_d.tabl.xml](inbound/ztq2c_pcs_itm_d.tabl.xml)
- Log tecnico: [inbound/ztbq2c_descgralog.tabl.xml](inbound/ztbq2c_descgralog.tabl.xml)
- Base compartilhada: [COPILOT_CORRECAO_GAP265_x_GAP340.md](COPILOT_CORRECAO_GAP265_x_GAP340.md)

## O que ja existe e nao deve ser recriado

- `ZTBQ2C_CTRL_PCS` ja existe e e compartilhada entre Carga e Descarga. Nao copiar, nao renomear, nao recriar.
- `ZTBQ2C_DESCGRALOG` ja existe no repo como tabela de log da Descarga. Nao substituir por `ZTBQ2C_RETGRALOG`.
- Os data elements de `objetos_comuns` ja estao modelados como objetos da Descarga compartilhados entre inbound e outbound. Nao listar como criacao nova se o arquivo ja existe no repo.

## Ajustes de DDIC obrigatorios

### 1. `ZTQ2C_PCS_DET_D` - header de retorno

Origem funcional: `ZTQ2C_PCS_DET`.

Estado do repo: o arquivo existe em [inbound/ztq2c_pcs_det_d.tabl.xml](inbound/ztq2c_pcs_det_d.tabl.xml).

Ajustes obrigatorios:

- Manter a tabela como copia adaptada da estrutura da Carga.
- Revalidar a chave tecnica para `MANDT + SHNUMBER + REMESSA + ITEM_REMESSA`.
- Garantir que `ORDERNUM` fique como campo nao-chave.
- Confirmar se `TRKINTWT` e `TRKFNLWT` devem permanecer com o tamanho atual ou se precisam ser ajustados para refletir o layout real do PCS.
- Os demais campos do U301-H devem continuar usando os data elements comuns ja existentes, sem criar DTEL novo se o objeto ja estiver no repositorio.

### 2. `ZTQ2C_PCS_ITM_D` - lacres de retorno

Origem funcional: `ZTQ2C_PCS_ITM`.

Estado do repo: o arquivo existe em [inbound/ztq2c_pcs_itm_d.tabl.xml](inbound/ztq2c_pcs_itm_d.tabl.xml).

Ajustes obrigatorios:

- Manter a tabela como copia adaptada da estrutura da Carga.
- Revalidar a chave tecnica para `MANDT + SHNUMBER + REMESSA + ITEM_REMESSA + SEQNO`.
- Garantir que `SORDRNM` fique como campo nao-chave.
- Manter `SEALCODE` e `SEALYRN` com os data elements da Descarga ja existentes.

### 3. `ZTBQ2C_DESCGRALOG` - log tecnico

Estado do repo: o arquivo existe em [inbound/ztbq2c_descgralog.tabl.xml](inbound/ztbq2c_descgralog.tabl.xml).

Ajustes obrigatorios:

- Manter a tabela como log tecnico da Descarga.
- Nao criar um log novo com nome de Carga para este fluxo.
- Confirmar apenas consistencia de chaves e campos com o uso esperado pelo retorno da Descarga.

### 4. Data elements comuns da Descarga

Os DTELs abaixo ja aparecem como objetos do repo e devem ser tratados como compartilhados da Descarga, nao como criacao duplicada:

- `ZDEQ2C_265_DESC_TRKINTWT`
- `ZDEQ2C_265_DESC_TRKFNLWT`
- `ZDEQ2C_265_DESC_LINEEMTY`
- `ZDEQ2C_265_DESC_PT_YRN`
- `ZDEQ2C_265_DESC_DESTTYRN`
- `ZDEQ2C_265_DESC_TRKIDY2N`
- `ZDEQ2C_265_DESC_CLR_HOSE`
- `ZDEQ2C_265_DESC_AVVERYRN`
- `ZDEQ2C_265_DESC_COMPDROP`
- `ZDEQ2C_265_DESC_TRKGDRYN`
- `ZDEQ2C_265_DESC_TRKBKACT`
- `ZDEQ2C_265_DESC_TRKMTOFF`
- `ZDEQ2C_265_DESC_LABINFO`
- `ZDEQ2C_265_DESC_AVVEREND`
- `ZDEQ2C_265_DESC_STARTTME`
- `ZDEQ2C_265_DESC_ENDTIME`
- `ZDEQ2C_265_DESC_SUPNAME`
- `ZDEQ2C_265_DESC_OPSNAME`
- `ZDEQ2C_265_DESC_SEALCODE`
- `ZDEQ2C_265_DESC_SEALYRN`
- `ZDEQ2C_265_DESC_DESTTANK`
- `ZDEQ2C_265_DESC_COLORYN`
- `ZDEQ2C_265_DESC_SAMPLEYN`
- `ZDEQ2C_265_DESC_LABMAN`
- `ZDEQ2C_265_DESC_LADAPPTM`
- `ZDEQ2C_265_DESC_INVOQTYL`
- `ZDEQ2C_265_DESC_INVOQKG`
- `ZDEQ2C_265_DESC_INVOICEN`
- `ZDEQ2C_265_DESC_BATCHIDS`
- `ZDEQ2C_265_DESC_CARTID`

## Ponto ainda pendente de confirmacao de DDIC

- `TRKINTWT` e `TRKFNLWT`: o repo mostra os DTELs existentes, mas o tamanho final do campo precisa ser confirmado contra o layout funcional antes de ativacao final da tabela.
- Se o objetivo for espelhar o padrao ja usado na Carga, a prioridade e alinhar a chave das tabelas de persistencia para nao usar `ORDERNUM`/`SORDRNM` como chave primaria.

## O que nao entra neste guia

- Refatoracao de classe ABAP.
- Ajuste de parsing de arquivo.
- Ajuste de job, runner ou mensagens.
- Mudanca de logica de gravacao fora da definicao das tabelas.
- Criacao de objetos legados antigos como `ZDESCARGA_INTERFACE_PCS`.

## Resultado esperado

Ao final, o pacote DDIC da Descarga deve ficar restrito a:

- `ZTQ2C_PCS_DET_D` como header de retorno.
- `ZTQ2C_PCS_ITM_D` como detalhe de lacres.
- `ZTBQ2C_DESCGRALOG` como log tecnico.
- `ZTBQ2C_CTRL_PCS` reaproveitada sem copia.
- Data elements comuns ja existentes em `objetos_comuns`.