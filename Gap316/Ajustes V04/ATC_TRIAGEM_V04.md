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

## Justificativas para Excecao ATC (copiar/colar)

1. T001L/OILT001L em `ZI_S2M_DEPOSITO_TANQUE`
Justificativa: o objeto utiliza o campo `oib_tnkassign`, de natureza especifica IS-OIL, sem equivalencia released comprovada no release atual com a mesma semantica funcional. A substituicao neste momento pode alterar a identificacao de depositos tanque e gerar regressao no processo. Solicitada excecao ATC temporaria ate validacao de alternativa released em trilha dedicada.

2. `CO_XT_COMPONENT_ADD` em `ZCLS2M_REMARCACAO_PARALLEL`
Justificativa: a chamada e parte do nucleo transacional da remarcacao de componentes em ordem de processo. A troca imediata por API alternativa sem POC homologada pode alterar inclusao de componente, quantidade e lote, com risco de impacto produtivo. Solicitada excecao temporaria com plano de migracao controlada.

3. `CO_XT_COMPONENTS_DELETE` em `ZCLS2M_REMARCACAO_PARALLEL`
Justificativa: a rotina de exclusao esta acoplada ao mesmo fluxo transacional da adicao/remarcacao. Substituicao sem desenho de equivalencia de chaves RESB e testes de regressao pode causar inconsistencias de componentes na ordem. Solicitada excecao ATC temporaria.

4. `CO_ZV_ORDER_POST` em `ZCLS2M_REMARCACAO_PARALLEL`
Justificativa: o post e commit da ordem dependem desse ponto tecnico para consolidacao das alteracoes. A troca imediata pode comprometer fechamento transacional e consistencia dos dados. Solicitada excecao temporaria, com acao futura em iniciativa clean-core.

5. `A_ProcessOrder` em `ZR_S2M_PO_COMP_MONITOR`/`ZC_S2M_PO_COMP_MONITOR`
Justificativa: o consumo atual abastece campos exibidos no monitor (`MaterialOrdem`, `MaterialOrdemName`) e suporta o comportamento funcional validado. Alteracao sem mapeamento release-equivalente confirmado pode quebrar exibicao e filtros de tela. Solicitada excecao ATC temporaria.

6. `I_MaterialText` em `ZR_S2M_PO_COMP_MONITOR`/`ZC_S2M_PO_COMP_MONITOR`
Justificativa: o texto de material esta estabilizado com filtro por idioma da sessao e usado na experiencia do usuario. Sem validacao de substituto released com mesma cobertura de dados no release atual, a troca pode gerar perda de descricao ou inconsistencias de idioma. Solicitada excecao temporaria.

7. `I_MasterRecipeMaterialAssgmt` em `ZI_S2M_MATERIAIS_COMPAT`
Justificativa: a fonte participa da regra central de compatibilidade material x receita. Substituicao sem reconfirmacao funcional completa pode alterar o conjunto de materiais candidatos e impactar a remarcacao. Solicitada excecao ATC temporaria com refatoracao planejada.

8. `R_BatchCharacteristicValueTP` em `ZI_S2M_MATERIAIS_COMPAT`
Justificativa: a regra atual depende de caracteristicas de lote (classe 023 e IDs especificos) para elegibilidade. Mudanca de fonte sem equivalencia tecnica comprovada pode alterar criterios de compatibilidade em producao. Solicitada excecao temporaria.

9. `NSDM_E_MCHB` em `ZI_S2M_MATERIAIS_COMPAT`
Justificativa: a leitura de estoque por lote/deposito e parte do filtro principal do monitor de materiais compativeis. Troca sem validacao de paridade de campos e semantica pode alterar saldo elegivel e resultado funcional. Solicitada excecao ATC temporaria.

10. `I_MfgOrderStatus` em `ZR_S2M_ORDEM`
Justificativa: o filtro `OrderIsCreated = 'X'` e requisito funcional do monitor atual. Sem comprovacao de entidade released com semantica identica no release em uso, a substituicao pode incluir/excluir ordens indevidamente. Solicitada excecao temporaria.

11. `MCHB` em `ZBP_R_S2M_PO_COMP_MONITOR` (V03)
Justificativa: a busca em `MCHB` define lote/deposito consumidos na execucao da remarcacao. Mudanca imediata de fonte de dados sem paridade funcional validada pode impactar diretamente a operacao de remarcacao ja estabilizada. Solicitada excecao ATC temporaria.

