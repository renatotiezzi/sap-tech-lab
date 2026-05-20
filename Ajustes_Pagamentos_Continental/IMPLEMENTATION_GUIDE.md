# Ajustes Pagamentos — Continental
## Implementation Guide

**Data:** 2026-05-14  
**Projeto:** Adaptações no meio de pagamento CNAB400 (F110 / Monitor Boletos)

---

## Visão Geral

Dois ajustes independentes, mas relacionados ao ciclo de pagamento via F110 + CNAB400:

| # | Ajuste | Objeto Principal |
|---|--------|-----------------|
| 1 | **DMEEX Exit — CNPJ no campo 03.1** | Function Module `ZFI_DMEEX_EXIT_CNPJ` |
| 2 | **Número FCHI → BSEG-XREF3** | FORM incluído em `ZRFFOBR_A` / `ZRFFOD__V` |

---

## Objetos a Criar / Configurar

| Objeto | Tipo | Ação |
|--------|------|------|
| `ZFI_DMEEX_EXIT_CNPJ` | Function Module | Copiar de `DMEE_EXIT_TEMPLATE_ABA` (SE37) para grupo `ZFIPAY` |
| `ZRFFOBR_A` | Report ABAP | Copiar de `RFFOBR_A` (SE38 → Copy) |
| `ZRFFOD__V` | Report ABAP | Copiar de `RFFOD__V` (SE38 → Copy) |
| `ZFI_XREF3_UPD` | Include ABAP | Criar como include dos reports acima |

> **Nota de transporte:** Todos os objetos devem ser alocados no mesmo TR do projeto.

---

## PARTE 1 — DMEEX Exit: CNPJ no campo 03.1

### Contexto

O nó `03.1 Identification Number` da árvore `Z_BR_FEBRABAN_CNAB400` está mapeado para  
`FPAYHX / REF01+1(14)` sem função exit. O objetivo é substituir esse mapeamento por uma  
função exit que retorne o CNPJ numérico da empresa pagadora (14 dígitos, sem pontuação).

### Fluxo

```
F110 → seleciona meio de pagamento
     → chama ZRFFOBR_A (ou ZRFFOD__V)
     → motor DMEEX processa Z_BR_FEBRABAN_CNAB400
     → para campo 03.1: chama ZFI_DMEEX_EXIT_CNPJ
     → exit lê CNPJ via J_1BREAD_CGC_COMPANY
     → retorna 14 dígitos numéricos
```

### Configuração na DMEEX

1. Transação `DMEEX` → formato `Z_BR_FEBRABAN_CNAB400` → **Change**
2. Selecionar nó `03.1 Identification Number`
3. Aba **Origem** → seção **Função exit**
4. Preencher campo `Função exit:` com `ZFI_DMEEX_EXIT_CNPJ`
5. **Salvar** → alocar no TR do projeto

> ⚠️ Após configurar a exit, o mapeamento de campo `FPAYHX / REF01+1(14)` ainda pode ficar  
> preenchido — a exit tem **prioridade**. Verificar comportamento na versão do sistema.

### Como criar o FM (passo a passo)

1. `SE37` → FM `DMEE_EXIT_TEMPLATE_ABA` → menu **Function Module → Copy**
2. Nome destino: `ZFI_DMEEX_EXIT_CNPJ` → confirmar grupo de funções (ex: `ZFIPAY`, criar se não existir)
3. Substituir o corpo do FM pelo código em `src/ZFI_DMEEX_EXIT_CNPJ.txt`
4. **Check → Activate**

### Interface do Function Module

A interface **real** do DMEEX é a do template `DMEE_EXIT_TEMPLATE_ABA` (confirmado via SE37):  

```
IMPORTING:
  VALUE(I_TREE_TYPE) TYPE DMEE_TREETYPE_ABA   " tipo da árvore (ex: PAYM)
  VALUE(I_TREE_ID)   TYPE DMEE_TREEID_ABA     " ID da árvore
  VALUE(I_ITEM)                               " genérico — cast para DMEE_PAYM_IF_TYPE
  VALUE(I_PARAM)
  VALUE(I_UPARAM)
EXPORTING:
  REFERENCE(O_VALUE)   " valor genérico
  REFERENCE(C_VALUE)   " texto
  REFERENCE(N_VALUE)   " numérico  ← usar para campo 03.1 (numérico)
  REFERENCE(P_VALUE)   " moeda
TABLES:
  I_TAB
```

