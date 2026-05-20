# TECHNICAL DECISIONS – FD 5047

**Data:** 20/05/2026  
**Status:** Rascunho para validação técnico-funcional

---

## Erros e Inconsistências Encontrados na EF

### 🔴 CRÍTICO – Contradição na Regra de Bloqueio (Seções 2.1 vs 3.1)

| Local | Texto |
|-------|-------|
| Seção 2.1 – Regras Funcionais | *"Na ausência de certificado para determinado item, o processo de impressão **DEVE ser interrompido**"* |
| Seção 3.1 – Tabela de Exceções | *"A impressão será realizada **somente dos documentos disponíveis**"* |

**Contradição direta.** As duas regras são opostas.

**Decisão técnica adotada:** Regra mais restritiva = **interromper** a impressão.  
Motivo: evitar expedição sem certificado obrigatório é o objetivo central do negócio.

> **⚠️ Validar com funcional antes de ativar** – se a regra "parcial" for aceita, alterar o método `print_for_transport_doc` para retornar `ev_partial = abap_true` em vez de falhar.

---

### 🟡 ATENÇÃO – Tabela OIGSI (precisa verificação no sistema)

A EF cita:
```
OIGSI-SHNUMBER  → número do TD (Documento de Transporte)
OIGSI-DOC_NUMBER → número da remessa
```

**OIGSI é uma tabela de SAP TM (Transportation Management).**  
Pode **não existir** em sistemas S/4HANA SD puro sem TM ativo, ou ter nome diferente.

**Alternativa SD clássica:**
- Shipment: `VTTK` (TKNUM = número do transporte)
- Remessas no transporte: `VTTS` (TKNUM + VBELN)

> **⚠️ Verificar SE11 → OIGSI no sistema do cliente antes de codificar.**  
> Se não existir: substituir por `VTTK`/`VTTS` nas queries da classe `ZCL_FD5047_CERT_PRINT`.

---

### 🟡 ATENÇÃO – DMS Cloud vs On-Premise

A EF menciona "SAP DMS" (termo on-premise) mas os endpoints fornecidos são **BTP-hosted**:
```
https://api-sdm-di.cfapps.br10.hana.ondemand.com/browser/...
```
Este é o **SAP Document Management Service (SDM)** baseado em CMIS REST – serviço de nuvem BTP.

**Impactos:**
1. O ABAP backend S/4HANA precisa de acesso de rede ao BTP (destino SM59)
2. Autenticação via OAuth2 Client Credentials (ou Basic) – **não documentado na EF**
3. O SM59 destino `ZDMS5047_DEST` precisa ser criado e certificado SSL importado

> **⚠️ Solicitar ao BTP admin:** client ID + client secret ou credenciais Basic para configuração do SM59.

---

### 🟡 ATENÇÃO – Mecanismo de Geração de SPOOL a Partir de PDF

A EF diz *"Gerar spool separado para cada certificado encontrado, diretamente via SAP"*.  
**Não especifica o mecanismo técnico** para converter bytes PDF (obtidos do DMS) em um SPOOL SAP.

**Abordagem implementada:**
- `RSPO_OPEN_SPOOLREQUEST` para abrir a requisição de spool
- Escrita dos bytes PDF via mecanismo a confirmar com equipe BASIS  
  (candidatos: `RSPO_WRITE_RAWDATA_TO_SPOOL`, `CL_ABAP_SPOOL` ou equivalente)

> **⚠️ Gap técnico** – método `create_spool_from_pdf` da classe `ZCL_FD5047_CERT_PRINT` contém `TODO` explícito.  
> Confirmar com BASIS qual função/API está disponível no sistema para escrita de PDF binário em spool.

---

### 🟡 ATENÇÃO – Parâmetro D-15 sem Destino de Configuração

A EF menciona "D-15 dias" mas não define onde este parâmetro é configurado.

**Decisão:** usar `TVARVC` (tabela standard de parâmetros do sistema).

| Chave | Tipo | Valor padrão |
|-------|------|-------------|
| `ZFD5047_CLEANUP_DAYS` | `P` (Single value) | `15` |

> **Pré-requisito:** criar a entrada via `SM30 → TVARVC` antes de agendar o job.

---

### 🟡 ATENÇÃO – Estrutura de Pastas DMS não Definida na EF

A EF não especifica como os documentos são organizados no DMS.

**Estrutura proposta (confirmada neste projeto):**
```
/root/Certificados/{MATNR}/{WERKS}/{LGORT}/{MATNR}_{WERKS}_{LGORT}_{YYYYMMDD}.pdf
```

**Lógica de "mais recente":**  
Browse da pasta `{MATNR}/{WERKS}/{LGORT}` com `orderBy=cmis:creationDate DESC`, pegar o primeiro resultado.

> **⚠️ Validar se o DMS já tem documentos cadastrados com outra estrutura.**  
> Se sim, adaptar `get_folder_path()` e `build_doc_name()` em `ZCL_FD5047_DMS_API`.

---

### 🟢 INFO – Campo de Autenticação OAuth2

O destino `ZDMS5047_DEST` no SM59 deve ser configurado com:
- **Tipo:** HTTP Connection to External Server
- **SSL:** Ativo (HTTPS)
- **Autenticação:** `OAuth 2.0` → Token Endpoint configurado via transaction `OA2C_CONFIG`

O token endpoint típico para BTP br10:
```
https://[subdomain].authentication.br10.hana.ondemand.com/oauth/token
```

---

## Decisões de Arquitetura

| Decisão | Motivo |
|---------|--------|
| Classe `ZCL_FD5047_DMS_API` separada (comum) | Reutilizada pelas 3 partes; evita duplicação de código HTTP |
| Parte 1 usa classe de serviço (`ZCL_FD5047_CERT_SVC`) separada da API DMS | Separação de concerns: validações de negócio vs. HTTP |
| Parte 2: regra de bloqueio em nível de item (não de remessa) | Cada item deve ter certificado; um item faltante bloqueia todo o TD |
| D-15 via TVARVC | Parametrizável sem transporte de código |
| Estrutura de pasta DMS por MATNR/WERKS/LGORT | Busca por "mais recente" via browse de pasta com sort DESC por data |
