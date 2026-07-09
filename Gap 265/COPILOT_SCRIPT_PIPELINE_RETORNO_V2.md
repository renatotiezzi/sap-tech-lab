# Script de Correção — Pipeline de Retorno Descarga (pós-renomeação de tabelas)

Este documento é só análise + instrução. Nada aqui foi aplicado — é para o Copilot executar.

Escopo analisado: `Gap 265/inbound/zclq2c_265_desc_ret_granel.clas.abap`, `zclq2c_265_desc_job.clas.abap`, `zclq2c_265_desc_common.clas.abap`, `outbound/zclq2c_265_descarga_granel.clas.abap`, `ztq2c_pcs_det_d.tabl.xml`, `ztq2c_pcs_itm_d.tabl.xml`, `IMPLEMENTATION_GUIDE.md` (estado atual "Copy-First").

O estado atual já resolveu vários pontos que eu tinha levantado antes (renomeação de tabela, chave de negócio SAP, nomes de campo CDS sem underscore, commit explícito em `update_historico`, `convert_weight` criado). O que segue são problemas **novos**, encontrados analisando o código como está agora.

---

## Parte 1 — Correções de programação (ABAP)

### 1.1 [CRÍTICO] Um erro em qualquer arquivo bloqueia a persistência do lote inteiro

**Onde:** `zclq2c_265_desc_ret_granel.clas.abap`, método `update_retorno`, linha do `IF line_exists( ct_msg[ type = 'E' ] ). RETURN. ENDIF.` (logo após montar `lt_hdr`/`lt_itm`).

**Problema:** esse `line_exists` verifica `ct_msg` **inteiro** — a mesma tabela de mensagens acumulada desde `load_tvarvc`, `process_single_file` e `valida_arquivos`. Se **qualquer** arquivo do lote tiver erro (ex.: um `ORDERNUM` de um arquivo não bate com `U301-S`, msg `037`), o `RETURN` aborta a gravação de **todos** os outros pedidos do lote, inclusive os que foram lidos e validados com sucesso e já estão montados em `lt_hdr`/`lt_itm`. Isso quebra o isolamento por chave que é o padrão estabelecido na Carga (nunca grava dado parcial, mas também nunca deixa um registro bom refém de um registro ruim de outro arquivo).

**Efeito prático:** um único arquivo malformado no AL11 impede a persistência de todo o lote a cada execução do job, até alguém remover/corrigir manualmente o arquivo problemático.

**Correção sugerida:** trocar a checagem global por isolamento por `ORDERNUM`. Em vez de `IF line_exists( ct_msg[ type = 'E' ] ). RETURN. ENDIF.`, filtrar `lt_hdr`/`lt_itm` removendo apenas as entradas cujo `ORDERNUM` tenha mensagem de erro associada (ex.: construir um `RANGE` de `ordernum`s com erro a partir de `ct_msg` — hoje `ct_msg-name` carrega o nome do arquivo, não o ordernum; ver achado 1.4 abaixo, que é pré-requisito para isso funcionar direito) e gravar normalmente o que sobrar.

---

### 1.2 [ALTO] `convert_weight` não protege contra o que deveria proteger

**Onde:** `zclq2c_265_desc_ret_granel.clas.abap`, `ty_u301_h` (campos `trkintwt`/`trkfnlwt` tipados como `zdeq2c_265_desc_trkintwt`/`_trkfnlwt`, ambos `NUMC`), método `read_u301_h_file` (o `SPLIT ... INTO ls_header-trkintwt ls_header-trkfnlwt ...`), e `update_historico` (`convert_weight( CONV string( ls_header-trkintwt ) )`).

**Problema:** o `SPLIT` em `read_u301_h_file` joga o texto bruto do arquivo **direto** num campo `NUMC`. Campo `NUMC` não tem como representar `,` ou `.` — então qualquer separador decimal que exista no arquivo real do PCS já se perde (ou quebra) nesse `SPLIT`, antes de `convert_weight` sequer rodar. Quando `update_historico` chama `convert_weight( CONV string( ls_header-trkintwt ) )`, está convertendo pra string um valor que **já passou** pelo `NUMC` — ou seja, o `REPLACE ALL OCCURRENCES OF ',' IN lv_normalized WITH '.'` dentro de `convert_weight` nunca vai achar uma vírgula pra substituir, porque ela já não existe mais naquele ponto. A blindagem de conversão de peso (criada pra resolver o achado anterior sobre peso com separador decimal) não protege o caminho real do dado — ela protege um valor que já saiu deformado do parsing.