> **Atenção:** `I_ITEM` é genérico. Para acessar os campos de pagamento (`FPAYH`, `FPAYHX`, `FPAYP`),  
> fazer cast: `ls_item TYPE dmee_paym_if_type. ls_item = i_item.`

> **Retorno:** popular `N_VALUE` se o nó 03.1 for tipo **N** na árvore, ou `C_VALUE` se tipo **C**.  
> Verificar o tipo do nó em `DMEEX → Z_BR_FEBRABAN_CNAB400 → nó 03.1 → aba Atributos`.

**Código:** ver `src/ZFI_DMEEX_EXIT_CNPJ.txt`

---

## PARTE 2 — Número FCHI → BSEG-XREF3

### Contexto

Quando a F110 gera o arquivo de pagamento CNAB400 (via RFFOBR_A / RFFOD__V), o SAP  
atribui um número sequencial do intervalo `FCHI` e grava em `PAYR-CHECT`.  
Este número é o **Nosso Número** do boleto.

O objetivo é que, ao gerar esse número, o sistema também popule `BSEG-XREF3` com o  
mesmo valor, usando a API `FI_DOCUMENT_CHANGE`. O XREF3 é lido pelo monitor de boletos  
(`ZFI_BOLETO_MONITOR_CONT`) como campo `Nosso Numero`.

### Ligação PAYR → BSEG

```
PAYR-ZBUKR  →  BSEG-BUKRS
PAYR-VBLNR  →  BSEG-ANFBN   (ANFBN = número do documento de referência/fatura)
PAYR-GJAHR  →  BSEG-GJAHR
```

A query para encontrar o documento contábil de pagamento:
```sql
SELECT belnr, buzei FROM bseg
 WHERE bukrs = payr-zbukr
   AND gjahr = payr-gjahr
   AND anfbn = payr-vblnr
   AND xref3 = space              " só processa se ainda não populado
```

### Cenários e Regras

| # | Situação | XREF3 antes | Ação |
|---|----------|-------------|------|
| 1 | **Primeira execução F110** | Vazio | Gerar FCHI interval → gravar PAYR-CHECT → chamar `FI_DOCUMENT_CHANGE` → populat XREF3 |
| 2 | **Re-execução F110 (instrução ao banco, ex: alteração de vencimento)** | Populado | **Não gerar** novo intervalo FCHI. Validar XREF3 ≠ space → pular lógica de geração |
| 3 | **Impressão pelo Monitor de Boletos (Tran. Z)** | Vazio | Pode gerar intervalo FCHI + chamar `FI_DOCUMENT_CHANGE` se XREF3 = space |
| 4 | **Reimpressão pelo Monitor de Boletos** | Populado | **Não gerar** novo intervalo FCHI. XREF3 já está preenchido → só imprimir |

> ⚠️ **Regra central:** XREF3 populado = número já atribuído = **nunca regerar intervalo**.

### Implementação nos Programs Z

#### Como copiar os programas

```
SE38 → código do programa (ex: RFFOBR_A) → menu Programa → Copiar
     → nome destino: ZRFFOBR_A
     → confirmar pacote / TR do projeto
Repetir para RFFOD__V → ZRFFOD__V
```

#### Onde inserir a chamada no código

1. Em `ZRFFOBR_A` / `ZRFFOD__V`, buscar por `NUMBER_GET_NEXT` com objeto `FCHI`  
   ou buscar pelo campo `CHECT` para localizar o ponto de atribuição do número.

2. Após a atribuição de `PAYR-CHECT`, inserir:
```abap
PERFORM f_update_xref3_from_payr USING payr.
```

3. O FORM `f_update_xref3_from_payr` deve ser adicionado via include `ZFI_XREF3_UPD`.

#### Cenário 2 — Re-execução F110 (sem regerar intervalo)

Na lógica de geração do número (antes de `NUMBER_GET_NEXT`), adicionar verificação:

```abap
" Cenário 2: Re-execução da F110 — não regerar intervalo se XREF3 já populado
SELECT SINGLE xref3 FROM bseg
  WHERE bukrs = @payr-zbukr
    AND gjahr = @payr-gjahr
    AND anfbn = @payr-vblnr
  INTO @DATA(lv_xref3_check).

IF sy-subrc = 0 AND lv_xref3_check IS NOT INITIAL.
  " Número já atribuído anteriormente — pular geração de intervalo FCHI
  CONTINUE.   " ou RETURN, conforme estrutura do loop
ENDIF.
" Continua com geração normal do número FCHI...
```

#### Cenário 3 — Monitor de Boletos (Tran. Z)

Em `ZFI_BOLETO_MONITOR_CONT` (ou successor), na rotina de impressão,  
antes de chamar a form de montagem do formulário:

```abap
" Cenário 3: Impressão pelo monitor — atribuir Nosso Número se ainda não existe
IF gs_alv-xref3 IS INITIAL.
  PERFORM f_assign_fchi_and_update_xref3 USING gs_alv-bukrs
                                               gs_alv-belnr
                                               gs_alv-gjahr
                                               gs_alv-buzei
                                    CHANGING gs_alv-xref3.
ENDIF.
" Cenário 4 (reimpressão): xref3 já populado → imprime normalmente
```

**Código dos FORMs:** ver `src/ZFI_XREF3_UPDATE_FORM.txt`

---

## Configuração SAP Necessária

### 1 — Intervalo de Numeração FCHI

Verificar/criar o intervalo de numeração:
- Transação `FCHI` → Intervals → confirmar que existe intervalo para a combinação  
  `Empresa / Banco / Conta / Meio de pagamento` usada pela Continental.

### 2 — Variante F110

- Verificar que a variante de impressão da F110 aponta para `ZRFFOBR_A` (ou `ZRFFOD__V`)  
  ao invés dos programas padrão.
- Menu: `FBZP → Meios de Pagamento → País BR → escolher método → campo "Programa RFFO"`

### 3 — Árvore DMEEX

- Confirmar que a árvore `Z_BR_FEBRABAN_CNAB400` está ativa no sistema.
- Após salvar o exit no campo, fazer **Ativar** a árvore.

---

## Checklist de Testes

### Teste Cenário 1 — Primeira execução F110
- [ ] Criar proposta de pagamento para fornecedor com boleto
- [ ] Executar pagamento (F110 → run payment)
- [ ] Executar print (F110 → print)
- [ ] Verificar `PAYR` (SE16): CHECT preenchido
- [ ] Verificar `BSEG` (SE16): XREF3 = mesmo valor que PAYR-CHECT
- [ ] Verificar arquivo CNAB400: campo 03.1 = CNPJ da empresa (14 dígitos numéricos)

### Teste Cenário 2 — Re-execução (instrução ao banco)
- [ ] Com pagamento já executado (XREF3 populado), executar F110 novamente com nova instrução
- [ ] Verificar que XREF3 **não mudou** (manteve valor original)
- [ ] Verificar que não foi criado novo número FCHI para o mesmo documento

### Teste Cenário 3 — Impressão pelo Monitor
- [ ] Encontrar documento AP com XREF3 vazio
- [ ] Abrir monitor `ZFI_BOLETO_MONITOR_CONT` e imprimir
- [ ] Verificar que XREF3 foi populado automaticamente
- [ ] Verificar que o boleto impresso traz o Nosso Número correto

### Teste Cenário 4 — Reimpressão
- [ ] Documento com XREF3 populado → reimprimir no monitor
- [ ] Verificar que XREF3 **não mudou**
- [ ] Boleto impresso com o mesmo Nosso Número

---

## Referências

| Item | Detalhe |
|------|---------|
| Padrão CNAB400 Febraban | Arquivo: `Z_BR_FEBRABAN_CNAB400` (DMEEX) |
| Boleto Monitor existente | `ZFI_BOLETO_MONITOR_CONT` (Bolepix folder) |
| FM CNPJ empresa | `J_1BREAD_CGC_COMPANY` |
| FM modelo DMEEX exit | `FI_PAYMED_EXIT_SAMPLE` |
| Tabela numeração | `FCHI` (intervalo) + `PAYR` (resultado) |
| API atualização doc | `FI_DOCUMENT_CHANGE` |
