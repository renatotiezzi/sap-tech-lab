# Double Check Técnico — GAP 265

## 1. Resumo executivo

**Classificação: Parcialmente aderente.**

A estrutura de pastas, o desenho de classes (outbound/inbound/comum), a nomenclatura de alto nível (`zclq2c_265_descarga_granel`, `zclq2c_265_desc_ret_granel`, `zrq2c_descarga_granel`, `zrq2c_desc_ret_granel`) e a existência de uma message class dedicada (`ZCL_Q2C_265_MSG_DG`) seguem o direcionamento da Carga.

Porém, no nível de implementação a Descarga diverge da Carga em pontos relevantes:

- o fluxo de **Retorno (inbound)** está praticamente todo stubado — `process_single_file`, `read_u301_h_file`, `read_u301_s_file`, `update_retorno`, `update_historico`, `display_file_summary` não fazem parse, validação nem persistência real;
- não existem **Data Elements (DDIC)** para os campos de Descarga (Carga tem `zdeq2c_265_*.dtel.xml` para cada campo; Descarga usa `TYPE string` cru em tudo);
- não existe **tabela Z de persistência** (`ZDESCARGA_INTERFACE_PCS` ou equivalente) nem **tabela de log técnico** (equivalente a `ZTBQ2C_RETGRALOG`);
- a **validação de campos obrigatórios** do envio (U200-H) é muito mais fraca que a validação dinâmica por lista de campos usada na Carga;
- o **cancelamento (U201)** não valida o status da Ordem (exigência explícita da EF) e o nome do arquivo gerado não segue exatamente o padrão definido na EF;
- falta o **cabeçalho técnico padrão** (bloco Object Name/Title/WRICEF/Author/Date) presente em 100% dos métodos da Carga.

Em resumo: a "casca" arquitetural está aderente, mas o **conteúdo funcional do retorno (Escopo 2 da EF) ainda não foi implementado**, e há lacunas de DDIC/persistência que precisam ser resolvidas antes de considerar o desenvolvimento pronto.

---

## 2. Padrão identificado na carga

- **Estrutura**: separação por classe de responsabilidade única — outbound (`zclq2c_265_carga_granel`), inbound/retorno (`zclq2c_265_carga_ret_granel`), job/APJ (`zclq2c_265_job`), runner SE38 (`zrq2c_carga_ret_granel`).
- **Nomenclatura**: prefixo técnico `zq2c_265` / `zdeq2c_265` / `zclq2c_265`; layouts mapeados por sufixo (`L200_H`, `L200_C`, `L300_H`, `L301_C`, `L301_H`); chave funcional `shnumber` presente em quase todas as estruturas.
- **Organização técnica**: cada campo de negócio tem um **Data Element dedicado** (`zdeq2c_265_*.dtel.xml`); tabelas de negócio e log são objetos DDIC próprios (`ztq2c_pcs_det`, `ztbq2c_retgralog`, `zstq2c_ret_granel_l301_h`).
- **Logs**: método `display_main_header` (cabeçalho de execução via `WRITE`, só quando `gv_job = abap_true`) + `display_file_summary` (tabela-resumo via `WRITE` com colunas fixas) + tabela de log técnico `ZTBQ2C_RETGRALOG` (gravada por `update_log`, hoje comentada no fluxo principal, mas existente).
- **Mensagens**: message class dedicada por fluxo (`ZCL_Q2C_265_MSG_CG`), com número + texto T100; no retorno, `TEXT-nnn` (text elements do programa) para mensagens funcionais, agregadas numa tabela `tt_message` com `shnumber`, `id`, `number`, `type`, `severity`, `v1..v4`.
- **Validações**: validação dinâmica por lista de campos obrigatórios (`ASSIGN COMPONENT ... loop at lt_fields`), gerando uma mensagem por campo ausente; validação cruzada de arquivos equivalentes (`valida_arquivos`, cruzando `L300_H`/`L301_C`/`L301_H` pelo `shnumber`).
- **Tratamento de erro**: `error_handling` centralizado, populando mensagens de sucesso/erro por chave de negócio; nunca grava dado parcial (checa flags de equivalência antes de atualizar).
- **Objetos comuns**: `zcl_tvarvc_range` (helper de leitura de TVARVC por range) e `zclq2c_status_granel` (helper de status/histórico), reutilizados entre os fluxos.
- **Persistência/commit**: `UPDATE ... FROM TABLE` em massa + `BAPI_TRANSACTION_COMMIT EXPORTING wait = abap_true` explícito logo após o update de negócio.
- **Comentário técnico**: bloco de cabeçalho padronizado repetido em **todo método**:
  ```
  *&---------------------------------------------------------------------*
  *& Report ZRQ2C_CARGA_RET_GRANEL
  *&---------------------------------------------------------------------*
  *************************************************************************
  * Object Name    : ...
  * Object Title   : ...
  * WRICEF ID      : ...
  * Author         : ...
  * Date           : ...
  *-----------------------------------------------------------------------*
  ```

