# Monitor MDF-e — ZMDFE

## Visão Geral

O **Monitor MDF-e** é uma solução ABAP customizada para emissão, envio e controle do **Manifesto Eletrônico de Documentos Fiscais (MDF-e)** no SAP. Integra-se ao DRC (Documento de Registro de Contribuinte) via classe padrão `CL_NFE_CLOUD_MDFE_PROCESSOR`, persiste o ciclo de vida do documento em tabelas Z e exibe um monitor ALV com semáforo de status.

**EF de Referência:** EF V1 (base) + EF V2 (prioridade — campos de pedágio, seguro, JSON reformatado)

---

## Objetos ADT a Criar no SAP

| Objeto                         | Tipo           | Descrição                                              |
|-------------------------------|----------------|--------------------------------------------------------|
| `ZMDFE_STATUS`                 | Tabela DDIC    | Status e controle do MDF-e                            |
| `ZMDFE_NFKEYS`                 | Tabela DDIC    | Chaves de acesso NF-e vinculadas ao MDF-e              |
| `ZCL_MDFE_MONITOR`             | Classe ABAP    | Lógica de negócio (select, criar, enviar, consultar…) |
| `ZMDFE`                        | Report (PROG/P)| Entry point / Module Pool (telas 100, 200)            |
| `ZEDO_FORM_MDFe`               | Adobe Form     | Formulário de impressão (stub — implementar separado) |
| Transação `ZMDFE`              | TRAN           | Acesso ao report via Menu                              |
| Status GUI `STATUS_100`        | Menu Painter   | Botões: CRIAR, ENVIAR, CONSULTAR, ENCERRAR, CANCELAR, IMPRIMIR, ATUALIZAR |
| Status GUI `STATUS_200_CRE/EDT/DSP` | Menu Painter | Botões: ADD_NF, DEL_NF, SALVAR, BACK              |

---

## Arquitetura

```
Usuário → Transação ZMDFE → Report ZMDFE (Module Pool)
               │
               ├── Tela 100 (Monitor ALV)
               │      └── ZCL_MDFE_MONITOR→select_data()  ←─ J_1BNFDOC + ZMDFE_NFKEYS + ZMDFE_STATUS
               │
               └── Tela 200 (Detalhe / Criação)
                      ├── ZCL_MDFE_MONITOR→create_mdfe()   ─→ [stub] BAPI_J_1B_NF_CREATEFROMDATA
                      │                                      ─→ ZMDFE_STATUS + ZMDFE_NFKEYS + LOGBR_NF_TEXTS
                      ├── ZCL_MDFE_MONITOR→send_mdfe()     ─→ CL_NFE_CLOUD_MDFE_PROCESSOR→SEND_REQUEST_JSON
                      ├── ZCL_MDFE_MONITOR→consult_mdfe()  ─→ DRC (stub)
                      ├── ZCL_MDFE_MONITOR→close_mdfe()    ─→ DRC evento encerramento (stub)
                      ├── ZCL_MDFE_MONITOR→cancel_mdfe()   ─→ DRC evento cancelamento (stub)
                      └── ZCL_MDFE_MONITOR→print_mdfe()    ─→ Adobe Form ZEDO_FORM_MDFe (stub)
```

---

## Telas

### Tela 01 — Selection Screen

| Bloco | Campo      | Tipo          | Descrição                    |
|-------|-----------|---------------|------------------------------|
| B1    | `S_BUKRS`  | SELECT-OPTIONS | Empresa (J_1BNFDOC-BUKRS)   |
| B1    | `S_BRANCH` | SELECT-OPTIONS | Local de negócio             |
| B1    | `S_DOCNUM` | SELECT-OPTIONS | Nº Documento NF-e            |
| B1    | `S_NFNUM`  | SELECT-OPTIONS | Nº NF-e                      |
| B1    | `S_SERIES` | SELECT-OPTIONS | Série NF-e                   |
| B1    | `S_CREDAT` | SELECT-OPTIONS | Data emissão NF-e            |
| B2    | `S_CHAVE`  | SELECT-OPTIONS | Chave acesso NF-e (44 chars) |
| B2    | `S_MDFNUM` | SELECT-OPTIONS | Nº MDF-e                     |
| B2    | `S_MCRDAT` | SELECT-OPTIONS | Data emissão MDF-e           |
| B3    | `P_PEND`   | CHECKBOX       | Exibir Pendentes / Erros     |
| B3    | `P_ENC`    | CHECKBOX       | Exibir Encerrados            |

### Tela 100 — Monitor ALV

