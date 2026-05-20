# IMPLEMENTATION GUIDE – Parte 1: Fiori Upload e Gestão de Certificados

## Visão Geral

O aplicativo Fiori é desenvolvido no **SAP Business Application Studio (BAS)** como um app Fiori Elements (List Report + Object Page) usando OData V4 com backend RAP ou como app customizado freestyle.

Este guia cobre o backend ABAP (`ZCL_FD5047_CERT_SVC`) e a estrutura de serviço necessária.

---

## Objetos ABAP da Parte 1

| Objeto | Tipo | Descrição |
|--------|------|-----------|
| `ZCL_FD5047_CERT_SVC` | CLAS | Serviço de negócio: validações, upload, listagem, exclusão |

> `ZCL_FD5047_DMS_API` (pasta raiz) é a dependência de infraestrutura – deve estar ativa antes.

---

## Integração com Fiori (OData)

**Opção recomendada**: Expor `ZCL_FD5047_CERT_SVC` via **ABAP RESTful Application Programming Model (RAP)**:

1. Criar CDS View `ZI_FD5047_CERT` com dados dos certificados
2. Criar Behavior Definition com ações: `upload`, `delete`
3. Behavior pool chama `ZCL_FD5047_CERT_SVC`
4. Service Binding OData V4 `ZSB_FD5047_CERT`

**Alternativa**: Criar endpoint HTTP via `CL_REST_HTTP_HANDLER` para upload binário direto.

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
