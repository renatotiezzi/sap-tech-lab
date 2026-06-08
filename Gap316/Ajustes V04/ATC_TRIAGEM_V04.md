# GAP316 - Ajustes V04 (ATC)

Estrutura unica por tema:
1. Motivo de estar no ATC.
2. Ajuste proposto, se houver alternativa minimamente plausivel.
3. Justificativa formal para excecao, caso o ajuste nao seja seguro no ciclo atual.

# GAP316 - Ajustes V04 (ATC)

Cada tema aparece uma unica vez, no formato pedido:
- Motivo de estar no ATC
- Ajuste / se possivel
- Justificativa / texto para excecao ATC, caso a troca nao seja segura agora

## 1. DDIC `T001L` / campo `oib_tnkassign`
Objeto: `ZI_S2M_DEPOSITO_TANQUE` (linha ~6, `as select from t001l`).

Motivo de estar no ATC:
O objeto consome tabela DDIC diretamente em CDS. O ponto sensivel nao e apenas `T001L`, mas o uso do campo `oib_tnkassign`, que leva o ATC a classificar o acesso como nao aderente ao padrao released/clean-core.

Ajuste / se possivel:
Tentar substituir a leitura direta por uma CDS released de deposito/localizacao que exponha atributo funcional equivalente ao conceito de tanque. Se nao existir view released com esse atributo, manter a implementacao atual. Neste momento, nao foi encontrado equivalente local confirmado.

Justificativa para excecao ATC:
O objeto `ZI_S2M_DEPOSITO_TANQUE` utiliza o campo `oib_tnkassign` para identificar depositos com comportamento especifico de tanque no contexto IS-OIL. Ate o momento, nao foi identificada no ambiente atual uma view released que exponha a mesma semantica de negocio com equivalencia funcional comprovada. A substituicao imediata da fonte de dados, sem garantia dessa equivalencia, pode alterar o conjunto de depositos elegiveis e comprometer o comportamento esperado do processo. Por essa razao, solicita-se excecao temporaria de ATC, condicionada a futura validacao de alternativa released em trilha dedicada de refatoracao.

## 2. FM interno `CO_XT_COMPONENT_ADD`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~139).

Motivo de estar no ATC:
O ATC identifica chamada a API interna nao released para manutencao de componente de ordem de processo.

Ajuste / se possivel:
Substituir por API released de alteracao de componente de ordem, caso exista no release alvo e cubra material, quantidade, operacao, sequencia, deposito e lote. Sem essa cobertura, a troca nao deve ser feita no ciclo atual.

Justificativa para excecao ATC:
A chamada ao modulo `CO_XT_COMPONENT_ADD` integra o nucleo transacional do processo de remarcacao e e responsavel pela inclusao tecnica do componente substituto na ordem. A eventual troca por outra API, sem comprovacao de equivalencia funcional e sem testes de regressao ponta a ponta, pode afetar diretamente inclusao de material, quantidade, lote, deposito e consistencia da ordem processada. Considerando que o fluxo funcional foi estabilizado e validado nas correcoes anteriores, solicita-se excecao ATC temporaria ate que seja conduzida uma refatoracao controlada, com prova tecnica de equivalencia e homologacao completa.

## 3. FM interno `CO_XT_COMPONENTS_DELETE`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~192).

Motivo de estar no ATC:
O ATC identifica uso de API interna nao released para exclusao de componentes de ordem.

Ajuste / se possivel:
Substituir por API released de remocao de componente, desde que aceite a mesma chave funcional hoje usada no processo. Sem essa equivalencia, nao aplicar a troca agora.

Justificativa para excecao ATC:
O modulo `CO_XT_COMPONENTS_DELETE` atua no mesmo bloco transacional da remarcacao e responde pela retirada tecnica do componente original da ordem. Sua substituicao sem definicao precisa de equivalencia para chaves de reserva, comportamento transacional e tratamento de mensagens pode gerar inconsistencias entre o componente removido e o componente inserido no mesmo fluxo. Em funcao desse risco de impacto funcional direto em producao, solicita-se excecao ATC temporaria, com a previsao de revisita em iniciativa especifica de clean-core.

