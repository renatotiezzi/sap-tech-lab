# Refatoração Descarga GAP 265 — Instruções para o Copilot

## Contexto

O pacote de Carga `ZPQ2C_265_20260703_082358` (`zclq2c_265_carga_granel`, `zclq2c_265_carga_ret_granel`, `zclq2c_265_job`, `zrq2c_carga_ret_granel`) é o padrão técnico de referência do GAP 265.

O desenvolvimento de Descarga (pastas `Gap 265/outbound`, `Gap 265/inbound`, `Gap 265/objetos_comuns`) deve seguir **exatamente** essa arquitetura, com apenas layout/regras de negócio diferentes. A EF de referência é `EF_GAP_265_DESCARGA.md` na raiz do repositório.

Não criar arquitetura nova. Não inventar origem de dado. Não usar comentário de versão `V6 - RTIEZZI` (este é código novo, não ajuste evolutivo — a EF proíbe explicitamente esse padrão aqui).

---

## Ajuste 1 — Criar Data Elements para os layouts de Descarga

**Arquivos:**
- `Gap 265/outbound/zclq2c_265_descarga_granel.clas.abap` (`ty_u200_h`, `ty_u200_s`)
- `Gap 265/inbound/zclq2c_265_desc_ret_granel.clas.abap` (`ty_u301_h`, `ty_u301_s`)
- Novos `.dtel.xml` em `Gap 265/objetos_comuns/` (campos compartilhados entre envio e retorno, ex. `ordernum`) ou na pasta específica do fluxo.

**O que fazer:**
- Substituir todo campo `TYPE string` das quatro estruturas por um Data Element dedicado, seguindo o padrão de nome `zdeq2c_265_desc_<campo>` já usado na Carga (`zdeq2c_265_*`).
- Reaproveitar Data Element já existente da Carga quando o campo for semanticamente idêntico (ex.: `truckid` → `zdeq2c_265_truck_id`; `prodnum`/`prodname`/`prodden` → equivalentes da Carga).
- Não alterar o layout de campos (ordem/quantidade) definido na EF — apenas o tipo de dado.

**Critério de aceite:** nenhuma estrutura de `U200-H`, `U200-S`, `U301-H`, `U301-S` usa `TYPE string` para campo de negócio.

---

## Ajuste 2 — Implementar o pipeline completo de retorno (inbound)

**Arquivo:** `Gap 265/inbound/zclq2c_265_desc_ret_granel.clas.abap`

**O que fazer, espelhando `zclq2c_265_carga_ret_granel`:**
- `get_directory_files`: apenas listar e filtrar arquivos (prefixo `U301` e `size > 0`), sem chamar `process_single_file` dentro do próprio método — mover o loop de processamento para `execute`, igual à Carga.
- `read_u301_h_file` / `read_u301_s_file`: implementar `SPLIT gv_raw_line AT ';' INTO ...` populando os campos da estrutura (`ty_u301_h` / `ty_u301_s`) igual a `read_l300_h_file`/`read_l301_c_file`/`read_l301_h_file`.
- Criar um método `valida_arquivos` (ou equivalente) que valide a consistência entre `U301-H` e `U301-S` pelo mesmo `ORDERNUM`, e que o `ORDERNUM` exista no SAP (consultar tabela/CDS oficial da Ordem de Descarga).
- `update_retorno`: gravar em tabela Z de destino via `UPDATE ... FROM TABLE` (ou `MODIFY`), de forma idempotente — mesmo `ORDERNUM` atualiza header e substitui lacres anteriores (não duplica), seguido de `CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true`.
- `update_historico`: atualizar status/histórico da Ordem de Descarga (criar helper equivalente a `zclq2c_status_granel` se necessário, ex. `zclq2c_status_descarga`).
- `display_file_summary`: implementar resumo via `WRITE`, igual ao formato de `display_file_summary` da Carga, usando a mensagem `099` já definida em `ZCL_Q2C_265_MSG_DG` ("Job Descarga concluído: &1 OK / &2 erro(s)").
- Adicionar chamada de `display_main_header` (novo método) no início de `execute`, condicionada a `mv_job = abap_true`, igual ao padrão de `display_main_header` da Carga.

**Critério de aceite:** um arquivo `U301-H`/`U301-S` de teste é lido, parseado, validado por `ORDERNUM`, e grava registro em tabela Z real; reprocessar o mesmo arquivo não duplica lacres.

---

## Ajuste 3 — Criar tabelas Z de persistência e log técnico

**Arquivos:** novos `.tabl.xml` em `Gap 265/inbound/` ou `Gap 265/objetos_comuns/`.

**O que fazer:**
- Confirmar antes se `ZDESCARGA_INTERFACE_PCS` já existe no ambiente (conforme a EF instrui). Se não existir:
  - Criar `ZDESCARGA_INTERFACE_PCS` (header do retorno) e `ZDESCARGA_INTERFACE_PCS_I` (lacres/itens), no mesmo espírito de `zstq2c_ret_granel_l301_h` da Carga.
  - Criar uma tabela de log técnico equivalente a `ZTBQ2C_RETGRALOG` (ex. `ZTBQ2C_DESCGRALOG`), com os mesmos campos de propósito (id interface, tipo, status, mensagem).
- Implementar um método `update_log` em `zclq2c_265_desc_ret_granel`, espelhando `update_log` da Carga, chamado a partir de `execute`.

