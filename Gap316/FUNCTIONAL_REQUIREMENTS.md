# GAP 316 — Requisitos Funcionais e Ajustes Solicitados

> **NOTA:** O arquivo Excel "Check list testes - GAP 316.xlsx" enviado pelo funcional está em formato binário
> XLS (OLE2), não foi possível extrair automaticamente. As informações abaixo foram consolidadas a partir
> da análise técnica disponível em `get_materiais_ordem_analise.txt` e do código-fonte.
> **Ação necessária:** Confirmar com o funcional se há requisitos adicionais no Excel além dos descritos aqui.

---

## Contexto Funcional

O app monitora componentes de Ordens de Produção que podem ser substituídos por materiais compatíveis
(substituição por aproveitamento). O funcional identificou comportamentos incorretos no app e enviou
o checklist com os cenários de teste esperados.

---

## Problema 1 — Material do grupo 87 não aparece na aba "Materiais"

### Comportamento atual (errado)
- Reserva 4841 / Item 6 / Material componente **30001500**
- A aba "Materiais" exibe: **30001000** (grupo 50000066) e **31409000** (grupo 50000060)
- Esses são substitutos de grupos da RECEITA do produto — não do grupo de compatibilidade do componente

### Comportamento esperado (correto)
- O material **30001500** pertence ao grupo de compatibilidade **50000087** em `ZI_S2M_MATERIAIS_COMPAT`
- A aba "Materiais" deveria exibir os substitutos do **grupo 50000087**

### Causa raiz
O código usa `I_MasterRecipeMaterialAssgmt` para obter o grupo via receita de fabricação:
- Material 30001500 → receita → grupos 50000066 e 50000060 (grupos do PRODUTO, não do componente)
- O grupo correto (50000087) está diretamente em `ZI_S2M_MATERIAIS_COMPAT` para o material 30001500

### Fix necessário
**Opção A (Fix de dados — pré-requisito):** Cadastrar em `ZI_S2M_MATERIAIS_COMPAT` as 3 características
(charcinternalid 991, 998 e 1031) para o grupo 50000087, materiais do grupo.

**Opção B (Fix de código):** Substituir a consulta via receita por consulta direta:
```abap
" ANTES (errado — busca grupos da receita):
SELECT DISTINCT billofoperationsgroup
  FROM I_MasterRecipeMaterialAssgmt
  WHERE material IN @ir_material

" DEPOIS (correto — busca grupo de compatibilidade direto):
SELECT DISTINCT grupo
  FROM ZI_S2M_MATERIAIS_COMPAT
  WHERE material IN @ir_material
```

---

## Problema 2 — Cross-join: materiais incorretos vinculados por reserva

### Comportamento atual (errado)
Quando existem múltiplas ordens/reservas abertas, o loop interno em `MAP_ATOM` não filtra por material.
Resultado: **todos** os materiais compatíveis de **todas** as ordens são associados a **cada** reserva.

Exemplo com 2 ordens abertas:
- Ordem A (material 30001000): recebe compatíveis de 30001000 **E** de 31409000
- Ordem B (material 31409000): recebe compatíveis de 31409000 **E** de 30001000

### Comportamento esperado
Cada reserva deve exibir **apenas** os materiais compatíveis do seu componente.

### Fix necessário
```abap
" ANTES (errado — cross join):
LOOP AT lt_materiais_compat ASSIGNING FIELD-SYMBOL(<fs_materiais_compat>).

" DEPOIS (correto — filtrado pelo material da ordem):
LOOP AT lt_materiais_compat ASSIGNING FIELD-SYMBOL(<fs_materiais_compat>)
  WHERE material_fonte = <fs_comp_monitor>-material.   " campo adicional necessário
```
> **Dependência:** `get_materiais_ordem` precisa retornar também o `material_fonte` (o material
> que gerou o grupo), para que o filtro no loop externo seja possível.

---

## Problema 3 — Buffer acumula dados obsoletos

### Comportamento atual (errado)
A SADL exit usa `MODIFY` (INSERT OR UPDATE) sem `DELETE` prévio.
- Ordens encerradas podem permanecer no buffer
- Execuções repetidas geram duplicatas ou dados de ordens antigas

