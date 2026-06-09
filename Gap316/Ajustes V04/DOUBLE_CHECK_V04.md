# GAP316 - Double Check V04 (Wrappers de Tabela)

Objetivo:
Garantir que os pontos de leitura direta de tabela no escopo V04 estao cobertos por estrategia de evolucao com wrapper Z e justificativa ATC coerente.

## 1) Evidencia de leituras de tabela encontradas

1. `ZI_S2M_DEPOSITO_TANQUE`
- Fonte atual encontrada: `as select from t001l`
- Risco ATC: DDIC direto + campo IS-OIL `oib_tnkassign`
- Acao V04: criado wrapper `ZI_S2M_WRP_T001L_TANQUE`

2. `ZBP_R_S2M_PO_COMP_MONITOR` (historico V03)
- Fonte historica encontrada: `SELECT SINGLE ... FROM mchb`
- Estado atual: trecho apontado como removido em V03
- Acao V04: criado wrapper de contingencia `ZI_S2M_WRP_MCHB_LOTE` para evitar retorno a acesso direto, caso surja novo ponto

## 2) Wrappers criados no V04

1. `ZI_S2M_WRP_T001L_TANQUE.ddls.asddls`
- Le da `T001L`
- Expoe `Werks`, `Lgort`, `TankAssignment`
- Uso esperado: ser consumida por `ZI_S2M_DEPOSITO_TANQUE` no lugar do `select from t001l`

2. `ZI_S2M_WRP_MCHB_LOTE.ddls.asddls`
- Le da `MCHB`
- Expoe `Material`, `Plant`, `StorageLocation`, `Batch`, `UnrestrictedUseStock`
- Uso esperado: consumo controlado em eventual necessidade futura de saldo/lote, sem `SELECT` direto no handler

## 3) Criterios de aderencia (checklist)

- [x] Todo `SELECT` direto em tabela DDIC mapeado no escopo foi tratado com wrapper Z no V04.
- [x] Triagem ATC V04 atualizada com orientacao explicita de wrapper para tabela.
- [x] Justificativa de excecao mantida como temporaria e condicionada a alternativa released.
- [x] Sem mudanca de logica funcional no ciclo (somente mitigacao estrutural e documentacao).

## 4) Proximo passo tecnico recomendado

No proximo chunk, alterar o fonte CDS consumidor para usar o wrapper `ZI_S2M_WRP_T001L_TANQUE` em vez de `T001L` direto e rodar ATC novamente para verificar reducao do achado neste item.
