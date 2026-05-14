# Ajustes V2 — Implementação Log Query Fix

## O que mudou em relação a V1?

### V1 (Ajustes V01 - Log SUM)
- ZI_Q2C_LOG_LAST: `GROUP BY pedido, bandeira` + `max(datum), max(uzeit)`
- ZI_Q2C_LOG_SUM: `INNER JOIN` com ZI_Q2C_LOG_LAST e ztbq2c_log_mgr usando 4 colunas (Pedido, Bandeira, Datum, Uzeit)
- **Problema:** JOIN usava `last.LastUzeit = log.uzeit` — se múltiplas execuções no mesmo dia/hora, retornava resultado inconsistente ou vazio

### V2 (Ajustes V2 - Log Query Fix)
- ZI_Q2C_LOG_LAST: `GROUP BY pedido, bandeira` + `max(datum)` **APENAS** (sem uzeit)
- ZI_Q2C_LOG_SUM: `INNER JOIN` com ZI_Q2C_LOG_LAST usando **3 colunas** (Pedido, Bandeira, Datum)
- **Benefício:** Mais estável e compatible com old-release CDS
- **Tradeoff:** Se houver múltiplas execuções no mesmo dia, retorna a PRIMEIRA (não a última por hora)

---

## Arquivos de V2 (9 objetos + 1 helper + configuração)

```
ZI_Q2C_LOG_LAST.ddls.txt             (helper — max(datum) simplificado)
ZI_Q2C_LOG_SUM.ddls.txt              (root — INNER JOIN com helper)
ZI_Q2C_LOG_SUM.bdef.txt              (BDEF master/dependent + composition)
ZI_Q2C_LOG_DET.ddls.txt              (child — interface sem raiz)
ZBP_I_Q2C_LOG_SUM.clas.txt           (classe ABAP global)
ZBP_I_Q2C_LOG_SUM.clas.locals_imp.txt (lhc_log_sum + lhc_log_det handlers)
ZC_Q2C_LOG_SUM_APP.ddls.txt          (root projection para List Report + Object Page)
ZC_Q2C_LOG_SUM_APP.bdef.txt          (projection BDEF)
ZC_Q2C_LOG_SUM_APP_MDE.ddlx.txt      (root metadata — facet com _Detail)
ZC_Q2C_LOG_DET_APP.ddls.txt          (child projection — acesso via composition)
ZC_Q2C_LOG_DET_APP_MDE.ddlx.txt      (child metadata — sem facets, sem drill-down)
ZSD_Q2C_LOG_MGR_APP.srvd.txt         (service definition — expõe LogSum only)
```

---

## Plano de Ativação (idêntico ao V1)

### Fase 1: Interfaces Base
1. Ativar: **ZI_Q2C_LOG_LAST.ddls**
   - Helper view — sem BDEF, sem serviço
   - Dependência: nenhuma

2. Ativar: **ZI_Q2C_LOG_DET.ddls**
   - Child interface — sem BDEF ainda
   - Dependência: ZI_Q2C_LOG_LAST (via association indirect)

3. Ativar: **ZI_Q2C_LOG_SUM.ddls**
   - Root interface — usa ZI_Q2C_LOG_LAST via JOIN
   - Composição: _Detail → ZI_Q2C_LOG_DET
   - Dependência: ZI_Q2C_LOG_LAST, ZI_Q2C_LOG_DET

### Fase 2: Comportamentos
4. Ativar: **ZBP_I_Q2C_LOG_SUM.clas.txt**
   - Classe global para BDEF unmanaged
   - Dependência: ZI_Q2C_LOG_SUM, ZI_Q2C_LOG_DET

5. Ativar: **ZBP_I_Q2C_LOG_SUM.clas.locals_imp.txt**
   - Handlers locais (lhc_log_sum, lhc_log_det)
   - Dependência: ZBP_I_Q2C_LOG_SUM

6. Ativar: **ZI_Q2C_LOG_SUM.bdef.txt**
   - BDEF master/dependent
   - Dependência: ZBP_I_Q2C_LOG_SUM.clas.txt, ZI_Q2C_LOG_SUM.ddls, ZI_Q2C_LOG_DET.ddls

