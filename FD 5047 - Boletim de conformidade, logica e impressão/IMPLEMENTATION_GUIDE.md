# IMPLEMENTATION GUIDE – FD 5047

**Ordem obrigatória de criação e ativação dos objetos.**

---

## Pré-Requisitos (verificar antes de iniciar)

| # | Item | Como verificar / fazer |
|---|------|------------------------|
| P1 | Destino SM59 `ZDMS5047_DEST` criado (HTTP/HTTPS → BTP SDM) | SM59 → HTTP Connections to External Server |
| P2 | SSL: certificado BTP importado | STRUST → SSL Client (Standard) → importar cert do host `api-sdm-di.cfapps.br10.hana.ondemand.com` |
| P3 | Autenticação OAuth2 configurada em `OA2C_CONFIG` | Ou Basic Auth direto no SM59 se não usar OAuth |
| P4 | Repositório DMS `ZDMS_S4D_110` acessível | GET `https://api-sdm-di.cfapps.br10.hana.ondemand.com/browser/ZDMS_S4D_110/root` deve retornar JSON |
| P5 | TVARVC: entrada `ZFD5047_CLEANUP_DAYS` criada | SM30 → TVARVC → New Entry → tipo P, valor `15` |
| P6 | Tabela OIGSI confirmada no sistema | SE11 → OIGSI → verificar campos SHNUMBER e DOC_NUMBER. Se não existir: ver TECHNICAL_DECISIONS.md para alternativa VTTK/VTTS |
| P7 | Pacote de desenvolvimento criado | SE80 ou DEVC → criar pacote `ZFD5047` |

---

## Fase 1 – Objeto Comum (base para todas as partes)

| Seq | Objeto | Tipo ADT | Descrição |
|-----|--------|----------|-----------|
| 1.1 | `ZCL_FD5047_DMS_API` | CLAS | New ABAP Class → PUBLIC FINAL → copiar de `ZCL_FD5047_DMS_API.clas.txt` |

**Ativar antes de continuar.**  
Testar: criar breakpoint no método `find_latest_certificate` e executar um GET simples no SM59 para verificar conectividade.

---

## Fase 2 – Parte 1: RAP Stack (backend Fiori)

Ativar nesta ordem exata:

| Seq | Objeto | Tipo ADT | Arquivo fonte |
|-----|--------|----------|---------------|
| 2.0 | `ZCL_FD5047_CERT_SVC` | CLAS | `Parte1 - Fiori Upload DMS/ZCL_FD5047_CERT_SVC.clas.txt` |
| 2.1 | `ZTFD5047_CERT` | TABL | `Parte1 - Fiori Upload DMS/ZTFD5047_CERT.tabl.txt` |
| 2.2 | `ZFD5047_CERT_UPL_P` | DDLS (abstract entity) | `Parte1 - Fiori Upload DMS/ZFD5047_CERT_UPL_P.ddls.txt` |
| 2.3 | `ZI_FD5047_CERT` | DDLS (root view entity) | `Parte1 - Fiori Upload DMS/ZI_FD5047_CERT.ddls.txt` |
| 2.4 | `ZI_FD5047_CERT` | BDEF (interface) | `Parte1 - Fiori Upload DMS/ZI_FD5047_CERT.bdef.txt` |
| 2.5 | `ZBP_I_FD5047_CERT` | CLAS (behavior pool) | `Parte1 - Fiori Upload DMS/ZBP_I_FD5047_CERT.clas.txt` + `*.clas.locals_imp.txt` |
| 2.6 | `ZC_FD5047_CERT` | DDLS (projection view) | `Parte1 - Fiori Upload DMS/ZC_FD5047_CERT.ddls.txt` |
| 2.7 | `ZC_FD5047_CERT` | BDEF (projection) | `Parte1 - Fiori Upload DMS/ZC_FD5047_CERT.bdef.txt` |
| 2.8 | `ZC_FD5047_CERT_MDE` | DDLX (metadata ext.) | `Parte1 - Fiori Upload DMS/ZC_FD5047_CERT_MDE.ddlx.txt` |
| 2.9 | `ZSD_FD5047_CERT` | SRVD | `Parte1 - Fiori Upload DMS/ZSD_FD5047_CERT.srvd.txt` |
| 2.10 | `ZSB_FD5047_CERT` | SRVB | Criar manualmente → Publish (ver `ZSB_FD5047_CERT.srvb.txt`) |

