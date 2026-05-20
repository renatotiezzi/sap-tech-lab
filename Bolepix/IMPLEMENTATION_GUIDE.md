# IMPLEMENTATION GUIDE — ZFI_BOLETO_MONITOR_CONT
**EF:** DBR EF - BOLEPIX_BOLETO MONITOR_CONTINENTAL_V1

Este guia documenta **tudo que precisa ser configurado no SAP** antes de executar o monitor de boletos.  
Sequência recomendada: da seção 1 até a 7 em ordem.

---

## 1. Tabelas Customizadas (SE11)

### 1.1 `ZTFI_BOLETO_PARA` — Parâmetros do programa

Criar com os campos:

| Campo | Tipo / Comprimento | Chave | Descrição |
|-------|--------------------|-------|-----------|
| `MANDT` | MANDT | ✅ | Client |
| `PARAM` | CHAR 30 | ✅ | Parameter name |
| `VALUE1` | CHAR 255 | | Value 1 |
| `VALUE2` | CHAR 255 | | Value 2 |

**Após criar a tabela, inserir as 4 linhas via SM30 / SE16N:**

| PARAM | VALUE1 | VALUE2 |
|-------|--------|--------|
| `FORM_NAME` | `ZFILY_BOLETO_COBRANCA` | *(nome exato do Adobe Form em SFP)* |
| `MAIL_SUBJECT` | `Boleto de Cobrança - {{ empresa }}` | *(texto livre)* |
| `EMAIL_CC_AR` | `cobranca@empresa.com.br` | *(email fixo em cópia — AR/Cobrança)* |
| `MAIL_BODY` | `Prezado cliente, segue em anexo o boleto...` | *(corpo do email)* |

> **ATENÇÃO:** O campo `FORM_NAME` precisa ter o nome **exato** do form ativo em SFP.  
> Se o form não existir ou não estiver ativo, a impressão não abrirá e nenhuma mensagem de erro clara será gerada.

---

### 1.2 `ZTFI_BOLETO_LOG` — Log de processamento

Criar com os campos:

| Campo | Tipo / Comprimento | Chave | Descrição |
|-------|--------------------|-------|-----------|
| `MANDT` | MANDT | ✅ | Client |
| `BUKRS` | BUKRS | ✅ | Company code |
| `BELNR` | BELNR_D | ✅ | Accounting document |
| `GJAHR` | GJAHR | ✅ | Fiscal year |
| `BUZEI` | BUZEI | ✅ | Line item |
| `PROC_TYPE` | CHAR 10 | | `PRINT` or `EMAIL` |
| `UNAME` | SYUNAME | | Processing user |
| `ERDAT` | SYDATUM | | Processing date |
| `ERZET` | SYUZEIT | | Processing time |
| `STATUS` | CHAR 1 | | `S` = success, `E` = error |
| `MESSAGE` | CHAR 255 | | Result message |

> **ATENÇÃO:** A chave tem 5 campos (MANDT+BUKRS+BELNR+GJAHR+BUZEI). Se o mesmo documento for processado mais de uma vez, o segundo `INSERT` vai falhar com DUPLICATE KEY. Considerar adicionar um campo de sequência (`SEQNR`) à chave se quiser manter o histórico completo de reimpressões.

---

## 2. TVARVC — Parâmetros PIX (transação STVARV)

Estes parâmetros são lidos pela classe `ZCFI_BOLETO_BRCODE`.  
Tipo deve ser **`P`** (Parameter) em todos.

| Nome (NAME) | Tipo | Valor de exemplo | Restrição do spec. BC |
|-------------|------|------------------|-----------------------|
| `ZBOLETO_PIX_CHAVE` | P | `00.000.000/0001-00` (CNPJ) ou UUID ou email | — |
| `ZBOLETO_PIX_NOME` | P | `CONTINENTAL SA` | **Máx 25 chars, sem acentos, maiúsculas** |
| `ZBOLETO_PIX_CIDADE` | P | `SAO PAULO` | **Máx 15 chars, sem acentos, maiúsculas** |

**Como manter (STVARV):**
1. Executar `STVARV`
2. Selecionar tipo `P`
3. Criar/alterar cada linha
4. Salvar e **ativar** (botão "Activate")

> **O que acontece se não estiver configurado?**  
> `build_brcode_payload` retorna string vazia → `CHECK lv_payload IS NOT INITIAL` pula a geração → o campo QR Code do boleto fica em branco.  
> **O boleto é gerado sem o QR Code PIX** (sem erro de runtime), mas o pagamento via PIX não funciona.

---

## 3. Intervalo de Números FCHI (transação FCHI)

Usado no Cenário 3: **primeiro print pelo Monitor sem execução prévia de F110**.

**Configuração:**
1. Acessar transação `FCHI`
2. Selecionar: `Empresa` + `House Bank (HBKID)` + `Account ID (HKTID)` do boleto
3. Verificar se existe o intervalo `01` configurado
4. Se não existir: criar intervalo `01` com faixa numérica adequada (ex: `0000000001` a `9999999999`)

O programa usa:
```abap
nr_range_nr = '01'
object      = 'FCHI'
```

> **ATENÇÃO:** Se o intervalo `01` não existir, `NUMBER_GET_NEXT` retorna `interval_not_found` e o boleto é gerado **sem nosso número** (xref3 = vazio).  
> O barcode e a linha digitável ficarão incorretos.

---

## 4. Classe ZCFI_BOLETO_BRCODE (SE24)

Criar a classe a partir do arquivo `ZCFI_BOLETO_BRCODE.txt` (pasta `Bolepix/`).

