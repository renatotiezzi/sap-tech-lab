# Ajustes V2 — Implementacao Estavel (Release Antigo)

## Delta do V2 final

- Modelo de navegacao consolidado em SUM -> MGR (sem DET_APP no pacote).
- Calculo do ultimo registro feito em 2 helpers deterministicos:
  - ZI_Q2C_LOG_LAST: max(datum) por chave
  - ZI_Q2C_LOG_LAST_TIME: max(uzeit) na ultima data
- ZI_Q2C_LOG_SUM faz join por pedido+bandeira+lastdatum+lastuzeit.

## Objetos do pacote V2 final

- ZI_Q2C_LOG_LAST.ddls.txt
- ZI_Q2C_LOG_LAST_TIME.ddls.txt
- ZI_Q2C_LOG_DET.ddls.txt
- ZI_Q2C_LOG_SUM.ddls.txt
- ZBP_I_Q2C_LOG_SUM.clas.txt
- ZBP_I_Q2C_LOG_SUM.clas.locals_imp.txt
- ZI_Q2C_LOG_SUM.bdef.txt
- ZC_Q2C_LOG_MGR_APP.ddls.txt
- ZC_Q2C_LOG_MGR_APP.bdef.txt
- ZC_Q2C_LOG_MGR_APP_MDE.ddlx.txt
- ZC_Q2C_LOG_SUM_APP.ddls.txt
- ZC_Q2C_LOG_SUM_APP.bdef.txt
- ZC_Q2C_LOG_SUM_APP_MDE.ddlx.txt
- ZSD_Q2C_LOG_MGR_APP.srvd.txt

## Ordem de ativacao obrigatoria

1. ZI_Q2C_LOG_LAST.ddls
2. ZI_Q2C_LOG_LAST_TIME.ddls
3. ZI_Q2C_LOG_DET.ddls
4. ZI_Q2C_LOG_SUM.ddls
5. ZBP_I_Q2C_LOG_SUM.clas
6. ZBP_I_Q2C_LOG_SUM.clas.locals_imp
7. ZI_Q2C_LOG_SUM.bdef
8. ZC_Q2C_LOG_MGR_APP.ddls
9. ZC_Q2C_LOG_MGR_APP.bdef
10. ZC_Q2C_LOG_SUM_APP.ddls
11. ZC_Q2C_LOG_SUM_APP.bdef
12. ZC_Q2C_LOG_MGR_APP_MDE.ddlx
13. ZC_Q2C_LOG_SUM_APP_MDE.ddlx
14. ZSD_Q2C_LOG_MGR_APP.srvd
15. Republicar ZSB_Q2C_LOG_MGR_APP

## Sequencia minima para destravar quando aparece "mostra tudo"

1. Ativar ZC_Q2C_LOG_MGR_APP.ddls (tem que selecionar de ZI_Q2C_LOG_DET)
2. Ativar ZC_Q2C_LOG_MGR_APP.bdef
3. Ativar ZC_Q2C_LOG_SUM_APP.ddls (tem que redirecionar _Detail para ZC_Q2C_LOG_MGR_APP)
4. Ativar ZC_Q2C_LOG_SUM_APP.bdef
5. Ativar ZSD_Q2C_LOG_MGR_APP.srvd
6. Republicar binding

## Check rapido no Eclipse

1. Preview em ZI_Q2C_LOG_SUM: deve vir 1 linha por pedido+bandeira.
2. Preview em ZC_Q2C_LOG_SUM_APP: deve espelhar o SUM.
3. Preview em ZC_Q2C_LOG_MGR_APP: aqui e detalhe, pode ter varias linhas.

Se ZI_Q2C_LOG_SUM ainda vier igual tabela inteira, nao e UI: a view base ainda nao esta ativa com a versao nova.

