# CR51 NEW — Guia de Implementação

Passo a passo para criação dos objetos no sistema SAP via ADT (Eclipse).
Siga a ordem exata — objetos dependentes são criados depois dos que referenciam.

---

## Pré-requisitos

- [ ] Pacote de desenvolvimento criado (ex: `ZQ2C_CR51`) e transporte aberto
- [ ] Tabelas `ZTBQ2C_ARQ_MGR` e `ZTBQ2C_LOG_MGR` definidas no SE11 ou ADT
- [ ] Classe `ZCL_Q2C_CPI_CALLER` existente ou stub (`METHOD call_cpi_reprocess. ENDMETHOD.`) criado antes de ativar o CCIMP
- [ ] Usuário com perfil `S_DEVELOP` e acesso ao Fiori Launchpad (apps F2373, SBAL_OBJECT)

---

## Fase 1 — Tabelas (SE11 / ADT)

### 1.1 ZTBQ2C_ARQ_MGR

| Campo       | Tipo        | Chave | Observação                          |
|-------------|-------------|-------|-------------------------------------|
| MANDT       | MANDT       | ✓     | Mandante (SAP padrão)               |
| PEDIDO      | CHAR(20)    | ✓     | Nº do pedido MGR                    |
| BANDEIRA    | CHAR(10)    | ✓     | Dealer / Montadora                  |
| TIPO_DOC    | CHAR(4)     |       | ZVTF / ZVTR / ZV01                  |
| ARQUIVO     | STRING      |       | Cabeçalho do arquivo — payload CPI  |
| CONTEUDO    | STRING      |       | Arquivo bruto                       |
| STATUS      | CHAR(20)    |       | CRIADO / ERRO / PROCESSADO / CANCELADO |
| TENTATIVAS  | NUMC(3)     |       | Contador de reprocessamentos        |
| DATUM       | DATS        |       | Data do último processamento        |
| UZEIT       | TIMS        |       | Hora do último processamento        |
| ERNAM       | CHAR(12)    |       | Usuário do último processamento     |
| ULTIMO_ERRO | STRING      |       | Última mensagem de erro (visível no cockpit) |

- Delivery Class: `A`
- Data Browser / Table View Maintenance: `Display/Maintenance Allowed`

### 1.2 ZTBQ2C_LOG_MGR

| Campo       | Tipo        | Chave | Observação                          |
|-------------|-------------|-------|-------------------------------------|
| MANDT       | MANDT       | ✓     | Mandante                            |
| PEDIDO      | CHAR(20)    | ✓     | FK funcional → ZTBQ2C_ARQ_MGR      |
| BANDEIRA    | CHAR(10)    | ✓     | FK funcional → ZTBQ2C_ARQ_MGR      |
| DATUM       | DATS        | ✓     | Data da tentativa                   |
| UZEIT       | TIMS        | ✓     | Hora da tentativa                   |
| ID_REF      | CHAR(10)    |       | Referência cruzada (ex: UUID do CPI) |
| ETAPA       | CHAR(30)    |       | REPROCESSAMENTO / CONCLUSAO / CANCELAMENTO / ERRO |
| MENSAGEM    | STRING      |       | Texto completo do erro/sucesso      |
| ERNAM       | CHAR(12)    |       | Usuário que executou                |

- Delivery Class: `A`
- Data Browser / Table View Maintenance: `Display/Maintenance Allowed`

> Ativar ambas as tabelas antes de prosseguir.

---

## Fase 2 — BO LOG (criar antes do ARQ)

> O ARQ referencia `ZI_Q2C_LOG_MGR` na association `_Log` — LOG deve existir primeiro.

### 2.1 ZI_Q2C_LOG_MGR (DDLS)

1. ADT → New → **Data Definition** → nome `ZI_Q2C_LOG_MGR`
2. Copiar conteúdo de `Log/ZI_Q2C_LOG_MGR.ddls.txt`
3. Ativar

### 2.2 ZI_Q2C_LOG_MGR (BDEF)

1. ADT → New → **Behavior Definition** → nome `ZI_Q2C_LOG_MGR`
2. Tipo: **Managed**
3. Copiar conteúdo de `Log/ZI_Q2C_LOG_MGR.bdef.txt`
4. Ativar
5. **Não gerar classe de implementação** — LOG é read-only, sem actions

### 2.3 ZC_Q2C_LOG_MGR_APP (DDLS)

1. ADT → New → **Data Definition** → nome `ZC_Q2C_LOG_MGR_APP`
2. Copiar conteúdo de `Log/ZC_Q2C_LOG_MGR_APP.ddls.txt`
3. Ativar