Grid ALV com semáforo (`STATUS_ICON`) e botões no GUI-Status `STATUS_100`:
`CRIAR` · `ENVIAR` · `CONSULTAR` · `ENCERRAR` · `CANCELAR` · `IMPRIMIR` · `ATUALIZAR`

**Colunas:** Status / Nº MDF-e / Série / Empresa / Local / Data / UF Orig. / UF Dest. / Placa / Motorista / Chave / Protocolo / Peso / Valor / Última Mensagem

### Tela 200 — Detalhe / Criação

Sub-ALV com chaves NF-e vinculadas. Botões: `ADD_NF` · `DEL_NF` · `SALVAR` · `BACK`.

**Modos:** `C` = Criar · `E` = Editar · `D` = Exibir (controlados por `GV_MODE_200`)

---

## Tabelas Z

### ZMDFE_STATUS

| Campo          | Tipo DDIC       | Descrição                               |
|---------------|-----------------|------------------------------------------|
| `MANDT`        | MANDT           | Mandante (chave)                         |
| `MDFE_NUMBER`  | J_1BDOCNUM      | Número do MDF-e (chave)                  |
| `BUKRS`        | BUKRS           | Empresa                                  |
| `BRANCH`       | J_1BBRANCH      | Local de negócio                         |
| `SERIES`       | J_1BSERIES      | Série MDF-e                              |
| `DOC_STATUS`   | CHAR1           | 1=Pend 2=Env 3=Aut 4=Erro 5=Enc 6=Canc  |
| `ACCESS_KEY`   | J_1BCHVNFE      | Chave de acesso MDF-e (44 dígitos)       |
| `NPROT`        | J_1B_AUTHCODE   | Protocolo de autorização SEFAZ           |
| `UUID_DRC`     | SYSUUID_C32     | UUID da comunicação DRC                  |
| `CREDAT`       | ERDAT           | Data de criação                          |
| `CREZET`       | ERZET           | Hora de criação                          |
| `ERNAM`        | ERNAM           | Criado por                               |
| `LAST_MSG`     | BAPI_MSG        | Última mensagem de retorno SEFAZ         |
| `UF_ORIG`      | REGIO           | UF Origem (de ADRC-REGION via filial)    |
| `MUN_ORIG`     | CHAR7           | Município Origem (últimos 7 de TAXJURCODE)|
| `UF_DEST`      | REGIO           | UF Destino (J_1BNFDOC-REGIO)            |
| `MUN_DEST`     | CHAR7           | Município Destino (últimos 7 de TXJCD)  |
| `CEP_CARGA`    | CHAR8           | CEP Carga (ADRC-POST_CODE1)             |
| `CEP_DESCAR`   | CHAR8           | CEP Descarga (J_1BNFDOC-PSTLZ)         |
| `BRGEW`        | BRGEW           | Peso bruto total                         |
| `GEWEI`        | GEWEI           | Unidade de peso                          |
| `NFTOT`        | ABGRS           | Valor total da carga                     |
| `MOTORISTA`    | CHAR20          | Nome do motorista                        |
| `CPF_MOTOR`    | CHAR11          | CPF motorista (somente números)          |
| `PLACA`        | CHAR7           | Placa veículo (sem traço)                |
| `RNTRC`        | CHAR20          | RNTRC do transportador                   |
| `PED_CNPJ_RESP`| STCD1           | CNPJ responsável pelo pedágio (V2)       |
| `PED_CNPJ_FORN`| STCD1           | CNPJ fornecedor do pedágio (V2)          |
| `PED_COMPROV`  | CHAR20          | Nº comprovante pedágio (V2)              |
| `SEGURADORA`   | CHAR60          | Nome da seguradora (V2)                  |
| `APOLICE`      | CHAR30          | Nº da apólice de seguro (V2)             |
| `JSON_ENVIADO` | SSTRING         | Payload JSON enviado (auditoria)         |

### ZMDFE_NFKEYS

| Campo         | Tipo DDIC   | Descrição                               |
|--------------|-------------|------------------------------------------|
| `MANDT`       | MANDT       | Mandante (chave)                         |
| `MDFE_NUMBER` | J_1BDOCNUM  | FK → ZMDFE_STATUS-MDFE_NUMBER (chave)   |
| `ITEM_NUM`    | NUMC3       | Sequencial do item: 001, 002… (chave)   |
| `ACCESSKEY`   | J_1BCHVNFE  | Chave de acesso NF-e (44 dígitos)        |
| `BUKRS`       | BUKRS       | Empresa                                  |
| `BRANCH`      | J_1BBRANCH  | Local de negócio                         |
| `DOCNUM`      | J_1BDOCNUM  | Nº documento NF-e (J_1BNFDOC-DOCNUM)   |
| `NFENUM`      | CHAR9       | Nº NF-e                                  |
| `SERIES`      | J_1BSERIES  | Série NF-e                               |