**Checklist de ativação:**
- [ ] Criar classe em SE24 com nome `ZCFI_BOLETO_BRCODE`
- [ ] Definição: `PUBLIC FINAL CREATE PUBLIC`
- [ ] Copiar todos os métodos (4): `build_brcode_payload`, `calc_crc16`, `tlv`, `read_tvarvc`
- [ ] Ativar (`Ctrl+F3`)
- [ ] Testar: `SE24 → ZCFI_BOLETO_BRCODE → Test` → chamar `build_brcode_payload` com iv_txid='TESTE001'

> A classe usa `BIT-XOR` para CRC-16-CCITT (poly=0x1021, init=0xFFFF).  
> **Não** usar a implementação antiga com loops manuais (`f_xor16`) — resultado incorreto.

---

## 5. Adobe Form (SFP)

O form **`ZFILY_BOLETO_COBRANCA`** deve estar ativo em SFP.  
Arquivos de referência na pasta `Bolepix/Backup/`:

| Arquivo | Uso |
|---------|-----|
| `ZFILY_BOLETO_COBRANCA.XDP` | Adobe LiveCycle Designer source |
| `ZFILY_BOLETO_COBRANCA.XSD` | Schema da interface |
| `SFPF_ZFILY_BOLETO_COBRANCA.XML` | Export completo de SFP (importar via SFP → Transport) |

**Interface esperada (ligação com F01):**
- Estrutura `GTY_form_data` (declarada em T01) passada via `IMPORTING` no FM gerado pelo form
- Campo `barcode` = string 44 dígitos (linha digitável numérica)
- Campo `qrcode` = XSTRING do bitmap PNG do QR Code PIX (gerado por `cl_rstx_barcode_renderer=>qr_code`)

---

## 6. GUI Status `ZZ_GUI_MAIN` (SE41)

Criar em SE41 no programa `ZFI_BOLETO_MONITOR_CONT` (ou em um include de status separado).

**Funções obrigatórias:**

| Código da função | Texto | Ícone sugerido |
|------------------|-------|----------------|
| `&ZPREVIEW` | `Preview` | `ICON_DISPLAY` |
| `&ZPRINT` | `Print` | `ICON_PRINT` |
| `&EMAIL` | `Send Email` | `ICON_MAIL_SEND` |

> **Atenção:** Os códigos devem ser **exatamente** `&ZPREVIEW`, `&ZPRINT`, `&EMAIL` — case-sensitive, com `&` no início. O event handler em `lcl_event_handler->on_user_command` usa `CASE e_salv_function` com esses valores literais.

---

## 7. Classe de Mensagens ZFI (SE91)

| Número | Texto | Uso |
|--------|-------|-----|
| `012` | `Nenhum dado encontrado para os critérios informados` | f_seleciona_bsid vazio |
| `013` | `Selecione ao menos uma linha antes de executar a ação` | botão clicado sem seleção |

---

## 8. Sequência de Ativação e Testes

### Ordem de ativação
1. SE11: Ativar `ZTFI_BOLETO_PARA` e `ZTFI_BOLETO_LOG`
2. SE91: Criar/verificar mensagens `ZFI` 012 e 013
3. SE24: Ativar classe `ZCFI_BOLETO_BRCODE`
4. SFP: Verificar/importar form `ZFILY_BOLETO_COBRANCA`
5. SE38: Ativar includes `_T01`, `_S01`, `_F01` e o program principal
6. SE41: Criar GUI status `ZZ_GUI_MAIN` com as 3 funções
7. SM30: Inserir as 4 linhas em `ZTFI_BOLETO_PARA`
8. STVARV: Inserir os 3 parâmetros TVARVC (PIX)
9. FCHI: Verificar/criar intervalo `01` para empresa + banco + conta

### Testes por funcionalidade

| Teste | O que verificar |
|-------|-----------------|
| **Seleção** | Tela inicial → resultado em ALV com itens BSID |
| **Status ícones** | Linhas com log existente mostram verde/vermelho |
| **Preview** | Clica botão → PDF abre no browser → ALV **não** muda status_proc |
| **Print** | Clica botão → PDF abre no browser → linha muda para ícone verde no ALV |
| **Email** | Clica botão → verificar SOST → email com PDF anexado |
| **PIX QR Code** | Abrir PDF → QR Code visível → testar com app de pagamento PIX |
| **Cenário 3** | Item sem XREF3 → Print → verificar FB03: XREF3 populado com FCHI |
| **Cenário 4** | Reimprimir → XREF3 não deve mudar |

---

## 9. Troubleshooting Rápido

| Sintoma | Causa provável | Onde verificar |
|---------|----------------|----------------|
| PDF não abre | `FORM_NAME` errado em ZTFI_BOLETO_PARA | SM30/SE16N: tabela ZTFI_BOLETO_PARA |
| QR Code PIX em branco | TVARVC não configurado | STVARV: ZBOLETO_PIX_CHAVE |
| Email não aparece em SOST | Destinatário sem email em ADR6 | SE16N: tabela ADR6 com ADDRNUMBER do cliente |
| XREF3 não populado no Cenário 3 | Intervalo FCHI '01' não configurado | Transação FCHI |
| ALV em branco | Nenhum item BSID para os critérios | Ampliar range de datas na seleção |
| Botão não executa nada | GUI Status sem as funções ou código errado | SE41: ZZ_GUI_MAIN |
| Dump CX_ROOT no QR Code | `cl_rstx_barcode_renderer` não disponível no sistema | Verificar basis — presente a partir de Basis 7.0 |
