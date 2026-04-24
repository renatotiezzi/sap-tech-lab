# CR51_APP - Aplicativo de Reprocessamento MGR

## Visão Geral
Aplicativo Fiori para monitoramento e reprocessamento de pedidos MGR com erro.

---

## Arquitetura dos Objetos (Parte 2)

```
┌─────────────────────────────────────────────────────────┐
│ ZC_Q2C_ARQ_MGR_APP (Projeção CDS)                       │
│ - Readonly + Associação com LOG                         │
│ - Actions: Reprocess, Cancel                            │
└─────────────────────────────────────────────────────────┘
                          ↑
                          │ (herda de)
                          │
┌─────────────────────────────────────────────────────────┐
│ ZI_Q2C_ARQ_MGR (Interface CDS Compartilhada)            │
│ - Tabela base: ZTBQ2C_ARQ_MGR                          │
│ - Compartilhada com ZC_Q2C_ARQ_MGR (CRUD)              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ ZC_Q2C_ARQ_MGR_APP.bdef (Behavior Definition)           │
│ - read (readonly)                                        │
│ - action Reprocess → invoca handler                     │
│ - action Cancel → invoca handler                        │
└─────────────────────────────────────────────────────────┘
                          ↑
                          │
┌─────────────────────────────────────────────────────────┐
│ ZBP_I_Q2C_ARQ_MGR_APP.clas.locals_imp                   │
│ lhc_arq_mgr_app                                         │
│ - reprocess → chama ZCL_Q2C_REPROCESS_ACTION            │
│ - cancel → atualiza status                              │
└─────────────────────────────────────────────────────────┘
                          ↑
                          │
┌─────────────────────────────────────────────────────────┐
│ ZCL_Q2C_REPROCESS_ACTION                                │
│ - execute( pedido, bandeira )                           │
│ - Incrementa TENTATIVAS                                 │
│ - Reseta STATUS = 'EM_PROCESSAMENTO'                   │
│ - Chama ZCL_Q2C_CPI_CALLER                              │
└─────────────────────────────────────────────────────────┘
                          ↑
                          │
┌─────────────────────────────────────────────────────────┐
│ ZCL_Q2C_CPI_CALLER                                      │
│ - call_cpi_reprocess( pedido, bandeira, conteudo, ...)  │
│ - prepare_payload( ) → Serializa JSON                  │
│ - execute_http_call( ) → Chama CPI/API                  │
└─────────────────────────────────────────────────────────┘
                          ↓
                        CPI/API
```

---

## Fluxo de Reprocessamento

```
1. Usuário clica "Reprocess" no APP Fiori
        ↓
2. OData dispara Action Reprocess
        ↓
3. Handler lhc_arq_mgr_app.reprocess() ativa
        ↓
4. ZCL_Q2C_REPROCESS_ACTION.execute() inicia
        ├─ read_arq_data( ) → Busca do arquivo
        ├─ update_tentativas( ) → +1 tentativa
        ├─ update_status( ) → 'EM_PROCESSAMENTO'
        └─ cpi_caller->call_cpi_reprocess( )
                ↓
5. ZCL_Q2C_CPI_CALLER.call_cpi_reprocess()
        ├─ prepare_payload( ) → JSON
        └─ execute_http_call( ) → POST/GET
                ↓
6. CPI processa e retorna status
        ↓
7. Resposta volta ao APP → Usuário vê resultado
```

---

## Objetos Gerados

### 1️⃣ CDS Views
- **ZC_Q2C_ARQ_MGR_APP.ddls** → Projeção readonly + composition
- **ZC_Q2C_LOG_MGR.ddls** → Já gerada em CR51 (child)

### 2️⃣ Behavior Definitions
- **ZC_Q2C_ARQ_MGR_APP.bdef** → Actions (Reprocess, Cancel) + read
- **ZBP_I_Q2C_ARQ_MGR_APP.clas** → Classe global (abstract)
- **ZBP_I_Q2C_ARQ_MGR_APP.clas.locals_imp** → Handlers (lhc_arq_mgr_app)

### 3️⃣ Classes ABAP
- **ZCL_Q2C_REPROCESS_ACTION.clas** → Orquestrador do reprocessamento
  - execute( pedido, bandeira )
  - read_arq_data( )
  - update_tentativas( )
  - update_status( )

