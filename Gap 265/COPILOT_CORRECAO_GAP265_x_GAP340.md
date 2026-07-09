# Correção GAP 265 x GAP 340 — Instruções para o Copilot

## 0. Ordem de prioridade (leia antes de tocar em qualquer arquivo)

1. **Prioridade 1 — Padrão interno do GAP 265.** O retorno de Descarga (`Gap 265/inbound/zclq2c_265_desc_ret_granel.clas.abap` + `zclq2c_265_desc_job.clas.abap`) precisa continuar espelhando **exatamente** a arquitetura já usada na Carga (`ZPQ2C_265_20260703_082358`): classe própria, job APJ próprio, runner próprio, mensagens próprias (`ZCL_Q2C_265_MSG_DG`), tabela de log própria (`ZTBQ2C_DESCGRALOG`), TVARVC via `zz1_tvarvc_q2c`. **Isso não muda.**
2. **Prioridade 2 — Não colidir com o GAP 340.** Onde o GAP 265 e o GAP 340/M06 tentam resolver o **mesmo problema** (ler retorno PCS da Descarga e localizar/atualizar a Ordem), o 265 não pode duplicar um job/objeto que o 340 já resolveu, nem duplicar persistência da mesma informação de negócio em lugares diferentes.

**Refatoração deve ser mínima.** Não reescrever o pipeline do GAP 265 (ele está correto e aderente à EF). Os ajustes abaixo tocam **apenas** nos pontos onde os dois GAPs esbarram.

---

## 1. Decisão: reaproveitar tabelas existentes?

**Decisão fechada, com base em busca `Z*PCS*` no SE11 do ambiente (não só no que está no git) — critério: chave igual/próxima + campos parecidos = mesma tabela, reaproveitar; chave/propósito diferente = criar.**

A busca `Z*PCS*` no ambiente encontrou 5 tabelas, nenhuma delas é `ZTQ2C_PCS_DET_D`: `ZTBQ2C_CTRL_PCS`, `ZTQ2C_PCS_DET`, `ZTQ2C_PCS_HDR`, `ZTQ2C_PCS_ITM`, `ZTQ2C_PCS_LAB`. Isso muda a decisão anterior (que só olhava o `GAP 340`) em dois pontos:

- **`ZTBQ2C_CTRL_PCS` — reaproveitar como está, não copiar.** Texto curto: *"Q2C - Controle de Numeração PCS (Carga/Descarga)"* — é a própria descrição do objeto que diz que essa tabela já é compartilhada entre os dois fluxos. **Ação para o Copilot:** verificar se `zclq2c_265_descarga_granel` (outbound) já usa `ZTBQ2C_CTRL_PCS` para gerar/controlar o `ORDERNUM` do envio; se não usa e está gerando `ORDERNUM` de outra forma, isso é um gap a corrigir — a numeração deveria vir dessa tabela de controle compartilhada, não de uma rotina própria da Descarga.
- **`ZTQ2C_PCS_HDR`/`ZTQ2C_PCS_DET`/`ZTQ2C_PCS_ITM`/`ZTQ2C_PCS_LAB` — não reaproveitar literalmente, mas são o molde real das tabelas do GAP 265.** Texto curto de todas: *"carregamento PCS Granel"* — são tabelas de **Carga**, e o próprio `ESTRUTURA_GAP_265.md` já instrui "Trocar no dev de Descarga: tabelas/visões de destino para update de negócio" (ou seja: mesma arquitetura, tabela nova). Confirma-se então que criar tabela nova para Descarga é o caminho certo. Porém `ZTQ2C_PCS_DET` (76 campos) tem campos **literalmente iguais** ao layout `U301-H` da EF da Descarga — `ORDERNUM`, `TRKINTWT`, `TRKFNLWT`, `LINEEMTY`, `LINE2USE`, `PRODNUMB` — o que confirma que essas tabelas foram o padrão-fonte de onde a EF da Descarga tirou o layout. `ZTQ2C_PCS_DET_D`/`_I` deveriam ter sido criadas como **cópia adaptada** desse padrão (mesmos data elements onde o campo é o mesmo dado), não com data elements novos do zero. Ver achados 2.6 e 2.7 abaixo — são consequência direta dessa checagem.
- **`ztbq2c_descarga` — segue reaproveitada (sem mudança).** `peso_inicial`/`peso_final` continuam vindo dessa tabela via `pcs_ordernum`, isso já estava certo e não muda com a descoberta acima.
- **`ZTQ2C_PCS_DET_D`/`_I` — criar, mas com dois ajustes de alinhamento ao padrão da Carga (2.6 e 2.7), não como estão hoje.**
- **O que não deve ser reaproveitado do GAP 340:** o job `ZCL_Q2C_PCS_RETORNO` (M06), a message class `ZQ2C_PCS`, o Application Log Object `ZQ2C_PCS`/`RETORNO` e as entradas de TVARVC `ZQ2C_PCS_RETURN_*`. Motivo no item 2.1.

