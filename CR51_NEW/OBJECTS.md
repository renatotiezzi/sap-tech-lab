# CR51 NEW — Matriz de Objetos

Visão consolidada de todos os objetos da solução. Ordenada por camada e grupo funcional.

---

## Tabelas (DDIC)

| Objeto | Tipo | Propósito | Quem usa |
|--------|------|-----------|----------|
| `ZTBQ2C_ARQ_MGR` | TABL | Armazena o arquivo TXT e status atual. 1 linha por (Pedido + Bandeira). Atualizado a cada reprocessamento ou cancelamento. | ARQ BO, CPI inbound ARQ |
| `ZTBQ2C_LOG_MGR` | TABL | Histórico de tentativas — INSERT-only. Nunca atualiza, nunca deleta (exceto cleanup 90 dias). | LOG BO, CPI inbound LOG |

---

## App 1 — Monitor / Reprocessamento

Fiori List Report com botões Reprocessar e Cancelar. Sem Object Page.

### Camada Interface (BO raiz)

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZI_Q2C_ARQ_MGR` | DDLS | View raiz sobre `ZTBQ2C_ARQ_MGR`. Calcula `StatusCriticality` (CASE). | Base do BO RAP — lida pelo framework |
| `ZI_Q2C_ARQ_MGR` | BDEF | Managed BO. Define `update`, `action Reprocess`, `action Cancel`. Liga ao handler `ZBP_I_Q2C_ARQ_MGR`. | RAP exige BDEF para expor comportamento |
| `ZBP_I_Q2C_ARQ_MGR` | CLAS | Classe global abstract final do handler. Declaração obrigatória para o BDEF encontrar o handler. | ADT valida existência da classe ao ativar o BDEF |
| `ZBP_I_Q2C_ARQ_MGR` | CCIMP | Local Types — lógica real das actions: valida status, chama CPI, grava LOG, atualiza ARQ. | Onde o código roda de fato |
| `ZCL_Q2C_CPI_CALLER` | CLAS | Stub que encapsula a chamada HTTP ao iFlow CPI. Recebe `ztbq2c_arq_mgr`, retorna sucesso/erro. | Separação de responsabilidades — CCIMP não chama HTTP diretamente |

### Camada Projeção UI (App 1)

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZC_Q2C_STATUS_VH_APP` | DDLS | View auxiliar — `SELECT DISTINCT status` da tabela ARQ. Alimenta o Value Help do filtro Status. | `@Consumption.valueHelpDefinition` na projeção ARQ exige entidade ativa |
| `ZC_Q2C_ARQ_MGR_APP` | DDLS | Projeção UI sobre `ZI_Q2C_ARQ_MGR`. Expõe campos com anotações de VH. `provider contract transactional_query`. | RAP exige projeção separada da interface para o serviço Fiori |
| `ZC_Q2C_ARQ_MGR_APP` | BDEF | Projection BDEF. `use action Reprocess; use action Cancel`. | Exposição seletiva de comportamento para o Fiori |
| `ZC_Q2C_ARQ_MGR_APP_MDE` | DDLX | Metadata Extension. Define `@UI.lineItem`, `@UI.selectionField` para todas as colunas e filtros do List Report. | Fiori Elements lê as anotações para montar a tela automaticamente |

