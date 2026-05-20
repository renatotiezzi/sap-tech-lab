# ZFI_BOLETO_MONITOR_CONT — Boleto Monitor Continental

**EF:** DBR EF - BOLEPIX_BOLETO MONITOR_CONTINENTAL_V1  
**Tipo:** REPORT ABAP (4 INCLUDEs) + Classe ZCFI_BOLETO_BRCODE  
**Objetivo:** Selecionar itens em aberto de clientes (BSID), exibir em ALV e permitir **Preview**, **Print** e **Envio por Email** do boleto com QR Code PIX embutido.

---

## Estrutura dos Arquivos

```
Bolepix/
├── ZFI_BOLETO_MONITOR_CONT.txt      ← REPORT principal (3 INCLUDEs + START/END-OF-SEL)
├── ZFI_BOLETO_MONITOR_CONT_T01.txt  ← Tipos, constantes, dados globais, lcl_event_handler
├── ZFI_BOLETO_MONITOR_CONT_S01.txt  ← Tela de seleção (s_bukrs, s_budat, s_faedt, s_kunnr, s_belnr, s_bupla)
├── ZFI_BOLETO_MONITOR_CONT_F01.txt  ← Toda a lógica de negócio (FORMs)
├── ZCFI_BOLETO_BRCODE.txt           ← Classe ABAP para gerar payload BR Code / PIX (referência SE24)
└── Backup/
    ├── DBR EF - BOLEPIX_BOLETO MONITOR_CONTINENTAL_V1.docx  ← EF original
    ├── ZFILY_BOLETO_COBRANCA.XDP    ← Adobe Form source (ADS)
    ├── ZFILY_BOLETO_COBRANCA.XSD    ← Schema da interface do form
    └── SFPF_ZFILY_BOLETO_COBRANCA.XML  ← Form exported from SFP
```

---

## Fluxo de Execução

```
SE38 → ZFI_BOLETO_MONITOR_CONT
│
├─ START-OF-SELECTION
│   ├── f_seleciona_dados
│   │   ├── f_ler_parametros       → lê ZTFI_BOLETO_PARA (form name, subject, cc, body)
│   │   ├── f_seleciona_bsid       → BSID JOIN BSEG (itens abertos com dados do banco)
│   │   ├── f_calcula_vencimento   → NET_DUE_DATE_GET + filtro s_faedt
│   │   ├── f_seleciona_bkpf/kna1/adr6/t012/t012k/t012c/t001/but000/...
│   │   └── f_seleciona_log        → ZTFI_BOLETO_LOG (status do último processamento)
│   └── f_trata_dados              → monta gt_alv com status/ícones
│
└─ END-OF-SELECTION
    └── f_exibe_dados              → CL_SALV_TABLE com GUI status ZZ_GUI_MAIN
```

---

## Ações no ALV (GUI Status `ZZ_GUI_MAIN`)

O usuário seleciona uma ou mais linhas e clica em um dos 3 botões:

| Botão SAP | Código | Comportamento |
|-----------|--------|---------------|
| Preview   | `&ZPREVIEW` | Abre PDF do boleto no browser Adobe. **Não grava log, não atualiza ALV.** |
| Print     | `&ZPRINT`   | Abre PDF do boleto no browser Adobe. **Grava ZTFI_BOLETO_LOG. Atualiza ALV.** |
| E-mail    | `&EMAIL`    | Gera PDF como binário, envia via BCS (cl_bcs). **Grava log. Atualiza ALV.** |

### Variável global `gv_mode`
| Valor | Significado |
|-------|-------------|
| `'V'` | Preview — só exibe, sem side effects |
| `'P'` | Print — exibe + grava log |
| `'E'` | Email — captura PDF binário + envia + grava log |

---

## Geração do Boleto (Adobe Forms)

### Parâmetros FP por modo