## 4. FM interno `CO_ZV_ORDER_POST`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~207).

Motivo de estar no ATC:
O ATC identifica uso de API interna nao released para post/fechamento transacional da ordem.

Ajuste / se possivel:
Substituir por mecanismo released de post/commit de alteracoes da ordem, desde que preserve a mesma consistencia transacional. Nao ha equivalente confirmado localmente.

Justificativa para excecao ATC:
O ponto tecnico tratado por `CO_ZV_ORDER_POST` nao representa apenas uma chamada de persistencia isolada, mas sim a consolidacao transacional das alteracoes realizadas na ordem durante a remarcacao. Qualquer mudanca nessa etapa, sem comprovacao de comportamento equivalente, pode comprometer gravacao, consistencia de dados e tratamento de erro do processo como um todo. Diante da inexistencia de substituto validado no contexto atual, solicita-se excecao temporaria de ATC ate a execucao de estudo tecnico dedicado.

## 5. API `A_ProcessOrder`
Objeto: `ZR_S2M_PO_COMP_MONITOR` (linha ~9) e `ZC_S2M_PO_COMP_MONITOR` (linhas ~31/32).

Motivo de estar no ATC:
O ATC classifica o consumo da entidade como uso de API nao released para leitura de dados da ordem.

Ajuste / se possivel:
Candidato encontrado: `I_ManufacturingOrder`. A tentativa mais objetiva e trocar a associacao em `ZR_S2M_PO_COMP_MONITOR` para `I_ManufacturingOrder` e depois remapear em `ZC_S2M_PO_COMP_MONITOR` os campos `MaterialOrdem` e `MaterialOrdemName`, desde que os campos equivalentes existam no release.

Justificativa para excecao ATC:
O consumo atual de `A_ProcessOrder` alimenta informacoes apresentadas no monitor e ja validadas funcionalmente, em especial os campos derivados de material da ordem. Embora exista indicio local de que `I_ManufacturingOrder` possa ser um candidato tecnico, ainda nao foi comprovado no ambiente que essa substituicao preserve integralmente a mesma disponibilidade de campos e a mesma semantica funcional. Uma troca prematura pode afetar exibicao, filtros e consistencia das informacoes apresentadas ao usuario. Solicita-se, portanto, excecao ATC temporaria ate a validacao controlada da entidade substituta.

## 6. API `I_MaterialText`
Objeto: `ZR_S2M_PO_COMP_MONITOR` (linha ~10) e `ZC_S2M_PO_COMP_MONITOR` (linha ~23).

Motivo de estar no ATC:
O ATC identifica consumo de view nao released para descricao do material.

Ajuste / se possivel:
Pesquisar e substituir por view released de texto de produto/material disponivel no release em uso, mantendo obrigatoriamente o filtro por idioma da sessao. Nao foi encontrado candidato confirmado no repositorio local.

Justificativa para excecao ATC:
O uso de `I_MaterialText` atende hoje a necessidade de descricao legivel dos materiais no idioma da sessao, compondo parte importante da experiencia do usuario no monitor. Como ainda nao foi identificado, no contexto deste ambiente, um substituto released confirmado com a mesma cobertura funcional e de idioma, a troca imediata pode resultar em perda de descricao, divergencia linguistica ou inconsistencias na apresentacao dos dados. Por esse motivo, solicita-se excecao ATC temporaria ate a identificacao e validacao de alternativa released adequada.

## 7. API `I_MasterRecipeMaterialAssgmt`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~6).

Motivo de estar no ATC:
O ATC identifica uso de view nao released na regra de vinculacao entre material e receita.

Ajuste / se possivel:
Substituir por fonte released equivalente para relacao entre material, planta e grupo de receita. Ate o momento, nao ha equivalente confirmado localmente.

