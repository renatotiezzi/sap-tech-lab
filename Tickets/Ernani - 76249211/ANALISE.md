# Ticket 76249211 — ZMENGEI: Unidade baseada em tabela Z (C4T IDOC + Form Print)

**Solicitante:** DART - Pauline Matthijs  
**Responsável:** Ernani Mainieri  
**Status:** Waiting for Customer  
**Prazo original:** 24/04/2026 ⚠️ (atrasado)

---

## 1. Entendimento do Negócio

A unidade de quantidade enviada ao sistema aduaneiro (campo `ZMENGEI` no IDOC C4T) está hardcoded ou derivada de forma incorreta. A necessidade é que essa unidade seja determinada dinamicamente com base em uma combinação de **Tipo de Material + Unidade Base de Medida** do artigo, conforme tabela de mapeamento fornecida pelo cliente.

Além disso, o mesmo mapeamento deve ser aplicado nos **formulários de impressão** (IV / ZIVF / YV / ZYVF), onde a unidade impressa de preço e quantidade também deve refletir a unidade derivada.

---

## 2. Objetos Técnicos Identificados (via screenshots)

| Objeto SAP | Valor | Tipo |
|---|---|---|
| Output Type C4T | `Z_BILLING_DOCUMENT_C4T` | IDOC |
| Output Type Form | `Z_BILLING_DOCUMENT_INVOIC_MM` | Printout (PRINT) |
| Adobe Form | `ZSD_SF_INVOICE` | SFP |
| Canal | `IDOC` e `PRINT` | Output Management |
| IDOC de exemplo | `0000000000131423` | WE02/WE05 |
| Billing Doc teste | `0090006875` | VF03 |

---

## 3. Tabela de Mapeamento (dados fornecidos pelo cliente)

| Tipo Material | Descr. | Unid. Base | Unid. ZMENGEI |
|---|---|---|---|
| ZBLK | Bulk | KG | PAL |
| ZBLK | Bulk | BAG | CAR |
| ZBLK | Bulk | CAR | CAR |
| ZBLK | Bulk | PC | CAR |
| ZCRB | Karton | PC | PC |
| ZCRB | Karton | KG | PC |
| ZCRB | Karton | M | ROL |
| ZFOI | Folie | PC | KG |
| ZFOI | Folie | KG | KG |
| ZING | Ingrediënten Menu | KG | KG |
| ZING | Ingrediënten Menu | L | KG |
| ZLBL | Labels | PC | BOX |
| ZPRP | Prepared Menu | CAR | CAR |
| ZPRP | Prepared Menu | KG | CAR |
| ZSLS | Sales - verpakt | CAR | CAR |
| ZSLS | Sales - verpakt | KG | PAL |
| ZSLS | Sales - verpakt | BAG | CAR |

---

## 4. Possíveis Caminhos — Onde o IDOC está sendo montado

Antes de abrir um debug "às cegas", execute estes atalhos na sequência. Cada um elimina incerteza e já te leva quase direto ao ponto.

---

### Caminho A — Partir do campo `ZMENGEI` (o mais rápido)

O campo `ZMENGEI` pertence a um segmento Z do IDOC. Esse segmento tem uma estrutura DDIC.

**Passo a passo:**
1. Tcode `SE11` → no campo de busca seleciona **"Data element"** → digita `ZMENGEI` → Enter
2. Dentro do Data Element → botão **"Where-Used List"** (ícone ou Ctrl+Shift+F3)
3. Marca o checkbox **"Structure"** → executa → vai listar a estrutura do segmento Z (ex: `E1ZC4T001`)
4. Clica duas vezes na estrutura → abre ela no SE11
5. De dentro da estrutura → **Where-Used** novamente → marca **"Program / Include"** → executa
6. Vai listar todos os programas/FMs que usam essa estrutura → o que tiver nome de FM de IDOC (`IDOC_OUTPUT_*` ou `Z*`) **é o ponto de montagem**
7. Clica duas vezes → SE38 abre direto no fonte → Ctrl+F em `ZMENGEI` → achou

