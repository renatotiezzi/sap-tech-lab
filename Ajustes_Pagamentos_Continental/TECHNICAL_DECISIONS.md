# Decisões Técnicas — Ajustes Pagamentos Continental

**Data:** 2026-05-14

---

## DT-01 — Interface da DMEEX Exit

**Decisão:** Usar o template `DMEE_EXIT_TEMPLATE_ABA` como base para `ZFI_DMEEX_EXIT_CNPJ`.

**Razão:** Este é o template padrão SAP para exits em árvores DMEEX de pagamento (tree type PAYM).  
O FM modelo `FI_PAYMED_EXIT_SAMPLE` **não existe** no sistema. Os templates oficiais são:

| FM Template | Interface | Uso |
|-------------|-----------|-----|
| `DMEE_EXIT_TEMPLATE` | básica | versões antigas |
| `DMEE_EXIT_TEMPLATE_ABA` | básica ABA | **usar este** |
| `DMEE_EXIT_TEMPLATE_EXTENDED` | estendida | acesso a outros nós da árvore |
| `DMEE_EXIT_TEMPLATE_EXTEND_ABA` | estendida ABA | se precisar ler outros nós |

**Interface `DMEE_EXIT_TEMPLATE_ABA` (confirmada via SE37):**
- `I_ITEM` é genérico (TYPE ANY) — cast para `DMEE_PAYM_IF_TYPE` para acessar `FPAYH`/`FPAYHX`/`FPAYP`
- Exporting: `O_VALUE`, `C_VALUE`, `N_VALUE`, `P_VALUE` — popular o que corresponde ao tipo do nó na árvore
- Não há `EXCEPTIONS` na interface — em vez de RAISE, usar RETURN para nó ficar vazio

**Referência:** SAP OSS Note 373145 (DMEE: enhanced interface for exit module)

---

## DT-02 — Fonte do CNPJ (Beneficiário)

**Decisão:** Usar `J_1BREAD_CGC_COMPANY` passando `FPAYH-ZBUKR` (empresa pagadora).

**Razão:** O campo 03.1 "Identification Number" no CNAB400 Febraban identifica o  
**beneficiário** (empresa enviando o arquivo ao banco). O CNPJ da empresa é obtido pelo  
FM padrão brasileiro `J_1BREAD_CGC_COMPANY`, o mesmo já usado em `ZFI_BOLETO_MONITOR_CONT`.

**Alternativa descartada:** Ler `LFA1-STCD1` (CNPJ do fornecedor) — este seria o CPF/CNPJ  
do pagador, não do beneficiário.

---

## DT-03 — Link PAYR → BSEG via ANFBN

**Decisão:** Usar `BSEG-ANFBN = PAYR-VBLNR` como chave de ligação.

**Razão:** `PAYR-VBLNR` contém o número do documento de fatura original (ex: 4400000715).  
`BSEG-ANFBN` na linha de pagamento aponta de volta para esse documento de referência.  
Portanto a query filtrando `ANFBN = PAYR-VBLNR` retorna o documento de compensação  
(pagamento) que deve ter seu XREF3 atualizado.

**Observação:** Como pode haver múltiplas posições (BUZEI) no documento de pagamento,  
o SELECT traz a primeira posição aberta (xref3 = space). Avaliar se é necessário atualizar  
todas as posições do mesmo documento.

---

## DT-04 — Idempotência via XREF3 = space

**Decisão:** Condição `AND xref3 = space` no SELECT dentro do FORM é a guarda principal  
contra regeneração de número em cenários 2 e 4.

**Razão:** Centralizar a regra em um único ponto evita duplicação de lógica. Se XREF3  
já está preenchido, o SELECT retorna `sy-subrc <> 0` e o FORM faz RETURN imediatamente,  
sem distinção entre cenário 2 (re-execução F110) ou cenário 4 (reimpressão monitor).

---

## DT-05 — Verificação adicional antes de NUMBER_GET_NEXT (Cenário 2)

**Decisão:** Em `ZRFFOBR_A` / `ZRFFOD__V`, adicionar verificação de XREF3 **antes**  
de chamar `NUMBER_GET_NEXT`, para evitar consumo desnecessário de intervalo FCHI.

**Razão:** O FORM `f_update_xref3_from_payr` já é idempotente (não re-atualiza XREF3  
se populado), mas o número FCHI **já teria sido gerado e consumido** caso a verificação  
venha apenas depois. A proteção deve ser antes da geração do número.

**Implementação:** Ver seção "Cenário 2" no IMPLEMENTATION_GUIDE.md.

---

## DT-06 — Cópia de RFFOBR_A e RFFOD__V vs. Enhancement Spot

**Decisão:** Copiar para ZRFFOBR_A / ZRFFOD__V.

**Razão:** Os programas precisam de modificação comportamental (adicionar lógica de  
geração e atualização de número), não apenas pontos de extensão. Programas Z permitem  
controle total do código e simplicidade de manutenção.

**Risco:** Atualizações SAP em RFFOBR_A/RFFOD__V não serão herdadas automaticamente.  
Avaliar periodicamente se há correções relevantes nos programas padrão.

---

## DT-07 — Interface de FI_DOCUMENT_CHANGE (confirmada)

**Decisão:** Usar `T_ACCCHG STRUCTURE ACCCHG` + `I_BUZEI` como IMPORTING direto.

**Interface real confirmada (via SE37):**
```
IMPORTING: I_BUKRS, I_BELNR, I_GJAHR, I_BUZEI (item direto)
TABLES:    T_ACCCHG STRUCTURE ACCCHG
EXCEPTIONS: NO_REFERENCE, NO_DOCUMENT, MANY_DOCUMENTS,
            WRONG_INPUT, OVERWRITE_CREDITCARD
```

**O que mudou vs. versão anterior:**
- `I_BUZEI` é passado como parâmetro IMPORTING direto — não dentro da tabela
- A tabela é `T_ACCCHG` do tipo padrão `ACCCHG`, com campos `FNAME` e `FVALUE`
- Não há tabela de retorno (BAPIRET2) — usar as exceptions declaradas
- Tipo custom `TY_FIELD_UPDATE` descartado — usar `ACCCHG` nativo

**Nota:** Verificar em `SE11 → ACCCHG` se os nomes dos campos no sistema são  
`FNAME`/`FVALUE` ou variam. A lógica de preenchimento é `FNAME = 'XREF3'`, `FVALUE = lv_chect`.
