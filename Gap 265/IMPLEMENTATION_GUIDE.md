# Projeto 265 - Guide de Implementacao

## 1. Visao geral

O GAP 265 implementa integracoes de Descarga com troca de arquivos PCS via AL11, cobrindo:

- Fluxo outbound SAP -> PCS (arquivos U200-H/U200-S e cancelamento U201).
- Fluxo inbound PCS -> SAP (arquivos U301-H/U301-S com persistencia e log).
- Reuso de objetos comuns para mensagem, TVARVC e utilitarios transversais.

Objetivo deste guide: evitar criacao fora de ordem e erros de dependencia durante montagem/ativacao tecnica.

## 2. Mapa de dependencias

### 2.1 Objetos base

Base DDIC (tipos primitivos usados por classes, tabelas e estruturas):

- Data Elements `ZDEQ2C_265_*` (ex.: `zdeq2c_265_order_num`, `zdeq2c_265_prod_num`, `zdeq2c_265_desc_*`).
- Estrutura tecnica: `zstq2c_ret_granel_l301_h`.

Observacao: os Domains nao estao exportados neste diretorio; devem existir/ser criados no ambiente antes dos Data Elements que dependem deles.

### 2.2 Objetos de persistencia

- Tabela de interface inbound: `ztq2c_pcs_det_d` (copia adaptada de `ZTQ2C_PCS_DET`).
- Tabela indice/apoio inbound: `ztq2c_pcs_itm_d` (copia adaptada de `ZTQ2C_PCS_ITM`).
- Tabela de log inbound/outbound descarga: `ztbq2c_descgralog`.
- Tabela de log de retorno/carga de referencia: `ztbq2c_retgralog`.

Dependencias:

- Todas dependem de Data Elements e, quando aplicavel, estruturas base.
- Classes de processamento dependem destas tabelas estarem ativas.

### 2.3 Objetos de regra/processamento

Objetos comuns:

- Classe comum: `zclq2c_265_desc_common`.
- Message class comum: `zcl_q2c_265_msg_dg`.

Outbound:

- Classe core: `zclq2c_265_descarga_granel`.
- Runner manual: `zrq2c_descarga_granel`.

Inbound:

- Classe core: `zclq2c_265_desc_ret_granel`.
- Classe de job: `zclq2c_265_desc_job`.
- Runner manual: `zrq2c_desc_ret_granel`.

Dependencias:

- `zclq2c_265_desc_common` deve existir antes de classes core e runners.
- Classes core dependem de DDIC base + tabelas de persistencia + message class.
- Runners dependem das classes core.
- Classe de job depende da classe core inbound e objetos APJ.

### 2.4 Objetos de exposicao/consumo

No GAP 265 desta estrutura nao ha camada RAP/OData (CDS behavior/service binding) para este fluxo.

Objetos de consumo tecnico identificados:

- Template/definicao de job APJ: `zjce_265_int_carregamento.sajc.json`.
- Variante/template APJ: `zjt_265_int_carregamento.sajt.json`.

Dependencias:

- APJ deve ser criado somente apos classes de execucao (`zclq2c_265_desc_job`) estarem ativas.

## 3. Ordem recomendada de criacao

1. Criar/confirmar Domains necessarios no ambiente (quando inexistentes).
2. Criar Data Elements `ZDEQ2C_265_*`.
3. Criar estrutura DDIC `zstq2c_ret_granel_l301_h`.
4. Criar tabelas transparentes de interface/log (`ztq2c_pcs_det_d`, `ztq2c_pcs_itm_d`, `ztbq2c_descgralog`, `ztbq2c_retgralog`).
5. Criar message class comum (`zcl_q2c_265_msg_dg`).
6. Criar classe comum (`zclq2c_265_desc_common`).
7. Criar classes core de negocio (`zclq2c_265_descarga_granel` e `zclq2c_265_desc_ret_granel`).
8. Criar classe de job (`zclq2c_265_desc_job`).
9. Criar runners (`zrq2c_descarga_granel`, `zrq2c_desc_ret_granel`).
10. Criar/ajustar objetos APJ (`*.sajc.json`, `*.sajt.json`) e validar execucao.
11. Ativar lote final e executar validacoes tecnicas de ponta a ponta.

## 4. Ordem de ativacao

Ativar em blocos para reduzir erro em cascata:

1. DDIC base: Domains -> Data Elements -> Estruturas.
2. Persistencia: tabelas transparentes e indices.
3. Mensagens e objetos comuns.
4. Classes core (outbound/inbound).
5. Classe de job e objetos APJ.
6. Runners/programas.
7. Ativacao em massa final do pacote para garantir consistencia cruzada.

Regra pratica: se um objeto referencia TYPE, TABLE, MESSAGE-ID, CLASS ou REPORT que ainda nao ativa, voltar uma etapa e ativar dependencia primeiro.

## 5. Validacoes por etapa

### Etapa 1 - Base DDIC

- Ativacao sem erro (SE11/ADT).
- Where-used basico para garantir visibilidade dos tipos.
- Verificar tamanho/tipo tecnico dos Data Elements conforme layout PCS.

### Etapa 2 - Persistencia

- Ativacao sem erro de chave, foreign key ou tipo.
- Teste rapido de leitura/escrita tecnico (SE16N/SQL Console em ambiente de dev).
- Conferir campos obrigatorios para log e rastreabilidade.

### Etapa 3 - Mensagens e comum

- Message class ativa e numeros utilizados pelas classes existentes.
- Classe comum compila sem warnings criticos.
- Teste rapido de leitura de parametro TVARVC (quando aplicavel).

### Etapa 4 - Classes core

- Syntax check (Ctrl+F2/ATC local) sem erro.
- Verificar dependencias de AL11, TVARVC e tabelas Z ativas.
- Executar fluxo minimo com runner em modo controlado.

### Etapa 5 - Job/APJ

- Classe de job ativa com interfaces APJ implementadas.
- Objeto SAJC/SAJT consistente com classe de execucao.
- Disparo tecnico de job com parametros minimos.

### Etapa 6 - Runners e validacao final

- Runner executa sem dump com parametros validos.
- Conferir criacao/consumo de arquivo e log gravado.
- Validar cenarios de sucesso e erro minimo.
- Rodar ATC/check final no pacote do GAP 265.

## 6. Observacoes tecnicas

- Nao criar consumidores (runner/job) antes de classes base e DDIC.
- Nao criar classes core antes de message class e tabelas de persistencia.
- Nao iniciar APJ antes da classe de job ativa.
- Evitar hardcode de textos de mensagem; usar message class/text elements.
- Manter comentarios tecnicos relevantes e rastreaveis.
- Padronizar cabecalho tecnico com Object Name, Object Title, WRICEF ID, Request/CHARM, Author e Date.
- Author padrao para este pacote: RTiezzi.

## 7. Checklist final

- [ ] Objetos base criados e ativados.
- [ ] Persistencia criada e ativada.
- [ ] Classe/message comum criadas.
- [ ] Classes principais de regra criadas.
- [ ] Objetos de execucao (runner/job/APJ) criados.
- [ ] Testes minimos executados (sucesso e erro).
- [ ] Cabecalhos revisados.
- [ ] Request preenchida nos cabecalhos.
- [ ] Author corrigido para RTiezzi.