---

## 3. Validação da descarga

| Item | Carga | Descarga | Status | Observação |
|---|---|---|---|---|
| Separação de classes (outbound/inbound/job/runner) | `zclq2c_265_carga_granel`, `zclq2c_265_carga_ret_granel`, `zclq2c_265_job`, `zrq2c_carga_ret_granel` | `zclq2c_265_descarga_granel`, `zclq2c_265_desc_ret_granel`, `zclq2c_265_desc_job`, `zrq2c_descarga_granel`, `zrq2c_desc_ret_granel` | OK | Estrutura de classes replicada corretamente. |
| Message class dedicada | `ZCL_Q2C_265_MSG_CG` | `ZCL_Q2C_265_MSG_DG` | OK | Existe e é referenciada via `zclq2c_265_desc_common=>gc_msgid`. |
| Helper de mensagens centralizado | Cada classe monta `APPEND VALUE #( ... ) TO ct_msg` inline | `zclq2c_265_desc_common=>add_error` / `add_success` | Parcial | Não é uma regressão (é melhoria), mas é um padrão **novo**, não existente na Carga — deveria estar documentado como decisão de arquitetura, não como "reuso". |
| Leitura de TVARVC | `zcl_tvarvc_range` (retorno) / `SELECT` direto em `zz1_tvarvc_q2c` (outbound) | `SELECT SINGLE` direto em `zz1_tvarvc_q2c` (`get_tvarvc_value`) | Parcial | Segue o padrão do outbound da Carga, mas **não** segue o padrão documentado como referência oficial (`zcl_tvarvc_range`) usado no retorno, que é justamente a classe espelhada (`carga_ret_granel` → `desc_ret_granel`). |
| Data Elements por campo (DDIC) | `zdeq2c_265_*.dtel.xml` para cada campo do layout | Nenhum — todos os campos de `ty_u200_h`, `ty_u200_s`, `ty_u301_h`, `ty_u301_s` são `TYPE string` | NOK | Perda de tipagem, F1, tamanho de campo e padronização DDIC. |
| Listagem de diretório (inbound) | `get_directory_files` só lista e filtra (`name(3) = 'L30'`, `size > 0`); loop de processamento fica em `execute` | `get_directory_files` já chama `process_single_file` dentro do loop, sem filtro de prefixo/tamanho | Parcial | Mistura responsabilidade de listar com processar; diverge do pipeline documentado em `ESTRUTURA_GAP_265.md`. |
| Parse de arquivo (inbound) | `read_l300_h_file` / `read_l301_c_file` / `read_l301_h_file` fazem `SPLIT ... AT ';'` populando estrutura real | `read_u301_h_file` / `read_u301_s_file` são métodos vazios (só comentário) | NOK | Nenhum parse de `U301-H`/`U301-S` implementado. |
| Validação cruzada de arquivos | `valida_arquivos` cruza `L300_H`/`L301_C`/`L301_H` por `shnumber` | Não existe validação equivalente para `ORDERNUM` entre `U301-H`/`U301-S` | NOK | Requisito explícito da EF ("validar consistencia do arquivo e do ORDERNUM") não atendido. |
| Carga de dados de apoio | `load_data` busca `ztq2c_pcs_det`, `oigsvcc`, valida existência do `shnumber`, calcula status via `zclq2c_status_granel` | Não existe método equivalente | NOK | Sem validação de `ORDERNUM` existente no SAP (exigida pela EF). |
| Persistência do retorno | `update_retorno` grava em `ztq2c_pcs_det` com `UPDATE ... FROM TABLE` + `BAPI_TRANSACTION_COMMIT` | `update_retorno` é método vazio | NOK | Nenhuma tabela Z de destino existe no pacote (`ZDESCARGA_INTERFACE_PCS` não localizada). |
| Atualização de histórico/status | `update_historico` usa `zclq2c_status_granel->set_status_moni_proc` | `update_historico` é método vazio | NOK | Sem helper de status equivalente para Descarga. |
| Log técnico dedicado | `ZTBQ2C_RETGRALOG` + método `update_log` (existente, hoje comentado no fluxo) | Nenhuma tabela de log e nenhum método `update_log` | NOK | Não há objeto de log técnico para Descarga. |
| Cabeçalho de execução (job) | `display_main_header` com `WRITE` condicionado a `gv_job` | Não existe nenhum método/chamada equivalente | NOK | Etapa 2 do pipeline documentado ("exibir header da execução") não implementada. |
| Resumo de execução (job) | `display_file_summary` monta tabela `WRITE` com colunas fixas | Método existe mas vazio (só comentário) | NOK | Mensagem `099` da message class ("Job Descarga concluído: &1 OK / &2 erro(s)") nunca é usada em lugar nenhum. |
| Validação de campos obrigatórios do envio | `validate_l200_h` / `validate_l200_c` — loop dinâmico por lista de ~14 campos, 1 mensagem por campo | `validate_order` — checa **apenas** `ordernum` | NOK | EF lista ~13 validações funcionais obrigatórias (tanque, linha, plataforma, produto, qty NF-e, peso NF-e, placa cavalo, placa carreta, lacres, DU aprovado etc.) — nenhuma implementada. |
| Origem dos dados do envio | `init` recebe `is_l200_h`/`it_l200_c` já montados pelo chamador (não faz SELECT interno) | `load_order_data` monta a estrutura internamente, mas hoje só ecoa `iv_ordernum` em `invoicen`/`msgrcvtm` — não busca dado real | NOK | Diverge do padrão de contrato da Carga (receber dado já resolvido) e não implementa a busca real dos ~20 campos do `U200-H`. |
| Cancelamento (U201) — nome de arquivo | N/A (não existe na Carga) | `U201_{ordernum}_{timestamp}.TXT` | Parcial | EF pede exatamente `U201_%numeroOrdemCarregamento%`, sem timestamp. |
| Cancelamento (U201) — validação de status | N/A | Nenhuma validação de status antes de gravar o arquivo | NOK | EF exige permitir cancelamento **apenas** quando a Ordem estiver no status `03 - TANQUE SELECIONADO`. |
| Cabeçalho técnico por método (Object Name/Title/WRICEF/Author/Date) | Presente em 100% dos métodos | Ausente em todos os métodos | Parcial | Ver seção 8 sobre o comentário `V6 - RTIEZZI` (não aplicável aqui, mas o bloco de identificação do objeto é um padrão à parte, sempre presente na Carga). |
| Runner manual (SE38) | Parâmetros com `TEXT-s01`, folder default hardcoded, shnumber, com_number, job | Parâmetros `p_ordnum` + `p_job` | OK | Adequado ao escopo (Descarga não precisa de `folder`/`com_number` de entrada manual). |
| Commit transacional | `BAPI_TRANSACTION_COMMIT wait = abap_true` explícito após update | Não se aplica ainda (não há update implementado) | Não localizado | Depende da implementação de `update_retorno`. |

