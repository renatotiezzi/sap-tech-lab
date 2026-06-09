# GAP316 - Ajustes V04 (ATC)

Formato unico por tema:
1. Motivo de estar no ATC.
2. Ajuste proposto (preferencialmente released).
3. Justificativa formal para excecao, quando a troca nao for segura no ciclo atual.

## Diretriz V04 - Wrappers para SELECT em tabela

Regra aplicada neste ciclo:
- Sempre que houver leitura direta de tabela DDIC no escopo V04, criar wrapper CDS Z no proprio pacote de ajuste.
- O wrapper reduz acoplamento do consumidor final com tabela fisica e centraliza o ponto tecnico para futura troca por objeto released.
- Se nao existir alternativa released com semantica equivalente no release alvo, manter wrapper + justificativa de excecao ATC temporaria.

Objetos wrapper criados no V04:
- `ZI_S2M_WRP_T001L_TANQUE` -> [Ajustes V04] leitura de `T001L` para atributo funcional de tanque.
- `ZI_S2M_WRP_MCHB_LOTE` -> [Ajustes V04] fallback tecnico para leitura de `MCHB` por material/centro/deposito/lote.

## 1. DDIC `T001L` / campo `oib_tnkassign`
Objeto: `ZI_S2M_DEPOSITO_TANQUE` (linha ~6, `as select from t001l`).

Motivo de estar no ATC:
Leitura direta de tabela DDIC em CDS, com dependencia de campo IS-OIL (`oib_tnkassign`) sem equivalente released confirmado no ambiente.

Ajuste / se possivel:
Aplicar wrapper local no V04: substituir consumo direto de `T001L` por `ZI_S2M_WRP_T001L_TANQUE`, mantendo mesma semantica funcional. Em trilha futura, tentar trocar o wrapper por fonte released equivalente.

Justificativa para excecao ATC:
A regra funcional de identificacao de deposito tanque depende de `oib_tnkassign`. Sem evidencia de objeto released com semantica equivalente no release atual, a troca direta para outra fonte pode alterar elegibilidade de depositos. Excecao ATC temporaria mantida, com mitigacao tecnica por wrapper Z local no V04.

## 2. FM interno `CO_XT_COMPONENT_ADD`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~139).

Motivo de estar no ATC:
Uso de API interna nao released para inclusao de componente na ordem.

Ajuste / se possivel:
Substituir por API released somente se cobrir material, quantidade, operacao, sequencia, deposito e lote no mesmo fluxo transacional.

Justificativa para excecao ATC:
Ponto transacional critico. Troca sem equivalencia comprovada + regressao ponta a ponta pode quebrar a remarcacao.

## 3. FM interno `CO_XT_COMPONENTS_DELETE`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~192).

Motivo de estar no ATC:
Uso de API interna nao released para exclusao de componentes.

Ajuste / se possivel:
Substituir por API released apenas com equivalencia funcional da chave tecnica e comportamento transacional.

Justificativa para excecao ATC:
Integrado ao mesmo bloco da inclusao de componente. Troca sem paridade pode gerar inconsistencias na estrutura da ordem.

## 4. FM interno `CO_ZV_ORDER_POST`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~207).

Motivo de estar no ATC:
Uso de API interna nao released para consolidacao transacional.

Ajuste / se possivel:
Substituir por mecanismo released de post/commit apenas com prova de equivalencia transacional.

Justificativa para excecao ATC:
Risco direto de comprometer gravacao, consistencia e tratamento de erro do fluxo completo.

## 5. API `A_ProcessOrder`
Objeto: `ZR_S2M_PO_COMP_MONITOR` (linha ~9) e `ZC_S2M_PO_COMP_MONITOR` (linhas ~31/32).

Motivo de estar no ATC:
Consumo de API nao released para dados de cabecalho da ordem.

Ajuste / se possivel:
Testar substituicao por `I_ManufacturingOrder` e remapear `MaterialOrdem`/`MaterialOrdemName` com validacao funcional completa.

Justificativa para excecao ATC:
Sem prova de paridade de campos/semantica no release atual, a troca pode degradar exibicao e filtros do monitor.

## 6. API `I_MaterialText`
Objeto: `ZR_S2M_PO_COMP_MONITOR` (linha ~10) e `ZC_S2M_PO_COMP_MONITOR` (linha ~23).

Motivo de estar no ATC:
Consumo de view nao released para descricao de material.

Ajuste / se possivel:
Substituir por view released de texto de material/produto com filtro por idioma da sessao.

Justificativa para excecao ATC:
Sem candidato local confirmado, a troca pode causar perda de descricao ou idioma incorreto.

## 7. API `I_MasterRecipeMaterialAssgmt`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~6).

Motivo de estar no ATC:
Uso de view nao released na regra de compatibilidade material-receita.

Ajuste / se possivel:
Substituir por fonte released equivalente, preservando semantica da regra de elegibilidade.

Justificativa para excecao ATC:
Mudanca pode alterar universo de materiais compativeis sem controle funcional.

## 8. API `R_BatchCharacteristicValueTP`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~10).

Motivo de estar no ATC:
Consumo de objeto nao released para caracteristicas de lote.

Ajuste / se possivel:
Substituir por API/view released de classificacao que preserve filtro de classe `023` e caracteristicas usadas no processo.

Justificativa para excecao ATC:
Sem equivalencia comprovada, pode alterar criterio de elegibilidade dos materiais.

## 9. API `NSDM_E_MCHB`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~11).

Motivo de estar no ATC:
Consumo de fonte nao released para saldo por lote/deposito.

Ajuste / se possivel:
Substituir por CDS released de estoque por lote com `Material`, `Plant`, `StorageLocation`, `Batch` e saldo.

Justificativa para excecao ATC:
Sem equivalencia semantica de saldo/campos, o monitor pode retornar materiais indevidos.

## 10. API `I_MfgOrderStatus`
Objeto: `ZR_S2M_ORDEM` (linha ~7, filtro `OrderIsCreated = 'X'`).

Motivo de estar no ATC:
Uso de view nao released para filtro de status da ordem.

Ajuste / se possivel:
Verificar simplificacao para `I_MfgOrderComponentWithStatus` (ja usada localmente), removendo join extra se a semantica for equivalente.

Justificativa para excecao ATC:
Sem validacao de paridade do status no release alvo, troca pode incluir/excluir ordens incorretamente.

## 11. DDIC `MCHB` em classe ABAP
Objeto: `ZBP_R_S2M_PO_COMP_MONITOR` (V03, linha ~148).

Motivo de estar no ATC:
Historico de leitura direta DDIC em ABAP (`SELECT ... FROM MCHB`).

Ajuste / se possivel:
No V03, o `SELECT` direto foi removido e substituido por dados RAP da propria linha. Para eventual reintroducao controlada em outro ponto, usar wrapper V04 `ZI_S2M_WRP_MCHB_LOTE` em vez de acesso direto.

Justificativa para excecao ATC:
Nao aplicavel ao trecho ja corrigido em V03. Se houver novo apontamento em ponto distinto, aplicar wrapper Z e justificar transitoriamente ate migracao para fonte released equivalente.