### 2.4 ZC_Q2C_LOG_MGR_APP (BDEF)

1. ADT → New → **Behavior Definition** → nome `ZC_Q2C_LOG_MGR_APP`
2. Tipo: **Projection**
3. Copiar conteúdo de `Log/ZC_Q2C_LOG_MGR_APP.bdef.txt`
4. Ativar

### 2.5 ZC_Q2C_LOG_MGR_APP_MDE (DDLX)

1. ADT → New → **Metadata Extension** → nome `ZC_Q2C_LOG_MGR_APP_MDE`
2. Copiar conteúdo de `Log/ZC_Q2C_LOG_MGR_APP_MDE.ddlx.txt`
3. Ativar

### 2.6 ZSD_Q2C_LOG_MGR_APP (SRVD)

1. ADT → New → **Service Definition** → nome `ZSD_Q2C_LOG_MGR_APP`
2. Copiar conteúdo de `Log/ZSD_Q2C_LOG_MGR_APP.srvd.txt`
3. Ativar

### 2.7 ZSB_Q2C_LOG_MGR_APP (SRVB)

1. ADT → New → **Service Binding** → nome `ZSB_Q2C_LOG_MGR_APP`
2. Binding Type: **OData V4 - UI**
3. Service Definition: `ZSD_Q2C_LOG_MGR_APP`
4. Ativar → **Publish**

---

## Fase 2.5 — Classe CPI Caller (antes do BDEF ARQ)

> O CCIMP de `ZBP_I_Q2C_ARQ_MGR` instancia `ZCL_Q2C_CPI_CALLER` — a classe **deve existir e estar ativa**
> antes de ativar o BDEF (passo 3.3) e o CCIMP (passo 3.4).

### 2.8 ZCL_Q2C_CPI_CALLER (CLAS)

1. ADT → New → **ABAP Class** → nome `ZCL_Q2C_CPI_CALLER`
2. Visibilidade: **Public**, Final
3. Copiar conteúdo de `Arq - Monitor/ZCL_Q2C_CPI_CALLER.clas.txt`
4. Ativar
5. ⚠️ **Não usar** o arquivo de `CR51_ListReport/Backup/` — assinatura diferente

---

## Fase 3 — BO ARQ

### 3.1 ZI_Q2C_ARQ_MGR (DDLS)

1. ADT → New → **Data Definition** → nome `ZI_Q2C_ARQ_MGR`
2. Copiar conteúdo de `Arq - Monitor/ZI_Q2C_ARQ_MGR.ddls.txt`
3. Ativar

### 3.2 ZBP_I_Q2C_ARQ_MGR (CLAS — global)

1. ADT → New → **ABAP Class** → nome `ZBP_I_Q2C_ARQ_MGR`
2. Copiar conteúdo de `Arq - Monitor/ZBP_I_Q2C_ARQ_MGR.clas.txt`
3. Ativar (classe global abstrata + final — lógica está no CCIMP)

### 3.3 ZI_Q2C_ARQ_MGR (BDEF)

1. ADT → New → **Behavior Definition** → nome `ZI_Q2C_ARQ_MGR`
2. Tipo: **Managed**
3. Copiar conteúdo de `Arq - Monitor/ZI_Q2C_ARQ_MGR.bdef.txt`
4. Ativar

### 3.4 ZBP_I_Q2C_ARQ_MGR (CCIMP — locals_imp)

1. Abrir `ZBP_I_Q2C_ARQ_MGR` no ADT
2. Navegar para aba **Local Types** (locals_imp)
3. Copiar conteúdo de `Arq - Monitor/ZBP_I_Q2C_ARQ_MGR.clas.locals_imp.txt`
4. Ativar

### 3.5 ZC_Q2C_STATUS_VH_APP (DDLS — Value Help Status)

> ⚠️ **Criar antes de ZC_Q2C_ARQ_MGR_APP** — a projeção ARQ referencia esta entidade
> via `@Consumption.valueHelpDefinition`. O CDS compiler valida a existência em tempo de ativação.

1. ADT → New → **Data Definition** → nome `ZC_Q2C_STATUS_VH_APP`
2. Copiar conteúdo de `Arq - Monitor/ZC_Q2C_STATUS_VH_APP.ddls.txt`
3. Ativar

### 3.6 ZC_Q2C_ARQ_MGR_APP (DDLS)

1. ADT → New → **Data Definition** → nome `ZC_Q2C_ARQ_MGR_APP`
2. Copiar conteúdo de `Arq - Monitor/ZC_Q2C_ARQ_MGR_APP.ddls.txt`
3. Ativar

