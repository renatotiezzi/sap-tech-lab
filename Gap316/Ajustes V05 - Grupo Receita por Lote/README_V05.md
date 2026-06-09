# GAP316 - Ajustes V05 (Grupo da receita pelo lote)

## Contexto funcional
Ao validar o GAP316, foram observadas linhas duplicadas do mesmo lote em grupos de receita diferentes quando existem duas versoes ativas.

Exemplo reportado:
- Lote aparece uma vez com grupo `5000087` (esperado)
- O mesmo lote aparece novamente com grupo `5000107` (indevido)

## Causa tecnica
No CDS base `ZI_S2M_MATERIAIS_COMPAT`, a combinacao de versoes ativas + caracteristicas de lote permitia associar o mesmo lote a grupo divergente da caracteristica de lote usada para grupo de receita (char. `1031`).

## Correcao V05
Foi adicionada validacao no `WHERE` para forcar consistencia:
- Para linhas da caracteristica `1031`, o `CharcValue` deve ser igual ao `BillOfOperationsGroup`.
- Para as demais caracteristicas (`991` e `998`), mantem comportamento atual.

Resultado esperado:
- O lote permanece somente no grupo de receita coerente com o proprio lote.
- Nao altera logica funcional de filtro de estoque, deposito, lote, centro e validacao de caracteristicas.

## Arquivo alterado
- `zi_s2m_materiais_compat.ddls.asddls`
