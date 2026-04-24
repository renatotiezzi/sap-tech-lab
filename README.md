# sap-tech-lab

Repositório de objetos SAP S/4HANA para o projeto MGR — integração Q2C com CPI via RAP (Restful Application Programming Model).

---

## Estrutura do Repositório

```
CR51/          → Serviço CRUD admin (OData V4) para tabelas ARQ + LOG
CR51_APP/      → App Fiori de reprocessamento (actions Reprocess + Cancel)
```

---

## CR51 — Guia de Implementação no Eclipse (ADT)

> **Regra geral RAP:** ative sempre em pares (interface + filho juntos).  
> Nunca ative um CDS filho sem o pai já ativo, e nunca ative um BDEF sem o CDS correspondente já ativo.

---

### FASE 1 — Tabelas de Banco (SE11 ou ADT)

Certifique-se de que as tabelas já existem e estão ativas antes de qualquer objeto RAP.

| # | Objeto | Tipo | Ação |
|---|--------|------|------|
| 1 | `ZTBQ2C_ARQ_MGR` | Database Table | Verificar/Ativar |
| 2 | `ZTBQ2C_LOG_MGR` | Database Table | Verificar/Ativar |

---

### FASE 2 — CDS Interface Views (par interface)

> Crie os dois, **selecione os dois juntos** no Project Explorer e ative com `Ctrl+F3`.

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 3 | `CR51/ZI_Q2C_ARQ_MGR.ddls.txt` | `ZI_Q2C_ARQ_MGR` | Data Definition (Core Data Services) |
| 4 | `CR51/ZI_Q2C_LOG_MGR.ddls.txt` | `ZI_Q2C_LOG_MGR` | Data Definition (Core Data Services) |

**Como criar cada CDS no ADT:**
1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Filtrar por `Data Definition` → `Next`
3. Informar o nome (ex: `ZI_Q2C_ARQ_MGR`) e descrição → `Next` → `Finish`
4. Substituir o conteúdo pelo do arquivo `.ddls.txt` correspondente
5. Repetir para o segundo CDS
6. **Selecionar os dois** → `Ctrl+F3` (ativar ambos juntos)

---

### FASE 3 — CDS Projection Views (par projeção CR51)

> Crie os dois, **selecione os dois juntos** e ative com `Ctrl+F3`.

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 5 | `CR51/ZC_Q2C_ARQ_MGR.ddls.txt` | `ZC_Q2C_ARQ_MGR` | Data Definition (Core Data Services) |
| 6 | `CR51/ZC_Q2C_LOG_MGR.ddls.txt` | `ZC_Q2C_LOG_MGR` | Data Definition (Core Data Services) |

---

### FASE 4 — Behavior Definition Interface (BDEF raiz)

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 7 | `CR51/ZI_Q2C_ARQ_MGR.bdef.txt` | `ZI_Q2C_ARQ_MGR` | Behavior Definition |

**Como criar BDEF no ADT:**
1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Filtrar por `Behavior Definition` → `Next`
3. Informar o nome `ZI_Q2C_ARQ_MGR` → `Next` → `Finish`
4. Substituir o conteúdo pelo do arquivo `.bdef.txt`
5. `Ctrl+F3` para ativar

---

### FASE 5 — Behavior Pool (classe global + CCIMP)

> O behavior pool é uma classe ABAP com include local. São **dois arquivos** mas **um único objeto** no ADT.

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 8 | `CR51/ZBP_I_Q2C_ARQ_MGR.clas.txt` | `ZBP_I_Q2C_ARQ_MGR` | ABAP Class |
| 9 | `CR51/ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt` | include `CCIMP` da mesma classe | — |

**Como criar a classe no ADT:**
1. Botão direito no pacote → `New` → `ABAP Class`
2. Nome: `ZBP_I_Q2C_ARQ_MGR` → `Next` → `Finish`
3. Na aba `Global Class`: substituir pelo conteúdo de `ZBP_I_Q2C_ARQ_MGR.clas.txt`
4. Na aba `Local Types` (CCIMP): substituir pelo conteúdo de `ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt`
5. `Ctrl+F3` para ativar

---

### FASE 6 — Behavior Definition Projection (BDEF projeção CR51)

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 10 | `CR51/ZC_Q2C_ARQ_MGR.bdef.txt` | `ZC_Q2C_ARQ_MGR` | Behavior Definition |

---

### FASE 7 — Service Definition CR51

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 11 | `CR51/ZSD_Q2C_MGR.srvd.txt` | `ZSD_Q2C_MGR` | Service Definition |

**Como criar Service Definition no ADT:**
1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Filtrar por `Service Definition` → `Next`
3. Nome: `ZSD_Q2C_MGR` → `Next` → `Finish`
4. Substituir conteúdo pelo do arquivo `.srvd.txt`
5. `Ctrl+F3` para ativar

---

### FASE 8 — Service Binding CR51 (criado manualmente no ADT)

> O Service Binding **não tem arquivo fonte** — deve ser criado diretamente no ADT.

| # | Objeto ADT a criar | Tipo ADT |
|---|---|---|
| 12 | `ZSB_Q2C_MGR` | Service Binding |

