# IMPLEMENTATION GUIDE – Parte 2: Serviço de Impressão de Certificados

## Visão Geral

`ZCL_FD5047_CERT_PRINT` é o serviço ABAP de impressão de certificados.  
É chamado pelo serviço de impressão do Kit de Documentos (FD 6083) passando o SHNUMBER do TD.

---

## Fluxo de Execução

```
FD 6083 → ZCL_FD5047_CERT_PRINT→print_for_transport_doc( iv_shnumber )
              │
              ├─ 1. OIGSI: SHNUMBER → DOC_NUMBER (remessas do TD)
              │         ⚠️ Verificar existência da tabela OIGSI no sistema
              │         (ver TECHNICAL_DECISIONS.md para alternativa VTTK/VTTS)
              │
              ├─ 2. LIPS: DOC_NUMBER → MATNR + WERKS + LGORT por item
              │
              ├─ 3. Para cada item único (MATNR+WERKS+LGORT):
              │      ZCL_FD5047_DMS_API→find_latest_certificate
              │         ├─ Encontrou → get_document_content → create_spool_from_pdf
              │         └─ Não encontrou → ev_success = abap_false, INTERROMPER
              │
              └─ 4. Retornar et_spools (lista de RSPOID) ao chamador FD 6083
```

---

## Regra de Bloqueio (confirmada em TECHNICAL_DECISIONS.md)

**Se qualquer item da remessa não tiver certificado → processo INTERROMPIDO.**  
`ev_success = abap_false` e `ev_message` descritivo são retornados ao chamador.  
Nenhum spool parcial é gerado.

---

## Integração com FD 6083

O chamador (Kit de Documentos) deve:

```abap
DATA lo_print TYPE REF TO zcl_fd5047_cert_print.
DATA lt_spools TYPE zcl_fd5047_cert_print=>tt_spool_result.
DATA lv_ok     TYPE abap_bool.
DATA lv_msg    TYPE string.

CREATE OBJECT lo_print.
lo_print->print_for_transport_doc(
  EXPORTING
    iv_shnumber = lv_shnumber
  IMPORTING
    et_spools   = lt_spools
    ev_success  = lv_ok
    ev_message  = lv_msg ).

IF lv_ok = abap_false.
  " Tratar bloqueio de impressão: certificado ausente
  RAISE EXCEPTION ... " ou logar e interromper o kit
ENDIF.

" Processar lt_spools: cada entrada tem o RSPOID de um certificado
LOOP AT lt_spools INTO DATA(ls_spool).
  " consolidar ls_spool-rspoid com os demais documentos do kit
ENDLOOP.
```

---

## Tabela OIGSI – Verificação Obrigatória

Antes de ativar, confirmar no sistema via SE11:
- `OIGSI` existe com campos `SHNUMBER` e `DOC_NUMBER`
- Se não existir: substituir nas queries da classe por `VTTK`/`VTTS` (ver TECHNICAL_DECISIONS.md)

---

## Gap Técnico: Geração de SPOOL a partir de PDF

O método `create_spool_from_pdf` contém um `TODO` explícito para a escrita dos bytes PDF no spool.

**Passo 1 (implementado):** `RSPO_OPEN_SPOOLREQUEST` abre a requisição → retorna `RSPOID`.  
**Passo 2 (⚠️ confirmar com BASIS):** Escrever os bytes PDF no spool aberto.

Candidatos a confirmar no sistema:
- `RSPO_WRITE_RAWDATA_TO_SPOOL`
- `CL_ABAP_SPOOL` (S/4HANA 1909+)
- Print via ADS (Adobe Document Services) com binding de destino

Após confirmação, substituir o bloco `TODO` no método `create_spool_from_pdf`.