### 3.7 ZC_Q2C_ARQ_MGR_APP (BDEF)

1. ADT → New → **Behavior Definition** → nome `ZC_Q2C_ARQ_MGR_APP`
2. Tipo: **Projection**
3. Copiar conteúdo de `Arq - Monitor/ZC_Q2C_ARQ_MGR_APP.bdef.txt`
4. Ativar

### 3.8 ZC_Q2C_ARQ_MGR_APP_MDE (DDLX)

1. ADT → New → **Metadata Extension** → nome `ZC_Q2C_ARQ_MGR_APP_MDE`
2. Copiar conteúdo de `Arq - Monitor/ZC_Q2C_ARQ_MGR_APP_MDE.ddlx.txt`
3. Ativar

### 3.9 ZSD_Q2C_ARQ_MGR_APP (SRVD)

1. ADT → New → **Service Definition** → nome `ZSD_Q2C_ARQ_MGR_APP`
2. Copiar conteúdo de `Arq - Monitor/ZSD_Q2C_ARQ_MGR_APP.srvd.txt`
3. Ativar
4. ℹ️ Este serviço expõe **ARQ + StatusVH**

### 3.10 ZSB_Q2C_ARQ_MGR_APP (SRVB)

1. ADT → New → **Service Binding** → nome `ZSB_Q2C_ARQ_MGR_APP`
2. Binding Type: **OData V4 - UI**
3. Service Definition: `ZSD_Q2C_ARQ_MGR_APP`
4. Ativar → **Publish**

---

## Fase 4 — Inbound CPI (callback de resultado — Web API)

> Pré-requisito: Fases 2 e 3 concluídas (ZI_Q2C_LOG_MGR e ZI_Q2C_ARQ_MGR ativos).

### 4.1 ZC_Q2C_ARQ_MGR_SVR (DDLS)

1. ADT → New → **Data Definition** → nome `ZC_Q2C_ARQ_MGR_SVR`
2. Copiar conteúdo de `Arq - INB/ZC_Q2C_ARQ_MGR_SVR.ddls.txt`
3. Ativar

### 4.2 ZC_Q2C_ARQ_MGR_SVR (BDEF)

1. ADT → New → **Behavior Definition** → tipo **Projection** → nome `ZC_Q2C_ARQ_MGR_SVR`
2. Copiar conteúdo de `Arq - INB/ZC_Q2C_ARQ_MGR_SVR.bdef.txt`
3. Ativar

### 4.3 ZSD_Q2C_ARQ_MGR_SVR (SRVD)

1. ADT → New → **Service Definition** → nome `ZSD_Q2C_ARQ_MGR_SVR`
2. Copiar conteúdo de `Arq - INB/ZSD_Q2C_ARQ_MGR_SVR.srvd.txt`
3. Ativar

### 4.4 ZSB_Q2C_ARQ_MGR_SVR (SRVB)

1. ADT → New → **Service Binding** → nome `ZSB_Q2C_ARQ_MGR_SVR`
2. **Binding Type: OData V4 - Web API** ← IMPORTANTE: Web API, não UI
3. Service Definition: `ZSD_Q2C_ARQ_MGR_SVR`
4. Ativar → **Publish**

### 4.5 ZC_Q2C_LOG_MGR_SVR (DDLS)

1. ADT → New → **Data Definition** → nome `ZC_Q2C_LOG_MGR_SVR`
2. Copiar conteúdo de `Log - INB/ZC_Q2C_LOG_MGR_SVR.ddls.txt`
3. Ativar

### 4.6 ZC_Q2C_LOG_MGR_SVR (BDEF)

1. ADT → New → **Behavior Definition** → tipo **Projection** → nome `ZC_Q2C_LOG_MGR_SVR`
2. Copiar conteúdo de `Log - INB/ZC_Q2C_LOG_MGR_SVR.bdef.txt`
3. Ativar

### 4.7 ZSD_Q2C_LOG_MGR_SVR (SRVD)

1. ADT → New → **Service Definition** → nome `ZSD_Q2C_LOG_MGR_SVR`
2. Copiar conteúdo de `Log - INB/ZSD_Q2C_LOG_MGR_SVR.srvd.txt`
3. Ativar

### 4.8 ZSB_Q2C_LOG_MGR_SVR (SRVB)

1. ADT → New → **Service Binding** → nome `ZSB_Q2C_LOG_MGR_SVR`
2. **Binding Type: OData V4 - Web API** ← IMPORTANTE: Web API, não UI
3. Service Definition: `ZSD_Q2C_LOG_MGR_SVR`
4. Ativar → **Publish**