### Fase 3: Projeções OData
7. Ativar: **ZC_Q2C_LOG_DET_APP.ddls.txt**
   - Child projection — `as projection on ZI_Q2C_LOG_DET`
   - Dependência: ZI_Q2C_LOG_DET

8. Ativar: **ZC_Q2C_LOG_DET_APP_MDE.ddlx.txt**
   - Metadata para child (UI annotations sem facets)
   - Dependência: ZC_Q2C_LOG_DET_APP

9. Ativar: **ZC_Q2C_LOG_SUM_APP.ddls.txt**
   - Root projection — `as projection on ZI_Q2C_LOG_SUM`
   - Dependência: ZI_Q2C_LOG_SUM, ZC_Q2C_LOG_DET_APP

10. Ativar: **ZC_Q2C_LOG_SUM_APP.bdef.txt**
    - Projection BDEF — declarações de `use association`
    - Dependência: ZC_Q2C_LOG_SUM_APP, ZC_Q2C_LOG_DET_APP

11. Ativar: **ZC_Q2C_LOG_SUM_APP_MDE.ddlx.txt**
    - Root metadata — List Report + Object Page facet
    - Dependência: ZC_Q2C_LOG_SUM_APP

### Fase 4: Serviço e Binding
12. Ativar: **ZSD_Q2C_LOG_MGR_APP.srvd.txt**
    - Service definition — expõe `ZC_Q2C_LOG_SUM_APP as LogSum`
    - Dependência: ZC_Q2C_LOG_SUM_APP

13. **Republicar:** ZSB_Q2C_LOG_MGR_APP (service binding)
    - Dependência: ZSD_Q2C_LOG_MGR_APP

---

## Teste de Validação Esperado

Após completar todas as ativações:

✅ **List Report:**
- Exibe **1 linha por (Pedido, Bandeira)**
- Coluna "Última Execução — Data": data do ÚLTIMO record dessa chave
- Coluna "Última Etapa": etapa do ÚLTIMO record
- Coluna "Última Mensagem": mensagem do ÚLTIMO record
- **Sem drill-down ao clicar em linha da lista**

✅ **Object Page (ao clicar em linha):**
- Título: `Pedido | Bandeira`
- Facet "Histórico de Execuções":
  - **Tabela com TODOS os logs daquela chave**
  - Colunas: Data, Hora, Etapa, Mensagem, Usuário
  - **Sem drill-down ao clicar em linha de log**
  - Comportamento: somente leitura

✅ **Data Completeness:**
- Se Pedido P1 tem 3 execuções (14/05 09:00, 14/05 18:00, 14/05 18:46):
  - List Report mostra 1 linha com UltDatum=14/05, UltUzeit=18:46, UltEtapa/UltMensagem do 18:46
  - Object Page facet mostra 3 linhas: 09:00, 18:00, 18:46

---

## Troubleshooting

**Sintoma:** List Report ainda mostra múltiplas linhas por (Pedido, Bandeira)
- Verifique se ZI_Q2C_LOG_SUM_APP está ativo (não ZC_Q2C_LOG_MGR_APP)
- Verifique se ZI_Q2C_LOG_LAST foi ativado
- Verifique se service binding foi republicado

**Sintoma:** Object Page facet vazio ou mostra misturado
- Verifique se ZC_Q2C_LOG_DET_APP projection está ativa
- Verifique se _Parent association está declarado em ZI_Q2C_LOG_DET
- Verifique se `use association _Detail` está no ZC_Q2C_LOG_SUM_APP.bdef

**Sintoma:** "Não aparece tudo que existe na LOG"
- Verifique se Object Page está usando _Detail navigation (não outro app)
- Verifique tabela ztbq2c_log_mgr — confirm dados para aquela chave

---

## Notas de Implementação

- **Sem WHERE paramétrico:** O framework OData aplica filtro por (Pedido, Bandeira) automaticamente ao navegar para child
- **GROUP BY + MAX(datum):** Simplificado para evitar issues com múltiplos fields de agregação
- **Unmanaged BDEF:** Handlers vazios — leitura apenas, sem create/update/delete
- **Composição:** Non-root child entity — acessível SOMENTE via _Detail navigation

