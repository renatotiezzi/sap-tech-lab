# ATC Guide — Monitor MDF-e
## Transport: `GHDK9A0JVA` | Data: 2026-05-13

---

## PARTE 1 — Objetos que precisam de redeploy (copiar e colar no ADT)

Dois arquivos foram alterados pelo refactoring ATC. Os outros objetos (**ZMDFE_STATUS**, **ZMDFE_NFKEYS**) **não foram alterados** e não precisam ser reaplicados.

---

### Objeto 1 — `ZCL_MDFE_MONITOR` (Classe ABAP)

**Arquivo:** `ZCL_MDFE_MONITOR.txt`  
**O que mudou:**
- 18 constantes `gc_*` renomeadas para `mc_*`
- 5 tipos `ty_*`/`tt_*` renomeados para `mty_*`/`mtty_*` (e cascata em todos os métodos)
- Variável de exceção `lx` → `lx_err` no CATCH de `send_mdfe`
- `REGEX` POSIX obsoleto → `PCRE` (2 ocorrências no método `build_json_payload`)
- `WRITE brgew` → adicionado `UNIT is_header-gewei` (fix SLIN UNIT)
- `WRITE nftot` → variável intermediária `TYPE P DECIMALS 2` (fix SLIN CURR)

**Como reaplicar no ADT:**
1. SE24 → classe `ZCL_MDFE_MONITOR` → **Change**
2. Abrir o arquivo `ZCL_MDFE_MONITOR.txt` deste repositório
3. Copiar **todo o conteúdo** → substituir o fonte no ADT
4. **Check → Activate** → resolver erros de sintaxe se houver
5. Confirmar que a classe fica no TR `GHDK9A0JVA`

---

### Objeto 2 — `ZRMM_MONITOR_MDFE` (Report ABAP)

**Arquivo:** `ZRMM_MONITOR_MDFE.txt`  
**O que mudou:**
- Todas as referências `zcl_mdfe_monitor=>gc_fc_*` atualizadas para `mc_fc_*`
- Todos os tipos `zcl_mdfe_monitor=>ty_*`/`tt_*` atualizados para `mty_*`/`mtty_*`
- `FORM action_mass USING iv_action` → `pv_action` (fix FORM parameter naming)
- Dentro do `MODULE user_command_0200`:
  - `DATA lt_msg` → `DATA gt_msg_200` (global naming)
  - `DATA lt_sel` → `DATA gt_sel_200` (global naming)
  - `DATA(ls_sel)` → `DATA(gs_sel_200)` (global naming)
  - `DATA(lv_next)` → `DATA(gv_next)` (global naming)
  - `DATA(lv_key)` → `DATA(gv_key)` (global naming)

**Como reaplicar no ADT:**
1. SE38 → programa `ZRMM_MONITOR_MDFE` → **Change**
2. Abrir o arquivo `ZRMM_MONITOR_MDFE.txt` deste repositório
3. Copiar **todo o conteúdo** → substituir o fonte no ADT
4. **Check → Activate**
5. Confirmar que o programa fica no TR `GHDK9A0JVA`

> ⚠️ **Atenção:** Ativar `ZCL_MDFE_MONITOR` **antes** de `ZRMM_MONITOR_MDFE`. O report depende da classe.

---

## PARTE 2 — Ações manuais obrigatórias no SAP (não são código)

Estas ações **não podem ser feitas via arquivo** — precisam ser feitas diretamente no SAP após o redeploy do código acima.

---

### Ação 1 — Criar GUI Statuses (SE41) — Prio 2 — BLOQUEANTE para release

O report usa `SET PF-STATUS` para 4 statuses que precisam existir no Menu Painter.

**Tcode:** `SE41` → Program: `ZRMM_MONITOR_MDFE` → Type: **GUI Status** → digitar nome → **Create**

#### STATUS_100 (Tela 100 — Monitor ALV)

| Function Code | Texto do botão | Tecla | Posição |
|---|---|---|---|
| `BACK` | Voltar | F3 | Standard toolbar |
| `EXIT` | Sair | Shift+F3 | Standard toolbar |
| `CANCEL` | Cancelar | F12 | Standard toolbar |
| `EXECUTE` | Executar | F8 | Application toolbar |
| `CRIAR` | Criar MDF-e | — | Application toolbar |
| `ENVIAR` | Enviar | — | Application toolbar |
| `CONSULTAR` | Consultar | — | Application toolbar |
| `ENCERRAR` | Encerrar | — | Application toolbar |
| `CANCELAR` | Cancelar MDF-e | — | Application toolbar |
| `IMPRIMIR` | Imprimir | — | Application toolbar |
| `ATUALIZAR` | Atualizar | F5 | Application toolbar |