Justificativa para excecao ATC:
`I_MasterRecipeMaterialAssgmt` participa diretamente da regra central de compatibilidade utilizada para compor a lista de materiais candidatos no processo de remarcacao. Uma alteracao de fonte nesse ponto nao se limita a ajuste tecnico de nomenclatura, podendo modificar de forma concreta o universo de materiais retornados ao usuario. Na ausencia de alternativa released comprovadamente equivalente, a substituicao imediata representa risco funcional elevado. Solicita-se excecao ATC temporaria, mantendo o comportamento atual ate a execucao de refatoracao especifica e testada.

## 8. API `R_BatchCharacteristicValueTP`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~10).

Motivo de estar no ATC:
O ATC identifica consumo de objeto nao released para leitura de caracteristicas de lote.

Ajuste / se possivel:
Substituir por API/view released de classificacao de lote, desde que ela permita preservar a filtragem atualmente usada para classe `023` e caracteristicas `1031`, `991` e `998`. Nao ha candidato confirmado localmente.

Justificativa para excecao ATC:
O objeto `R_BatchCharacteristicValueTP` nao e utilizado de forma acessoria, mas sim como parte do criterio de elegibilidade dos materiais compativeis apresentados pelo monitor. A semantica atual depende de uma combinacao especifica de classe e identificadores de caracteristica. Qualquer substituicao sem prova de equivalencia pode alterar o criterio funcional de selecao, impactando diretamente os materiais disponibilizados para remarcacao. Diante desse risco, solicita-se excecao ATC temporaria ate que haja alternativa released validada tecnicamente e funcionalmente.

## 9. API `NSDM_E_MCHB`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~11).

Motivo de estar no ATC:
O ATC identifica consumo de fonte nao released para estoque por lote/deposito.

Ajuste / se possivel:
Substituir por CDS released de estoque por lote que entregue, no minimo, `Material`, `Plant`, `StorageLocation`, `Batch` e saldo disponivel. Ainda nao ha candidato confirmado localmente.

Justificativa para excecao ATC:
O uso de `NSDM_E_MCHB` e parte essencial do filtro que garante disponibilidade de saldo por lote e deposito para os materiais compativeis. A remocao ou troca dessa fonte, sem garantia de equivalencia semantica dos campos e dos saldos retornados, pode alterar de forma indevida o resultado do monitor e induzir selecao de materiais sem disponibilidade real. Em funcao desse risco funcional, solicita-se excecao ATC temporaria ate a identificacao de fonte released equivalente e validada.

## 10. API `I_MfgOrderStatus`
Objeto: `ZR_S2M_ORDEM` (linha ~7, filtro `OrderIsCreated = 'X'`).

Motivo de estar no ATC:
O ATC identifica uso de view nao released para filtragem de status da ordem.

Ajuste / se possivel:
Candidato encontrado: `I_MfgOrderComponentWithStatus`, ja usada em `ZI_S2M_ORDEM`. A tentativa sugerida e eliminar o join adicional com `I_MfgOrderStatus` e verificar se o filtro equivalente de status pode ser obtido diretamente da view base, reduzindo dependencias.

Justificativa para excecao ATC:
O filtro por status de ordem criada e requisito funcional do monitor atual e interfere diretamente no conjunto de ordens elegiveis para processamento. Embora exista indicao de que a view base `I_MfgOrderComponentWithStatus` possa absorver essa necessidade, essa equivalencia ainda nao foi comprovada no objeto final de consumo. A troca sem validacao pode incluir ou excluir ordens incorretamente, afetando o comportamento funcional da aplicacao. Solicita-se excecao ATC temporaria ate a validacao segura dessa simplificacao.

## 11. DDIC `MCHB` em classe ABAP
Objeto: `ZBP_R_S2M_PO_COMP_MONITOR` (V03, linha ~148).

Motivo de estar no ATC:
O ATC identifica acesso direto a tabela DDIC em logica ABAP.

Ajuste / se possivel:
Aplicado. O `SELECT ... FROM MCHB` foi removido e substituido pelo uso direto dos dados ja disponiveis na linha RAP (`centro`, `deposito`, `charg`) para montagem de `is_storage_location` e `iv_batch`.

