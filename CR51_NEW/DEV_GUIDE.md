# CR51 NEW — Guia de Desenvolvimento

**Baseado em:** EF CR51 – Reprocessamento Gap 14 - Integração MGR (Rodolfo Gambarini, 25/03/2026)
**Diferença principal em relação à versão anterior (CR51_ListReport):**
ARQ e LOG são entidades **completamente independentes** — apps separados, serviços separados, sem composition, sem relação parent/child no RAP. LOG é 1:N (histórico completo de tentativas) ligado ao ARQ apenas pela chave funcional (Pedido + Bandeira).

---

## Decisões de Arquitetura

### ARQ — Tabela de Arquivos
- Representa o **pedido/arquivo** recebido da MGR
- Chave: `(PEDIDO, BANDEIRA)` — chave funcional de negócio
- Guarda o conteúdo original do TXT e o status atual
- Campo `ULTIMO_ERRO` STRING para exibição rápida no cockpit sem precisar de join
- **Imutável pelo usuário** — somente leitura + actions

### LOG — Tabela de Log
- Representa **cada tentativa de processamento** do arquivo
- Chave: `(PEDIDO, BANDEIRA, DATUM, UZEIT)` — chave funcional + data/hora da tentativa
- Relação 1:N com ARQ **apenas pelo dado** (Pedido + Bandeira) — sem vínculo RAP
- Cada reprocessamento gera **nova linha** no log — nunca sobrescreve
- Entidade independente: **app próprio, serviço próprio**

### Separação de responsabilidades
```
ZTBN_Q2C_ARQ_MGR   →  O QUE e QUAL STATUS (pedido atual)
ZTBN_Q2C_LOG_MGR   →  O QUE ACONTECEU e QUANDO (histórico de tentativas)
```

---

## 1. Modelo de Dados

### 1.1 Tabela ZTBN_Q2C_ARQ_MGR

| Campo         | Tipo ABAP   | Chave | Descrição                              |
|---------------|-------------|-------|----------------------------------------|
| PEDIDO        | CHAR(35)    | ✓     | Nº do pedido MGR                       |
| BANDEIRA      | CHAR(10)    | ✓     | Dealer / Montadora (Ford, JCB, Renault...) |
| TIPO_DOC      | CHAR(4)     |       | ZVTF / ZVTR / ZV01                     |
| CABEC_ARQ     | CHAR(100)   |       | Cabeçalho original do TXT              |
| CONTEUDO      | RAWSTRING   |       | Arquivo bruto conforme Q2C014I000      |
| STATUS        | CHAR(20)    |       | ERRO / EM_PROCESSAMENTO / PROCESSADO / CANCELADO |
| TENTATIVAS    | INT4        |       | Incrementado a cada reprocessamento    |
| ULTIMO_ERRO   | STRING      |       | Última mensagem de erro — exibição rápida cockpit |
| DATUM         | DATS        |       | Data do último processamento           |
| UZEIT         | TIMS        |       | Hora do último processamento           |
| ERNAM         | CHAR(12)    |       | Usuário do último processamento        |

> **ULTIMO_ERRO STRING:** sem limite de tamanho — guarda a mensagem completa do último erro
> diretamente na ARQ, sem necessidade de join com o LOG para exibição na lista.

### 1.2 Tabela ZTBN_Q2C_LOG_MGR

| Campo         | Tipo ABAP   | Chave | Descrição                              |
|---------------|-------------|-------|----------------------------------------|
| PEDIDO        | CHAR(35)    | ✓     | FK → ZTBN_Q2C_ARQ_MGR (chave pai)     |
| BANDEIRA      | CHAR(10)    | ✓     | FK → ZTBN_Q2C_ARQ_MGR (chave pai)     |
| DATUM         | DATS        | ✓     | Data da tentativa                      |
| UZEIT         | TIMS        | ✓     | Hora da tentativa                      |
| ETAPA         | CHAR(30)    |       | Leitura / Validação / OV / Remessa / Fatura / XML |
| MENSAGEM      | STRING      |       | Texto detalhado do erro/sucesso        |
| ERNAM         | CHAR(12)    |       | Usuário que executou                   |