- **ZCL_Q2C_CPI_CALLER.clas** → Integração com CPI
  - call_cpi_reprocess( pedido, bandeira, conteudo, tipo_doc )
  - prepare_payload( ) → **CUSTOMIZE AQUI com seu JSON**
  - execute_http_call( ) → **CUSTOMIZE AQUI com sua API**

### 4️⃣ Services
- **ZSD_Q2C_MGR_APP.srvd** → Service Definition (expõe ArqMgrApp + LogMgr)
- **ZSB_Q2C_MGR_APP.srvb** → Service Binding OData V4 UI (criar no ADT)

---

## Passos de Ativação no SAP

### Fase 1: Ativar Objetos CDS
```
1. Abrir cada arquivo .ddls na pasta CR51_APP
2. Clicar em Activate (Ctrl+Shift+F3)
   - ZC_Q2C_ARQ_MGR_APP.ddls
   - ZC_Q2C_LOG_MGR.ddls (se ainda não)
```

### Fase 2: Ativar Behavior
```
1. Ativar ZC_Q2C_ARQ_MGR_APP.bdef
2. Ativar ZBP_I_Q2C_ARQ_MGR_APP.clas
   - Inclui automaticamente locals_imp
```

### Fase 3: Ativar Classes ABAP
```
1. Ativar ZCL_Q2C_REPROCESS_ACTION.clas
2. Ativar ZCL_Q2C_CPI_CALLER.clas
   - Aqui você customiza os TODOs
```

### Fase 4: Ativar Service Definition
```
1. Ativar ZSD_Q2C_MGR_APP.srvd
```

### Fase 5: Criar Service Binding (Manual no ADT)
```
1. Right-click on package → New → Service Binding
2. Nome: ZSB_Q2C_MGR_APP
3. Tipo: OData V4 - UI
4. Service Def: ZSD_Q2C_MGR_APP
5. Activate + Publish
```

---

## Customização Necessária

### ❌ OBRIGATÓRIO: ZCL_Q2C_CPI_CALLER

No método `prepare_payload()`:
```abap
METHOD prepare_payload.
  " Customize conforme estrutura JSON esperada pelo seu CPI
  " Exemplo:
  DATA json TYPE string.
  json = |{|
       & | "pedido": "|pedido|",|
       & | "bandeira": "|bandeira|",|
       & | "tipo_doc": "|tipo_doc|",|
       & | "conteudo": "|conteudo|"|
       & |}|.
  rs_payload = json.
ENDMETHOD.
```

No método `execute_http_call()`:
```abap
METHOD execute_http_call.
  " Customize sua chamada HTTP/REST
  " Opciones:
  " - cl_http_client → REST API
  " - /iwcm/client_api → WebService
  " - Seu mecanismo de integração
  
  " TODO: Implementar chamada conforme seu CPI
  
  rs_response = 'Sucesso'. " Placeholder
ENDMETHOD.
```

### ⚠️ Validação: Campos no Log
Se precisar registrar erros no LOG com mais detalhes:
- Editar `ZCL_Q2C_REPROCESS_ACTION` → método `execute()`
- Adicionar INSERT em `ZTBQ2C_LOG_MGR` conforme necessário

---

## Teste Rápido (Após Ativação)

1. **Criar teste manualmente:**
   - INSERT em ZTBQ2C_ARQ_MGR com STATUS = 'ERRO'
   - INSERT em ZTBQ2C_LOG_MGR

2. **Abrir Service Binding (Preview):**
   - Clicar em "Publish" → Preview
   - Selecionar ArqMgrApp collection
   - Filtrar STATUS = 'ERRO'
   - Clicar em Reprocess → Monitor Log

3. **Validar resultado:**
   - TENTATIVAS deve ter incrementado
   - STATUS deve ter mudado para 'EM_PROCESSAMENTO'
   - CPI deve ter sido chamado (verificar logs de network)

---

## Questionário de Validação

- [ ] Todos os 8 objetos estão na pasta CR51_APP?
- [ ] ZCL_Q2C_CPI_CALLER customizado com sua API?
- [ ] Service Binding criado manualmente no ADT?
- [ ] Teste Reprocess executado com sucesso?
- [ ] LOG registrado corretamente em ZTBQ2C_LOG_MGR?
- [ ] Tabelas ZTBQ2C_ARQ_MGR e ZTBQ2C_LOG_MGR criadas no SAP?

---

## Próximos Passos

- Parte 3: Job de Processamento automático (disparado pelo CPI após reprocessamento)
- Integração com CPI para processar conteúdo JSON
- Fiori UI para visualizar APP (fora do escopo RAP)
