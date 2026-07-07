# GAP 265 - Inbound Descarga

Escopo do inbound:

- ler arquivos PCS -> SAP no AL11
- interpretar `U301-H`
- interpretar `U301-S`
- validar consistencia do arquivo e do `ORDERNUM`
- gravar retorno da descarga em tabela Z
- mover arquivo para processado/erro quando o padrao definitivo pedir isso

## Objetos esperados

- `zclq2c_265_desc_ret_granel` - classe core de processamento inbound
- `zrq2c_desc_ret_granel` - runner para execucao manual e testes
- `zcl_q2c_265_msg_dg` ou equivalente - classe de mensagens do retorno
- `zq2c_descarga_*` - job/APJ se o padrao final exigir separacao do inbound

## Reuso da carga

Usar como guia:

- `zclq2c_265_carga_ret_granel`
- `zclq2c_265_job`
- `zrq2c_carga_ret_granel`

## Pipeline base

1. carregar parametros TVARVC
2. exibir header da execucao quando aplicavel
3. listar arquivos de entrada no AL11
4. processar arquivo a arquivo
5. parsear `U301-H` e `U301-S`
6. validar regras de negocio
7. localizar a Ordem de Descarga pelo `ORDERNUM`
8. persistir header e lacres
9. tratar erro e historico
10. exibir resumo/log

## Observacao tecnica

Persistencia do inbound deve usar `ZTQ2C_PCS_DET_D` (header) e `ZTQ2C_PCS_ITM_D` (itens), como copias adaptadas de `ZTQ2C_PCS_DET` e `ZTQ2C_PCS_ITM` da Carga.
