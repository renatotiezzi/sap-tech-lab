# CR51 — Análise da Especificação Funcional

**Documento base:** CR51 – Reprocessamento Gap 14 - Integração MGR
**Autor EF:** Rodolfo Gambarini | **Arquiteto:** Rosana Sanches Lopes
**Status EF:** Em Especificação (versão 1 — 25/03/2026)

---

## 1. Resumo do que a EF pede

### Objetivo
Monitor Fiori para acompanhar e reprocessar arquivos TXT recebidos da MGR que falharam
na criação automática de Ordens de Venda (ZVTF, ZVTR, ZV01).

### Tabela de Arquivos — `ZARQ_MGR` (EF)

| Campo             | Tipo       | Chave | Obs |
|-------------------|------------|-------|-----|
| ID_ARQ            | NUMC 10    | ✓     | Num. Pedido + Dealer |
| TIPO_DOC_VENDAS   | CHAR       |       | |
| CABEÇALHO_ARQUIVO | CHAR 100   |       | Layout original TXT |
| BANDEIRA          | CHAR 10    |       | Ford, JCB, Renault... |
| CONTEUDO_TXT      | RAWSTRING  |       | Arquivo bruto |
| STATUS            | CHAR 20    |       | Processado/Erro/Cancelado |
| TENTATIVAS        | INT4       |       | Incrementado no reprocessamento |
| **ÚLTIMO_ERRO**   | CHAR 255   |       | **Mensagem funcional/técnica — exibida no cockpit** |
| DATA_PROCESSAMENTO| TIMESTAMP  |       | |

### Tabela de Log — `ZLOG_MGR` (EF)

| Campo        | Tipo      | Chave | Obs |
|--------------|-----------|-------|-----|
| **ID_LOG**   | NUMC 10   | ✓     | **Chave própria — permite múltiplos registros por arquivo** |
| ID_REFERÊNCIA| NUMC 10   |       | FK para ID_ARQ ou DOCNUM |
| ETAPA        | CHAR 30   |       | Leitura/Validação/OV/Remessa/Fatura/XML |
| MENSAGEM     | STRING    |       | Texto detalhado do erro |
| TIMESTAMP    | TIMESTAMP |       | Data/hora do registro |

---

## 2. GAP: EF vs Implementação Atual

### 2.1 Modelo da Tabela de Log — GAP CRÍTICO

| Aspecto               | O que a EF pede                        | O que foi implementado               |
|-----------------------|----------------------------------------|--------------------------------------|
| Chave do log          | `ID_LOG` (NUMC auto-incremental)       | `(pedido, bandeira)` — chave composta do arquivo |
| Cardinalidade         | **1:N** — múltiplos logs por arquivo   | **1:1** — 1 log por arquivo, sobrescreve |
| Histórico de tentativas | Preservado — cada tentativa gera nova linha | Perdido — só a última tentativa fica |
| Rastreabilidade       | Completa por etapa e timestamp         | Parcial — apenas último estado       |

**Trecho da EF que confirma a intenção de histórico (seção 2.4.1):**
> *"para fins de rastreabilidade, diagnóstico e análise, os erros poderão ser registrados em
> nível de item/linha do pedido (chave técnica)"*

**Trecho da EF (seção 3.3 — OBS):**
> *"para fins de registro, análise e rastreabilidade de erros, recomenda-se que os logs sejam
> mantidos em nível de item/linha do pedido, permitindo a identificação precisa de
> inconsistências específicas"*

### 2.2 Campo ÚLTIMO_ERRO na Tabela de Arquivo — GAP

| Aspecto           | EF                                  | Implementado                         |
|-------------------|-------------------------------------|--------------------------------------|
| Campo na ARQ      | `ÚLTIMO_ERRO` CHAR 255              | Não existe — a mensagem vem só do join com LOG |
| Intenção          | Exibir no cockpit o erro mais recente de forma rápida, sem join | Depende do join 1:1 com LOG |

### 2.3 Chave da Tabela de Arquivo