**Correção sugerida:**
- Adicionar dois campos `string` em `ty_u301_h` para o valor bruto do peso, ex. `trkintwt_raw TYPE string` e `trkfnlwt_raw TYPE string`.
- Em `read_u301_h_file`, fazer o `SPLIT` **primeiro** para variáveis `string` (incluindo essas duas), e só depois preencher `ls_header-trkintwt`/`trkfnlwt` (os campos `NUMC`, usados para a cópia arquivada em `ztq2c_pcs_det_d`) a partir do valor bruto — dentro de um `TRY/CATCH` para não deixar a atribuição estourar se o conteúdo não for numérico puro.
- Em `update_historico`, chamar `convert_weight` passando `ls_header-trkintwt_raw`/`trkfnlwt_raw` (o texto original do arquivo), não `CONV string( ls_header-trkintwt )`.

---

### 1.3 [MÉDIO] `update_historico` não verifica se o `ORDERNUM` já falhou antes de tentar o `UPDATE`

**Onde:** `zclq2c_265_desc_ret_granel.clas.abap`, método `update_historico`.

**Problema:** o método roda `LOOP AT gt_u301_h` e tenta `UPDATE ztbq2c_descarga ... WHERE pcs_ordernum = ls_header-ordernum` para **toda** linha, mesmo pra `ORDERNUM`s que `valida_arquivos`/`update_retorno` já sinalizaram como não encontrados em `zi_q2c_descarga` (msg `036`). Hoje isso não quebra nada visivelmente (o `UPDATE` só não casa linha nenhuma e segue em silêncio), mas é inconsistente com `update_retorno`, que trata erro de forma **agressiva demais** (achado 1.1) enquanto `update_historico` trata erro de forma **nenhuma**. As duas gravações do mesmo evento de negócio (`ztq2c_pcs_det_d`/`_itm_d` de um lado, `ztbq2c_descarga` do outro) deveriam ter exatamente o mesmo critério de "esse `ORDERNUM` está apto a ser gravado ou não".

**Correção sugerida:** aplicar o mesmo filtro por `ORDERNUM` do achado 1.1 aqui também — pular (`CONTINUE`) o `UPDATE` para qualquer `ordernum` que tenha mensagem de erro em `ct_msg`, usando a mesma lógica de filtro proposta em 1.1/1.4.

---

### 1.4 [BAIXO, mas é pré-requisito de 1.1 e 1.3] Mensagens de erro não carregam o `ORDERNUM` de forma pesquisável

**Onde:** `zclq2c_265_desc_common.clas.abap` (`ty_message`, `add_error`, `add_success`) e todos os pontos de chamada em `zclq2c_265_desc_ret_granel.clas.abap`.

**Problema:** `ty_message` tem um campo `ordernum TYPE zdeq2c_265_order_num`, mas nenhuma chamada a `add_error`/`add_success` no fluxo de retorno preenche esse campo — o `ORDERNUM` é passado solto em `iv_v1` (texto livre), não em um parâmetro dedicado. Isso tem dois efeitos:
- `display_file_summary` escreve a coluna `ls_msg-ordernum` (posição 30 do `WRITE`) sempre em branco — o resumo do job nunca mostra o número da ordem na coluna própria, mesmo ele estando disponível.
- Sem esse campo populado de forma confiável, não dá para filtrar `ct_msg` por `ordernum` (necessário pros achados 1.1 e 1.3) sem fazer parsing de texto livre em `v1`, que é frágil.

**Correção sugerida:** adicionar `iv_ordernum TYPE zdeq2c_265_order_num OPTIONAL` em `add_error`/`add_success`, preencher `ordernum = iv_ordernum` no `APPEND VALUE #( ... )`, e passar `iv_ordernum = ls_header-ordernum` (ou `ls_seal-sordrnm`) em toda chamada do fluxo de retorno que hoje só usa `iv_v1` pra isso. Isso desbloqueia um filtro limpo tipo `ct_msg[ ordernum = ls_header-ordernum type = 'E' ]` pros achados 1.1 e 1.3.

---

### 1.5 [BAIXO, nota] Parâmetro `ORDERNUM` do job nunca é usado

**Onde:** `zclq2c_265_desc_job.clas.abap`, método `if_apj_rt_exec_object~execute`.