#### STATUS_200_CRE (Tela 200 — Criar MDF-e)

| Function Code | Texto | Tecla |
|---|---|---|
| `BACK` | Voltar | F3 |
| `CANCEL` | Cancelar | F12 |
| `SALVAR` | Salvar e Enviar | F11 |
| `ADD_NF` | Adicionar NF-e | — |
| `DEL_NF` | Remover NF-e | — |

#### STATUS_200_EDT (Tela 200 — Editar MDF-e)

Mesmos function codes que `STATUS_200_CRE`.

#### STATUS_200_DSP (Tela 200 — Exibir MDF-e)

| Function Code | Texto | Tecla |
|---|---|---|
| `BACK` | Voltar | F3 |
| `CANCEL` | Cancelar | F12 |

**Após criar cada status:** botão **Activate** → gravar no TR `GHDK9A0JVA`.

> ⚠️ Os Function Codes devem coincidir **exatamente** (maiúsculas, sem espaço) com os `VALUE` das constantes `mc_fc_*` da classe. Qualquer diferença = botão não funciona.

---

### Ação 2 — Criar GUI Titles (SE41) — Prio 2 — BLOQUEANTE para release

**Tcode:** `SE41` → Program: `ZRMM_MONITOR_MDFE` → Type: **GUI Title** → digitar nome → **Create**

| Nome do Title | Texto |
|---|---|
| `TITLE_100` | Monitor MDF-e |
| `TITLE_200_CRE` | Criar MDF-e |
| `TITLE_200_EDT` | Editar MDF-e |
| `TITLE_200_DSP` | Exibir MDF-e |

**Após criar cada título:** Salvar → Activate → TR `GHDK9A0JVA`.

---

### Ação 3 — Criar Text Elements (SE38) — Prio 3 — não bloqueante

Os blocos da Selection Screen mostram texto em branco sem esses símbolos.

**Tcode:** `SE38` → `ZRMM_MONITOR_MDFE` → **Change** → menu `Goto → Text Elements → Text Symbols`

| Símbolo | Texto |
|---|---|
| `B01` | Dados da Nota Fiscal |
| `B02` | Dados do MDF-e |
| `B03` | Filtro de Status |

Salvar → Activate.

---

### Ação 4 — Criar exceções ATC para itens não acionáveis — Prio 2/3

Alguns itens do ATC **não podem nem devem ser corrigidos**. Para cada um, criar uma exceção:

**Como criar exceção ATC:**
`Tcode ATC` → resultado da última execução → selecionar o item → botão **Request Exception** → preencher justificativa → **Save**

| Objeto | Violação | Justificativa para a exceção |
|---|---|---|
| `J_1BNFE_MONITOR` | `DATA/STATICS (local)` naming | SAP standard program — naming convention not applicable |
| `J_1BNFE_MONITOR` | `TYPES (local)` naming | SAP standard program — naming convention not applicable |
| `ZCL_MDFE_MONITOR` | Text element missing (strings de validação, ~18 ocorrências prio 3) | Validation messages in PT-BR — no translation requirement for this delivery |
| `ZCL_NFSE_LAYOUT_CPI` | CONSTANTS / TYPES naming (7 ocorrências) | Out of scope — belongs to NFSE project, different TR |

---

## PARTE 3 — Sequência de execução completa

```
1. ADT: ativar ZCL_MDFE_MONITOR   ← colar conteúdo de ZCL_MDFE_MONITOR.txt
2. ADT: ativar ZRMM_MONITOR_MDFE  ← colar conteúdo de ZRMM_MONITOR_MDFE.txt
3. SE41: criar STATUS_100          ← Ação 1
4. SE41: criar STATUS_200_CRE      ← Ação 1
5. SE41: criar STATUS_200_EDT      ← Ação 1
6. SE41: criar STATUS_200_DSP      ← Ação 1
7. SE41: criar TITLE_100           ← Ação 2
8. SE41: criar TITLE_200_CRE       ← Ação 2
9. SE41: criar TITLE_200_EDT       ← Ação 2
10. SE41: criar TITLE_200_DSP      ← Ação 2
11. SE38: criar text symbols B01/B02/B03 ← Ação 3
12. ATC: criar exceções para J_1BNFE_MONITOR e ZCL_NFSE_LAYOUT_CPI ← Ação 4
13. ATC: re-executar check no TR GHDK9A0JVA → confirmar Critical Errors = 0
14. SE01: release do TR GHDK9A0JVA
```

