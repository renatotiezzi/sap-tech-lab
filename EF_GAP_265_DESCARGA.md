# GAP 265 | Descarga PCS | Desenvolvimento ABAP seguindo padrao da Carga

## Objetivo

Desenvolver a parte de Descarga do GAP 265 seguindo o padrao tecnico ja existente na parte de Carga.

A Carga ja foi desenvolvida no pacote `ZPQ2C_265_20260703_082358`.

O Copilot ja analisou essa implementacao e identificou a arquitetura base. Portanto, este desenvolvimento nao deve criar uma arquitetura nova. A Descarga deve ser uma continuacao natural do padrao ja implementado na Carga, alterando apenas processo funcional, layouts, tabelas, validacoes e regras especificas da Descarga.

Regra principal:

> Ler o padrao atual da Carga e replicar para Descarga, mantendo arquitetura, nomenclatura, pipeline, logs, TVARVC, AL11, runners e job/APJ no mesmo estilo.

---

## Documentos funcionais base

Usar como base funcional:

1. `Q2C265I004 - Interface com PCS para envio dos dados de descarga`
   - Fluxo SAP -> PCS
   - Geracao dos arquivos da Descarga
   - Layouts `U200-H` e `U200-S`
   - Disparo pelo APP 340 no botao `CONFIRMAR E ENVIAR`

2. `Q2C265I005 e Q2C265I006 - Interface com PCS para Retorno dos dados de descarga`
   - Fluxo PCS -> SAP
   - Leitura do retorno da Descarga
   - Layouts `U301-H` e `U301-S`
   - Processamento via job lendo AL11
   - Cancelamento SAP -> PCS via arquivo `U201`

---

## Arquitetura modelo existente da Carga

Usar como referencia tecnica os objetos existentes da Carga:

- `zclq2c_265_carga_granel`
- `zclq2c_265_carga_ret_granel`
- `zclq2c_265_job`
- `zrq2c_carga_ret_granel`
- `zjce_265_int_carregamento.sajc.json`
- `zjt_265_int_carregamento.sajt.json`
- `zcl_q2c_265_msg_cg`
- `ztbq2c_retgralog`
- `zdeq2c_265_*`

A arquitetura da Carga ja possui:

- classe outbound
- classe inbound/retorno
- runner manual
- job/APJ
- leitura de TVARVC
- leitura de diretorio AL11
- gravacao de arquivo AL11
- parse de arquivos
- validacao
- mensagens
- log/historico
- commit transacional
- resumo de execucao

A Descarga deve seguir esse mesmo modelo.

---

## Comparativo entre Carga e Descarga

A Carga possui dois fluxos principais:

| Processo | Sentido | Classe modelo |
| --- | --- | --- |
| Envio da Carga | SAP -> PCS | `zclq2c_265_carga_granel` |
| Retorno da Carga | PCS -> SAP | `zclq2c_265_carga_ret_granel` |

A Descarga tambem deve possuir dois fluxos principais:

| Processo | Sentido | Classe nova sugerida |
| --- | --- | --- |
| Envio da Descarga | SAP -> PCS | `zclq2c_265_descarga_granel` |
| Retorno da Descarga | PCS -> SAP | `zclq2c_265_desc_ret_granel` |

Alm disso, a Descarga possui o cancelamento SAP -> PCS via `U201`.

O cancelamento deve ser tratado no contexto do outbound da Descarga, preferencialmente como metodo da classe `zclq2c_265_descarga_granel`, salvo se o padrao atual do GAP 265 justificar classe separada.

---

# Escopo 1 | Envio da Descarga SAP -> PCS

## Objetivo funcional

Quando a Ordem de Descarga for confirmada no APP 340, o SAP deve gerar os arquivos para o PCS executar a operacao fisica de descarga.

O gatilho funcional principal e o botao `CONFIRMAR E ENVIAR`.

O envio deve ocorrer apos as confirmacoes funcionais necessarias:

- tanque
- linha
- plataforma
- aprovacao do DU
- dados fiscais da NF-e
- dados logisticos da descarga
- lacres

## Arquivos gerados

Gerar dois arquivos no AL11:

- `U200-H<DDMMAAHHMMSS>.txt`
- `U200-S<DDMMAAHHMMSS>.txt`

Os dois arquivos devem compartilhar o mesmo `ORDERNUM`.

## Formato dos arquivos

- Delimitador: `;`
- Terminador: `CRLF`
- Encoding: seguir padrao ja usado na Carga
- Diretorio: AL11 via TVARVC, sem hardcode

## Classe referencia

Usar como modelo:

- `zclq2c_265_carga_granel`

Criar para Descarga:

- `zclq2c_265_descarga_granel`

A classe deve seguir o mesmo estilo da classe de Carga:

- mesma separacao de responsabilidade
- mesmo padrao de metodos
- mesma forma de carregar TVARVC
- mesma forma de carregar dados
- mesma forma de validar
- mesma forma de montar payload
- mesma forma de gravar arquivo
- mesma forma de tratar mensagens
- mesma forma de logar execucao

Nao criar desenho paralelo.

---

## Pipeline esperado | Envio Descarga

Usar o pipeline da classe outbound da Carga como referencia.

Fluxo logico esperado:

1. carregar parametros TVARVC
2. carregar dados da Ordem de Descarga
3. validar dados obrigatorios
4. montar registro `U200-H`
5. montar registros `U200-S`
6. gravar arquivos no AL11
7. atualizar status/historico, se aplicavel no padrao atual
8. registrar logs/mensagens
9. retornar sucesso ou erro ao chamador

O nome exato dos metodos deve seguir a nomenclatura ja existente na Carga. Se ja existir metodo equivalente na Carga, reutilizar o padrao de nome.

---

## Layout U200-H | Header da Descarga

Gerar um registro por Ordem de Descarga.

| Seq | Campo PCS | Regra / Origem |
| --- | --- | --- |
| 1 | ORDERNUM | `DG` + intervalo/range de numeracao definido |
| 2 | INVOQTYL | quantidade da NF-e em litros |
| 3 | INVOQTKG | peso bruto da NF-e em kg |
| 4 | DESTTANK | tanque destino. Buscar sequencial em `OIISOCISL` conforme deposito/centro |
| 5 | PRODNUM | codigo do material |
| 6 | PRODNAME | descricao do material |
| 7 | PRODDEN | densidade via dados de QM/lote de inspecao |
| 8 | UNLOADLN | linha de descarga |
| 9 | UNLOADPT | plataforma |
| 10 | TRUCKID | placa cavalo |
| 11 | COLORYN | cor/mangote conforme cadastro/material |
| 12 | PPRDNAME | produto anterior |
| 13 | PPRODNUM | codigo do produto anterior |
| 14 | SAMPLEYN | indicador de amostra/laboratorio |
| 15 | LABMAN | responsavel/aprovador laboratorio |
| 16 | LADAPPTM | data/hora aprovacao laboratorio |
| 17 | INVOICEN | numero NF-e |
| 18 | BATCHIDS | lote material/fornecedor |
| 19 | MSGRCVTM | data/hora de geracao/envio da mensagem |
| 20 | CARTID | placa carreta |

A origem tecnica exata deve ser validada nos objetos existentes do APP 340, na tabela/estrutura `ZDESCARGA` e nos objetos ja entregues do processo de Descarga.

Nao inventar origem caso exista campo oficial no APP 340 ou DDIC do processo.

---

## Layout U200-S | Lacres da Descarga

Gerar registros de lacre vinculados ao mesmo `ORDERNUM` do `U200-H`.

| Seq | Campo PCS | Regra / Origem |
| --- | --- | --- |
| 1 | SORDRNM | mesmo `ORDERNUM` do header |
| 2 | SEALCODE | enviar vazio, conforme EF |
| 3 | SCOLOR | cor do lacre fornecedor |
| 4 | SSEALID | codigo do lacre fornecedor |
| 5 | SSEALQTY | quantidade de lacres fornecedor |

---

## Validacoes do Envio

Antes de gerar os arquivos, validar:

- Ordem de Descarga existe
- Ordem esta no status correto para envio ao PCS
- NF-e vinculada e validada
- DU aprovado, quando aplicavel
- tanque informado
- linha informada
- plataforma informada
- produto informado
- quantidade da NF-e preenchida
- peso da NF-e preenchido
- placa cavalo preenchida
- placa carreta preenchida quando aplicavel
- lacres informados
- diretorio de saida configurado
- usuario/processo com autorizacao para gravar no AL11

Em caso de erro funcional:

- nao gerar arquivo parcial
- nao atualizar status como enviado
- registrar mensagem/log conforme padrao da Carga
- retornar erro ao APP 340

Em caso de erro tecnico:

- nao atualizar status como enviado
- registrar log tecnico
- permitir reprocessamento manual

---

# Escopo 2 | Retorno da Descarga PCS -> SAP

## Objetivo funcional

O PCS executa a descarga fisica e gera o arquivo de retorno com os dados operacionais.

O SAP deve ler periodicamente os arquivos no AL11, validar o conteudo e persistir o resultado da descarga.

Esse fluxo e inbound do ponto de vista do SAP.

## Processamento

O processamento deve ocorrer via job/batch, seguindo o padrao tecnico ja usado no retorno da Carga.

O job deve:

- listar arquivos pendentes no diretorio AL11 de entrada
- processar arquivo a arquivo
- interpretar `U301-H`
- interpretar `U301-S`
- validar os dados
- gravar retorno na tabela Z
- mover arquivos processados/erro, se este for o padrao aplicado na Carga
- registrar logs e historico