**Como criar Service Binding no ADT:**
1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Filtrar por `Service Binding` → `Next`
3. Nome: `ZSB_Q2C_MGR`, Binding Type: `OData V4 - UI` → `Next` → `Finish`
4. Na tela do binding: campo `Service Definition` → digitar `ZSD_Q2C_MGR`
5. Clicar em **`Publish`** (botão no topo do editor)
6. Após publish: clicar em **`Preview`** para abrir o Fiori Launchpad e testar

---

## CR51_APP — Guia de Implementação no Eclipse (ADT)

> Os objetos da CR51_APP **dependem** de CR51 (ZI_* e ZBP_I_Q2C_ARQ_MGR) já ativos.  
> Implemente CR51 completamente antes de iniciar esta fase.

---

### FASE 9 — Classes ABAP de Integração CPI

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 13 | `CR51_APP/ZCL_Q2C_CPI_CALLER.clas.txt` | `ZCL_Q2C_CPI_CALLER` | ABAP Class |
| 14 | `CR51_APP/ZCL_Q2C_REPROCESS_ACTION.clas.txt` | `ZCL_Q2C_REPROCESS_ACTION` | ABAP Class |

> Ative `ZCL_Q2C_CPI_CALLER` **primeiro** pois `ZCL_Q2C_REPROCESS_ACTION` depende dela.

---

### FASE 10 — CDS Projection Views APP

> Crie os dois, **selecione os dois juntos** e ative com `Ctrl+F3`.

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 15 | `CR51_APP/ZC_Q2C_ARQ_MGR_APP.ddls.txt` | `ZC_Q2C_ARQ_MGR_APP` | Data Definition |
| 16 | `CR51_APP/ZC_Q2C_LOG_MGR_APP.ddls.txt` | `ZC_Q2C_LOG_MGR_APP` | Data Definition |

---

### FASE 11 — Behavior Definition Projection APP

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 17 | `CR51_APP/ZC_Q2C_ARQ_MGR_APP.bdef.txt` | `ZC_Q2C_ARQ_MGR_APP` | Behavior Definition |

> Não há behavior pool separado para APP — as actions `Reprocess` e `Cancel` são implementadas em `ZBP_I_Q2C_ARQ_MGR` (CR51), compartilhado entre os dois serviços.

---

### FASE 12 — Service Definition APP

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 18 | `CR51_APP/ZSD_Q2C_MGR_APP.srvd.txt` | `ZSD_Q2C_MGR_APP` | Service Definition |

---

### FASE 13 — Service Binding APP (criado manualmente no ADT)

| # | Objeto ADT a criar | Tipo ADT |
|---|---|---|
| 19 | `ZSB_Q2C_MGR_APP` | Service Binding |

**Como criar:**
1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Filtrar por `Service Binding` → `Next`
3. Nome: `ZSB_Q2C_MGR_APP`, Binding Type: `OData V4 - UI` → `Next` → `Finish`
4. Service Definition: `ZSD_Q2C_MGR_APP`
5. Clicar em **`Publish`**
6. Clicar em **`Preview`** para testar o App de Reprocessamento

---

## Ordem de Ativação Resumida

```
ZTBQ2C_ARQ_MGR  ──┐
                   ├─► ZI_Q2C_ARQ_MGR ──┐
ZTBQ2C_LOG_MGR  ──┘      +              ├─► ZC_Q2C_ARQ_MGR ──┐
                   ZI_Q2C_LOG_MGR ──────┘      +              │
                          │              ZC_Q2C_LOG_MGR ───────┤
                          │                                    │
                          ▼                                    ▼
                  ZI_Q2C_ARQ_MGR.bdef          ZC_Q2C_ARQ_MGR.bdef
                          │
                          ▼
                  ZBP_I_Q2C_ARQ_MGR (global class + CCIMP)
                          │
                          ▼
                    ZSD_Q2C_MGR  ──►  ZSB_Q2C_MGR (Publish!)


            [após tudo acima ativo]

ZCL_Q2C_CPI_CALLER  ──►  ZCL_Q2C_REPROCESS_ACTION
          │
          ▼
ZC_Q2C_ARQ_MGR_APP ──┐
          +           ├─► ZC_Q2C_ARQ_MGR_APP.bdef ──► ZSD_Q2C_MGR_APP ──► ZSB_Q2C_MGR_APP (Publish!)
ZC_Q2C_LOG_MGR_APP ──┘
```

---

## Observações Importantes

- **`strict(2)` obrigatório:** todos os BDEFs usam `strict(2)`. Campos sem `%control = mk-on` não são persistidos.
- **Sem draft:** nenhum dos objetos usa draft. Todas as mudanças são síncronas.
- **LOG é 1:1 com ARQ:** mesma chave `PEDIDO + BANDEIRA`. Cada reprocessamento **sobrescreve** o LOG anterior (upsert).
- **Actions implementadas em CR51:** `Reprocess` e `Cancel` estão no handler `ZBP_I_Q2C_ARQ_MGR`. O APP apenas as expõe via `use action`.
- **`ZCL_Q2C_REPROCESS_ACTION`** é para uso **fora do RAP** (jobs, programas clássicos). Dentro do RAP, o handler chama `ZCL_Q2C_CPI_CALLER` diretamente.
