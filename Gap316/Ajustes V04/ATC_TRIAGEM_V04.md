# GAP316 - Ajustes V04 (ATC)

## Objetivo
Listar, ponto a ponto, o que mudar em cada objeto ATC e o que nao e seguro mudar agora.

## Regra de decisao usada
- Aplicar somente alteracao de baixo risco e sem impacto funcional no fluxo Remarcar.
- Quando a troca exigir redesenho funcional/tecnico, marcar como "SEM ACAO SEGURA AGORA" e justificar.

---

## Plano por achado ATC (programa por programa)

| Item ATC | Objeto e trecho atual | Mudar de -> para (acao tecnica) | Aplicar em V04? | Decisao |
|---|---|---|---|---|
| Usage of DDIC table T001L/OILT001L in CDS | ZI_S2M_DEPOSITO_TANQUE: `as select from t001l` | De: tabela DDIC `T001L` com campo IS-OIL `oib_tnkassign` -> Para: view released equivalente (se existir no seu release) contendo `Plant/StorageLocation` e flag de tanque; se nao houver view released com esse campo, manter como esta | Nao | SEM ACAO SEGURA AGORA. O campo `oib_tnkassign` e especifico e normalmente nao existe em view released padrao |
| Usage of internal API CO_XT_COMPONENT_ADD | ZCLS2M_REMARCACAO_PARALLEL: `CALL FUNCTION 'CO_XT_COMPONENT_ADD'` | De: FMs CO_XT* -> Para: API released de alteracao de componente de ordem (quando disponivel no release), com mapeamento de `material/quantity/operation/sequence/storage/batch` | Nao | SEM ACAO SEGURA AGORA. Troca exige redesenho completo da remarcacao |
| Usage of internal API CO_XT_COMPONENTS_DELETE | ZCLS2M_REMARCACAO_PARALLEL: `CALL FUNCTION 'CO_XT_COMPONENTS_DELETE'` | De: delete por FM interno -> Para: operacao released de remocao de componente com mesma chave `RESB` | Nao | SEM ACAO SEGURA AGORA. Alto risco de regressao operacional |
| Usage of internal API CO_ZV_ORDER_POST | ZCLS2M_REMARCACAO_PARALLEL: `CALL FUNCTION 'CO_ZV_ORDER_POST'` | De: post interno de ordem -> Para: commit/post via API released de ordem de processo | Nao | SEM ACAO SEGURA AGORA. Mudanca mexe no commit transacional do processo |
| Usage of internal API A_PROCESSORDER | ZR_S2M_PO_COMP_MONITOR e ZC_S2M_PO_COMP_MONITOR: associacao/uso de `A_ProcessOrder` | De: consumo direto de `A_ProcessOrder` para `Material/MaterialName` -> Para: entidade released de Manufacturing Order para leitura (se disponivel no release) + ajuste de aliases `MaterialOrdem/MaterialOrdemName` | Nao | SEM ACAO SEGURA AGORA. Troca exige revisao de campos expostos no monitor |
| Usage of internal API I_MATERIALTEXT | ZR_S2M_PO_COMP_MONITOR e ZC_S2M_PO_COMP_MONITOR: associacao/uso de `I_MaterialText.MaterialName` | De: `I_MaterialText` -> Para: view de texto de produto released no release alvo (ex.: texto de produto) mantendo filtro por idioma da sessao | Nao | SEM ACAO SEGURA AGORA. Sem confirmacao de substituto released identico no release atual |
| Usage of internal API I_MASTERRECIPEMATERIALASSGMT | ZI_S2M_MATERIAIS_COMPAT: `as select from I_MasterRecipeMaterialAssgmt` | De: consumo direto da VDM interna de receita -> Para: fonte released equivalente para vinculo material x grupo de receita | Nao | SEM ACAO SEGURA AGORA. Sem substituto direto confirmado sem alterar regra de compatibilidade |
| Usage of internal API R_BATCHCHARACTERISTICVALUETP | ZI_S2M_MATERIAIS_COMPAT: join com `R_BatchCharacteristicValueTP` | De: leitura direta de caracteristica de lote -> Para: API released para classificacao/lote que preserve `ClassType 023` e caracteristicas 1031/991/998 | Nao | SEM ACAO SEGURA AGORA. Alto risco de mudar resultado de compatibilidade |
| Usage of internal API NSDM_DDL_MCHB | ZI_S2M_MATERIAIS_COMPAT: join com `nsdm_e_mchb` | De: estoque por lote via NSDM -> Para: entidade released de estoque por lote com mesmos campos `matnr/werks/lgort/charg/clabs` | Nao | SEM ACAO SEGURA AGORA. Mudanca afeta saldo e filtro principal do monitor |
| Usage of internal API I_MFGORDERSTATUS | ZR_S2M_ORDEM: join e filtro `OrderIsCreated = 'X'` | De: `I_MfgOrderStatus` -> Para: status released equivalente de ordem de fabricacao com mesmo filtro funcional | Nao | SEM ACAO SEGURA AGORA. Precisa confirmar semantica de status no release |
| Usage of DDIC table MCHB em classe ABAP | ZBP_R_S2M_PO_COMP_MONITOR (V03): `SELECT SINGLE ... FROM mchb` | De: leitura direta MCHB para localizar lote/deposito -> Para: CDS/API released de estoque por lote e ajuste de SELECT para leitura equivalente | Nao | SEM ACAO SEGURA AGORA. Pode alterar selecao de lote usada na remarcacao |

---

## O que da para fazer agora, sem quebrar
- Acao V04 executavel: registrar justificativa tecnica formal item a item (este documento) para waiver de ATC.
- Acao de codigo em V04: nenhuma alteracao de fonte, porque nao ha troca de baixo risco validada no release atual.

---

## Backlog de refatoracao (V04.1 ou trilha clean-core)
1. Levantar APIs/views released disponiveis no seu release para: ordem de processo, status de ordem, texto de material/produto e estoque por lote.
2. Fazer POC isolada por objeto CDS (um por vez), comparando contagem/resultado com baseline atual.
3. So depois migrar a classe de remarcacao (CO_XT* e CO_ZV_ORDER_POST), com testes de regressao ponta a ponta.

---

## Conclusao objetiva para o ATC atual
Para os itens listados, hoje o correto e:
- dizer exatamente onde estao;
- documentar qual seria a troca tecnica esperada;
- assumir "nao tem o que fazer com seguranca agora" nos pontos criticos;
- seguir com waiver ATC nesta versao e refatoracao dedicada na proxima.

