# GAP 265 - Descarga Outbound - Implementation Guide

Author: RTiezzi  
Request/CHARM: ZPQ2C_265_20260703_082358

---

## 1. Objetivo

Garantir a ativação e execução do fluxo Descarga Outbound, responsável por gerar os
arquivos `U200-H` e `U200-S` a partir de uma ordem de descarga SAP com status `03`.

---

## 2. Objetos necessários para o Outbound Descarga

| Ordem | Objeto | Tipo | Ação | Observação |
|---|---|---|---|---|
| 1 | `ZDEQ2C_265_DESC_DESTTANK` | Data Element | Garantir no ambiente SAP | `TY_U200_H-DESTTANK` |
| 2 | `ZDEQ2C_265_DESC_INVOQTYL` | Data Element | Garantir no ambiente SAP | `TY_U200_H-INVOQTYL` |
| 3 | `ZDEQ2C_265_DESC_INVOQKG` | Data Element | Garantir no ambiente SAP | `TY_U200_H-INVOQTYKG` |
| 4 | `ZDEQ2C_265_DESC_COLORYN` | Data Element | Garantir no ambiente SAP | `TY_U200_H-COLORYN` |
| 5 | `ZDEQ2C_265_DESC_SAMPLEYN` | Data Element | Garantir no ambiente SAP | `TY_U200_H-SAMPLEYN` |
| 6 | `ZDEQ2C_265_DESC_LABMAN` | Data Element | Garantir no ambiente SAP | `TY_U200_H-LABMAN` |
| 7 | `ZDEQ2C_265_DESC_LADAPPTM` | Data Element | Garantir no ambiente SAP | `TY_U200_H-LADAPPTM` |
| 8 | `ZDEQ2C_265_DESC_INVOICEN` | Data Element | Garantir no ambiente SAP | `TY_U200_H-INVOICEN` |
| 9 | `ZDEQ2C_265_DESC_BATCHIDS` | Data Element | Garantir no ambiente SAP | `TY_U200_H-BATCHIDS` |
| 10 | `ZDEQ2C_265_DESC_CARTID` | Data Element | Garantir no ambiente SAP | `TY_U200_H-CARTID` |
| 11 | `ZDEQ2C_265_DESC_SEALCODE` | Data Element | Garantir no ambiente SAP | `TY_U200_S-SEALCODE` |
| 12 | `ZCL_Q2C_265_MSG_DG` | Message Class | Garantir no ambiente SAP | Dependência de `ZCLQ2C_265_DESC_COMMON` |
| 13 | `ZCLQ2C_265_DESC_COMMON` | Classe | Ativar | Dependência direta da classe principal |
| 14 | `ZCLQ2C_265_DESCARGA_GRANEL` | Classe | Ativar | Classe principal do Outbound |
| 15 | `ZRQ2C_DESCARGA_GRANEL` | Report | Ativar/testar | Runner manual do Outbound |
| 16 | `ZQ2C_DESCARGA_PCS_OUT` | TVARVC | Configurar | Diretório AL11 de saída dos arquivos |

> Todos os objetos das linhas 1–13 já existem no repositório em `objetos_comuns/`.
> Não precisam ser criados do zero — apenas importados/ativados no ambiente via abapGit pull.

---

## 3. Data Elements do payload Outbound

Apenas os Data Elements específicos dos tipos `TY_U200_H` e `TY_U200_S` que estão em
`objetos_comuns/` e precisam ser garantidos no ambiente SAP.