---

## Classe ZCL_MDFE_MONITOR

### Métodos Públicos

| Método             | Responsabilidade                                                                    |
|-------------------|-------------------------------------------------------------------------------------|
| `CONSTRUCTOR`      | Instancia `CL_NFE_CLOUD_MDFE_PROCESSOR` (MO_PROC)                                 |
| `SELECT_DATA`      | Lê J_1BNFDOC com ranges dinâmicas → vincula a ZMDFE_STATUS via ZMDFE_NFKEYS.DOCNUM → monta TT_MONITOR com semáforo |
| `CREATE_MDFE`      | Valida campos obrigatórios → stub BAPI_J_1B_NF_CREATEFROMDATA → persiste ZMDFE_STATUS + ZMDFE_NFKEYS + LOGBR_NF_TEXTS |
| `SEND_MDFE`        | Lê tabelas Z → monta JSON → chama MO_PROC→SEND_REQUEST_JSON → atualiza status      |
| `CONSULT_MDFE`     | Consulta status DRC (stub) → atualiza ZMDFE_STATUS                                 |
| `CLOSE_MDFE`       | Valida status = Autorizado → envia evento encerramento DRC (stub) → status = 5     |
| `CANCEL_MDFE`      | Valida status ≠ Cancelado/Encerrado → envia cancelamento DRC (stub) → status = 6  |
| `PRINT_MDFE`       | Valida status = Autorizado → chama Adobe Form ZEDO_FORM_MDFe (stub)               |
| `READ_HEADER`      | SELECT SINGLE em ZMDFE_STATUS por MDFE_NUMBER                                      |
| `READ_NFKEYS`      | SELECT em ZMDFE_NFKEYS por MDFE_NUMBER, ordenado por ITEM_NUM                     |
| `GET_NFE_ACCESSKEY`| Concatena campos de J_1BNFE_ACTIVE para montar chave de 44 dígitos               |
| `GET_STATUS_ICON`  | (CLASS-METHOD) Retorna ícone semáforo: verde/amarelo/vermelho por status           |

### Métodos Privados

| Método              | Responsabilidade                                                                   |
|--------------------|------------------------------------------------------------------------------------|
| `BUILD_JSON_PAYLOAD`| Monta payload JSON conforme EF V2 Seção 5 (decimais sem milhar, placa sem traço, CEP 8 dígitos) |
| `SAVE_STATUS`       | MODIFY em ZMDFE_STATUS                                                            |
| `SAVE_NFKEYS`       | DELETE + INSERT em ZMDFE_NFKEYS (garantia de consistência)                        |
| `GET_BRANCH_GEO`    | Lê J_1BBRANCH → ADRC → extrai REGION, POST_CODE1 e TAXJURCODE[-7:] para município|
| `GET_DEST_GEO`      | Lê J_1BNFDOC → extrai REGIO, PSTLZ e TXJCD[-7:] para município destino           |
| `SAVE_INFCOMP`      | MODIFY em LOGBR_NF_TEXTS (txttyp='C') com texto complementar EF V2               |

### Constantes de Status

| Constante         | Valor | Significado   |
|------------------|-------|---------------|
| `GC_ST_PENDENTE`  | `1`   | Pendente      |
| `GC_ST_ENVIADO`   | `2`   | Enviado       |
| `GC_ST_AUTORIZADO`| `3`   | Autorizado    |
| `GC_ST_ERRO`      | `4`   | Erro          |
| `GC_ST_ENCERRADO` | `5`   | Encerrado     |
| `GC_ST_CANCELADO` | `6`   | Cancelado     |

---

## Regras Críticas do JSON (EF V2 Seção 5)

| Campo JSON              | Regra                                                        |
|------------------------|--------------------------------------------------------------|
| `totalQuantity`         | Decimal SEM separador de milhar: `1000.50` (não `1.000,50`) |
| `cargoTotalValue`       | Idem                                                         |
| `loadingPostalCode`     | Exatamente 8 dígitos com zeros à esquerda, sem traço        |
| `unloadingPostalCode`   | Idem                                                         |
| `vehicleInfo.plate`     | Sem traço (ex: `ABC1234`, não `ABC-1234`)                    |
| `conductor[].cpf`       | Somente números (11 dígitos)                                 |
| `environmentType`       | `1` = Produção · `2` = Homologação                          |
| `issuingType`           | Sempre `"1"`                                                 |
| `issuingState`          | UF de T001W-REGIO ou J_1BBRANCH-REGIO                       |