Justificativa para excecao ATC:
Nao aplicavel para a versao ajustada, pois o acesso direto a `MCHB` foi removido do ponto tratado. Caso o ATC continue apontando o achado, recomenda-se reprocessar a verificacao sobre a ultima versao do fonte transportado.
## 1. DDIC `T001L` / campo `oib_tnkassign`
Objeto: `ZI_S2M_DEPOSITO_TANQUE` (linha ~6, `as select from t001l`).

Motivo de estar no ATC:
o objeto consome tabela DDIC diretamente em CDS e ainda depende do campo `oib_tnkassign`, que e especifico de IS-OIL. O ATC sinaliza esse desenho por nao utilizar uma view released e estavel de consumo.

Ajuste / se possivel:
trocar a origem `T001L` por uma CDS released de deposito, somente se essa CDS tambem expuser um atributo funcionalmente equivalente ao conceito de tanque hoje representado por `oib_tnkassign`. Sem esse atributo, a troca nao preserva a regra atual.

Justificativa / como justificar se nao funcionar:
o objeto nao utiliza `T001L` apenas como cadastro tecnico de deposito; ele utiliza um atributo de negocio especifico de IS-OIL para identificar depositos tanque elegiveis no processo. Ate o momento, nao ha evidencia local de uma CDS released que preserve essa mesma semantica funcional. Uma substituicao apenas para eliminar o achado ATC, sem equivalencia comprovada do atributo de tanque, introduziria risco de classificacao incorreta de depositos e alteracao do comportamento funcional ja validado. Por esse motivo, a recomendacao e manter temporariamente a fonte atual e tratar o achado por excecao ATC, ate que seja validada uma alternativa released com cobertura funcional equivalente.

## 2. FM `CO_XT_COMPONENT_ADD`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~139).

Motivo de estar no ATC:
o objeto chama uma API interna de alteracao de componentes de ordem de processo. O ATC classifica esse uso como dependencia de interface nao released.

Ajuste / se possivel:
pesquisar e testar uma API released de manutencao de componentes de ordem de processo que aceite, no minimo, material, quantidade, operacao, sequencia, deposito e lote. A substituicao so deve ser feita se a API alternativa suportar o mesmo fluxo transacional ponta a ponta.

Justificativa / como justificar se nao funcionar:
essa chamada faz parte do nucleo da remarcacao e nao representa uma leitura auxiliar ou decorativa; ela efetivamente cria o componente substituto dentro da ordem. Qualquer troca sem equivalencia funcional comprovada pode alterar inclusao de material, amarracao por operacao, atribuicao de lote e consistencia do processo produtivo. Como nao ha ainda uma API released homologada no contexto deste sistema e deste fluxo especifico, a substituicao imediata seria tecnicamente arriscada. A excecao ATC e justificavel porque a manutencao da estabilidade operacional e mais critica neste momento do que uma troca estrutural sem reteste regressivo completo.

## 3. FM `CO_XT_COMPONENTS_DELETE`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~192).

Motivo de estar no ATC:
uso de API interna para exclusao de componentes na ordem.

Ajuste / se possivel:
procurar API released de remocao de componente que aceite a mesma chave funcional hoje baseada em `RESB`, mantendo consistencia com a etapa de inclusao do componente substituto.

Justificativa / como justificar se nao funcionar:
essa rotina nao atua isoladamente; ela compoe o mesmo fluxo transacional da remarcacao. A remocao do componente original precisa continuar coerente com a inclusao do substituto e com o post final da ordem. Substituir esse ponto sem garantia de equivalencia das chaves tecnicas e da sequencia transacional pode gerar componentes duplicados, remocao indevida ou divergencia de estrutura na ordem. Nessa situacao, a excecao ATC e tecnicamente defensavel ate que exista prova de equivalencia funcional em ambiente de teste controlado.

## 4. FM `CO_ZV_ORDER_POST`
Objeto: `ZCLS2M_REMARCACAO_PARALLEL` (linha ~207).