> **Chave (Pedido + Bandeira + Datum + Uzeit):** identifica unicamente cada tentativa.
> Garante rastreabilidade direta sem FK numérica — a chave do pai está na própria linha.
> Cada tentativa = INSERT de nova linha. Nunca UPDATE/UPSERT.
> Atenção: se dois reprocessamentos ocorrerem no mesmo segundo, o segundo falha na INSERT.
> Mitigação: usar TIMESTAMP (DATS+TIMS+microsegundo) ou aceitar a limitação por design.

### 1.3 Number Ranges necessários
- Nenhum — a chave é funcional em ambas as tabelas.

---

## 2. Objetos RAP — Estrutura

> ARQ e LOG são **BO independentes** — sem composition, sem parent/child.
> Cada um tem seu próprio serviço e app Fiori.

### BO 1 — ARQ (Monitor / Reprocessamento)

```
ZI_Q2C_ARQ_MGR       (DDLS)  → Root entity standalone — lê ZTBN_Q2C_ARQ_MGR
ZI_Q2C_ARQ_MGR       (BDEF)  → managed, actions Reprocess e Cancel
ZBP_I_Q2C_ARQ_MGR    (CLAS)  → Behavior implementation
ZBP_I_Q2C_ARQ_MGR    (CCIMP) → Actions e determinações

ZC_Q2C_ARQ_MGR_APP   (DDLS)  → Projection — cockpit Fiori
ZC_Q2C_ARQ_MGR_APP   (BDEF)  → use action Reprocess; use action Cancel
ZC_Q2C_ARQ_MGR_APP_MDE (DDLX) → Anotações UI
ZSD_Q2C_ARQ_MGR_SVR  (SRVD)  → expose ArqMgrApp
ZSB_Q2C_ARQ_MGR_SVR  (SRVB)  → OData V4 - UI
```

### BO 2 — LOG (Histórico — app separado, somente leitura)

```
ZI_Q2C_LOG_MGR         (DDLS)  → Root entity standalone — lê ZTBN_Q2C_LOG_MGR
ZI_Q2C_LOG_MGR         (BDEF)  → managed read-only (sem actions, sem create, sem impl. class)

ZC_Q2C_LOG_MGR_APP     (DDLS)  → Projection — histórico Fiori
ZC_Q2C_LOG_MGR_APP     (BDEF)  → Projection BDEF read-only (obrigatório pelo RAP)
ZC_Q2C_LOG_MGR_APP_MDE (DDLX)  → Anotações UI
ZSD_Q2C_LOG_MGR_SVR    (SRVD)  → expose LogMgrApp
ZSB_Q2C_LOG_MGR_SVR    (SRVB)  → OData V4 - UI
```

> **Nomenclatura:** interfaces sem sufixo adicional; projeções com `_APP`; serviços (SRVD/SRVB) com `_SVR`.

---

## 3. Modelo RAP — ZI_Q2C_ARQ_MGR (DDLS)

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface ARQ MGR - Reprocessamento'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_Q2C_ARQ_MGR
  as select from ztbn_q2c_arq_mgr as arq
  association [0..*] to ZI_Q2C_LOG_MGR as _Log
    on  $projection.Pedido   = _Log.Pedido
    and $projection.Bandeira = _Log.Bandeira
{
  key arq.pedido      as Pedido,
  key arq.bandeira    as Bandeira,
      arq.tipo_doc    as TipoDoc,
      arq.cabec_arq   as CabecArq,
      arq.conteudo    as Conteudo,
      arq.status      as Status,
      case arq.status
        when 'ERRO'             then 1
        when 'EM_PROCESSAMENTO' then 2
        when 'PROCESSADO'       then 3
        when 'CANCELADO'        then 0
        else 0
      end             as StatusCriticality,
      arq.tentativas  as Tentativas,
      arq.ultimo_erro as UltimoErro,
      arq.datum       as Datum,
      arq.uzeit       as Uzeit,
      arq.ernam       as Ernam,

      /* Associations */
      _Log
}
```

---

## 4. Modelo RAP — ZI_Q2C_LOG_MGR (DDLS)

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface LOG MGR - Histórico de Processamento'
@Metadata.ignorePropagatedAnnotations: true

// BO independente — sem composition, sem associação pai/filho RAP.
// Ligado ao ARQ apenas pelo dado (Pedido + Bandeira).
// Cada linha = uma tentativa de processamento (INSERT, nunca UPDATE).
define root view entity ZI_Q2C_LOG_MGR
  as select from ztbn_q2c_log_mgr as log
{
  key log.pedido   as Pedido,
  key log.bandeira as Bandeira,
  key log.datum    as Datum,
  key log.uzeit    as Uzeit,
      log.etapa    as Etapa,
      log.mensagem as Mensagem,
      log.ernam    as Ernam
}
```