### Serviço (App 1)

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZSD_Q2C_ARQ_MGR_APP` | SRVD | Service Definition — expõe `ZC_Q2C_ARQ_MGR_APP` (ArqMgrApp) e `ZC_Q2C_STATUS_VH_APP` (StatusVH). | Define quais entidades ficam acessíveis no endpoint OData |
| `ZSB_Q2C_ARQ_MGR_APP` | SRVB | Service Binding — **OData V4 - UI**. Liga a SRVD ao endpoint HTTP do Fiori. | Publicar = gerar URL do serviço; Fiori Launchpad aponta para este binding |

---

## App 2 — LOG / Histórico

Fiori List Report (última execução por chave) + Object Page (histórico completo via `_Detail`).

### Camada Interface (BO LOG raiz)

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZI_Q2C_LOG_MGR` | DDLS | View raiz sobre `ZTBQ2C_LOG_MGR`. Todos os campos do LOG. | Base do BO LOG — permite create via inbound CPI |
| `ZI_Q2C_LOG_MGR` | BDEF | Managed BO com `create` + mapping. Sem update/delete (INSERT-only). | Framework RAP gera o INSERT automaticamente via mapping |
| `ZBP_I_Q2C_LOG_MGR` | CLAS | Handler global abstract final do LOG BO. Classe vazia — framework cuida do create via mapping. | ADT exige existência da classe declarada no BDEF |
| `ZBP_I_Q2C_LOG_MGR` | CCIMP | Local Types vazio — nenhuma lógica customizada necessária. | Placeholder obrigatório pela estrutura RAP |

### Camada Interface (BO Sumário — read-only)

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZI_Q2C_LOG_LAST` | DDLS | Helper — agrega `MAX(datum)` e `MAX(uzeit)` por (Pedido + Bandeira). Sem BDEF. | `ZI_Q2C_LOG_SUM` depende desta view para saber qual é a última execução |
| `ZI_Q2C_LOG_SUM` | DDLS | View raiz de sumário — JOIN `ZI_Q2C_LOG_LAST` + `ZTBQ2C_LOG_MGR`. 1 linha por chave com campos da última execução. `_Detail` → `ZI_Q2C_LOG_MGR`. | BO separado para o List Report do App 2 (1 linha por chave, não 1 por execução) |
| `ZI_Q2C_LOG_SUM` | BDEF | Unmanaged read-only. Sem create/update/delete. `authorization not required`. | RAP exige BDEF para o BO aparecer como root e ser projetável |
| `ZBP_I_Q2C_LOG_SUM` | CLAS | Handler global abstract final do BO sumário. Vazio — nenhum comportamento write necessário. | ADT exige existência ao ativar o BDEF |
| `ZBP_I_Q2C_LOG_SUM` | CCIMP | Local Types com handler vazio `lhc_log_sum`. | RAP exige ao menos a declaração do handler local para unmanaged BOs |

### Camada Projeção UI (App 2)

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZC_Q2C_LOG_SUM_APP` | DDLS | Projeção do sumário — List Report do App 2. Expõe UltDatum, UltEtapa, UltMensagem etc. | Fiori Elements monta o List Report a partir desta projeção |
| `ZC_Q2C_LOG_SUM_APP` | BDEF | Projection BDEF. `use association _Detail`. | Habilita a navegação List Report → Object Page via `_Detail` |
| `ZC_Q2C_LOG_SUM_APP_MDE` | DDLX | Anotações UI do List Report + `@UI.facet` para Object Page (aponta para `_Detail`). | Fiori Elements precisa das anotações para montar List Report e Object Page |
| `ZC_Q2C_LOG_MGR_APP` | DDLS | Projeção do histórico completo — target da navegação `_Detail`. Todos os logs de uma chave. | Object Page do App 2 exibe esta entidade como tabela de linhas |
| `ZC_Q2C_LOG_MGR_APP` | BDEF | Projection BDEF read-only. Sem actions — apenas leitura. | Necessário para o framework RAP reconhecer a entidade como projetável |
| `ZC_Q2C_LOG_MGR_APP_MDE` | DDLX | Anotações UI — `@UI.lineItem` para as colunas da tabela de histórico no Object Page. | Fiori Elements renderiza a tabela dentro do Object Page com base nestas anotações |

