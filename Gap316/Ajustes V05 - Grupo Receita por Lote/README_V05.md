# GAP316 - Ajustes V05 (Grupo da receita pelo lote)

## Contexto funcional
Ao validar o GAP316, foram observadas linhas duplicadas do mesmo lote em grupos de receita diferentes quando existem duas versoes ativas.

Exemplo reportado:
- Lote aparece uma vez com grupo `5000087` (esperado)
- O mesmo lote aparece novamente com grupo `5000107` (indevido)

## Causa tecnica
No CDS base `ZI_S2M_MATERIAIS_COMPAT`, a combinacao de versoes ativas + caracteristicas de lote permitia associar o mesmo lote a grupo divergente da caracteristica de lote usada para grupo de receita.

## Correcao V05
Foi adicionada validacao no `WHERE` para forcar consistencia:
- Sem hardcode de `CharcInternalID`.
- Removido o filtro restritivo por igualdade direta de `CharcValue` com `BillOfOperationsGroup`, pois estava excluindo lotes validos.

Adicionalmente, este V05 foi sincronizado com a baseline de V1 do mesmo objeto:
- Mantido o join com `I_ClfnCharcDesc` (remocao de hardcode de IDs), evitando evolucao em objeto desatualizado.
- Regra: toda nova versao deste objeto deve partir da ultima baseline consolidada na base.

Resultado esperado:
- O lote permanece somente no grupo de receita coerente com o proprio lote.
- Lotes validos com mesmo grupo de receita nao sao indevidamente filtrados.
- Nao altera logica funcional de filtro de estoque, deposito, lote, centro e validacao por descricao de caracteristica (baseline V1).

## Arquivo alterado
- `zi_s2m_materiais_compat.ddls.asddls`