| Modo | getpdf | preview | nodialog | noprint | Resultado |
|------|--------|---------|----------|---------|-----------|
| `'V'` / `'P'` | space | X | X | X | PDF abre no browser — **sem spool** |
| `'E'`          | X     | space | X | X | PDF retornado como XSTRING — sem browser |

**Form name** é lido da tabela `ZTFI_BOLETO_PARA` via parâmetro `FORM_NAME`.  
**Interface do form** (`ZFILY_BOLETO_COBRANCA`): estrutura `GTY_form_data` + xstring para QR Code PIX.

---

## Nosso Número / XREF3 — 4 Cenários

```
f_monta_form_data → lv_nosso_raw
│
├── 1° tentativa: ps_alv-xref3          (campo do ALV, do BSEG)
├── 2° tentativa: ls_bsid_form-xref3    (SELECT direto do BSID)
├── 3° tentativa: ls_bsid_form-anfbn    (referência ao doc. original)
│
└── Se ainda vazio E gv_mode = 'P'  ← Cenário 3
    └── f_assign_fchi_and_update_xref3
        ├── ENQUEUE FCHI
        ├── NUMBER_GET_NEXT  nr_range_nr='01'  object='FCHI'
        ├── DEQUEUE FCHI
        └── FI_DOCUMENT_CHANGE  FDNAME='XREF3'  NEWVAL=fchi_number
```

| Cenário | Situação | Ação |
|---------|----------|------|
| 1 | Primeira execução F110 | `ZFI_XREF3_UPDATE_FORM` (include em ZRFFOBR_A) popula XREF3 |
| 2 | Re-execução F110 (reprint) | XREF3 já populado → FORM retorna sem ação |
| 3 | **Primeiro print pelo Monitor (sem F110)** | XREF3 vazio → Monitor gera FCHI → atualiza BSEG-XREF3 |
| 4 | Reimpressão pelo Monitor | XREF3 já populado → não altera |

> **ATENÇÃO Cenário 3:** `gv_mode = 'P'` é a única ação que gera FCHI.  
> Preview (`'V'`) e Email (`'E'`) **não** alteram XREF3.

---

## PIX QR Code

Gerado por `f_gerar_qrcode_pix` usando a classe `ZCFI_BOLETO_BRCODE`:

```abap
lv_payload = zcfi_boleto_brcode=>build_brcode_payload(
  iv_txid  = lv_txid    " belnr + buzei, só alfanumérico, max 25
  iv_valor = ps_alv-dmbtr ).

cl_rstx_barcode_renderer=>qr_code(
  IMPORTING e_bitmap = cv_qrcode ).  " XSTRING para o campo do form
```

A classe lê os parâmetros de configuração PIX via `TVARVC` (tabela **STVARV**):
- `ZBOLETO_PIX_CHAVE` — chave PIX (CNPJ, UUID, email ou telefone)
- `ZBOLETO_PIX_NOME` — nome do beneficiário (max 25 chars, sem acentos, maiúsculas)
- `ZBOLETO_PIX_CIDADE` — cidade (max 15 chars, sem acentos, maiúsculas)

Se qualquer parâmetro estiver ausente → `build_brcode_payload` retorna `''` → `CHECK` pula geração do QR sem erro.

---

## Envio de Email (BCS)

`f_enviar_email` chama `f_gerar_pdf_boleto` (modo `'E'`) para obter o xstring do PDF,  
depois chama `f_send_email_bcs` que usa `cl_bcs` / `cl_document_bcs` / `cl_cam_address_bcs`.

- **Destinatário:** lido de `ADR6` (email default do cliente em `KNA1-ADRNR`)
- **CC:** configurado em `ZTFI_BOLETO_PARA` → parâmetro `EMAIL_CC_AR`
- **Assunto:** `ZTFI_BOLETO_PARA` → parâmetro `MAIL_SUBJECT`
- **Corpo:** `ZTFI_BOLETO_PARA` → parâmetro `MAIL_BODY`
- **Attachment:** PDF binário, tamanho correto via `SCMS_XSTRING_TO_BINARY` → `lv_length`
- **Fila:** SOST — `send_immediately = abap_true`