### Serviço (App 2)

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZSD_Q2C_LOG_MGR_APP` | SRVD | Service Definition — expõe `ZC_Q2C_LOG_SUM_APP` (LogSum) e `ZC_Q2C_LOG_MGR_APP` (LogDetail). | Ambas as entidades precisam estar no mesmo serviço para a navegação `_Detail` funcionar |
| `ZSB_Q2C_LOG_MGR_APP` | SRVB | Service Binding — **OData V4 - UI**. | Fiori Launchpad aponta para este binding para o App 2 |

---

## Inbound CPI — Callback de Resultado (Web API)

Chamado pelo iFlow CPI após processar o arquivo. Machine-to-machine.

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZC_Q2C_ARQ_MGR_SVR` | DDLS | Projeção CPI do ARQ. `provider contract transactional_query`. Expõe todos os campos de ZI_Q2C_ARQ_MGR. | RAP exige projeção separada para SRVB Web API — distinção UI×API fica no SRVB, não no provider contract |
| `ZC_Q2C_ARQ_MGR_SVR` | BDEF | `use update`. CPI faz PATCH. | Exposição do update para o CPI atualizar o registro ARQ |
| `ZSD_Q2C_ARQ_MGR_SVR` | SRVD | Service Definition — expõe `ZC_Q2C_ARQ_MGR_SVR` (ArqSvr). | Serviço separado do Fiori — contrato e binding type diferentes |
| `ZSB_Q2C_ARQ_MGR_SVR` | SRVB | Service Binding — **OData V4 - Web API**. | Web API = contrato adequado para machine-to-machine CPI → SAP |
| `ZC_Q2C_LOG_MGR_SVR` | DDLS | Projeção CPI do LOG para inserção. `provider contract transactional_query`. | CPI cria nova linha no LOG a cada callback |
| `ZC_Q2C_LOG_MGR_SVR` | BDEF | `use create`. CPI faz POST. | Framework RAP gera o INSERT via mapping |
| `ZSD_Q2C_LOG_MGR_SVR` | SRVD | Service Definition — expõe `ZC_Q2C_LOG_MGR_SVR` (LogSvr). | |
| `ZSB_Q2C_LOG_MGR_SVR` | SRVB | Service Binding — **OData V4 - Web API**. | |

---

## Job de Limpeza (APJ)

Execução agendada — remove dados antigos das tabelas.

| Objeto | Tipo | Propósito | Necessidade |
|--------|------|-----------|-------------|
| `ZQ2C_LOG` | BALI | Log Object para registrar execuções do job (subobject: `CLEANUP`). Criado manualmente em `SBAL_OBJECT`. | `ZCL_Q2C_MGR_CLEANUP` usa BALI para logar resultado |
| `ZCL_Q2C_MGR_CLEANUP` | CLAS | Implementa `IF_APJ_DT_EXEC_OBJECT` + `IF_APJ_RT_EXEC_OBJECT`. Lógica: DELETE LOG > 90 dias; DELETE ARQ CANCELADO/PROCESSADO > corte; ARQ ERRO nunca removido. | Ponto de entrada do Application Jobs (F2373) |
| `ZQ2C_CLEANUP_CE` | APJ CE | Job Catalog Entry — registra a classe no APJ framework. Criado manualmente no ADT. | APJ exige Catalog Entry para expor o job |
| `ZQ2C_CLEANUP_JT` | APJ JT | Job Template — define parâmetro padrão `P_DAYS = 90`. Criado manualmente no ADT. | Permite agendamento recorrente sem redigitar parâmetros |

---

## Legenda de Tipos

| Tipo | Significado |
|------|-------------|
| TABL | Tabela transparente DDIC |
| DDLS | CDS Data Definition (view) |
| BDEF | Behavior Definition RAP |
| CLAS | Classe ABAP global |
| CCIMP | Local Types da classe (aba "Local Types" no ADT) |
| DDLX | Metadata Extension (anotações UI) |
| SRVD | Service Definition OData |
| SRVB | Service Binding OData |
| BALI | Log Object (SBAL) |
| APJ CE | Application Jobs Catalog Entry |
| APJ JT | Application Jobs Job Template |