| Campo | Data Element | Tipo | Tamanho | Descrição |
|---|---|---|---|---|
| `DESTTANK` | `ZDEQ2C_265_DESC_DESTTANK` | CHAR | 10 | Tanque de destino |
| `INVOQTYL` | `ZDEQ2C_265_DESC_INVOQTYL` | DEC | 13,3 | Quantidade faturada em litros |
| `INVOQTYKG` | `ZDEQ2C_265_DESC_INVOQKG` | DEC | 13,3 | Peso faturado em KG |
| `COLORYN` | `ZDEQ2C_265_DESC_COLORYN` | CHAR | 1 | Cor S/N |
| `SAMPLEYN` | `ZDEQ2C_265_DESC_SAMPLEYN` | CHAR | 1 | Amostra S/N |
| `LABMAN` | `ZDEQ2C_265_DESC_LABMAN` | CHAR | 12 | Responsável de laboratório |
| `LADAPPTM` | `ZDEQ2C_265_DESC_LADAPPTM` | CHAR | 17 | Timestamp aprovação laboratório |
| `INVOICEN` | `ZDEQ2C_265_DESC_INVOICEN` | CHAR | 20 | Número da nota fiscal |
| `BATCHIDS` | `ZDEQ2C_265_DESC_BATCHIDS` | CHAR | 20 | IDs de lote |
| `CARTID` | `ZDEQ2C_265_DESC_CARTID` | CHAR | 10 | Placa do reboque |
| `SEALCODE` | `ZDEQ2C_265_DESC_SEALCODE` | CHAR | 10 | Código do lacre |

> Os demais campos do payload (`ORDERNUM`, `PRODNUM`, `PRODNAME`, `UNLOADLN`,
> `TRUCKID`, `SEALCLR`, etc.) usam Data Elements de `ZPQ2C_265_20260703_082358/src/`
> já ativos no ambiente desde a primeira entrega.

---

## 4. Classe Outbound

| Objeto | Ação | Detalhe |
|---|---|---|
| `ZCLQ2C_265_DESCARGA_GRANEL` | Ativar | Monta `TY_U200_H`/`TY_U200_S`, grava arquivos no diretório TVARVC |

Nenhuma alteração de código necessária.

---

## 5. Runner Outbound

| Objeto | Ação | Detalhe |
|---|---|---|
| `ZRQ2C_DESCARGA_GRANEL` | Ativar/testar | Executa o Outbound Descarga; parâmetros: referência da ordem e flag de job |

---

## 6. Configuração necessária

| Item | Tipo | Ação | Observação |
|---|---|---|---|
| `ZQ2C_DESCARGA_PCS_OUT` | TVARVC | Configurar | Diretório AL11 onde U200-H e U200-S serão gravados |
| `ZI_Q2C_DESCARGA` | CDS View (GAP 340) | Verificar ativo | Fonte principal de dados da ordem de descarga |
| `ZI_Q2C_MONI_DESCARGA` | CDS View (GAP 340) | Verificar ativo | Fonte de dados de monitoramento (veículo, lote, produto) |

---

## 7. Ordem de implementação

1. Importar `objetos_comuns/` via abapGit pull — ativa em massa os 11 DTELs, a message class e `ZCLQ2C_265_DESC_COMMON`.
2. Verificar CDS `ZI_Q2C_DESCARGA` e `ZI_Q2C_MONI_DESCARGA` ativas (GAP 340).
3. Configurar TVARVC `ZQ2C_DESCARGA_PCS_OUT` com o diretório de saída AL11.
4. Ativar `ZCLQ2C_265_DESCARGA_GRANEL`.
5. Ativar `ZRQ2C_DESCARGA_GRANEL`.
6. Executar teste com uma referência de descarga válida (status `03`).
7. Validar geração dos arquivos U200-H e U200-S na AL11.

---

## 8. Checklist final

- [ ] Data Elements do payload Outbound Descarga disponíveis no SAP
- [ ] `ZCL_Q2C_265_MSG_DG` ativa
- [ ] `ZCLQ2C_265_DESC_COMMON` ativa
- [ ] `ZCLQ2C_265_DESCARGA_GRANEL` ativa
- [ ] `ZRQ2C_DESCARGA_GRANEL` ativo
- [ ] TVARVC `ZQ2C_DESCARGA_PCS_OUT` configurada
- [ ] CDS `ZI_Q2C_DESCARGA` e `ZI_Q2C_MONI_DESCARGA` ativas
- [ ] U200-H gerado
- [ ] U200-S gerado