---

## 4. Aderência à EF/ET

A EF (`EF_GAP_265_DESCARGA.md`) existe e está bem detalhada (layouts `U200-H`/`U200-S`/`U301-H`/`U301-S`, regras de validação, TVARVC sugeridas, regras de cancelamento). Portanto, **a EF não está ausente**, mas o desenvolvimento atual não cobre boa parte dela:

- **Escopo 1 (Envio)**: parcialmente atendido — arquivos são gerados no formato certo (`;` delimitado, CRLF, nome de arquivo conforme EF), mas **as validações funcionais obrigatórias da EF não estão implementadas** e a origem dos ~20 campos do `U200-H` não foi resolvida contra o APP 340 / tabela `ZDESCARGA` (está tudo hardcoded/placeholder em `load_order_data`).
- **Escopo 2 (Retorno)**: **não atendido** — parse de `U301-H`/`U301-S`, validação de `ORDERNUM`, persistência em tabela Z e idempotência (substituir lacres, não duplicar) são requisitos explícitos da EF e nenhum foi implementado.
- **Escopo 3 (Cancelamento)**: parcialmente atendido — arquivo é gerado, mas **falta a validação de status `03 - TANQUE SELECIONADO`** exigida pela EF, e o nome do arquivo tem um sufixo de timestamp que a EF não pede.
- **Persistência (`ZDESCARGA_INTERFACE_PCS`)**: a EF pede para validar se a tabela já existe antes de criar DDIC novo — **não há evidência no repositório de que essa validação foi feita**, nem a tabela nem uma equivalente foram criadas.
- **Comentários (`V6 - RTIEZZI`)**: a EF é explícita em **não usar** esse padrão de comentário de versão para este desenvolvimento novo. Isso está sendo respeitado no código atual (não há ocorrências). **Atenção**: o critério de aceite genérico no final deste double-check pede "comentários técnicos no padrão V6 - RTIEZZI quando houver alteração" — como não há alteração de objeto pré-existente aqui (é código novo), a **EF prevalece** e esse padrão não deve ser aplicado neste GAP.

