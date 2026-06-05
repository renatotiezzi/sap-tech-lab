# Ajustes V4 — Campos visíveis na tela inicial (REQ2)

## Requisito
REQ 2 do checklist funcional: incluir na grid da tela inicial:
1. `A_PROCESSORDER.MATERIAL` (código do produto da ordem)
2. `A_PROCESSORDER.MATERIALNAME` (nome do produto da ordem)
3. `MARA.MAKTX` (nome do componente)
4. Filtrar: apenas materiais com `ZZ1_GR_APROVEITAMENTO_PRD != '0'`

## Análise do estado atual

### Campos no CDS — JÁ EXISTEM
Em `ZC_S2M_PO_COMP_MONITOR`:
- `material` — componente
- `I_MaterialText.MaterialName` — nome do componente (MAKTX)
- `A_ProcessOrder.Material as MaterialOrdem` — material da ordem
- `A_ProcessOrder.MaterialName as MaterialOrdemName` — nome da ordem

### Filtro ZZ1_GR_APROVEITAMENTO_PRD — JÁ EXISTE
Em `ZR_S2M_ORDEM`: `inner join I_Product on ... and I_Product.ZZ1_Gr_aproveitamento_PRD != '0'`

### O que FALTA
Não existe metadata extension (asddlx) para `ZC_S2M_PO_COMP_MONITOR`.
Sem `@UI.lineItem` annotation, o Fiori Elements não exibe os campos na grid por padrão.

## Solução
Criar `zc_s2m_po_comp_monitor.ddls.asddlx` com:
- `@UI.lineItem` para os campos principais (posições numeradas)
- `MaterialOrdem`, `MaterialOrdemName`, `I_MaterialText.MaterialName` recebem posição na grid

## Arquivo criado
| Arquivo | Tipo | Mudança |
|---------|------|---------|
| `zc_s2m_po_comp_monitor.ddls.asddlx` | CDS Metadata Extension | Cria anotações UI.lineItem para tela inicial |

## Notas
- `UpdateTable` tem `@UI.hidden: true` no CDS principal — não precisa de anotação aqui
- Posições na grid: espaçadas de 10 em 10 para facilitar inserção futura de campos
- `@UI.selectionField` adicionado nos filtros mais usados (Ordem, Material, Centro)
