# sap-tech-lab

Repositório de objetos SAP S/4HANA para o projeto MGR — integração Q2C com CPI via RAP (Restful Application Programming Model).

---

## Estrutura do Repositório

```
CR51/          → Serviço CRUD admin (OData V4) para tabelas ARQ + LOG
CR51_APP/      → App Fiori de reprocessamento (actions Reprocess + Cancel)
```

---

## Tipos de Objeto — Como criar cada um no ADT

> Cada extensão de arquivo corresponde a um tipo diferente de objeto no ADT.  
> Abaixo o caminho exato de menu para criar cada um.

---

### `.ddls` — Data Definition (CDS View)
> Usado por: `ZI_Q2C_ARQ_MGR`, `ZI_Q2C_LOG_MGR`, `ZC_Q2C_ARQ_MGR`, `ZC_Q2C_LOG_MGR`, etc.

1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Na caixa de busca digitar: **`Data Definition`** → selecionar → `Next`
3. Preencher nome e descrição → `Next` → `Finish`
4. O ADT abre um editor com template. **Apagar tudo** e colar o conteúdo do arquivo `.ddls.txt`
5. `Ctrl+S` para salvar → `Ctrl+F3` para ativar

---

### `.bdef` — Behavior Definition
> Usado por: `ZI_Q2C_ARQ_MGR`, `ZC_Q2C_ARQ_MGR`, `ZC_Q2C_ARQ_MGR_APP`  
> ⚠️ **Objeto completamente separado do CDS** — não é criado clicando no CDS, é um objeto novo e independente.

1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Na caixa de busca digitar: **`Behavior Definition`** → selecionar → `Next`
3. Preencher nome (ex: `ZI_Q2C_ARQ_MGR`) e descrição → `Next` → `Finish`
4. **Apagar tudo** e colar o conteúdo do arquivo `.bdef.txt`
5. `Ctrl+S` → `Ctrl+F3`

> O BDEF tem o **mesmo nome** que o CDS raiz, mas são objetos distintos.  
> No Project Explorer aparecem separados: um com ícone de tabela (CDS) e outro com ícone de engrenagem (BDEF).

---

### `.clas` — ABAP Class
> Usado por: `ZBP_I_Q2C_ARQ_MGR`, `ZCL_Q2C_CPI_CALLER`, `ZCL_Q2C_REPROCESS_ACTION`

1. Botão direito no pacote → `New` → **`ABAP Class`** (atalho direto, sem precisar de "Other")
2. Preencher nome e descrição → `Next` → `Finish`
3. O ADT abre o editor com abas. Há **duas abas importantes**:
   - Aba **`Global Class`** → colar o conteúdo do arquivo `.clas.txt`
   - Aba **`Local Types`** → colar o conteúdo do arquivo `.clas.locals_imp.txt` (quando existir)
4. `Ctrl+S` → `Ctrl+F3`

---

### `.srvd` — Service Definition
> Usado por: `ZSD_Q2C_MGR`, `ZSD_Q2C_MGR_APP`

1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Na caixa de busca digitar: **`Service Definition`** → selecionar → `Next`
3. Preencher nome e descrição → `Next` → `Finish`
4. **Apagar tudo** e colar o conteúdo do arquivo `.srvd.txt`
5. `Ctrl+S` → `Ctrl+F3`

---

### `.srvb` — Service Binding
> Usado por: `ZSB_Q2C_MGR`, `ZSB_Q2C_MGR_APP`  
> ⚠️ **Não tem arquivo fonte** — criado e configurado 100% no ADT.

1. Botão direito no pacote → `New` → `Other ABAP Repository Object`
2. Na caixa de busca digitar: **`Service Binding`** → selecionar → `Next`
3. Preencher nome, descrição e **Binding Type: `OData V4 - UI`** → `Next` → `Finish`
4. No editor que abre: campo **`Service Definition`** → digitar o nome da Service Definition correspondente
5. Clicar no botão **`Publish`** (canto superior do editor)
6. Após publicar: clicar em **`Preview`** para abrir o Fiori e testar

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
| 3 | `CR51/ZI_Q2C_ARQ_MGR.ddls.txt` | `ZI_Q2C_ARQ_MGR` | Data Definition `.ddls` |
| 4 | `CR51/ZI_Q2C_LOG_MGR.ddls.txt` | `ZI_Q2C_LOG_MGR` | Data Definition `.ddls` |

> Como criar: ver seção **`.ddls` — Data Definition** acima.  
> Crie os dois, selecione ambos no Project Explorer e ative com `Ctrl+F3` juntos.

---

### FASE 3 — CDS Projection Views (par projeção CR51)

> Crie os dois, **selecione os dois juntos** e ative com `Ctrl+F3`.

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 5 | `CR51/ZC_Q2C_ARQ_MGR.ddls.txt` | `ZC_Q2C_ARQ_MGR` | Data Definition `.ddls` |
| 6 | `CR51/ZC_Q2C_LOG_MGR.ddls.txt` | `ZC_Q2C_LOG_MGR` | Data Definition `.ddls` |

> Como criar: ver seção **`.ddls` — Data Definition** acima.  
> Crie os dois, selecione ambos e ative com `Ctrl+F3` juntos.

---