> **Behavior Pool (passo 2.5):**  
> No ADT, criar a classe `ZBP_I_FD5047_CERT` como "FOR BEHAVIOR OF ZI_FD5047_CERT".  
> Copiar conteúdo de `ZBP_I_FD5047_CERT.clas.txt` para a include CPUB.  
> Copiar conteúdo de `ZBP_I_FD5047_CERT.clas.locals_imp.txt` para a include CCIMP (Local Types).
>
> **Service Binding (passo 2.10):**  
> Abrir `ZSD_FD5047_CERT` → New → OData V4 - UI → Nome: `ZSB_FD5047_CERT` → Publish.  
> Ver `Parte1 - Fiori Upload DMS/IMPLEMENTATION_GUIDE.md` para configuração do app Fiori no BAS.

---

## Fase 3 – Parte 2: Serviço de Impressão

| Seq | Objeto | Tipo ADT | Arquivo fonte |
|-----|--------|----------|---------------|
| 3.1 | `ZCL_FD5047_CERT_PRINT` | CLAS | `Parte2 - Servico Impressao/ZCL_FD5047_CERT_PRINT.clas.txt` |

> **Dependência:** Fase 1 (ZCL_FD5047_DMS_API) deve estar ativa.  
> **Integração FD 6083:** o chamador (Kit de Documentos) chama o método público:
> ```abap
> DATA lo_svc TYPE REF TO zcl_fd5047_cert_print.
> CREATE OBJECT lo_svc.
> lo_svc->print_for_transport_doc(
>   EXPORTING iv_shnumber = lv_shnumber
>   IMPORTING et_spools   = lt_spools
>             ev_success  = lv_ok
>             ev_message  = lv_msg ).
> ```

---

## Fase 4 – Parte 3: Job de Limpeza

| Seq | Objeto | Tipo ADT | Arquivo fonte |
|-----|--------|----------|---------------|
| 4.1 | `ZFD5047_CERT_CLEANUP` | PROG | `Parte3 - Job Cleanup/ZFD5047_CERT_CLEANUP.prog.txt` |

**Agendamento (SM36):**
- Job: `ZFD5047_CERT_CLEANUP`
- Frequência: 2x por mês (ex: dia 1 e dia 15)
- Horário: 02:00 (madrugada)
- Step: `ZFD5047_CERT_CLEANUP` sem variante (usa TVARVC)

---

## Checkpoint de Testes por Fase

### Fase 1 – DMS API
- [ ] SM59 → testar conexão `ZDMS5047_DEST` → RC 200
- [ ] Executar `ZCL_FD5047_DMS_API→find_latest_certificate` em SE24 com MATNR/WERKS/LGORT existentes

### Fase 2 – Parte 1 (RAP + Upload)
- [ ] Ativar ZTFD5047_CERT no SE11 → DB Table criada sem erros
- [ ] Ativar todos os objetos CDS (sem syntax errors)
- [ ] Publicar ZSB_FD5047_CERT → URL OData acessível no browser do ADT
- [ ] Criar registro via OData POST → UUID gerado, CreatedBy/CreatedAt preenchidos
- [ ] Chamar action UploadPdf com base64 válido → DmsDocId preenchido no registro
- [ ] Chamar UploadPdf com conteúdo não-PDF → erro "Apenas arquivos PDF são aceitos"
- [ ] Chamar UploadPdf novamente no mesmo registro → erro "já possui PDF"
- [ ] Tentar criar registro duplicado (mesmo MATNR+WERKS+LGORT+DATE) → erro de validação
- [ ] DELETE do registro → remove da tabela ZTFD5047_CERT

### Fase 3 – Parte 2 (Impressão)
- [ ] Chamar `print_for_transport_doc` com SHNUMBER válido (com remessa e certificado) → spool gerado
- [ ] Chamar com SHNUMBER sem certificado → `ev_success = abap_false`, mensagem informativa
- [ ] Resultado integrado com FD 6083 (chamador do kit)

### Fase 4 – Parte 3 (Job)
- [ ] Executar `ZFD5047_CERT_CLEANUP` em modo test (sem deletar) → lista documentos antigos
- [ ] Executar sem modo test → documentos deletados do DMS
- [ ] Verificar log de execução no SM37

---

## Notas de Ativação ADT

Para cada classe ABAP:
1. ADT → New ABAP Class
2. Name = nome do objeto
3. Superclass: deixar vazio
4. Interfaces: deixar vazio
5. Adicionar ao pacote `ZFD5047`
6. Copiar o conteúdo do `.clas.txt` para o editor
7. Ctrl+S → Ativar (F3 no ADT)
