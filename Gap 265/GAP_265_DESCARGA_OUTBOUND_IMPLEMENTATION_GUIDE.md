# GAP 265 - Descarga Outbound - Action Guide

Author: RTiezzi  
Request/CHARM: ZPQ2C_265_20260703_082358

## 1. Bloqueio atual
Erro de ativacao na classe ZCLQ2C_265_DESCARGA_GRANEL:

Type "ZDEQ2C_265_DESC_DESTTANK" is unknown.

Classe afetada: ZCLQ2C_265_DESCARGA_GRANEL (TY_U200_H-DESTTANK).

## 2. Decisao tecnica
| Campo | Problema | Decisao | Acao |
|---|---|---|---|
| DESTTANK | ZDEQ2C_265_DESC_DESTTANK nao existe no ambiente | Criar novo Data Element com o nome tecnico atual (sem trocar para equivalente de Carga/Inbound e sem remover campo) | Criar ZDEQ2C_265_DESC_DESTTANK em SE11/ADT e manter DESTTANK TYPE ZDEQ2C_265_DESC_DESTTANK na classe |

## 3. Objetos a criar
| Objeto | Tipo DDIC | Tipo base | Tamanho | Decimais | Descricao | Usado em |
|---|---|---|---|---|---|---|
| ZDEQ2C_265_DESC_DESTTANK | Data Element | CHAR | 10 | 0 | Tanque de destino | ZCLQ2C_265_DESCARGA_GRANEL => TY_U200_H-DESTTANK |

Origem da decisao:
- Campo DESTTANK faz parte do layout U200-H ja implementado no Outbound.
- Nao ha Data Element equivalente em Carga/Inbound com a mesma semantica de tanque destino.
- O nome tecnico ja usado na classe esta consistente com o padrao ZDEQ2C_265_DESC_*.

## 4. Objetos a modificar
| Objeto | Tipo | Alteracao necessaria | Motivo |
|---|---|---|---|
| ZCLQ2C_265_DESCARGA_GRANEL | Classe | Nenhuma alteracao de codigo obrigatoria apos criacao do Data Element | O tipo ja esta correto na classe; a falha e apenas dependencia DDIC ausente |

## 5. Objetos a ativar/testar
| Objeto | Tipo | Acao | Criterio de sucesso |
|---|---|---|---|
| ZDEQ2C_265_DESC_DESTTANK | Data Element | Ativar | Data Element ativo sem erro |
| ZCLQ2C_265_DESCARGA_GRANEL | Classe | Ativar | Classe ativa sem erro de tipo desconhecido |
| ZRQ2C_DESCARGA_GRANEL | Report | Ativar e executar | Runner ativo e gerando U200-H/U200-S |

## 6. Ordem de execucao
1. Criar ZDEQ2C_265_DESC_DESTTANK.
2. Ativar ZDEQ2C_265_DESC_DESTTANK.
3. Ativar ZCLQ2C_265_DESCARGA_GRANEL.
4. Ativar ZRQ2C_DESCARGA_GRANEL.
5. Testar geracao U200-H/U200-S.
6. Validar impacto em Descarga Inbound e Carga.

## 7. Checklist final
- [ ] ZDEQ2C_265_DESC_DESTTANK criado
- [ ] ZDEQ2C_265_DESC_DESTTANK ativo
- [ ] ZCLQ2C_265_DESCARGA_GRANEL ativa
- [ ] ZRQ2C_DESCARGA_GRANEL ativo
- [ ] Arquivos U200-H e U200-S gerados
- [ ] Descarga Inbound sem impacto
- [ ] Carga sem impacto
