# V12 — Complementos para a Especificação Técnica (ET)

Itens implementados que **não constam na ET** (versão Inicial 19/05/2026).
Formato idêntico ao documento — copiar e colar nas seções indicadas.

---

## ► Seção 3 — Dependências (TVARV) — ADICIONAR linha

Adicionar à tabela existente da seção 3:

| TVARV | Descrição | Utilização |
|---|---|---|
| ZZ_GAP014_BAND_DEPARA | De-para Bandeira | Define a tradução entre o código técnico do arquivo recebido da MGR (ex.: PMDREN) e o nome amigável exibido na coluna Bandeira do cockpit Fiori (ex.: DSH_Renault). Manutenção via SM30 da tabela ZZ1_TVARVC_Q2C sem necessidade de retransporte de código. |

---

## ► Seção 3.1 — Atividades de Cutover — ADICIONAR linha

Adicionar à tabela existente da seção 3.1:

| TVARV | Descrição | Utilização |
|---|---|---|
| ZZ_GAP014_BAND_DEPARA | De-para Bandeira | Define a tradução entre o código técnico do arquivo recebido da MGR (ex.: PMDREN) e o nome amigável exibido na coluna Bandeira do cockpit Fiori (ex.: DSH_Renault). Manutenção via SM30 da tabela ZZ1_TVARVC_Q2C sem necessidade de retransporte de código. |

---

## ► Seção 4.2 — Objetos Criados/Alterados — ADICIONAR linhas

Adicionar às linhas existentes da tabela de objetos:

| Tipo | Objeto | Descrição |
|---|---|---|
| Tabela | ZZ1_TVARVC_Q2C | Tabela customizada de variáveis de parametrização Q2C (TVARV custom). Armazena os parâmetros ZZ_GAP014_ARQ_DIAS (retenção do job de cleanup) e ZZ_GAP014_BAND_DEPARA (de-para Bandeira). Manutenção via SM30. |
| Grupo de Funções | ZFG_Q2C_ASYNC | Grupo de funções para chamadas assíncronas ao CPI. Contém o FM ZFM_Q2C_CPI_CALL_ASYNC. |
| Function Module | ZFM_Q2C_CPI_CALL_ASYNC | FM RFC-enabled que executa a chamada ao CPI em nova work process (STARTING NEW TASK), desacoplada do contexto RAP. Necessário para evitar HTTP 423 causado pelo lock ativo durante o callback do CPI. |
| App Log Object | ZQ2C_ARQ | Objeto de log de aplicação (SLG0) para a solução Q2C ARQ Manager. Criado via transação SLG0. |
| App Log Subobject | CLEANUP | Subobjeto de log para o job de limpeza ZCL_Q2C_ARQ_CLEANUP. Vinculado ao objeto ZQ2C_ARQ. Criado via transação SLG0. |
| Job Catalog Entry | ZQ2C_ARQ_CLEANUP_CE | Catalog Entry APJ que registra o job de limpeza no framework Application Job. Aponta para a classe ZCL_Q2C_ARQ_CLEANUP. |
| Job Template | ZQ2C_ARQ_CLEANUP_JT | Template APJ para agendamento do job de limpeza. Usa o Catalog Entry ZQ2C_ARQ_CLEANUP_CE; parâmetro P_DIAS default lido da TVARV ZZ_GAP014_ARQ_DIAS. |
| Programa | ZR_Q2C_CLEANUP_RUNNER | Report ABAP para execução direta do job de limpeza fora do framework APJ (uso em teste e operação emergencial). |
| Programa | ZR_Q2C_CLEANUP_SEED_DATA | Report ABAP auxiliar para geração de massa de dados de teste (registros com datas retroativas). Uso exclusivo em ambiente de desenvolvimento/teste. |

---

## ► Seção 4.3.1 — Tabelas — ADICIONAR tabela ZZ1_TVARVC_Q2C

| | |
|---|---|
| **Nome** | ZZ1_TVARVC_Q2C |
| **Descrição** | Tabela de variáveis de parametrização customizadas Q2C |
| **Manutenção (SM30)** | SIM |
| **Campos principais** | MANDT (chave), NAME CHAR 30 (chave), TYPE CHAR 1 (chave), NUMB NUMC 4 (chave), LOW CHAR 45, HIGH CHAR 45 |
| **Índices** | N/A |
| **Observação** | Não é a tabela standard TVARVC. Layout equivalente, namespace Z. Usada para parâmetros ZZ_GAP014_ARQ_DIAS e ZZ_GAP014_BAND_DEPARA. |

---

## ► Seção 4.3.9 — Programas — ADICIONAR