| Aspecto       | EF                              | Implementado              |
|---------------|---------------------------------|---------------------------|
| Chave ARQ     | `ID_ARQ` = Pedido + Dealer (NUMC 10 gerado) | `(pedido, bandeira)` diretamente |
| Impacto       | Permite chave técnica desacoplada da chave funcional | Chave funcional = chave técnica (sem separação) |

### 2.4 Nomes de Tabela

| EF              | Implementado        |
|-----------------|---------------------|
| `ZARQ_MGR`      | `ZTBQ2C_ARQ_MGR`    |
| `ZLOG_MGR`      | `ZTBQ2C_LOG_MGR`    |

Divergência de nomenclatura — provavelmente intencional (padrão Q2C do projeto).

---

## 3. O Campo de Mensagem no App — Análise

A EF define **dois locais** para a mensagem de erro:

1. `ÚLTIMO_ERRO` na tabela de arquivo (`ZARQ_MGR`) → exibição rápida no cockpit
2. `MENSAGEM` na tabela de log (`ZLOG_MGR`) → histórico detalhado por etapa

Na implementação atual:
- A app exibe `LogMensagem` que vem via join da `ZTBQ2C_LOG_MGR`
- Se o campo está vazio no banco → aparece em branco na tela
- Não existe `ÚLTIMO_ERRO` na tabela de arquivo

**Para o campo aparecer populado no app**, quem processa o arquivo (JOB/CPI) precisa:
1. Fazer UPDATE em `ZTBQ2C_LOG_MGR.mensagem` com o retorno do erro
2. **E/ou** fazer UPDATE em `ZTBQ2C_ARQ_MGR` com o campo `ÚLTIMO_ERRO` (se adicionado)

---

## 4. Pontos em Aberto para Discussão

### 4.1 Log histórico (1:N) — decisão pendente

A EF prevê histórico mas a implementação atual é 1:1.

**Opções:**
- **A) Manter 1:1** (implementação atual) → simples, atende o monitor básico. Não atende
  rastreabilidade total pedida na EF. Seria um gap documentado e aceito.
- **B) Evoluir para 1:N** (alinhado à EF) → adicionar campo `ID_LOG` como chave na tabela
  de log + sequence/GUID. Impacta behavior implementation (não mais upsert, sempre INSERT).
  App precisaria de seção de histórico ou subitem.

### 4.2 Campo ÚLTIMO_ERRO na tabela de arquivo

Adicionar `ÚLTIMO_ERRO CHAR 255` na `ZTBQ2C_ARQ_MGR` e populá-lo no behavior
a cada reprocessamento. Simplificaria o join e garantiria sempre um valor exibível
mesmo que o log seja 1:N.

### 4.3 Retenção de 30 a 90 dias

A EF define exclusão automática do log após 90 dias. Não existe job de limpeza implementado.

### 4.4 Export para Excel

A EF pede exportação do log para Excel. O Fiori Elements List Report já oferece
isso nativamente (botão de download) — basta confirmar se está habilitado no binding.

---

## 5. O que está correto na implementação (alinhado à EF)

- Tabela de arquivo separada da tabela de log ✓
- Campos STATUS, TENTATIVAS, BANDEIRA, TIPO_DOC, CONTEUDO ✓
- Actions Reprocess e Cancel no app ✓
- Imutabilidade dos dados (somente leitura + actions, sem edição de campos) ✓
- Filtros por Status, TipoDoc, Bandeira, Data ✓
- Campo ETAPA no log ✓
- Incremento de TENTATIVAS no reprocessamento ✓

---

## 6. Recomendação de Próximo Passo

Levar ao funcional (Rodolfo) e arquiteto (Rosana) a seguinte questão:

> **"A EF prevê log em nível de item com ID_LOG próprio (1:N por arquivo).
> A implementação atual usa 1:1 (sobrescreve). Confirmamos manter 1:1
> como simplificação aceita, ou evoluímos para 1:N conforme a EF?"**

A decisão impacta:
- Estrutura da tabela `ZTBQ2C_LOG_MGR` (adição de campo chave)
- Behavior implementation (upsert → insert)
- App Fiori (exibição de histórico ou só último estado)
- Transporte e migração de dados existentes
