# IMPLEMENTATION GUIDE – Parte 1: Fiori Upload e Gestão de Certificados

## Visão Geral

O aplicativo Fiori é um **Fiori Elements List Report** (OData V4) com backend **RAP (Managed, strict 2)**.  
O PDF é enviado codificado em Base64 via OData action `UploadPdf`, que realiza upload no DMS cloud (SAP SDM/CMIS).

---

## Objetos ABAP da Parte 1

| Objeto | Tipo | Descrição |
|--------|------|-----------|
| `ZTFD5047_CERT` | TABL | Tabela persistente: metadados dos certificados |
| `ZFD5047_CERT_UPL_P` | DDLS (abstract) | Parâmetro da action UploadPdf (Description + PdfBase64) |
| `ZI_FD5047_CERT` | DDLS | CDS Interface view (root entity) |
| `ZI_FD5047_CERT` | BDEF | Behavior Definition interface (managed, strict 2) |
| `ZBP_I_FD5047_CERT` | CLAS | Behavior Pool – global class (stub) |
| `ZBP_I_FD5047_CERT` | CCIMP | Behavior Pool – local handler `lhc_cert` (lógica de negócio) |
| `ZC_FD5047_CERT` | DDLS | CDS Projection view (Fiori App) |
| `ZC_FD5047_CERT` | BDEF | Projection Behavior |
| `ZC_FD5047_CERT_MDE` | DDLX | Metadata Extension (anotações Fiori UI) |
| `ZSD_FD5047_CERT` | SRVD | Service Definition |
| `ZSB_FD5047_CERT` | SRVB | Service Binding (OData V4 – UI) |
| `ZCL_FD5047_CERT_SVC` | CLAS | Helper: validações e build_description |
| `ZCL_FD5047_DMS_API` | CLAS | Helper: operações REST com o DMS (pasta raiz) |

---

## Ordem de Ativação (RAP Stack — Fase 1)

```
1. ZTFD5047_CERT          → Criar tabela no SAP (SE11 / ADT)
2. ZFD5047_CERT_UPL_P     → Criar abstract entity (DDLS)
3. ZI_FD5047_CERT (DDLS)  → Criar interface CDS view
4. ZI_FD5047_CERT (BDEF)  → Criar behavior definition interface
5. ZBP_I_FD5047_CERT      → Criar behavior pool (global class + CCIMP)
6. ZC_FD5047_CERT (DDLS)  → Criar projection CDS view
7. ZC_FD5047_CERT (BDEF)  → Criar projection behavior
8. ZC_FD5047_CERT_MDE     → Criar metadata extension
9. ZSD_FD5047_CERT        → Criar service definition
10. ZSB_FD5047_CERT       → Criar service binding → Publicar (Publish)
```

> Dependências comuns (`ZCL_FD5047_DMS_API`, `ZCL_FD5047_CERT_SVC`) devem estar ativas antes do passo 5.

---

## Fluxo OData da Action UploadPdf

```
Fiori (FileUploader) → encode PDF em base64 →
  POST /Cert({UUID})/com.sap.gateway.srvd.zsb_fd5047_cert/UploadPdf
  Body: { "PdfBase64": "<base64>", "Description": "..." }

Backend:
  1. lhc_cert~upload_pdf
  2. Decode base64 → xstring  (cl_http_utility=>decode_x_base64)
  3. Valida magic bytes %PDF
  4. ZCL_FD5047_DMS_API→upload_certificate → objectId do DMS
  5. MODIFY ENTITY: DmsDocId + PdfSize + Description
  6. Retorna registro atualizado
```

---

## Integração com Fiori (OData)

---

## Validações implementadas em ZCL_FD5047_CERT_SVC

| Validação | Regra |
|-----------|-------|
| Formato arquivo | Somente PDF (verificação dos magic bytes: `%PDF`) |
| Campos obrigatórios | MATNR + WERKS + LGORT + DATA obrigatórios |
| Duplicidade | Verificação via `ZCL_FD5047_DMS_API→certificate_exists` antes do upload |
| Tamanho máximo | Configurável via TVARVC `ZFD5047_MAX_PDF_SIZE_KB` (padrão: 10240 KB = 10 MB) |

---

## Telas do App Fiori (referência EF)

### Tela 1 – Upload de Certificado
- Material (obrigatório, Value Help MATNR)
- Centro (obrigatório, Value Help WERKS)
- Depósito (obrigatório, Value Help LGORT)
- Data de Referência (obrigatório, DatePicker)
- Descrição (automática: `{MATNR}-{WERKS}-{LGORT}-{YYYYMMDD}`)
- Upload de arquivo PDF (drag & drop ou botão Selecionar)
- Botões: Enviar / Cancelar

### Tela 2 – Lista de Certificados
- Filtros: Material, Centro, Depósito, Período
- Colunas: Certificado (link PDF), Material, Centro, Depósito, Data, Ações (Excluir)

---

## Mensagens de Erro Implementadas

| Código | Texto |
|--------|-------|
| `ZFD5047_001` | Apenas arquivos PDF são aceitos. Selecione um arquivo válido. |
| `ZFD5047_002` | Todos os campos obrigatórios devem ser preenchidos (Material, Centro, Depósito, Data). |
| `ZFD5047_003` | Já existe um certificado para esta combinação Material/Centro/Depósito/Data. |
| `ZFD5047_004` | Erro ao realizar upload no DMS. Verifique o arquivo e tente novamente. |
| `ZFD5047_005` | Certificado excluído com sucesso. |
| `ZFD5047_006` | Tamanho máximo de arquivo excedido. |