---

## 2. Erros / colisões encontrados

### 2.1 [CRÍTICO] Dois jobs concorrentes para o mesmo arquivo de retorno PCS

**Onde:** `GAP 340/Ajustes M06 - retorno_pcs_descarga/ZCL_Q2C_PCS_RETORNO.clas.txt` **vs.** `Gap 265/inbound/zclq2c_265_desc_ret_granel.clas.abap` + `zclq2c_265_desc_job.clas.abap`.

**Problema:** os dois objetos fazem a mesma coisa — listam arquivo `U301-H` no AL11, localizam a Descarga por `pcs_ordernum`/`ORDERNUM` e atualizam `peso_inicial`/`peso_final` em `ztbq2c_descarga`. O GAP 265 é um superconjunto (também trata `U301-S`/lacres, valida `ORDERNUM` contra o SAP, persiste header+lacres em `ZTQ2C_PCS_DET_D`/`_I`). O `ZCL_Q2C_PCS_RETORNO` do M06 **ainda não foi criado no sistema** (é só o `.txt`/guia, checklist do `IMPLEMENTATION_GUIDE.md` de M06 está todo em aberto).

**Risco se os dois forem criados:** dois jobs lendo o mesmo diretório AL11, cada um movendo o arquivo processado para sua própria pasta — o job que rodar primeiro "consome" o arquivo e o outro nunca o processa. Além disso, duas message classes (`ZQ2C_PCS` e `ZCL_Q2C_265_MSG_DG`) e dois mecanismos de log (BALI/SLG1 vs `ZTBQ2C_DESCGRALOG`) para o mesmo evento de negócio.

**Correção:** **não implementar o checklist de M06** (Passos 0 a 6 do `IMPLEMENTATION_GUIDE.md` de M06 — TVARVC `ZQ2C_PCS_RETURN_*`, Log Object `ZQ2C_PCS`, message class `ZQ2C_PCS`, classe `ZCL_Q2C_PCS_RETORNO`, runner e job APJ). O job do GAP 265 (`zclq2c_265_desc_job` → `zclq2c_265_desc_ret_granel`) passa a ser o único responsável por processar o retorno PCS da Descarga, seguindo só a Prioridade 1 (item 0). Marcar `GAP 340/Ajustes M06 - retorno_pcs_descarga/IMPLEMENTATION_GUIDE.md` com uma nota no topo: "Superseded pelo pipeline `zclq2c_265_desc_ret_granel` do GAP 265 — não criar estes objetos." Não apagar os arquivos de M06 (ficam como referência histórica), só adicionar a nota.

---

### 2.2 [ALTO] Layout de parsing do `U301-H` em M06 não bate com a EF

**Onde:** `GAP 340/.../ZCL_Q2C_PCS_RETORNO.clas.txt`, método `parse_header` (constantes `gc_pos_rectype`, `gc_header_tag = 'U301-H'`).

**Problema:** o método assume que a **posição 0** de cada linha é um marcador literal `'U301-H'`, e só então `ORDERNUM` (posição 1), `TRKINTWT` (posição 2), `TRKFNLWT` (posição 3). Mas `EF_GAP_265_DESCARGA.md`, seção "Layout U301-H | Header de Retorno", define a **Seq 1 = ORDERNUM** — não existe campo de marcador de tipo de registro na linha. É o **nome do arquivo** que carrega o `U301-H`/`U301-S` (é assim que `zclq2c_265_desc_ret_granel::process_single_file` decide, verificando `iv_file_name(6)`). Se `ZCL_Q2C_PCS_RETORNO` fosse ativado como está, todo campo seria lido deslocado em uma posição (leria `ORDERNUM` no lugar do peso, etc.).

