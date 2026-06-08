# GAP316 - Ajustes V04 (ATC)

Formato direto, no modelo pedido: "trocar X por Y" ou "impossivel agora".

1. Trocar busca na DDIC `T001L` por CDS released de deposito/tanque.
Objeto: `ZI_S2M_DEPOSITO_TANQUE` (linha ~6, `as select from t001l`).
Status V04: acredito que seja impossivel com seguranca agora.
Motivo: o filtro usa `oib_tnkassign`, campo especifico IS-OIL; trocar sem equivalente released pode quebrar regra de tanque.

2. Trocar FM interno `CO_XT_COMPONENT_ADD` por API released de alteracao de componente.
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~139).
Status V04: acredito que seja impossivel sem quebrar.
Pode tentar: POC com API released de Process Order Component em branch separado.

3. Trocar FM interno `CO_XT_COMPONENTS_DELETE` por API released de remocao de componente.
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~192).
Status V04: acredito que seja impossivel sem quebrar.
Pode tentar: POC de delete com mesma chave RESB em trilha V04.1.

4. Trocar FM interno `CO_ZV_ORDER_POST` por post/commit via API released.
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~207).
Status V04: acredito que seja impossivel sem quebrar.
Motivo: mexe no fechamento transacional da remarcacao.

5. Trocar `A_ProcessOrder` por entidade released equivalente.
Objeto: `ZR_S2M_PO_COMP_MONITOR` (linha ~9, associacao `A_ProcessOrder`) e `ZC_S2M_PO_COMP_MONITOR` (linhas ~31/32, campos `MaterialOrdem*`).
Status V04: acredito que seja impossivel com seguranca agora.
Motivo: pode mudar os campos exibidos no monitor.

6. Trocar `I_MaterialText` por CDS released de texto de produto/material.
Objeto: `ZR_S2M_PO_COMP_MONITOR` (linha ~10) e `ZC_S2M_PO_COMP_MONITOR` (linha ~23).
Status V04: acredito que seja impossivel com seguranca agora.
Pode tentar: validar objeto released equivalente no seu release e manter filtro por idioma.

7. Trocar `I_MasterRecipeMaterialAssgmt` por fonte released equivalente.
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~6).
Status V04: acredito que seja impossivel sem quebrar.
Motivo: altera regra base de compatibilidade de materiais.

8. Trocar `R_BatchCharacteristicValueTP` por API released de caracteristica de lote.
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~10).
Status V04: acredito que seja impossivel sem quebrar.
Motivo: risco de mudar filtro de caracteristicas 1031/991/998.

9. Trocar `NSDM_E_MCHB` por CDS released de estoque por lote.
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~11).
Status V04: acredito que seja impossivel sem quebrar.
Motivo: risco direto no saldo/lote/deposito retornado.

10. Trocar `I_MfgOrderStatus` por status released equivalente.
Objeto: `ZR_S2M_ORDEM` (linha ~7, filtro `OrderIsCreated = 'X'`).
Status V04: acredito que seja impossivel com seguranca agora.
Motivo: sem validar semantica equivalente de status no release atual.

11. Trocar `SELECT ... FROM MCHB` por CDS/API released de estoque por lote.
Objeto: `ZBP_R_S2M_PO_COMP_MONITOR` (V03, linha ~148).
Status V04: acredito que seja impossivel sem quebrar.
Motivo: essa leitura define lote/deposito usados na remarcacao.

## Fechamento V04
1. Para esta versao: sem mudanca de fonte (somente justificativa ATC), para nao gerar regressao funcional.
2. Para proxima versao (V04.1): fazer tentativa controlada item a item, via POC e teste regressivo.

