# FD 5047 – Boletim de Conformidade: Lógica e Impressão

**RICEFW ID:** 8944  
**Status:** Desenvolvimento  
**Consultor Funcional:** Luciano França  
**Criticidade:** Média | **Complexidade:** Média

---

## Visão Geral

Solução em 3 partes para gestão, armazenamento e impressão automatizada de certificados de conformidade PDF vinculados a materiais de venda, utilizando SAP DMS (Document Management Service – BTP/CMIS).

---

## Partes e Objetos

### Objetos Comuns (pasta raiz)

| Objeto | Tipo | Descrição |
|--------|------|-----------|
| `ZCL_FD5047_DMS_API` | CLAS | Helper HTTP para API REST do DMS (SDM BTP). Usado por todas as partes. |

---

### Parte 1 – Fiori Upload e Gestão de Certificados
> Pasta: `Parte1 - Fiori Upload DMS/`

| Objeto | Tipo | Descrição |
|--------|------|-----------|
| `ZCL_FD5047_CERT_SVC` | CLAS | Serviço ABAP de backend: upload, listagem, exclusão e validação de duplicidade via DMS |

> **Nota:** A UI Fiori (app HTML5 via BAS/Fiori Elements) é desenvolvida separadamente. Esta classe é o backend OData consumido pelo app.

**Funcionalidades:**
- Upload de PDF com associação a Material + Centro + Depósito + Data
- Validação de formato (somente PDF) e duplicidade (Material+Centro+Depósito+Data)
- Listagem com filtros e deleção

---

### Parte 2 – Serviço de Impressão de Certificados
> Pasta: `Parte2 - Servico Impressao/`

| Objeto | Tipo | Descrição |
|--------|------|-----------|
| `ZCL_FD5047_CERT_PRINT` | CLAS | Serviço de impressão: recebe SHNUMBER, busca OIGSI→LIPS→DMS, gera SPOOLs |

**Trigger:** Chamado pelo serviço de impressão do Kit de Documentos (FD 6083).  
**Regra crítica:** Se não houver certificado para qualquer item → interrompe a impressão.

---

### Parte 3 – Job de Limpeza DMS (D-15)
> Pasta: `Parte3 - Job Cleanup/`

| Objeto | Tipo | Descrição |
|--------|------|-----------|
| `ZFD5047_CERT_CLEANUP` | PROG | Report/Job para eliminar certificados com mais de 15 dias no DMS |

**Agendamento:** 2x por mês, madrugada.  
**Parâmetro D-15:** Configurável via TVARVC → chave `ZFD5047_CLEANUP_DAYS` (padrão: `15`).

---

## Destino HTTP (pré-requisito BASIS)

| Item | Valor |
|------|-------|
| SM59 – Destino | `ZDMS5047_DEST` (HTTP Connection to External Server) |
| Host | `api-sdm-di.cfapps.br10.hana.ondemand.com` |
| Path Prefix | `/browser/` |
| Autenticação | OAuth2 ou Basic (confirmar com BTP admin) |
| Repository ID | `ZDMS_S4D_110` |

---

## Estrutura de Pastas no DMS

```
/root/
  └── Certificados/
        └── {MATNR}/
              └── {WERKS}/
                    └── {LGORT}/
                          └── {MATNR}_{WERKS}_{LGORT}_{YYYYMMDD}.pdf
```

Nome do documento: `{MATNR}_{WERKS}_{LGORT}_{YYYYMMDD}.pdf`  
Busca "mais recente" = browse na pasta com `orderBy=cmis:creationDate DESC`, primeiro resultado.

---

## Dependências Externas

- **FD 6083** – Kit de Documentos de Venda: trigger da Parte 2 (chamar `ZCL_FD5047_CERT_PRINT→print_for_transport_doc`)
- **Tabela OIGSI** – Necessário confirmar existência e campos no sistema SAP do cliente (ver TECHNICAL_DECISIONS.md)
- **BTP SDM** – API REST configurada e acessível pelo servidor SAP

---

## Convenção de Nomenclatura

| Prefixo | Uso |
|---------|-----|
| `ZFD5047_` | Reports e programas batch |
| `ZCL_FD5047_` | Classes ABAP |
| `ZDMS5047_` | Destino SM59 |
| `ZFD5047_CLEANUP_DAYS` | Chave TVARVC |
