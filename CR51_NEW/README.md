# CR51 NEW — Reprocessamento MGR

**CR51 – Gap 14 – Integração MGR**
Baseado na EF de Rodolfo Gambarini (25/03/2026)

---

## O que é esta solução

Cockpit Fiori para monitoramento e reprocessamento de arquivos TXT recebidos da integração MGR (Q2C014I000). Quando a integração falha, o arquivo fica armazenado na tabela ARQ com status `ERRO`. O usuário pode **reprocessar** (envia novamente para o CPI) ou **cancelar** (soft delete) diretamente pelo Fiori.

---

## Arquitetura

```
┌─────────────────────────────────────────────────────┐
│  App 1 — Monitor / Reprocessamento                  │
│  ZSB_Q2C_ARQ_MGR_SVR (OData V4 - UI)               │
│                                                     │
│  List Report                                        │
│   └─ colunas: Status, Pedido, Bandeira, UltimoErro  │
│   └─ ações: [Reprocessar]  [Cancelar]               │
│                                                     │
│  Object Page (clicou no registro)                   │
│   └─ Dados Gerais + Último Erro + Conteúdo          │
│   └─ Histórico de Processamento ──────────────────┐ │
└───────────────────────────────────────────────────┼─┘
                                                    │ navegação _Log
┌───────────────────────────────────────────────────▼─┐
│  App 2 — LOG / Histórico (também standalone)        │
│  ZSB_Q2C_LOG_MGR_SVR (OData V4 - UI)               │
│                                                     │
│  List Report                                        │
│   └─ Pedido, Bandeira, Datum, Uzeit, Etapa,         │
│      Mensagem, Ernam                                │
│   └─ filtros: Pedido, Bandeira, Data, Etapa         │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Inbound CPI — Callback de Resultado                │
│                                                     │
│  ZSB_Q2C_ARQ_INB_SVR (OData V4 - Web API)          │
│   └─ PATCH Pedido+Bandeira → Status + UltimoErro   │
│                                                     │
│  ZSB_Q2C_LOG_INB_SVR (OData V4 - Web API)          │
│   └─ POST → nova linha de resultado no LOG          │
└─────────────────────────────────────────────────────┘
          ↑ chamado pelo iFlow CPI após processar o arquivo

┌─────────────────────────────────────────────────────┐
│  Job — Limpeza 90 dias (Application Jobs / F2373)   │
│  ZCL_Q2C_MGR_CLEANUP                                │
│   └─ Remove LOG com DATUM < hoje - 90 dias          │
│   └─ Remove ARQ CANCELADO/PROCESSADO com DATUM < corte │
│   └─ ARQ com ERRO não é removido                    │
└─────────────────────────────────────────────────────┘
```

---

## Tabelas

| Tabela              | Descrição                              |
|---------------------|----------------------------------------|
| `ZTBQ2C_ARQ_MGR`    | Arquivo recebido — status atual        |
| `ZTBQ2C_LOG_MGR`    | Histórico de tentativas (INSERT-only)  |

---

## Objetos SAP

### App 1 — Monitor / Reprocessamento (`Arq - Monitor/`)

| Objeto                    | Tipo  | Descrição                            |
|---------------------------|-------|--------------------------------------|
| `ZI_Q2C_ARQ_MGR`          | DDLS  | Interface ARQ — lê `ZTBQ2C_ARQ_MGR`, `_Log` association |
| `ZI_Q2C_ARQ_MGR`          | BDEF  | Managed — actions Reprocess, Cancel  |
| `ZBP_I_Q2C_ARQ_MGR`       | CLAS  | Handler global (abstract final)      |
| `ZBP_I_Q2C_ARQ_MGR`       | CCIMP | Lógica das actions + insert_log      |
| `ZCL_Q2C_CPI_CALLER`      | CLAS  | Envia arquivo ao CPI (stub)          |
| `ZC_Q2C_ARQ_MGR_APP`      | DDLS  | Projection UI — redireciona `_Log`   |
| `ZC_Q2C_ARQ_MGR_APP`      | BDEF  | use action + use association _Log    |
| `ZC_Q2C_ARQ_MGR_APP_MDE`  | DDLX  | Anotações UI — facets, lineItem      |
| `ZSD_Q2C_ARQ_MGR_SVR`     | SRVD  | Expõe ARQ + LOG (para navegação)     |
| `ZSB_Q2C_ARQ_MGR_SVR`     | SRVB  | OData V4 - UI                        |