**Problema:** o job lê `lv_ordernum` do parâmetro `ORDERNUM` da tela de seleção, mas nunca passa esse valor pra `zclq2c_265_desc_ret_granel->execute` — o job sempre processa o lote inteiro do diretório, ignorando o parâmetro. Não é necessariamente errado (a Carga também processa em lote), mas é um parâmetro de tela que engana quem for agendar o job esperando poder filtrar por ordem.

**Correção sugerida:** não é bloqueante. Se a intenção for permitir reprocessamento pontual de uma ordem específica, `execute` precisaria aceitar um `ORDERNUM` opcional e filtrar `gt_dir_files`/`gt_u301_h` por ele. Se a intenção é sempre processar o lote inteiro, remover o parâmetro `ORDERNUM` da definição do job (`if_apj_dt_exec_object~get_parameters`) pra não sugerir uma capacidade que não existe.

---

## Parte 2 — Instrução para o Copilot: criar `IMPLEMENTATION_GUIDE_V2.md`

**Não sou eu que crio esse arquivo — é uma instrução para o Copilot gerar.**

Pedido: criar `Gap 265/IMPLEMENTATION_GUIDE_V2.md`, contendo **somente** pendências de dicionário de dados (DDIC) — nada de classe/ABAP, nada do que já foi resolvido na Parte 1 acima (aquilo é código, fica registrado só neste documento). O v2 deve listar, no mínimo, os itens abaixo, cada um com: objeto, situação atual, o que falta confirmar/ajustar, e por quê.

1. **`zdeq2c_265_desc_trkintwt` / `zdeq2c_265_desc_trkfnlwt`** — hoje `NUMC(6)`. A tabela real da Carga (`ZTQ2C_PCS_DET`, ambiente) usa `NUMC(5)` pros mesmos campos. Pendente: confirmar com funcional/PCS o tamanho real do campo de peso no layout `U301-H` antes de ativar em definitivo; ajustar para `NUMC(5)` se for esse o caso (já registrado no `IMPLEMENTATION_GUIDE.md` atual, seção 6.3 — o v2 deve herdar esse item, ele continua em aberto).
2. **`ZTBQ2C_CTRL_PCS`** — tabela de numeração PCS compartilhada Carga/Descarga (`Q2C - Controle de Numeração PCS (Carga/Descarga)`), já existe no ambiente. Confirmado no código atual (`zclq2c_265_descarga_granel.clas.abap`) que **não há** nenhuma referência a essa tabela — o `ORDERNUM` do outbound vem direto de `ms_descarga-pcsordernum` (ou seja, de um campo que já precisa estar preenchido antes, por outro processo). Pendente: mapear no dicionário de dados se `ZTBQ2C_CTRL_PCS` precisa de algum campo/estrutura adicional para servir de fonte de numeração da Descarga, ou se ela já está pronta e só falta o código consumir (esse último ponto é ABAP, não DDIC — fica registrado aqui só como gatilho para abrir a investigação).
3. **Data Elements da lista 3.1.1 do `IMPLEMENTATION_GUIDE.md` atual** — conferidos por amostragem (`zdeq2c_265_desc_starttme`/`_endtime` = `CHAR(17)`, `_compdrop` = `CHAR(3)`, `_labinfo` = `CHAR(60)`, `_sealcode` = `CHAR(10)`) e batem com o que o guia atual descreve. Pendente: conferir a lista completa (faltam confirmar os demais itens da tabela 3.1.1) contra o layout oficial `U301-H`/`U301-S` da EF antes do fechamento definitivo — o v2 deve trazer essa conferência completa, não só a amostra feita aqui.
4. **Tipo dos campos `TRKINTWT`/`TRKFNLWT` em `ty_u301_h` (local da classe) vs `ztq2c_pcs_det_d` (DDIC)** — depois do ajuste de código do achado 1.2 (Parte 1), `ty_u301_h` passa a ter campos `string` adicionais (`trkintwt_raw`/`trkfnlwt_raw`) que **não existem** na tabela `ztq2c_pcs_det_d`. Pendente: decidir/documentar no DDIC se esses campos brutos devem ser persistidos em `ztq2c_pcs_det_d` (auditoria do texto exatamente como veio do PCS) ou se ficam só em memória durante o processamento. Se a decisão for persistir, é um campo novo na tabela — isso é uma mudança de DDIC real e deve entrar no v2.

**Regra pra esse documento novo:** nada de reexplicar arquitetura de classe ou pipeline — isso já está no `IMPLEMENTATION_GUIDE.md` atual e não muda. O v2 é um adendo focado em dicionário de dados: o que existe, o que falta confirmar de tamanho/tipo, e o que pode virar campo novo.