**Correção:** não é necessário corrigir esse método isoladamente — ele deixa de existir como job próprio pela decisão do item 2.1. Se qualquer trecho de `ZCL_Q2C_PCS_RETORNO` for reaproveitado dentro do pipeline do GAP 265 (ver item 2.3), **usar o parsing já correto de `zclq2c_265_desc_ret_granel::read_u301_h_file`** (sem coluna de marcador), que já está de acordo com a EF.

---

### 2.3 [ALTO] Nome de campo da CDS inconsistente entre os dois GAPs

**Onde:** `GAP 340/.../ZCL_Q2C_PCS_RETORNO.clas.txt`, método `find_descarga`:
```abap
SELECT SINGLE shnumber, remessa, item_remessa
  FROM zi_q2c_descarga
  WHERE pcs_ordernum = @iv_pcs_ordernum
```

**Problema:** a CDS view `ZI_Q2C_DESCARGA` (`GAP 340/ZPQ2C_340_D_20260617_232623/src/zi_q2c_descarga.ddls.asddls`, linha 86) expõe o campo como `pcs_ordernum as PcsOrdernum` — ou seja, o nome público do elemento é `PcsOrdernum` (sem underscore). Um `WHERE pcs_ordernum = ...` contra essa CDS view não resolve (`pcs_ordernum` ≠ `PcsOrdernum` para o Open SQL, que preserva underscore como parte do identificador). O mesmo problema existe para `item_remessa` (expõe como `ItemRemessa`). Isso teria dado erro de sintaxe/ativação em M06.

**Evidência de que o padrão correto já existe no próprio repositório:** `Gap 265/outbound/zclq2c_265_descarga_granel.clas.abap` (linhas 213-214, 236, 299) já consulta a mesma CDS `zi_q2c_descarga` corretamente usando `pcsordernum` (sem underscore, case-insensitive bate com `PcsOrdernum`). Já `zclq2c_265_desc_ret_granel::update_historico` (linha 354) usa `pcs_ordernum` **com** underscore, mas contra a **tabela base** `ztbq2c_descarga` (não a CDS) — lá está correto, porque o campo físico da tabela é `PCS_ORDERNUM`.

**Correção:** não corrigir isoladamente em M06 (objeto não será criado, item 2.1). Regra a seguir daqui para frente em qualquer código do GAP 265/340 que toque nesse dado: **consultando a CDS `ZI_Q2C_DESCARGA`/`ZI_Q2C_MONI_DESCARGA` → usar os nomes sem underscore (`pcsordernum`, `itemremessa`, `shnumber`); consultando a tabela base `ztbq2c_descarga` diretamente → usar os nomes com underscore (`pcs_ordernum`, `item_remessa`)**.

---

### 2.4 [MÉDIO] `update_historico` do GAP 265 não valida/converte o peso antes de gravar

**Onde:** `Gap 265/inbound/zclq2c_265_desc_ret_granel.clas.abap`, método `update_historico` (linha ~347-356) e `read_u301_h_file` (linha ~224-252).

**Problema:** `trkintwt`/`trkfnlwt` são tipados como `zdeq2c_265_desc_trkintwt`/`_trkfnlwt` (`NUMC(6)`, dígitos puros). O `SPLIT` em `read_u301_h_file` joga o valor bruto do arquivo direto nesse campo `NUMC`, e `update_historico` grava esse valor direto em `ztbq2c_descarga-peso_inicial/peso_final` (`QUAN(13,3)`), sem nenhum tratamento. O GAP 340/M06 já tinha resolvido exatamente esse problema no método `convert_weight` (`ZCL_Q2C_PCS_RETORNO.clas.txt`, linhas 565-603): normaliza separador decimal (`,`/`.`), converte via `decfloat34` dentro de um `TRY/CATCH`, e retorna erro controlado (mensagem `025`) em vez de deixar o programa quebrar.

Sem esse tratamento, um valor de peso com caractere não numérico no arquivo do PCS gera erro de conversão não tratado no `SPLIT`/`MOVE` (o campo é `NUMC`, que não aceita separador decimal), interrompendo o job em vez de logar o arquivo como erro e seguir para o próximo.

