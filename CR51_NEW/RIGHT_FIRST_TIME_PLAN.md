# CR51 NEW — Plano Right-First-Time

**Data:** 08/05/2026  
**Sistema:** vhilfws1wd01.sap.iconic.com.br:44380 · Client 100  
**Branch:** `main` (commit atual: `9b19f0d`)

---

## Bugs Corrigidos Antes da Ativação

| # | Arquivo | Problema | Correção |
|---|---------|----------|----------|
| 1 | `ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt` | Comentário stale: "ARQ não possui campo ULTIMO_ERRO" | Corrigido — ARQ possui ULTIMO_ERRO (STRING) |
| 2 | `ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt` | `is_arq = entity` — tipo RAP derivado incompatível com método regular | Corrigido → `CORRESPONDING ztbq2c_arq_mgr( entity )` |
| 3 | `ZCL_Q2C_CPI_CALLER.clas.txt` | Backup tinha campo `cabec_arq` (campo removido) e assinatura sem `is_arq` | Novo stub criado em CR51_NEW com `is_arq TYPE ztbq2c_arq_mgr` |

---

## Pré-condições (verificar ANTES de iniciar)

| # | Verificação | Como |
|---|-------------|------|
| P1 | `ZTBQ2C_ARQ_MGR` **Active** no SE11 | Confirmado via screenshot |
| P2 | `ZTBQ2C_LOG_MGR` **Active** no SE11 | **Verificar agora** — SE11 → ativar se necessário |
| P3 | Pacote e transport request definidos | Criar TR para todos os objetos novos |
| P4 | `ZCL_Q2C_CPI_CALLER` **não existe** no sistema | Criar fresh a partir do stub (não usar backup CR51_ListReport) |

---

## Ordem de Ativação

### Fase 2 — BO LOG (criar primeiro)

> Razão: `ZI_Q2C_ARQ_MGR` depende de `ZI_Q2C_LOG_MGR` via `association _Log`.  
> O LOG deve estar ativo antes de qualquer objeto ARQ.

| Seq | Objeto | Tipo | Ação ADT | Arquivo fonte |
|-----|--------|------|----------|---------------|
| 2.1 | `ZI_Q2C_LOG_MGR` | DDLS | New CDS View Entity → Root → copiar conteúdo | `Log/ZI_Q2C_LOG_MGR.ddls.txt` |
| 2.2 | `ZI_Q2C_LOG_MGR` | BDEF | New Behavior Definition → copiar | `Log/ZI_Q2C_LOG_MGR.bdef.txt` |
| 2.3 | `ZI_Q2C_LOG_LAST` | DDLS | New CDS View Entity (sem root) → copiar | `Log/ZI_Q2C_LOG_LAST.ddls.txt` |
| 2.4 | `ZBP_I_Q2C_LOG_SUM` | CLAS | New ABAP Class → PUBLIC ABSTRACT FINAL → copiar global | `Log/ZBP_I_Q2C_LOG_SUM.clas.txt` |
| 2.5 | `ZI_Q2C_LOG_SUM` | DDLS | New CDS View Entity → Root → copiar | `Log/ZI_Q2C_LOG_SUM.ddls.txt` |
| 2.6 | `ZI_Q2C_LOG_SUM` | BDEF | New Behavior Definition → copiar | `Log/ZI_Q2C_LOG_SUM.bdef.txt` |
| 2.7 | `ZBP_I_Q2C_LOG_SUM` | CCIMP | Abrir classe → aba "Local Types" → copiar | `Log/ZBP_I_Q2C_LOG_SUM.clas.locals_imp.txt` |
| 2.8 | `ZC_Q2C_LOG_MGR_APP` | DDLS | New CDS View Entity → Root → copiar | `Log/ZC_Q2C_LOG_MGR_APP.ddls.txt` |
| 2.9 | `ZC_Q2C_LOG_MGR_APP` | BDEF | New Behavior Definition → copiar | `Log/ZC_Q2C_LOG_MGR_APP.bdef.txt` |
| 2.10 | `ZC_Q2C_LOG_MGR_APP_MDE` | DDLX | New Metadata Extension → copiar | `Log/ZC_Q2C_LOG_MGR_APP_MDE.ddlx.txt` |
| 2.11 | `ZC_Q2C_LOG_SUM_APP` | DDLS | New CDS View Entity → Root → copiar | `Log/ZC_Q2C_LOG_SUM_APP.ddls.txt` |
| 2.12 | `ZC_Q2C_LOG_SUM_APP` | BDEF | New Behavior Definition → copiar | `Log/ZC_Q2C_LOG_SUM_APP.bdef.txt` |
| 2.13 | `ZC_Q2C_LOG_SUM_APP_MDE` | DDLX | New Metadata Extension → copiar | `Log/ZC_Q2C_LOG_SUM_APP_MDE.ddlx.txt` |
| 2.14 | `ZSD_Q2C_LOG_MGR_SVR` | SRVD | New Service Definition → copiar | `Log/ZSD_Q2C_LOG_MGR_SVR.srvd.txt` |
| 2.15 | `ZSB_Q2C_LOG_MGR_SVR` | SRVB | New Service Binding → OData V4 - UI → **Publish** | `Log/ZSB_Q2C_LOG_MGR_SVR.srvb.txt` (ref) |