---

## 5. Behavior Definitions

### BDEF — ZI_Q2C_ARQ_MGR (ARQ)

```abap
managed implementation in class ZBP_I_Q2C_ARQ_MGR unique;
strict ( 2 );

define behavior for ZI_Q2C_ARQ_MGR alias ArqMgr
  persistent table ztbn_q2c_arq_mgr
  lock master
  authorization master ( global )
  etag master Uzeit
{
  // update necessário para MODIFY IN LOCAL MODE nas actions
  update;

  field ( readonly ) Pedido; Bandeira; TipoDoc; CabecArq; Conteudo;
  field ( readonly ) Status; Tentativas; UltimoErro; Datum; Uzeit; Ernam;
  // StatusCriticality é campo calculado no CDS — não declarar em field(readonly)

  action Reprocess result [1] $self;
  action Cancel    result [1] $self;

  // Associação de leitura ao LOG — navegação Object Page ARQ → histórico
  association _Log { }

  mapping for ztbn_q2c_arq_mgr
  {
    Pedido     = pedido;
    Bandeira   = bandeira;
    TipoDoc    = tipo_doc;
    CabecArq   = cabec_arq;
    Conteudo   = conteudo;
    Status     = status;
    Tentativas = tentativas;
    UltimoErro = ultimo_erro;
    Datum      = datum;
    Uzeit      = uzeit;
    Ernam      = ernam;
  }
}
```

### BDEF — ZI_Q2C_LOG_MGR (LOG — somente leitura)

```abap
managed;
strict ( 2 );

define behavior for ZI_Q2C_LOG_MGR alias LogMgr
  persistent table ztbn_q2c_log_mgr
  lock master
  // authorization: não declarar — acesso controlado via @AccessControl no DDLS
{
  field ( readonly ) Pedido; Bandeira; Datum; Uzeit; Etapa; Mensagem; Ernam;

  mapping for ztbn_q2c_log_mgr
  {
    Pedido   = pedido;
    Bandeira = bandeira;
    Datum    = datum;
    Uzeit    = uzeit;
    Etapa    = etapa;
    Mensagem = mensagem;
    Ernam    = ernam;
  }
}
```

---

## 6. Behavior Implementation — Lógica das Actions

### Action Reprocess
```
1. Ler registro ARQ pelo Pedido + Bandeira
2. Validar STATUS != CANCELADO e != EM_PROCESSAMENTO
3. UPDATE ARQ:
   - STATUS = 'EM_PROCESSAMENTO'
   - TENTATIVAS = TENTATIVAS + 1
   - DATUM/UZEIT/ERNAM = sy-datum/sy-uzeit/sy-uname
4. INSERT nova linha em LOG:
   - PEDIDO = Pedido, BANDEIRA = Bandeira (chave pai)
   - DATUM = sy-datum, UZEIT = sy-uzeit (chave temporal)
   - ETAPA = 'REPROCESSAMENTO'
   - MENSAGEM = 'Reprocessamento iniciado'
   - DATUM/UZEIT/ERNAM = sy-datum/sy-uzeit/sy-uname
5. Chamar ZCL_Q2C_CPI_CALLER (ou equivalente)
6. Se OK:
   - UPDATE ARQ: STATUS = 'PROCESSADO', ULTIMO_ERRO = ''
   - INSERT LOG: ETAPA = 'CONCLUSAO', MENSAGEM = 'Processado com sucesso'
7. Se ERRO:
   - UPDATE ARQ: STATUS = 'ERRO', ULTIMO_ERRO = mensagem_erro (STRING — sem truncação)
   - INSERT LOG: ETAPA = etapa_erro, MENSAGEM = mensagem_erro (STRING completa)
```