**Nome:** ZR_Q2C_CLEANUP_RUNNER
**Descrição:** Executor direto do job de limpeza
**Tipo:** Report
**Lógica:** Instancia ZCL_Q2C_ARQ_CLEANUP e executa o método IF_APJ_RT_EXEC_OBJECT~EXECUTE diretamente, sem o framework APJ. Aceita parâmetros P_DIAS (número de dias de retenção) e P_TESTE (checkbox — sem delete real). Utilizado para execução emergencial ou testes fora do agendamento APJ.

---

**Nome:** ZR_Q2C_CLEANUP_SEED_DATA
**Descrição:** Gerador de massa de dados para teste do cleanup
**Tipo:** Report
**Lógica:** Insere registros na ZTBQ2C_ARQ_MGR com datas retroativas (acima de 90 dias) para validação do job de limpeza em ambiente de desenvolvimento/teste. Não deve ser transportado para produção.

---

## ► Seção 4.3.10 — Classes / Interfaces — NENHUM OBJETO NOVO
Todos os objetos desta seção já constam na ET. Nenhum ajuste necessário.

---

## ► Seção 4.3.11 — Grupo de Funções — ADICIONAR

**Nome:** ZFG_Q2C_ASYNC
**Descrição:** Grupo de funções para chamadas assíncronas CPI

**FM: ZFM_Q2C_CPI_CALL_ASYNC**

| | |
|---|---|
| **Descrição** | Wrapper RFC para chamada assíncrona ao CPI |
| **RFC** | Remote-Enabled Module (RFC obrigatório para STARTING NEW TASK funcionar). Chamado internamente pelo behavior ZBP_I_Q2C_ARQ_MGR via CALL FUNCTION STARTING NEW TASK. |
| **Parâmetros IMPORTING** | IV_PEDIDO TYPE ztbq2c_arq_mgr-pedido (VALUE), IV_BANDEIRA TYPE ztbq2c_arq_mgr-bandeira (VALUE) |
| **Exceções** | N/A |
| **Lógica** | Lê o registro completo da ZTBQ2C_ARQ_MGR pela chave recebida; aguarda 5 segundos (garante liberação do lock RAP e commit antes do callback); instancia ZCL_Q2C_CPI_CALLER e executa CALL_CPI_REPROCESS. O FM não contém lógica de negócio — apenas isola a chamada HTTP do contexto RAP para evitar HTTP 423 causado pelo lock ativo. |

---

## ► Seção 4.3.12 — Parâmetros — ADICIONAR

Adicionar ao texto da seção:

| TVARV | Tabela | Tipo | Campo LOW | Campo HIGH | Utilização |
|---|---|---|---|---|---|
| ZZ_GAP014_ARQ_DIAS | ZZ1_TVARVC_Q2C | P | Quantidade de dias (ex.: 090) | — | Retenção de registros — lida pelo job ZCL_Q2C_ARQ_CLEANUP. Fallback 90 dias se ausente. |
| ZZ_GAP014_BAND_DEPARA | ZZ1_TVARVC_Q2C | S | Código técnico bandeira (ex.: PMDREN) | Nome amigável (ex.: DSH_Renault) | De-para exibido na coluna Bandeira do cockpit Fiori. Lido pela CDS ZI_Q2C_ARQ_MGR via LEFT OUTER JOIN. Fallback exibe a própria bandeira se entrada ausente. |

Carga inicial de ZZ_GAP014_BAND_DEPARA: ver arquivo ENTRADAS_TVARV_ZZ_GAP014_BAND_DEPARA.txt neste pacote.

---

## ► Seção 4.3.7 — CDS Básica — AJUSTAR descrição de ZI_Q2C_ARQ_MGR

| Tipo | Objeto | Descrição |
|---|---|---|
| CDS – View Entity (Básica) | ZI_Q2C_ARQ_MGR | Base de dados de arquivos MGR. Inclui campo derivado BandeiraDesc obtido via LEFT OUTER JOIN à ZZ1_TVARVC_Q2C (NAME = ZZ_GAP014_BAND_DEPARA, TYPE = S, LOW = bandeira técnica) — exibido na coluna Bandeira do cockpit via @ObjectModel.text.element + @UI.textArrangement: #TEXT_ONLY. Sem entrada cadastrada exibe a própria bandeira (fallback). |

REMOVER da lista a view ZI_Q2C_LOG_LAST_TIME — foi consolidada dentro de ZI_Q2C_LOG_LAST (max(datum) + max(uzeit) via group by), eliminando a necessidade de view separada.

Comparação realizada em **03/06/2026** entre a ET (CR51 – GAP 014 – Q2C014E010 Reprocessar MGR, versão Inicial 19/05/2026, autor Renato Tiezzi) e o estado atual do repositório (após V11).