Erro de ativação na classe `ZCLQ2C_265_DESCARGA_GRANEL`:

```
Type "ZDEQ2C_265_DESC_DESTTANK" is unknown.
```

**Causa raiz:** todos os Data Elements usados pela classe já existem no repositório
(`objetos_comuns/` e `ZPQ2C_265_20260703_082358/src/`), mas os objetos de
`objetos_comuns/` **ainda não foram ativados no ambiente SAP**. O objeto
`ZDEQ2C_265_DESC_DESTTANK` existe em `objetos_comuns/zdeq2c_265_desc_desttank.dtel.xml`
(CHAR 10, "Destination Tank") — não precisa ser criado.

**Impacto:** enquanto os Data Elements de `objetos_comuns/` não estiverem ativos, a
classe não ativa e o report `ZRQ2C_DESCARGA_GRANEL` também não.

**Data Elements de `objetos_comuns/` referenciados por `ZCLQ2C_265_DESCARGA_GRANEL`:**

| # | Data Element | Tipo | Tamanho | Desc | Estrutura |
|---|---|---|---|---|---|
| 1 | `ZDEQ2C_265_DESC_DESTTANK` | CHAR | 10 | Tanque de destino | `TY_U200_H-DESTTANK` |
| 2 | `ZDEQ2C_265_DESC_INVOQTYL` | DEC | 13,3 | Quantidade faturada em litros | `TY_U200_H-INVOQTYL` |
| 3 | `ZDEQ2C_265_DESC_INVOQKG` | DEC | 13,3 | Peso faturado em KG | `TY_U200_H-INVOQTYKG` |
| 4 | `ZDEQ2C_265_DESC_COLORYN` | CHAR | 1 | Cor S/N | `TY_U200_H-COLORYN` |
| 5 | `ZDEQ2C_265_DESC_SAMPLEYN` | CHAR | 1 | Amostra S/N | `TY_U200_H-SAMPLEYN` |
| 6 | `ZDEQ2C_265_DESC_LABMAN` | CHAR | 12 | Responsável de laboratório | `TY_U200_H-LABMAN` |
| 7 | `ZDEQ2C_265_DESC_LADAPPTM` | CHAR | 17 | Timestamp aprovação laboratório | `TY_U200_H-LADAPPTM` |
| 8 | `ZDEQ2C_265_DESC_INVOICEN` | CHAR | 20 | Número da nota fiscal | `TY_U200_H-INVOICEN` |
| 9 | `ZDEQ2C_265_DESC_BATCHIDS` | CHAR | 20 | IDs de lote | `TY_U200_H-BATCHIDS` |
| 10 | `ZDEQ2C_265_DESC_CARTID` | CHAR | 10 | Placa do reboque | `TY_U200_H-CARTID` |
| 11 | `ZDEQ2C_265_DESC_SEALCODE` | CHAR | 10 | Código do lacre | `TY_U200_S-SEALCODE` |

Os demais Data Elements da classe (`ZDEQ2C_265_ORDER_NUM`, `ZDEQ2C_265_PROD_NUM`,
`ZDEQ2C_265_LOAD_LINE`, `ZDEQ2C_265_TRUCK_ID`, etc.) vêm de
`ZPQ2C_265_20260703_082358/src/` e já foram ativados na primeira entrega.

**Pré-requisito externo (GAP 340):** as CDS views `ZI_Q2C_DESCARGA` e
`ZI_Q2C_MONI_DESCARGA` devem estar ativas no ambiente (entregues pelo pacote
`ZPQ2C_340_D_20260617_232623`). A classe lê dados dessas views — se não estiverem
ativas, a classe não ativa mesmo após os DTELs serem criados.

---

## 2. Decisão técnica

