# Projeto 265 - Guide de Implementacao (Copy-First)

## 1. Objetivo e premissas

Este guide segue o principio de copiar o que ja foi entregue no pacote base da Carga e ajustar apenas o delta necessario para Descarga.

Pacote base (fonte de verdade):

- `ZPQ2C_265_20260703_082358`

Premissas obrigatorias:

- Nao recriar arquitetura.
- Nao criar Data Element ou estrutura do zero se o equivalente ja existe na base.
- Priorizar copia + ajuste minimo (add/remocao pontual).
- Refatoracao somente quando inevitavel e minima (ex.: nomenclatura/chave de tabela para alinhamento com o padrao).

## 2. Baseline da primeira entrega

Objetos da primeira entrega que devem ser referencia direta:

- Core outbound: `zclq2c_265_carga_granel`
- Core inbound retorno: `zclq2c_265_carga_ret_granel`
- Job APJ: `zclq2c_265_job`
- Runner manual: `zrq2c_carga_ret_granel`
- Message class: `zcl_q2c_265_msg_cg`
- DDIC base: `zdeq2c_265_*`
- Estrutura de retorno: `zstq2c_ret_granel_l301_h`
- Log tecnico: `ztbq2c_retgralog`

Regra: para cada objeto novo de Descarga, apontar explicitamente de qual objeto da Carga ele foi copiado antes de qualquer ajuste.

## 2.1 Mapa exato de copia (origem -> destino)

### A) Tabelas

- Origem: `ztbq2c_retgralog` -> Destino: `ztbq2c_descgralog`
	- Copiar: estrutura completa da tabela (MANDT, TMSTMP, INTID, INTTY, INTST, MSGTY, MENSAGEM).
	- Remover: nenhum campo.
	- Adicionar: nenhum campo.
	- Ajustar: `TABNAME` e `DDTEXT` para contexto de Descarga.

- Origem: `ZTQ2C_PCS_DET` (ambiente) -> Destino: `ztq2c_pcs_det_d`
	- Copiar: estrutura de header PCS usada na Carga.
	- Remover: nao remover campos de layout sem validacao funcional.
	- Adicionar: chave de negocio SAP de Descarga (`SHNUMBER`, `REMESSA`, `ITEM_REMESSA`) quando nao vier pronta no objeto copiado.
	- Ajustar: `ORDERNUM` fica como atributo nao-chave.

- Origem: `ZTQ2C_PCS_ITM` (ambiente) -> Destino: `ztq2c_pcs_itm_d`
	- Copiar: estrutura de itens/lacres da Carga.
	- Remover: nao remover campos de item sem validacao funcional.
	- Adicionar: chave de negocio SAP (`SHNUMBER`, `REMESSA`, `ITEM_REMESSA`) + `SEQNO`.
	- Ajustar: `SORDRNM` como atributo nao-chave.

### B) Classes

- Origem: `zclq2c_265_carga_ret_granel` -> Destino: `zclq2c_265_desc_ret_granel`
	- Copiar: pipeline tecnico (`load_tvarvc` -> leitura AL11 -> parse -> validacao -> persistencia -> historico -> log/resumo).
	- Remover: blocos especificos de L300/L301 da Carga.
	- Adicionar: parse de `U301-H` e `U301-S`, persistencia em `ztq2c_pcs_det_d`/`ztq2c_pcs_itm_d`, update em `ztbq2c_descarga`.

- Origem: `zclq2c_265_carga_granel` -> Destino: `zclq2c_265_descarga_granel`
	- Copiar: estrutura da classe de envio (validacao, montagem de linhas, gravacao de arquivos, cancelamento).
	- Remover: campos e validacoes exclusivas de Carga.
	- Adicionar: campos e validacoes de Descarga conforme layout U200.

- Origem: `zclq2c_265_job` -> Destino: `zclq2c_265_desc_job`
	- Copiar: interfaces APJ (`if_apj_dt_exec_object` e `if_apj_rt_exec_object`) e forma de execucao.
	- Remover: parametros que nao se aplicam a Descarga.
	- Adicionar: parametros de Descarga (ex.: `ORDERNUM`) quando necessarios.

### C) Runners

- Origem: `zrq2c_carga_ret_granel` -> Destino: `zrq2c_desc_ret_granel`
	- Copiar: estrutura de report e chamada da classe core.
	- Remover: parametros de Carga nao usados na Descarga.
	- Adicionar: parametros minimos para operacao do retorno de Descarga.

- Origem: `zrq2c_carga_ret_granel` (padrao de report) -> Destino: `zrq2c_descarga_granel`
	- Copiar: formato de execucao manual/controlada.
	- Remover: selecoes especificas de retorno de Carga.
	- Adicionar: referencia/ordernum para envio e cancelamento de Descarga.

### D) Mensagens

