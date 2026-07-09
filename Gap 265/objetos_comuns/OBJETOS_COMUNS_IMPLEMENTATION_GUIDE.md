# GAP 265 - Objetos Comuns - Implementation Guide

Author: RTiezzi  
Request/CHARM: ZPQ2C_265_20260703_082358

---

## 1. Objetivo

Este guide concentra os objetos técnicos de apoio compartilhados entre os fluxos do
GAP 265 (Descarga Outbound e Descarga Inbound/Retorno). Inclui Data Elements,
message class e classe comum. Os arquivos `.xml` nesta pasta são artefatos técnicos
de importação abapGit — este guide é a fonte humana de leitura e implementação.

---

## 2. Data Elements — Descarga Outbound

Usados diretamente em `ZCLQ2C_265_DESCARGA_GRANEL` (`TY_U200_H` e `TY_U200_S`).

| Ordem | Objeto | Tipo base | Tamanho | Decimais | Descrição | Usado em |
|---|---|---|---|---|---|---|
| 1 | `ZDEQ2C_265_DESC_DESTTANK` | CHAR | 10 | 0 | Tanque de destino | `TY_U200_H-DESTTANK` |
| 2 | `ZDEQ2C_265_DESC_INVOQTYL` | DEC | 13 | 3 | Quantidade faturada em litros | `TY_U200_H-INVOQTYL` |
| 3 | `ZDEQ2C_265_DESC_INVOQKG` | DEC | 13 | 3 | Peso faturado em KG | `TY_U200_H-INVOQTYKG` |
| 4 | `ZDEQ2C_265_DESC_COLORYN` | CHAR | 1 | 0 | Cor S/N | `TY_U200_H-COLORYN` |
| 5 | `ZDEQ2C_265_DESC_SAMPLEYN` | CHAR | 1 | 0 | Amostra S/N | `TY_U200_H-SAMPLEYN` |
| 6 | `ZDEQ2C_265_DESC_LABMAN` | CHAR | 12 | 0 | Responsável de laboratório | `TY_U200_H-LABMAN` |
| 7 | `ZDEQ2C_265_DESC_LADAPPTM` | CHAR | 17 | 0 | Timestamp aprovação laboratório | `TY_U200_H-LADAPPTM` |
| 8 | `ZDEQ2C_265_DESC_INVOICEN` | CHAR | 20 | 0 | Número da nota fiscal | `TY_U200_H-INVOICEN` |
| 9 | `ZDEQ2C_265_DESC_BATCHIDS` | CHAR | 20 | 0 | IDs de lote | `TY_U200_H-BATCHIDS` |
| 10 | `ZDEQ2C_265_DESC_CARTID` | CHAR | 10 | 0 | Placa do reboque | `TY_U200_H-CARTID` |
| 11 | `ZDEQ2C_265_DESC_SEALCODE` | CHAR | 10 | 0 | Código do lacre | `TY_U200_H-SEALCODE` / `TY_U200_S-SEALCODE` / `TY_U301_S-SEALCODE` |

---

## 3. Data Elements — Descarga Inbound/Retorno

Usados diretamente em `ZCLQ2C_265_DESC_RET_GRANEL` (`TY_U301_H` e `TY_U301_S`).

| Ordem | Objeto | Tipo base | Tamanho | Decimais | Descrição | Usado em |
|---|---|---|---|---|---|---|
| 1 | `ZDEQ2C_265_DESC_TRKINTWT` | NUMC | 6 | 0 | Peso inicial do caminhão | `TY_U301_H-TRKINTWT` |
| 2 | `ZDEQ2C_265_DESC_TRKFNLWT` | NUMC | 6 | 0 | Peso final do caminhão | `TY_U301_H-TRKFNLWT` |
| 3 | `ZDEQ2C_265_DESC_LINEEMTY` | CHAR | 1 | 0 | Linha vazia S/N | `TY_U301_H-LINEEMTY` |
| 4 | `ZDEQ2C_265_DESC_PT_YRN` | CHAR | 1 | 0 | Plataforma S/N | `TY_U301_H-PT_YRN` |
| 5 | `ZDEQ2C_265_DESC_DESTTYRN` | CHAR | 1 | 0 | Tanque de destino S/N | `TY_U301_H-DESTTYRN` |
| 6 | `ZDEQ2C_265_DESC_TRKIDY2N` | CHAR | 1 | 0 | ID caminhão 2 S/N | `TY_U301_H-TRKIDY2N` |
| 7 | `ZDEQ2C_265_DESC_AVVERYRN` | CHAR | 1 | 0 | Verificação AV S/N | `TY_U301_H-AVVERYRN` |
| 8 | `ZDEQ2C_265_DESC_COMPDROP` | CHAR | 3 | 0 | Compartimento drop | `TY_U301_H-COMPDROP` |
| 9 | `ZDEQ2C_265_DESC_TRKGDRYN` | CHAR | 1 | 0 | Grau caminhão S/N | `TY_U301_H-TRKGDRYN` |
| 10 | `ZDEQ2C_265_DESC_TRKBKACT` | CHAR | 1 | 0 | Caminhão re-ativo S/N | `TY_U301_H-TRKBKACT` |
| 11 | `ZDEQ2C_265_DESC_TRKMTOFF` | CHAR | 1 | 0 | Motor do caminhão desligado S/N | `TY_U301_H-TRKMTOFF` |
| 12 | `ZDEQ2C_265_DESC_LABINFO` | CHAR | 60 | 0 | Informações de laboratório | `TY_U301_H-LABINFO` |
| 13 | `ZDEQ2C_265_DESC_AVVEREND` | CHAR | 17 | 0 | Timestamp final verificação AV | `TY_U301_H-AVVEREND` |
| 14 | `ZDEQ2C_265_DESC_STARTTME` | CHAR | 17 | 0 | Timestamp início da operação | `TY_U301_H-STARTTME` |
| 15 | `ZDEQ2C_265_DESC_ENDTIME` | CHAR | 17 | 0 | Timestamp fim da operação | `TY_U301_H-ENDTIME` |
| 16 | `ZDEQ2C_265_DESC_SUPNAME` | CHAR | 40 | 0 | Nome do fornecedor | `TY_U301_H-SUPNAME` |
| 17 | `ZDEQ2C_265_DESC_OPSNAME` | CHAR | 40 | 0 | Nome do operador | `TY_U301_H-OPSNAME` |
| 18 | `ZDEQ2C_265_DESC_SEALYRN` | CHAR | 1 | 0 | Lacre S/N | `TY_U301_S-SEALYRN` |