Este pacote **não introduz código novo** — registra os deltas que precisam ser refletidos no documento da ET e/ou na carga de dados, antes do deploy do CR.

---

## 1. Itens implementados que NÃO estão na ET

### 1.1 TVARV `ZZ_GAP014_BAND_DEPARA` (V11) — FALTANTE NA ET

A V11 trocou o de-para hardcode por leitura de `ZZ1_TVARVC_Q2C`. A ET hoje, em **3 (Dependências)**, **3.1 (Cutover)** e **4.3.12 (Parâmetros)**, só lista:

| TVARV existente na ET | Descrição | Utilização |
|-----------------------|-----------|------------|
| ZZ_GAP014_ARQ_DIAS    | Retenção de arquivos e logs | Define dias para limpeza automática |

**Adicionar na ET (mesma seção):**

| TVARV a incluir | Descrição | Utilização |
|-----------------|-----------|------------|
| `ZZ_GAP014_BAND_DEPARA` | De-para Bandeira → Operação | Traduz o `tipoArquivo` técnico recebido da MGR (ex.: `PMDREN`) para o nome amigável (ex.: `DSH_Renault`) exibido na coluna **Bandeira** do cockpit Fiori (List Report e Object Page do app `ZUI_Q2C_ARQ_MGR_APP`). |

**Estrutura das entradas (`TYPE = S`, range):**

```
NAME = ZZ_GAP014_BAND_DEPARA
TYPE = S
LOW  = <tipoArquivo recebido>      (ex.: PMDREN)
HIGH = <operação a exibir>          (ex.: DSH_Renault)
```

Carga inicial em [ENTRADAS_TVARV_ZZ_GAP014_BAND_DEPARA.txt](ENTRADAS_TVARV_ZZ_GAP014_BAND_DEPARA.txt) — replicar via SM30 / maintenance da `ZZ1_TVARVC_Q2C` no transporte de customizing (DS4K907886).

### 1.2 Tabela `ZZ1_TVARVC_Q2C` — FALTANTE NA ET

A ET seção **4.2 (Objetos Criados/Alterados)** e **4.3.1 (Tabelas)** lista apenas:

- `ZTBQ2C_ARQ_MGR`
- `ZTBQ2C_LOG_MGR`

**Adicionar:**

| Tipo   | Objeto             | Descrição |
|--------|--------------------|-----------|
| Tabela | `ZZ1_TVARVC_Q2C`   | Tabela customizada de variáveis (TVARV custom) usada pela solução Q2C – GAP 014. Armazena os parâmetros `ZZ_GAP014_ARQ_DIAS` (retenção do job de cleanup) e `ZZ_GAP014_BAND_DEPARA` (de-para Bandeira). |

> A solução **não usa a TVARVC standard SAP** — usa uma tabela customizada `ZZ1_TVARVC_Q2C` com layout equivalente (campos `NAME`, `TYPE`, `NUMB`, `LOW`, `HIGH`). Esse ponto **precisa ficar explícito na ET** para evitar confusão na operação.

E em **4.3.1**, alterar **Manutenção (SM30): N/A** para **Manutenção (SM30): SIM** (View de manutenção é necessária para o time funcional manter o de-para sem novo transporte).

### 1.3 CDS `ZI_Q2C_ARQ_MGR` — descrição desatualizada

ET lista como "Base de dados de arquivos MGR". Após V11, a view faz **LEFT OUTER TO ONE JOIN** em `ZZ1_TVARVC_Q2C` para derivar o campo `BandeiraDesc`.

**Adicionar à descrição na seção 4.3.7 (CDS Básica):**

> *"Base de dados de arquivos MGR. Inclui campo derivado `BandeiraDesc` via join à `ZZ1_TVARVC_Q2C` (NAME = `ZZ_GAP014_BAND_DEPARA`, TYPE = `S`) — exibido na coluna Bandeira do List Report via `@ObjectModel.text.element` + `@UI.textArrangement: #TEXT_ONLY`. Sem entrada cadastrada exibe a própria bandeira (fallback)."*

---

## 2. Itens listados na ET que NÃO existem na implementação

### 2.1 `ZI_Q2C_LOG_LAST_TIME` — view consolidada na implementação

A ET lista no **4.3.7** duas views básicas:
- `ZI_Q2C_LOG_LAST` — Último log por arquivo
- `ZI_Q2C_LOG_LAST_TIME` — Timestamp do último processamento

A implementação **consolidou ambas** em `ZI_Q2C_LOG_LAST.ddls` (`max(datum)` + `max(uzeit)` via `group by`). Funcionalmente equivalente; reduz uma view e simplifica o `ZI_Q2C_LOG_SUM`.

**Decisão recomendada:** atualizar ET para listar somente `ZI_Q2C_LOG_LAST` (motivo: simplificação, sem perda funcional).