---

### Caminho B — Partir do Output Type no Output Management (SPRO)

O output type `Z_BILLING_DOCUMENT_C4T` tem uma **Action Class** registrada. É ela que dispara tudo.

**Passo a passo detalhado:**

**B1. Achar a Action Class via SPRO**
1. Tcode `SPRO` → Enter
2. Menu: **SAP Customizing Implementation Guide**
3. Navegar: `Cross-Application Components → Output Management → Make Settings for Action Determination → Define Actions`
4. Na tela de seleção, campo **"Output Type"** → digitar `Z_BILLING_DOCUMENT_C4T` → Execute (F8)
5. Na lista que aparece → duplo clique na linha do C4T → vai aparecer a configuração da action
6. Campo **"Action Class"** → anota o nome (ex: `ZCL_BILLING_DOCUMENT_C4T`)

**B2. Abrir a Action Class no SE24**
1. Tcode `SE24` → digita o nome da Action Class anotada → Enter → **Display**
2. Aba **"Methods"** → procura o método `EXECUTE` (implementação da interface `IF_OACT_EXEC_ACTION`)
3. Duplo clique em `EXECUTE` → abre o código fonte
4. Dentro do `EXECUTE` → Ctrl+F por `IDOC` ou `ZMENGEI` ou `MENGEN` → vai achar a chamada ao FM de montagem ou a lógica direta

**B3. Alternativa mais rápida — BRF+**
1. Tcode `BRF+` → Enter
2. No campo de pesquisa (canto superior) → digitar `C4T` → Enter
3. Se aparecer algum objeto com `C4T` no nome → duplo clique → aba **"Actions"** → vai mostrar a classe configurada
4. Mesmo resultado que o SPRO, mas em menos cliques

> 💡 **Dica:** Se o SPRO não retornar nada para `Z_BILLING_DOCUMENT_C4T`, tenta pesquisar só por `C4T` (sem o prefixo) — às vezes o nome no Customizing é abreviado.

---

### Caminho C — Partir do Process Code do IDOC (WE41 / WE57)

Usado quando o IDOC foi construído no modelo clássico (pre-S/4 Output Management), sem Action Class.

**Passo a passo:**

**C1. Verificar o Message Type no IDOC**
1. Tcode `WE02` → campo **"IDoc Number"** → digita `0000000000131423` → Execute
2. Na estrutura em árvore → clica no nó raiz do IDOC → lado direito aparece o **Control Record**
3. Anota o campo **"Message Type"** (ex: `INVOIC`, `ZBILINV`, etc.)

**C2. Achar o FM via WE57**
1. Tcode `WE57` → Enter (lista todos os FMs registrados para IDOCs de saída)
2. Ctrl+F pelo Message Type anotado → vai aparecer o FM registrado
3. Anota o nome do FM (ex: `IDOC_OUTPUT_INVOIC` ou `ZIDOC_OUTPUT_C4T`)

**C3. Abrir o FM no SE37**
1. Tcode `SE37` → digita o nome do FM → **Display**
2. Ctrl+F por `ZMENGEI` → achou o ponto exato

---

### Caminho D — Pesquisa por nomenclatura (SE37 / SE24)

O desenvolvedor original quase sempre coloca o nome do output type ou do IDOC no nome do objeto.

**Passo a passo:**
1. Tcode `SE37` → campo Function Module → digita `*C4T*` → Execute → verifica os resultados
2. Tcode `SE24` → campo Class → digita `*C4T*` → Execute → verifica
3. Tcode `SE38` → campo Program → digita `*C4T*` → Execute → verifica
4. Para qualquer resultado que pareça relevante → abre → Ctrl+F em `ZMENGEI`