**Correção:** portar a lógica de `convert_weight` (normalização de `,`/`.` + `TRY/CATCH cx_root` + fallback controlado) para dentro de `zclq2c_265_desc_ret_granel`, como um novo método privado `convert_weight`, chamado a partir de `update_historico` antes do `UPDATE`. Em caso de falha de conversão, usar `zclq2c_265_desc_common=>add_error` (mesmo padrão do resto da classe) em vez de deixar o SPLIT gravar valor bruto num campo `NUMC`. Isso é reaproveitar uma solução já validada pelo 340, dentro do padrão de mensagens do 265 — não é criar arquitetura nova.

---

### 2.5 [MÉDIO] Falta commit explícito após o `UPDATE` de `ztbq2c_descarga`

**Onde:** `Gap 265/inbound/zclq2c_265_desc_ret_granel.clas.abap`, método `execute` (linha ~140-143) e `update_historico` (linha ~347-356).

**Problema:** `execute` chama `update_retorno` (que faz `BAPI_TRANSACTION_COMMIT` na linha ~342-344) **antes** de `update_historico` (que faz o `UPDATE ztbq2c_descarga ... SET peso_inicial, peso_final` sem nenhum commit depois). Ou seja, o `UPDATE` na tabela de negócio do GAP 340 fica sem commit explícito na mesma execução. O GAP 340/M06 já segue o padrão correto — `update_descarga_weights` faz `COMMIT WORK AND WAIT` logo após o `UPDATE`, no mesmo método (mesmo padrão de commit transacional que a Carga do 265 também usa).

**Correção:** adicionar `CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true` ao final de `update_historico`, logo após o `LOOP`/`UPDATE`, mantendo o mesmo padrão já usado em `update_retorno` na mesma classe.

---

### 2.6 [MÉDIO] Tamanho de campo do peso divergente do padrão real da Carga

**Onde:** `Gap 265/objetos_comuns/zdeq2c_265_desc_trkintwt.dtel.xml` e `zdeq2c_265_desc_trkfnlwt.dtel.xml` (`NUMC(6)`).

**Problema:** na tabela real da Carga (`ZTQ2C_PCS_DET`, campos `TRKINTWT`/`TRKFNLWT`), o tipo é `NUMC(5)` — um dígito a menos. O GAP 340/M06 também assumiu 6 dígitos (`char6`) na sua documentação, sem checar contra o objeto que a própria Carga já usa em produção. Ou seja, há três números diferentes boiando para o "mesmo" campo: 5 (Carga, já em uso real), 6 (GAP 265 novo), 6 (suposição do M06).

**Correção:** **não decidir sozinho** — este é um dado de layout físico do arquivo PCS, não uma decisão de arquitetura. Confirmar com o time funcional/PCS qual é o tamanho real do campo de peso no arquivo `U301-H`. Se for 5 dígitos (mais provável, por já estar em produção na Carga), ajustar `zdeq2c_265_desc_trkintwt`/`_trkfnlwt` de `NUMC(6)` para `NUMC(5)` antes de ativar — evita truncamento/estouro silencioso ao gravar um valor de 6 dígitos num campo de 5, ou vice-versa perder um dígito de precisão se o real for 6.

---

### 2.7 [ALTO] Chave de `ZTQ2C_PCS_DET_D` não segue o padrão de chave já estabelecido pela Carga

**Onde:** `Gap 265/inbound/ztq2c_pcs_det_d.tabl.xml` (chave `MANDT+ORDERNUM`) e `ztq2c_pcs_itm_d.tabl.xml` (chave `MANDT+SORDRNM+SEQNO`).

**Problema:** a tabela equivalente já em produção na Carga, `ZTQ2C_PCS_DET`, usa como chave a **chave de negócio SAP** (`SHNUMBER+PCSITEM+DELIVERY+VEH_NR+TPU_NR+COM_NUMBER`) — o `ORDERNUM` do PCS aparece nela só como **campo não-chave** (atributo de cross-reference). O GAP 265 fez o oposto em `ZTQ2C_PCS_DET_D`: usou `ORDERNUM` como chave primária. Isso quebra a Prioridade 1 (seguir o padrão já estabelecido na Carga) — o padrão real da Carga é "a chave é sempre a chave de negócio SAP, o identificador do PCS é atributo", exatamente para evitar acoplar a estrutura da tabela SAP ao identificador de um sistema externo.

