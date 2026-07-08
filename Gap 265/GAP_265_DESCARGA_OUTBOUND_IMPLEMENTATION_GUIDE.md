# GAP 265 - Descarga Outbound - Action Guide Revisado

Author: RTiezzi  
Request/CHARM: ZPQ2C_265_20260703_082358

## 1. Bloqueio atual
Erro de ativacao na classe ZCLQ2C_265_DESCARGA_GRANEL:

Type "ZDEQ2C_265_DESC_DESTTANK" is unknown.

## 2. Acoes obrigatorias
| Ordem | Objeto | Tipo | Acao obrigatoria | Resultado esperado |
|---|---|---|---|---|
| 1 | ZDEQ2C_265_DESC_DESTTANK | Data Element | Transportar de objetos_comuns para o ambiente e ativar | Dependencia DDIC resolvida |
| 2 | ZDEQ2C_265_DESC_INVOQTYL, ZDEQ2C_265_DESC_INVOQKG, ZDEQ2C_265_DESC_COLORYN, ZDEQ2C_265_DESC_SAMPLEYN, ZDEQ2C_265_DESC_LABMAN, ZDEQ2C_265_DESC_LADAPPTM, ZDEQ2C_265_DESC_INVOICEN, ZDEQ2C_265_DESC_BATCHIDS, ZDEQ2C_265_DESC_CARTID, ZDEQ2C_265_DESC_SEALCODE | Data Elements | Conferir no ambiente; transportar e ativar somente os ausentes | Outbound com DDIC comum completo |
| 3 | ZCLQ2C_265_DESCARGA_GRANEL | Classe | Ativar apos DDIC ativo | Classe ativa sem erro de tipo |
| 4 | ZRQ2C_DESCARGA_GRANEL | Report | Ativar e executar teste manual | Runner ativo e executando |

Decisao pratica para DESTTANK:
- Decisao: transportar do pacote comum (nao criar do zero).
- Justificativa: objeto ja existe em objetos_comuns e e o tipo usado no Outbound atual.
- Pendencia objetiva unica: se o transporte nao existir/nao ativar no ambiente, abrir criacao controlada com base no layout U200-H aprovado.

## 3. DDIC com acao
| Objeto | Tipo DDIC | Acao | Fonte | Observacao tecnica |
|---|---|---|---|---|
| ZDEQ2C_265_DESC_DESTTANK | Data Element | Transportar e ativar | Gap 265/objetos_comuns | Bloqueio direto da ativacao da classe |
| ZDEQ2C_265_DESC_INVOQTYL | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_INVOQKG | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_COLORYN | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_SAMPLEYN | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_LABMAN | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_LADAPPTM | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_INVOICEN | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_BATCHIDS | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_CARTID | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_h |
| ZDEQ2C_265_DESC_SEALCODE | Data Element | Transportar/ativar se ausente | Gap 265/objetos_comuns | Usado em ty_u200_s |

## 4. Ajustes ABAP
| Objeto | Acao | Detalhe |
|---|---|---|
| ZCLQ2C_265_DESCARGA_GRANEL | Ativar | Sem refatoracao; apenas resolver dependencia DDIC |
| ZCLQ2C_265_DESC_COMMON | Reutilizar | Nao duplicar metodos comuns |
| ZRQ2C_DESCARGA_GRANEL | Ativar/testar | Validar execucao manual do Outbound |

## 5. Ordem de execucao
1. Transportar e ativar ZDEQ2C_265_DESC_DESTTANK a partir de objetos_comuns.
2. Conferir os demais ZDEQ2C_265_DESC_* do Outbound e transportar somente os ausentes.
3. Ativar DDIC.
4. Ativar ZCLQ2C_265_DESCARGA_GRANEL.
5. Ativar ZRQ2C_DESCARGA_GRANEL.
6. Executar teste de geracao U200-H e U200-S.

## 6. Checklist final
- [ ] ZDEQ2C_265_DESC_DESTTANK transportado e ativo
- [ ] ZDEQ2C_265_DESC_* do Outbound ativos
- [ ] ZCLQ2C_265_DESCARGA_GRANEL ativa
- [ ] ZRQ2C_DESCARGA_GRANEL ativo
- [ ] Arquivos U200-H e U200-S gerados
- [ ] Descarga Inbound sem impacto
- [ ] Carga sem impacto