> ⏱️ Tempo médio: 2–3 minutos. Se o desenvolvedor usou `C4T` no nome, resolve aqui sem mais nada.

---

### Caminho E — ST05 (SQL trace durante o Send)

Último recurso se os anteriores não derem resultado.

**Passo a passo:**
1. Tcode `ST05` → botão **"Activate Trace"** (ativa para o próprio usuário)
2. Em outra janela: `Manage Output Items` → seleciona o item C4T → **Duplicate → Send**
3. Volta no `ST05` → botão **"Deactivate Trace"**
4. Botão **"Display Trace"** → na tela de seleção, filtra por **Table** = `EDIDD` ou `EDID4`
5. Execute → nos resultados, clica em qualquer linha → botão **"Call Stack"** (ou F6)
6. O call stack mostra a pilha de chamadas completa → o FM que fez o INSERT nos segmentos está ali

---

### Onde o `ZMENGEI` provavelmente está — Palpite técnico

Em cenários de billing IDOC com campos Z adicionados em segmentos de extensão, o padrão mais comum em S/4 é:

- **Enhancement Spot** sobre o FM padrão `IDOC_OUTPUT_INVOIC` (se o IDOC base é INVOIC)
- Ou um **Z FM** próprio registrado como process code substituto
- O campo `ZMENGEI` quase certamente é preenchido com a `MEINS` (unidade base) do item — hardcoded via `vbrp-meins` — sem qualquer conversão

**Hipótese mais provável:** existe um `ENHANCEMENT SECTION` dentro do FM de montagem do segmento de item, onde alguém fez `zseg-zmengei = vbrp-meins.` — e é exatamente ali que vamos plugar o lookup na `ZTMENGEI_MAP`.

---

## 5. O que precisa ser feito — Passo a Passo

### PASSO 1 — Localizar onde o IDOC C4T é montado

**Objetivo:** Achar o ponto exato onde o campo `ZMENGEI` do segmento Z do IDOC é preenchido.

**Como investigar:**
1. `VF03` → doc `0090006875` → Menu Saídas → ver Output Type `Z_BILLING_DOCUMENT_C4T`
2. `WE05` ou `WE02` → IDOC `0000000000131423` → ver estrutura de segmentos e achar o campo `ZMENGEI`
3. `SE11` → buscar a estrutura do segmento Z (ex: `E1ZBD_...` ou similar) → confirmar nome do campo
4. `SE19` ou `SPRO → Output Management` → achar a Action Class ou Processing Class do output type `Z_BILLING_DOCUMENT_C4T`
5. Debug: re-triggar o IDOC via `Manage Output Items → Duplicate → Send` e breakpoint na Action Class

**Resultado esperado:** Nome do método/FM onde `ZMENGEI` é preenchido → este é o ponto de enhancement.

---

### PASSO 2 — Criar tabela Z de mapeamento

**Nome sugerido:** `ZTMENGEI_MAP`  
**Delivery Class:** C (Customizing — permite SM30)

```
Estrutura:
  MANDT   : MANDT       (chave)
  MTART   : MTART       (chave — Tipo de Material)
  MEINS   : MEINS       (chave — Unidade Base)
  ZMENGEI_UNIT : MEINS  (Unidade para ZMENGEI)
```

- Criar View de Manutenção via `SE54` para acesso via `SM30`
- Carregar os 17 registros iniciais do cliente

---

### PASSO 3 — Implementar lógica no IDOC C4T

No ponto identificado no Passo 1, adicionar:

```abap
" Buscar MTART e MEINS do material do item de faturamento
SELECT SINGLE mtart meins FROM mara
  INTO (@lv_mtart, @lv_meins)
  WHERE matnr = <item>-matnr.

" Consultar tabela de mapeamento
SELECT SINGLE zmengei_unit FROM ztmengei_map
  INTO @lv_zmengei_unit
  WHERE mtart = @lv_mtart
    AND meins = @lv_meins.

IF sy-subrc = 0.
  <segmento_idoc>-zmengei = lv_zmengei_unit.
ELSE.
  " Fallback: manter unidade base (ou logar warning — CONFIRMAR COM CLIENTE)
  <segmento_idoc>-zmengei = lv_meins.
ENDIF.
```