> **Dependências internas Fase 2 (respeitar ordem):**  
> 2.1 → 2.2 (BDEF após DDLS)  
> 2.1 + 2.3 → 2.5 (ZI_Q2C_LOG_SUM depende de ZI_Q2C_LOG_LAST + ZI_Q2C_LOG_MGR)  
> 2.4 + 2.5 → 2.6 (BDEF depende da CLAS + DDLS)  
> 2.2 + 2.8 → 2.11 (ZC_Q2C_LOG_SUM_APP depende de ZI_Q2C_LOG_SUM BDEF + ZC_Q2C_LOG_MGR_APP)

**Checkpoint 2:** Publicar `ZSB_Q2C_LOG_MGR_SVR` e testar URL no browser — deve retornar metadata vazia (sem dados ainda é normal).

> **App 2 — estrutura esperada:**  
> List Report → 1 linha por (Pedido+Bandeira), campos da última execução (UltDatum, UltEtapa, UltMensagem).  
> Clicar no registro → Object Page → tabela com **todas** as execuções daquela chave (via `_Detail`).

---

### Fase 2.5 — Classe CPI Caller (criar antes do BDEF ARQ)

> Razão: O BDEF `ZI_Q2C_ARQ_MGR` declara `implementation in class ZBP_I_Q2C_ARQ_MGR`.  
> O CCIMP da classe instancia `ZCL_Q2C_CPI_CALLER` → classe deve existir ao ativar.

| Seq | Objeto | Tipo | Ação ADT |
|-----|--------|------|----------|
| 2.8 | `ZCL_Q2C_CPI_CALLER` | CLAS | New ABAP Class → PUBLIC FINAL → copiar conteúdo de `Arq - Monitor/ZCL_Q2C_CPI_CALLER.clas.txt` |

> **Atenção:** O método `call_cpi_reprocess` desta versão recebe `is_arq TYPE ztbq2c_arq_mgr`.  
> **Não usar** o backup de `CR51_ListReport/Backup/ZCL_Q2C_CPI_CALLER.clas.txt` — assinatura diferente.

---

### Fase 3 — BO ARQ (depende de LOG + CPI_CALLER)