### App 2 — LOG / Histórico (`Log/`)

| Objeto                    | Tipo  | Descrição                            |
|---------------------------|-------|--------------------------------------|
| `ZI_Q2C_LOG_MGR`          | DDLS  | Interface LOG — lê `ZTBQ2C_LOG_MGR` |
| `ZI_Q2C_LOG_MGR`          | BDEF  | Managed com create (para inbound CPI)|
| `ZC_Q2C_LOG_MGR_APP`      | DDLS  | Projection UI standalone             |
| `ZC_Q2C_LOG_MGR_APP`      | BDEF  | Projection read-only (sem create)    |
| `ZC_Q2C_LOG_MGR_APP_MDE`  | DDLX  | Anotações UI                         |
| `ZSD_Q2C_LOG_MGR_SVR`     | SRVD  | Expõe LOG standalone                 |
| `ZSB_Q2C_LOG_MGR_SVR`     | SRVB  | OData V4 - UI                        |

### Inbound CPI — Callback de Resultado (`Arq - INB/` e `Log - INB/`)

| Objeto                    | Tipo  | Descrição                            |
|---------------------------|-------|--------------------------------------|
| `ZC_Q2C_ARQ_INB`          | DDLS  | Projection inbound ARQ — só Status + UltimoErro |
| `ZC_Q2C_ARQ_INB`          | BDEF  | use update — CPI faz PATCH           |
| `ZSD_Q2C_ARQ_INB_SVR`     | SRVD  | Expõe ArqInb                         |
| `ZSB_Q2C_ARQ_INB_SVR`     | SRVB  | OData V4 - **Web API** (máquina)    |
| `ZC_Q2C_LOG_INB`          | DDLS  | Projection inbound LOG — todos os campos |
| `ZC_Q2C_LOG_INB`          | BDEF  | use create — CPI faz POST           |
| `ZSD_Q2C_LOG_INB_SVR`     | SRVD  | Expõe LogInb                         |
| `ZSB_Q2C_LOG_INB_SVR`     | SRVB  | OData V4 - **Web API** (máquina)    |

### Job de Limpeza (`JOB/`)

| Objeto                    | Tipo  | Descrição                            |
|---------------------------|-------|--------------------------------------|
| `ZCL_Q2C_MGR_CLEANUP`     | CLAS  | APJ — `IF_APJ_DT/RT_EXEC_OBJECT`    |
| `ZQ2C_CLEANUP_CE`         | —     | Job Catalog Entry (manual no ADT)    |
| `ZQ2C_CLEANUP_JT`         | —     | Job Template (manual no ADT)         |
| `ZQ2C_LOG`                | —     | Log Object BALI (manual em SBAL_OBJECT) |

---

## Documentação

| Arquivo               | Conteúdo                                              |
|-----------------------|-------------------------------------------------------|
| [DEV_GUIDE.md](DEV_GUIDE.md) | Modelo de dados, código de referência, decisões de arquitetura |
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | Passo a passo de criação dos objetos no ADT/SAP |

---

## Pré-requisitos

- S/4HANA (sistema ABAP com RAP + OData V4)
- Pacote de desenvolvimento definido (ver DEV_GUIDE Seção 10)
- Classe `ZCL_Q2C_CPI_CALLER` existente ou stub criado antes de ativar o CCIMP
- Acesso ao app Fiori F2373 (Application Jobs) para agendamento do job