---

## Tabelas Custom

### `ZTFI_BOLETO_PARA` — Parâmetros do programa
| Campo | Tipo | Conteúdo esperado |
|-------|------|-------------------|
| `PARAM` | CHAR 30 | Nome do parâmetro |
| `VALUE1` | CHAR 255 | Valor principal |
| `VALUE2` | CHAR 255 | Valor complementar (reserva) |

Parâmetros usados:
| PARAM | Conteúdo |
|-------|----------|
| `FORM_NAME` | Nome do Adobe Form (ex: `ZFILY_BOLETO_COBRANCA`) |
| `MAIL_SUBJECT` | Assunto do email de boleto |
| `EMAIL_CC_AR` | Email em cópia fixa (AR/cobrança) |
| `MAIL_BODY` | Texto do corpo do email |

### `ZTFI_BOLETO_LOG` — Log de processamento
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `BUKRS` | BUKRS | Empresa |
| `BELNR` | BELNR_D | Documento contábil |
| `GJAHR` | GJAHR | Exercício |
| `BUZEI` | BUZEI | Posição do item |
| `PROC_TYPE` | CHAR 10 | `'PRINT'` ou `'EMAIL'` |
| `UNAME` | SYUNAME | Usuário |
| `ERDAT` | SYDATUM | Data |
| `ERZET` | SYUZEIT | Hora |
| `STATUS` | CHAR 1 | `'S'` = sucesso, `'E'` = erro |
| `MESSAGE` | CHAR 255 | Mensagem de resultado |

---

## Objetos SAP a Criar/Verificar

| Objeto | Tipo | Transação |
|--------|------|-----------|
| `ZFI_BOLETO_MONITOR_CONT` | Program | SE38 |
| `ZFI_BOLETO_MONITOR_CONT_T01` | Include | SE38 |
| `ZFI_BOLETO_MONITOR_CONT_S01` | Include | SE38 |
| `ZFI_BOLETO_MONITOR_CONT_F01` | Include | SE38 |
| `ZCFI_BOLETO_BRCODE` | Class | SE24 |
| `ZFILY_BOLETO_COBRANCA` | Adobe Form | SFP |
| `ZTFI_BOLETO_PARA` | Table | SE11 |
| `ZTFI_BOLETO_LOG` | Table | SE11 |
| `ZZ_GUI_MAIN` | GUI Status | SE41 (program `ZFI_BOLETO_MONITOR_CONT`) |
| `ZFI` | Message Class | SE91 |

---

## Dependências de Runtime

```
ZFI_BOLETO_MONITOR_CONT
    │
    ├── ZTFI_BOLETO_PARA        (parâmetros: form name, email, etc.)
    ├── ZTFI_BOLETO_LOG         (grava e lê histórico de processamento)
    ├── ZCFI_BOLETO_BRCODE      (classe PIX BR Code — SE24)
    ├── ZFILY_BOLETO_COBRANCA   (Adobe Form — SFP)
    ├── TVARVC                  (parâmetros PIX — STVARV)
    ├── FCHI number range       (objeto 'FCHI', intervalo '01' — transação FCHI)
    ├── FI_DOCUMENT_CHANGE      (atualiza BSEG-XREF3 — standard SAP)
    └── NET_DUE_DATE_GET        (cálculo data vencimento — standard SAP)
```

---

## Histórico de Mudanças

| Data | Descrição |
|------|-----------|
| Mai/2026 | Criação inicial — 4 INCLUDEs + ZCFI_BOLETO_BRCODE |
| Mai/2026 | Fix: Preview/Print/Email modes, BCS attachment size, PIX via classe, FCHI XREF3, sy-subrc DEQUEUE |
