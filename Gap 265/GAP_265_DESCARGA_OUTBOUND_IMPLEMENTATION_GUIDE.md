# GAP 265 - Descarga Outbound - Implementation Guide

## 1. Objetivo
Definir a implementacao tecnica do fluxo Descarga Outbound no pacote ZPQ2C_265_D com estrategia copy-first, reuso maximo de objetos ja existentes do GAP 265 e zero duplicacao desnecessaria.

Objetivo funcional do fluxo:
- Gerar arquivos U200-H e U200-S para envio SAP -> PCS.
- Suportar cancelamento via arquivo U201.
- Validar dados minimos de negocio antes da geracao.
- Preservar compatibilidade com os fluxos ja entregues de Carga e Descarga Inbound.

Objetivo tecnico:
- Reusar DDIC e padroes ja existentes.
- Evitar criacao de Domain/Data Element/Structure sem necessidade real.
- Garantir ativacao sem erro por ordem correta de dependencias.

## 2. Escopo
Separacao de escopo do GAP 265:

- Outbound da Descarga:
  - Classe core: ZCLQ2C_265_DESCARGA_GRANEL
  - Runner manual: ZRQ2C_DESCARGA_GRANEL
  - Geracao de U200-H, U200-S, U201
  - Leitura de dados por ZI_Q2C_DESCARGA e ZI_Q2C_MONI_DESCARGA
  - Validacao de obrigatorios e status

- Inbound da Descarga:
  - Classe core: ZCLQ2C_265_DESC_RET_GRANEL
  - Job/APJ: ZCLQ2C_265_DESC_JOB
  - Runner manual: ZRQ2C_DESC_RET_GRANEL
  - Persistencia de retorno em ZTQ2C_PCS_DET_D e ZTQ2C_PCS_ITM_D
  - Log tecnico em ZTBQ2C_DESCGRALOG

- Comum entre Carga e Descarga:
  - Estrategia de TVARVC via ZZ1_TVARVC_Q2C
  - Padrao de mensagens e severidade
  - Padrao de gravacao AL11 e commit
  - Data elements base de negocio ja consolidados do GAP 265

- Especifico da Descarga Outbound:
  - Layout U200-H/U200-S e cancelamento U201
  - Campos de Descarga (ex.: DESTTANK, INVOQTYL, INVOQTYKG, BATCHIDS)
  - Regras de validacao para status da ordem de Descarga

## 3. Objetos existentes analisados
Objetos do pacote de Descarga ja existentes e relevantes:

- Classes:
  - ZCLQ2C_265_DESCARGA_GRANEL
  - ZCLQ2C_265_DESC_COMMON
  - ZCLQ2C_265_DESC_RET_GRANEL
  - ZCLQ2C_265_DESC_JOB

- Runners:
  - ZRQ2C_DESCARGA_GRANEL
  - ZRQ2C_DESC_RET_GRANEL

- Message class:
  - ZCL_Q2C_265_MSG_DG

- Tabelas Inbound Descarga:
  - ZTQ2C_PCS_DET_D
  - ZTQ2C_PCS_ITM_D
  - ZTBQ2C_DESCGRALOG

- Base de Carga (fonte de copia/referencia):
  - ZCLQ2C_265_CARGA_GRANEL
  - ZCLQ2C_265_CARGA_RET_GRANEL
  - ZCLQ2C_265_JOB
  - ZCL_Q2C_265_MSG_CG
  - Data elements ZDEQ2C_265_* (ja usados pela Carga)

- DDIC de Descarga em objetos comuns:
  - Serie ZDEQ2C_265_DESC_* (inclui ZDEQ2C_265_DESC_DESTTANK)

- Dependencias externas usadas no codigo:
  - CDS/views: ZI_Q2C_DESCARGA, ZI_Q2C_MONI_DESCARGA
  - Tabela historica: ZTBQ2C_DESCARGA
  - TVARVC custom: ZZ1_TVARVC_Q2C

Observacao:
- Nao foram encontrados novos domains, structures, table types ou CDS locais no diretorio do GAP 265 para Outbound Descarga.
- O desenho atual e orientado a reuso de data elements e tabelas ja existentes.

## 4. Objetos comuns a reutilizar
Reuso obrigatorio antes de qualquer criacao:

- Reusar ZCLQ2C_265_DESC_COMMON para:
  - get_tvarvc_value
  - add_error
  - add_success
  - Motivo: padronizacao de TVARVC e mensagens em inbound/outbound Descarga.

- Reusar message class ZCL_Q2C_265_MSG_DG:
  - Motivo: ja centraliza codigos 011, 020, 030, 031, 032, 033, 034, 035, 040, 041, 099.
  - Nao recriar message class paralela para Outbound.

- Reusar data elements da base Carga:
  - Exemplos: ZDEQ2C_265_ORDER_NUM, ZDEQ2C_265_PROD_NUM, ZDEQ2C_265_PROD_NAME, ZDEQ2C_265_PROD_DEN, ZDEQ2C_265_LOAD_LINE, ZDEQ2C_265_LOAD_PTFM, ZDEQ2C_265_TRUCK_ID, ZDEQ2C_265_MSGRCVTM, ZDEQ2C_265_SEALCLR, ZDEQ2C_265_SEAL_NUM, ZDEQ2C_265_SEAL_QTY.
  - Motivo: compatibilidade semantica e tecnica com pipeline GAP 265.