Caso a ET seja mantida como está, será necessário criar `ZI_Q2C_LOG_LAST_TIME` separadamente — recomenda-se NÃO fazer (overhead sem ganho).

---

## 3. Resumo dos itens a adicionar/corrigir na ET (texto pronto)

### Seção 3 — Dependências
> "A solução possui dependência direta da correta manutenção das seguintes TVARVs, criadas no transporte:
> - `ZZ_GAP014_ARQ_DIAS` — Retenção de arquivos e logs
> - **`ZZ_GAP014_BAND_DEPARA` — De-para Bandeira → Operação (exibição no cockpit)**"

### Seção 3.1 — Atividade de Cutover
Adicionar linha:
> "Carga das entradas de de-para na `ZZ1_TVARVC_Q2C` (NAME = `ZZ_GAP014_BAND_DEPARA`) — ver arquivo `ENTRADAS_TVARV_ZZ_GAP014_BAND_DEPARA.txt`."

### Seção 4.2 — Objetos Criados/Alterados
Adicionar:
| Tipo | Objeto | Descrição |
|------|--------|-----------|
| Tabela | `ZZ1_TVARVC_Q2C` | Tabela de variáveis customizadas Q2C (parâmetros de retenção e de-para) |

### Seção 4.3.12 — Parâmetros
Adicionar:
> "**`ZZ_GAP014_BAND_DEPARA`** — Mantida em `ZZ1_TVARVC_Q2C` com TYPE = `S` (range: LOW = tipoArquivo, HIGH = operação). Lida pela `ZI_Q2C_ARQ_MGR` para traduzir a coluna Bandeira no cockpit Fiori. Manutenção via SM30 da tabela. Sem entrada cadastrada para uma bandeira → fallback exibe a própria bandeira."

### Seção 4.3.1 — Tabelas
Trocar `Manutenção (SM30): N/A` por `Manutenção (SM30): SIM` para `ZZ1_TVARVC_Q2C` e adicionar visão de manutenção `ZZ1_TVARVC_Q2C_VW` (ou nome equivalente — confirmar).

### Seção 4.3.7 — CDS Básica
- Atualizar descrição de `ZI_Q2C_ARQ_MGR` (item 1.3 acima).
- Remover `ZI_Q2C_LOG_LAST_TIME` da lista (consolidado em `ZI_Q2C_LOG_LAST`).

---

## 4. Itens conferidos (OK — não há gap)

| Categoria | Status |
|-----------|--------|
| Tabelas `ZTBQ2C_ARQ_MGR`, `ZTBQ2C_LOG_MGR` | ✓ implementadas |
| Views `ZI_Q2C_ARQ_MGR`, `ZI_Q2C_LOG_MGR`, `ZI_Q2C_LOG_DET`, `ZI_Q2C_LOG_SUM`, `ZI_Q2C_LOG_LAST` | ✓ implementadas |
| Views consumo `ZC_Q2C_ARQ_MGR_APP/_SVR`, `ZC_Q2C_LOG_MGR_APP/_SVR`, `ZC_Q2C_LOG_SUM_APP`, `ZC_Q2C_LOG_DET_APP`, `ZC_Q2C_STATUS_VH_APP` | ✓ implementadas |
| MDE: `ZC_Q2C_ARQ_MGR_APP_MDE`, `ZC_Q2C_LOG_MGR_APP_MDE`, `ZC_Q2C_LOG_SUM_APP_MDE`, `ZC_Q2C_LOG_DET_APP_MDE` | ✓ implementadas |
| Service Bindings APP/SVR (Arq + Log) | ✓ implementadas |
| Classes `ZCL_Q2C_CPI_CALLER`, `ZCL_Q2C_ARQ_CLEANUP`, `ZBP_I_Q2C_ARQ_MGR`, `ZBP_I_Q2C_LOG_SUM` | ✓ implementadas |
| TVARV `ZZ_GAP014_ARQ_DIAS` (job cleanup) | ✓ implementada (V9) |
| Domínios `ZDOQ2C_ETAPA`, `ZDOQ2C_STRING` e DEs `ZDEQ2C_*` | ✓ conforme ET (criados no DDIC do sistema) |

---

## 5. Itens neste pacote V12

| Arquivo | Conteúdo |
|---------|----------|
| `README.md` | Este documento (gaps ET ↔ implementação) |
| `ENTRADAS_TVARV_ZZ_GAP014_BAND_DEPARA.txt` | Carga inicial das entradas para o de-para Bandeira |

**Nenhum objeto ABAP/CDS é alterado nesta versão.** As mudanças são:
1. Editorial — atualizar a ET conforme seção 3 acima.
2. Operacional — carregar entradas TVARV via SM30 (cutover).
