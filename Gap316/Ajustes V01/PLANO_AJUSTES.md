# GAP316 — Plano de Ajustes (CR Única)

> **Data:** 05/06/2026  
> **CR:** CR GAP316 — uma única entrega com todos os pontos abaixo  
> **Estratégia:** Todos os objetos modificados entram em uma única ativação no SAP

---

## Objetos alterados nesta CR

| # | Objeto | Tipo | Motivo |
|---|--------|------|--------|
| 1 | `ZCLS2M_MAT_CARACT_CALC` | ABAP Class | FIX2 — cross-join no MAP_ATOM |
| 2 | `ZCLS2M_MATERIAIS_ORDEM` | ABAP Class | FIX1 + FIX3 + REQ1 |
| 3 | `ZI_S2M_MATERIAIS_COMPAT` | CDS DDL | REQ1 — filtro dinâmico charcinternalid |
| 4 | `ZI_S2M_MATERIAIS_COMPATIVEIS` | CDS DDL | REQ3-6 — MAKTX segunda tela |
| 5 | `ZR_S2M_MATERIAIS_COMPATIVEIS` | CDS DDL | REQ3-6 — expor MaterialName |
| 6 | `ZC_S2M_MATERIAIS_COMPATIVEIS` | CDS DDL | REQ3-6 — expor MaterialName |
| 7 | `ZC_S2M_PO_COMP_MONITOR` | BDEF | REQ3-4 — manter `Edit` (exigência RAP strict+draft) |
| 8 | `ZC_S2M_PO_COMP_MONITOR` | Metadata Ext. (existente, ajustada) | REQ2 — campos visíveis tela inicial |
| 9 | `ZC_S2M_MATERIAIS_COMPATIVEIS` | Metadata Ext. (existente, ajustada) | REQ3-4 — seleção única |

---

## Pontos já implementados (sem mudança necessária)

| Ponto | Localização | Status |
|-------|-------------|--------|
| Filtro depósito `OIB_TNKASSIGN = 'T'` | `ZI_S2M_Deposito_tanque` (WHERE existente) | ✅ JÁ EXISTE |
| Filtro `ZZ1_GR_APROVEITAMENTO_PRD != '0'` | `ZR_S2M_ORDEM` (JOIN existente) | ✅ JÁ EXISTE |
| Código material da ordem (`MaterialOrdem`) | `ZC_S2M_PO_COMP_MONITOR` (campo existente) | ✅ JÁ EXISTE |
| Nome material da ordem (`MaterialOrdemName`) | `ZC_S2M_PO_COMP_MONITOR` (campo existente) | ✅ JÁ EXISTE |
| Nome componente (`MaterialName`) | `ZC_S2M_PO_COMP_MONITOR` via `I_MaterialText` | ✅ JÁ EXISTE |

---

## Ponto 1 — FIX2: Cross-join no loop MAP_ATOM

**Objeto:** `ZCLS2M_MAT_CARACT_CALC`

**Problema:**  
Loop interno em `MAP_ATOM` não filtra por material da reserva — vincula TODOS os materiais compatíveis de TODAS as ordens a CADA reserva. Com 2 ordens abertas (A e B), cada reserva recebe os compatíveis de A + B.

**Solução:**  
1. Antes do loop principal, fazer SELECT de `ZI_S2M_MATERIAIS_COMPAT` para obter o mapeamento `material_componente → grupo_compatibilidade`  
2. No loop por reserva: filtrar `lt_mat_grupo_map` pelo material da reserva para obter o(s) grupo(s) corretos  
3. No loop por grupo: filtrar `lt_materiais_compat` por `grupo = <fs_mat_grp>-grupo`

**Antes:**
```abap
LOOP AT lt_comp_monitor...
  LOOP AT lt_materiais_compat...  " SEM filtro → cross-join
    APPEND.
  ENDLOOP.
ENDLOOP.
```