Motivo de estar no ATC:
uso de API interna para consolidacao e post das alteracoes na ordem.

Ajuste / se possivel:
identificar API released de post/commit de alteracoes em ordem de processo, desde que preserve o mesmo comportamento transacional apos adicao e exclusao de componentes.

Justificativa / como justificar se nao funcionar:
esse ponto controla a consolidacao final das mudancas na ordem. Mesmo que as etapas anteriores fossem preservadas, uma troca inadequada aqui pode comprometer commit, integridade transacional e persistencia das alteracoes efetuadas. Como o impacto potencial e transversal ao processo inteiro, a substituicao nao deve ser feita apenas para satisfazer o ATC sem validacao completa do comportamento transacional. A excecao ATC se sustenta pelo risco concreto de comprometer a consistencia final da ordem de processo.

## 5. `A_ProcessOrder`
Objeto: `ZR_S2M_PO_COMP_MONITOR` (linha ~9) e `ZC_S2M_PO_COMP_MONITOR` (linhas ~31/32).

Motivo de estar no ATC:
consumo de entidade nao released para derivar dados de cabecalho da ordem, especialmente `MaterialOrdem` e `MaterialOrdemName`.

Ajuste / se possivel:
candidato local encontrado: `I_ManufacturingOrder`. A tentativa recomendada e trocar a associacao em `ZR_S2M_PO_COMP_MONITOR` para `I_ManufacturingOrder` e remapear no `ZC_S2M_PO_COMP_MONITOR` os campos expostos do cabecalho da ordem, validando se os nomes e a semantica permanecem equivalentes.

Justificativa / como justificar se nao funcionar:
embora exista um candidato local plausivel, a troca ainda nao foi comprovada no codigo produtivo nem validada no release alvo quanto a cobertura exata dos campos usados no monitor. Como esses campos sao exibidos para o usuario e participam da leitura funcional da ordem, uma migracao incompleta pode degradar a tela, suprimir informacoes ou alterar interpretacao do processo. Assim, se a tentativa com `I_ManufacturingOrder` nao reproduzir integralmente os dados atuais, a excecao ATC deve ser mantida ate conclusao de uma substituicao funcionalmente equivalente.

## 6. `I_MaterialText`
Objeto: `ZR_S2M_PO_COMP_MONITOR` (linha ~10) e `ZC_S2M_PO_COMP_MONITOR` (linha ~23).

Motivo de estar no ATC:
consumo de entidade nao released para obtencao da descricao do material no idioma da sessao.

Ajuste / se possivel:
trocar por CDS released de texto de produto/material disponivel no release, preservando o filtro por idioma da sessao. Ate o momento, nenhum equivalente local foi confirmado no repositorio.

Justificativa / como justificar se nao funcionar:
esse ponto parece simples por tratar apenas de texto, mas ele influencia diretamente a experiencia do usuario e a identificacao correta do material no monitor. Uma troca sem equivalencia garantida pode resultar em descricoes ausentes, idioma incorreto ou divergencia entre o material tecnico e o texto exibido. Como ainda nao ha substituto released confirmado no contexto atual, a excecao ATC e adequada ate que seja identificado e validado um objeto que entregue a mesma cobertura funcional.

## 7. `I_MasterRecipeMaterialAssgmt`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~6).

Motivo de estar no ATC:
consumo de entidade nao released para relacionar material, planta e grupo de receita no calculo de materiais compativeis.

Ajuste / se possivel:
pesquisar uma fonte released equivalente para o vinculo entre material e receita. A troca so faz sentido se preservar o criterio funcional atualmente utilizado para montar a base de compatibilidade.

Justificativa / como justificar se nao funcionar:
essa entidade participa do criterio central de elegibilidade de materiais substitutos. Nao se trata de um enriquecimento visual; ela define a base sobre a qual a compatibilidade e calculada. Alterar essa origem sem reconfirmar o mesmo conjunto de materiais candidatos pode mudar o resultado final da remarcacao. A excecao ATC, nesse caso, se justifica porque a estabilidade da regra de negocio prevalece sobre a remocao imediata de um consumo nao released sem equivalencia demonstrada.

