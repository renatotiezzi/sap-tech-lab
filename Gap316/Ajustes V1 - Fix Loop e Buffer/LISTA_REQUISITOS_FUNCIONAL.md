# Lista de Requisitos Funcionais — GAP 316
> Fonte: "Check list testes - GAP 316.xlsx" / "Check list testesV2- GAP 316.xlsx"  
> Extraído em: 05/06/2026 via análise de imagens das planilhas

---

## Estrutura da planilha

4 colunas principais: **Requisito | Processo | Erro | Ajuste a efetuar/Instrução**  
Colunas adicionais: Dt.Teste | Status  
3 abas: Sheet1 (checklist), Sheet2 (tela inicial - print), Sheet3 (segunda tela - print)

---

## Requisito 1 — Lógica de busca charcinternalid deve ser dinâmica (A_BATCHCHARCVALUE)

**Processo:** 6. Consultar A_BATCHCHARCVALUE  
**Erro:** `CASE <fs_grupo_mat>-charcinternalid` fixo (hardcoded WHEN '991' / '998' / '1031')

**Ajuste a efetuar:**  
Trocar o:
```
CASE <fs_grupo_mat>-charcinternalid.
  WHEN '991'
  WHEN '998'
  WHEN '1031'
```
Por busca dinâmica na CDS `I_ClfnCharcDesc` com os filtros:
- `LANGUAGE = 'P'`
- `CHARCDESCRIPTION = 'Grp Receita Mestre'`
- `Data_atual >= VALIDITYSTARTDATE`
- `Data_atual <= VALIDITYENDDATE`
- `ISDELETED = ''`

**Lógica esperada:**  
SE existir registro em `A_BATCHCHARCVALUE` E existir correspondência em `I_ClfnCharcDesc` via `CHARCINTERNALID` com os filtros acima → seguir com o processamento.  
Os valores 991/998/1031 são apenas os IDs atuais de "Grp Receita Mestre" — devem ser obtidos dinamicamente para não quebrar se mudarem.

**Contexto adicional (dado das imagens):**  
Material 30001500, Centro 4815 → pertence aos grupos 50000087, 50000097, 50000098, 50000104 via `A_MASTERRECIPEMATERIALASSGMT`.  
Grupos 50000087 é confirmado via `I_PRODUCTIONVERSION` (versão 0001, não bloqueada).  
`A_BATCHCHARCVALUE` com `CHARCVALUE = 50000087, CLASSTYPE = 023`.

---

## Requisito 2 — Tela inicial: incluir campos na grid

**Processo:** Tela inicial  
**Erro:** Falta de campos na grid principal

**Ajuste a efetuar:**

1. **Incluir código e nome do produto da ordem:**
   - `A_PROCESSORDER.MATERIAL`
   - `A_PROCESSORDER.MATERIALNAME`

2. **Incluir o nome do componente (material):**
   - `MARA.MAKTX`

3. **Mostrar apenas materiais com `MARA.ZZ1_GR_APROVEITAMENTO_PRD` diferente de zero/vazio**

**Contexto adicional (print da Sheet2):**  
URL: `https://vhilfws1wd01.sap.iconic.com.br:44380/sap/bc/adt/businessservices/odatav4/feap...`  
A grid mostra: Ordem de produção, Reserva, Item da res., Tipo de regist., Grupo de mercado, Material, Centro, Qtd.necessária, ID interno opera.  
Campos **faltando** visualmente: código/nome do produto da ordem, nome do componente (MAKTX).

---

## Requisito 3 — Segunda tela: ajustes de comportamento e campos

**Processo:** Segunda tela (detalhe da ordem / aba Materiais)  
**Erro:** (sem erro crítico — melhorias de UX e filtragem)

**Ajuste a efetuar:**

4. **Remover o botão "Editar"** — permitir marcar **apenas uma linha** e clicar no botão "Remarcar". A ação deve manter a quantidade da linha e aplicar a regra de mudança de material e lote do campo marcado.

5. **Filtrar depósitos:** exibir apenas os que têm `T001L.OIB_TNKASSIGN = 'T'`

6. **Incluir o nome do componente (material):**
   - `MARA.MAKTX`

**Contexto adicional (print da Sheet3):**  
Aba Materiais da ordem 1000625 exibe: Material, Lote, Centro, Grupo, Versão de prod., Data fim validade, Depósito, Numerador, QTD utiliz.livre.  
Exemplos de linhas: Material 31240500, grupos 50000060 e 50000081, depósito F001, versões 0001 e 0002.  
Campo MAKTX e filtro de depósito por OIB_TNKASSIGN estão ausentes.