---

## 5. Pontos fora do padrão

### Ponto 1 — Ausência de Data Elements (DDIC) para os campos de Descarga

**Arquivo/objeto:**
`outbound/zclq2c_265_descarga_granel.clas.abap` (`ty_u200_h`, `ty_u200_s`) e `inbound/zclq2c_265_desc_ret_granel.clas.abap` (`ty_u301_h`, `ty_u301_s`).

**Problema:**
Todos os campos das quatro estruturas são declarados como `TYPE string`. A Carga criou um Data Element dedicado por campo (`zdeq2c_265_order_num`, `zdeq2c_265_load_qty`, etc.).

**Impacto:**
Perda de padronização DDIC, sem tamanho/domínio controlado, sem texto de campo (F1), maior risco de erro de layout (tamanho de campo incorreto no arquivo gerado para o PCS) e inconsistência de arquitetura dentro do mesmo GAP.

**Ajuste recomendado:**
Criar Data Elements `zdeq2c_265_desc_*` (ou reaproveitar os já existentes da Carga quando o campo for semanticamente igual, ex. `truckid`, `prodnum`, `prodname`, `prodden`) e trocar os `TYPE string` pelos data elements correspondentes.

---

### Ponto 2 — Pipeline de retorno (inbound) não implementado

**Arquivo/objeto:**
`inbound/zclq2c_265_desc_ret_granel.clas.abap`

**Problema:**
`process_single_file`, `read_u301_h_file`, `read_u301_s_file`, `update_retorno`, `update_historico` e `display_file_summary` estão vazios (apenas comentário). `get_directory_files` já chama `process_single_file` sem filtrar por prefixo/tamanho, misturando responsabilidade de listar e processar.

**Impacto:**
O fluxo de Retorno da Descarga (Escopo 2 da EF) está funcionalmente inoperante — nenhum dado do PCS é lido, validado ou persistido. É o ponto de maior risco do desenvolvimento.

**Ajuste recomendado:**
Replicar o pipeline de `zclq2c_265_carga_ret_granel` (leitura via `SPLIT ... AT ';'`, validação cruzada `U301-H`/`U301-S` por `ORDERNUM`, persistência idempotente e commit explícito), adaptando apenas layout e tabela de destino.

---

### Ponto 3 — Persistência e log técnico inexistentes

**Arquivo/objeto:**
`inbound/zclq2c_265_desc_ret_granel.clas.abap`, ausência de `.tabl.xml` em todo o diretório `Gap 265` para o fluxo de Descarga.

**Problema:**
Não existe tabela Z de destino (`ZDESCARGA_INTERFACE_PCS` ou equivalente) nem tabela de log técnico (equivalente a `ZTBQ2C_RETGRALOG`). `update_retorno` e `update_historico` estão vazios; não há método `update_log`.

**Impacto:**
Sem tabela de persistência, o retorno da Descarga não pode ser gravado; sem log técnico, não há rastreabilidade de arquivo processado/erro para suporte/monitoria.