**Depois:**
```abap
" 1. Obter mapa material→grupo
SELECT DISTINCT material, grupo FROM zi_s2m_materiais_compat
  WHERE material IN @lr_material INTO TABLE @lt_mat_grupo_map.

" 2. Loop triplo filtrado
LOOP AT lt_comp_monitor...
  LOOP AT lt_mat_grupo_map WHERE material = <monitor>-material.
    LOOP AT lt_materiais_compat WHERE grupo = <mat_grp>-grupo.
      APPEND.
    ENDLOOP.
  ENDLOOP.
ENDLOOP.
```

---

## Ponto 2 — FIX1: Rota errada via I_MasterRecipeMaterialAssgmt

**Objeto:** `ZCLS2M_MATERIAIS_ORDEM`

**Problema:**  
`get_materiais_ordem` usa `I_MasterRecipeMaterialAssgmt` para obter grupos via receita de fabricação. Para o material 30001500, retorna grupos 50000066/50000060 (grupos do produto). O grupo correto (50000087) está direto em `ZI_S2M_MATERIAIS_COMPAT` para o componente.

**Solução:**  
Substituir o SELECT via receita por SELECT direto em `ZI_S2M_MATERIAIS_COMPAT`:
```abap
" ANTES:
SELECT DISTINCT billofoperationsgroup FROM I_MasterRecipeMaterialAssgmt
  WHERE material IN @ir_material ...

" DEPOIS:
SELECT DISTINCT material, grupo FROM zi_s2m_materiais_compat
  WHERE centro IN @ir_plant AND material IN @ir_material
```

---

## Ponto 3 — FIX3: Buffer sem DELETE antes do MODIFY

**Objeto:** `ZCLS2M_MATERIAIS_ORDEM` (métodos `insert_ordem` e `insert_materiais`)

**Problema:**  
`MODIFY` (INSERT OR UPDATE) sem `DELETE` prévio → ordens encerradas permanecem no buffer; execuções repetidas geram dados obsoletos.

**Solução:**  
Antes do MODIFY: `DELETE FROM ztbs2m_ordem WHERE reservation IN @lr_reservation_o` e idem para `ztbs2m_mat_compa`.

---

## Ponto 4 — REQ1: charcinternalid hardcoded (WHEN '991'/'998'/'1031')

**Objetos:** `ZCLS2M_MATERIAIS_ORDEM` + `ZI_S2M_MATERIAIS_COMPAT`

**Problema:**  
Dois lugares com IDs fixos:
- ABAP: `CASE charcinternalid WHEN '991' WHEN '998' WHEN '1031'`  
- CDS: `WHERE CharcInternalID IN ('0000001031','0000000991','0000000998')`  

Se os IDs mudarem no sistema (renovação de características), o código para de funcionar silenciosamente — sem erro, apenas sem retornar materiais.

**Solução — ABAP:**  
Buscar IDs válidos dinamicamente de `I_ClfnCharcDesc` filtrando:
- `Language = 'P'`, `CharcDescription = 'Grp Receita Mestre'`
- `ValidityStartDate <= sy-datum`, `ValidityEndDate >= sy-datum`, `IsDeleted = ''`  

Substituir CASE fixo por: `IF charcinternalid IN lr_valid_charc → lv_ok_count + 1`  
Condição de inclusão: `lv_ok_count = lv_charcs_count` (todos os IDs válidos presentes)

**Solução — CDS:**  
Substituir o OR hardcoded no WHERE por INNER JOIN com `I_ClfnCharcDesc` usando os mesmos filtros.

**Fail-safe:** Se `I_ClfnCharcDesc` não retornar registros ativos → `RETURN` imediato sem processar nada (comportamento seguro).

---

## Ponto 5 — REQ2: Campos da tela inicial não visíveis no Fiori

**Objeto:** `ZC_S2M_PO_COMP_MONITOR` (Metadata Extension — objeto existente, ajustado)

**Problema:**  
Os campos `MaterialOrdem`, `MaterialOrdemName` e `MaterialName` (MAKTX componente) JÁ EXISTEM no CDS de projeção. Porém sem `@UI.lineItem` annotation, o Fiori Elements não os exibe na grid do List Report.

**Solução:**  
Criar `zc_s2m_po_comp_monitor.ddls.asddlx` com anotações `@UI.lineItem` e `@UI.selectionField` para todos os campos relevantes, incluindo os 3 acima.

