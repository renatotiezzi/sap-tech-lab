# Implementation Guide - CR51 List Report (LR)

## Objetivo
Este guia descreve a ordem exata para implementar no ambiente SAP a solucao RAP LR localizada em CR51_ListReport, com foco em List Report (pagina unica) e sem dependencia de item filho na app.

## Pre-requisitos
- Tabelas existentes no ambiente: ZTBQ2C_ARQ_MGR e ZTBQ2C_LOG_MGR.
- Classe utilitaria existente para integracao: ZCL_Q2C_CPI_CALLER.
- Pacote/transporte definidos para os novos objetos LR.
- Permissao para ativacao e publicacao de Service Binding OData V4.

## Estrutura de Implementacao
- Base comum (BO/interface/behavior): CR51_Page_Unica
- Projection de servico tecnico: CR51_Page_Unica_SRV
- Projection da app FE + metadata: CR51_Page_Unica_APP

## Ordem Recomendada de Criacao e Ativacao

### Fase 1 - Base comum (obrigatoria)
1. ZI_Q2C_LOGLR_MGR (DDLS)
2. ZI_Q2C_ARQLR_MGR (DDLS)
3. ZBP_I_Q2C_ARQLR_MGR (classe global)
4. ZI_Q2C_ARQLR_MGR (BDEF)
5. ZBP_I_Q2C_ARQLR_MGR (CCIMP / locals_imp)

Arquivos de referencia:
- CR51_Page_Unica/ZI_Q2C_LOGLR_MGR.ddls.txt
- CR51_Page_Unica/ZI_Q2C_ARQLR_MGR.ddls.txt
- CR51_Page_Unica/ZBP_I_Q2C_ARQLR_MGR.clas.txt
- CR51_Page_Unica/ZI_Q2C_ARQLR_MGR.bdef.txt
- CR51_Page_Unica/ZBP_I_Q2C_ARQLR_MGR.clas.locals_imp.txt

### Fase 2 - Projection de servico tecnico (SRV)
1. ZC_Q2C_ARQLR_MGR (DDLS)
2. ZC_Q2C_ARQLR_MGR (BDEF)
3. ZSD_Q2C_MGRLR (SRVD)
4. Criar no ADT o Binding ZSB_Q2C_MGRLR (OData V4 - UI), ativar e publicar

Arquivos de referencia:
- CR51_Page_Unica_SRV/ZC_Q2C_ARQLR_MGR.ddls.txt
- CR51_Page_Unica_SRV/ZC_Q2C_ARQLR_MGR.bdef.txt
- CR51_Page_Unica_SRV/ZSD_Q2C_MGRLR.srvd.txt
- CR51_Page_Unica_SRV/ZSB_Q2C_MGRLR.srvb.txt

### Fase 3 - Projection da app FE (APP)
1. ZC_Q2C_ARQLR_MGR_APP (DDLS)
2. ZC_Q2C_ARQLR_MGR_APP (BDEF)
3. ZC_Q2C_ARQLR_MGR_APP_MDE (DDLX)
4. ZSD_Q2C_MGRLR_APP (SRVD)
5. Criar no ADT o Binding ZSB_Q2C_MGRLR_APP (OData V4 - UI), ativar e publicar

Arquivos de referencia:
- CR51_Page_Unica_APP/ZC_Q2C_ARQLR_MGR_APP.ddls.txt
- CR51_Page_Unica_APP/ZC_Q2C_ARQLR_MGR_APP.bdef.txt
- CR51_Page_Unica_APP/ZC_Q2C_ARQLR_MGR_APP_MDE.ddlx.txt
- CR51_Page_Unica_APP/ZSD_Q2C_MGRLR_APP.srvd.txt
- CR51_Page_Unica_APP/ZSB_Q2C_MGRLR_APP.srvb.txt

## Checklist de Validacao Pos-Ativacao
1. Metadata OData abre sem erro no endpoint da app.
2. Entity set ArqMgrApp existe no servico ZSD_Q2C_MGRLR_APP.
3. List Report carrega registros sem popup tecnico.
4. Filtros principais operando:
   - Status
   - TipoDoc
   - Bandeira
   - Pedido
   - Data/Hora
5. Actions operando sem dump:
   - Reprocess
   - Cancel
6. Em registro sem log, tela nao apresenta erro tecnico (campos de log podem ficar vazios).

## Sequencia de Smoke Test (5 minutos)
1. Abrir preview da app publicada (binding APP).
2. Executar busca sem filtro (Go).
3. Filtrar Status = ERRO e validar retorno.
4. Executar Reprocess em um registro de teste.
5. Confirmar mudanca de status/tentativas e atualizacao de LogMensagem/LogEtapa.
6. Executar Cancel em outro registro de teste.

## Troubleshooting Rapido
- Erro tecnico com texto oculto (Gateway):
  - Verificar /IWFND/ERROR_LOG e ST22.
  - Confirmar que o binding publicado e o endpoint usado sao do conjunto LR.
- Erro de metadata antiga:
  - Limpar cache browser e reabrir em janela anonima.
- Erro de ativacao por dependencia:
  - Reativar na ordem das fases acima.
- Action com falha:
  - Validar disponibilidade e parametros da classe ZCL_Q2C_CPI_CALLER no ambiente.

## Observacoes de Projeto
- A app LR e page-unica/list-report-first.
- O log exibido na UI e o ultimo estado (campos achatados no root), evitando navegacao de item filho na app.
- A modelagem evita o ponto que gerava UX ruim e erro tecnico ao tentar tratar associacao 0..1 como tabela de item.
