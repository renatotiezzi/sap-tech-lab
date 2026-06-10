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
- Regra funcional mantida: `CharcValue = BillOfOperationsGroup`.
- Essa regra foi introduzida no V05 para impedir combinacoes inconsistentes de grupo de receita x lote.
- Nao remover essa linha sem validacao funcional explicita, pois e ponto central da correcao.
- Refinamento V05: comparacao com tolerancia a zeros a esquerda para evitar perda de lotes validos por diferenca de formatacao do valor da caracteristica.

## Correcao complementar V05
O ponto que ainda fazia o app trazer grupo pela receita estava em `ZCLS2M_MATERIAIS_ORDEM`.
- Antes: `SELECT DISTINCT billofoperationsgroup FROM I_MasterRecipeMaterialAssgmt`
- Agora: `SELECT DISTINCT grupo FROM ZI_S2M_MATERIAIS_COMPAT`

Isso corrige o comportamento que deixava de listar lotes validos como 2963/2964 quando o grupo correto ja estava cadastrado na base de materiais compativeis.

## Correcao de pivot V05
No pivot de caracteristicas, somente `991`, `998` e `1031` contam para fechar a linha.
- `WHEN OTHERS` nao incrementa mais `lv_ok`.
- O loop sai quando as 3 caracteristicas esperadas sao encontradas.

Adicionalmente, este V05 foi sincronizado com a baseline de V1 do mesmo objeto:
- Mantido o join com `I_ClfnCharcDesc` (remocao de hardcode de IDs), evitando evolucao em objeto desatualizado.
- Regra: toda nova versao deste objeto deve partir da ultima baseline consolidada na base.

Resultado esperado:
- O lote permanece somente no grupo de receita coerente com o proprio lote.
- Lotes validos com mesmo grupo de receita nao sao indevidamente filtrados.
- Nao altera logica funcional de filtro de estoque, deposito, lote, centro e validacao por descricao de caracteristica (baseline V1).

## Arquivo alterado
- `zi_s2m_materiais_compat.ddls.asddls`