---

## Ponto 6 — REQ3-4: Ajuste de Edit no projection BDEF

**Objeto:** `ZC_S2M_PO_COMP_MONITOR.bdef`

**Problema:**  
Ao remover `use action Edit`, o projection BDEF deixa de compilar com erro do framework: em `strict(2)` com `use draft`, a draft action `Edit` precisa estar explicitamente incluída na projeção.

**Solução:**  
Manter `use action Edit` na projeção `ZC_S2M_PO_COMP_MONITOR` para cumprir a validação RAP.  
Manter `use update` no item para preservar comportamento baseline.  
Ocultar o botão `Edit` via adaptação de UI no FLP (UI Adaptation at Runtime), sem alterar o contrato técnico exigido pelo RAP.

**Observação de compatibilidade:** no release atual, a annotation `@UI.updateHidden` não compila neste objeto.

**Nota:** Base BDEF (`ZR_S2M_PO_COMP_MONITOR`) define `Remarcar` como action sem dependência de update na projeção — não precisa de alteração.

---

## Ponto 7 — REQ3-6: MAKTX (nome do componente) ausente na segunda tela

**Objetos:** `ZI_S2M_MATERIAIS_COMPATIVEIS` + `ZR_` + `ZC_`

**Problema:**  
A aba de materiais compatíveis (segunda tela) não exibe o nome do material substituto. O campo MAKTX (`MaterialName`) precisa ser incluído no CDS chain.

**Solução:**  
Em `ZI_S2M_MATERIAIS_COMPATIVEIS`: adicionar LEFT OUTER JOIN com `I_MaterialText` (Language = `$session.system_language`) e expor `_MatText.MaterialName`.  
Propagar o campo por `ZR_` e `ZC_`.

**LEFT OUTER JOIN** para não excluir materiais que não tenham texto cadastrado.

---

## Ponto 8 — REQ3-4: Seleção única na segunda tela

**Objeto:** `ZC_S2M_MATERIAIS_COMPATIVEIS` (Metadata Extension — objeto existente, ajustado)

**Problema:**  
A tabela de materiais compatíveis permite seleção múltipla. O funcional quer selecionar apenas uma linha antes de clicar em Remarcar.

**Solução:**  
Criar `zc_s2m_materiais_compativeis.ddls.asddlx` com anotação `@UI.selectionMode: #SINGLE` e `@UI.lineItem` para os campos da tabela incluindo `MaterialName`.

---

## Sequência de ativação no SAP

```
1. ZI_S2M_MATERIAIS_COMPAT          (CDS base - afeta comportamento do buffer)
2. ZI_S2M_MATERIAIS_COMPATIVEIS     (CDS base - adiciona MAKTX)
3. ZR_S2M_MATERIAIS_COMPATIVEIS     (CDS transacional)
4. ZC_S2M_MATERIAIS_COMPATIVEIS     (CDS projeção)
5. ZCLS2M_MATERIAIS_ORDEM           (ABAP - FIX1+FIX3+REQ1)
6. ZCLS2M_MAT_CARACT_CALC           (ABAP - FIX2)
7. ZC_S2M_PO_COMP_MONITOR.bdef      (BDEF - manter Edit por regra RAP strict+draft)
8. ZC_S2M_PO_COMP_MONITOR.asddlx    (META - existente, ajustada para campos da tela inicial)
9. ZC_S2M_MATERIAIS_COMPATIVEIS.asddlx  (META - existente, ajustada para seleção única + MAKTX)
```

---

## Pré-requisito de dados (necessário antes de testar)

O material 30001500 e outros materiais do grupo 50000087 precisam ter as características `Grp Receita Mestre` (IDs obtidos via `I_ClfnCharcDesc`) cadastradas em `A_BATCHCHARCVALUE` / `ZI_S2M_MATERIAIS_COMPAT`. Sem isso o FIX1 retorna os materiais corretos mas o pivot de características os descarta.

**Verificar:** `SELECT * FROM zi_s2m_materiais_compat WHERE material = '30001500' AND centro = '4815'`  
→ Se não retornar linhas com as 3 características → cadastrar via transação de classificação de lote.
