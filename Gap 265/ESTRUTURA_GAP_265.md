# GAP 265 - Estrutura Tecnica Base (Carga)

## Objetivo deste documento

Mapear o padrao tecnico implementado no pacote `ZPQ2C_265_20260703_082358` para servir como base do desenvolvimento de Descarga, mantendo arquitetura, nomenclatura e comportamento operacional similares.

## Estrutura de diretorios

- `Gap 265/ZPQ2C_265_20260703_082358/.abapgit.xml`
- `Gap 265/ZPQ2C_265_20260703_082358/src/`

### Objetos principais em `src`

- Classes ABAP
  - `zclq2c_265_carga_granel.clas.abap`
  - `zclq2c_265_carga_ret_granel.clas.abap`
  - `zclq2c_265_job.clas.abap`
- Programa Runner
  - `zrq2c_carga_ret_granel.prog.abap`
- Job APJ
  - `zjce_265_int_carregamento.sajc.json` (Catalog Entry)
  - `zjt_265_int_carregamento.sajt.json` (Job Template)
- Mensagens
  - `zcl_q2c_265_msg_cg.msag.xml`
- DDIC (tipos de dados)
  - `zdeq2c_265_*.dtel.xml`
- Tabelas
  - `zstq2c_ret_granel_l301_h.tabl.xml`
  - `ztbq2c_retgralog.tabl.xml`

## Padrao arquitetural identificado

## 1) Separacao por responsabilidade

- Classe de geracao outbound: `zclq2c_265_carga_granel`
  - Monta payloads L200-H e L200-C.
  - Valida campos obrigatorios.
  - Escreve arquivos em diretorio configurado em TVARVC.
- Classe de retorno inbound: `zclq2c_265_carga_ret_granel`
  - Lista arquivos no AL11.
  - Le e parseia layouts L300-H, L301-C e L301-H.
  - Valida equivalencia entre arquivos por chave de negocio (SHNUMBER).
  - Carrega dados de apoio da base.
  - Atualiza tabela de negocio (`ztq2c_pcs_det`).
  - Atualiza historico/status.
  - Prepara logs de processamento.
- Classe APJ: `zclq2c_265_job`
  - Implementa `if_apj_dt_exec_object` e `if_apj_rt_exec_object`.
  - Define parametros de job e executa a classe de retorno.
- Runner SE38/SA38: `zrq2c_carga_ret_granel`
  - Executa manualmente o mesmo fluxo da classe de retorno.

## 2) Pipeline tecnico do inbound (retorno)

Fluxo observado no metodo `execute` de `zclq2c_265_carga_ret_granel`:

1. `load_stvarv_values`
2. `display_main_header` (quando execucao com flag de job)
3. `get_directory_files`
4. `process_single_file` para cada arquivo elegivel
5. `valida_arquivos` (consistencia entre L300-H/L301-C/L301-H)
6. `load_data`
7. `update_retorno`
8. `error_handling`
9. `update_historico`
10. Impressao de resumo (`display_file_summary`) em execucao de job

Observacao: rotinas de `move_input_file` e `update_log` existem no codigo, mas aparecem comentadas no fluxo principal atual.

## 3) Padrao de configuracao (customizing)

A classe de retorno usa leitura de parametros via TVARVC (helper `zcl_tvarvc_range`) para:

- caminho de entrada (`ZQ2C_RETORNO_PCS_IN`)
- caminho de saida/processados (`ZQ2C_RETORNO_PCS_OUT`)
- status de referencia (`ZQ2C_RETORNO_PCS_STATUS`)

Tambem ha uso de leitura de diretorio AL11 por `EPS2_GET_DIRECTORY_LISTING`.

## 4) Padrao de mensagens e monitoracao

- Classe de mensagens dedicada: `ZCL_Q2C_265_MSG_CG`.
- Estrutura interna de mensagens com metadados:
  - arquivo
  - chave de negocio (shnumber/com_number)
  - msgid/msgno/tipo/severity
  - variaveis de texto (`v1..v4`)
- Persistencia prevista em tabela de log `ZTBQ2C_RETGRALOG`.

## 5) Padrao de dados e naming

- Prefixo tecnico dominante: `zq2c_265` / `zdeq2c_265` / `zclq2c_265`.
- Estruturas de layout mapeadas por tipo:
  - L200-H / L200-C (saida)
  - L300-H / L301-C / L301-H (retorno)
- Chave funcional recorrente no fluxo: `shnumber`.

## 6) Padrao de commit transacional

- Atualizacao em massa com `UPDATE ... FROM TABLE`.
- Confirmacao explicita com `BAPI_TRANSACTION_COMMIT` (`wait = abap_true`) apos update de negocio.

## Reuso recomendado para o futuro dev de Descarga

## Reaproveitar quase 1:1

- Estrutura de classe de processamento inbound (metodos e pipeline).
- Classe APJ (`if_apj_dt_exec_object` / `if_apj_rt_exec_object`).
- Runner para teste/manual.
- Modelo de leitura de AL11 e parse por layout.
- Modelo de tratamento de mensagens e resumo de execucao.
- Modelo de TVARVC para paths/status.

## Trocar no dev de Descarga

- Layouts e campos de parse (ex.: U301-H e campos de peso).
- Tabelas/visoes de destino para update de negocio.
- Classe de mensagens e textos funcionais especificos de descarga.
- Regras de validacao de negocio (status, chave de busca, fallbacks).

## Checklist estrutural para o novo GAP (descarga)

- Criar classe core de retorno descarga espelhando pipeline do inbound atual.
- Criar classe APJ equivalente com parametros minimos (path/chave/item).
- Criar runner de apoio para execucao manual.
- Criar classe de mensagens dedicada.
- Definir TVARVCs de entrada, processado/erro e status.
- Definir tabela de log tecnico e pontos de commit.
- Preservar nomenclatura e organizacao de metodos no mesmo estilo do GAP 265.

## Referencias analisadas

- `Gap 265/ZPQ2C_265_20260703_082358/src/zclq2c_265_carga_granel.clas.abap`
- `Gap 265/ZPQ2C_265_20260703_082358/src/zclq2c_265_carga_ret_granel.clas.abap`
- `Gap 265/ZPQ2C_265_20260703_082358/src/zclq2c_265_job.clas.abap`
- `Gap 265/ZPQ2C_265_20260703_082358/src/zrq2c_carga_ret_granel.prog.abap`
- `Gap 265/ZPQ2C_265_20260703_082358/src/zjce_265_int_carregamento.sajc.json`
- `Gap 265/ZPQ2C_265_20260703_082358/src/zjt_265_int_carregamento.sajt.json`
- `Gap 265/ZPQ2C_265_20260703_082358/src/zcl_q2c_265_msg_cg.msag.xml`
