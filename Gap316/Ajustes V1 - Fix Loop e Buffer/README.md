# Ajustes V1 — Fix Cross-Join + Rota Compatibilidade + Buffer Cleanup

## Escopo desta versão

Corrige os 4 problemas identificados na análise:

1. **Cross-join** no loop interno do MAP_ATOM (`ZCLS2M_MAT_CARACT_CALC`)
2. **Rota via receita** na `ZCLS2M_MATERIAIS_ORDEM::get_materiais_ordem`  
3. **Buffer sem DELETE** antes do INSERT
4. **lv_ok WHEN OTHERS** — lógica do pivot substituída por flags booleanas

## Arquivos alterados

| Arquivo | Classe/Objeto | Mudança |
|---------|--------------|---------|
| `zcls2m_materiais_ordem.clas.abap` | `ZCLS2M_MATERIAIS_ORDEM` | Fix 1 (rota), Fix 3 (buffer DELETE), Fix 4 (lv_ok → flags) |
| `zcls2m_mat_caract_calc.clas.abap` | `ZCLS2M_MAT_CARACT_CALC` | Fix 2 (cross-join loop) |

## O que NÃO muda nesta versão

- CDS views (nenhuma alteração de definição)
- BDEF (comportamento RAP mantido)
- Ação Remarcar (não alterada)
- Tabelas buffer (estrutura mantida, apenas o uso muda)
- App Fiori / anotações

## Dependências de dados (ação do funcional)

> **Pré-requisito antes de testar:** Confirmar se grupo 50000087 tem as 3 características
> (991, 998, 1031) em `ZI_S2M_MATERIAIS_COMPAT`. SE16N filtro: grupo = 50000087.
> Se faltar, cadastrar as linhas de características no dado mestre.

## Como testar

1. Deployar os 2 arquivos alterados nesta pasta para o sistema
2. Limpar o buffer manualmente: SE16N → ZTBS2M_MAT_COMPA → deletar entradas de teste
3. Abrir o app Fiori ZZ1_COMP_MONIT
4. Verificar aba "Materiais" da reserva 4841/6 → deve mostrar grupo 87
5. Abrir com múltiplas reservas abertas → cada uma deve ter apenas seus substitutos
6. Fechar e reabrir o app → buffer deve ser repopulado corretamente