Varredura completa dos 22 Data Elements usados em `TY_U200_H` e `TY_U200_S`:
todos existem no repositório. Nenhum precisa ser criado.

| Campo | Tipo atual na classe | Situação | Decisão | Ação |
|---|---|---|---|---|
| `DESTTANK` | `ZDEQ2C_265_DESC_DESTTANK` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `INVOQTYL` | `ZDEQ2C_265_DESC_INVOQTYL` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `INVOQTYKG` | `ZDEQ2C_265_DESC_INVOQKG` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `COLORYN` | `ZDEQ2C_265_DESC_COLORYN` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `SAMPLEYN` | `ZDEQ2C_265_DESC_SAMPLEYN` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `LABMAN` | `ZDEQ2C_265_DESC_LABMAN` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `LADAPPTM` | `ZDEQ2C_265_DESC_LADAPPTM` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `INVOICEN` | `ZDEQ2C_265_DESC_INVOICEN` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `BATCHIDS` | `ZDEQ2C_265_DESC_BATCHIDS` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `CARTID` | `ZDEQ2C_265_DESC_CARTID` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |
| `SEALCODE` | `ZDEQ2C_265_DESC_SEALCODE` | Existe em `objetos_comuns/` | Caso A: reutilizar | Ativar DTEL existente; sem alteração na classe |

**Conclusão:** a classe `ZCLQ2C_265_DESCARGA_GRANEL` está correta. Zero alterações de código.

---

## 3. Objetos a criar

Nenhum objeto novo necessário.

Todos os Data Elements, a message class (`ZCL_Q2C_265_MSG_DG`) e a classe comum
(`ZCLQ2C_265_DESC_COMMON`) já existem no repositório em `objetos_comuns/`.

---

## 4. Objetos a modificar

Nenhum objeto existente precisa ser alterado.

A classe `ZCLQ2C_265_DESCARGA_GRANEL` está correta conforme `outbound/zclq2c_265_descarga_granel.clas.abap`.
O report `ZRQ2C_DESCARGA_GRANEL` está correto conforme `outbound/zrq2c_descarga_granel.prog.abap`.

---

## 5. Objetos de Job/APJ

Nenhum objeto de Job/APJ necessário para o Descarga Outbound neste momento.

**Evidência:**
- Padrão da Carga Outbound (`ZCLQ2C_265_CARGA_GRANEL`): não tem APJ próprio. É
  chamado diretamente pela Fiori app ou por report avulso.
- O report `ZRQ2C_DESCARGA_GRANEL` já possui o parâmetro `p_job` (checkbox) para
  modo silencioso quando executado como job clássico (SM36/JOBD).
- O APJ `ZCLQ2C_265_DESC_JOB` existe para o **Inbound/Retorno** (`ZCLQ2C_265_DESC_RET_GRANEL`),
  não para o Outbound. Não duplicar.
- Job Catalog e Job Template: não aplicável para o Outbound neste escopo.

---

## 6. Objetos a ativar e testar