## Arquivos/blocos processados

O retorno contem:

- `U301-H` | Header Data
- `U301-S` | Compartment Data / Lacres

Os dois blocos usam o mesmo `ORDERNUM`.

## Classe referencia

Usar como modelo:

- `zclq2c_265_carga_ret_granel`

Criar para Descarga:

- `zclq2c_265_desc_ret_granel`

Essa classe deve espelhar a classe de retorno da Carga.

---

## Pipeline esperado | Retorno Descarga

O pipeline deve seguir o metodo `execute` da classe de retorno da Carga.

Modelo observado na Carga:

1. `load_stvarv_values`
2. `display_main_header`
3. `get_directory_files`
4. `process_single_file`
5. `valida_arquivos`
6. `load_data`
7. `update_retorno`
8. `error_handling`
9. `update_historico`
10. `display_file_summary`

Para Descarga, manter o mesmo desenho logico:

1. carregar parametros TVARVC
2. exibir header da execucao quando aplicavel
3. listar arquivos de entrada no AL11
4. processar arquivo a arquivo
5. parsear `U301-H` e `U301-S`
6. validar consistencia do arquivo
7. carregar dados SAP necessarios para validar `ORDERNUM`
8. gravar retorno da descarga
9. tratar erro
10. atualizar historico/log
11. exibir resumo da execucao

Nao criar novo fluxo se o fluxo da Carga atende.

---

## Layout U301-H | Header de Retorno

Gravar um registro por Ordem.

| Seq | Campo PCS | Campo SAP sugerido |
| --- | --- | --- |
| 1 | ORDERNUM | ORDERNUM |
| 2 | TRKINTWT | TRKINTWT |
| 3 | TRKFNLWT | TRKFNLWT |
| 4 | LINEEMTY | LINEEMTY |
| 5 | PT_YRN | PT_YRN |
| 6 | DESTTYRN | DESTTYRN |
| 7 | PRODNUMB | PRODNUMB |
| 8 | LINE2USE | LINE2USE |
| 9 | TRKIDY2N | TRKIDY2N |
| 10 | CLRHOSE | CLRHOSE |
| 11 | AVVERYRN | AVVERYRN |
| 12 | COMPDROP | COMPDROP |
| 13 | TRKGDRYN | TRKGDRYN |
| 14 | TRKBKACT | TRKBKACT |
| 15 | TRKMTOFF | TRKMTOFF |
| 16 | LABINFO | LABINFO |
| 17 | AVVEREND | AVVEREND |
| 18 | STARTTME | STARTTME |
| 19 | ENDTIME | ENDTIME |
| 20 | SUPNAME | SUPNAME |
| 21 | OPSNAME | OPSNAME |

---

## Layout U301-S | Lacres de Retorno

Gravar ate 10 registros por Ordem.

| Seq | Campo PCS | Campo SAP sugerido |
| --- | --- | --- |
| 1 | SORDRNM | ORDERNUM |
| 2 | SEALCODE | SEALCODE |
| 3 | SEALYRN | SEALYRN |

---

## Persistencia do Retorno

A EF cita a tabela:

- `ZDESCARGA_INTERFACE_PCS`

Antes de criar qualquer DDIC novo, validar no ambiente se essa tabela ja existe ou se ja existe definicao oficial entregue para o processo.

Como o retorno possui header e ate 10 lacres, existem duas possibilidades:

1. header e itens na mesma tabela, se a EF/DDIC oficial ja tiver definido assim
2. header em tabela principal e lacres em tabela filha, se ainda nao houver DDIC definitivo

Recomendacao tecnica, apenas se ainda nao existir tabela oficial:

- `ZDESCARGA_INTERFACE_PCS` | Header
- `ZDESCARGA_INTERFACE_PCS_I` | Itens/Lacres

Nao duplicar tabela.

Nao criar estrutura paralela se a tabela oficial ja existir.

Nao alterar definicao funcional sem evidencia.

---

## Regras de gravacao do Retorno

A gravacao deve ser idempotente.

Para o mesmo `ORDERNUM`:

- atualizar/substituir header
- substituir lacres anteriores pelos lacres do novo arquivo
- nao duplicar itens
- registrar reprocessamento se o padrao da Carga ja fizer isso

Seguir o mesmo padrao transacional da Carga:

- update/modify em massa quando possivel
- commit explicito conforme padrao ja usado no GAP 265
- rollback/tratamento de erro se a gravacao falhar
- nao deixar header e itens inconsistentes

---

## Validacoes do Retorno

Validar por arquivo:

- arquivo legivel
- layout com delimitador `;`
- header `U301-H` identificado
- `ORDERNUM` preenchido
- `ORDERNUM` existente no SAP
- campos obrigatorios preenchidos
- pesos numericos
- flags `Y/N` validas
- `LINEEMTY` com valor permitido
- datas no formato esperado pela EF
- quantidade maxima de lacres respeitada
- lacres vinculados ao mesmo `ORDERNUM` do header