**Impacto prático:** com `ORDERNUM` como chave, um reprocessamento onde o PCS reaproveitasse um número de ordem (ou um cenário de teste/estorno que gerasse novo `ORDERNUM` para a mesma remessa) criaria um registro desconexo do histórico da Ordem em `ztbq2c_descarga`. Com a chave de negócio SAP (`SHNUMBER+REMESSA+ITEM_REMESSA`, que já é literalmente a chave de `ztbq2c_descarga`), o header/lacres do retorno ficam sempre rastreáveis pela mesma chave que o resto do processo de Descarga usa.

**Correção:** trocar a chave de `ZTQ2C_PCS_DET_D` para `MANDT+SHNUMBER+REMESSA+ITEM_REMESSA` (mesma chave de `ztbq2c_descarga`, seguindo o padrão da Carga), mantendo `ORDERNUM` como campo não-chave. Ajustar `ZTQ2C_PCS_ITM_D` para `MANDT+SHNUMBER+REMESSA+ITEM_REMESSA+SEQNO`. Isso exige ajuste em `zclq2c_265_desc_ret_granel::update_retorno` (resolver `SHNUMBER/REMESSA/ITEM_REMESSA` a partir do `ORDERNUM` — a própria `valida_arquivos` já faz esse SELECT contra `zi_q2c_descarga`, só precisa propagar o resultado para o `MOVE-CORRESPONDING`/`MODIFY`). **Antes de aplicar, confirmar com o funcional/DBA se `ZTQ2C_PCS_DET_D`/`_I` já foram transportadas para algum ambiente com a chave atual — se sim, é mudança de chave em tabela já existente, requer avaliação de impacto, não é ajuste trivial de DDIC.**

---

## 3. Script de renomeação de tabelas (padrão de nomenclatura da Carga)

Critério: onde já existir uma tabela da Carga com propósito/campos equivalentes, o nome novo da Descarga segue o **mesmo nome + sufixo `_D`**, em vez de inventar um nome novo (`ZDESCARGA_INTERFACE_PCS` não segue o padrão do resto do pacote — nenhuma outra tabela do GAP 265/PCS usa esse estilo de nome).

| Nome antigo (descontinuado) | Nome novo | Copiado de (Carga) | Chave nova | Status no ambiente |
|---|---|---|---|---|
| `ZDESCARGA_INTERFACE_PCS` | `ZTQ2C_PCS_DET_D` | `ZTQ2C_PCS_DET` (estrutura/campos) | `MANDT+SHNUMBER+REMESSA+ITEM_REMESSA` (`ORDERNUM` não-chave) | Nunca criada no ambiente (busca `Z*PCS*` no SE11 não retornou) — renomear é seguro, não é objeto já transportado |
| `ZDESCARGA_INTERFACE_PCS_I` | `ZTQ2C_PCS_ITM_D` | `ZTQ2C_PCS_ITM` (papel de tabela item/filha) | `MANDT+SHNUMBER+REMESSA+ITEM_REMESSA+SEQNO` (`SORDRNM` não-chave) | Idem |
| — (nenhuma, reaproveitar) | `ZTBQ2C_CTRL_PCS` | é a própria | sem alteração | Já existe, compartilhada Carga/Descarga — não copiar, não renomear |

**Passo a passo sugerido para o Copilot executar (nada disso foi aplicado por mim — só análise e recomendação):**

1. **Renomear** `Gap 265/inbound/zdescarga_interface_pcs.tabl.xml` → `Gap 265/inbound/ztq2c_pcs_det_d.tabl.xml`.
   - **O quê:** ajustar `TABNAME` (em `DD02V` e `DD09L`) de `ZDESCARGA_INTERFACE_PCS` para `ZTQ2C_PCS_DET_D`; trocar a chave de `MANDT+ORDERNUM` para `MANDT+SHNUMBER+REMESSA+ITEM_REMESSA`, com `ORDERNUM` virando campo não-chave.
   - **Por quê:** ver achado 2.7 — o padrão real da Carga (`ZTQ2C_PCS_DET`) usa a chave de negócio SAP, não o `ORDERNUM` do PCS; e o nome segue a convenção `ZTQ2C_PCS_*` já usada em todo o resto do pacote PCS, em vez de `ZDESCARGA_INTERFACE_PCS`, que é um nome isolado sem paralelo em nenhuma outra tabela do GAP 265.