- Reusar data elements Descarga ja criados em objetos comuns:
  - Exemplos: ZDEQ2C_265_DESC_INVOQTYL, ZDEQ2C_265_DESC_INVOQKG, ZDEQ2C_265_DESC_DESTTANK, ZDEQ2C_265_DESC_COLORYN, ZDEQ2C_265_DESC_SAMPLEYN, ZDEQ2C_265_DESC_LABMAN, ZDEQ2C_265_DESC_LADAPPTM, ZDEQ2C_265_DESC_INVOICEN, ZDEQ2C_265_DESC_BATCHIDS, ZDEQ2C_265_DESC_CARTID, ZDEQ2C_265_DESC_SEALCODE.
  - Motivo: ja versionados para Descarga; evita duplicidade e divergencia.

Onde o reuso deve ser chamado no codigo:
- ZCLQ2C_265_DESCARGA_GRANEL:
  - execute e cancel_order usando ZCLQ2C_265_DESC_COMMON
  - load_tvarvc usando get_tvarvc_value
  - validacoes usando add_error
- ZCLQ2C_265_DESC_RET_GRANEL:
  - load_tvarvc, valida_arquivos, update_log usando ZCLQ2C_265_DESC_COMMON
- Runners:
  - Tipagem e retorno de mensagens via ZCLQ2C_265_DESC_COMMON=>TT_MESSAGE

## 5. Objetos especificos da Descarga Outbound
Objetos especificos que devem ser mantidos no Outbound:

- ZCLQ2C_265_DESCARGA_GRANEL
  - Responsavel por:
    - carregar dados da ordem
    - validar obrigatorios
    - gerar U200-H e U200-S
    - gerar U201 no cancelamento
    - gravar AL11

- ZRQ2C_DESCARGA_GRANEL
  - Runner tecnico/manual para execucao controlada e suporte operacional.

Campos especificos do layout U200-H/U200-S:
- Header: DESTTANK, INVOQTYL, INVOQTYKG, UNLOADLN, UNLOADPT, BATCHIDS, INVOICEN, CARTID etc.
- Item: SEALCODE, SCOLOR, SSEALID, SSEALQTY.

## 6. Novos objetos DDIC necessarios
Decisao tecnica principal:
- Nao ha necessidade de criar novo objeto DDIC para corrigir o erro atual.
- O objeto ZDEQ2C_265_DESC_DESTTANK ja existe no repositorio de objetos comuns e deve ser reutilizado.

Tratamento do erro atual:
- Erro: Type ZDEQ2C_265_DESC_DESTTANK is unknown.
- Opcao escolhida: Reutilizar tipo existente.
- Acao: importar/ativar ZDEQ2C_265_DESC_DESTTANK no ambiente antes da ativacao da classe.
- Justificativa: ja existe definicao tecnica valida no pacote de Descarga comum.

Ficha tecnica do objeto reutilizado (nao novo):
- Nome tecnico sugerido: ZDEQ2C_265_DESC_DESTTANK
- Tipo de objeto: Data Element
- Descricao funcional: Destination Tank
- Tipo base: CHAR
- Tamanho: 10
- Decimais: nao aplicavel
- Valores fixos: nao aplicavel
- Objeto dependente anterior: nenhum dominio custom obrigatorio
- Ordem correta de criacao: ativar/importar antes das classes que o referenciam
- Request: ZPQ2C_265_20260703_082358
- Pacote: ZPQ2C_265_D
- Observacoes de ativacao: se ausente no ambiente, ativacao da classe falha com type unknown

Politica DDIC para este escopo:
- Domain novo: nao criar.
- Data Element novo: nao criar enquanto houver equivalente aderente.
- Structure/Table Type novo: nao criar para Outbound sem gap tecnico comprovado.
- Se algum DDIC estiver faltando no sistema, tratar como transporte/importacao de objeto existente, nao criacao conceitual nova.

## 7. Ordem de criacao dos objetos
Ordem recomendada para evitar dependencias quebradas:

1. Confirmar presenca/ativacao dos data elements reutilizados (base Carga e serie ZDEQ2C_265_DESC_*).
2. Validar message class ZCL_Q2C_265_MSG_DG ativa.
3. Validar dependencias externas ativas:
   - ZI_Q2C_DESCARGA
   - ZI_Q2C_MONI_DESCARGA
   - ZZ1_TVARVC_Q2C
4. Ativar classe comum ZCLQ2C_265_DESC_COMMON.
5. Ativar classe Outbound ZCLQ2C_265_DESCARGA_GRANEL.
6. Ativar runner ZRQ2C_DESCARGA_GRANEL.
7. Ativacao em massa final de objetos da Descarga.
8. Executar testes tecnicos e funcionais.

Observacao de sequencia generica (quando houver novos DDIC em futuras versoes):
- Domain -> Data Element -> Structure -> Table Type -> Table -> Classes -> Reports/Jobs.