---

## Checklist de Release

- [ ] `ZCL_MDFE_MONITOR` ativado sem erros de sintaxe no ADT
- [ ] `ZRMM_MONITOR_MDFE` ativado sem erros de sintaxe no ADT
- [ ] 4 GUI Statuses criados e ativos no SE41
- [ ] 4 GUI Titles criados e ativos no SE41
- [ ] Text symbols B01/B02/B03 criados no SE38
- [ ] Exceções ATC criadas para `J_1BNFE_MONITOR` e `ZCL_NFSE_LAYOUT_CPI`
- [ ] ATC re-executado → **Critical Errors = 0** para objetos do TR
- [ ] TR `GHDK9A0JVA` liberado (SE01)

**Mensagem ATC:** `GUI status not defined`

Os módulos `STATUS_0100` e `STATUS_0200` referenciam GUI statuses via `SET PF-STATUS` que precisam ser criados no **Menu Painter (SE41)**.

| Status referenciado no código | Tela |
|---|---|
| `STATUS_100`      | Tela 100 – Monitor ALV |
| `STATUS_200_CRE`  | Tela 200 – Criar MDF-e |
| `STATUS_200_EDT`  | Tela 200 – Editar MDF-e |
| `STATUS_200_DSP`  | Tela 200 – Exibir MDF-e |

**Como criar:**
1. `SE41` → Program `ZRMM_MONITOR_MDFE` → GUI Status → nome exato → **Create**
2. Para `STATUS_100`: adicionar as function codes abaixo na toolbar:

| Function Code | Tipo | Texto Sugerido |
|---|---|---|
| `CRIAR`      | Push Button | Criar MDF-e |
| `ENVIAR`     | Push Button | Enviar |
| `CONSULTAR`  | Push Button | Consultar |
| `ENCERRAR`   | Push Button | Encerrar |
| `CANCELAR`   | Push Button | Cancelar |
| `IMPRIMIR`   | Push Button | Imprimir |
| `ATUALIZAR`  | Push Button | Atualizar |
| `BACK`       | Padrão SAP  | Voltar |
| `EXIT`       | Padrão SAP  | Sair |
| `CANCEL`     | Padrão SAP  | Cancelar |
| `EXECUTE`    | Push Button | Executar |

3. Para `STATUS_200_CRE / EDT / DSP`: adicionar `SALVAR`, `ADD_NF`, `DEL_NF`, `BACK`, `CANCEL`
4. Ativar cada GUI Status → **Save**

---

## 2. TITLE não definido — `ZRMM_MONITOR_MDFE` (4 erros, prio 2)

**Mensagem ATC:** `TITLE not defined`

Os módulos usam `SET TITLEBAR` com os seguintes títulos:

| TITLE referenciado | Sugestão de texto |
|---|---|
| `TITLE_100`      | Monitor MDF-e |
| `TITLE_200_CRE`  | Criar MDF-e |
| `TITLE_200_EDT`  | Editar MDF-e |
| `TITLE_200_DSP`  | Exibir MDF-e |

**Como criar:**
1. `SE41` → Program `ZRMM_MONITOR_MDFE` → **GUI Title** → nome exato → Create
2. Preencher o campo de texto
3. Ativar → Save

---

## 3. Text elements ausentes (prio 3 — SLIN)

**Mensagem ATC:** `Text element missing in a character string` / `Text element not defined in TEXT-POOL`

### 3a. Selection screen blocks — `ZRMM_MONITOR_MDFE`

Os blocos de seleção referenciam `TEXT-b01`, `TEXT-b02`, `TEXT-b03`:

```abap
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-b03.
```

**Como criar:**
1. `SE38` → Programa `ZRMM_MONITOR_MDFE` → `Goto → Text Elements → Selection Texts`
2. Ou via menu `Goto → Text Elements → Text Symbols`
3. Criar os símbolos:

| Símbolo | Texto sugerido |
|---|---|
| b01 | Dados da Nota Fiscal |
| b02 | Dados do MDF-e |
| b03 | Filtro de Status |

### 3b. Mensagens de string template / character strings — `ZCL_MDFE_MONITOR` e `ZRMM_MONITOR_MDFE`

Strings hardcoded como `'Empresa é obrigatória'`, `'Placa do veículo é obrigatória'`, etc. geram SLIN warning porque não usam `TEXT-xyz` ou classe de mensagens.