2. **Renomear** `Gap 265/inbound/zdescarga_interface_pcs_i.tabl.xml` → `Gap 265/inbound/ztq2c_pcs_itm_d.tabl.xml`.
   - **O quê:** ajustar `TABNAME` para `ZTQ2C_PCS_ITM_D`; trocar a chave de `MANDT+SORDRNM+SEQNO` para `MANDT+SHNUMBER+REMESSA+ITEM_REMESSA+SEQNO`, com `SORDRNM` virando campo não-chave.
   - **Por quê:** mesmo motivo do item 1 — alinhar com a chave de `ztq2c_pcs_det_d` (header) e com o papel de tabela item/filha que `ZTQ2C_PCS_ITM` já tem na Carga.

3. **Ajustar** `Gap 265/inbound/zclq2c_265_desc_ret_granel.clas.abap`, método `update_retorno`.
   - **O quê:** antes de montar `lt_hdr`/`lt_itm`, fazer `SELECT shnumber, remessa, itemremessa, pcsordernum FROM zi_q2c_descarga WHERE pcsordernum IN @lt_ordernum` (mesmo padrão de `pcsordernum` sem underscore do achado 2.3) e usar o resultado pra preencher `SHNUMBER`/`REMESSA`/`ITEM_REMESSA` em cada linha; trocar as referências de `zdescarga_interface_pcs`/`_i` para `ztq2c_pcs_det_d`/`ztq2c_pcs_itm_d`; trocar a condição do `DELETE` de `sordrnm = ordernum` para `shnumber/remessa/item_remessa`.
   - **Por quê:** consequência direta da mudança de chave nos itens 1 e 2 — sem isso a classe não compila (referencia tabelas/campos que não existem mais) e não teria como preencher a nova chave.

4. **Atualizar** `Gap 265/IMPLEMENTATION_GUIDE.md`, seção "2.2 Objetos de persistência".
   - **O quê:** para cada tabela, indicar explicitamente de qual tabela da Carga foi copiada e qual é o nome novo (ex.: "`ztq2c_pcs_det_d` — cópia adaptada de `ZTQ2C_PCS_DET`"), e remover as referências a `zdescarga_interface_pcs`/`_i` da "Ordem recomendada de criação".
   - **Por quê:** pedido explícito — o guia de implementação precisa deixar rastreável qual tabela virou qual, para quem for criar os objetos no SE11/ADT não confundir com o nome antigo.

5. **Atualizar** `Gap 265/inbound/README.md`, seção "Observação técnica".
   - **O quê:** trocar a menção a `ZDESCARGA_INTERFACE_PCS` pelos nomes novos e pela origem (cópia de `ZTQ2C_PCS_DET`/`ZTQ2C_PCS_ITM`).
   - **Por quê:** mesmo motivo do item 4, manter a documentação da pasta consistente com o nome real das tabelas.

**Ainda a decidir antes de criar qualquer coisa no ambiente ABAP:**

- Resolver o achado 2.6 (tamanho `NUMC(5)` da Carga vs `NUMC(6)` assumido pelo GAP 265/M06) antes de definir o tipo final dos campos de peso em `ztq2c_pcs_det_d`.
- `ZDESCARGA_INTERFACE_PCS`/`_I` (nomes antigos) não existem hoje no ambiente — confirmado pela busca `Z*PCS*` no SE11 — então não há risco de "quebrar" um objeto já transportado ao renomear; mesmo assim, confirmar de novo no momento de criar, caso algo tenha sido criado entre essa checagem e a execução deste script.
- Os arquivos de análise histórica `COPILOT_REFACTOR_GAP_265.md` e `DOUBLE_CHECK_GAP_265.md` ainda citam `ZDESCARGA_INTERFACE_PCS`/`_I` — ficam como registro do que foi decidido antes; não precisam ser reescritos, mas quem ler deve saber que a decisão de nome mudou (está registrada aqui).

---

## 4. O que o Copilot **não** deve fazer