> **Autenticação CPI → SAP:** configurar usuário técnico via Communication Arrangement.
> Consultar arquivo `.srvb.txt` de cada inbound para exemplo de payload JSON.

---

## Fase 5 — Job de Limpeza (APJ)

### 5.1 Log Object BALI

1. Transação `SBAL_OBJECT`
2. Criar novo objeto:
   - **Object**: `ZQ2C_LOG`
   - **Subobject**: `CLEANUP`
   - **Descrição**: `Q2C MGR — Log de limpeza de registros antigos`
3. Salvar

### 5.2 ZCL_Q2C_MGR_CLEANUP (CLAS)

1. ADT → New → **ABAP Class** → nome `ZCL_Q2C_MGR_CLEANUP`
2. Copiar conteúdo de `JOB/ZCL_Q2C_MGR_CLEANUP.clas.txt`
3. Ativar

### 5.3 Job Catalog Entry

1. ADT → New → **Application Job Catalog Entry**
2. Dados:
   - **Name**: `ZQ2C_CLEANUP_CE`
   - **Descrição**: `Q2C MGR — Limpeza de registros antigos (90 dias)`
   - **Class**: `ZCL_Q2C_MGR_CLEANUP`
3. Ativar

### 5.4 Job Template

1. ADT → New → **Application Job Template**
2. Dados:
   - **Name**: `ZQ2C_CLEANUP_JT`
   - **Descrição**: `Q2C MGR — Template limpeza mensal`
   - **Catalog Entry**: `ZQ2C_CLEANUP_CE`
   - **P_DAYS**: `90`
3. Ativar

### 5.5 Agendamento

1. Abrir app Fiori **F2373 Application Jobs**
2. **Schedule New Job** → Template: `ZQ2C_CLEANUP_JT`
3. Recorrência sugerida: **diária às 01:00**
4. Ajustar `P_DAYS` se necessário

---

## Checklist de Validação

### App ARQ — Monitor
- [ ] SRVB publicado com sucesso (status = Published)
- [ ] Preview no ADT abre List Report com colunas: Pedido, Bandeira, Status, TipoDoc, Tentativas
- [ ] Status exibe ícone de criticidade (vermelho = ERRO, verde = PROCESSADO, cinza = CANCELADO)
- [ ] Botões "Reprocessar" e "Cancelar" visíveis na lista
- [ ] Clicar em um registro abre Object Page com 2 facets (Dados Gerais, Histórico de Processamento)
- [ ] Seção "Histórico de Processamento" exibe linhas do LOG daquele Pedido+Bandeira
- [ ] Action Reprocess: status muda para PROCESSADO (sucesso) ou ERRO (falha) + ULTIMO_ERRO preenchido
- [ ] Action Cancel: status muda para CANCELADO
- [ ] Após cada action: nova linha inserida em ZTBQ2C_LOG_MGR

### App LOG — Histórico
- [ ] SRVB publicado com sucesso
- [ ] List Report exibe todas as linhas com filtro por Pedido + Bandeira
- [ ] Object Page de uma linha de LOG exibe Etapa e Mensagem completa (multiline)

### Job de Limpeza
- [ ] `ZCL_Q2C_MGR_CLEANUP` ativa sem erro de sintaxe
- [ ] Job Catalog Entry ativo e apontando para a classe correta
- [ ] Execução manual via F2373 completa sem dump
- [ ] Log BALI gerado e visível no app Application Logs
- [ ] Registros com STATUS = ERRO **não** foram removidos

---

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---------|----------------|---------|
| DDLS não ativa — `ZI_Q2C_LOG_MGR not found` | LOG criado depois do ARQ | Criar LOG primeiro (Fase 2 antes da Fase 3) |
| CCIMP não ativa — `ZCL_Q2C_CPI_CALLER unknown` | Classe CPI não existe | Criar stub da classe antes de ativar o CCIMP |
| Object Page não mostra seção LOG | `ZC_Q2C_LOG_MGR_APP` não exposta no SRVD ARQ | Verificar `ZSD_Q2C_ARQ_MGR_SVR` — deve expor ambas as projeções |
| Action retorna erro sem mensagem | `get_global_authorizations` bloqueando | Verificar se usuário tem acesso; rever lógica de auth |
| Segunda tentativa no mesmo segundo falha | Colisão de chave no LOG (Pedido+Bandeira+Datum+Uzeit) | Decisão de design — ver DEV_GUIDE Seção 1.2 |
| Job não aparece em F2373 | Catalog Entry não ativado | Verificar se `ZQ2C_CLEANUP_CE` está ativo e publicado |