| Seq | Objeto | Tipo | Ação ADT | Arquivo fonte | Dependência |
|-----|--------|------|----------|---------------|-------------|
| 3.1 | `ZI_Q2C_ARQ_MGR` | DDLS | New CDS View Entity → Root | `Arq - Monitor/ZI_Q2C_ARQ_MGR.ddls.txt` | ZI_Q2C_LOG_MGR ativo (Fase 2) |
| 3.2 | `ZBP_I_Q2C_ARQ_MGR` | CLAS | New ABAP Class → PUBLIC ABSTRACT FINAL → copiar global | `Arq - Monitor/ZBP_I_Q2C_ARQ_MGR.clas.txt` | ZI_Q2C_ARQ_MGR ativo |
| 3.3 | `ZI_Q2C_ARQ_MGR` | BDEF | New Behavior Definition → copiar | `Arq - Monitor/ZI_Q2C_ARQ_MGR.bdef.txt` | ZBP_I_Q2C_ARQ_MGR ativo |
| 3.4 | `ZBP_I_Q2C_ARQ_MGR` | CCIMP | Abrir classe → aba "Local Types" → copiar conteúdo | `Arq - Monitor/ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt` | BDEF ativo (3.3) + ZCL_Q2C_CPI_CALLER ativo (2.8) |
| 3.5 | `ZC_Q2C_STATUS_VH_APP` | DDLS | New CDS View Entity → copiar | `Arq - Monitor/ZC_Q2C_STATUS_VH_APP.ddls.txt` | ZTBQ2C_ARQ_MGR ativo |
| 3.6 | `ZC_Q2C_ARQ_MGR_APP` | DDLS | New CDS View Entity → Root | `Arq - Monitor/ZC_Q2C_ARQ_MGR_APP.ddls.txt` | ZI_Q2C_ARQ_MGR (3.1) + ZC_Q2C_STATUS_VH_APP (3.5) + ZC_Q2C_LOG_MGR_APP (2.3) |
| 3.7 | `ZC_Q2C_ARQ_MGR_APP` | BDEF | New Behavior Definition → copiar | `Arq - Monitor/ZC_Q2C_ARQ_MGR_APP.bdef.txt` | BDEF ZI_Q2C_ARQ_MGR ativo (3.3) |
| 3.8 | `ZC_Q2C_ARQ_MGR_APP_MDE` | DDLX | New Metadata Extension → copiar | `Arq - Monitor/ZC_Q2C_ARQ_MGR_APP_MDE.ddlx.txt` | ZC_Q2C_ARQ_MGR_APP ativo (3.6) |
| 3.9 | `ZSD_Q2C_ARQ_MGR_SVR` | SRVD | New Service Definition → copiar | `Arq - Monitor/ZSD_Q2C_ARQ_MGR_SVR.srvd.txt` | ZC_Q2C_ARQ_MGR_APP (3.6) + ZC_Q2C_LOG_MGR_APP (2.8) + ZC_Q2C_STATUS_VH_APP (3.5) |
| 3.10 | `ZSB_Q2C_ARQ_MGR_SVR` | SRVB | New Service Binding → OData V4 - UI → **Publish** | `Arq - Monitor/ZSB_Q2C_ARQ_MGR_SVR.srvb.txt` (ref) | ZSD_Q2C_ARQ_MGR_SVR ativo (3.9) |

**Checkpoint 3:** Publicar `ZSB_Q2C_ARQ_MGR_SVR` e testar via Fiori Launchpad.

---

### Fase 4 — Inbound CPI (callback de resultado — Web API)

> Pré-requisito: Fases 2 e 3 concluídas (ZI_Q2C_LOG_MGR e ZI_Q2C_ARQ_MGR ativos).

| Seq | Objeto | Tipo | Ação ADT | Arquivo fonte |
|-----|--------|------|----------|---------------|
| 4.1 | `ZC_Q2C_ARQ_INB` | DDLS | New CDS View Entity → Root → copiar | `Arq - INB/ZC_Q2C_ARQ_INB.ddls.txt` |
| 4.2 | `ZC_Q2C_ARQ_INB` | BDEF | New Behavior Definition → copiar | `Arq - INB/ZC_Q2C_ARQ_INB.bdef.txt` |
| 4.3 | `ZSD_Q2C_ARQ_INB_SVR` | SRVD | New Service Definition → copiar | `Arq - INB/ZSD_Q2C_ARQ_INB_SVR.srvd.txt` |
| 4.4 | `ZSB_Q2C_ARQ_INB_SVR` | SRVB | New Service Binding → **OData V4 - Web API** → Publish | `Arq - INB/ZSB_Q2C_ARQ_INB_SVR.srvb.txt` (ref) |
| 4.5 | `ZC_Q2C_LOG_INB` | DDLS | New CDS View Entity → Root → copiar | `Log - INB/ZC_Q2C_LOG_INB.ddls.txt` |
| 4.6 | `ZC_Q2C_LOG_INB` | BDEF | New Behavior Definition → copiar | `Log - INB/ZC_Q2C_LOG_INB.bdef.txt` |
| 4.7 | `ZSD_Q2C_LOG_INB_SVR` | SRVD | New Service Definition → copiar | `Log - INB/ZSD_Q2C_LOG_INB_SVR.srvd.txt` |
| 4.8 | `ZSB_Q2C_LOG_INB_SVR` | SRVB | New Service Binding → **OData V4 - Web API** → Publish | `Log - INB/ZSB_Q2C_LOG_INB_SVR.srvb.txt` (ref) |

