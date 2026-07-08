# GAP 265 - Descarga Outbound - Action Guide Revisado

Author: RTiezzi  
Request/CHARM: ZPQ2C_265_20260703_082358

## 1. Bloqueio atual
Erro de ativacao na classe ZCLQ2C_265_DESCARGA_GRANEL:

Type "ZDEQ2C_265_DESC_DESTTANK" is unknown.

Objeto afetado: ZCLQ2C_265_DESCARGA_GRANEL (estrutura ty_u200_h, campo DESTTANK).

## 2. Analise obrigatoria antes de criar DDIC
| Campo | Tipo usado na classe | Existe no Inbound? | Existe em objetos comuns? | Existe equivalente na Carga? | Decisao | Acao |
|---|---|---|---|---|---|---|
| ORDERNUM | ZDEQ2C_265_ORDER_NUM | Sim | Nao | Sim (mesmo) | Reutilizar | Nao criar; garantir ativo no ambiente |
| INVOQTYL | ZDEQ2C_265_DESC_INVOQTYL | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| INVOQTYKG | ZDEQ2C_265_DESC_INVOQKG | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| DESTTANK | ZDEQ2C_265_DESC_DESTTANK | Nao | Sim | Parcial (SOURCET na Carga, sem mesma semantica) | Reutilizar nome atual | Nao criar novo por padrao; transportar/ativar ZDEQ2C_265_DESC_DESTTANK de objetos_comuns |
| PRODNUM | ZDEQ2C_265_PROD_NUM | Sim | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| PRODNAME | ZDEQ2C_265_PROD_NAME | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| PRODDEN | ZDEQ2C_265_PROD_DEN | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| UNLOADLN | ZDEQ2C_265_LOAD_LINE | Sim (LINE2USE) | Nao | Sim (LOADLINE) | Reutilizar | Nao criar |
| UNLOADPT | ZDEQ2C_265_LOAD_PTFM | Nao | Nao | Sim (LOADPTFM) | Reutilizar | Nao criar |
| TRUCKID | ZDEQ2C_265_TRUCK_ID | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| COLORYN | ZDEQ2C_265_DESC_COLORYN | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| PPRDNAME | ZDEQ2C_265_PPRD_NAME | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| PPRODNUM | ZDEQ2C_265_PPRD_NUM | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| SAMPLEYN | ZDEQ2C_265_DESC_SAMPLEYN | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| LABMAN | ZDEQ2C_265_DESC_LABMAN | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| LADAPPTM | ZDEQ2C_265_DESC_LADAPPTM | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| INVOICEN | ZDEQ2C_265_DESC_INVOICEN | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| BATCHIDS | ZDEQ2C_265_DESC_BATCHIDS | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| MSGRCVTM | ZDEQ2C_265_MSGRCVTM | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| CARTID | ZDEQ2C_265_DESC_CARTID | Nao | Sim | Nao | Reutilizar | Transportar de objetos_comuns se ausente |
| SORDRNM | ZDEQ2C_265_ORDER_NUM | Sim | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| SEALCODE | ZDEQ2C_265_DESC_SEALCODE | Sim | Sim | Nao | Reutilizar | Nao criar novo |
| SCOLOR | ZDEQ2C_265_SEALCLR | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| SSEALID | ZDEQ2C_265_SEAL_NUM | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |
| SSEALQTY | ZDEQ2C_265_SEAL_QTY | Nao | Nao | Sim (mesmo) | Reutilizar | Nao criar |

Decisao especifica para DESTTANK:
- Campo nao existe no layout de Inbound U301-H como DESTTANK; Inbound usa DESTTYRN (S/N) e COMPDROP, que nao substituem tanque destino.
- Nome tecnico ZDEQ2C_265_DESC_DESTTANK existe em objetos_comuns e esta coerente com o delta U200-H do Outbound.
- Tipo/tamanho com evidencia de repositorio: CHAR(10) no objeto comum.
- Acao correta: transportar/ativar o objeto comum; criar do zero apenas se o objeto comum estiver inconsistente/inexistente no baseline do pacote.

## 3. Objetos com acao real
| Ordem | Objeto | Tipo | Acao | Detalhe tecnico |
|---|---|---|---|---|
| 1 | ZDEQ2C_265_DESC_DESTTANK | Data Element | Corrigir dependencia | Objeto existe em objetos_comuns; transportar/ativar no ambiente antes da classe |
| 2 | ZDEQ2C_265_DESC_* usados no Outbound (INVOQTYL, INVOQKG, COLORYN, SAMPLEYN, LABMAN, LADAPPTM, INVOICEN, BATCHIDS, CARTID, SEALCODE) | Data Elements | Validar presenca e ativar | Mesma fonte comum usada no Inbound; nao recriar |
| 3 | ZCLQ2C_265_DESCARGA_GRANEL | Classe | Ativar | Ativar apos DDIC comum ativo |
| 4 | ZRQ2C_DESCARGA_GRANEL | Report | Ativar/testar | Runner manual do Outbound |

## 4. Matriz de criacao DDIC, somente se criacao for inevitavel
No estado atual, nao ha criacao DDIC inevitavel confirmada.

| Objeto | Tipo DDIC | Tipo base | Tamanho | Decimais | Descricao | Evidencia |
|---|---|---|---|---|---|---|
| Nenhum (por enquanto) | - | - | - | - | Nao criar ainda | Todos os tipos de acao do Outbound possuem fonte em objetos_comuns ou pacote base |

## 5. Ordem correta de acao
1. Comparar tipos da classe Outbound com Inbound e objetos_comuns (copy-first).
2. Confirmar em SE11/ADT se ZDEQ2C_265_DESC_DESTTANK existe no ambiente.
3. Se ausente, transportar/ativar ZDEQ2C_265_DESC_DESTTANK do pacote comum (nao criar novo inicialmente).
4. Validar os demais ZDEQ2C_265_DESC_* usados no Outbound e transportar apenas os ausentes.
5. Ativar DDIC.
6. Ativar ZCLQ2C_265_DESCARGA_GRANEL.
7. Ativar ZRQ2C_DESCARGA_GRANEL.
8. Testar geracao U200-H/U200-S.

## 6. O que nao fazer
- Nao recriar Data Element sem comparar com Inbound e objetos_comuns.
- Nao criar novo objeto so porque a classe nao ativa.
- Nao listar objetos sem acao real.
- Nao assumir CHAR(10), CHAR(7), DEC ou NUMC sem evidencia de layout/objeto-base.
- Nao divergir do copy-first ja adotado no Inbound.