---

## Configurações SPRO Necessárias

| Atividade SPRO                                         | Path Aproximado                                         |
|-------------------------------------------------------|---------------------------------------------------------|
| Parametrização do DRC (URL, certificado, ambiente)    | NF-e → Configurações Gerais → DRC                       |
| Número de documento MDF-e (série/numeração)           | NF-e → Séries e Numeração → MDF-e                       |
| Configuração do local de negócio (J_1BBRANCH)         | NF-e → Local de Negócio                                 |
| Certificado digital para assinatura                   | NF-e → Certificados Digitais                            |
| Adobe Forms — ativação ZEDO_FORM_MDFe                 | Basis → Adobe Document Services                         |
| Objeto de autorização J_1BNFE (reaproveitar)          | Basis → Autorizações (mesmos de J1BNFE)                 |

---

## Ordem de Criação no ADT

```
1.  Domínios e Data Elements customizados (se necessário)
2.  ZMDFE_STATUS   – Tabela DDIC (CDS define table ou SE11)
3.  ZMDFE_NFKEYS   – Tabela DDIC (CDS define table ou SE11)
4.  ZCL_MDFE_MONITOR DEFINITION  – Criar classe com public section
5.  ZCL_MDFE_MONITOR IMPLEMENTATION – Adicionar implementação
6.  Ativar a classe (ABAPTest / check syntax)
7.  ZMDFE          – Criar report (PROG/P) com include Top/F01/PBO/PAI
8.  Criar telas 100 e 200 no Screen Painter
9.  Criar GUI-Status STATUS_100 / STATUS_200_CRE / STATUS_200_EDT / STATUS_200_DSP no Menu Painter
    – OK-codes: CRIAR, ENVIAR, CONSULTAR, ENCERRAR, CANCELAR, IMPRIMIR, ATUALIZAR
    – OK-codes tela 200: ADD_NF, DEL_NF, SALVAR, BACK
10. Criar transação ZMDFE (SE93) apontando para o report
11. Executar ativação final e testes em ambiente de Homologação
12. Criar Adobe Form ZEDO_FORM_MDFe (opcional — stub já referenciado)
```

---

## Diferenças EF V1 vs EF V2 Aplicadas

| Aspecto                          | EF V1                              | EF V2 (prioridade)                                          |
|---------------------------------|------------------------------------|--------------------------------------------------------------|
| **Vale Pedágio**                 | Não existia                        | Campos `PED_CNPJ_RESP`, `PED_CNPJ_FORN`, `PED_COMPROV`     |
| **Seguro**                       | Não existia                        | Campos `SEGURADORA`, `APOLICE`                               |
| **Criação do documento NF**      | Gravação direta em tabelas Z       | Stub `BAPI_J_1B_NF_CREATEFROMDATA` + `LOGBR_NF_TEXTS`      |
| **JSON – decimais**              | `STYLE = SIMPLE` (não determinístico) | `WRITE...NO-GROUPING` → sem separador de milhar garantido  |
| **JSON – placa**                 | Sem strip de traço                 | `REPLACE '-'` antes de montar JSON                           |
| **JSON – CEP**                   | Sem validação de dígitos           | Strip non-digits + padding zeros até 8 posições             |
| **Informações complementares**   | Não especificado                   | `save_infcomp` → LOGBR_NF_TEXTS tipo 'C'                   |
| **Vinculo NF-e → MDF-e**         | Lookup por BUKRS+BRANCH (impreciso)| Lookup via `ZMDFE_NFKEYS.DOCNUM` (exato)                    |
| **Ranges de filtro**             | `VALUE rseloption()` c/ empty → filtra tudo | Ranges dinâmicas (só adiciona quando não-inicial)  |

---

## Notas de Implementação

- Os métodos `CONSULT_MDFE`, `CLOSE_MDFE`, `CANCEL_MDFE` e `PRINT_MDFE` contêm **stubs documentados** — as chamadas reais ao DRC e ao Adobe Form precisam ser confirmadas no sistema antes de implementar.
- O método `SEND_MDFE` usa **Field Symbols** para processar o retorno genérico de `CL_NFE_CLOUD_MDFE_PROCESSOR→SEND_REQUEST_JSON` — confirmar a estrutura real de retorno antes de ativar em produção.
- A chamada `BAPI_J_1B_NF_CREATEFROMDATA` em `CREATE_MDFE` está como stub comentado — ativar apenas quando o fluxo de criação de NF via J1B1N for requerido.
- Autorização: reutilizar os mesmos objetos de autorização de `J1BNFE` (não criar novos).