**Critério de aceite:** existe tabela de destino para header + lacres do retorno, e uma tabela de log técnico específica da Descarga sendo gravada a cada execução.

---

## Ajuste 4 — Reforçar validação de campos obrigatórios do envio (`U200-H`)

**Arquivo:** `Gap 265/outbound/zclq2c_265_descarga_granel.clas.abap` (`validate_order`)

**O que fazer:**
- Reescrever `validate_order` usando o mesmo padrão dinâmico de `validate_l200_h`/`validate_l200_c` da Carga (`DATA lt_fields TYPE STANDARD TABLE OF string`, `ASSIGN COMPONENT lv_field OF STRUCTURE cs_u200_h TO <fs>`, uma mensagem de erro por campo ausente).
- Cobrir, no mínimo, os campos exigidos pela EF: `desttank`, `prodnum`, `unloadln`, `unloadpt`, `truckid`, `invoqtyl`, `invoqtykg`, além de validações funcionais adicionais (Ordem no status correto, NF-e vinculada, DU aprovado quando aplicável, lacres informados).

**Critério de aceite:** cada campo obrigatório ausente gera uma mensagem individual via `zclq2c_265_desc_common=>add_error`; nenhum arquivo é gravado se houver campo obrigatório vazio ou Ordem fora do status correto.

---

## Ajuste 5 — Implementar busca real de dados da Ordem de Descarga

**Arquivo:** `Gap 265/outbound/zclq2c_265_descarga_granel.clas.abap` (`load_order_data`)

**O que fazer:**
- Substituir a implementação atual (que apenas ecoa `iv_ordernum` em `invoicen`/`msgrcvtm`) por busca real dos ~20 campos do `U200-H` (ver tabela "Layout U200-H" da EF), a partir da fonte oficial (APP 340 / tabela `ZDESCARGA` / objetos já entregues do processo).
- Se a decisão de arquitetura for que o chamador (APP 340) já monta a estrutura antes de chamar a classe (como faz `zclq2c_265_carga_granel->init`, que recebe `is_l200_h`/`it_l200_c` prontos), ajustar a assinatura de `execute` para receber `is_u200_h`/`it_u200_s` como `IMPORTING`, em vez de `iv_ordernum` sozinho — confirmar essa decisão com o time funcional antes de implementar.

**Critério de aceite:** os campos do `U200-H` gerado refletem dado real de uma Ordem de Descarga, não apenas o `ORDERNUM` repetido.

---

## Ajuste 6 — Corrigir cancelamento (`cancel_order`)

**Arquivo:** `Gap 265/outbound/zclq2c_265_descarga_granel.clas.abap` (`cancel_order`)

**O que fazer:**
- Adicionar validação de status da Ordem antes de gravar o arquivo: só permitir cancelamento quando a Ordem estiver no status `03 - TANQUE SELECIONADO`; caso contrário, retornar erro via `zclq2c_265_desc_common=>add_error` e não gravar arquivo.
- Corrigir o nome do arquivo gerado para `U201_{ordernum}` (sem sufixo de timestamp), conforme `U201_%numeroOrdemCarregamento%` definido na EF.
- Manter o conteúdo do arquivo como apenas o `ORDER NUMBER`, já implementado corretamente.

**Critério de aceite:** tentativa de cancelamento com Ordem fora do status `03` gera erro e não grava arquivo; nome do arquivo gerado bate exatamente com `U201_{ordernum}`.

---

## Ajuste 7 — Adicionar cabeçalho técnico padrão em todos os objetos novos

**Arquivos:** todos os `.clas.abap` e `.prog.abap` em `Gap 265/inbound/`, `Gap 265/outbound/`, `Gap 265/objetos_comuns/`.

**O que fazer:**
- Adicionar, no topo de cada classe/programa, o mesmo bloco de identificação usado na Carga:
  ```
  *&---------------------------------------------------------------------*
  * Object Name    : <nome do objeto>
  * Object Title   : <título funcional>
  * WRICEF ID      : <ID da EF correspondente, ex. Q2C265I004>
  * Author         : <autor>
  * Date           : <data>
  *-----------------------------------------------------------------------*
  ```
- **Não** usar a tag `V6 - RTIEZZI` — a EF proíbe esse padrão para desenvolvimento novo.
- Comentários de bloco funcional (ex. `" Monta header U200-H conforme layout PCS da Descarga`) podem ser mantidos como estão.

**Critério de aceite:** todo objeto novo da Descarga tem o bloco de identificação técnica no topo, sem a tag `V6 - RTIEZZI`.

---

## Ajuste 8 — Padronizar leitura de TVARVC

**Arquivo:** `Gap 265/objetos_comuns/zclq2c_265_desc_common.clas.abap` (`get_tvarvc_value`)

**O que fazer:**
- Avaliar substituir o `SELECT SINGLE ... FROM zz1_tvarvc_q2c` por uso de `zcl_tvarvc_range->get_range_for_name`, igual ao padrão usado em `zclq2c_265_carga_ret_granel->load_stvarv_values`.
- Se a tabela `zz1_tvarvc_q2c` for de fato a fonte correta (diferente de `tvarvc` padrão), manter o `SELECT` mas documentar a decisão no cabeçalho do método.

**Critério de aceite:** leitura de parâmetro técnico segue um único padrão consistente com o restante do GAP 265, com decisão documentada caso divirja do helper `zcl_tvarvc_range`.
