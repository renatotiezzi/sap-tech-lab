# ATC Implementation Guide — Monitor MDF-e
## Eliminação dos pontos restantes após o ATC (TC: GHDK9A0JVA)

**Data:** 2026-05-11  
**Objetos no TR:** `ZRMM_MONITOR_MDFE` (PROG) + `ZCL_MDFE_MONITOR` (CLAS)

---

## Resumo: O que foi refatorado no código (Git)

| # | Problema | Objeto | Correção aplicada |
|---|----------|--------|-------------------|
| 1 | `CONSTANTS` com prefixo `gc_` em class global | `ZCL_MDFE_MONITOR` | Renomeados para `mc_*` (18 constantes + todas as referências) |
| 2 | `TYPES` com prefixo `ty_` / `tt_` em class global | `ZCL_MDFE_MONITOR` | `ty_*` → `mty_*`, `tt_*` → `mtty_*` (5 tipos + cascata) |
| 3 | `DATA/STATICS (local)` — variável `lx` nua | `ZCL_MDFE_MONITOR` | `lx` → `lx_err` no bloco CATCH de `send_mdfe` |
| 4 | `USING parameter (FORM)` — `iv_action`, `it_msg` | `ZRMM_MONITOR_MDFE` | `iv_action` → `pv_action`, `it_msg` → `pt_msg` |
| 5 | `DATA (global)` em MODULE — `lt_*` / `ls_*` / `lv_*` | `ZRMM_MONITOR_MDFE` | `lt_msg` → `gt_msg_200`, `lt_sel` → `gt_sel_200`, `ls_sel` → `gs_sel_200`, `lv_next` → `gv_next`, `lv_key` → `gv_key` |
| 6 | REGEX POSIX obsoleto | `ZCL_MDFE_MONITOR` | `REGEX '[^0-9]'` → `PCRE '[^0-9]'` (2 ocorrências) |
| 7 | `CURR field without CURRENCY addition` | `ZCL_MDFE_MONITOR` | Campo `nftot` convertido para `TYPE P DECIMALS 2` antes do `WRITE` |
| 8 | `UNIT field without UNIT addition` | `ZCL_MDFE_MONITOR` | `WRITE ... UNIT is_header-gewei` adicionado para `brgew` |
| 9 | Referências de tipo e constante desatualizadas | `ZRMM_MONITOR_MDFE` | Cascata atualizada: `zcl_mdfe_monitor=>mc_*`, `mty_*`, `mtty_*` |

---

## O que DEVE ser feito manualmente no SAP (não é código)

### 1. GUI Status — SE41 (3 erros SLIN "GUI status not defined")

Os módulos de status referenciados no report precisam ser criados manualmente no **Menu Painter (SE41)**.

**Como fazer:**
1. Tcode `SE41` → Program: `ZRMM_MONITOR_MDFE` → Enter  
2. Para cada status abaixo: digitar o nome → **Create** → configurar botões → **Save + Activate**

#### STATUS_100 — Monitor ALV (Tela 100)

| Código de função | Texto | Tecla | Tipo |
|-----------------|-------|-------|------|
| `BACK` | Voltar | F3 | E |
| `EXIT` | Sair | Shift+F3 | E |
| `CANCEL` | Cancelar | F12 | E |
| `EXECUTE` | Executar (F8) | F8 | F |
| `CRIAR` | Criar MDF-e | — | F |
| `ENVIAR` | Enviar | — | F |
| `CONSULTAR` | Consultar Status | — | F |
| `ENCERRAR` | Encerrar | — | F |
| `CANCELAR` | Cancelar MDF-e | — | F |
| `IMPRIMIR` | Imprimir | — | F |
| `ATUALIZAR` | Atualizar | F5 | F |

> **Atenção:** Os códigos de função devem coincidir EXATAMENTE com os `VALUE` das constantes `mc_fc_*` na classe.

#### STATUS_200_CRE — Detalhe modo Criar

| Código de função | Texto | Tecla |
|-----------------|-------|-------|
| `BACK` | Voltar | F3 |
| `CANCEL` | Cancelar | F12 |
| `SALVAR` | Salvar e Enviar | F11 |
| `ADD_NF` | Adicionar NF-e | — |
| `DEL_NF` | Remover NF-e | — |

#### STATUS_200_EDT — Detalhe modo Editar

Mesmos botões que `STATUS_200_CRE`.

#### STATUS_200_DSP — Detalhe modo Display

| Código de função | Texto | Tecla |
|-----------------|-------|-------|
| `BACK` | Voltar | F3 |
| `CANCEL` | Cancelar | F12 |

---

### 2. Titlebars — SE41 (4 erros SLIN "TITLE not defined")

Na mesma tela SE41, aba **Title Bar**:

1. Tcode `SE41` → Program: `ZRMM_MONITOR_MDFE` → **Title Bar** → **Change**  
2. Criar cada entry abaixo:

| Nome | Texto sugerido |
|------|----------------|
| `TITLE_100` | Monitor MDF-e |
| `TITLE_200_CRE` | Criar MDF-e |
| `TITLE_200_EDT` | Editar MDF-e |
| `TITLE_200_DSP` | Visualizar MDF-e |

3. **Save + Activate** tudo.

---

### 3. Text Elements do Report — SE38 (3 erros "Text element not defined in TEXT-POOL" + ~20 "missing in character string")

Os blocos da Selection Screen usam `TEXT-bxx` para os títulos dos frames. Também há mensagens inline no report que SLIN sinaliza por não estarem no text pool.

**Como fazer:**
1. Tcode `SE38` → Program: `ZRMM_MONITOR_MDFE` → **Change**  
2. Menu: `Goto → Text Elements → Text Symbols`  
3. Criar os seguintes símbolos de texto:

| Símbolo | Texto sugerido |
|---------|----------------|
| `B01` | Filtro por NF-e |
| `B02` | Filtro por Chave / MDF-e |
| `B03` | Filtro por Status |

4. **Save + Activate**.

> **Nota sobre mensagens inline:** As strings hardcoded no report (como `'Selecione ao menos uma linha.'`) geram avisos SLIN de severidade 3. Para eliminar esses avisos, mova-as para o **text pool** com símbolos `T01`, `T02`, etc., e referencie como `TEXT-t01`. Como são strings fixas sem necessidade de tradução imediata, é aceitável tolerar esses avisos de severidade 3 para esta entrega.

---

### 4. Text Elements da Classe — SE24 (12 erros "missing in character string" + 6 "in string template")

Esses avisos SLIN (severidade **3**) ocorrem porque a classe `ZCL_MDFE_MONITOR` usa string literals e string templates para mensagens de validação (ex.: `'Empresa é obrigatória'`, `|MDF-e { iv_mdfe_number } nao encontrado|`).

**Opções para resolver:**

**Opção A — Criar Message Class Z (recomendado para produção):**
1. Tcode `SE91` → criar Message Class `ZMDFE`
2. Definir mensagens numeradas (ex.: `001` = `'Empresa é obrigatória'`)
3. Na classe, substituir as strings por `MESSAGE ID 'ZMDFE' TYPE 'E' NUMBER '001' ...`
4. Elimina todos os warnings de text elements

**Opção B — Manter como literal (aceitável para entrega):**
- Avisos são severidade 3 (informativos), não bloqueantes para release
- Exceção de ATC pode ser criada: Tcode `ATC` → **Manage Exceptions** → marcar os itens de severidade 3 da `ZCL_MDFE_MONITOR` com justificativa "Strings de validação PT-BR sem requisito de tradução"

**Recomendação:** Para a release atual, usar **Opção B** + exceção ATC. Opção A pode ser feita em um sprint separado.

---

### 5. ZCL_NFSE_LAYOUT_CPI — Fora do escopo do TR atual

O ATC sinalizou também `ZCL_NFSE_LAYOUT_CPI` (pacote `Z001`) com:
- `CONSTANTS` sem prefixo `mc_` (2 erros)
- `TYPES` sem prefixo `mty_` (5 erros)

Esses objetos estão em TR separado (`Z001`). **Não alterar agora** — abrir item de melhoria separado para tratar no próximo ciclo.

---

### 6. J_1BNFE_MONITOR — SAP Standard (não acionável)

O ATC reportou avisos de `DATA/STATICS (local)` e `TYPES (local)` no programa SAP standard `J_1BNFE_MONITOR` (pacote `J1BNFE`). Esses são **falsos positivos de convecção** — o padrão `delaware` foi aplicado sobre código SAP que usa convenções diferentes. **Não modificar código SAP standard.** Criar exceção ATC para esses itens.

**Como criar exceção:**
1. ATC → resultado da execução
2. Selecionar os itens de `J_1BNFE_MONITOR`
3. **Request Exception** → justificativa: `SAP standard program - naming convention not applicable`

---

## Checklist Final antes do Release do TR

- [ ] SE41: Criar `STATUS_100`, `STATUS_200_CRE`, `STATUS_200_EDT`, `STATUS_200_DSP`
- [ ] SE41: Criar `TITLE_100`, `TITLE_200_CRE`, `TITLE_200_EDT`, `TITLE_200_DSP`
- [ ] SE38 (`ZRMM_MONITOR_MDFE`): Criar text symbols `B01`, `B02`, `B03`
- [ ] ATC exception: `J_1BNFE_MONITOR` (SAP standard)
- [ ] ATC exception: Text element warnings severidade 3 em `ZCL_MDFE_MONITOR` (OU criar Message Class `ZMDFE`)
- [ ] Ativar `ZCL_MDFE_MONITOR` e `ZRMM_MONITOR_MDFE` no ADT após aplicar os arquivos atualizados
- [ ] Re-executar ATC → confirmar Critical Errors = 0 para os objetos do TR