### FASE 4 — Behavior Definition Interface (BDEF raiz)

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 7 | `CR51/ZI_Q2C_ARQ_MGR.bdef.txt` | `ZI_Q2C_ARQ_MGR` | Behavior Definition `.bdef` |

> ⚠️ Mesmo nome que o CDS (`ZI_Q2C_ARQ_MGR`), mas é um **objeto diferente**.  
> Como criar: ver seção **`.bdef` — Behavior Definition** acima.

---

### FASE 5 — Behavior Pool (classe global + CCIMP)

> O behavior pool é uma classe ABAP com include local. São **dois arquivos** mas **um único objeto** no ADT.

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 8 | `CR51/ZBP_I_Q2C_ARQ_MGR.clas.txt` | `ZBP_I_Q2C_ARQ_MGR` | ABAP Class `.clas` |
| 9 | `CR51/ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt` | aba **`Local Types`** da mesma classe | — |

> São **dois arquivos mas um único objeto** no ADT.  
> Como criar: ver seção **`.clas` — ABAP Class** acima.

---

### FASE 6 — Behavior Definition Projection (BDEF projeção CR51)

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 10 | `CR51/ZC_Q2C_ARQ_MGR.bdef.txt` | `ZC_Q2C_ARQ_MGR` | Behavior Definition `.bdef` |

> ⚠️ Mesmo nome que o CDS de projeção (`ZC_Q2C_ARQ_MGR`), mas objeto separado.  
> Como criar: ver seção **`.bdef` — Behavior Definition** acima.

---

### FASE 7 — Service Definition CR51

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 11 | `CR51/ZSD_Q2C_MGR.srvd.txt` | `ZSD_Q2C_MGR` | Service Definition `.srvd` |

> Como criar: ver seção **`.srvd` — Service Definition** acima.

---

### FASE 8 — Service Binding CR51

> Não tem arquivo fonte — criado e publicado 100% no ADT.

| # | Objeto ADT a criar | Tipo ADT |
|---|---|---|
| 12 | `ZSB_Q2C_MGR` | Service Binding `.srvb` |

> Como criar: ver seção **`.srvb` — Service Binding** acima.  
> Service Definition a informar: **`ZSD_Q2C_MGR`**

---

## CR51_APP — Guia de Implementação no Eclipse (ADT)

> Os objetos da CR51_APP **dependem** de CR51 (ZI_* e ZBP_I_Q2C_ARQ_MGR) já ativos.  
> Implemente CR51 completamente antes de iniciar esta fase.

---

### FASE 9 — Classes ABAP de Integração CPI

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 13 | `CR51_APP/ZCL_Q2C_CPI_CALLER.clas.txt` | `ZCL_Q2C_CPI_CALLER` | ABAP Class `.clas` |
| 14 | `CR51_APP/ZCL_Q2C_REPROCESS_ACTION.clas.txt` | `ZCL_Q2C_REPROCESS_ACTION` | ABAP Class `.clas` |

> Como criar: ver seção **`.clas` — ABAP Class** acima.  
> Ative `ZCL_Q2C_CPI_CALLER` **primeiro** — `ZCL_Q2C_REPROCESS_ACTION` depende dela.

---

### FASE 10 — CDS Projection Views APP

> Crie os dois, **selecione os dois juntos** e ative com `Ctrl+F3`.

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 15 | `CR51_APP/ZC_Q2C_ARQ_MGR_APP.ddls.txt` | `ZC_Q2C_ARQ_MGR_APP` | Data Definition `.ddls` |
| 16 | `CR51_APP/ZC_Q2C_LOG_MGR_APP.ddls.txt` | `ZC_Q2C_LOG_MGR_APP` | Data Definition `.ddls` |

> Como criar: ver seção **`.ddls` — Data Definition** acima.  
> Crie os dois, selecione ambos e ative com `Ctrl+F3` juntos.

---

### FASE 11 — Behavior Definition Projection APP

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 17 | `CR51_APP/ZC_Q2C_ARQ_MGR_APP.bdef.txt` | `ZC_Q2C_ARQ_MGR_APP` | Behavior Definition `.bdef` |

> ⚠️ Mesmo nome que o CDS (`ZC_Q2C_ARQ_MGR_APP`), mas objeto separado.  
> Como criar: ver seção **`.bdef` — Behavior Definition** acima.  
> Não há behavior pool separado para APP — as actions `Reprocess` e `Cancel` são implementadas em `ZBP_I_Q2C_ARQ_MGR` (CR51), compartilhado.

---

### FASE 12 — Service Definition APP

| # | Arquivo fonte | Objeto ADT a criar | Tipo ADT |
|---|---------------|--------------------|----------|
| 18 | `CR51_APP/ZSD_Q2C_MGR_APP.srvd.txt` | `ZSD_Q2C_MGR_APP` | Service Definition `.srvd` |

> Como criar: ver seção **`.srvd` — Service Definition** acima.

---

### FASE 13 — Service Binding APP

> Não tem arquivo fonte — criado e publicado 100% no ADT.

| # | Objeto ADT a criar | Tipo ADT |
|---|---|---|
| 19 | `ZSB_Q2C_MGR_APP` | Service Binding `.srvb` |

> Como criar: ver seção **`.srvb` — Service Binding** acima.  
> Service Definition a informar: **`ZSD_Q2C_MGR_APP`**

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