---

### PASSO 4 — Ajustar Form Print (IV / ZIVF / YV / ZYVF)

#### O que o cliente quer exatamente

O ticket diz:
> *"printed unit of the price and quantity = the ZMENGEI unit"*

Ou seja: **tanto a quantidade impressa quanto o preço unitário** devem aparecer na unidade derivada da `ZTMENGEI_MAP` — a mesma usada no IDOC. Não é só trocar a label.

**Exemplo concreto:**
- Item com 1.000 KG, preço 2 EUR/KG → mapeamento diz: ZBLK + KG → PAL
- Form deve imprimir: **2 PAL**, preço **1.000 EUR/PAL** (assumindo 1 PAL = 500 KG)
- Isso exige conversão de UOM via `MARM` (fatores de conversão do material)

---

#### Análise dos 4 Forms

O ticket menciona IV, ZIVF, YV, ZYVF. Pelos screenshots, o form template identificado é `ZSD_SF_INVOICE` vinculado ao output type `Z_BILLING_DOCUMENT_INVOIC_MM`.

**Primeira tarefa: confirmar se os 4 usam o mesmo form ou forms separados:**
1. `VF03` → doc de teste → Menu **Saídas** → verificar todos os output types da fatura
2. Para cada output type (IV, ZIVF, YV, ZYVF) → ver qual Form Template está configurado
3. Se todos apontam para `ZSD_SF_INVOICE` → **1 ponto de mudança** (baixo risco)
4. Se são forms separados → **4 pontos de mudança** (esforço multiplica)

---

#### Como localizar o driver do form

O Adobe Form `ZSD_SF_INVOICE` é chamado por um FM driver (gerado automaticamente pelo SFP com prefixo `FP_`). Para achar:

1. `SFP` → digita `ZSD_SF_INVOICE` → **Display**
2. Anota o nome da **Interface** (ex: `ZSD_SF_INVOICE`) → aba **Interface** → ver parâmetros de entrada
3. `SE37` → pesquisa `FP_FUNCTION_MODULE_NAME` ou direto o FM gerado `FP_ZSD_SF_INVOICE` (nome padrão gerado pelo SFP)
4. **Where-Used** no nome do form → acha o programa/classe que chama o FM gerado → **esse é o driver**

O driver terá um loop sobre os itens da fatura onde os dados são preparados antes de chamar o form.

---

#### O que mudar no driver

No loop de itens, após montar os dados de cada linha, adicionar:

```abap
" Buscar unidade ZMENGEI para o item
DATA lv_zmengei_unit TYPE meins.
DATA lv_qty_converted TYPE menge_d.
DATA lv_price_converted TYPE brtwr.

SELECT SINGLE zmengei_unit FROM ztmengei_map
  INTO @lv_zmengei_unit
  WHERE mtart = @<item>-mtart
    AND meins = @<item>-meins.

IF sy-subrc = 0 AND lv_zmengei_unit <> <item>-meins.

  " Converter quantidade
  CALL FUNCTION 'UNIT_CONVERSION_SIMPLE'
    EXPORTING
      input    = <item>-fkimg        " quantidade faturada
      old_unit = <item>-meins        " unidade base
      new_unit = lv_zmengei_unit
      material = <item>-matnr
    IMPORTING
      output   = lv_qty_converted
    EXCEPTIONS
      OTHERS   = 1.

  IF sy-subrc = 0.
    " Recalcular preço unitário: preco_original / qty_convertida * qty_original
    lv_price_converted = <item>-netwr / lv_qty_converted.
    " Atualizar campos que vão para o form
    <item_form>-print_qty  = lv_qty_converted.
    <item_form>-print_unit = lv_zmengei_unit.
    <item_form>-print_price = lv_price_converted.
  ENDIF.

ELSE.
  " Sem mapeamento: mantém unidade original
  <item_form>-print_qty   = <item>-fkimg.
  <item_form>-print_unit  = <item>-meins.
  <item_form>-print_price = <item>-netwr / <item>-fkimg.
ENDIF.
```