**Ajuste recomendado:**
Confirmar com o time funcional/DBA se `ZDESCARGA_INTERFACE_PCS` já existe no ambiente (conforme a própria EF pede). Se não existir, criar `ZDESCARGA_INTERFACE_PCS` (header) e `ZDESCARGA_INTERFACE_PCS_I` (lacres), mais uma tabela de log técnico equivalente a `ZTBQ2C_RETGRALOG`, e implementar `update_retorno`/`update_historico`/`update_log` seguindo o padrão de commit da Carga.

---

### Ponto 4 — Validação de campos obrigatórios do envio muito mais fraca que a Carga

**Arquivo/objeto:**
`outbound/zclq2c_265_descarga_granel.clas.abap` (`validate_order`)

**Problema:**
`validate_order` verifica apenas `ordernum`. A Carga usa um loop dinâmico (`ASSIGN COMPONENT ... loop at lt_fields`) validando ~14 campos obrigatórios do header. A EF lista explicitamente ~13 validações funcionais (tanque, linha, plataforma, produto, quantidade NF-e, peso NF-e, placa cavalo, placa carreta, lacres, aprovação do DU etc.) que não estão implementadas.

**Impacto:**
Risco de gerar arquivo para o PCS com campos obrigatórios vazios, quebrando o processamento físico da descarga no pátio.

**Ajuste recomendado:**
Reescrever `validate_order` no mesmo estilo de `validate_l200_h`/`validate_l200_c` (lista de campos + loop dinâmico), cobrindo todos os campos obrigatórios do `U200-H` e as validações funcionais da EF (status da Ordem, DU aprovado, NF-e vinculada, etc.).

---

### Ponto 5 — Origem dos dados do envio não implementada (`load_order_data` é placeholder)

**Arquivo/objeto:**
`outbound/zclq2c_265_descarga_granel.clas.abap` (`load_order_data`)

**Problema:**
O método apenas ecoa `iv_ordernum` para dentro de `invoicen` e `msgrcvtm`; nenhum dos outros ~18 campos do `U200-H` é buscado de fato. Além disso, o contrato diverge do padrão da Carga: `zclq2c_265_carga_granel->init` recebe a estrutura **já montada** pelo chamador (`is_l200_h`/`it_l200_c`), enquanto a Descarga tenta montar a estrutura internamente a partir de um `ORDERNUM` solto, sem indicar de onde vêm os dados (APP 340 / tabela `ZDESCARGA`).

**Impacto:**
O arquivo `U200-H` gerado hoje não reflete dados reais de Ordem de Descarga — geraria arquivo inválido para o PCS em produção.

**Ajuste recomendado:**
Definir com o funcional/APP 340 se o contrato correto é (a) receber a estrutura já montada pelo chamador, espelhando `init` da Carga, ou (b) buscar por `ORDERNUM` numa tabela/CDS oficial do processo de Descarga — e então implementar a busca real dos campos listados na EF (seção "Layout U200-H").

---

### Ponto 6 — Cancelamento (U201) sem validação de status e com nome de arquivo fora do padrão da EF

**Arquivo/objeto:**
`outbound/zclq2c_265_descarga_granel.clas.abap` (`cancel_order`)

**Problema:**
Não há nenhuma checagem de status da Ordem antes de gravar o arquivo de cancelamento. O nome gerado é `U201_{ordernum}_{timestamp}.TXT`, mas a EF pede exatamente `U201_%numeroOrdemCarregamento%` (sem timestamp).

**Impacto:**
Permite cancelar uma Ordem em qualquer status (violando a regra de negócio "só status 03 - TANQUE SELECIONADO"), e o nome de arquivo fora do padrão pode quebrar o processamento do lado do PCS, que espera o nome exato definido na EF.

**Ajuste recomendado:**
Adicionar validação de status (`03 - TANQUE SELECIONADO`) antes de `save_file`, retornando erro caso a Ordem esteja em outro status; remover o sufixo de timestamp do nome do arquivo, mantendo exatamente `U201_{ordernum}.TXT` (ou o nome definido pela EF, sem extensão adicional se não especificado).

---

### Ponto 7 — Ausência do cabeçalho técnico padrão por método/objeto