> **CRÍTICO:** O LOG é sempre INSERT — nunca UPDATE. Isso garante o histórico completo.

### Action Cancel
```
1. Validar STATUS != PROCESSADO
2. UPDATE ARQ: STATUS = 'CANCELADO', DATUM/UZEIT/ERNAM
3. INSERT LOG: ETAPA = 'CANCELAMENTO', MENSAGEM = 'Cancelado pelo usuário'
```

---

## 7. App Fiori — Estrutura da Tela

### Página principal (List Report)
Colunas visíveis:
- Status (com ícone de criticidade)
- Pedido
- Bandeira
- TipoDoc
- Tentativas
- **UltimoErro** ← campo direto da ARQ, sem join, sempre populado
- Datum / Uzeit

Ações na lista:
- **Reprocessar** (action Reprocess)
- **Cancelar Erro** (action Cancel)

Filtros:
- Status (Value Help)
- Bandeira
- TipoDoc
- Pedido
- Data (range)

### Object Page (detalhe do registro — App ARQ)
Facets:
1. **Informações do Arquivo** → Pedido, Bandeira, TipoDoc, Status, Tentativas
2. **Último Erro** → UltimoErro (STRING, multiline, readonly)
3. **Conteúdo Original** → CabecArq, Conteudo (binário, readonly)
4. **Histórico de Processamento** → tabela com todas as linhas de LOG daquele Pedido+Bandeira (`#LINEITEM_REFERENCE` → `_Log`)

> O usuário clica no registro ARQ → Object Page abre → seção LOG exibe **todas** as tentativas (Datum, Uzeit, Etapa, Mensagem, Ernam), ordenáveis.

### App LOG (app separado — histórico standalone)
List Report independente, acessível diretamente pelo Fiori Launchpad:
- Colunas: Pedido, Bandeira, Datum, Uzeit, Etapa, Mensagem, Ernam
- Filtros: Pedido, Bandeira, Data (range), Etapa
- Serve para consulta avançada / cruzada — independente do App ARQ

---

## 8. Projeções APP

### ZC_Q2C_ARQ_MGR_APP (DDLS) — App ARQ

```abap
@EndUserText.label: 'ARQ MGR - Cockpit Reprocessamento'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_Q2C_ARQ_MGR_APP
  provider contract transactional_query
  as projection on ZI_Q2C_ARQ_MGR
{
  key Pedido,
  key Bandeira,
      TipoDoc,
      CabecArq,
      Conteudo,
      Status,
      StatusCriticality,
      Tentativas,
      UltimoErro,
      Datum,
      Uzeit,
      Ernam,

      /* Associations */
      _Log : redirected to ZC_Q2C_LOG_MGR_APP
}
```

### ZC_Q2C_LOG_MGR_APP (DDLS) — App LOG

```abap
@EndUserText.label: 'LOG MGR - Histórico de Processamento'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_Q2C_LOG_MGR_APP
  provider contract transactional_query
  as projection on ZI_Q2C_LOG_MGR
{
  key Pedido,
  key Bandeira,
  key Datum,
  key Uzeit,
      Etapa,
      Mensagem,
      Ernam
}
```

---

## 9. Ordem de Criação e Ativação

### Fase 1 — Tabelas
1. `ZTBN_Q2C_ARQ_MGR` (SE11 / ADT)
2. `ZTBN_Q2C_LOG_MGR` (SE11 / ADT)

### Fase 2 — BO LOG (criar antes do ARQ — ARQ referencia o LOG na association)
1. `ZI_Q2C_LOG_MGR` (DDLS)
2. `ZI_Q2C_LOG_MGR` (BDEF — read-only, sem classe de impl.)
3. `ZC_Q2C_LOG_MGR_APP` (DDLS)
4. `ZC_Q2C_LOG_MGR_APP` (BDEF — projection read-only)
5. `ZC_Q2C_LOG_MGR_APP_MDE` (DDLX)
6. `ZSD_Q2C_LOG_MGR_SVR` (SRVD)
7. `ZSB_Q2C_LOG_MGR_SVR` (SRVB — criar e publicar no ADT)

