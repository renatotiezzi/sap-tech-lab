# CR51 ListReport - Arquitetura

## Visao Geral
CR51_ListReport contem uma variacao paralela da solucao RAP para monitor de reprocessamento MGR.
O objetivo e entregar uma experiencia de List Report (pagina unica) com operacao estavel e sem dependencia de item filho na app.

## Principios da Solucao
- Nomenclatura dedicada com sufixo LR para evitar conflito com a versao anterior.
- Separacao em 3 camadas/pastas: base comum, servico tecnico e app FE.
- Campos do ultimo log expostos no root da app para simplificar UX.
- Actions de negocio mantidas no root: Reprocess e Cancel.

## Estrutura de Pastas

### CR51_Page_Unica (Base comum)
Contem os objetos de dominio/interface e implementacao RAP.

Objetos:
- ZI_Q2C_ARQLR_MGR.ddls.txt
- ZI_Q2C_LOGLR_MGR.ddls.txt
- ZI_Q2C_ARQLR_MGR.bdef.txt
- ZBP_I_Q2C_ARQLR_MGR.clas.txt
- ZBP_I_Q2C_ARQLR_MGR.clas.locals_imp.txt

Responsabilidades:
- Definir entidade raiz e entidade de log.
- Mapear para tabelas persistentes ZTBQ2C_ARQ_MGR e ZTBQ2C_LOG_MGR.
- Implementar determinacoes administrativas (Datum/Uzeit/Ernam).
- Implementar actions Reprocess e Cancel.
- Atualizar/gerar ultimo log via rotina upsert.

### CR51_Page_Unica_SRV (Projection de servico tecnico)
Contem a projection para exposicao de servico tecnico.

Objetos:
- ZC_Q2C_ARQLR_MGR.ddls.txt
- ZC_Q2C_ARQLR_MGR.bdef.txt
- ZSD_Q2C_MGRLR.srvd.txt
- ZSB_Q2C_MGRLR.srvb.txt (instrucao de criacao no ADT)

Responsabilidades:
- Expor a projection root para integracao tecnica.
- Disponibilizar CRUD + actions do BO root.

### CR51_Page_Unica_APP (Projection da app Fiori Elements)
Contem projection da app e anotacoes UI.

Objetos:
- ZC_Q2C_ARQLR_MGR_APP.ddls.txt
- ZC_Q2C_ARQLR_MGR_APP.bdef.txt
- ZC_Q2C_ARQLR_MGR_APP_MDE.ddlx.txt
- ZSD_Q2C_MGRLR_APP.srvd.txt
- ZSB_Q2C_MGRLR_APP.srvb.txt (instrucao de criacao no ADT)

Responsabilidades:
- Expor entidade ArqMgrApp para FE.
- Configurar filtros, colunas e facets relevantes para monitor.
- Expor actions Reprocess e Cancel na lista.

## Modelo de Dados da UI (Root + Ultimo Log)
A app usa um unico root de consumo com campos principais do arquivo e campos do ultimo processamento:
- Dados de negocio: Pedido, Bandeira, TipoDoc, Status, Tentativas.
- Auditoria: Datum, Uzeit, Ernam.
- Ultimo log: LogIdRef, LogEtapa, LogMensagem, LogDatum, LogUzeit, LogErnam.

Essa abordagem remove a necessidade de tratar log como item navegavel na app.

## Fluxo Funcional
1. Usuario lista erros no List Report.
2. Usuario aplica filtros e seleciona registros.
3. Action Reprocess chama CPI e atualiza status/tentativas/log.
4. Action Cancel marca cancelamento e atualiza log.
5. UI exibe resultado no mesmo contexto root.

## Dependencias Externas
- Tabelas: ZTBQ2C_ARQ_MGR, ZTBQ2C_LOG_MGR.
- Classe: ZCL_Q2C_CPI_CALLER (integracao).

## Objetos de Servico Publicados
- Servico APP (UI): ZSD_Q2C_MGRLR_APP
  - Entity set: ArqMgrApp
- Servico SRV (tecnico): ZSD_Q2C_MGRLR
  - Entity set: ArqMgr

## Boas Praticas de Deploy
- Ativar em ordem: Base comum -> SRV -> APP.
- Publicar bindings somente apos ativacao sem erros.
- Testar metadata e cache em janela anonima apos publish.
- Validar ST22 e /IWFND/ERROR_LOG se surgir popup tecnico.

## Estado Atual
- Scaffold completo e consistente no repositorio.
- Pronto para implementacao/ativacao no ambiente SAP conforme guia.
- Sem erros estruturais detectados no workspace local.