## 8. Ajustes nas classes ABAP
Escopo de ajuste recomendado (sem redesign):

- ZCLQ2C_265_DESCARGA_GRANEL:
  - Nao trocar o tipo DESTTANK por outro da Carga.
  - Manter TYPE ZDEQ2C_265_DESC_DESTTANK.
  - Garantir so a disponibilidade do DDIC no ambiente.

- ZCLQ2C_265_DESC_COMMON:
  - Manter como ponto unico de TVARVC e mensagens.

- ZRQ2C_DESCARGA_GRANEL:
  - Sem alteracao estrutural, apenas uso da classe core.

Cabecalho padrao obrigatorio para objetos novos/alterados:
- Object Name
- Object Title
- WRICEF ID
- Request/CHARM: ZPQ2C_265_20260703_082358
- Author: RTiezzi
- Date

Comentarios de alteracao (quando houver mudanca em objeto existente):
- Usar padrao: VXX - RTIEZZI - descricao objetiva do ajuste
- Comentar apenas decisao tecnica relevante, regra de negocio e ponto de reuso.
- Evitar comentarios excessivos.

## 9. Tratamento de mensagens
Padrao definido:

- Message class unica: ZCL_Q2C_265_MSG_DG
- Classe de apoio: ZCLQ2C_265_DESC_COMMON
- Metodos:
  - add_error para erros bloqueantes
  - add_success para sucesso tecnico/operacional
- Boas praticas:
  - Sem hardcode de texto em regra de negocio quando houver mensagem catalogada
  - Reaproveitar numeros de mensagem existentes
  - Preservar severidade padrao do projeto

## 10. Estrategia de ativacao
Estrategia recomendada para o cenario atual:

1. Pre-checagem no SE11/ADT de ZDEQ2C_265_DESC_DESTTANK e demais ZDEQ2C_265_DESC_* usados no Outbound.
2. Se faltar objeto, importar/transportar do pacote base da Descarga.
3. Ativar DDIC primeiro.
4. Ativar ZCL_Q2C_265_MSG_DG.
5. Ativar ZCLQ2C_265_DESC_COMMON.
6. Ativar ZCLQ2C_265_DESCARGA_GRANEL.
7. Ativar ZRQ2C_DESCARGA_GRANEL.
8. Ativacao em massa do pacote para validar dependencias cruzadas.

Criterio de aceite da ativacao:
- Zero erro de tipo desconhecido.
- Zero erro de objeto inexistente.
- Classes e runner ativos sem warnings criticos.

## 11. Plano de testes
Testes tecnicos e funcionais minimos:

1. Ativacao sem erro:
   - Ativar objetos do Outbound Descarga e confirmar sucesso.
2. Execucao do fluxo Descarga Outbound:
   - Rodar ZRQ2C_DESCARGA_GRANEL com ORDERNUM valido.
3. Validacao dos campos de cabecalho:
   - Confirmar geracao de U200-H com campos obrigatorios preenchidos.
4. Validacao dos itens:
   - Confirmar geracao de U200-S com lacres esperados.
5. Validacao dos tanques:
   - Confirmar DESTTANK preenchido a partir de LGORTDESTINO.
6. Validacao do payload gerado:
   - Conferir ordem e separador de campos conforme layout.
7. Validacao de mensagens de erro:
   - Simular falta de TVARVC, ORDERNUM invalido, status invalido.
8. Validacao de reprocessamento:
   - Reexecutar ordem e validar comportamento esperado do fluxo.
9. Nao impacto no Descarga Inbound:
   - Executar ZCLQ2C_265_DESC_RET_GRANEL/ZRQ2C_DESC_RET_GRANEL e validar persistencia.
10. Nao impacto no fluxo de Carga:
   - Regressao minima no pipeline de Carga Outbound/Inbound.

## 12. Checklist final de validacao
- [ ] Tipo ZDEQ2C_265_DESC_DESTTANK validado como existente e reutilizado.
- [ ] Nenhum DDIC novo criado sem necessidade comprovada.
- [ ] Reuso de ZCLQ2C_265_DESC_COMMON aplicado.
- [ ] Reuso de ZCL_Q2C_265_MSG_DG aplicado.
- [ ] Dependencias CDS e TVARVC validadas.
- [ ] ZCLQ2C_265_DESCARGA_GRANEL ativo sem erro.
- [ ] ZRQ2C_DESCARGA_GRANEL ativo sem erro.
- [ ] Testes tecnicos executados com sucesso.
- [ ] Testes funcionais executados com sucesso.
- [ ] Descarga Inbound sem regressao.
- [ ] Carga sem regressao.
- [ ] Cabecalho padrao e autoria RTiezzi respeitados.
- [ ] Comentarios de alteracao no padrao VXX - RTIEZZI usados quando aplicavel.

Resultado objetivo para o erro atual:
- Nao criar novo tipo.
- Reutilizar ZDEQ2C_265_DESC_DESTTANK ja existente.
- Corrigir por importacao/ativacao e ordem de dependencia de DDIC.
