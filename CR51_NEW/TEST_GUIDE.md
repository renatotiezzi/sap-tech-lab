# TEST GUIDE — CR51 ARQ MGR Service

Serviço OData V4 Web API exposto via `ZSB_Q2C_ARQ_MGR_SVR`.  
Entity set: **ArqSvr** | Chaves: `Pedido` + `Bandeira`

---

## Base URL

```
/sap/opu/odata4/sap/zsd_q2c_arq_mgr_svr/srvd_a2x/sap/zsd_q2c_arq_mgr_svr/0001/ArqSvr
```

---

## 1. POST — Criar Registro

CPI envia arquivo para SAP iniciar processamento.

### FORD — NF nova

```json
POST /ArqSvr
Content-Type: application/json

{
  "Pedido":     "PED-FORD-001",
  "Bandeira":   "FORD",
  "TipoDoc":    "NF",
  "Arquivo":    "NF_FORD_001.xml",
  "Conteudo":   "<NF><Pedido>PED-FORD-001</Pedido></NF>",
  "Status":     "PENDENTE",
  "Tentativas": 0,
  "Ernam":      "CPI_USER"
}
```

### RENAULT — NF nova

```json
POST /ArqSvr
Content-Type: application/json

{
  "Pedido":     "PED-REN-001",
  "Bandeira":   "RENAULT",
  "TipoDoc":    "NF",
  "Arquivo":    "NF_REN_001.xml",
  "Conteudo":   "<NF><Pedido>PED-REN-001</Pedido></NF>",
  "Status":     "PENDENTE",
  "Tentativas": 0,
  "Ernam":      "CPI_USER"
}
```

---

## 2. PATCH — Callback de Status

CPI atualiza o registro após processamento assíncrono.

### FORD — Processado com sucesso

```json
PATCH /ArqSvr(Pedido='PED-FORD-001',Bandeira='FORD')
Content-Type: application/json

{
  "Status":     "PROCESSADO",
  "Tentativas": 1,
  "UltimoErro": ""
}
```

### RENAULT — Erro no processamento

```json
PATCH /ArqSvr(Pedido='PED-REN-001',Bandeira='RENAULT')
Content-Type: application/json

{
  "Status":     "ERRO",
  "Tentativas": 1,
  "UltimoErro": "Timeout na integração com sistema legado Renault"
}
```

### FORD — Segunda tentativa após reprocessamento

```json
PATCH /ArqSvr(Pedido='PED-FORD-001',Bandeira='FORD')
Content-Type: application/json

{
  "Status":     "CANCELADO",
  "Tentativas": 3,
  "UltimoErro": "Máximo de tentativas atingido"
}
```

---

## 3. GET — Consultar Registro

```
GET /ArqSvr(Pedido='PED-FORD-001',Bandeira='FORD')
GET /ArqSvr(Pedido='PED-REN-001',Bandeira='RENAULT')
```

### Listar todos

```
GET /ArqSvr
```

### Filtrar por Status

```
GET /ArqSvr?$filter=Status eq 'ERRO'
GET /ArqSvr?$filter=Status eq 'CANCELADO'
GET /ArqSvr?$filter=Bandeira eq 'FORD'
```

---

## 4. Valores válidos de Status

| Status | Descrição |
|--------|-----------|
| `PENDENTE` | Aguardando processamento |
| `PROCESSADO` | Processado com sucesso |
| `ERRO` | Falha no processamento — elegível para reprocessamento |
| `CANCELADO` | Cancelado manualmente ou por excesso de tentativas |

---

## 5. Ações disponíveis via Fiori (Object Page)

| Ação | dataAction | Disponível para |
|------|-----------|-----------------|
| Reprocessar | `Reprocess` | Status = ERRO |
| Cancelar | `Cancel` | Status = ERRO ou PENDENTE |