---

## 4. Message Class

| Objeto | Tipo | Descrição PT-BR | Usado em |
|---|---|---|---|
| `ZCL_Q2C_265_MSG_DG` | Message Class | Descarga Granel | `ZCLQ2C_265_DESC_COMMON` |

### Mensagens

| Nº | Tipo | Texto PT-BR | Usado em |
|---|---|---|---|
| 001 | I | Job Descarga iniciado: dir &1 | Descarga Inbound |
| 010 | I | Processando ordem: &1 | Descarga Inbound |
| 011 | S | Arquivo &1 gravado com sucesso | Descarga Outbound |
| 012 | E | Referência da descarga não informada: &1 | Descarga Outbound |
| 020 | E | Diretório TVARVC inválido: &1 | Outbound e Inbound |
| 030 | E | ORDERNUM inválido: &1 | Outbound e Inbound |
| 031 | E | Campo obrigatório não preenchido: &1 | Descarga Outbound |
| 032 | E | Lacres da descarga não informados para a ordem &1 | Descarga Outbound |
| 033 | E | Status da ordem não identificado: &1 | Descarga Outbound |
| 034 | E | Status inválido para envio PCS: &1 | Descarga Outbound |
| 035 | E | Cancelamento permitido apenas no status 03. Atual: &1 | Descarga Outbound |
| 036 | E | ORDERNUM não existe no SAP: &1 | Descarga Inbound |
| 037 | E | Inconsistência de arquivos de retorno: &1 | Descarga Inbound |
| 040 | E | Erro ao gravar arquivo: &1 | Descarga Outbound |
| 041 | E | Erro ao ler arquivo: &1 | Descarga Inbound |
| 099 | S | Job Descarga concluído: &1 OK / &2 erro(s) | Descarga Inbound |

---

## 5. Classe comum

| Objeto | Tipo | Responsabilidade | Usado por |
|---|---|---|---|
| `ZCLQ2C_265_DESC_COMMON` | Classe | Métodos compartilhados: `add_error`, `add_success`, `get_tvarvc_value`. Constante `gc_msgid = ZCL_Q2C_265_MSG_DG`. | `ZCLQ2C_265_DESCARGA_GRANEL` e `ZCLQ2C_265_DESC_RET_GRANEL` |

---

## 6. Ordem de criação/ativação

1. Criar/ativar os 11 Data Elements do Descarga Outbound (seção 2).
2. Criar/ativar os 18 Data Elements do Descarga Inbound (seção 3).
3. Criar/ativar a Message Class `ZCL_Q2C_265_MSG_DG` com todas as 16 mensagens.
4. Ativar `ZCLQ2C_265_DESC_COMMON`.
5. Prosseguir para os guides específicos de Outbound e Inbound.

> Todos os objetos desta pasta já existem como artefatos abapGit.
> Usar abapGit pull nesta pasta para importar tudo em massa.

---

## 7. Checklist

- [ ] Data Elements do Descarga Outbound disponíveis no SAP (seção 2)
- [ ] Data Elements do Descarga Inbound disponíveis no SAP (seção 3)
- [ ] `ZCL_Q2C_265_MSG_DG` ativa com 16 mensagens
- [ ] `ZCLQ2C_265_DESC_COMMON` ativa
- [ ] Descrições em PT-BR conferidas
- [ ] Nenhum objeto comum sem documentação