## 8. `R_BatchCharacteristicValueTP`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~10).

Motivo de estar no ATC:
consumo de entidade nao released para leitura de caracteristicas de lote usadas na elegibilidade dos materiais.

Ajuste / se possivel:
buscar API ou CDS released de classificacao/lote que permita reproduzir o filtro atual de classe `023` e das caracteristicas especificas utilizadas no processo.

Justificativa / como justificar se nao funcionar:
as caracteristicas de lote sao parte integrante da regra de compatibilidade. Uma mudanca de fonte que altere a interpretacao dessas caracteristicas pode permitir materiais indevidos ou bloquear materiais validos. Como ainda nao existe substituicao comprovada que reproduza exatamente a mesma leitura de classificacao no release atual, a excecao ATC e tecnicamente consistente e evita alterar um ponto sensivel da logica de selecao.

## 9. `NSDM_E_MCHB`
Objeto: `ZI_S2M_MATERIAIS_COMPAT` (linha ~11).

Motivo de estar no ATC:
uso de fonte nao released para estoque por lote e deposito dentro da CDS de materiais compativeis.

Ajuste / se possivel:
trocar por CDS released de estoque por lote que exponha, no minimo, `Material`, `Plant`, `StorageLocation`, `Batch` e saldo disponivel. No codigo local, ainda nao foi encontrado equivalente confirmado.

Justificativa / como justificar se nao funcionar:
esse ponto define a disponibilidade fisica do material candidato por lote e deposito. Uma troca feita sem paridade de campos e semantica pode alterar saldo elegivel, devolver lote errado ou mudar o deposito retornado ao processo. Dado que isso afeta diretamente o resultado operacional da remarcacao, a substituicao so deve ocorrer com equivalencia comprovada. Ate la, a excecao ATC e a medida mais segura tecnicamente.

## 10. `I_MfgOrderStatus`
Objeto: `ZR_S2M_ORDEM` (linha ~7, filtro `OrderIsCreated = 'X'`).

Motivo de estar no ATC:
consumo de entidade nao released para filtrar ordens por status.

Ajuste / se possivel:
candidato local encontrado: `I_MfgOrderComponentWithStatus`, ja utilizado em `ZI_S2M_ORDEM`. A tentativa recomendada e verificar se o status necessario ja esta presente ou pode ser derivado dessa origem, eliminando o join adicional com `I_MfgOrderStatus`.

Justificativa / como justificar se nao funcionar:
existe uma direcao tecnica promissora, mas ainda nao ha confirmacao de que a view base entregue exatamente a mesma semantica do filtro `OrderIsCreated = 'X'` no release em uso. Uma substituicao precipitada pode incluir ordens fora do status esperado ou excluir ordens validas do monitor. Se a validacao nao comprovar equivalencia integral, a excecao ATC permanece justificada por preservar o comportamento funcional atualmente homologado.

## 11. `MCHB`
Objeto: `ZBP_R_S2M_PO_COMP_MONITOR` (V03, linha ~148).

Motivo de estar no ATC:
leitura direta de tabela DDIC em codigo ABAP para obter centro, deposito e lote do material substituto.

Ajuste / se possivel:
ajuste aplicado em modo seguro. O `SELECT ... FROM MCHB` foi removido e substituido pelo uso direto dos campos ja disponiveis na linha RAP (`centro`, `deposito`, `charg`). Com isso, o fluxo deixa de depender da tabela DDIC nesse ponto especifico.

Justificativa / como justificar se nao funcionar:
neste item a justificativa de excecao deixa de ser necessaria para o handler ajustado, pois a referencia direta a `MCHB` foi retirada. Caso ainda exista apontamento ATC em outro ponto relacionado a estoque por lote, a justificativa deve ser concentrada no objeto CDS que continua responsavel por fornecer esses dados, e nao mais neste trecho do handler.

