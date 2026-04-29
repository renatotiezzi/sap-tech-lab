# Monitor MDF-e — ZMDFE

> **Empresa:** Continental Serviços do Brasil Ltda  
> **Sistema:** SAP S/4HANA  
> **EF de Referência:** EF V1 (base) + **EF V2 (prioridade)**  
> **Última revisão:** Abril/2026

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Arquitetura da Solução](#2-arquitetura-da-solução)
3. [Arquivos do Repositório](#3-arquivos-do-repositório)
4. [Data Elements Z — Pré-requisito](#4-data-elements-z--pré-requisito)
5. [Tabelas DDIC — Guia de Criação](#5-tabelas-ddic--guia-de-criação)
6. [Classe ZCL_MDFE_MONITOR](#6-classe-zcl_mdfe_monitor)
7. [Report ZMDFE — Module Pool](#7-report-zmdfe--module-pool)
8. [Guia de Implementação no ADT](#8-guia-de-implementação-no-adt)
9. [GUI Status — Menu Painter](#9-gui-status--menu-painter)
10. [Configurações SPRO](#10-configurações-spro)
11. [Regras Críticas do JSON](#11-regras-críticas-do-json)
12. [Ciclo de Vida do MDF-e](#12-ciclo-de-vida-do-mdf-e)
13. [Stubs — O Que Ainda Falta Ativar](#13-stubs--o-que-ainda-falta-ativar)
14. [Diferenças EF V1 vs EF V2](#14-diferenças-ef-v1-vs-ef-v2)

---

## 1. Visão Geral

O **Monitor MDF-e** é uma solução ABAP customizada para emissão, envio e controle do **Manifesto Eletrônico de Documentos Fiscais (MDF-e)** no SAP S/4HANA.

### O que a solução faz

- **Seleciona NF-es** emitidas (J_1BNFDOC) e identifica quais já possuem MDF-e criado
- **Cria MDF-e** agrupando chaves de acesso NF-e, dados do motorista/veículo, UF origem/destino, pedágio e seguro
- **Envia ao DRC** via `CL_NFE_CLOUD_MDFE_PROCESSOR→SEND_REQUEST_JSON` e recebe protocolo SEFAZ
- **Consulta**, **encerra** e **cancela** MDF-e junto ao DRC
- **Imprime DAMDFE** via Adobe Form `ZEDO_FORM_MDFe` (implementação separada)
- **Persiste** todo o ciclo de vida em tabelas Z com auditoria do JSON enviado

### Integração com o DRC

```
ABAP (ZCL_MDFE_MONITOR)
    ↓  build_json_payload()         → monta JSON conforme EF V2 Seção 5
    ↓  CL_NFE_CLOUD_MDFE_PROCESSOR  → comunica com o Cloud DRC da SAP
    ↓  SEFAZ                        → autorização / protocolo
    ↓  ZMDFE_STATUS                 → grava resultado + UUID + NPROT
```

---

## 2. Arquitetura da Solução

```
Usuário → Transação ZMDFE
               │
               ▼
          Report ZMDFE (Module Pool)
               │
    ┌──────────┴───────────┐
    │                      │
    ▼                      ▼
Tela 100                Tela 200
(Monitor ALV)      (Detalhe / Criação)
    │                      │
    ▼                      ▼
ZCL_MDFE_MONITOR       ZCL_MDFE_MONITOR
  select_data()          create_mdfe()
                         send_mdfe()
                         consult_mdfe()
                         close_mdfe()
                         cancel_mdfe()
                         print_mdfe()
```

### Fluxo de dados

```
J_1BNFDOC  ──────────────────────────────────────┐
J_1BNFE_ACTIVE → accesskey (44 dígitos) ─────────┤
J_1BBRANCH → ADRC → UF/CEP/Município origem ─────┤──→ ZCL_MDFE_MONITOR
                                                  │         │
                                          ZMDFE_NFKEYS       │
                                          ZMDFE_STATUS ←─────┘
                                          LOGBR_NF_TEXTS (infcomp)
```

---

## 3. Arquivos do Repositório

| Arquivo                    | Tipo           | Descrição                                                      |
|---------------------------|----------------|----------------------------------------------------------------|
| `ZMDFE_STATUS.txt`         | DDIC (CDS)     | Tabela de status e controle do MDF-e — colagem no ADT (DDL)   |
| `ZMDFE_NFKEYS.txt`         | DDIC (CDS)     | Tabela de chaves NF-e vinculadas — colagem no ADT (DDL)        |
| `ZCL_MDFE_MONITOR.txt`     | Classe ABAP    | Lógica completa: DEFINITION + IMPLEMENTATION juntos            |
| `ZMDFE.txt`                | Report/ModPool | Entry point: selection screen + telas 100 e 200               |
| `README.md`                | Documentação   | Este guia                                                      |

> **Nota:** Os arquivos `.txt` estão prontos para **copiar e colar** diretamente no ADT. Cada um representa um objeto SAP completo.

---

## 4. Data Elements Z — Pré-requisito

> **ATENÇÃO — Execute este passo ANTES de criar qualquer tabela.**  
> As tabelas `ZMDFE_STATUS` e a classe `ZCL_MDFE_MONITOR` referenciam data elements Z customizados.  
> Se os DEs não existirem no sistema, a **ativação das tabelas e da classe falhará** com erro de tipo desconhecido.

### Por que data elements Z e não `abap.char(N)` diretamente?

No ABAP e no DDIC, `TYPE c LENGTH N` / `abap.char(N)` é um tipo **genérico sem semântica**. Para campos que não existem em nenhuma tabela SAP padrão (calculados, de display ou específicos do processo), o correto é criar um **data element Z** com:
- Tipo base adequado e comprimento exato
- Label de campo (Short/Medium/Long) para aparecer corretamente nas telas e no ALV
- Possibilidade de adicionar ajuda de pesquisa depois

### Como criar um Data Element no SE11 (DDIC)

1. Executar transação **SE11**
2. Selecionar **Data type** → digitar o nome do DE → **Create**
3. Na tela seguinte selecionar **Data element** → Enter
4. Preencher:
   - **Short description**: conforme tabela abaixo
   - Aba **Data Type**: selecionar **Elementary Type**
     - **Predefined ABAP type**: `CHAR`
     - **Length**: conforme tabela
   - Aba **Field label**: preencher Short, Medium, Long, Heading
5. **Salvar** → **Activate (Ctrl+F3)**

> **Alternativa ADT (Eclipse):** botão direito no pacote → New → Other ABAP Repository Object → filtrar `Data Element` → preencher nome e descrição → Next → Finish → editar os campos conforme acima.

### Data Elements a Criar

| Nome DE          | Tipo Base | Comprimento | Descrição (Short Description SE11)         | Label sugerido (Medium)         |
|-----------------|-----------|-------------|--------------------------------------------|---------------------------------|
| `ZMDFE_MOTORISTA`| CHAR      | 20          | Monitor MDF-e: Nome do Motorista           | Nome Motorista                  |
| `ZMDFE_MUNCD`    | CHAR      | 7           | Monitor MDF-e: Cód. IBGE do Município (7 dígitos) | Cód. Município IBGE      |
| `ZMDFE_CEP`      | CHAR      | 8           | Monitor MDF-e: CEP sem traço (8 dígitos)  | CEP                             |
| `ZMDFE_COMPROV`  | CHAR      | 20          | Monitor MDF-e: Nº Comprovante Pedágio     | Comprovante Pedágio             |
| `ZMDFE_SEGURAD`  | CHAR      | 60          | Monitor MDF-e: Nome da Seguradora         | Seguradora                      |
| `ZMDFE_APOLICE`  | CHAR      | 30          | Monitor MDF-e: Número da Apólice          | Nº Apólice                      |
| `ZMDFE_ACCESSKEY`| CHAR      | 44          | Monitor MDF-e: Chave de Acesso NF-e/MDF-e (44 dígitos) | Chave de Acesso   |

> **`SYSUUID_C32`** (usado para o campo `UUID_DRC`) é um data element **SAP padrão** — já existe no sistema, não precisa criar.

### Ordem de criação obrigatória

```
[1] Criar os 7 DEs Z acima no SE11
        ↓
[2] Criar tabela ZMDFE_STATUS (referencia ZMDFE_MOTORISTA, ZMDFE_MUNCD, ZMDFE_CEP, etc.)
        ↓
[3] Criar tabela ZMDFE_NFKEYS (referencia ZMDFE_STATUS via chave estrangeira)
        ↓
[4] Criar classe ZCL_MDFE_MONITOR (referencia os DEs nos tipos locais)
        ↓
[5] Criar report ZMDFE, telas, GUI-Status e transação
```

---

## 5. Tabelas DDIC — Guia de Criação

### Como criar tabelas DDIC via ADT (DDL Source)

No ADT (Eclipse com plugins SAP), tabelas transparentes podem ser criadas como **DDL Source** com sintaxe `define table`. O conteúdo dos arquivos `.txt` já está nesse formato.

**Passos gerais:**
1. No ADT, botão direito no pacote Z → **New → Other ABAP Repository Object**
2. Filtrar por **"Database Table"** → Next
3. Informar o nome da tabela e descrição → Finish
4. O editor DDL abre — **apagar o conteúdo gerado** e colar o conteúdo do `.txt`
5. **Ctrl+S** para salvar → **Activate** (Ctrl+F3)

---

### 5.1 ZMDFE_STATUS

**Arquivo:** `ZMDFE_STATUS.txt`  
**Descrição:** Tabela principal de controle do MDF-e. Um registro por MDF-e. Armazena status, dados de autorização, dados do motorista/veículo, endereços, pedágio, seguro e o JSON enviado para auditoria.

#### Chave Primária

| Campo         | Tipo DDIC   | Comprimento | Obrigatório | Descrição              |
|--------------|-------------|-------------|-------------|------------------------|
| `MANDT`       | MANDT       | 3           | ✓           | Mandante               |
| `MDFE_NUMBER` | J_1BDOCNUM  | 9           | ✓           | Número do MDF-e        |

#### Campos de Identificação

| Campo    | Tipo DDIC  | Comprimento | Descrição         |
|---------|------------|-------------|-------------------|
| `BUKRS`  | BUKRS      | 4           | Empresa           |
| `BRANCH` | J_1BBRANC_ | 4           | Local de negócio  |
| `SERIES` | J_1BSERIES | 3           | Série do MDF-e    |

#### Status e Controle DRC

| Campo        | Tipo DDIC     | Comprimento | Descrição                                               |
|-------------|---------------|-------------|---------------------------------------------------------|
| `DOC_STATUS` | CHAR1         | 1           | Status: 1=Pend 2=Env 3=Aut 4=Erro 5=Enc 6=Canc         |
| `ACCESS_KEY` | ZMDFE_ACCESSKEY | 44          | Chave de acesso MDF-e (44 dígitos)                      |
| `NPROT`      | J_1BNFEAUTHCODE | 15          | Protocolo de autorização SEFAZ (J_1BNFDOC-AUTHCOD)         |
| `UUID_DRC`   | SYSUUID_C32     | 32          | UUID da comunicação com o DRC (DE SAP padrão)           |

#### Campos Administrativos

| Campo      | Tipo DDIC | Descrição                        |
|-----------|-----------|----------------------------------|
| `CREDAT`   | J_1BCREDAT  | Data de criação (J_1BNFDOC-CREDAT)   |
| `CREZET`   | J_1BCRETIM  | Hora de criação (J_1BNFDOC-CRETIM)   |
| `ERNAM`    | ERNAM     | Usuário criador (SY-UNAME)       |
| `LAST_MSG` | BAPI_MSG  | Última mensagem de retorno SEFAZ |

#### Dados Geográficos

Derivados automaticamente pelo método `GET_BRANCH_GEO` (filial) e `GET_DEST_GEO` (destino da NF-e).

| Campo       | Tipo  | Comprimento | Origem                                     |
|------------|-------|-------------|--------------------------------------------|
| `UF_ORIG`   | REGIO | 3           | `J_1BBRANCH → ADRC-REGION`                 |
| `MUN_ORIG`  | ZMDFE_MUNCD  | 7           | `ADRC-TAXJURCODE` últimos 7 dígitos (cód. IBGE) |
| `UF_DEST`   | REGIO | 3           | `J_1BNFDOC-REGIO`                          |
| `MUN_DEST`  | ZMDFE_MUNCD  | 7           | `J_1BNFDOC-TXJCD` últimos 7 dígitos (cód. IBGE) |
| `CEP_CARGA` | ZMDFE_CEP    | 8           | `ADRC-POST_CODE1` (8 dígitos, sem traço)   |
| `CEP_DESCAR`| ZMDFE_CEP    | 8           | `J_1BNFDOC-PSTLZ` (8 dígitos, sem traço)  |

#### Dados de Carga

| Campo   | Tipo  | Descrição                                  |
|--------|-------|--------------------------------------------|
| `BRGEW` | BRGEW_15 | Peso bruto total (J_1BNFDOC-BRGEW, QUAN 15,3)          |
| `GEWEI` | GEWEI    | Unidade de peso (ex: KG)                               |
| `NFTOT` | J_1BNFTOT| Valor total da carga (J_1BNFDOC-NFTOT, CURR 15,2)     |

#### Dados do Motorista e Veículo

| Campo      | Tipo  | Comprimento | Descrição                         |
|-----------|-------|-------------|-----------------------------------|
| `MOTORISTA`| ZMDFE_MOTORISTA        | 20          | Nome do motorista (entrada manual)|
| `CPF_MOTOR`| J_1BCPF                | 11          | CPF do motorista (J_1BNFDOC-CPF, NUMC11)|
| `PLACA`    | J_1B_VEHICLE_LIC_PL    | 7           | Placa do veículo (J_1BNFDOC-PLACA, CHAR7)|
| `RNTRC`    | J_1B_NAT_CARGO_CARRIER | 20          | RNTRC do transportador (J_1BNFDOC-RNTC)|

#### Vale Pedágio (V2)

| Campo          | Tipo  | Comprimento | Descrição                       |
|---------------|-------|-------------|---------------------------------|
| `PED_CNPJ_RESP`| J_1BCGC | 14          | CNPJ do responsável pelo pedágio (J_1BNFDOC-CGC, NUMC14)|
| `PED_CNPJ_FORN`| J_1BCGC | 14          | CNPJ do fornecedor do pedágio (J_1BNFDOC-CGC, NUMC14)  |
| `PED_COMPROV`  | ZMDFE_COMPROV| 20          | Nº do comprovante de pedágio    |

#### Seguro (V2)

| Campo       | Tipo  | Comprimento | Descrição              |
|------------|-------|-------------|------------------------|
| `SEGURADORA`| ZMDFE_SEGURAD| 60          | Nome da seguradora     |
| `APOLICE`   | ZMDFE_APOLICE| 30          | Número da apólice      |

#### Auditoria

| Campo          | Tipo    | Descrição                          |
|---------------|---------|-------------------------------------|
| `JSON_ENVIADO` | abap.sstring(5000) | Payload JSON completo enviado ao DRC (máx. 5000 chars)|

---

### 5.2 ZMDFE_NFKEYS

**Arquivo:** `ZMDFE_NFKEYS.txt`  
**Descrição:** Tabela filha de `ZMDFE_STATUS`. Armazena as chaves de acesso NF-e (44 dígitos) vinculadas a cada MDF-e. Relacionamento 1 MDF-e : N NF-es.

#### Chave Primária

| Campo         | Tipo DDIC  | Comprimento | Descrição                                |
|--------------|------------|-------------|------------------------------------------|
| `MANDT`       | MANDT      | 3           | Mandante                                 |
| `MDFE_NUMBER` | J_1BDOCNUM | 9           | FK → `ZMDFE_STATUS-MDFE_NUMBER`          |
| `ITEM_NUM`    | abap.numc(3) | 3           | Sequencial do item: 001, 002, 003…       |

#### Campos de Dados

| Campo      | Tipo DDIC  | Comprimento | Descrição                                              |
|-----------|------------|-------------|--------------------------------------------------------|
| `ACCESSKEY`| ZMDFE_ACCESSKEY | 44          | Chave de acesso NF-e (44 dígitos, somente números)    |
| `BUKRS`    | BUKRS      | 4           | Empresa                                                |
| `BRANCH`   | J_1BBRANC_ | 4           | Local de negócio                                       |
| `DOCNUM`   | J_1BDOCNUM | 9           | Nº documento NF-e (`J_1BNFDOC-DOCNUM`) — chave de vínculo |
| `NFENUM`   | J_1BNFNUM9 | 9           | Número da NF-e (J_1BNFDOC-NFENUM, DE: J_1BNFNUM9, CHAR9) |
| `SERIES`   | J_1BSERIES | 3           | Série da NF-e                                          |

> **Como a chave de 44 dígitos é montada:**  
> Concatenação dos campos de `J_1BNFE_ACTIVE`:  
> `REGIO(2) + NFYEAR(2) + NFMONTH(2) + STCD1(14) + MODEL(2) + SERIE(3) + NFNUM9(9) + TPEMIS(1) + DOCNUM9(9) + CDV(1) = 45` — ajustar conforme padrão SEFAZ local.

---

## 6. Classe ZCL_MDFE_MONITOR

**Arquivo:** `ZCL_MDFE_MONITOR.txt`  
Arquivo único com `CLASS DEFINITION` + `CLASS IMPLEMENTATION`. Cole tudo de uma vez no ADT.

### Métodos Públicos

| Método              | Parâmetros relevantes                               | O que faz                                                                                    |
|--------------------|-----------------------------------------------------|----------------------------------------------------------------------------------------------|
| `CONSTRUCTOR`       | —                                                   | Instancia `CL_NFE_CLOUD_MDFE_PROCESSOR` em `MO_PROC`                                        |
| `SELECT_DATA`       | `IS_SEL` (filtros) → `ET_MONITOR`                   | Lê `J_1BNFDOC` com ranges dinâmicas, vincula a `ZMDFE_STATUS` via `ZMDFE_NFKEYS.DOCNUM`, monta grid com ícone de semáforo |
| `CREATE_MDFE`       | `IS_HEADER`, `IT_NFKEYS`, `IV_INFCOMP` → `ES_HEADER`, `ET_MESSAGES` | Valida → stub BAPI → persiste `ZMDFE_STATUS` + `ZMDFE_NFKEYS` + `LOGBR_NF_TEXTS`    |
| `SEND_MDFE`         | `IV_MDFE_NUMBER` → `ES_STATUS`, `ET_MESSAGES`       | Lê tabelas → monta JSON → chama DRC → atualiza status + grava JSON para auditoria           |
| `CONSULT_MDFE`      | `IV_MDFE_NUMBER` → `ES_STATUS`, `ET_MESSAGES`       | Consulta status no DRC (stub a implementar)                                                  |
| `CLOSE_MDFE`        | `IV_MDFE_NUMBER` → `ET_MESSAGES`                    | Valida status=Autorizado → envia evento encerramento DRC (stub) → status=5                  |
| `CANCEL_MDFE`       | `IV_MDFE_NUMBER` → `ET_MESSAGES`                    | Valida que não está cancelado/encerrado → envia cancelamento DRC (stub) → status=6          |
| `PRINT_MDFE`        | `IV_MDFE_NUMBER`                                    | Valida status=Autorizado → chama Adobe Form `ZEDO_FORM_MDFe` (stub)                         |
| `READ_HEADER`       | `IV_MDFE_NUMBER` → `ES_HEADER`, `RV_FOUND`          | `SELECT SINGLE` em `ZMDFE_STATUS`                                                            |
| `READ_NFKEYS`       | `IV_MDFE_NUMBER` → `ET_NFKEYS`                      | `SELECT` em `ZMDFE_NFKEYS` ordenado por `ITEM_NUM`                                          |
| `GET_NFE_ACCESSKEY` | `IV_BUKRS`, `IV_BRANCH`, `IV_DOCNUM` → `RV_KEY`     | Monta chave de 44 dígitos concatenando campos de `J_1BNFE_ACTIVE`                           |
| `GET_STATUS_ICON`   | `IV_STATUS` → `RV_ICON` (CLASS-METHOD)              | Retorna ícone semáforo: verde=Aut/Enc · amarelo=Pend/Env · vermelho=Erro/Canc               |

### Métodos Privados

| Método               | O que faz                                                                                               |
|---------------------|---------------------------------------------------------------------------------------------------------|
| `BUILD_JSON_PAYLOAD` | Monta payload JSON conforme EF V2 Seção 5. Aplica regras críticas de decimal, placa e CEP              |
| `SAVE_STATUS`        | `MODIFY zmdfe_status` — funciona como INSERT ou UPDATE                                                 |
| `SAVE_NFKEYS`        | `DELETE FROM zmdfe_nfkeys` + `INSERT zmdfe_nfkeys FROM TABLE` — garante consistência por replace total |
| `GET_BRANCH_GEO`     | `J_1BBRANCH → ADRC` → extrai `REGION`, `POST_CODE1` e últimos 7 dígitos de `TAXJURCODE`               |
| `GET_DEST_GEO`       | `J_1BNFDOC` → extrai `REGIO`, `PSTLZ` e últimos 7 dígitos de `TXJCD`                                  |
| `SAVE_INFCOMP`       | `MODIFY logbr_nf_texts` com `txttyp='C'` — texto complementar EF V2                                   |

### Constantes

| Constante          | Valor | Uso                           |
|-------------------|-------|-------------------------------|
| `GC_ST_PENDENTE`   | `1`   | Status: Pendente              |
| `GC_ST_ENVIADO`    | `2`   | Status: Enviado               |
| `GC_ST_AUTORIZADO` | `3`   | Status: Autorizado pela SEFAZ |
| `GC_ST_ERRO`       | `4`   | Status: Erro no envio         |
| `GC_ST_ENCERRADO`  | `5`   | Status: Encerrado             |
| `GC_ST_CANCELADO`  | `6`   | Status: Cancelado             |
| `GC_FC_CRIAR`      | `'CRIAR'`      | OK-code botão Criar      |
| `GC_FC_ENVIAR`     | `'ENVIAR'`     | OK-code botão Enviar     |
| `GC_FC_CONSULTAR`  | `'CONSULTAR'`  | OK-code botão Consultar  |
| `GC_FC_ENCERRAR`   | `'ENCERRAR'`   | OK-code botão Encerrar   |
| `GC_FC_CANCELAR`   | `'CANCELAR'`   | OK-code botão Cancelar   |
| `GC_FC_IMPRIMIR`   | `'IMPRIMIR'`   | OK-code botão Imprimir   |
| `GC_FC_ATUALIZAR`  | `'ATUALIZAR'`  | OK-code botão Atualizar  |
| `GC_FC_ADD_NF`     | `'ADD_NF'`     | OK-code botão Add NF-e   |
| `GC_FC_DEL_NF`     | `'DEL_NF'`     | OK-code botão Del NF-e   |
| `GC_FC_SALVAR`     | `'SALVAR'`     | OK-code botão Salvar     |

---

## 7. Report ZMDFE — Module Pool

**Arquivo:** `ZMDFE.txt`  
Tipo: **PROG/P** (Module Pool). Não executa diretamente — precisa de uma transação `ZMDFE`.

### Selection Screen (Tela de Seleção Padrão)

| Bloco | Campo       | FOR (referência de tipo)         | Descrição                    |
|-------|------------|----------------------------------|------------------------------|
| B1    | `S_BUKRS`   | `j_1bnfdoc-bukrs`                | Empresa                      |
| B1    | `S_BRANCH`  | `j_1bnfdoc-branch`               | Local de negócio             |
| B1    | `S_DOCNUM`  | `j_1bnfdoc-docnum`               | Nº Documento NF-e            |
| B1    | `S_NFNUM`   | `j_1bnfdoc-nfenum`               | Nº NF-e                      |
| B1    | `S_SERIES`  | `j_1bnfdoc-series`               | Série NF-e                   |
| B1    | `S_CREDAT`  | `j_1bnfdoc-credat`               | Data de emissão NF-e         |
| B2    | `S_CHAVE`   | `zmdfe_nfkeys-accesskey`         | Chave de acesso NF-e (44 ch) |
| B2    | `S_MDFNUM`  | `zmdfe_status-mdfe_number`       | Nº MDF-e                     |
| B2    | `S_MCRDAT`  | `zmdfe_status-credat`            | Data de emissão MDF-e        |
| B3    | `P_PEND`    | CHECKBOX (default `'X'`)         | Exibir Pendentes / Erros     |
| B3    | `P_ENC`     | CHECKBOX (default `' '`)         | Exibir Encerrados            |

### Tela 100 — Monitor ALV

- **Container:** `CC_ALV_100` (Custom Container no Screen Painter)
- **GUI-Status:** `STATUS_100`
- **Títulotitle:** `TITLE_100`
- **Layout ALV:** zebra + sel_mode = 'A' (multi-seleção para ações em massa)

**Colunas do grid:**

| Campo         | Descrição                     |
|--------------|-------------------------------|
| `STATUS_ICON` | Semáforo (ícone SAP)          |
| `MDFE_NUMBER` | Nº MDF-e                      |
| `SERIES`      | Série                         |
| `BUKRS`       | Empresa                       |
| `BRANCH`      | Local de negócio              |
| `CREDAT`      | Data de criação               |
| `UF_ORIG`     | UF Origem                     |
| `UF_DEST`     | UF Destino                    |
| `PLACA`       | Placa do veículo              |
| `MOTORISTA`   | Nome do motorista             |
| `ACCESS_KEY`  | Chave de acesso MDF-e         |
| `NPROT`       | Protocolo SEFAZ               |
| `BRGEW`       | Peso bruto                    |
| `NFTOT`       | Valor total                   |
| `LAST_MSG`    | Última mensagem de retorno    |

### Tela 200 — Detalhe / Criação

- **Container:** `CC_ALV_200` (Custom Container no Screen Painter) — sub-ALV de chaves NF-e
- **GUI-Status:** `STATUS_200_CRE` (criar) / `STATUS_200_EDT` (editar) / `STATUS_200_DSP` (exibir)
- **Modo de tela:** `GV_MODE_200` = `'C'` / `'E'` / `'D'`

**Campos de cabeçalho na tela** (elementos de tela para `GS_DETAIL`):
`BUKRS`, `BRANCH`, `SERIES`, `PLACA`, `MOTORISTA`, `CPF_MOTOR`, `RNTRC`, `BRGEW`, `NFTOT`, `UF_ORIG`, `UF_DEST`, `SEGURADORA`, `APOLICE`, `PED_CNPJ_RESP`, `PED_CNPJ_FORN`, `PED_COMPROV`

**Campo de texto complementar:** `GV_INFCOMP` (informações complementares → `LOGBR_NF_TEXTS`)

**Campos para adicionar NF-e:** `GV_ADD_KEY` (chave manual) e `GV_ADD_DOCNUM` (busca automática via `GET_NFE_ACCESSKEY`)

---

## 8. Guia de Implementação no ADT

### 8.1 Pré-requisitos

- ADT (Eclipse) instalado com plugins **ABAP Development Tools** para S/4HANA
- Pacote Z criado (ex: `ZMDFE_PKG` ou conforme padrão da empresa)
- Acesso à transação **SE93** para criar transação
- Acesso ao **Menu Painter (SE41)** para criar GUI-Status
- Acesso ao **Screen Painter** para criar telas 100 e 200
- Classe `CL_NFE_CLOUD_MDFE_PROCESSOR` existente e ativa no sistema
- Tabelas `J_1BNFDOC`, `J_1BNFE_ACTIVE`, `J_1BBRANCH`, `ADRC`, `LOGBR_NF_TEXTS` existentes

### 8.2 Passo a Passo

---

#### Passo 1 — Criar os Data Elements Z (SE11)

> **Obrigatório antes de qualquer outro passo.** As tabelas e a classe não ativam sem esses DEs.

1. Executar transação **SE11** no SAP GUI
2. Selecionar opção **Data type** → digitar o nome do primeiro DE → **Create**
3. Selecionar **Data element** → Enter
4. Preencher conforme a tabela abaixo → **Salvar** → **Activate (Ctrl+F3)**
5. Repetir para cada DE da lista

| Nome DE          | Aba Data Type           | Comprimento | Aba Field Label — Medium |
|-----------------|-------------------------|-------------|---------------------------|
| `ZMDFE_MOTORISTA`| CHAR (Predefined ABAP)  | 20          | Nome Motorista            |
| `ZMDFE_MUNCD`    | CHAR (Predefined ABAP)  | 7           | Cód. Município IBGE       |
| `ZMDFE_CEP`      | CHAR (Predefined ABAP)  | 8           | CEP                       |
| `ZMDFE_COMPROV`  | CHAR (Predefined ABAP)  | 20          | Comprovante Pedágio       |
| `ZMDFE_SEGURAD`  | CHAR (Predefined ABAP)  | 60          | Seguradora                |
| `ZMDFE_APOLICE`  | CHAR (Predefined ABAP)  | 30          | Nº Apólice                |

> **`SYSUUID_C32`** — DE SAP padrão para UUID. Não criar — já existe no sistema.

> **ADT (alternativa):** botão direito no pacote → New → Other ABAP Repository Object → `Data Element` → preencher nome → Next → Finish → editar tipo e labels → Activate.

---

#### Passo 2 — Criar a tabela ZMDFE_STATUS

1. ADT → botão direito no pacote → **New → Other ABAP Repository Object**
2. Filtrar `Database Table` → **Next**
3. Nome: `ZMDFE_STATUS` | Descrição: `Monitor MDF-e - Status e Controle` → **Next → Finish**
4. O editor DDL abre. **Selecionar todo o conteúdo (Ctrl+A)** e **apagar**
5. Abrir `ZMDFE_STATUS.txt` deste repositório, **copiar tudo** e **colar** no editor
6. **Ctrl+S** (salvar) → verificar que não há erros de sintaxe
7. **Ctrl+F3** (Activate) → confirmar ativação

---

#### Passo 3 — Criar a tabela ZMDFE_NFKEYS

1. Repetir os passos 1–7 do Passo 2, mas com:
   - Nome: `ZMDFE_NFKEYS`
   - Descrição: `Monitor MDF-e - Chaves de Acesso NF-e`
   - Conteúdo: arquivo `ZMDFE_NFKEYS.txt`

> **Atenção:** Criar `ZMDFE_STATUS` **antes** de `ZMDFE_NFKEYS` pois a tabela filha referencia `ZMDFE_STATUS-MDFE_NUMBER`.

---

#### Passo 4 — Criar a classe ZCL_MDFE_MONITOR

1. ADT → botão direito no pacote → **New → ABAP Class**
2. Nome: `ZCL_MDFE_MONITOR` | Descrição: `Monitor MDF-e - Lógica de Negócio` → **Next → Finish**
3. O editor da classe abre com um esqueleto vazio
4. **Selecionar todo o conteúdo (Ctrl+A)** e **apagar**
5. Abrir `ZCL_MDFE_MONITOR.txt` deste repositório, **copiar tudo** e **colar**
6. **Ctrl+S** (salvar) → verificar erros de sintaxe na aba **Problems**
7. **Ctrl+F3** (Activate)

> **Dica:** Se aparecer erro `CL_NFE_CLOUD_MDFE_PROCESSOR not found`, confirmar o nome real da classe processadora DRC no sistema e ajustar no constructor e no método `SEND_MDFE`.

---

#### Passo 5 — Criar o Report ZMDFE (Module Pool)

1. ADT → botão direito no pacote → **New → Other ABAP Repository Object**
2. Filtrar `Program` → Next
3. Nome: `ZMDFE` | Tipo: **Module Pool (PROG/P)** | Descrição: `Monitor MDF-e - Entry Point` → **Finish**
4. **Selecionar todo o conteúdo** e **apagar**
5. Abrir `ZMDFE.txt`, **copiar tudo** e **colar**
6. **Ctrl+S** → **Ctrl+F3** (Activate)

> O report sozinho ainda não executa — precisa das telas e da transação.

---

#### Passo 6 — Criar as Telas (Screen Painter)

O Screen Painter no ADT fica na aba **Screens** dentro do report.

**Tela 100:**
1. No report `ZMDFE` → aba **Screens** → botão **+** → Número: `100`
2. Em **Attributes**: título = `Monitor MDF-e`
3. No layout da tela, inserir um **Custom Container** com nome: `CC_ALV_100`
   - Para inserir: no toolbar do Screen Painter → ícone "Custom Control" → desenhar área ocupando quase toda a tela
   - Nome do controle: `CC_ALV_100` (exatamente como está no código)
4. Ativar a tela

**Tela 200:**
1. Criar tela `200` da mesma forma
2. Inserir campos de cabeçalho do MDF-e (elementos de tela para `GS_DETAIL-BUKRS`, `GS_DETAIL-BRANCH`, `GS_DETAIL-PLACA`, etc.)
3. Inserir campos `GV_ADD_KEY` e `GV_ADD_DOCNUM` para inclusão de NF-e
4. Inserir campo `GV_INFCOMP` para informações complementares
5. Inserir **Custom Container** com nome: `CC_ALV_200` (sub-ALV das chaves NF-e)
6. Ativar a tela

---

#### Passo 7 — Criar GUI-Status (Menu Painter SE41)

> **Alternativa:** No ADT, abrir o report → aba **GUI Status** → botão **+**

**STATUS_100** (Monitor principal):
- Tipo: **Normal Status**
- Botões a criar na toolbar:

| Função    | Tecla  | Texto         | Ícone sugerido       |
|-----------|--------|---------------|----------------------|
| `CRIAR`   | —      | Criar MDF-e   | ICON_CREATE          |
| `ENVIAR`  | —      | Enviar        | ICON_SEND            |
| `CONSULTAR`| —     | Consultar     | ICON_SEARCH          |
| `ENCERRAR`| —      | Encerrar      | ICON_CHECKED         |
| `CANCELAR`| —      | Cancelar      | ICON_CANCEL          |
| `IMPRIMIR`| —      | Imprimir      | ICON_PRINT           |
| `ATUALIZAR`| F5    | Atualizar     | ICON_REFRESH         |
| `BACK`    | F3     | Voltar        | ICON_PREVIOUS_PAGE   |
| `EXIT`    | F15    | Sair          | ICON_SYSTEM_END      |

**STATUS_200_CRE** (Tela criação):

| Função   | Tecla | Texto        |
|----------|-------|--------------|
| `ADD_NF` | —     | Add NF-e     |
| `DEL_NF` | —     | Remover NF-e |
| `SALVAR` | Ctrl+S| Salvar       |
| `BACK`   | F3    | Voltar       |
| `CANCEL` | F12   | Cancelar     |

**STATUS_200_EDT** — igual ao `STATUS_200_CRE`  
**STATUS_200_DSP** — apenas `BACK`, sem `SALVAR`, `ADD_NF`, `DEL_NF`

---

#### Passo 8 — Criar a Transação ZMDFE (SE93)

1. Executar **SE93** no SAP
2. Nome: `ZMDFE` → **Create**
3. Tipo: **Transaction with parameters (parameter transaction)**
4. Ou mais simples: **Program and selection screen (report transaction)**
   - Program: `ZMDFE`
   - Screen number: deixar em branco (Module Pool abre a tela 100 via `CALL SCREEN 100`)

> **Alternativa via ADT:** botão direito no pacote → New → Other → `Transaction` → preencher nome e apontar para o report `ZMDFE`.

---

#### Passo 9 — Criar os Textos de Seleção (Text Elements)

No report `ZMDFE`, acessar **Goto → Text elements → Selection texts** e criar:

| Variável | Texto                        |
|---------|------------------------------|
| `B01`   | Filtros NF-e                 |
| `B02`   | Filtros MDF-e                |
| `B03`   | Opções de exibição           |
| `P_PEND`| Exibir Pendentes / Erros     |
| `P_ENC` | Exibir Encerrados            |

---

#### Passo 10 — Ativação Final e Teste

1. Ativar todos os objetos (F3 → Activate all)
2. Executar a transação `ZMDFE`
3. Testar o fluxo em ambiente de **Homologação** (`GC_AMB_HOMOL = '2'`):
   - Selecionar NF-es existentes → verificar se aparecem no grid
   - Criar MDF-e de teste → verificar `ZMDFE_STATUS` e `ZMDFE_NFKEYS`
   - Ativar o stub de `SEND_MDFE` após confirmar a assinatura de `CL_NFE_CLOUD_MDFE_PROCESSOR`

---

## 9. GUI Status — Menu Painter

### Resumo de todos os OK-codes

| OK-code     | Tela   | Ação                                                        |
|------------|--------|-------------------------------------------------------------|
| `BACK`      | 100/200| Voltar / Fechar programa                                    |
| `EXIT`      | 100    | Sair do programa                                            |
| `EXECUTE`   | 100    | Re-executar seleção (F8 padrão)                             |
| `CRIAR`     | 100    | Abre tela 200 em modo `'C'`                                 |
| `ENVIAR`    | 100    | Envia MDF-e(s) selecionados → `SEND_MDFE` (ação em massa)  |
| `CONSULTAR` | 100    | Consulta status DRC → `CONSULT_MDFE`                        |
| `ENCERRAR`  | 100    | Encerra MDF-e → `CLOSE_MDFE`                                |
| `CANCELAR`  | 100    | Cancela MDF-e → `CANCEL_MDFE`                               |
| `IMPRIMIR`  | 100    | Imprime DAMDFE → `PRINT_MDFE`                               |
| `ATUALIZAR` | 100    | Recarrega grid sem ir à seleção                             |
| `ADD_NF`    | 200    | Adiciona chave NF-e ao sub-ALV                              |
| `DEL_NF`    | 200    | Remove chaves NF-e selecionadas do sub-ALV                  |
| `SALVAR`    | 200    | Salva e envia o MDF-e → `CREATE_MDFE` + `SEND_MDFE`        |

---

## 10. Configurações SPRO

Execute `SPRO` → SAP Reference IMG e configure:

| Atividade                                              | Caminho SPRO (aproximado)                                       | O que configurar                                        |
|-------------------------------------------------------|-----------------------------------------------------------------|---------------------------------------------------------|
| Parâmetros DRC (URL, certificado, ambiente)            | Nota Fiscal → Configurações Gerais → DRC Cloud Service          | URL do endpoint, certificado, ambiente (P/H)            |
| Séries e numeração MDF-e                               | Nota Fiscal → Numeração → Séries de Documentos Fiscais          | Série e faixa numérica para MDF-e (modelo 58)           |
| Configuração do local de negócio                       | Nota Fiscal → Configuração → Local de Negócio (J_1BBRANCH)     | Verificar ADRNR preenchido com TAXJURCODE correto        |
| Certificado digital para assinatura                    | Nota Fiscal → Certificados Digitais                             | Certificado A1/A3 da empresa                            |
| Adobe Document Services                                | Basis → Adobe Document Services                                 | Necessário para `ZEDO_FORM_MDFe` (formulário DAMDFE)    |
| Autorizações de usuário                                | Basis → Perfis → Autorizações                                   | Reutilizar objeto `J_1BNFE` com atividade ZMD           |
| Configuração do modelo 58 (MDF-e) no domínio FICA      | Nota Fiscal → Tipos de Documento                                | Verificar se modelo 58 está configurado                 |

---

## 11. Regras Críticas do JSON

O método `BUILD_JSON_PAYLOAD` monta o payload conforme a **EF V2 Seção 5**. As regras abaixo são críticas — erro em qualquer uma causa rejeição pela SEFAZ.

| Campo JSON               | Regra                                                                            | Implementação no código                             |
|-------------------------|----------------------------------------------------------------------------------|-----------------------------------------------------|
| `totalQuantity`          | Decimal SEM separador de milhar. Ex: `1000.50` e NÃO `1.000,50`                 | `WRITE...NO-GROUPING` + CONDENSE + REPLACE `,`→`.` |
| `cargoTotalValue`        | Idem                                                                             | Idem                                                |
| `loadingPostalCode`      | Exatamente **8 dígitos** com zeros à esquerda, sem traço, sem espaços           | Strip `[^0-9]` via REGEX + pad 8 com zeros          |
| `unloadingPostalCode`    | Idem                                                                             | Idem                                                |
| `vehicleInfo.plate`      | Sem traço. Ex: `ABC1234` e NÃO `ABC-1234`                                       | `REPLACE '-' WITH ''`                               |
| `conductor[].cpf`        | Somente números (11 dígitos). Sem pontos ou traços                              | Campo `CPF_MOTOR` já é `CHAR11` numérico             |
| `environmentType`        | `1` = Produção · `2` = Homologação (inteiro, não string)                        | Constante `GC_AMB_PROD = '1'`                       |
| `issuingType`            | Sempre `"1"` (string)                                                           | Hard-coded no JSON                                  |
| `issuingState`           | Sigla UF de 2 letras (ex: `"SP"`, `"MG"`)                                      | Vem de `UF_ORIG` = `ADRC-REGION` da filial          |
| `loadingCity`            | Código de município IBGE (7 dígitos)                                            | Últimos 7 dígitos de `ADRC-TAXJURCODE`              |
| `unloadingCity`          | Código de município IBGE (7 dígitos) do destino                                 | Últimos 7 dígitos de `J_1BNFDOC-TXJCD`             |

### Estrutura do JSON enviado

```json
{
  "issuingState": "SP",
  "environmentType": 1,
  "issuingType": "1",
  "loadingCity": "3550308",
  "loadingPostalCode": "01310100",
  "unloadingCity": "3304557",
  "unloadingPostalCode": "20040020",
  "totalQuantity": 1500.00,
  "cargoTotalValue": 85000.00,
  "vehicleInfo": { "plate": "ABC1234" },
  "conductor": [{ "cpf": "12345678901", "name": "JOSE DA SILVA" }],
  "road": { "anttInfo": "12345678901234" },
  "nfeKeys": ["35240112345678000195550010000001234000000123"]
}
```

---

## 12. Ciclo de Vida do MDF-e

```
[CRIADO]
    │  create_mdfe()  →  ZMDFE_STATUS.DOC_STATUS = '1' (Pendente)
    ▼
[PENDENTE - Status 1]
    │  send_mdfe()    →  chama DRC → SEFAZ
    ▼
[ENVIADO - Status 2]  ←──── transitório (atualizado pelo retorno DRC)
    │
    ├── Autorizado   →  Status '3' + NPROT + UUID_DRC gravados
    │
    └── Erro         →  Status '4' + LAST_MSG com motivo da rejeição
          │
          └── corrigir dados → send_mdfe() novamente

[AUTORIZADO - Status 3]
    │
    ├── close_mdfe()   →  Status '5' (Encerrado)  ← mercadoria entregue
    │
    └── cancel_mdfe()  →  Status '6' (Cancelado)  ← antes do encerramento

[ENCERRADO - Status 5]  ← estado final normal
[CANCELADO - Status 6]  ← estado final cancelado
```

> **Regras de negócio:**
> - Apenas MDF-e **Autorizado** pode ser encerrado ou impresso
> - Apenas MDF-e **Autorizado** pode ser cancelado (não encerrado)
> - MDF-e **Encerrado** não pode ser cancelado
> - Reenvio é possível apenas para status **Pendente** ou **Erro**

---

## 13. Stubs — O Que Ainda Falta Ativar

Os itens abaixo estão com código **stub comentado** — precisam ser confirmados no sistema real antes de ativar:

| Método / Objeto        | O que confirmar no sistema                                               | Arquivo         |
|-----------------------|---------------------------------------------------------------------------|-----------------|
| `SEND_MDFE`            | Assinatura real de `CL_NFE_CLOUD_MDFE_PROCESSOR→SEND_REQUEST_JSON` e estrutura do retorno `RS_RESPONSE` | `ZCL_MDFE_MONITOR.txt` |
| `CONSULT_MDFE`         | Método DRC para consulta de status por UUID                              | `ZCL_MDFE_MONITOR.txt` |
| `CLOSE_MDFE`           | Método DRC para evento de encerramento                                   | `ZCL_MDFE_MONITOR.txt` |
| `CANCEL_MDFE`          | Método DRC para evento de cancelamento                                   | `ZCL_MDFE_MONITOR.txt` |
| `PRINT_MDFE`           | FM `ZMDFE_PRINT` ou chamada direta ao Adobe Form `ZEDO_FORM_MDFe`        | `ZCL_MDFE_MONITOR.txt` |
| `CREATE_MDFE`          | `BAPI_J_1B_NF_CREATEFROMDATA` — confirmar tipos `BAPI_J_1B_NF_HEADER` e `BAPI_J_1B_NF_ITEMS_T` no sistema | `ZCL_MDFE_MONITOR.txt` |
| `ZEDO_FORM_MDFe`       | Adobe Form para impressão do DAMDFE — objeto separado (EF Formulário)    | Não criado ainda |

> **Como validar a assinatura do DRC no sistema:**  
> No ADT → abrir `CL_NFE_CLOUD_MDFE_PROCESSOR` → aba **Methods** → localizar os métodos disponíveis → verificar parâmetros e tipos de importação/exportação.

---

## 14. Diferenças EF V1 vs EF V2

| Aspecto                          | EF V1                                      | EF V2 (prioridade aplicada)                              |
|---------------------------------|--------------------------------------------|-----------------------------------------------------------|
| **Vale Pedágio**                 | Não existia                                | `PED_CNPJ_RESP`, `PED_CNPJ_FORN`, `PED_COMPROV` em `ZMDFE_STATUS` |
| **Seguro**                       | Não existia                                | `SEGURADORA`, `APOLICE` em `ZMDFE_STATUS`                |
| **Criação do documento**         | Gravação direta em tabelas Z               | Stub `BAPI_J_1B_NF_CREATEFROMDATA` + `LOGBR_NF_TEXTS`  |
| **JSON — decimais**              | `STYLE = SIMPLE` (falha em locale PT-BR)   | `WRITE...NO-GROUPING` + CONDENSE → garantido sem milhar  |
| **JSON — placa**                 | Sem tratamento de traço                    | `REPLACE '-' WITH ''` antes de montar JSON               |
| **JSON — CEP**                   | Sem validação de formato                   | Strip non-digits + zero-pad até 8 posições               |
| **Informações complementares**   | Não especificado                           | `save_infcomp` → `LOGBR_NF_TEXTS` tipo `'C'`            |
| **Vínculo NF-e → MDF-e**         | Por `BUKRS + BRANCH` (impreciso)           | Via `ZMDFE_NFKEYS.DOCNUM` (exato, sem ambiguidade)       |
| **Ranges de filtro**             | `VALUE rseloption()` vazia filtra tudo     | Ranges dinâmicas — só adiciona quando `*_low IS NOT INITIAL` |
| **Município no JSON**            | Não tratado                                | Últimos 7 dígitos de `TAXJURCODE` / `TXJCD` (código IBGE)|