> ⚠️ **Binding Type:** Web API (não UI) — obrigatório para machine-to-machine.  
> Consultar os arquivos `.srvb.txt` para exemplos de payload JSON (PATCH ARQ + POST LOG).

| Seq | Objeto | Tipo | Observação |
|-----|--------|------|------------|
| 5.1 | Log Object `ZQ2C_LOG` | SBAL | `SBAL_OBJECT` → subobject `CLEANUP` |
| 5.2 | `ZCL_Q2C_MGR_CLEANUP` | CLAS | Implementa `IF_APJ_DT/RT_EXEC_OBJECT` — arquivo: `JOB/ZCL_Q2C_MGR_CLEANUP.clas.txt` |
| 5.3 | Job Catalog Entry `ZQ2C_CLEANUP_CE` | ADT | Aponta para `ZCL_Q2C_MGR_CLEANUP` |
| 5.4 | Job Template `ZQ2C_CLEANUP_JT` | ADT | Usa Catalog Entry; `P_DAYS = 90` |
| 5.5 | Agendar | F2373 | App Fiori "Application Jobs" |

---

## Pitfalls Conhecidos

| # | Situação | O que fazer |
|---|----------|-------------|
| PT1 | `ZI_Q2C_ARQ_MGR` BDEF falha ao ativar | Verificar se `ZBP_I_Q2C_ARQ_MGR` (global) e `ZCL_Q2C_CPI_CALLER` estão ativos |
| PT2 | CCIMP não compila: "tipo incompatível" | Confirmar que `ZCL_Q2C_CPI_CALLER->call_cpi_reprocess` tem `is_arq TYPE ztbq2c_arq_mgr` (não o parâmetro individual do backup) |
| PT3 | LOG não aparece na Object Page do ARQ | O SRVD do ARQ (`ZSD_Q2C_ARQ_MGR_SVR`) expõe `ZC_Q2C_LOG_MGR_APP` — verificar que está ativo e exposto |
| PT4 | Value Help de Status vazio | `ZC_Q2C_STATUS_VH_APP` usa `SELECT DISTINCT` da tabela real — inserir pelo menos 1 registro de teste |
| PT5 | Colisão de chave no LOG (duplicate key) | Dois reprocessamentos no mesmo segundo causam falha no INSERT. Aceito como limitação conhecida |
| PT6 | `ZTBQ2C_LOG_MGR` inativo | Ativar no SE11 antes de iniciar Fase 2 |
| PT7 | Stub CPI retorna "sucesso" mas STATUS não muda | Esperado — CPI é assíncrono. A ação loga ENVIO_CPI mas não altera STATUS. Callback inbound atualiza o STATUS |
| PT8 | App 2 List Report vazio após reprocessamento | Verificar que ZI_Q2C_LOG_LAST e ZI_Q2C_LOG_SUM estão ativos; testar select direto na view |
| PT9 | Object Page do App 2 sem tabela de histórico | Verificar que `_Detail` em ZI_Q2C_LOG_SUM BDEF está declarado e ZC_Q2C_LOG_MGR_APP exposto no SRVD |

---

## Verificação Pós-Ativação (smoke test)

```
1. Acessar ZSB_Q2C_ARQ_MGR_SVR via Fiori Launchpad
2. Inserir 1 registro de teste na ZTBQ2C_ARQ_MGR (SE16N):
   PEDIDO=TEST0001, BANDEIRA=FORD, TIPO_DOC=ZVTF, STATUS=CRIADO, TENTATIVAS=0
3. Abrir app ARQ — registro deve aparecer com status "Criado" (ícone azul)
4. Clicar "Reprocessar"
   → STATUS não muda (CPI é assíncrono — callback pendente)
   → TENTATIVAS = 1, DATUM/UZEIT/ERNAM atualizados
   → Object Page → LOG App 1: 1 linha (ENVIO_CPI — "aguardando callback")
   → App 2 (LOG Viewer): 1 linha no List Report com UltEtapa = 'ENVIO_CPI'
5. Simular callback CPI (testar inbound):
   → PATCH `ZSB_Q2C_ARQ_INB_SVR` com `Status='PROCESSADO'`
   → POST `ZSB_Q2C_LOG_INB_SVR` com nova linha de resultado
   → ARQ deve mostrar STATUS=PROCESSADO
   → App 2 List Report: UltEtapa = 'CONCLUSAO'
6. Clicar "Cancelar" em outro registro com STATUS=ERRO
   → STATUS deve mudar para CANCELADO
   → LOG: 1 linha (CANCELAMENTO)
7. Tentar Reprocessar registro CANCELADO
   → Deve exibir mensagem de erro (validação ativa)
```

