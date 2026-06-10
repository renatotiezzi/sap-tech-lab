# GAP316 V05 - Sumário de Mudanças

## Problema Resolvido

**Duplicidade de lotes na tela do app**: O mesmo lote aparecia múltiplas vezes associado a grupos de receita diferentes (ex: lote com grupo 50000087 E 50000107).

**Causa Raiz**: 
- Material 30001600 ausência inicial = falta de cadastro em I_ProductVersion (funcional, não código)
- Duplicidade persistente = mesmos lotes sendo retornados em múltiplos grupos (50000087 vs 50000107)

## Ajustes Implementados

### 1. Limpeza da Tela (CDS Projection)
**Arquivo**: `ZC_S2M_MATERIAIS_COMPATIVEIS.ddls.asddls`  
**O que mudou**:
- ❌ Removido: `Grupo` (campo técnico)
- ❌ Removido: `Productionversion` (Versão de Produção)
- ❌ Removido: `Validade` (Data Fim da Validade)
- ❌ Removido: `boomatlinternalversioncounter` (Contador)
- ✅ Renomeado: `Charcvalue` → `GrupoReceitaMestre` (mais legível)
- ✅ Posição: Agora após `Centro` na exibição

**Resultado**: UI simplificada, mostrando apenas campos essenciais ao usuário final.

### 2. Eliminação de Duplicidade por Lote
**Arquivo**: `ZCLS2M_MATERIAIS_ORDEM.clas.abap` (método `get_materiais_ordem`)  
**O que mudou**:
- Adicionada deduplicação final: para cada lote único (material+centro+lote+deposito), manter apenas a primeira ocorrência de grupo
- Mantém lógica de validação de características (pivot dinâmico)
- Ordem de precedência: primeiro grupo encontrado é mantido, alternativas são descartadas

**Código**:
```abap
" V05 - Eliminar duplicidade de lotes com multiplos grupos
" Manter apenas a primeira ocorrencia de cada material/centro/lote/deposito
IF et_materiais_compat IS NOT INITIAL.
  DATA lt_dedup_lote TYPE TABLE OF ztbs2m_mat_compa.
  DATA ls_last_lote TYPE ztbs2m_mat_compa.
  
  SORT et_materiais_compat BY material centro lote deposito grupo.
  
  CLEAR ls_last_lote.
  LOOP AT et_materiais_compat ASSIGNING FIELD-SYMBOL(<fs_compat>).
    IF ls_last_lote-material    <> <fs_compat>-material
    OR ls_last_lote-centro      <> <fs_compat>-centro
    OR ls_last_lote-lote        <> <fs_compat>-lote
    OR ls_last_lote-deposito    <> <fs_compat>-deposito.
      APPEND <fs_compat> TO lt_dedup_lote.
      ls_last_lote = <fs_compat>.
    ENDIF.
  ENDLOOP.
  
  et_materiais_compat = lt_dedup_lote.
ENDIF.
```

**Resultado**: Cada lote aparece apenas uma única vez no buffer, com o primeiro grupo válido encontrado.

## Resultado Final Esperado

- ✅ Sem duplicação de lotes por múltiplos grupos
- ✅ Tela limpa: removidas informações técnicas desnecessárias
- ✅ Campo "Grupo de Receita Mestre" claro e bem posicionado
- ✅ Lote 30001500 com 5 registros (un único grupo 50000087, sem 50000107)
- ✅ Lote 30001600 aparecerá quando cadastrado em I_ProductVersion

## Sincronização V05

Todos os ajustes foram sincronizados em ambos os locais:
- Base: `Gap316/ZPS2M_316E001_20260604_132249/src/`
- V05: `Gap316/Ajustes V05 - Grupo Receita por Lote/`

## Commits Associados

1. `5c665ec` - Remove UI technical fields and rename Charcvalue
2. `289073b` - Add V05 copy of UI Projection view
3. `eae866b` - Eliminate duplicate lots with multiple groups

## Validação

- ✅ Sem erros de sintaxe ABAP
- ✅ CDS views validadas
- ✅ Lógica de deduplicação testada em base + V05
- ✅ Git commits publicados com sucesso
