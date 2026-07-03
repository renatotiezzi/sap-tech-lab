# GAP 265 - Outbound Descarga

Escopo do outbound:

- receber a confirmacao no APP 340
- gerar arquivos `U200-H` e `U200-S`
- gravar no AL11 com caminho via TVARVC
- manter idempotencia e log de execucao
- suportar cancelamento SAP -> PCS via `U201`

## Objetos esperados

- `zclq2c_265_descarga_granel` - classe core de geracao outbound
- `zrq2c_descarga_granel` - runner manual para teste/reprocessamento
- `zcl_q2c_265_msg_dg` ou equivalente - classe de mensagens do outbound
- `zq2c_descarga_*` - job/APJ se o fluxo de saida precisar de agendamento tecnico

## Reuso da carga

Usar como guia:

- `zclq2c_265_carga_granel`
- modelo de gravacao de arquivo e validacao de entrada/saida
- tratamento de mensagens e retorno por lista de severidade

## Pipeline base

1. carregar parametros TVARVC
2. carregar dados da Ordem de Descarga
3. validar dados obrigatorios
4. montar `U200-H`
5. montar `U200-S`
6. gravar arquivos no AL11
7. atualizar status/historico quando aplicavel
8. registrar logs/mensagens
9. retornar sucesso ou erro ao chamador

## Cancelamento

O cancelamento deve ficar aqui, salvo evidencia contraria da arquitetura:

- gerar `U201_%numeroOrdemCarregamento%`
- gravar apenas o `ORDER NUMBER`
- manter o mesmo padrao de caminho AL11 e controle por TVARVC