---

## Arquivos Fonte (referência rápida)

```
CR51_NEW/
├── Log/
│   ├── ZI_Q2C_LOG_MGR.ddls.txt            → 2.1
│   ├── ZI_Q2C_LOG_MGR.bdef.txt            → 2.2
│   ├── ZI_Q2C_LOG_LAST.ddls.txt           → 2.3  ← NOVO
│   ├── ZBP_I_Q2C_LOG_SUM.clas.txt         → 2.4  ← NOVO
│   ├── ZI_Q2C_LOG_SUM.ddls.txt            → 2.5  ← NOVO
│   ├── ZI_Q2C_LOG_SUM.bdef.txt            → 2.6  ← NOVO
│   ├── ZBP_I_Q2C_LOG_SUM.clas.locals_imp.txt → 2.7  ← NOVO
│   ├── ZC_Q2C_LOG_MGR_APP.ddls.txt        → 2.8
│   ├── ZC_Q2C_LOG_MGR_APP.bdef.txt        → 2.9
│   ├── ZC_Q2C_LOG_MGR_APP_MDE.ddlx.txt    → 2.10
│   ├── ZC_Q2C_LOG_SUM_APP.ddls.txt        → 2.11 ← NOVO
│   ├── ZC_Q2C_LOG_SUM_APP.bdef.txt        → 2.12 ← NOVO
│   ├── ZC_Q2C_LOG_SUM_APP_MDE.ddlx.txt    → 2.13 ← NOVO
│   ├── ZSD_Q2C_LOG_MGR_SVR.srvd.txt       → 2.14
│   └── ZSB_Q2C_LOG_MGR_SVR.srvb.txt       → 2.15 (ref — criar no ADT)
├── Arq - Monitor/
│   ├── ZCL_Q2C_CPI_CALLER.clas.txt        → 2.5-CPI (criar na Fase 2.5)
│   ├── ZI_Q2C_ARQ_MGR.ddls.txt            → 3.1
│   ├── ZBP_I_Q2C_ARQ_MGR.clas.txt         → 3.2
│   ├── ZI_Q2C_ARQ_MGR.bdef.txt            → 3.3
│   ├── ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt → 3.4
│   ├── ZC_Q2C_STATUS_VH_APP.ddls.txt      → 3.5
│   ├── ZC_Q2C_ARQ_MGR_APP.ddls.txt        → 3.6
│   ├── ZC_Q2C_ARQ_MGR_APP.bdef.txt        → 3.7
│   ├── ZC_Q2C_ARQ_MGR_APP_MDE.ddlx.txt    → 3.8
│   ├── ZSD_Q2C_ARQ_MGR_SVR.srvd.txt       → 3.9
│   └── ZSB_Q2C_ARQ_MGR_SVR.srvb.txt       → 3.10 (ref — criar no ADT)
├── Arq - INB/
│   ├── ZC_Q2C_ARQ_INB.ddls.txt            → 4.1
│   ├── ZC_Q2C_ARQ_INB.bdef.txt            → 4.2
│   ├── ZSD_Q2C_ARQ_INB_SVR.srvd.txt       → 4.3
│   └── ZSB_Q2C_ARQ_INB_SVR.srvb.txt       → 4.4 (ref — criar no ADT, Web API)
└── Log - INB/
    ├── ZC_Q2C_LOG_INB.ddls.txt            → 4.5
    ├── ZC_Q2C_LOG_INB.bdef.txt            → 4.6
    ├── ZSD_Q2C_LOG_INB_SVR.srvd.txt       → 4.7
    └── ZSB_Q2C_LOG_INB_SVR.srvb.txt       → 4.8 (ref — criar no ADT, Web API)
```
