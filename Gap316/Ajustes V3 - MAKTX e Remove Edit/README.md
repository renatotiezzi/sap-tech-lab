# Ajustes V3 — MAKTX segunda tela + remover botão Edit

## Requisito
REQ 3 do checklist funcional:
- Item 4: Remover o botão "Editar", permitir selecionar apenas uma linha
- Item 5: Filtrar depósitos por T001L.OIB_TNKASSIGN = 'T' (já implementado via ZI_S2M_Deposito_tanque)
- Item 6: Incluir o nome do componente (material) = MARA.MAKTX na segunda tela

## Análise do estado atual

### Filtro de depósito (item 5) — JÁ IMPLEMENTADO
`ZI_S2M_Deposito_tanque` já tem `where oib_tnkassign = 'T'`
e `ZI_S2M_MATERIAIS_COMPATIVEIS` faz inner join com ele.
**Nenhuma alteração necessária para o item 5.**

### MAKTX (item 6) — FALTA
`ZI_S2M_MATERIAIS_COMPATIVEIS` tem `association to I_Product as _Mara` mas
não expõe `ProductName` (MAKTX). Precisa adicionar join com `I_MaterialText`
para obter o nome do componente com filtro de idioma.

### Botão Edit (item 4) — FALTA
`ZC_S2M_PO_COMP_MONITOR.bdef.asbdef` tem:
  `use update;`
  `use action Edit;`
Remover ambos remove o modo de edição da primeira tela.
Em `ZC_S2M_MATERIAIS_COMPATIVEIS` (segunda tela):
  `use update;`  ← também remover — a Remarcar não precisa de update draft

## Arquivos alterados

| Arquivo | Tipo | Mudança |
|---------|------|---------|
| `zi_s2m_materiais_compativeis.ddls.asddls` | CDS DDL | Adiciona JOIN com I_MaterialText para MAKTX |
| `zr_s2m_materiais_compativeis.ddls.asddls` | CDS DDL | Expõe campo MaterialName |
| `zc_s2m_materiais_compativeis.ddls.asddls` | CDS DDL | Expõe campo MaterialName |
| `zc_s2m_po_comp_monitor.bdef.asbdef` | BDEF | Remove use update + use action Edit |

## Notas
- `I_MaterialText` é filtrado por `$session.system_language` (idioma da sessão)
- A association é 0..1 (nem todo material tem texto) — usar LEFT OUTER JOIN no ZI para não perder linhas
- Remover `use update` da segunda tela (ZC_S2M_MATERIAIS_COMPATIVEIS) é seguro pois a action Remarcar
  é implementada diretamente no handler sem precisar do update draft
