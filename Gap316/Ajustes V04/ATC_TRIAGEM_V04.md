# GAP316 - Ajustes V04 (ATC)

## Objetivo
Fechar a demanda ATC sem quebrar o processo de remarcacao.

## Resultado da triagem
Pela lista enviada, os achados sao majoritariamente de categoria "Usage of internal API" e "Usage of DDIC tables in CDS".

Decisao tecnica para V04:
- Nao fazer substituicoes arriscadas de API neste ciclo, porque pode quebrar comportamento funcional ja estabilizado no V03.
- Tratar por justificativa tecnica formal onde nao ha alternativa publica viavel no escopo curto.
- Registrar backlog de refatoracao clean-core para ciclo dedicado.

---

## Matriz ATC (corrigir vs justificar)

| Item ATC | Objeto | Acao V04 | Motivo |
|---|---|---|---|
| DDIC table OILT001L em CDS | ZI_S2M_DEPOSITO_TANQUE | JUSTIFICAR | Dependencia IS-OIL especifica; sem substituto publico direto no escopo atual |
| DDIC table T001L em CDS | ZI_S2M_DEPOSITO_TANQUE | JUSTIFICAR | Troca para API released exigiria redesenho de join e reteste funcional |
| Internal API CO_XT_COMPONENT_ADD | ZCLS2M_REMARCACAO_PARALLEL | JUSTIFICAR | API de processo de ordem usada no core da remarcacao; troca exige redesenho completo |
| Internal API CO_XT_COMPONENTS_DELETE | ZCLS2M_REMARCACAO_PARALLEL | JUSTIFICAR | Mesmo motivo acima |
| Internal API CO_ZV_ORDER_POST | ZCLS2M_REMARCACAO_PARALLEL | JUSTIFICAR | Mesmo motivo acima |
| Internal API A_PROCESSORDER | ZC_S2M_PO_COMP_MONITOR / ZR_S2M_PO_COMP_MONITOR | JUSTIFICAR | Substituicao demanda revisao de campos Material/MaterialName e comportamento da OP |
| Internal API I_MATERIALTEXT | ZC/ZR/ZI *_PO_COMP_MONITOR / *_MATERIAIS_COMPATIVEIS | JUSTIFICAR | Campo de descricao ja estabilizado; troca para outra VDM exige reteste amplo |
| Internal API NSDM_DDL_MCHB | ZI_S2M_MATERIAIS_COMPAT | JUSTIFICAR | Fonte de estoque por lote com filtros especificos do processo |
| Internal API R_BATCHCHARACTERISTICVALUETP | ZI_S2M_MATERIAIS_COMPAT | JUSTIFICAR | Dependencia de caracteristicas de lote para regra de compatibilidade |
| Internal API I_MASTERRECIPEMATERIALASSGMT | ZI_S2M_MATERIAIS_COMPAT | JUSTIFICAR | Parte do criterio de compatibilidade no desenho atual |
| Internal API I_MFGORDERSTATUS | ZR_S2M_ORDEM | JUSTIFICAR | Filtro de ordem criada no monitor atual |
| DDIC table MCHB em classe | ZBP_R_S2M_PO_COMP_MONITOR | JUSTIFICAR | Mudanca para API released precisa garantia de mesmos campos lote/deposito para BAPI |

---

## O que foi efetivamente corrigido no fluxo (fora ATC clean-core)
- V03 corrigiu o bug de quantidade/material na acao Remarcar.
- V03 adicionou validacoes de quantidade e selecao unica para a acao.

Esses pontos reduzem risco funcional imediato, mas nao removem os alertas de API interna no ATC.

---

## Recomendacao para gate
- Aprovar V04 com justificativas ATC registradas (waiver/exemption por objeto).
- Abrir iniciativa separada "Clean Core Refactor" para migrar APIs internas com teste regressivo completo.