Em erro:

- registrar log/mensagem conforme padrao da Carga
- mover arquivo para erro se esse for o padrao ativo da Carga
- nao deixar dados inconsistentes gravados

---

# Escopo 3 | Cancelamento SAP -> PCS

## Objetivo funcional

O cancelamento e um fluxo SAP -> PCS.

Ele deve ser chamado pelo APP 340 no botao de estorno.

## Regra funcional

O cancelamento deve:

- receber o numero da Ordem PCS gerada no SAP no momento do envio
- permitir execucao apenas quando a Ordem estiver no status `03 | TANQUE SELECIONADO`
- gerar arquivo `U201_%numeroOrdemCarregamento%`
- gravar no AL11 configurado
- enviar no conteudo apenas o `ORDER NUMBER`

## Implementacao tecnica

Implementar no contexto tecnico do outbound da Descarga.

Preferencia:

- metodo na classe `zclq2c_265_descarga_granel`

Criar classe separada somente se o padrao atual do projeto justificar.

## Arquivo U201

Nome:

- `U201_%numeroOrdemCarregamento%`

Conteudo:

- `ORDER NUMBER`

Regras:

- conteudo deve conter apenas o numero da Ordem
- usar CRLF se o padrao da Carga trabalhar com CRLF
- diretorio via TVARVC
- sem hardcode de path

---

# TVARVC e diretorios

Usar exatamente o padrao de configuracao da Carga.

A Carga usa TVARVC para:

- entrada
- saida/processados
- status de referencia

Para Descarga, criar parametros equivalentes seguindo a convencao do GAP 265.

Sugestao apenas se nao houver padrao mais especifico:

- `ZQ2C_DESCARGA_PCS_OUT`
- `ZQ2C_DESCARGA_PCS_IN`
- `ZQ2C_DESCARGA_PCS_PROC`
- `ZQ2C_DESCARGA_PCS_ERR`
- `ZQ2C_DESCARGA_PCS_STATUS`

Porem, a decisao final de nomes deve respeitar a convencao existente no pacote `ZPQ2C_265_20260703_082358`.

Nao hardcodar caminho AL11.

---

# Job, APJ e runners

A Carga ja possui:

- `zclq2c_265_job`
- `zrq2c_carga_ret_granel`
- `zjce_265_int_carregamento`
- `zjt_265_int_carregamento`

Para Descarga, criar equivalentes somente onde fizer sentido.

## Retorno da Descarga

Criar runner manual para processar inbound:

- `zrq2c_desc_ret_granel`

Criar job/APJ equivalente ao da Carga:

- `zclq2c_265_desc_job`

Ou adaptar o job existente se o padrao do projeto indicar um job generico por GAP.

## Envio da Descarga

O envio principal vem do APP 340.

Runner manual e util apenas para teste/reprocessamento:

- `zrq2c_descarga_granel`

O runner nao deve substituir o gatilho funcional do APP.

---

# Mensagens e logs

Seguir o padrao da Carga.

A Carga usa message class dedicada:

- `zcl_q2c_265_msg_cg`

Para Descarga, criar message class equivalente, por exemplo:

- `zcl_q2c_265_msg_dg`

Ou seguir exatamente o padrao de nome ja usado no pacote.

Nao usar mensagem final hardcoded no codigo.

Mensagens devem cobrir, no minimo:

- TVARVC nao configurada
- diretorio AL11 invalido
- erro ao abrir arquivo
- erro ao gravar arquivo
- erro ao listar diretorio
- Ordem de Descarga nao encontrada
- status invalido para envio
- status invalido para cancelamento
- campo obrigatorio ausente
- layout invalido
- valor invalido para flag
- retorno gravado com sucesso
- arquivo enviado com sucesso
- arquivo de cancelamento gerado com sucesso

Logs devem seguir o mesmo padrao da Carga, incluindo:

- inicio da execucao
- fim da execucao
- arquivo processado
- arquivo com erro
- chave funcional `ORDERNUM`
- mensagem tecnica/funcional
- resumo em execucao manual/job, quando aplicavel

---

# Comentarios no codigo

Este e um desenvolvimento novo da Descarga dentro do GAP 265.

Nao usar comentario de versao do tipo:

- `V6 - RTIEZZI`

Esse padrao faz sentido para ajuste evolutivo em objeto ja existente, nao para desenvolvimento novo.

Comentar apenas blocos relevantes, de forma limpa.

Exemplos aceitaveis:

```abap
" Monta header U200-H conforme layout PCS da Descarga
" Processa retorno U301-H/U301-S gerado pelo PCS
" Gera arquivo U201 para cancelamento da Ordem no PCS
```