- Não recriar a arquitetura do GAP 265 (classes, mensagens, log table) — ela já está correta e é a referência (Prioridade 1).
- Não criar os objetos do checklist de M06 (`ZQ2C_PCS_RETURN_*` em TVARVC, Log Object `ZQ2C_PCS`, message class `ZQ2C_PCS`, `ZCL_Q2C_PCS_RETORNO`, runner, job/catalog/template de M06).
- Não apagar `GAP 340/Ajustes M06 - retorno_pcs_descarga/*` — apenas adicionar nota de "superseded" no `IMPLEMENTATION_GUIDE.md` de M06 apontando para `zclq2c_265_desc_ret_granel`.
- Não reaproveitar `ZTQ2C_PCS_HDR`/`ZTQ2C_PCS_DET`/`ZTQ2C_PCS_ITM`/`ZTQ2C_PCS_LAB` literalmente — são tabelas de Carga em uso. Servem só como molde de estrutura/campo (ver 2.6/2.7), não como destino de gravação da Descarga.
- Não ativar `ZTQ2C_PCS_DET_D`/`_I` como estão hoje sem antes resolver 2.6 (tamanho do campo de peso) e 2.7 (chave) — e sem confirmar se já foram transportadas para algum ambiente (mudança de chave em objeto já existente é diferente de ajustar DDIC ainda não transportado).
- Não tocar em `envia_pcs`: com a decisão do item 2.1, o TODO de `validate_pcs_enabled` em M06 fica sem efeito (M06 não será ativado); a validação de `ORDERNUM` existente já é feita por `valida_arquivos` no pipeline do 265.

---

## 5. Checklist de aceite

- [ ] Nota de "superseded" adicionada em `GAP 340/Ajustes M06 - retorno_pcs_descarga/IMPLEMENTATION_GUIDE.md`.
- [ ] Nenhum objeto do checklist de M06 (Passos 0-6) foi criado no sistema.
- [ ] `zclq2c_265_desc_ret_granel` ganhou método `convert_weight` (normalização decimal + `TRY/CATCH` + erro controlado via `add_error`), chamado por `update_historico` antes do `UPDATE`.
- [ ] `update_historico` grava peso já convertido/validado, não o `NUMC` bruto.
- [ ] `update_historico` faz `BAPI_TRANSACTION_COMMIT WAIT = abap_true` após o `UPDATE`.
- [ ] Nenhuma tabela nova foi criada para persistir peso (continua usando `ztbq2c_descarga`).
- [ ] Confirmado (de novo, no momento da execução) que `ZDESCARGA_INTERFACE_PCS`/`_I` continuam não existindo no ambiente antes de renomear.
- [ ] Tabelas renomeadas no repositório conforme seção 3: `zdescarga_interface_pcs.tabl.xml` → `ztq2c_pcs_det_d.tabl.xml`, `zdescarga_interface_pcs_i.tabl.xml` → `ztq2c_pcs_itm_d.tabl.xml`, chave ajustada para `MANDT+SHNUMBER+REMESSA+ITEM_REMESSA` (+`SEQNO` no item), `ORDERNUM`/`SORDRNM` como campo não-chave.
- [ ] `update_retorno` ajustado para resolver `SHNUMBER/REMESSA/ITEM_REMESSA` a partir do `ORDERNUM` via `SELECT ... FROM zi_q2c_descarga` antes de gravar.
- [ ] `IMPLEMENTATION_GUIDE.md` e `inbound/README.md` atualizados com tabela de origem/nome novo.
- [ ] Criar `ZTQ2C_PCS_DET_D`/`ZTQ2C_PCS_ITM_D` de fato no ambiente ABAP (SE11/ADT), a partir dos `.tabl.xml` renomeados.
- [ ] Tamanho de `TRKINTWT`/`TRKFNLWT` confirmado com o funcional/PCS (`NUMC(5)`, igual à Carga, ou `NUMC(6)` se houver evidência real do layout) e ajustado nos data elements antes de ativar `ztq2c_pcs_det_d`.
- [ ] Verificado se `zclq2c_265_descarga_granel` (outbound) já usa `ZTBQ2C_CTRL_PCS` para numeração do `ORDERNUM`; se não usa, abrir item para avaliar migração para essa tabela de controle compartilhada Carga/Descarga.
- [ ] Pipeline, mensagens e log do GAP 265 (Prioridade 1) permanecem inalterados fora dos pontos acima.
- [ ] Item separado, não bloqueante: re-exportar `ztbq2c_descarga.tabl.xml` do ambiente pro repo (git está com 83 campos, ambiente tem 89 — fora do escopo deste ajuste, mas fica registrado para não ficar esquecido).