### Fase 3 — BO ARQ (depende do LOG para a association `_Log`)
1. `ZI_Q2C_ARQ_MGR` (DDLS)
2. `ZBP_I_Q2C_ARQ_MGR` (CLAS — global)
3. `ZI_Q2C_ARQ_MGR` (BDEF)
4. `ZBP_I_Q2C_ARQ_MGR` (CCIMP — locals_imp)
5. `ZC_Q2C_ARQ_MGR_APP` (DDLS)
6. `ZC_Q2C_ARQ_MGR_APP` (BDEF)
7. `ZC_Q2C_ARQ_MGR_APP_MDE` (DDLX)
8. `ZSD_Q2C_ARQ_MGR_SVR` (SRVD — expõe ARQ + LOG para navegação Object Page)
9. `ZSB_Q2C_ARQ_MGR_SVR` (SRVB — criar e publicar no ADT)

### Fase 4 — Job de Limpeza (APJ)
1. Criar Log Object `ZQ2C_LOG` (subobject `CLEANUP`) via `SBAL_OBJECT`
2. Criar `ZCL_Q2C_MGR_CLEANUP` (CLAS) — implementa `IF_APJ_DT/RT_EXEC_OBJECT`
3. Criar Job Catalog Entry `ZQ2C_CLEANUP_CE` no ADT → aponta para `ZCL_Q2C_MGR_CLEANUP`
4. Criar Job Template `ZQ2C_CLEANUP_JT` no ADT → usa Catalog Entry, `P_DAYS = 90`
5. Agendar via app Fiori **F2373 Application Jobs**

---

## 10. Pontos que precisam de decisão antes de codificar

| # | Ponto                          | Opções                                     | Quem decide     |
|---|--------------------------------|--------------------------------------------|-----------------|
| 1 | Nome das tabelas               | `ZTBN_Q2C_*` ou outro padrão              | Arquiteto       |
| 2 | Pacote / transporte            | Definir pacote Q2C para os novos objetos   | Basis / Arquiteto |
| 3 | Colisão de chave no LOG        | E se dois reprocessamentos ocorrerem no mesmo segundo? Usar TIMESTAMP com microsegundo ou aceitar limitação? | Dev + Arquiteto |
| 4 | Quem chama o INSERT no LOG?    | Behavior impl. ou classe externa de integração? | Dev        |
| 5 | Campo CONTEUDO tipo RAWSTRING  | Suportado como campo de tabela em S4 ABAP? Alternativa: LCHR ou tabela filho de linhas | Dev |
| 6 | Retenção 90 dias               | Job de limpeza — quando implementar?       | Funcional / Basis |
| 7 | Export Excel                   | Nativo no FE List Report (já disponível)   | — confirmar UI5 version |
| 8 | Autorização / Role             | Qual role SAP para acesso ao cockpit?      | Basis / Funcional |

---

## 11. Diferenças em relação à versão anterior (CR51_ListReport)

| Aspecto                  | CR51_ListReport (anterior)         | CR51_NEW (esta versão)                |
|--------------------------|------------------------------------|---------------------------------------|
| Chave ARQ                | `(pedido, bandeira)` — funcional   | `(pedido, bandeira)` — mesma, funcional |
| Chave LOG                | `(pedido, bandeira)` — 1:1         | `(pedido, bandeira, datum, uzeit)` — 1:N histórico por data/hora |
| Campo mensagem no cockpit| Join com LOG (pode vir vazio)      | `ULTIMO_ERRO` direto na ARQ           |
| Histórico de tentativas  | Não — sobrescreve sempre           | Sim — INSERT a cada tentativa        |
| Apps                     | Um único app (page única)          | **Dois apps separados**: ARQ (cockpit) e LOG (histórico) |
| Alinhamento com EF       | Parcial                            | Total                                 |