> ⚠️ `UNIT_CONVERSION_SIMPLE` usa os fatores de conversão cadastrados em `MARM` por material. Se o material não tiver o fator PAL↔KG cadastrado, a conversão falha. Confirmar com o cliente se os materiais têm essa configuração.

---

#### Campos no layout do form (SFP)

Verificar no layout do `ZSD_SF_INVOICE` se os campos de unidade e quantidade estão ligados diretamente ao contexto (aí basta mudar o dado no driver) ou se estão com valores fixos no layout (aí precisa editar o form também via SFP → Layout).

---

#### Estimativa específica para o form

| Sub-atividade | Estimativa |
|---|---|
| Confirmar se 4 forms usam 1 ou mais templates | 1h |
| Localizar FM driver do ZSD_SF_INVOICE | 1h |
| Implementar lógica de conversão no driver | 3h |
| Verificar/ajustar layout SFP se necessário | 1–2h |
| Teste de impressão para cada tipo de material | 2h |
| **Subtotal form** | **8–9h** |

---

### PASSO 5 — Perguntas a confirmar com o cliente antes de iniciar form

1. **Fallback**: O que fazer quando não há entrada em `ZTMENGEI_MAP` para a combinação material+unidade?
2. **Preço no form**: O ticket diz "printed unit of price = ZMENGEI unit" — confirmar se o preço deve ser **recalculado por conversão de UOM** ou apenas a label muda (sem recalcular valor)
3. **Fatores de conversão**: Os materiais têm os fatores PAL↔KG, CAR↔KG etc. cadastrados em `MARM`? Se não, a conversão `UNIT_CONVERSION_SIMPLE` vai falhar
4. **4 forms**: IV, ZIVF, YV, ZYVF apontam para o mesmo form template `ZSD_SF_INVOICE` ou cada um tem o seu?
5. **Retroativo**: A correção se aplica a documentos já impressos ou apenas novos?

---

## 6. Estimativa de Esforço

| Atividade | Estimativa |
|---|---|
| Localizar método `IDOC_ITEM_EXTRA_GET_CONV_QUANT` e entender lógica atual | 1h |
| Criar tabela `ZTMENGEI_MAP` + SM30 view + carga dos 17 registros | 2h |
| Implementar lógica no método C4T | 2h |
| Confirmar quantos form templates existem (1 ou 4) | 1h |
| Localizar FM driver do `ZSD_SF_INVOICE` | 1h |
| Implementar conversão de quantidade + preço no driver | 3h |
| Verificar/ajustar layout SFP se campos estiverem fixos | 1–2h |
| Testes integrados (IDOC + form, vários tipos material) | 2h |
| **Total estimado** | **13–14h** |

> ⚠️ Se os 4 forms tiverem templates separados, adicionar +4–6h. Se o cliente confirmar que só precisa trocar a label (sem recalcular preço), reduz ~2h.

---

## 7. Estratégia de Teste

- `VF03` → doc `0090006875` → `Manage Output Items` → **Duplicate → Send**
- Verificar IDOC gerado em `WE02`: campo `ZMENGEI` deve ter unidade conforme tabela
- Imprimir form via output type `Z_BILLING_DOCUMENT_INVOIC_MM`: verificar quantidade e preço nos itens na unidade correta
- Testar ao menos 1 artigo de cada tipo (ZBLK, ZCRB, ZFOI, ZING, ZLBL, ZPRP, ZSLS)
