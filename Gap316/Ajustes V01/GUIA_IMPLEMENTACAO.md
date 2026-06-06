# GAP316 — Guia de Implementação

## Ordem de ativação

### 1. `ZI_S2M_MATERIAIS_COMPAT`
CDS base que alimenta o buffer. Troca o filtro hardcoded de charcinternalid por JOIN com `I_ClfnCharcDesc`.  
**Por quê primeiro:** os objetos ABAP e CDS downstream dependem desta view.

---

### 2. `ZI_S2M_MATERIAIS_COMPATIVEIS`
CDS base da segunda tela. Adiciona LEFT OUTER JOIN com `I_MaterialText` para trazer o nome do material (MAKTX).  
**Por quê:** `ZR_` e `ZC_` propagam o campo — precisam que ele exista na base antes.

---

### 3. `ZR_S2M_MATERIAIS_COMPATIVEIS`
CDS transacional. Propaga o campo `MaterialName` adicionado no passo 2.

---

### 4. `ZC_S2M_MATERIAIS_COMPATIVEIS`
CDS de projeção. Propaga `MaterialName` e expõe para o Fiori.

---

### 5. `ZCLS2M_MATERIAIS_ORDEM`
Classe ABAP com 3 correções juntas:
- **FIX1** — busca grupos direto em `ZI_S2M_MATERIAIS_COMPAT` (antes passava por receita de fabricação → grupo errado)
- **FIX3** — DELETE antes do MODIFY para não acumular dados obsoletos no buffer
- **REQ1** — IDs de `charcinternalid` lidos de `I_ClfnCharcDesc` em vez de hardcoded

---

### 6. `ZCLS2M_MAT_CARACT_CALC`
SADL Exit (MAP_ATOM). Corrige o loop triplo para filtrar compatíveis pelo grupo do material da reserva.  
**FIX2** — sem este fix, todas as reservas recebem os compatíveis de todas as ordens ao mesmo tempo (cross-join).

---

### 7. `ZR_S2M_PO_COMP_MONITOR.bdef`
Declara `MaterialName` como `field (readonly)` em `ZR_S2M_MATERIAIS_COMPATIVEIS`.  
**Por quê:** em RAP `strict(2)` com draft, qualquer campo da CDS que não existe na tabela persistente precisa estar declarado no BDEF. `MaterialName` vem do JOIN com `I_MaterialText` — não existe em `ztbs2m_mat_compa` nem em `ztbs2m_mat_compd`.

---

### 8. `ZC_S2M_PO_COMP_MONITOR.bdef`
Remove `use action Edit` da projeção RAP.  
**Por quê:** desabilita o botão "Editar" na tela principal — tela passa a ser somente leitura + Remarcar.

---

### 9. `ZC_S2M_PO_COMP_MONITOR.asddlx` *(objeto NOVO)*
Metadata Extension da tela inicial. Adiciona `@UI.lineItem` para os campos que já existiam no CDS mas não apareciam na grid: código/nome do produto da ordem e nome do componente.

---

### 10. `ZC_S2M_MATERIAIS_COMPATIVEIS.asddlx` *(objeto NOVO)*
Metadata Extension da segunda tela. Define seleção única (`@UI.selectionMode: #SINGLE`) e inclui `MaterialName` nas colunas.

---

## Após ativar tudo

Limpar o buffer manualmente para garantir que os dados antigos não persistam:
```sql
DELETE FROM ztbs2m_ordem.
DELETE FROM ztbs2m_mat_compa.
```
Depois abrir o app — o buffer é repopulado automaticamente pelo SADL exit na primeira abertura.
