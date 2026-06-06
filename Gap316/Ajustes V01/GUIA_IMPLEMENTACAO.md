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

### 7. `ZTBS2M_MAT_COMPD` — SE11 (tabela DDIC)
Adicionar campo `MATERIALNAME` com rollname `MAKTX` antes do `.INCLUDE` de administração de draft.  
**Por quê:** em RAP `strict(2)`, o framework valida que TODOS os campos da CDS transacional existam fisicamente na draft table — mesmo os declarados `field (readonly)` no BDEF. Sem este campo na tabela, o BDEF não compila.  
**Como:** SE11 → `ZTBS2M_MAT_COMPD` → inserir campo `MATERIALNAME` (rollname `MAKTX`) → salvar e ativar com ajuste de tabela.

---

### 8. `ZR_S2M_PO_COMP_MONITOR.bdef`
Declara `MaterialName` como `field (readonly)` em `ZR_S2M_MATERIAIS_COMPATIVEIS`.  
**Por quê:** o campo vem de JOIN externo com `I_MaterialText` — não é gravado pelo handler MODIFY. O `field (readonly)` informa ao framework RAP que este campo não é editável pelo usuário.

---

### 9. `ZC_S2M_PO_COMP_MONITOR.bdef`
Mantém `use action Edit` explicitamente na projeção RAP.  
**Por quê:** em `strict(2)` com `use draft`, o framework exige `Edit` na projeção; sem isso o BDEF não compila. O controle de edição da segunda tela continua restrito por ausência de `use update` em `ZC_S2M_MATERIAIS_COMPATIVEIS`.

---

### 10. `ZC_S2M_PO_COMP_MONITOR.asddlx` *(objeto existente, ajustado)*
Metadata Extension da tela inicial já existente no baseline. Nesta CR, foi ajustada para garantir `@UI.lineItem` dos campos de código/nome do produto da ordem e nome do componente.

---

### 11. `ZC_S2M_MATERIAIS_COMPATIVEIS.asddlx` *(objeto existente, ajustado)*
Metadata Extension da segunda tela já existente no baseline. Nesta CR, foi ajustada para seleção única (`@UI.selectionMode: #SINGLE`) e inclusão de `MaterialName` nas colunas.

---

## Após ativar tudo

Limpar o buffer manualmente para garantir que os dados antigos não persistam:
```sql
DELETE FROM ztbs2m_ordem.
DELETE FROM ztbs2m_mat_compa.
```
Depois abrir o app — o buffer é repopulado automaticamente pelo SADL exit na primeira abertura.