**Decisão:** Para prio 3 (SLIN warning), é aceitável manter como está se o cliente aprova. Alternativa correta: migrar para uma **Classe de Mensagens Z** (SE91 → criar `ZMDFE_MSG`) e referenciar com `MESSAGE e001(ZMDFE_MSG)`.

> ⚠️ **Recomendação**: Criar a classe de mensagens é boa prática, mas gera refatoração adicional. Avaliar com o cliente se é necessário para esta entrega.

---

## 4. DATA (global) — 5 violações em `ZRMM_MONITOR_MDFE` (prio 2)

**Mensagem ATC:** `Invalid name ... for DATA (global)`

Estas 5 variáveis não foram identificadas automaticamente no arquivo local. **No SAP, abrir o resultado ATC** e clicar em cada violação para ver o nome exato.

**Como investigar no SAP:**
1. `SE80` → Programa `ZRMM_MONITOR_MDFE` → `ATC → Run Check`
2. Clicar em cada "DATA (global)" → ver o campo **"Used name"** no detalhe
3. Renomear seguindo o padrão: `GT_*` (tables), `GV_*` (value), `GS_*` (structure), `GO_*` (object ref), `GR_*` (reference)

**Suspeita mais provável:** as 5 variáveis globais `go_*` (TYPE REF TO) podem precisar de prefixo `gr_*` dependendo do check variant. Verificar os padrões válidos na mensagem de detalhe.

---

## 5. CURR field sem CURRENCY addition — `ZCL_MDFE_MONITOR` (prio 3)

**Mensagem ATC:** `CURR field produced without CURRENCY Addition`

No método `build_json_payload`:
```abap
WRITE is_header-nftot TO lv_valor NO-GROUPING LEFT-JUSTIFIED.
```

`nftot` é campo de moeda. **Fix sugerido** (confirmar campo `waers` em `ZMDFE_STATUS`):
```abap
WRITE is_header-nftot TO lv_valor NO-GROUPING LEFT-JUSTIFIED CURRENCY is_header-waers.
```
Se `ZMDFE_STATUS` não tiver campo `waers`, adicionar e ajustar a lógica de persistência.

---

## 6. UNIT field sem UNIT addition — `ZCL_MDFE_MONITOR` (prio 3)

**Mensagem ATC:** `UNIT field produced without UNIT addition`

No método `build_json_payload`:
```abap
WRITE is_header-brgew TO lv_peso  NO-GROUPING LEFT-JUSTIFIED.
```

`brgew` é campo de quantidade (peso). **Fix sugerido** (confirmar campo `gewei` em `ZMDFE_STATUS`):
```abap
WRITE is_header-brgew TO lv_peso NO-GROUPING LEFT-JUSTIFIED UNIT is_header-gewei.
```

> Para ambos (5 e 6): confirmar em `SE11 → ZMDFE_STATUS` se os campos `waers` e `gewei` existem. Se não, adicionar à tabela antes de aplicar o fix.

---

## 7. Objetos SAP Standard — não modificar

Os seguintes objetos aparecem no ATC mas **pertencem ao namespace SAP** e não devem ser modificados:

| Objeto | Tipo | Motivo |
|---|---|---|
| `J_1BNFE_MONITOR` | PROG | SAP Standard (J1BNFE) |

As violações de `DATA/STATICS (local)` e `TYPES (local)` nesse programa são responsabilidade SAP.

---

## 8. `ZCL_NFSE_LAYOUT_CPI` — não pertence ao Monitor MDF-e

Este objeto apareceu no ATC do mesmo transport request mas é de outro projeto (NFSE). As violações de CONSTANTS e TYPES nessa classe devem ser tratadas separadamente no contexto do projeto NFS-e.

---

## Resumo de Prioridades

| # | Prio | Objeto | Ação | Onde |
|---|---|---|---|---|
| 1 | 2 | ZRMM | Criar GUI Status (4 statuses) | SE41 |
| 2 | 2 | ZRMM | Criar GUI Title (4 títulos) | SE41 |
| 3 | 2 | ZRMM | Identificar e renomear 5 DATA (global) | SAP ATC detail |
| 4 | 3 | ZRMM | Criar text elements b01/b02/b03 | SE38 |
| 5 | 3 | ZCL + ZRMM | Criar classe de mensagens Z (opcional) | SE91 |
| 6 | 3 | ZCL | Fix WRITE CURRENCY (nftot) | Código |
| 7 | 3 | ZCL | Fix WRITE UNIT (brgew) | Código |