**Arquivo/objeto:**
Todos os arquivos em `inbound/`, `outbound/` e `objetos_comuns/`.

**Problema:**
A Carga tem, em 100% dos métodos e no topo de cada classe/programa, um bloco de identificação técnica (Object Name, Object Title, WRICEF ID, Author, Date). Nenhum arquivo da Descarga tem esse bloco.

**Impacto:**
Perda de rastreabilidade técnica (WRICEF, autor, data) e inconsistência de padrão documental dentro do mesmo GAP — dificulta suporte e auditoria futura.

**Ajuste recomendado:**
Adicionar o bloco de cabeçalho padrão (Object Name/Title/WRICEF ID/Author/Date) no topo de cada classe e programa da Descarga, no mesmo formato usado na Carga — **sem** usar a tag de versão `V6 - RTIEZZI` (a EF proíbe esse padrão específico para desenvolvimento novo).

---

### Ponto 8 — Leitura de TVARVC não usa o helper de referência (`zcl_tvarvc_range`)

**Arquivo/objeto:**
`objetos_comuns/zclq2c_265_desc_common.clas.abap` (`get_tvarvc_value`)

**Problema:**
O método faz `SELECT SINGLE` direto em `zz1_tvarvc_q2c`, sem usar `zcl_tvarvc_range`, que é o helper apontado como padrão de referência para TVARVC no `ESTRUTURA_GAP_265.md` (usado no retorno da Carga, o fluxo espelhado por `desc_ret_granel`).

**Impacto:**
Duas formas diferentes de ler o mesmo tipo de parâmetro técnico dentro do mesmo GAP; perde a validação de range (sign/option/low/high) que `zcl_tvarvc_range` oferece.

**Ajuste recomendado:**
Avaliar se `get_tvarvc_value` deveria delegar para `zcl_tvarvc_range` (retornando o `low` do primeiro range) em vez de fazer `SELECT` direto — mantendo compatibilidade com o padrão já estabelecido pelo retorno da Carga.

---

## 6. Recomendações para refatoração pelo Copilot

1. **Objetivo**: criar Data Elements para os campos de `U200-H`/`U200-S`/`U301-H`/`U301-S` e substituir os `TYPE string`.
   **Arquivos impactados**: `outbound/zclq2c_265_descarga_granel.clas.abap`, `inbound/zclq2c_265_desc_ret_granel.clas.abap`, novos `.dtel.xml` em `objetos_comuns/` (campos compartilhados) ou em cada pasta (campos exclusivos).
   **Regra técnica**: seguir o padrão `zdeq2c_265_*` já usado na Carga; reaproveitar data element existente quando o campo for semanticamente idêntico.
   **Critério de aceite**: nenhuma estrutura de layout usa `TYPE string` cru para campo de negócio.

2. **Objetivo**: implementar o pipeline completo de retorno (parse, validação cruzada por `ORDERNUM`, persistência idempotente, log, resumo).
   **Arquivos impactados**: `inbound/zclq2c_265_desc_ret_granel.clas.abap`.
   **Regra técnica**: espelhar `zclq2c_265_carga_ret_granel` (métodos `read_l300_h_file`/`read_l301_c_file`/`read_l301_h_file` → `read_u301_h_file`/`read_u301_s_file`; `valida_arquivos`; `load_data`; `update_retorno` com `UPDATE ... FROM TABLE` + `BAPI_TRANSACTION_COMMIT`).
   **Critério de aceite**: um arquivo `U301-H`/`U301-S` de teste é lido, validado, e gera registro em tabela Z real, de forma idempotente (reprocessar não duplica).

3. **Objetivo**: criar tabela(s) Z de persistência e de log técnico.
   **Arquivos impactados**: novos `.tabl.xml` (ex.: `zdescarga_interface_pcs`, `zdescarga_interface_pcs_i`, tabela de log técnico equivalente a `ZTBQ2C_RETGRALOG`).
   **Regra técnica**: antes de criar, confirmar se `ZDESCARGA_INTERFACE_PCS` já existe no ambiente (conforme a EF instrui); não duplicar.
   **Critério de aceite**: existe tabela de destino para header + lacres do retorno e tabela de log técnico específica da Descarga.