- Origem: `zcl_q2c_265_msg_cg` -> Destino: `zcl_q2c_265_msg_dg`
	- Copiar: conceito de classe de mensagens dedicada por fluxo.
	- Remover: textos estritos de Carga.
	- Adicionar: textos de Descarga (U200/U301, ORDERNUM, retorno).

## 3. Estrategia por tipo de objeto

### 3.1 DDIC base (Data Elements e estrutura)

Nao criar do zero. Proceder assim:

1. Confirmar existencia no ambiente (SE11/ADT) dos `ZDEQ2C_265_*` necessarios.
2. Se ja existir: reutilizar.
3. Se nao existir no ambiente: transportar/copiar do pacote base exatamente como estao.
4. Somente depois aplicar ajuste pontual exigido por layout (ex.: tamanho de campo confirmado com funcional).

Para `zstq2c_ret_granel_l301_h`:

- Tratar como artefato de referencia pronto da primeira entrega.
- Nao redesenhar estrutura; copiar e ajustar apenas campos realmente diferentes no fluxo de Descarga.

### 3.2 Persistencia

Padrao adotado:

- `ztq2c_pcs_det_d` = copia adaptada de `ZTQ2C_PCS_DET`
- `ztq2c_pcs_itm_d` = copia adaptada de `ZTQ2C_PCS_ITM`
- `ztbq2c_descgralog` = copia direta de `ztbq2c_retgralog` (somente troca de nome/descricao)

Regras:

- Nao inventar modelo novo de persistencia.
- Manter chave orientada ao negocio SAP quando aplicavel.
- Usar `ORDERNUM` como atributo de correlacao, nao como pilar de arquitetura.

### 3.3 Classes, runner e job

Implementacao por copia controlada:

- `zclq2c_265_descarga_granel` copia a arquitetura de `zclq2c_265_carga_granel`.
- `zclq2c_265_desc_ret_granel` copia a arquitetura de `zclq2c_265_carga_ret_granel`.
- `zclq2c_265_desc_job` copia a arquitetura de `zclq2c_265_job`.
- `zrq2c_desc_ret_granel`/`zrq2c_descarga_granel` seguem o padrao do runner da Carga.

Permitido alterar somente:

- Layouts e campos especificos de Descarga.
- Tabelas de destino do retorno.
- Mensagens e textos funcionais da Descarga.
- Pontos de validacao estritamente necessarios ao cenario U301.

### 3.3.1 Fatoracao dos objetos tecnicos (resultado final esperado)

Objetivo desta secao: deixar explicito como os objetos de codigo devem ficar no estado final, sempre por copia da base da Carga com delta minimo.

- Origem: `zclq2c_265_carga_ret_granel` -> Destino final: `zclq2c_265_desc_ret_granel`
	- Manter: desenho de classe, sequencia de processamento, leitura AL11, validacao e resumo.
	- Ajustar minimo: trocar layouts de Carga para `U301-H`/`U301-S`.
	- Ajustar minimo: persistir em `ztq2c_pcs_det_d` e `ztq2c_pcs_itm_d`.
	- Ajustar minimo: log tecnico em `ztbq2c_descgralog` (mesmo conceito da Carga).
	- Ajustar minimo: update de historico na `ztbq2c_descarga` por `pcs_ordernum`.

- Origem: `zclq2c_265_job` -> Destino final: `zclq2c_265_desc_job`
	- Manter: interfaces APJ (`if_apj_dt_exec_object` e `if_apj_rt_exec_object`) e padrao de execucao.
	- Ajustar minimo: parametros do job para contexto de Descarga.
	- Ajustar minimo: instanciar e executar `zclq2c_265_desc_ret_granel`.

- Origem: `zrq2c_carga_ret_granel` -> Destino final: `zrq2c_desc_ret_granel`
	- Manter: padrao de runner tecnico para execucao manual.
	- Ajustar minimo: assinatura de parametros para retorno de Descarga.
	- Ajustar minimo: chamada da classe `zclq2c_265_desc_ret_granel`.

- Origem: `zclq2c_265_carga_granel` -> Destino final: `zclq2c_265_descarga_granel`
	- Manter: arquitetura de validacao, montagem de arquivo e gravacao.
	- Ajustar minimo: estruturas/layout de Descarga (`U200-H`/`U200-S` e cancelamento `U201`).
	- Ajustar minimo: leitura de dados de negocio da Descarga via objetos existentes.
	- Ajuste pontual em aberto: adotar `ZTBQ2C_CTRL_PCS` para controle de numeracao compartilhado.

- Origem: `zcl_q2c_265_msg_cg` -> Destino final: `zcl_q2c_265_msg_dg`
	- Manter: estrategia de classe de mensagens dedicada.
	- Ajustar minimo: textos e codigos para semantica de Descarga.

### 3.4 Estruturas de saida (orientacao objetiva)

Para evitar desenho do zero, usar sempre base de estrutura existente e aplicar delta:

- Estrutura de saida header Descarga (`ty_u200_h`) deve ser copiada de `ty_l200_h` em `zclq2c_265_carga_granel`.
	- Sugerir nome: manter `ty_u200_h` no objeto de Descarga (ja alinhado ao layout U200).
	- Remover da copia base: `SHNUMBER`, `ORIGORDN`, `LOADQTY`, `SOURCET`, `DRIVERNM`, `TANKINSP`, `FLUSHARM`, `FABS`, `SEALCLR`, `SEALNUM`, `SEALQTY`, `GRPNAME`.
	- Adicionar no delta Descarga: `INVOQTYL`, `INVOQTYKG`, `DESTTANK`, `UNLOADLN`, `UNLOADPT`, `COLORYN`, `SAMPLEYN`, `LABMAN`, `LADAPPTM`, `INVOICEN`, `BATCHIDS`, `CARTID`.

- Estrutura de saida item Descarga (`ty_u200_s`) deve copiar o padrao de segunda linha/arquivo da Carga (conceito de tabela filha) e ajustar para lacres.
	- Sugerir nome: manter `ty_u200_s`.
	- Remover da referencia de Carga: campos de compartimento de `ty_l200_c`.
	- Adicionar no delta Descarga: `SORDRNM`, `SEALCODE`, `SCOLOR`, `SSEALID`, `SSEALQTY`.

## 4. Ordem recomendada (copy-first)

1. Confirmar no ambiente o que ja existe da primeira entrega (DDIC, classes, mensagens, APJ).
2. Copiar/reutilizar DDIC base (`ZDEQ2C_265_*`, `zstq2c_ret_granel_l301_h`) sem redesenho.
3. Copiar e ajustar somente o delta das tabelas de persistencia da Descarga.
4. Copiar classe comum/mensagens e ajustar somente textos e numeros faltantes.
5. Copiar classes core (outbound/inbound) da Carga e aplicar delta de Descarga.
6. Copiar job e runners no mesmo padrao tecnico.
7. Ajustar APJ/TVARVC mantendo naming e comportamento da entrega base.
8. Ativar em blocos e validar fim a fim.

## 5. Ordem de ativacao

1. DDIC reaproveitado/copiado (domains, data elements, estruturas).
2. Tabelas de persistencia da Descarga.
3. Message class e objetos comuns.
4. Classes core (outbound/inbound).
5. Job/APJ.
6. Runners.
7. Ativacao final em massa.

Regra pratica: se houver dependencia quebrada, voltar para o objeto-base de onde deveria ter sido copiado e corrigir pelo mesmo padrao, sem redesign.

## 6. Validacoes obrigatorias

### 6.1 Alinhamento com baseline

- Pipeline da Descarga segue o mesmo desenho da Carga.
- Mesma estrategia de commit transacional.
- Mesma abordagem de TVARVC/AL11.
- Sem criacao de arquitetura paralela.

### 6.2 Delta funcional minimo

- Diferencas limitadas a layout/fields/target tables da Descarga.
- Se houver diferenca estrutural, documentar origem da copia e motivo do ajuste.
- Em qualquer conflito com GAP 340, manter o GAP 265 como pipeline unico de retorno PCS para Descarga.

### 6.3 DDIC

- Nenhum Data Element criado do zero sem justificativa tecnica e funcional formal.
- Estruturas base copiadas/reutilizadas da primeira entrega.
- Campos de peso validados com funcional antes de ativacao final (NUMC(5) x NUMC(6)).

### 6.4 Controle de numeracao ORDERNUM

- Verificacao obrigatoria: `zclq2c_265_descarga_granel` deve usar `ZTBQ2C_CTRL_PCS` para controle de numeracao compartilhado Carga/Descarga.
- Estado observado no codigo atual: nao ha referencia a `ZTBQ2C_CTRL_PCS` no objeto.
- Tratamento recomendado: abrir ajuste pontual para adotar a tabela de controle compartilhada, sem reescrever o pipeline.

## 7. O que nao fazer

- Nao iniciar por criar Data Element/estrutura do zero.
- Nao refatorar classe/pipeline por preferencia tecnica.
- Nao criar objetos duplicados do fluxo M06 em paralelo ao pipeline do GAP 265.
- Nao alterar logica ja estavel fora do delta minimo de Descarga.

## 8. Checklist final

- [ ] Baseline da primeira entrega identificado e usado como fonte de copia.
- [ ] Data Elements e estrutura reaproveitados/copiados, sem criacao do zero.
- [ ] Tabelas da Descarga derivadas por copia adaptada do modelo da Carga.
- [ ] Classes, job e runners implementados por copia + delta minimo.
- [ ] APJ/TVARVC alinhados ao padrao da primeira entrega.
- [ ] Validacao de sintaxe/ativacao sem erros.
- [ ] Teste minimo de sucesso e erro executado.
- [ ] Rastreabilidade de ajustes mantida nos comentarios tecnicos.
- [ ] Author padrao do pacote mantido como RTiezzi.