### Comportamento esperado
A cada abertura do app, o buffer deve refletir exatamente o estado atual das ordens ativas.

### Fix necessário
```abap
" Antes de INSERT: limpar buffer das reservas que serão reprocessadas
DELETE FROM ztbs2m_ordem WHERE reservation IN @lr_reservation.
DELETE FROM ztbs2m_mat_compa WHERE reservation IN @lr_reservation.
" Ou DELETE total (mais simples, depende do impacto em uso simultâneo):
DELETE FROM ztbs2m_ordem.
DELETE FROM ztbs2m_mat_compa.
```

---

## Problema 4 — lv_ok com WHEN OTHERS pode ultrapassar 3

### Comportamento atual (risco)
No pivot de características:
```abap
WHEN OTHERS.
  lv_ok = lv_ok + 1.   " qualquer charcinternalid desconhecido também incrementa
```
Se o lote tiver 4 características (ex: 991 + 998 + 1031 + algum outro), `lv_ok` chega a 4.
A condição `IF lv_ok > 3 → EXIT` poderia sair antes de processar as 3 características necessárias.

### Fix necessário
Remover o `WHEN OTHERS` do incremento ou usar flag booleanas independentes:
```abap
DATA: lv_has_991  TYPE abap_bool,
      lv_has_998  TYPE abap_bool,
      lv_has_1031 TYPE abap_bool.
...
CASE <fs_grupo_mat>-charcinternalid.
  WHEN '991'.  lv_has_991  = abap_true.
  WHEN '998'.  lv_has_998  = abap_true.
  WHEN '1031'. lv_has_1031 = abap_true.
ENDCASE.
...
IF lv_has_991 = abap_true AND lv_has_998 = abap_true AND lv_has_1031 = abap_true.
  APPEND ls_materiais_compat TO et_materiais_compat.
ENDIF.
```

---

## Cenários de Teste Esperados (check list funcional)

> Os itens abaixo devem ser validados após os ajustes. **Confirmar com o funcional se o Excel
> contém cenários adicionais.**

| # | Cenário | Resultado Esperado |
|---|---------|-------------------|
| 1 | Abrir app com reserva 4841/6 (material 30001500, grupo 87) | Aba Materiais exibe substitutos do grupo 50000087 |
| 2 | Múltiplas ordens abertas simultaneamente | Cada reserva exibe apenas seus próprios substitutos |
| 3 | Fechar e reabrir o app | Buffer é limpo e repopulado corretamente |
| 4 | Material com grupo sem as 3 características (991/998/1031) | Material **não** aparece na aba (filtrado corretamente) |
| 5 | Material com as 3 características e estoque > 0 | Material aparece na aba com quantidade disponível |
| 6 | Ação Remarcar com 1 material substituto | Componente substituído na OP; mensagem de sucesso |
| 7 | Ação Remarcar com quantidade parcial | Substituto adicionado com quantidade informada; original re-adicionado com saldo |
| 8 | Ação Remarcar — quantidade > RequiredQuantity | Mensagem de erro; OP não alterada |
| 9 | Ordem em status diferente de Criado | **Não** aparece no monitor |
| 10 | Material sem `ZZ1_Gr_aproveitamento != '0'` | **Não** aparece no monitor |

---

## Prioridade de Implementação

| Prioridade | Fix | Impacto | Objeto(s) Alterado(s) |
|------------|-----|---------|----------------------|
| 1 (crítico) | Problema 2 — cross-join loop | Dados errados para todas as ordens | `ZCLS2M_MAT_CARACT_CALC` |
| 2 (crítico) | Problema 1 — rota via receita | Material correto não aparece | `ZCLS2M_MATERIAIS_ORDEM` |
| 3 (melhoria) | Problema 3 — buffer sem DELETE | Dados obsoletos após reuso | `ZCLS2M_MATERIAIS_ORDEM` |
| 4 (menor) | Problema 4 — lv_ok com WHEN OTHERS | Edge case com lotes com +3 características | `ZCLS2M_MATERIAIS_ORDEM` |
