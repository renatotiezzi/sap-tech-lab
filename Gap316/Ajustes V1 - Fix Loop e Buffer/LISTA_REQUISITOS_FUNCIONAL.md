# Lista de Requisitos Funcionais — GAP 316
> Fonte: "Check list testes - GAP 316.xlsx" (Check list testesV2- GAP 316.xlsx)  
> Extraído em: 05/06/2026

---

## Requisito 1 — Consultar A_BATCHCHARCVALUE (charcinternalid dinâmico)

**Processo:** 6. Consultar A_BATCHCHARCVALUE  
**Erro identificado:** CASE `<fs_grupo_mat>-charcinternalid` fixo (hardcoded WHEN '991' / '998' / '1031')

**Instrução:**  
Trocar o:
```
CASE <fs_grupo_mat>-charcinternalid.
  WHEN '991'
  WHEN '998'
  WHEN '1031'
```
Por buscar na CDS `I_ClfnCharcDesc`:
- `I_ClfnCharcDesc-LANGUAGE = 'P'`
- `I_ClfnCharcDesc-CHARCDESCRIPTION = 'Grp Receita Mestre'`
- `Data_atual >= VALIDITYSTARTDATE`
- `Data_atual <= VALIDITYENDDATE`
- `ISDELETED = ''`

SE existir registro na CDS `A_BATCHCHARCVALUE` E existir correspondência na CDS `I_ClfnCharcDesc` via `CHARCINTERNALID`, ENTÃO:
- SE `I_ClfnCharcDesc-LANGUAGE = 'P'`
- E `I_ClfnCharcDesc-CHARCDESCRIPTION = 'Grp Receita Mestre'`
- E `Data_atual >= VALIDITYSTARTDATE`
- E `Data_atual <= VALIDITYENDDATE`
- E `ISDELETED = ''`
- ENTÃO: seguir com o processamento

---

## Requisito 2 — Tela Inicial (campos faltando)

**Processo:** Tela inicial  
**Erro identificado:** Falta de campos

**Instrução:**

1. **Tela inicial — incluir código e nome do produto da ordem:**
   - `A_PROCESSORDER.MATERIAL`
   - `A_PROCESSORDER.MATERIALNAME`

2. **Tela inicial — incluir o nome do componente (material):**
   - `MARA.MAKTX`

3. **Tela inicial — mostrar apenas materiais com grupo diferente de zero:**
   - `MARA.ZZ1_GR_APROVEITAMENTO_PRD <> ''` (diferente de vazio/zero)

---

## Requisito 3 — Segunda Tela (ajustes de comportamento)

**Processo:** Segunda Tela  
**Erro identificado:** (sem erro — melhorias de comportamento)

**Instrução:**

4. **Remover o botão editar** — permitir marcar apenas uma linha e clicar no botão "Remarca". A ação irá manter a quantidade da linha e fazer a regra de mudar material e lote do campo de marcação.

5. **Filtrar apenas os depósitos onde `T001L.OIB_TNKASSIGN = 'T'`**

6. **Incluir o nome do componente (material):**
   - `MARA.MAKTX`
