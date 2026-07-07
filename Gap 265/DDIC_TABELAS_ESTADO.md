# Gap 265 - Estado real das tabelas DDIC

Este arquivo fica na raiz do Gap 265 para orientar a refatoracao.

## Conclusao da analise

- As classes ABAP inspecionadas nao apresentam erro de sintaxe no workspace.
- O ponto a tratar agora e Dicionario de Dados / ativacao, ou descompasso entre codigo e tabela no ambiente externo.
- Se houver algo alem de DDIC, nao entra aqui.

## Codigo observado

- O retorno ja referencia `remessa`, `item_remessa` e `seqno` no codigo atual.
- `ZTBQ2C_DESCGRALOG` tambem ja e usada como tipo e alvo de `MODIFY` no retorno.
- Portanto, o que aparece na tela do Eclipse nao bate com o texto atual do workspace e parece ser ativacao/stale state, nao refatoracao funcional pendente no ABAP.

## Tabelas reais

### `ZTQ2C_PCS_DET_D`

Header de retorno PCS Granel.

Chave:

- `MANDT`
- `DELIVERY`  
	Remessa funcional.
- `PCSITEM`  
	Item funcional da remessa.

Campo complementar:

- `SEQ_NMBR` representa a sequencia tecnica do header.

Campos que precisam ser mantidos/avaliados:

- `ORDERNUM` como nao-chave
- `TRKINTWT`
- `TRKFNLWT`
- `LINEEMTY`
- `PT_YRN`
- `DESTTYRN`
- `PRODNUMB`
- `LINE2USE`
- `TRKIDY2N`
- `CLRHOSE`
- `AVVERYRN`
- `COMPDROP`
- `TRKGDRYN`
- `TRKBKACT`
- `TRKMTOFF`
- `LABINFO`
- `AVVEREND`
- `STARTTME`
- `ENDTIME`
- `SUPNAME`
- `OPSNAME`

Leituras confirmadas no artefato:

- `TRKINTWT = NUMC(5)`
- `TRKFNLWT = NUMC(5)`
- `STARTTME = CHAR(17)`
- `ENDTIME = CHAR(17)`

### `ZTQ2C_PCS_ITM_D`

Lacres de retorno PCS Granel.

Chave:

- `MANDT`
- `VBELN`  
	Remessa funcional.
- `PCSITEM`  
	Item funcional da remessa.

Campos importantes:

- `SORDRNM` como nao-chave
- `SEALCODE`
- `SEALYRN`

Campo de sequencia:

- `TDITEM` representa a sequencia funcional dos lacres.

### `ZTBQ2C_DESCGRALOG`

Log tecnico da Descarga.

Chave:

- `MANDT`
- `TMSTMP`
- `INTID`
- `INTTY`

Campos de log:

- `INTST`
- `MSGTY`
- `MENSAGEM`

## O que nao recriar

- `ZTBQ2C_CTRL_PCS`
- `ZTBQ2C_DESCGRALOG`
- DTELs de `objetos_comuns` que ja existem para Descarga

## Se houver novo guide v2

Se a quebra for realmente de DDIC, o v2 deve listar somente:

- `ZTQ2C_PCS_DET_D`
- `ZTQ2C_PCS_ITM_D`
- `ZTBQ2C_DESCGRALOG`
- `ZTBQ2C_CTRL_PCS` como reaproveitamento
- qualquer DTEL realmente ausente no ambiente