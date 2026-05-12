# CR51 — Job de Limpeza: Registros Cancelados

**Classe:** `ZCL_Q2C_ARQ_CLEANUP`  
**Pacote:** `ZPQ2C_014`  
**Objetivo:** Deletar registros `CANCELADO` de `ZTBQ2C_ARQ_MGR` (e respectivos logs em `ZTBQ2C_LOG_MGR`) com data anterior a N dias (padrão: 90).

---

## Objetos a criar

| # | Objeto | Tipo | Descrição |
|---|--------|------|-----------|
| 0 | `ZZ1_TVARVC_Q2C` | Entrada de tabela | Parâmetro `ZZ_GAP014_ARQ_DIAS = 090` |
| 1 | `ZQ2C_ARQ` / `CLEANUP` | Application Log Object / Subobject | Log de execução do job |
| 2 | `ZCL_Q2C_ARQ_CLEANUP` | ABAP Class | Lógica do job (DT + RT) |
| 3 | `ZQ2C_ARQ_CLEANUP_CE` | Job Catalog Entry | Registra o job no framework APJ |
| 4 | `ZQ2C_ARQ_CLEANUP_JT` | Job Template | Template com parâmetros default para agendar |

---

## Passo 0 — Entrada na ZZ1_TVARVC_Q2C

Antes de qualquer objeto, inserir o parâmetro de retenção na tabela de variáveis customizáveis:

| Campo | Valor |
|-------|-------|
| NAME  | `ZZ_GAP014_ARQ_DIAS` |
| TYPE  | `P` |
| LOW   | `090` |

> Se a entrada não existir, a classe usa o fallback hard-coded de **90 dias**. Ajustar `LOW` para mudar a retenção sem reativar a classe.

---

## Passo 1 — Application Log Object

> O BALI log precisa de um objeto configurado. Se `ZQ2C_ARQ` já existir de outro job do projeto, apenas adicionar o subobject `CLEANUP`.

**Via ADT (BTP / S/4 Cloud):**
1. ADT → `Ctrl+N` → Other → **Manage Application Log Objects**
2. Ou abrir diretamente: ADT → menu *Window* → *Show View* → *Application Log Objects*

**Via SM59 / SBAL_OBJECT (on-premise):**
1. `SBAL_OBJECT` → *New*
2. Object: `ZQ2C_ARQ` — Description: `Q2C ARQ Manager`
3. Subobject: `CLEANUP` — Description: `Limpeza de registros cancelados`
4. Salvar e transportar

---

## Passo 2 — Classe ZCL_Q2C_ARQ_CLEANUP

1. ADT → `Ctrl+N` → **ABAP Class**
2. Nome: `ZCL_Q2C_ARQ_CLEANUP`
3. Pacote: `ZPQ2C_014`
4. Copiar conteúdo de `Job - Cleanup/ZCL_Q2C_ARQ_CLEANUP.clas.txt`
5. Ativar

**Interfaces obrigatórias (ambas no PUBLIC SECTION):**
```abap
INTERFACES if_apj_dt_exec_object.   " Design-time: tela de seleção
INTERFACES if_apj_rt_exec_object.   " Runtime:     lógica de execução
```

**Métodos implementados:**

| Método | Finalidade |
|--------|-----------|
| `IF_APJ_DT_EXEC_OBJECT~GET_PARAMETERS` | Define parâmetros da tela de seleção + valores default |
| `IF_APJ_RT_EXEC_OBJECT~EXECUTE` | Lógica de limpeza + BALI log |

**Parâmetros da tela de seleção:**

| SELNAME | Tipo | Descrição | Default |
|---------|------|-----------|---------|
| `P_DIAS` | NUMC(3) | Retenção em dias | Lido de `ZZ1_TVARVC_Q2C / ZZ_GAP014_ARQ_DIAS` (fallback 90) |
| `P_TESTE` | CHAR(1) checkbox | Modo Teste — sem delete real | ` ` |

---

## Passo 3 — Job Catalog Entry

> O Catalog Entry é o que **registra** o job no framework APJ e aponta para a classe.

1. ADT → `Ctrl+N` → Other → **Application Job Catalog Entry**
2. Preencher:
   - **Name:** `ZQ2C_ARQ_CLEANUP_CE`
   - **Description:** `Q2C - Limpeza ARQ Cancelados`
   - **Class:** `ZCL_Q2C_ARQ_CLEANUP`
3. Ativar e transportar

> Após ativar, o job já aparece disponível para agendamento — mas é mais cômodo criar um **Template** com os parâmetros pré-configurados.

---

## Passo 4 — Job Template

> O Template permite agendar o job com valores pre-defaults sem precisar preencher todo o formulário a cada vez.

1. ADT → `Ctrl+N` → Other → **Application Job Template**
2. Preencher:
   - **Name:** `ZQ2C_ARQ_CLEANUP_JT`
   - **Description:** `Q2C - Limpeza ARQ Cancelados (padrão 90 dias)`
   - **Catalog Entry:** `ZQ2C_ARQ_CLEANUP_CE`
3. Na aba de parâmetros: confirmar `P_DIAS = 090`, `P_TESTE = ' '`
4. Definir recorrência sugerida: **Semanal** (domingo de madrugada)
5. Ativar e transportar

---

## Passo 5 — Agendamento (Fiori)

**App Fiori:** *Application Jobs* (F4580) ou *Schedule Application Job*

1. Abrir app → *Create*
2. Selecionar template `ZQ2C_ARQ_CLEANUP_JT`
3. Ajustar `P_DIAS` se necessário (ex: 20 para ambiente teste)
4. Definir recorrência: Semanal / Mensal conforme política do cliente
5. Confirmar → *Schedule*

---

## Lógica de Execução

```
sy-datum - P_DIAS  →  lv_corte (data de corte)

Seleciona elegíveis:
  ZTBQ2C_ARQ_MGR WHERE STATUS = 'CANCELADO' AND DATUM <= lv_corte

Modo Teste:
  → Loga contagens (ARQ + LOG), nenhum DELETE é executado

Produção:
  1. SELECT chaves do LOG elegíveis (JOIN ARQ) → lt_log_keys
  2. DELETE ZTBQ2C_LOG_MGR FROM TABLE lt_log_keys   ← LOG primeiro
  3. DELETE FROM ZTBQ2C_ARQ_MGR WHERE ...           ← ARQ depois
  4. COMMIT WORK
  5. Loga: "Deletados ARQ X / LOG Y"
```

> **Ordem:** LOG antes de ARQ — preserva integridade referencial mesmo sem FK ativo no DB.

---

## Resultado no Application Jobs

Após execução, o log aparece no app **Application Jobs** com:
- Status `Completed` / `Completed with warnings` (modo teste)
- Link para o BALI log com detalhe de quantos registros foram deletados
- Histórico de execuções anteriores
