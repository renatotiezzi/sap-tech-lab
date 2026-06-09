# GAP316 - Double Check V04 (Wrappers de Tabela)

Objetivo:
Garantir que os pontos de leitura direta de tabela no escopo V04 estao cobertos por estrategia de evolucao com wrapper Z e justificativa ATC coerente.

## 1) Evidencia de leituras de tabela encontradas

1. `ZI_S2M_DEPOSITO_TANQUE`
- Fonte atual encontrada: `as select from t001l`
- Risco ATC: DDIC direto + campo IS-OIL `oib_tnkassign`
- Acao V04: criado wrapper `ZI_S2M_WRP_T001L_TANQUE` e ajustado o consumidor `ZI_S2M_DEPOSITO_TANQUE`

2. `ZBP_R_S2M_PO_COMP_MONITOR` (historico V03)
- Fonte historica encontrada: `SELECT SINGLE werks, lgort, charg FROM mchb`
- Estado atual: no fonte real, o acesso direto ainda existia e foi substituido no V04
- Acao V04: criado wrapper `ZI_S2M_WRP_MCHB_LOTE` com os mesmos campos efetivamente usados pelo fluxo e ajustado o handler consumidor

## 2) Wrappers criados no V04

1. `ZI_S2M_WRP_T001L_TANQUE.ddls.asddls`
- Le da `T001L`
- Expoe `Werks`, `Lgort`, `Tanque`
- Uso esperado: ser consumida por `ZI_S2M_DEPOSITO_TANQUE` no lugar do `select from t001l`

2. `ZI_S2M_WRP_MCHB_LOTE.ddls.asddls`
- Le da `MCHB`
- Expoe `Material`, `Plant`, `StorageLocation`, `Batch`
- Uso esperado: consumo controlado em eventual necessidade futura do mesmo lookup tecnico do handler historico, sem `SELECT` direto no handler

## 3) Criterios de aderencia (checklist)

- [x] Todo `SELECT` direto em tabela DDIC mapeado no escopo foi tratado com wrapper Z no V04.
- [x] Todo consumidor real dos wrappers foi ajustado no fonte principal do GAP316.
- [x] Triagem ATC V04 atualizada com orientacao explicita de wrapper para tabela.
- [x] Justificativa de excecao mantida como temporaria e condicionada a alternativa released.
- [x] Wrapper `MCHB` reduzido ao contrato minimo do uso real para evitar erro de compilacao por campos nao necessarios.
- [x] Sem mudanca de logica funcional no ciclo (somente mitigacao estrutural e documentacao).

## 4) Proximo passo tecnico recomendado

Proximo passo de validacao funcional: ativar wrappers e consumidores no ADT e reprocessar o ATC para confirmar que os achados migraram dos consumidores para os wrappers, onde cabera a justificativa por inexistencia de alternativa standard/released.