| Ordem | Objeto | Tipo | Pacote | Ação | Critério de sucesso |
|---|---|---|---|---|---|
| 1 | `ZCL_Q2C_265_MSG_DG` | Message Class | `objetos_comuns/` | Ativar | Message class ativa, 16 mensagens visíveis em SE91 |
| 2 | `ZDEQ2C_265_DESC_DESTTANK` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 10, sem erro |
| 3 | `ZDEQ2C_265_DESC_INVOQTYL` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, DEC 13,3, sem erro |
| 4 | `ZDEQ2C_265_DESC_INVOQKG` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, DEC 13,3, sem erro |
| 5 | `ZDEQ2C_265_DESC_COLORYN` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 1, sem erro |
| 6 | `ZDEQ2C_265_DESC_SAMPLEYN` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 1, sem erro |
| 7 | `ZDEQ2C_265_DESC_LABMAN` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 12, sem erro |
| 8 | `ZDEQ2C_265_DESC_LADAPPTM` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 17, sem erro |
| 9 | `ZDEQ2C_265_DESC_INVOICEN` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 20, sem erro |
| 10 | `ZDEQ2C_265_DESC_BATCHIDS` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 20, sem erro |
| 11 | `ZDEQ2C_265_DESC_CARTID` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 10, sem erro |
| 12 | `ZDEQ2C_265_DESC_SEALCODE` | Data Element | `objetos_comuns/` | Ativar | DTEL ativo, CHAR 10, sem erro |
| 13 | `ZCLQ2C_265_DESC_COMMON` | Classe | `objetos_comuns/` | Ativar | Classe ativa, sem erro de dependência |
| 14 | `ZCLQ2C_265_DESCARGA_GRANEL` | Classe | `outbound/` | Ativar | Classe ativa, sem erro "Type unknown" |
| 15 | `ZRQ2C_DESCARGA_GRANEL` | Report | `outbound/` | Ativar e executar | Report ativo; execução gera U200-H e U200-S no diretório `ZQ2C_DESCARGA_PCS_OUT` |

**Pré-requisito externo (verificar antes de iniciar):**

| Objeto | Tipo | Pacote | Status esperado |
|---|---|---|---|
| `ZI_Q2C_DESCARGA` | CDS View | GAP 340 / `ZPQ2C_340_D_20260617_232623` | Ativo no ambiente |
| `ZI_Q2C_MONI_DESCARGA` | CDS View | GAP 340 / `ZPQ2C_340_D_20260617_232623` | Ativo no ambiente |
| `ZZ1_TVARVC_Q2C` | CDS View / View | Ambiente | Ativo no ambiente |

---

## 7. Ordem de execução

1. Verificar pré-requisitos externos (GAP 340): `ZI_Q2C_DESCARGA` e `ZI_Q2C_MONI_DESCARGA` ativos.
2. Ativar `ZCL_Q2C_265_MSG_DG` (message class).
3. Ativar os 11 Data Elements de `objetos_comuns/` (ordens 2–12 da tabela acima) — podem ser ativados em massa via SE11 ou abapGit pull.
4. Ativar `ZCLQ2C_265_DESC_COMMON`.
5. Ativar `ZCLQ2C_265_DESCARGA_GRANEL` — esperar zero erros de tipo.
6. Ativar `ZRQ2C_DESCARGA_GRANEL`.
7. Configurar TVARVC `ZQ2C_DESCARGA_PCS_OUT` com o diretório de saída correto (se ainda não configurado).
8. Executar `ZRQ2C_DESCARGA_GRANEL` com uma referência de descarga válida (status `03`).
9. Validar arquivos U200-H e U200-S gerados no diretório AL11.
10. Validar regressão mínima: Descarga Inbound (`ZRQ2C_DESC_RET_GRANEL`) e Carga (`ZRQ2C_CARGA_RET_GRANEL`) sem impacto.

---

## 8. Checklist final

- [ ] `ZI_Q2C_DESCARGA` e `ZI_Q2C_MONI_DESCARGA` (GAP 340) confirmados como ativos no ambiente
- [ ] Todos os 11 Data Elements de `objetos_comuns/` usados pela classe mapeados e ativados
- [ ] Nenhum Data Element novo criado (todos reutilizados do repositório)
- [ ] Classe `ZCLQ2C_265_DESCARGA_GRANEL` ativa sem erro de tipo desconhecido
- [ ] Código de `ZCLQ2C_265_DESCARGA_GRANEL` sem alteração (zero refatoração)
- [ ] Report `ZRQ2C_DESCARGA_GRANEL` ativo
- [ ] TVARVC `ZQ2C_DESCARGA_PCS_OUT` configurado
- [ ] Arquivos U200-H e U200-S gerados com sucesso
- [ ] Descarga Inbound sem impacto
- [ ] Carga sem impacto