4. **Objetivo**: reforçar validação de campos obrigatórios do envio (`U200-H`).
   **Arquivos impactados**: `outbound/zclq2c_265_descarga_granel.clas.abap` (`validate_order`).
   **Regra técnica**: usar o mesmo padrão dinâmico (`ASSIGN COMPONENT` + loop de lista de campos) de `validate_l200_h`/`validate_l200_c`, cobrindo todos os campos citados na EF.
   **Critério de aceite**: cada campo obrigatório ausente gera uma mensagem individual; nenhum arquivo é gravado se houver campo obrigatório vazio.

5. **Objetivo**: implementar a busca real de dados da Ordem de Descarga para montar `U200-H`/`U200-S`.
   **Arquivos impactados**: `outbound/zclq2c_265_descarga_granel.clas.abap` (`load_order_data`).
   **Regra técnica**: confirmar fonte oficial (APP 340 / tabela `ZDESCARGA`) antes de implementar; não inventar origem de campo.
   **Critério de aceite**: os ~20 campos do `U200-H` são preenchidos com dado real, não com valor placeholder do `ORDERNUM`.

6. **Objetivo**: corrigir cancelamento (`cancel_order`) para validar status e usar o nome de arquivo exato da EF.
   **Arquivos impactados**: `outbound/zclq2c_265_descarga_granel.clas.abap` (`cancel_order`).
   **Regra técnica**: só permitir cancelamento com status `03 - TANQUE SELECIONADO`; nome de arquivo `U201_{ordernum}` sem timestamp.
   **Critério de aceite**: tentativa de cancelamento fora do status correto gera erro e não grava arquivo; nome do arquivo gerado bate exatamente com o padrão da EF.

7. **Objetivo**: adicionar cabeçalho técnico padrão (Object Name/Title/WRICEF/Author/Date) em todas as classes/programas da Descarga.
   **Arquivos impactados**: todos os `.clas.abap` e `.prog.abap` em `inbound/`, `outbound/`, `objetos_comuns/`.
   **Regra técnica**: mesmo formato do cabeçalho da Carga, sem usar a tag `V6 - RTIEZZI`.
   **Critério de aceite**: todo objeto novo tem o bloco de identificação técnica no topo.

8. **Objetivo**: padronizar leitura de TVARVC via `zcl_tvarvc_range`.
   **Arquivos impactados**: `objetos_comuns/zclq2c_265_desc_common.clas.abap` (`get_tvarvc_value`).
   **Regra técnica**: usar `zcl_tvarvc_range->get_range_for_name`, igual ao retorno da Carga.
   **Critério de aceite**: `get_tvarvc_value` não faz mais `SELECT` direto em `zz1_tvarvc_q2c`.

---

## 7. Markdown final para o Copilot

Ver arquivo separado: [`COPILOT_REFACTOR_GAP_265.md`](COPILOT_REFACTOR_GAP_265.md)

---

## 8. Critérios de aceite final

A Descarga só deve ser considerada pronta se:

- [ ] seguir o mesmo padrão estrutural da Carga (classes, métodos, pipeline) — **parcialmente atendido hoje**;
- [ ] respeitar a EF/ET (`EF_GAP_265_DESCARGA.md`) — **não atendido integralmente hoje** (Escopo 2 e validações do Escopo 1/3 pendentes);
- [ ] não ter hardcode desnecessário (paths, nomes de arquivo fora do padrão da EF) — **pendente** (timestamp extra no U201; placeholders em `load_order_data`);
- [ ] usar text elements/message class para mensagens — **atendido estruturalmente**, mas mensagens `001`/`099` da message class estão definidas e nunca usadas (pipeline incompleto);
- [ ] ter logs e tratamento de erro compatíveis com a Carga — **não atendido** (sem tabela de log técnico, sem `display_main_header`/`display_file_summary` funcionais);
- [ ] não duplicar lógica comum sem necessidade — **atendido** (via `zclq2c_265_desc_common`);
- [ ] preservar o fluxo de carga existente — **atendido** (nenhum objeto da Carga foi alterado);
- [ ] ter comentários técnicos no padrão **V6 - RTIEZZI somente quando houver alteração de objeto já existente** — **não se aplica a este desenvolvimento novo**; a EF explicitamente instrui a **não** usar esse padrão aqui. Usar comentários simples de bloco, como já orientado na própria EF.
