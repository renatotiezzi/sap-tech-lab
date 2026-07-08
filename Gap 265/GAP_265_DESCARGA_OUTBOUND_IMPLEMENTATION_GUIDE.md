# GAP 265 - Descarga Outbound - Action Guide

Author: RTiezzi  
Request/CHARM: ZPQ2C_265_20260703_082358

## 1. Objetivo
Ativar e finalizar o fluxo Descarga Outbound agora, removendo o bloqueio de ativacao da classe ZCLQ2C_265_DESCARGA_GRANEL por ausencia de DDIC no ambiente.

## 2. Acoes necessarias
| Ordem | Acao | Objeto | Tipo | Observacao |
|---|---|---|---|---|
| 1 | Validar existencia no ambiente | ZDEQ2C_265_DESC_DESTTANK | Data Element | Bloqueio atual de ativacao |
| 2 | Criar ou transportar (se ausente) | ZDEQ2C_265_DESC_DESTTANK | Data Element | Necessario para ativar ZCLQ2C_265_DESCARGA_GRANEL |
| 3 | Ativar | ZDEQ2C_265_DESC_DESTTANK | Data Element | Ativar DDIC antes da classe |
| 4 | Ativar | ZCLQ2C_265_DESCARGA_GRANEL | Classe | Deve compilar sem erro de tipo desconhecido |
| 5 | Ativar | ZRQ2C_DESCARGA_GRANEL | Report | Runner manual outbound |
| 6 | Validar execucao | ZRQ2C_DESCARGA_GRANEL | Report | Teste minimo de geracao U200-H/U200-S |

## 3. Matriz DDIC necessaria
Escopo da matriz: dependencias DDIC usadas diretamente em ZCLQ2C_265_DESCARGA_GRANEL (tipos TYPE zdeq2c_265_*).

| Objeto | Tipo DDIC | Tipo base | Tamanho | Decimais | Descricao | Criar ou reutilizar |
|---|---|---|---|---|---|---|
| ZDEQ2C_265_DESC_DESTTANK | Data Element | CHAR | 10 | 0 | Tanque de destino | Criar ou transportar se nao existir no ambiente |
| ZDEQ2C_265_DESC_INVOQTYL | Data Element | DEC | 13 | 3 | Quantidade da nota em litros | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_INVOQKG | Data Element | DEC | 13 | 3 | Peso da nota em kg | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_INVOICEN | Data Element | CHAR | 20 | 0 | Numero da nota fiscal | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_BATCHIDS | Data Element | CHAR | 20 | 0 | Lotes | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_CARTID | Data Element | CHAR | 10 | 0 | Placa do carreto | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_COLORYN | Data Element | CHAR | 1 | 0 | Cor informada (S/N) | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_SAMPLEYN | Data Element | CHAR | 1 | 0 | Amostra coletada (S/N) | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_LABMAN | Data Element | CHAR | 12 | 0 | Responsavel do laboratorio | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_LADAPPTM | Data Element | CHAR | 17 | 0 | Data/hora aprovacao laboratorio | Reutilizar objetos_comuns |
| ZDEQ2C_265_DESC_SEALCODE | Data Element | CHAR | 10 | 0 | Codigo do lacre | Reutilizar objetos_comuns |
| ZDEQ2C_265_ORDER_NUM | Data Element | Conforme objeto fonte | Conforme objeto fonte | Conforme objeto fonte | Numero da ordem | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_PROD_NUM | Data Element | CHAR | 18 | 0 | Numero do produto | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_PROD_NAME | Data Element | CHAR | 18 | 0 | Nome do produto | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_PROD_DEN | Data Element | QUAN | 6 | 0 | Densidade do produto | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_LOAD_LINE | Data Element | Conforme objeto fonte | Conforme objeto fonte | Conforme objeto fonte | Linha de carga/descarga | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_LOAD_PTFM | Data Element | Conforme objeto fonte | Conforme objeto fonte | Conforme objeto fonte | Plataforma de carga | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_TRUCK_ID | Data Element | Conforme objeto fonte | Conforme objeto fonte | Conforme objeto fonte | Identificacao do caminhao | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_MSGRCVTM | Data Element | CHAR | 17 | 0 | Data e hora de recebimento | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_PPRD_NAME | Data Element | CHAR | 18 | 0 | Nome do produto anterior | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_PPRD_NUM | Data Element | CHAR | 18 | 0 | Numero do produto anterior | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_SEALCLR | Data Element | Conforme objeto fonte | Conforme objeto fonte | Conforme objeto fonte | Cor do lacre | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_SEAL_NUM | Data Element | NUMC | 8 | 0 | Numero do lacre | Reutilizar pacote base ZPQ2C_265_20260703_082358 |
| ZDEQ2C_265_SEAL_QTY | Data Element | NUMC | 2 | 0 | Quantidade de lacres | Reutilizar pacote base ZPQ2C_265_20260703_082358 |

Nota de tamanho para DESTTANK:
- Evidencia tecnica atual do repositorio: ZDEQ2C_265_DESC_DESTTANK esta definido como CHAR(10) em objetos_comuns.
- Validacao funcional obrigatoria: confirmar o tamanho no layout U200-H oficial antes de transporte final.
- Regra pratica: se layout oficial exigir CHAR(7), ajustar para CHAR(7); se nao houver evidencia diferente, manter CHAR(10) para alinhar com o objeto fonte do pacote.

## 4. Correcao do erro atual
Erro atual:
Type "ZDEQ2C_265_DESC_DESTTANK" is unknown.

Acao:
Criar ou transportar o Data Element ZDEQ2C_265_DESC_DESTTANK antes de ativar a classe ZCLQ2C_265_DESCARGA_GRANEL.

Este ponto e bloqueio de ativacao, nao observacao.

## 5. Ordem de implementacao
1. Validar no SE11/ADT se ZDEQ2C_265_DESC_DESTTANK existe.
2. Se nao existir, criar ou transportar ZDEQ2C_265_DESC_DESTTANK com tipo/tamanho correto do layout.
3. Ativar ZDEQ2C_265_DESC_DESTTANK.
4. Ativar ZCLQ2C_265_DESCARGA_GRANEL.
5. Ativar ZRQ2C_DESCARGA_GRANEL.
6. Executar teste minimo de geracao do outbound (U200-H e U200-S).

## 6. Ajustes ABAP
| Objeto | Acao | Detalhe |
|---|---|---|
| ZCLQ2C_265_DESCARGA_GRANEL | Ativar/corrigir tipagem | Corrigir dependencias DDIC ausentes (principalmente DESTTANK) |
| ZCLQ2C_265_DESC_COMMON | Reutilizar | Nao duplicar metodos comuns de TVARVC e mensagens |
| ZRQ2C_DESCARGA_GRANEL | Validar execucao | Runner manual do outbound |

## 7. Checklist final
- [ ] Data Element ZDEQ2C_265_DESC_DESTTANK criado ou transportado
- [ ] Data Element ativo
- [ ] Classe ZCLQ2C_265_DESCARGA_GRANEL ativa
- [ ] Runner ZRQ2C_DESCARGA_GRANEL ativo
- [ ] Payload outbound gerado
- [ ] Descarga Inbound nao impactada
- [ ] Carga nao impactada
