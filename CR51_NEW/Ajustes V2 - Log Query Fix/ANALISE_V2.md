# Ajustes V2 — Correção de Query LOG

## Problema Diagnosticado

**Sintoma:** List Report e Object Page não mudaram de comportamento após V1.

**Causa Raiz:**
1. `ZI_Q2C_LOG_DET` (child) está selecionando de `ztbq2c_log_mgr` sem aplicar filtro por `(Pedido, Bandeira)`
2. Quando OData navega para o child via composição, ele deveria aplicar filtro automático, mas:
   - A `association to parent` não é suficiente para filtrar
   - Precisa haver um `WHERE` explícito ou uma derivação de view que aplique o filtro

**Exemplo do problema:**
```
Parent: Pedido=P1, Bandeira=B1 (tem 3 logs nesta chave)
Child retorna: TODOS os 23 logs da tabela (ignora parent key)
  → Facet mostra misturado
  → "não aparece tudo que existe na LOG" da chave específica
```

## Solução V2

### Estratégia:
Criar um view intermediário que filtra por `(Pedido, Bandeira)` dinamicamente, depois ZI_Q2C_LOG_DET projeta esse view filtrado.

Mas como passar o parent key para o child em CDS?

**Opção A:** Usar `$session.user_param` (não existe)
**Opção B:** Usar metadados da associação para derivar (complexo)
**Opção C:** Deixar o BDEF/framework fazer o filtro (relied-upon behavior)

### Implementação V2:

Após testaria esta solução é realmente a seguinte: mudar ZI_Q2C_LOG_DET para que ele retorne APENAS registros que correspondem ao parent.

Mas em CDS puro, sem WHERE parâmetrico, não conseguimos filtrar dinamicamente.

**REAL SOLUTION:** O framework OData deveria fazer isso automaticamente quando você declara `association to parent` e `composition [0..*] of child`.

Se não está fazendo, pode ser:
1. BDEF não tem configuração correta
2. Service Binding não está republicado
3. Há um erro de sintaxe na declaração de composition

## Ações Necessárias:

1. ✅ **ZI_Q2C_LOG_SUM.bdef** — Verificar se `association _Detail` está mapeado como composition
2. ✅ **ZC_Q2C_LOG_SUM_APP.bdef** — Verificar declarações de `use association`
3. ✅ **Service Binding** — Republicar ZSB_Q2C_LOG_MGR_APP

## Teste de Validação:

Após ativar V2:
- List Report deve mostrar **1 linha por (Pedido, Bandeira)**
- Clicar em linha → Object Page com facet _Detail
- Facet deve mostrar **TODOS os logs daquela chave APENAS** (não misturado)
- Não há "drill-down" ao clicar em linha da facet

