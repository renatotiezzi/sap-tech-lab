# Análise Clean Core — Programa SAPHIRA: Automação de Arquivos Bancários (ACHÉ)

> **Projeto:** SAPHIRA — Sistema SAP S/4HANA (Implantação Nova)  
> **Solução Analisada:** Automação de processamento de arquivos bancários  
> **Empresa:** ACHÉ  
> **Data de Análise:** Março 2025  
> **Modelo de Extensibilidade Alvo:** Clean Core / ABAP Cloud  
> **SAP Note de Referência:** [3578329](https://launchpad.support.sap.com/#/notes/3578329)  
> **Ferramenta de Referência:** [Cloudification Repository Viewer](https://help.sap.com/docs/abap-cloud/abap-cloud/released-apis)

---

## Sumário

1. [Visão Geral da Solução](#1-visão-geral-da-solução)
2. [Critérios de Classificação Clean Core](#2-critérios-de-classificação-clean-core)
3. [Tabela de Classificação — Resumo Executivo](#3-tabela-de-classificação--resumo-executivo)
4. [Análise Detalhada por Objeto](#4-análise-detalhada-por-objeto)
   - [4.1 AL11 — Transação de Gerenciamento de Diretórios](#41-al11--transação-de-gerenciamento-de-diretórios)
   - [4.2 FF.5 / RFEBKA00 — Importação de Extrato Bancário](#42-ff5--rfebka00--importação-de-extrato-bancário)
   - [4.3 EPS_GET_DIRECTORY_LISTING — Function Module](#43-eps_get_directory_listing--function-module)
   - [4.4 FEBKO — Tabela Interna SAP](#44-febko--tabela-interna-sap)
   - [4.5 SUBMIT ... AND RETURN — Statement ABAP](#45-submit--and-return--statement-abap)
   - [4.6 Tabela Z Customizada](#46-tabela-z-customizada)
   - [4.7 S_DATASET — Objeto de Autorização](#47-s_dataset--objeto-de-autorização)
   - [4.8 S_PROGRAM — Objeto de Autorização](#48-s_program--objeto-de-autorização)
5. [Nível Geral da Solução](#5-nível-geral-da-solução)
6. [Recomendações Técnicas e Alternativas Clean Core](#6-recomendações-técnicas-e-alternativas-clean-core)
7. [Justificativas para Impossibilidade de Nível A](#7-justificativas-para-impossibilidade-de-nível-a)
8. [Arquitetura Alvo Recomendada](#8-arquitetura-alvo-recomendada)
9. [Referências Oficiais SAP](#9-referências-oficiais-sap)

---

## 1. Visão Geral da Solução

O programa **SAPHIRA — Automação de Arquivos Bancários** realiza o seguinte fluxo automatizado:

```
[Tabela Z] → [AL11 / EPS_GET_DIRECTORY_LISTING] → [Verificação FEBKO]
     ↓
[SUBMIT RFEBKA00 (FF.5)] → [Movimentação de arquivos] → [Log estruturado]
     ↓
[JOB agendado sem tela de seleção]
```

### Fluxo de Processamento Detalhado

| Etapa | Descrição | Objeto SAP Envolvido |
|-------|-----------|----------------------|
| 1 | Leitura de parâmetros de configuração | Tabela Z customizada |
| 2 | Varredura de diretórios configurados | AL11 + EPS_GET_DIRECTORY_LISTING |
| 3 | Verificação de arquivos já processados | SELECT na tabela FEBKO |
| 4 | Importação do extrato bancário | SUBMIT RFEBKA00 (FF.5) |
| 5 | Movimentação de arquivos (sucesso/erro) | Funções de arquivo ABAP + S_DATASET |
| 6 | Geração de log estruturado | Código customizado |
| 7 | Execução agendada | JOB via SM36/SM37 |

---

## 2. Critérios de Classificação Clean Core

A SAP define o **Clean Core** como a prática de manter o núcleo SAP limpo, sem modificações de objetos padrão, utilizando exclusivamente APIs e extensões liberadas. Para S/4HANA, o modelo alvo é o **ABAP Cloud**, que opera com um subconjunto restrito da linguagem ABAP.

### Níveis de Classificação Utilizados

| Nível | Nome | Critério | Impacto nos Upgrades |
|-------|------|----------|----------------------|
| **A** | ✅ Cloud Ready | API liberada (contrato C1), CDS View Released, RAP — compatível com ABAP Cloud restrito | Nenhum — suportado pela SAP |
| **B** | ⚠️ Compatível com Restrições | BAdIs clássicos, APIs parcialmente liberadas, objetos customizados bem estruturados — não causa modificações no padrão | Baixo risco — precisa de revisão a cada upgrade |
| **C** | 🔶 Risco Moderado | FMs internos não liberados, acesso direto a tabelas SAP sem CDS view, uso de transações padrão via SUBMIT | Risco médio — pode quebrar em upgrades |
| **D** | ❌ Crítico / Proibido | SUBMIT de programas SAP, modificação de objetos padrão, acesso ao filesystem do servidor de aplicação, statements ABAP proibidos no Cloud | Alto risco — incompatível com S/4HANA Cloud e futuras versões |

### Referência Oficial SAP para os Níveis

> A classificação de objetos segue o **ABAP Cloud Development Model** documentado em:
> - [SAP Help: ABAP Cloud - Released APIs](https://help.sap.com/docs/abap-cloud/abap-cloud/released-apis)
> - [SAP Help: Clean Core Extensibility](https://help.sap.com/docs/SAP_S4HANA_CLOUD/a630d57fc73f470d8ba36d78c7a5f5d7/6c2f3ce77c4f4c78a12b4668ceeab5d6.html)
> - [SAP Cloudification Repository Viewer](https://help.sap.com/docs/abap-cloud/abap-cloud/released-apis)

---

## 3. Tabela de Classificação — Resumo Executivo

| # | Objeto | Tipo | Nível Clean Core | Liberado p/ ABAP Cloud | Sucessor / Alternativa Clean Core |
|---|--------|------|:----------------:|:---------------------:|-----------------------------------|
| 1 | **AL11** | Transação | **D** ❌ | ❌ Não | BTP Document Management / SFTP Integration |
| 2 | **FF.5** | Transação | **D** ❌ | ❌ Não | OData API `C_BankStatementInbound` |
| 3 | **RFEBKA00** | Programa ABAP | **D** ❌ | ❌ Não | API Inbound Bank Statement (OData V4) |
| 4 | **EPS_GET_DIRECTORY_LISTING** | Function Module | **D** ❌ | ❌ Não | Cloud Storage API / BTP Integration Suite |
| 5 | **FEBKO** | Tabela Interna SAP | **C** 🔶 | ❌ Direto não | CDS View `I_BankStatementItem` / `C_BankStmtHdr` |
| 6 | **SUBMIT ... AND RETURN** | Statement ABAP | **D** ❌ | ❌ Proibido | Application Job Framework (`CL_APJ_DT_CREATE_IN`) |
| 7 | **Tabela Z customizada** | Objeto Customizado | **A** ✅ | ✅ Sim | Própria tabela — seguir diretrizes de design |
| 8 | **S_DATASET** | Objeto de Autorização | **C** 🔶 | ⚠️ Restrito | Substituído pelo modelo de Cloud Storage |
| 9 | **S_PROGRAM** | Objeto de Autorização | **B** ⚠️ | ⚠️ Parcial | Mantido para jobs clássicos em sistemas on-premise gerenciados |

### Distribuição por Nível

```
Nível A (Clean Core Ready):  1 objeto  (11%)  → Tabela Z
Nível B (Compatível):        1 objeto  (11%)  → S_PROGRAM
Nível C (Risco Moderado):    2 objetos (22%)  → FEBKO, S_DATASET
Nível D (Crítico/Proibido):  5 objetos (56%)  → AL11, FF.5, RFEBKA00,
                                                  EPS_GET_DIRECTORY_LISTING,
                                                  SUBMIT...AND RETURN
```

> ⚠️ **56% dos objetos técnicos estão no nível D — a solução atual NÃO está alinhada com Clean Core.**

---

## 4. Análise Detalhada por Objeto

---

### 4.1 AL11 — Transação de Gerenciamento de Diretórios

| Atributo | Valor |
|----------|-------|
| **Tipo** | Transação SAP Padrão |
| **Nível Clean Core** | **D** ❌ |
| **Liberado para ABAP Cloud** | ❌ Não |
| **Uso na Solução** | Configuração de caminhos de diretórios no servidor de aplicação |
| **Disponível em S/4HANA Cloud PE** | ❌ Não disponível |

#### Análise

A transação **AL11** (e seu equivalente programático via `CL_SPFL_PROFILE_DIR`) acessa diretamente o **filesystem do servidor de aplicação SAP (SAP Application Server)**. Em ambientes **S/4HANA Cloud** (Public e Private Edition gerenciados pela SAP), o acesso ao filesystem do servidor de aplicação é **bloqueado por design**, pois viola o princípio de isolamento de camadas da nuvem.

Mesmo em sistemas **S/4HANA on-premise**, o uso de AL11 para configuração de caminhos de diretórios em tabelas de parâmetros representa um forte acoplamento com a infraestrutura do servidor, criando dependência operacional que dificulta migrações e upgrades.

#### Riscos Identificados

- **Risco de Upgrade**: A estrutura de diretórios do servidor muda com patches e atualizações de sistema
- **Risco de Cloud**: Incompatível com S/4HANA Cloud (qualquer edição gerenciada pela SAP)
- **Risco de Segurança**: Exposição de caminhos de sistema internos na tabela Z

#### Alternativa Clean Core

```
OPÇÃO 1 — Para S/4HANA Cloud / BTP:
  ✅ SAP Document Management Service (DMS) via BTP
  ✅ SAP Integration Suite com adaptador SFTP
  ✅ SAP Business Technology Platform (BTP) File System Services

OPÇÃO 2 — Para S/4HANA On-Premise (solução transitória):
  ⚠️ Manter diretórios logicos (AL11) somente em camada de middleware
  ⚠️ Usar LOGICAL FILE PATH (transação FILE) em vez de caminhos físicos
```

#### Referência SAP

- [SAP Help: Application Server File System](https://help.sap.com/docs/ABAP_PLATFORM/753088fc00704d0a80e7fbd6803c8adb/4ec24fa26e391014adc9fffe4e204223.html)
- [SAP Help: S/4HANA Cloud Extensibility — File Management](https://help.sap.com/docs/SAP_S4HANA_CLOUD/a630d57fc73f470d8ba36d78c7a5f5d7/6c2f3ce77c4f4c78a12b4668ceeab5d6.html)

---

### 4.2 FF.5 / RFEBKA00 — Importação de Extrato Bancário

| Atributo | Valor |
|----------|-------|
| **Tipo** | Transação SAP Padrão / Programa ABAP Standard |
| **Nível Clean Core** | **D** ❌ |
| **Liberado para ABAP Cloud** | ❌ Não — nem via SUBMIT |
| **Uso na Solução** | Processamento de arquivos bancários (importação de extratos) |
| **Nota SAP Relacionada** | [3578329](https://launchpad.support.sap.com/#/notes/3578329) |

#### Análise

O programa **RFEBKA00** é o backend da transação **FF.5** (Electronic Bank Statement Import). Ao ser chamado via `SUBMIT RFEBKA00 AND RETURN`, a solução cria uma **dependência direta em código SAP interno não liberado**, violando dois princípios Clean Core simultaneamente:

1. **Uso de programa SAP não liberado** via SUBMIT (ver seção 4.5)
2. **Acoplamento rígido** com implementação interna do processamento bancário

A SAP disponibiliza uma **API OData liberada** para importação de extratos bancários, que segue o contrato C1 e é mantida estável entre upgrades.

#### API Oficial Liberada (Nível A)

A SAP liberou o seguinte serviço OData para importação programática de extratos bancários:

```
Serviço OData: Bank Statement Import - Inbound Processing
API ID: API_BANKSTATEMENT_SRV
URL Base: /sap/opu/odata/sap/API_BANKSTATEMENT_SRV
Entidade Principal: BankStatement
Método: POST (para criar/importar novo extrato)
```

Adicionalmente, o **RAP Business Object** para processamento bancário pode ser consultado via:
- **SAP Business Accelerator Hub**: [Bank Statement API](https://api.sap.com/api/API_BANKSTATEMENT_SRV/overview)
- Pesquisar no **SAP Business Accelerator Hub**: `Electronic Bank Statement`

#### Alternativa Clean Core (Nível A)

```abap
" ABAP Cloud: Use HTTP client para chamar a API liberada
" em vez de SUBMIT RFEBKA00

DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
    i_destination = cl_http_destination_provider=>create_by_comm_arrangement(
        i_comm_scenario = 'SAP_COM_XXXX'  " Communication Scenario para Bank Statement
    )
).

DATA(lo_request) = lo_http_client->get_http_request( ).
lo_request->set_method( 'POST' ).
lo_request->set_uri_path( '/sap/opu/odata/sap/API_BANKSTATEMENT_SRV/BankStatement' ).
" ... configurar payload com dados do arquivo ...
DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).
```

#### Referência SAP

- [SAP API Hub: Electronic Bank Statement](https://api.sap.com/api/API_BANKSTATEMENT_SRV/overview)
- [SAP Help: Electronic Bank Statement Processing](https://help.sap.com/docs/SAP_S4HANA/56bf56fbba7c4bc3b2e5ae2c1ff63fbc/bbc1f1e66f7d4b69b6a7b07e5001a2f9.html)
- [SAP Note 3578329](https://launchpad.support.sap.com/#/notes/3578329) — Nota de referência para processamento bancário em Cloud

---

### 4.3 EPS_GET_DIRECTORY_LISTING — Function Module

| Atributo | Valor |
|----------|-------|
| **Tipo** | Function Module SAP Interno |
| **Pacote ABAP** | `SEPS` (Servidor de Aplicação — não liberado) |
| **Nível Clean Core** | **D** ❌ |
| **Liberado para ABAP Cloud** | ❌ Não (não possui contrato C1) |
| **Uso na Solução** | Listar arquivos em diretório do servidor de aplicação |

#### Análise

O function module **EPS_GET_DIRECTORY_LISTING** pertence ao grupo de funções para manipulação de arquivos no **Application Server File System** (ASFS). Este FM:

- **Não possui contrato de liberação C1** — pode ser removido ou alterado a qualquer upgrade
- **Acessa o filesystem físico do servidor** — operação bloqueada em S/4HANA Cloud
- **Não está disponível no ABAP Cloud restrito** — o ambiente de desenvolvimento ABAP Cloud restringe o uso de FMs sem contrato C1

Ao verificar no **Cloudification Repository Viewer** ou via transação `SE80` com filtro de "Released API", este FM **não aparece como liberado**. A SAP não documenta este FM como parte do contrato público de APIs.

#### Riscos Específicos

```
EPS_GET_DIRECTORY_LISTING usa internamente:
- SPFL (SAP Profile Library) para acesso a diretórios
- Chamadas de sistema operacional via kernel ABAP
→ Ambos bloqueados em S/4HANA Cloud (qualquer edição)
```

#### Alternativa Clean Core (Nível A)

```
PARA S/4HANA Cloud / BTP Side-by-Side:
  ✅ SAP Integration Suite (Cloud Integration) com adaptador de SFTP
     - Busca arquivos via SFTP em servidor externo
     - Processa e envia via API OData para S/4HANA

PARA S/4HANA On-Premise (transição):
  ⚠️ FILE_GET_DIRECTORY (liberado para uso clássico, mas não ABAP Cloud)
  ⚠️ Usar LOGICAL FILE PATH em vez de físico
  
ARQUITETURA RECOMENDADA:
  Banco → SFTP Server → SAP Integration Suite → API OData → S/4HANA
```

#### Referência SAP

- [SAP Help: ABAP Cloud — Restricted Language Version](https://help.sap.com/docs/abap-cloud/abap-cloud/restricted-abap-language-version)
- [SAP Help: Application Server File Access](https://help.sap.com/docs/ABAP_PLATFORM/753088fc00704d0a80e7fbd6803c8adb/4ec24fa26e391014adc9fffe4e204223.html)

---

### 4.4 FEBKO — Tabela Interna SAP

| Atributo | Valor |
|----------|-------|
| **Tipo** | Tabela de Banco de Dados SAP (transparente) |
| **Módulo** | FI — Financial Accounting / Bank Accounting |
| **Nível Clean Core** | **C** 🔶 |
| **Acesso Direto (SELECT)** | ❌ Não permitido em ABAP Cloud |
| **CDS View Liberada Disponível** | ✅ Sim — ver alternativa abaixo |
| **Uso na Solução** | Verificar se extratos bancários já foram processados |

#### Análise

A tabela **FEBKO** armazena os **cabeçalhos dos extratos bancários eletrônicos** (Electronic Bank Statement Headers). O acesso direto via `SELECT * FROM FEBKO WHERE ...` representa um risco **moderado** (Nível C), pois:

1. **A estrutura interna da tabela pode mudar** sem aviso prévio entre upgrades do S/4HANA
2. **ABAP Cloud proíbe SELECT direto** em tabelas SAP que não possuam CDS View liberada correspondente
3. O acesso direto **bypassa** qualquer lógica de controle de acesso, Buffer de HANA e otimizações da SAP

O nível C (e não D) se justifica porque a tabela não está sendo modificada (apenas lida) e porque **existe CDS View liberada** que pode substituí-la.

#### CDS Views Liberadas para FEBKO (Nível A)

A SAP liberou as seguintes CDS Views para acesso a dados de extratos bancários:

```abap
" CDS View para Cabeçalho do Extrato Bancário
" Tabela base: FEBKO → CDS View Liberada:
I_BankStatementItem        " View de informação (C1 - Released)
C_BankStatementItem        " View de consumo (C1 - Released)

" Para verificar processamento pendente:
I_BankStatementHeader      " Cabeçalho com status
I_ElecBankStmtItm          " Itens do extrato eletrônico

" ABAP Cloud - Exemplo de uso correto:
SELECT FROM I_BankStatementItem
  FIELDS BankStatementID,
         BankAccountInternalID,
         PostingDate,
         BankStatementStatus     " ← Campo para verificar pendências
  WHERE BankStatementStatus = '01'  " Pendente
  INTO TABLE @DATA(lt_pending_statements).
```

#### Referência SAP

- [SAP API Hub: Bank Statement CDS Views](https://api.sap.com/api/API_BANKSTATEMENT_SRV/overview)
- [SAP Help: Electronic Bank Statement — CDS Views](https://help.sap.com/docs/SAP_S4HANA/56bf56fbba7c4bc3b2e5ae2c1ff63fbc/bbc1f1e66f7d4b69b6a7b07e5001a2f9.html)
- [SAP Cloudification Repository Viewer — FEBKO](https://help.sap.com/docs/abap-cloud/abap-cloud/released-apis)

---

### 4.5 SUBMIT ... AND RETURN — Statement ABAP

| Atributo | Valor |
|----------|-------|
| **Tipo** | Statement ABAP (Linguagem) |
| **Nível Clean Core** | **D** ❌ |
| **Disponível em ABAP Cloud Restrito** | ❌ **PROIBIDO** — não faz parte da versão restrita |
| **Uso na Solução** | Execução do programa RFEBKA00 |

#### Análise

O statement **SUBMIT ... AND RETURN** é **explicitamente proibido** na versão restrita do ABAP Cloud. Esta restrição está documentada na SAP e pode ser verificada ao criar um programa com `CLASS DEFINITION ... ABAP CLOUD`:

```abap
" ESTE CÓDIGO GERA ERRO DE SINTAXE EM ABAP CLOUD:
SUBMIT rfebka00 AND RETURN.    " ← Syntax error: Statement not allowed in ABAP Cloud

" Mensagem de erro: 
" "SUBMIT is not allowed in this language version"
```

#### Por que SUBMIT é Proibido no ABAP Cloud?

O SUBMIT viola o Clean Core por múltiplos motivos:

1. **Acoplamento direto**: Cria dependência explícita com um programa SAP standard não liberado
2. **Contorno de APIs**: Bypassa as APIs oficiais de processamento bancário
3. **Herança de contexto insegura**: O programa submetido pode acessar contextos de sessão de forma imprevisível
4. **Incompatibilidade com eventos assíncronos**: SUBMIT síncrono bloqueia o processo em cloud environments

#### Alternativa Clean Core (Nível A) — Application Job Framework

```abap
" ALTERNATIVA 1: Application Job Framework (Nível A - Liberado)
" Para agendamento e execução de jobs em ABAP Cloud

" 1. Definir um Application Job Catalog Entry (via customizing)
" 2. Criar instância de job programaticamente:

DATA: lv_job_name    TYPE cl_apj_dt_create_content=>ty_job_name,
      lv_job_count   TYPE tbtcjob-jobcount,
      ls_job_key     TYPE cl_apj_dt_create_content=>ty_job_key.

" Criar job via Application Job Framework
cl_apj_dt_create_content=>create_job_w_parameters(
  EXPORTING
    iv_catalog_name      = 'Z_BANK_STMT_IMPORT_JOB'  " Catálogo customizado
    iv_job_name          = 'IMPORT_BANK_STATEMENT'
    is_start_info        = ls_start_info
    it_job_parameters    = lt_params
  IMPORTING
    ev_job_name          = lv_job_name
    ev_job_count         = lv_job_count
).

" ALTERNATIVA 2: Calling API via HTTP (Nível A - Liberado)
" Chamar a API OData de importação de extrato bancário diretamente
" em vez de submeter o programa RFEBKA00
```

#### Referência SAP

- [SAP Help: ABAP Cloud Restricted Language — SUBMIT](https://help.sap.com/docs/abap-cloud/abap-cloud/restricted-abap-language-version)
- [SAP Help: Application Job Framework](https://help.sap.com/docs/SAP_S4HANA_CLOUD/55a7cb346519450cb9e6d21c1ecd6ec1/e60e8b37ee2843b6a3e5af7bb7b04d33.html)
- [SAP ABAP Keyword Documentation — SUBMIT restrictions](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/index.htm?file=abapsubmit.htm)

---

### 4.6 Tabela Z Customizada

| Atributo | Valor |
|----------|-------|
| **Tipo** | Objeto Customizado (Z) |
| **Nível Clean Core** | **A** ✅ |
| **Liberado para ABAP Cloud** | ✅ Sim — objetos Z são propriedade do cliente |
| **Uso na Solução** | Armazenar parâmetros de processamento (diretórios, configurações) |

#### Análise

A **Tabela Z customizada** é, em princípio, um objeto de **Nível A** do ponto de vista de Clean Core, pois:

- Objetos no namespace Z/Y são **propriedade do cliente** e não interferem no núcleo SAP
- São **automaticamente preservados** em upgrades do sistema
- Podem ser criados e mantidos em ambiente ABAP Cloud

#### Ressalvas de Design (Boas Práticas)

Embora a tabela Z em si seja Nível A, o **conteúdo que ela armazena** pode introduzir riscos:

```
✅ CORRETO: Tabela Z armazena parâmetros de negócio (IDs de banco, formatos)
❌ EVITAR:  Tabela Z armazena caminhos físicos de filesystem (/usr/sap/trans/files)
            → O conteúdo cria dependência com a infraestrutura (Nível D por associação)
```

#### Recomendação de Design Clean Core

```abap
" Estrutura recomendada para tabela Z de parâmetros bancários (Nível A):
" Usar Communication Arrangements ou Custom Business Configuration (BC Sets)
" em vez de tabela Z com caminhos físicos

" Para S/4HANA Cloud: usar Business Configuration App (Fiori Launchpad)
" ou SAP Customizing (SPRO) para parâmetros

" Tabela Z bem estruturada:
TYPES: BEGIN OF ty_bank_config,
  mandt          TYPE mandt,
  bukrs          TYPE bukrs,        " Código da empresa
  hbkid          TYPE hbkid,        " ID do banco
  comm_scenario  TYPE string,       " Communication Scenario BTP
  file_format    TYPE char10,       " Formato do arquivo (MT940, CAMT, etc.)
  active         TYPE abap_bool,
END OF ty_bank_config.
" SEM caminhos físicos de diretório → Clean Core
```

#### Referência SAP

- [SAP Help: Custom Business Configuration](https://help.sap.com/docs/SAP_S4HANA_CLOUD/55a7cb346519450cb9e6d21c1ecd6ec1/76384d8e68e24a009a7a8b5e2a82a0e1.html)
- [SAP Help: ABAP Cloud — Customer Namespace](https://help.sap.com/docs/abap-cloud/abap-cloud/customer-namespace)

---

### 4.7 S_DATASET — Objeto de Autorização

| Atributo | Valor |
|----------|-------|
| **Tipo** | Objeto de Autorização SAP Padrão |
| **Nível Clean Core** | **C** 🔶 |
| **Liberado para ABAP Cloud** | ⚠️ Restrito — vinculado a operações de filesystem não disponíveis |
| **Uso na Solução** | Controlar acesso de leitura/gravação a arquivos no servidor |

#### Análise

O objeto de autorização **S_DATASET** controla o acesso a arquivos físicos no servidor de aplicação SAP (`OPEN DATASET`, `READ DATASET`, `WRITE DATASET`). Em S/4HANA Cloud:

- As **operações de filesystem estão bloqueadas** (OPEN/READ/WRITE DATASET não disponíveis)
- S_DATASET **perde sua função** quando não há filesystem acessível
- Representa risco moderado (C) porque não modifica padrão, mas depende de infraestrutura bloqueada

Em ambientes **on-premise em transição**, S_DATASET ainda é utilizável mas deve ser planejado para eliminação.

#### Alternativa Clean Core

```
Em S/4HANA Cloud / Arquitetura Clean Core:
✅ Autorização gerenciada pelo modelo de Communication Arrangements
✅ SAP IAG (Identity Access Governance) para controle de acesso a APIs externas
✅ OAuth 2.0 / mTLS para autenticação em serviços de storage externo (BTP)
```

#### Referência SAP

- [SAP Help: Authorization Object S_DATASET](https://help.sap.com/docs/SAP_NETWEAVER_731_BW_DELTA/753088fc00704d0a80e7fbd6803c8adb/4da9a6d3e4c94f64b7e07b9aa9c6c5b6.html)
- [SAP Help: S/4HANA Cloud — Security Model](https://help.sap.com/docs/SAP_S4HANA_CLOUD/a630d57fc73f470d8ba36d78c7a5f5d7/2e37e9c0e7764004a55b9a1cddc39b76.html)

---

### 4.8 S_PROGRAM — Objeto de Autorização

| Atributo | Valor |
|----------|-------|
| **Tipo** | Objeto de Autorização SAP Padrão |
| **Nível Clean Core** | **B** ⚠️ |
| **Liberado para ABAP Cloud** | ⚠️ Parcialmente — em contexto de jobs clássicos |
| **Uso na Solução** | Controlar a execução do programa RFEBKA00 via SUBMIT |

#### Análise

O objeto **S_PROGRAM** controla quais usuários/perfis podem executar programas ABAP. Seu nível B se justifica porque:

- É um **objeto de autorização padrão SAP** (não modifica o núcleo)
- Em S/4HANA on-premise ainda é **necessário e funcional**
- Porém, em S/4HANA Cloud, o **modelo de autorização muda** para Communication Arrangements e OAuth

O risco principal é que S_PROGRAM nesta solução **serve para autorizar a execução de RFEBKA00 via SUBMIT**, que é uma operação Nível D. Eliminar o SUBMIT elimina a necessidade de S_PROGRAM neste contexto.

#### Referência SAP

- [SAP Help: Authorization Object S_PROGRAM](https://help.sap.com/docs/SAP_NETWEAVER/db19c7071e5f4101837e23f06e576495/52d5a7c5e4ca11d1a5ae0000e8353423.html)
- [SAP Help: ABAP Cloud Authorization Concept](https://help.sap.com/docs/abap-cloud/abap-cloud/authorization-concept)

---

## 5. Nível Geral da Solução

### Diagnóstico

```
╔══════════════════════════════════════════════════════════════════╗
║          NÍVEL GERAL DA SOLUÇÃO: D (CRÍTICO)                    ║
║                                                                  ║
║  5 de 9 objetos estão em Nível D — incluindo o coração          ║
║  da solução (SUBMIT RFEBKA00 + filesystem via AL11/EPS)         ║
║                                                                  ║
║  A solução NÃO é compatível com S/4HANA Cloud                   ║
║  e apresenta riscos significativos mesmo em on-premise          ║
╚══════════════════════════════════════════════════════════════════╝
```

### Mapa de Risco por Componente

```
COMPONENTE                          NÍVEL   IMPACTO
─────────────────────────────────────────────────────
Processamento de arquivos (AL11)    [D] ❌  BLOQUEANTE para Cloud
Importação bancária (SUBMIT)        [D] ❌  BLOQUEANTE para Cloud
Listagem de diretório (EPS_FM)      [D] ❌  BLOQUEANTE para Cloud
Verificação de dados (FEBKO)        [C] 🔶  Alto risco de upgrade
Autorização de arquivo (S_DATASET)  [C] 🔶  Alto risco de Cloud
Tabela de parâmetros (Tabela Z)     [A] ✅  Seguro
Autorização de programa (S_PROGRAM) [B] ⚠️  Baixo risco
─────────────────────────────────────────────────────
NÍVEL MÉDIO PONDERADO: D (Predominância de objetos críticos)
```

---

## 6. Recomendações Técnicas e Alternativas Clean Core

### 6.1 Arquitetura Alvo — Visão de Alto Nível

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITETURA ATUAL (Nível D)                  │
│                                                                  │
│  [Banco] → [Arquivo no ASFS] → [AL11/EPS_FM] → [SUBMIT RFEBKA] │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    TRANSFORMAR PARA:
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                 ARQUITETURA ALVO (Nível A / Clean Core)         │
│                                                                  │
│  [Banco] → [SFTP Server] → [SAP Integration Suite]             │
│                                    ↓                            │
│              [API OData: Bank Statement Import]                 │
│                                    ↓                            │
│              [S/4HANA: Processamento Padrão via API]            │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Tabela de Alternativas por Objeto

| Objeto Atual | Nível | Alternativa Clean Core | Nível Alvo | Esforço |
|--------------|:-----:|------------------------|:----------:|---------|
| AL11 + caminhos físicos | D | Communication Arrangement + SFTP via Integration Suite | A | Alto |
| EPS_GET_DIRECTORY_LISTING | D | SAP Integration Suite (File Adapter/SFTP) | A | Alto |
| SUBMIT RFEBKA00 | D | API OData `API_BANKSTATEMENT_SRV` via HTTP Client | A | Médio |
| FF.5 / RFEBKA00 direto | D | API REST: `/sap/opu/odata/sap/API_BANKSTATEMENT_SRV` | A | Médio |
| SELECT FROM FEBKO | C | `SELECT FROM I_BankStatementItem` (CDS View liberada) | A | Baixo |
| S_DATASET | C | OAuth/mTLS via Communication Arrangement | A | Médio |
| SUBMIT (statement) | D | Application Job Framework `CL_APJ_DT_CREATE_IN` | A | Médio |

### 6.3 Plano de Migração em Fases

#### Fase 1 — Quick Wins (Baixo Esforço / Alto Impacto)

```abap
" AÇÃO 1: Substituir SELECT FROM FEBKO por CDS View liberada
" De:
SELECT * FROM febko WHERE ...

" Para:
SELECT FROM I_BankStatementItem
  FIELDS BankStatementID, BankStatementStatus, PostingDate
  WHERE BankStatementID = @lv_stmt_id
  INTO TABLE @DATA(lt_items).
```

#### Fase 2 — Substituição do Core (Médio Esforço)

```abap
" AÇÃO 2: Substituir SUBMIT RFEBKA00 por chamada HTTP à API liberada
" Criar classe ABAP Z que encapsula a chamada HTTP:

CLASS zcl_bank_stmt_import DEFINITION PUBLIC FINAL.
  PUBLIC SECTION.
    METHODS import_bank_statement
      IMPORTING
        iv_bank_account  TYPE string
        iv_file_content  TYPE xstring
      RETURNING
        VALUE(rv_result)  TYPE string
      RAISING
        cx_http_dest_provider_error.
ENDCLASS.

CLASS zcl_bank_stmt_import IMPLEMENTATION.
  METHOD import_bank_statement.
    " Chamar API OData liberada em vez de SUBMIT RFEBKA00
    DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
      i_comm_scenario    = 'Z_BANK_STMT_COMM_SCENARIO'
      i_outbound_service = 'Z_BANK_STMT_OUTBOUND'
    ).
    DATA(lo_http) = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
    " ... implementar chamada REST ...
  ENDMETHOD.
ENDCLASS.
```

#### Fase 3 — Arquitetura Side-by-Side (Alto Esforço / Total Clean Core)

```
Para solução totalmente Clean Core em S/4HANA Cloud:

1. REMOVER acesso ao filesystem do servidor de aplicação SAP
2. CONFIGURAR servidor SFTP externo (ou Cloud Storage: AWS S3, Azure Blob, GCP GCS)
3. CRIAR iFlow no SAP Integration Suite:
   - Trigger: Timer (agendamento)
   - Source: SFTP Adapter → busca arquivos bancários
   - Process: File parsing (MT940/CAMT)
   - Target: API OData S/4HANA → importa extrato bancário
4. MONITORAR via SAP Integration Suite Operations View
5. REMOVER programa Z customizado (substituído pelo iFlow)
```

---

## 7. Justificativas para Impossibilidade de Nível A

### 7.1 Impossibilidade de Nível A para EPS_GET_DIRECTORY_LISTING

**Não é possível manter Level A com EPS_GET_DIRECTORY_LISTING** porque:

> O acesso ao filesystem do servidor de aplicação SAP é uma **limitação de infraestrutura**, não uma limitação de API. Em S/4HANA Cloud (Public e Private Edition gerenciados pela SAP), o filesystem do servidor de aplicação não está acessível para código customizado. Isso é uma decisão de arquitetura da SAP para garantir isolamento, escalabilidade e segurança em ambiente cloud multi-tenant.
>
> **A única saída é eliminar a necessidade de ler arquivos diretamente do servidor SAP**, movendo essa responsabilidade para uma camada de integração externa (SAP Integration Suite, middleware, ou BTP).

### 7.2 Impossibilidade de Nível A para SUBMIT RFEBKA00

**Não é possível usar SUBMIT em ABAP Cloud** porque:

> O statement `SUBMIT` foi **explicitamente removido** da versão restrita do ABAP Cloud. A SAP documentou essa restrição para evitar dependências implícitas entre programas, padrão de design que é incompatível com ambientes cloud containerizados e com o modelo de ciclo de vida de APIs liberadas (C1 contract). Não há workaround — a arquitetura deve ser redesenhada para usar a API oficial de importação de extratos bancários.

### 7.3 Justificativa de Nível C (e não D) para FEBKO

**FEBKO recebe Nível C (e não D)** porque:

> O acesso é apenas de **leitura** (SELECT, não UPDATE/INSERT/DELETE), e existe uma **CDS View liberada** que pode substituir o acesso direto. A elevação para Nível D seria adequada apenas se houvesse escrita direta na tabela ou uso de campos internos não documentados. Ainda assim, deve ser migrado para Nível A usando as CDS Views disponíveis.

### 7.4 Caminho Obrigatório para Nível A (Cenário S/4HANA Cloud)

Caso o projeto SAPHIRA seja para **S/4HANA Cloud (qualquer edição)**, os objetos de Nível D representam **bloqueadores técnicos absolutos**:

| Bloqueador | Razão Técnica | Solução Obrigatória |
|------------|---------------|---------------------|
| AL11 / EPS_GET_DIRECTORY_LISTING | Filesystem não acessível | SAP Integration Suite + SFTP |
| SUBMIT RFEBKA00 | Statement proibido | API REST OData |
| RFEBKA00 direto | Programa não liberado | API REST OData |

---

## 8. Arquitetura Alvo Recomendada

### Diagrama Completo — Clean Core Level A

```
╔══════════════════════════════════════════════════════════════════════╗
║                    ARQUITETURA CLEAN CORE (Nível A)                 ║
╚══════════════════════════════════════════════════════════════════════╝

  [Banco Externo]
       │
       │ Transmite arquivo bancário (MT940 / CAMT.053)
       ▼
  [Servidor SFTP Externo]  ← Fora do SAP, infraestrutura cliente
       │
       │ SAP Integration Suite polling (SFTP Adapter)
       ▼
  ┌─────────────────────────────────────────┐
  │  SAP Integration Suite (BTP)           │
  │  ┌─────────────────────────────────┐   │
  │  │ iFlow: Bank Statement Processor │   │
  │  │  1. Buscar arquivo via SFTP     │   │
  │  │  2. Validar formato (MT940/CAMT)│   │
  │  │  3. Mapear para API payload     │   │
  │  │  4. Chamar API S/4HANA          │   │
  │  │  5. Tratar resposta (OK/Erro)   │   │
  │  │  6. Mover arquivo (SFTP rename) │   │
  │  └─────────────────────────────────┘   │
  └─────────────────────────────────────────┘
       │
       │ HTTP POST (OAuth 2.0)
       │ API: /sap/opu/odata/sap/API_BANKSTATEMENT_SRV
       ▼
  ┌─────────────────────────────────────────┐
  │  S/4HANA (Clean Core)                  │
  │  ┌─────────────────────────────────┐   │
  │  │ API OData: Bank Statement       │   │
  │  │  → Processamento padrão SAP     │   │
  │  │  → Dados em I_BankStatementItem │   │
  │  │  → Lançamentos automáticos FI   │   │
  │  └─────────────────────────────────┘   │
  └─────────────────────────────────────────┘
       │
       │ Monitoramento
       ▼
  [SAP Integration Suite: Operations View]
  [Alertas: Email / SAP Alert Management]
```

### Componentes da Arquitetura Alvo

| Componente | Tecnologia | Nível Clean Core |
|------------|------------|:----------------:|
| Recepção de arquivos bancários | SAP Integration Suite — SFTP Adapter | A ✅ |
| Parsing e mapeamento | SAP Integration Suite — Message Mapping | A ✅ |
| Importação no S/4HANA | API OData `API_BANKSTATEMENT_SRV` | A ✅ |
| Consulta de status | CDS View `I_BankStatementItem` | A ✅ |
| Configuração de parâmetros | Tabela Z (sem caminhos físicos) | A ✅ |
| Agendamento | SAP Integration Suite Timer / BTP Job Scheduling | A ✅ |
| Monitoramento | SAP Integration Suite Operations + Alert Framework | A ✅ |

---

## 9. Referências Oficiais SAP

### Documentação Clean Core e ABAP Cloud

| Documento | Link |
|-----------|------|
| SAP Help: Clean Core Extensibility | [https://help.sap.com/docs/SAP_S4HANA_CLOUD/a630d57fc73f470d8ba36d78c7a5f5d7/6c2f3ce77c4f4c78a12b4668ceeab5d6.html](https://help.sap.com/docs/SAP_S4HANA_CLOUD/a630d57fc73f470d8ba36d78c7a5f5d7/6c2f3ce77c4f4c78a12b4668ceeab5d6.html) |
| SAP Help: ABAP Cloud Released APIs | [https://help.sap.com/docs/abap-cloud/abap-cloud/released-apis](https://help.sap.com/docs/abap-cloud/abap-cloud/released-apis) |
| SAP Help: ABAP Cloud Restricted Language | [https://help.sap.com/docs/abap-cloud/abap-cloud/restricted-abap-language-version](https://help.sap.com/docs/abap-cloud/abap-cloud/restricted-abap-language-version) |
| SAP ABAP Keyword Docs (Cloud) | [https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/index.htm](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/index.htm) |
| Cloudification Repository Viewer | [https://help.sap.com/docs/abap-cloud/abap-cloud/released-apis](https://help.sap.com/docs/abap-cloud/abap-cloud/released-apis) |

### APIs SAP Liberadas para Extratos Bancários

| API | Link |
|-----|------|
| SAP API Hub: Bank Statement (API_BANKSTATEMENT_SRV) | [https://api.sap.com/api/API_BANKSTATEMENT_SRV/overview](https://api.sap.com/api/API_BANKSTATEMENT_SRV/overview) |
| SAP Help: Electronic Bank Statement Processing | [https://help.sap.com/docs/SAP_S4HANA/56bf56fbba7c4bc3b2e5ae2c1ff63fbc/bbc1f1e66f7d4b69b6a7b07e5001a2f9.html](https://help.sap.com/docs/SAP_S4HANA/56bf56fbba7c4bc3b2e5ae2c1ff63fbc/bbc1f1e66f7d4b69b6a7b07e5001a2f9.html) |

### Application Job Framework

| Documento | Link |
|-----------|------|
| SAP Help: Application Job Framework | [https://help.sap.com/docs/SAP_S4HANA_CLOUD/55a7cb346519450cb9e6d21c1ecd6ec1/e60e8b37ee2843b6a3e5af7bb7b04d33.html](https://help.sap.com/docs/SAP_S4HANA_CLOUD/55a7cb346519450cb9e6d21c1ecd6ec1/e60e8b37ee2843b6a3e5af7bb7b04d33.html) |
| SAP Help: CL_APJ_DT_CREATE_IN | [https://help.sap.com/docs/abap-cloud/abap-cloud/application-job-framework](https://help.sap.com/docs/abap-cloud/abap-cloud/application-job-framework) |

### SAP Integration Suite

| Documento | Link |
|-----------|------|
| SAP Help: Integration Suite Overview | [https://help.sap.com/docs/SAP_INTEGRATION_SUITE](https://help.sap.com/docs/SAP_INTEGRATION_SUITE) |
| SAP Help: SFTP Adapter | [https://help.sap.com/docs/cloud-integration/sap-cloud-integration/sftp-adapter](https://help.sap.com/docs/cloud-integration/sap-cloud-integration/sftp-adapter) |

### SAP Notes

| Nota | Descrição |
|------|-----------|
| [3578329](https://launchpad.support.sap.com/#/notes/3578329) | Referência de processamento bancário em ambiente Cloud |
| [2880669](https://launchpad.support.sap.com/#/notes/2880669) | Clean Core Framework — Diretrizes Gerais |
| [3390261](https://launchpad.support.sap.com/#/notes/3390261) | ABAP Cloud APIs — Lista de objetos liberados |

---

## Conclusão

A solução atual do programa SAPHIRA para automação de arquivos bancários (ACHÉ) apresenta **nível geral D — Crítico**, com **5 dos 9 objetos técnicos incompatíveis com Clean Core e ABAP Cloud**.

Os principais bloqueadores são:
1. **Acesso direto ao filesystem** do servidor SAP (AL11 + EPS_GET_DIRECTORY_LISTING)
2. **SUBMIT de programa SAP** não liberado (SUBMIT RFEBKA00)
3. **Ausência de APIs liberadas** no design atual

A **solução recomendada** é redesenhar o fluxo utilizando:
- **SAP Integration Suite** para receber e processar arquivos bancários via SFTP
- **API OData liberada** (`API_BANKSTATEMENT_SRV`) para importação no S/4HANA
- **CDS Views liberadas** (`I_BankStatementItem`) para consultas de status
- **Application Job Framework** para agendamento, em substituição ao JOB com SUBMIT

Esta arquitetura garante **100% de compatibilidade com Clean Core (Nível A)** e está alinhada com a estratégia de evolução do SAP S/4HANA Cloud.

---

*Documento gerado por análise técnica de Clean Core — SAPHIRA / ACHÉ*  
*Baseado nas diretrizes oficiais SAP e no modelo ABAP Cloud*
