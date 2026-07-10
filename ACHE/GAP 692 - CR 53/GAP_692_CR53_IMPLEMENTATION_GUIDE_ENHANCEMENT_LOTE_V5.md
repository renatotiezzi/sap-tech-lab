# GAP 692 / CR 53 — Guia Técnico de Implementação do Enhancement de Geração Automática de Lote (Aché)

> **Escopo deste guia**: cobre exclusivamente o enhancement ABAP (BAdI + lógica central de determinação de lote) que você é responsável por implementar. A criação das tabelas customizadas, CDS Views, RAP App (BDEF/SDEF/Service Binding) e app Fiori de manutenção dos parâmetros é responsabilidade de outro desenvolvedor — este guia trata os nomes dessas tabelas/CDS como **dependências externas a confirmar**, não como objetos que você vai criar.
>
> Fonte: `ACHE_EF_MM_GAP_692_CR53Geracao_Numeracao_Lote_Ache.pdf` (EF GAP 692 / CR 53, V1, 14/06/2026).
>
> Nomenclatura dos objetos ABAP deste guia segue `WORKBOOK_SAPHIRA_ACHE_V1 (20260317)` — Convenção de Nomenclaturas para Objetos SAP do projeto SAPHIRA. Onde o workbook não cobre um tipo de objeto específico do seu escopo (ex. Lock Object), isso é sinalizado explicitamente como pendência de confirmação com o COE.

### Histórico de revisões

| Versão | O que mudou |
|---|---|
| V1 | Primeira versão, assinatura do BAdI assumida a partir da documentação genérica da EF (não confirmada em sistema). |
| V2 | Nomenclatura de todos os objetos do enhancement ajustada para o padrão WORKBOOK SAPHIRA (`/ACHE/...`), prefixos de parâmetro/form corrigidos. |
| V3 | **Correção de arquitetura**, a partir do template real gerado pela SE24 no sistema: a interface é `IF_LOBM_BEFORE_BATCH_NMBR_INT` (não a assumida em V1), e o método `BEFORE_NUMBER_ASSIGNMENT` **não recebe o lote para preenchimento direto** — ele só controla se a numeração interna standard é pulada. A gravação do lote customizado passa para o método **AFTER_NUMBER_ASSIGNMENT** (BAdI irmã, seção 7 reescrita). Demais seções mantidas sem alteração de conteúdo. |
| V4 | **Substituídos os placeholders de tabela/campo por objetos reais**, confirmados por print de tela das CDS Views já criadas pelo outro desenvolvedor (`/ACHE/I_MMCDS_1001` a `1004`) e pelo código-fonte completo da FM legada `YYPCL_DETERMINA_LOTE` (ECC/As Is). Seção 2 reescrita com o mapeamento As Is → To Be completo; seções 3 (locks) e 5 (função central) reescritas com nomes de campo reais (sem prefixo `ZZ`) e lógica de montagem do lote fiel ao legado, **exceto** onde o legado tinha bugs conhecidos (lock vazando em um caminho, ausência de validação de range) — esses pontos foram corrigidos, não replicados, e estão marcados explicitamente. Revisão adicional: fechado o furo de `ERRO_GERAL`/mensagem `006` (declarada mas nunca levantada) com `TRY`/`CATCH cx_root`. |
| V5 | **Duas correções de campo em produção**, encontradas ao revisar a implementação real: (1) a CDS renomeia os campos ao expor (`MaterialGroup`, `MaterialType`, `FiscalYear`, `FiscalPeriod`, `Sequence05/06/08`, `BatchNumericLength`, `MonthlyBreak` — diferentes dos nomes técnicos da tabela física); seção 2.1 ganhou uma coluna explícita "Campo exposto pela CDS", e a seção 5.2 agora traduz campo a campo (`ls_..._db`) antes do `MODIFY` nas tabelas físicas — não dá mais pra usar a estrutura da CDS direto num `MODIFY`. (2) A implementação da BAdI está sob restrição de ABAP Cloud/Extensibilidade e não permite `CALL FUNCTION` direto de dentro do método — nova seção 7.4 cria a classe wrapper liberada `/ACHE/CLMM_LOTE_DETERMINAR`, e a BAdI AFTER (seção 7.5) passa a chamar essa classe em vez da FM. O Coletor de Recebimento (seção 8) não precisa do wrapper, por não estar sob essa restrição. |

---

## 0. Visão geral do que você vai construir

Três pontos de disparo, uma lógica central:

| # | Cenário | Ponto técnico | Tipo de integração |
|---|---------|----------------|---------------------|
| 1 | Entrada de mercadoria | Enhancement Spot `LOBM_BATCH_EXT` → BAdI `LOBM_BEFORE_BATCH_NUMBER_INT` → método `BEFORE_NUMBER_ASSIGNMENT` | BAdI standard SAP |
| 2 | Criação de ordem de processo | Mesmo Enhancement Spot / BAdI / método do item 1 | BAdI standard SAP (mesma implementação) |
| 3 | Coletor de Recebimento | Fluxo custom do GAP334/391 (pergunta "Deseja gerar Lote Aché?") | Reuso da lógica central via chamada de função — **não é BAdI** |

Os itens 1 e 2 são acionados pelo **mesmo** enhancement spot — não são duas implementações diferentes. O SAP standard chama esse enhancement spot sempre que a determinação interna de número de lote é necessária, independente da transação de origem. Você não precisa (e não deve) diferenciar o fluxo de negócio dentro dos métodos; a regra de geração é orientada por parametrização do tipo de material, não pela transação chamadora.

O item 3 **não passa por BAdI nenhuma** — é um desenvolvimento custom (coletor de recebimento). Para esse cenário, a EF pede reuso da mesma lógica central, acionada pelo fluxo específico do GAP334/391. Trate isso como "chamar a mesma função central a partir de um ponto diferente do código", não como um enhancement novo.

**Importante (confirmado em sistema via SE24 — ver seção 7):** o Enhancement Spot `LOBM_BATCH_EXT` expõe **duas** BAdIs, não uma só, e elas têm papéis diferentes:

- `LOBM_BEFORE_BATCH_NUMBER_INT` (interface `IF_LOBM_BEFORE_BATCH_NMBR_INT`, método `BEFORE_NUMBER_ASSIGNMENT`) — **não recebe o lote para preenchimento**. Só decide se a numeração interna standard (e/ou de um Custom BO) deve ser **pulada** para este material.
- A BAdI irmã de **AFTER** (nome exato a confirmar na SE18 — ver seção 7.5) é onde o lote customizado é efetivamente calculado e gravado.

Arquitetura recomendada:

```
BAdI BEFORE_NUMBER_ASSIGNMENT ──► decide pular numeração standard  ─┐
                                                                      │
BAdI AFTER_NUMBER_ASSIGNMENT  ──► chama a função central e grava ────┼──► FUNCTION /ACHE/MMF_LOTE_DETERMINAR (lógica central)
                                                                      │
Coletor de Recebimento (GAP334/391, ponto a localizar) ─────────────┘
```

Toda a regra de negócio (validação de lote manual, parametrização, contador, lock, montagem do número, duplicidade, range) fica **dentro da função central**. As duas BAdIs e o coletor são apenas chamadores finos.

### 0.1 Pacote (defina antes de criar qualquer objeto)

Todo o desenvolvimento deste guia (BAdI clássica, function group, function module, objeto de bloqueio, classe de mensagens) é **ABAP clássico** — não é RAP/Cloud. Pela regra de nomenclatura SAPHIRA (WORKBOOK seção 1):

```text
Pacote final: <confirmar com COE>
Sugestão inicial: pacote /ACHE/ relacionado a MM/P2P
Se ABAP clássico não aderente a Cloud: validar uso de /ACHE/DEV_OLD
Não usar ZDEV sem aprovação
```

Como todos os objetos deste enhancement são clássicos, a leitura mais direta da regra aponta para `/ACHE/DEV_OLD` (o caminho `/ACHE/` + subpacote de macroprocesso é para desenvolvimento aderente ao modelo ABAP Cloud, que não é o seu caso aqui). **Confirme essa leitura com o COE técnico — André Alvarez / Eder Marcelino** (mesmos nomes que o workbook indica para dúvidas de ABAP Clássico) antes de criar o primeiro objeto. Não use `ZDEV` a menos que `/ACHE/DEV_OLD` não atenda tecnicamente, e mesmo assim só com aprovação formal.

### 0.2 Nomenclatura definitiva dos objetos deste enhancement

Aplicando o WORKBOOK SAPHIRA (seções 3–9) ao seu escopo:

| Objeto | Padrão do workbook | Nome definitivo |
|---|---|---|
| Grupo de função (SE37) | §3.4 `/ACHE/XXGF_<Descrição>` | `/ACHE/MMGF_LOTE` |
| Function module central (SE37) | §3.4 `/ACHE/XXF_<Descrição>` | `/ACHE/MMF_LOTE_DETERMINAR` |
| Implementação BAdI (SE19) | §5 `/ACHE/XX_<Descrição>` | `/ACHE/MM_LOTE_BADI` |
| Classe implementadora (SE24) | §5 `/ACHE/CLXX_<Descrição>` | `/ACHE/CLMM_LOTE_BADI` |
| Classe wrapper da FM central (SE24) | §5 `/ACHE/CLXX_<Descrição>` | `/ACHE/CLMM_LOTE_DETERMINAR` (necessária por restrição de Cloud/Extensibilidade — seção 7.4) |
| Classe de mensagens (SE91) | §7 `/ACHE/XX_<Descrição>` | `/ACHE/MM_LOTE` (mensagens continuam numeradas 001–007) |
| Objeto de bloqueio mensal (SE11) | não coberto pelo workbook | `/ACHE/EMMLOTEMES` (sugestão — ver seção 3 deste guia) |
| Objeto de bloqueio anual (SE11) | não coberto pelo workbook | `/ACHE/EMMLOTEANO` (sugestão — ver seção 3 deste guia) |

Também se aplicam ao seu código (WORKBOOK seção 8.5 — prefixo de parâmetros): parâmetros de function module usam `I_`/`E_`/`C_` (não `IV_`/`EV_`/`CV_`), e rotinas internas (`PERFORM`) usam prefixo `F_`. Já ajustei isso nos esqueletos de código deste guia (seções 5 e 7). Variáveis e estruturas locais (`LV_`/`LS_`/`LT_`) já seguiam o padrão e não mudaram.

> As CDS/tabelas de parametrização continuam sendo objetos do outro desenvolvedor (não são suas para criar), mas na V4 os nomes já foram confirmados por print de tela: `/ACHE/I_MMCDS_1001` a `1004` (SQL views `/ache/mmt100`, `/ache/mmt101`, `/ache/mmt103`, `/ache/mmt104`) — ver mapeamento completo na seção 2.1. Isso bate com o padrão do workbook (`/ACHE/XXCDS_NNNN` + prefixo `I_` de CDS interface view, seção 6 do workbook).

---

## 1. Passo 1 — Reconhecer o legado antes de codificar

Existe hoje uma função custom `YYPCL_DETERMINA_LOTE` que já faz determinação automática de lote por tipo de material (ambiente As Is / ECC legado citado na EF, seção 1.1 e 1.8.2).

1. Abra **SE37**.
2. Informe `YYPCL_DETERMINA_LOTE` → **Exibir**.
3. Leia a lógica: como ela consulta as tabelas de parametrização atuais, como monta o lote (ano/mês/sequencial), como trata mensal vs. anual.
4. Anote as diferenças entre a estrutura legada e o novo modelo de dados (seção 2 abaixo) — a EF deixa claro que o novo desenvolvimento usa **novas tabelas** (`/ACHE/*`), não as tabelas legadas `YYPCL_*`. `YYPCL_DETERMINA_LOTE` serve só como referência de comportamento, não é para ser chamada pelo novo enhancement.

Isso evita reinventar regras que o Aché já validou (ex.: como a quebra mensal/anual afeta o zero-padding do sequencial).

---

## 2. Passo 2 — Dependências de dados (confirmadas na V4 por print de tela)

Estas tabelas/CDS **não são suas para criar** — são do desenvolvedor do RAP App. Mas sua função central depende delas para `SELECT`/`MODIFY`.

Na V4, os objetos abaixo deixaram de ser placeholder: foram confirmados por print de tela do ABAP Development Tools (pacote `/ACHE/MM_GEN_NUMLOTE`, 10/07/2026) e mapeados 1:1 contra a FM legada `YYPCL_DETERMINA_LOTE` (ECC/As Is), que o próprio código-fonte confirma qual campo legado virou qual campo novo.

### 2.1 Mapeamento As Is (ECC) → To Be (S/4, este enhancement)

**Atenção — são dois "alfabetos" de nome de campo diferentes, não um só.** A CDS View **renomeia** os campos ao expor (isso é o `AS` na definição da CDS, confirmado pelos prints de tela): quem lê pela CDS usa os nomes em inglês da coluna "Campo exposto pela CDS"; quem grava direto na tabela física (o `MODIFY` do contador) usa os nomes técnicos curtos da coluna "Campo na tabela física". Confundir os dois foi o bug que corrigi na seção 5.2 desta revisão.

| Legado (`YYPCL_*`) | CDS View nova | SQL View / tabela física | Campo na tabela física (era `ZZ...`) | Campo exposto pela CDS |
|---|---|---|---|---|
| `YYPCL_AGRUPMTART` | `/ACHE/I_MMCDS_1001` — "Agrupamento x tipo de material" | `/ache/mmt100` | `MTART` (chave) | `MaterialType` |
| | | | `GRPMA` (era `ZZGRPMA`) | `MaterialGroup` |
| `YYPCL_AGRUPLOTES` | `/ACHE/I_MMCDS_1002` — "Agrupamento x qtd caract. x quebra mensal" | `/ache/mmt101` | `GRPMA` (chave, era `ZZGRPMA`) | `MaterialGroup` |
| | | | `SEQLOTE` (era `ZZSEQLOTE`) | `BatchNumericLength` |
| | | | `SEQMENSAL` (era `ZZSEQMENSAL`) | `MonthlyBreak` |
| `YYPCL_CNTLOTEMES` | `/ACHE/I_MMCDS_1003` — "Controle de Lotes x quebra mensal" | `/ache/mmt103` | `GJAHR` (chave) | `FiscalYear` |
| | | | `MONAT` (chave) | `FiscalPeriod` |
| | | | `GRPMA` (chave, era `ZZGRPMA`) | `MaterialGroup` |
| | | | `SEQ05`/`SEQ06`/`SEQ08` (eram `ZZSEQ05`/`06`/`08`) | `Sequence05`/`Sequence06`/`Sequence08` |
| `YYPCL_CNTLOTE` | `/ACHE/I_MMCDS_1004` — "Controle de Lotes x quebra anual" | `/ache/mmt104` | `GJAHR` (chave) | `FiscalYear` |
| | | | `GRPMA` (chave, era `ZZGRPMA`) | `MaterialGroup` |
| | | | `SEQ05`/`SEQ06`/`SEQ08` (idem) | `Sequence05`/`Sequence06`/`Sequence08` |

> **O prefixo `ZZ` sumiu** na tabela física. Fazia sentido no legado porque eram campos de anexo (append) sobre estrutura standard; nas tabelas `/ACHE/MMT1xx`, 100% customizadas, não é mais necessário.
>
> **Numeração não é sequencial** — não existe `/ache/mmt102`; a CDS `1002` aponta para `/ache/mmt101`. Não é erro de digitação, é como está de fato no sistema.
>
> **Pacote confirmado**: `/ACHE/MM_GEN_NUMLOTE` → superior `/ACHE/DEV_OLD` — bate exatamente com a recomendação da seção 0.1 (ABAP clássico não aderente ao modelo Cloud). Nenhuma ação pendente aqui.

Por Clean Core (EF seção 1.8.1), sua função central deve fazer **leitura via CDS View** (`/ACHE/I_MMCDS_1001` a `1004`, usando os nomes de campo em inglês) — não diretamente nas tabelas físicas `/ache/mmt1xx`. Gravação (incremento de contador) é feita direto na tabela física (nomes técnicos curtos) — pergunte ao dev do RAP App se existe alguma ação/BO exposta pra isso antes de gravar direto na tabela, para não pular alguma validação do lado dele. A seção 5.2 mostra exatamente onde acontece a tradução de um "alfabeto" pro outro, campo a campo, antes do `MODIFY`.

### 2.2 Por que três campos de contador (`SEQ05`/`SEQ06`/`SEQ08`)

A regra de range (EF seção 2.5) prevê sequenciais de 5, 6 ou 8 dígitos dependendo do grupo. Cada grupo usa **um** desses campos (definido por `SEQLOTE`/`BatchNumericLength` — tabela/CDS, seção 2.1 — em `/ACHE/I_MMCDS_1002`); os outros dois ficam em branco/zero para aquele grupo. Sua função central deve ler/incrementar o campo certo com base nesse indicador, não os três — exatamente como a FM legada fazia com `CASE it_yypcl_agruplotes-zzseqlote`.

> ⚠️ **Confirmar antes de codificar**: os prints mostram os nomes e a semântica dos campos (`Sequence05`/`06`/`08`, `BatchNumericLength`, `MonthlyBreak`), mas não o comprimento exato (tipo de dados / elemento de dados) de `SEQ05`/`SEQ06`/`SEQ08`. O legado monta o lote por `CONCATENATE` puro (sem zero-pad explícito no código), então o zero-padding vem do próprio tipo NUMC do campo. Confirme o comprimento exato de cada campo no Dictionary antes de assumir quantos dígitos cada um gera — a seção 5.2 explica exatamente onde isso importa.

---

## 3. Passo 3 — Criar o objeto de bloqueio (lock) para concorrência

A EF exige (seção "Regra de Concorrência") bloqueio técnico do contador antes do incremento, para evitar lote duplicado sob concorrência.

1. Abra **SE11**.
2. Selecione **Objeto de bloqueio** (Lock Object) → nome sugerido `/ACHE/EMMLOTEMES`.
3. Tabela de bloqueio primária: aponte para a tabela física `/ache/mmt103` (base da CDS `/ACHE/I_MMCDS_1003`, confirmada na seção 2.1).
4. Campos de bloqueio: `MANDT`, `GRPMA`, `GJAHR`, `MONAT` (bloqueio mensal — conforme EF; nomes de campo sem `ZZ`, conforme seção 2.1).
5. Crie um segundo objeto de bloqueio `/ACHE/EMMLOTEANO` sobre `/ache/mmt104` (base da CDS `/ACHE/I_MMCDS_1004`), campos `MANDT`, `GRPMA`, `GJAHR` (bloqueio anual — conforme EF).
6. Ative. O SAP gera automaticamente as function modules de enqueue/dequeue com base nesse nome (algo como `/ACHE/ENQUEUE_EMMLOTEMES` / `/ACHE/DEQUEUE_EMMLOTEMES`, e o par `_EMMLOTEANO`) — **confirme o nome exato gerado após ativar**, o padrão pode variar com o namespace.

> ⚠️ O WORKBOOK SAPHIRA não define um padrão específico para Objetos de Bloqueio (Lock Objects) — não há linha equivalente na seção 4 (Dicionário de Dados). O nome sugerido acima segue apenas a regra técnica obrigatória do SAP (todo lock object começa com `E`) dentro do namespace `/ACHE/`. Confirme com o COE (André Alvarez / Eder Marcelino) antes de criar, para alinhar com qualquer padrão interno não documentado no workbook.

> Por que dois objetos de bloqueio e não um genérico: a EF diferencia explicitamente os campos de bloqueio mensal (inclui `MONAT`) dos anuais (sem `MONAT`) — um único objeto de bloqueio com campo opcional geraria granularidade errada (bloquearia o ano inteiro mesmo em regra mensal, ou vice-versa).

> **Por que isso é uma melhoria em relação ao legado (V4)**: a FM `YYPCL_DETERMINA_LOTE` usava dois mecanismos de lock diferentes e assimétricos — `ENQUEUE_EY_YYPCL_CNTLOTE`/`DEQUEUE_EY_YYPCL_CNTLOTE` explícito no branch mensal, e um `SELECT SINGLE FOR UPDATE` implícito no branch anual (sem `DEQUEUE` correspondente — o lock só se soltava no `COMMIT WORK` do chamador). Pior: no branch mensal, se o `SELECT` do contador viesse vazio, o `DEQUEUE` **nunca era chamado** — lock vazado. A V4 usa dois objetos de bloqueio explícitos e simétricos, com `DEQUEUE` garantido em **todo** caminho de saída (sucesso ou erro) — ver seção 5.2.

---

## 4. Passo 4 — Criar a classe de mensagens `/ACHE/MM_LOTE`

1. Abra **SE91**.
2. Classe de mensagens: `/ACHE/MM_LOTE` (padrão WORKBOOK SAPHIRA §7 — `/ACHE/XX_<Descrição>`).
3. Cadastre as mensagens conforme a EF (seção 2.6), mantendo a numeração 001–007:

| Nº | Tipo | Texto | Quando ocorre |
|---|---|---|---|
| 001 | E | Tipo de material &1 sem regra de geração de lote. | Não existe registro em `/ACHE/I_MMCDS_1001` para o `MTART`. |
| 002 | E | Grupo &1 sem estrutura de lote parametrizada. | Não existe registro em `/ACHE/I_MMCDS_1002` para o grupo. |
| 003 | E | Contador de lote não mantido para grupo &1, ano &2, mês &3. | Não existe linha de contador em `/ACHE/I_MMCDS_1003` ou `/ACHE/I_MMCDS_1004` para o período. |
| 004 | E | Não foi possível bloquear o range de lote. Tente novamente. | `ENQUEUE` do contador falhou (`sy-subrc <> 0`, `FOREIGN_LOCK`). |
| 005 | E | Range de lote esgotado para grupo &1 no período &2. | Sequencial atingiu o limite máximo configurado (99999 / 999999 / 99999999). |
| 006 | E | Não foi possível determinar lote automático para o material &1. | Erro genérico tratado (fallback). |
| 007 | I | Lote manual informado. Geração automática não executada. | Campo de lote já preenchido — usar somente em log, quando aplicável; **não é bloqueante**. |

> Regra da EF: mensagens de erro (tipo E, 001–006) devem ser bloqueantes quando impedem rastreabilidade ou geração segura do lote. A mensagem 007 é informativa e **não deve interromper** o processo — ela documenta que a preservação de lote manual ocorreu, nada mais.

---

## 5. Passo 5 — Construir a função central de determinação

Esta é a peça principal do seu desenvolvimento — tudo mais (BAdI, coletor) só chama esta função.

1. Abra **SE37** → crie o grupo de funções `/ACHE/MMGF_LOTE` (WORKBOOK SAPHIRA §3.4) se ainda não existir um adequado.
2. Crie a function module `/ACHE/MMF_LOTE_DETERMINAR` (WORKBOOK SAPHIRA §3.4 — `/ACHE/XXF_<Descrição>`).

### 5.1 Assinatura sugerida

Parâmetros seguem o prefixo do WORKBOOK SAPHIRA §8.5 (`I_`/`E_` em vez de `IV_`/`EV_`).

**Mudança na V4**: a FM legada `YYPCL_DETERMINA_LOTE` recebe `YYMTART` diretamente e **nunca usa `YYMATNR`** em lugar nenhum do corpo — o material em si nunca entrou na regra de determinação, só o tipo de material. Também nunca usa centro (plant). Por fidelidade ao comportamento validado pelo negócio, a assinatura abaixo recebe `I_MTART` diretamente; `I_MATNR`/`I_WERKS` ficam como opcionais só para eventual log/rastreabilidade — a lógica de determinação, como no legado, não os utiliza.

```abap
FUNCTION /ache/mmf_lote_determinar.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(I_MTART) TYPE  MTART
*"     REFERENCE(I_DATA_BASE) TYPE  SY-DATUM
*"     REFERENCE(I_LOTE_INFORMADO) TYPE  CHARG_D OPTIONAL
*"     REFERENCE(I_MATNR) TYPE  MATNR OPTIONAL   " não usado na determinação — fiel ao legado, só para log
*"     REFERENCE(I_WERKS) TYPE  WERKS_D OPTIONAL  " reservado; legado nunca usa centro
*"  EXPORTING
*"     REFERENCE(E_LOTE) TYPE  CHARG_D
*"     REFERENCE(E_STATUS) TYPE  CHAR1 " 'S' sucesso, 'N' não aplicável (lote já informado), 'E' erro
*"     REFERENCE(E_MSG) TYPE  BAPI_MSG
*"  EXCEPTIONS
*"      SEM_PARAMETRIZACAO
*"      SEM_ESTRUTURA
*"      CONTADOR_INEXISTENTE
*"      LOCK_INDISPONIVEL
*"      RANGE_ESGOTADO
*"      ERRO_GERAL
*"----------------------------------------------------------------------
```

> Isso também simplifica a chamada a partir da BAdI AFTER (seção 7.5): passe `batch_allocation-material_type` diretamente como `i_mtart`, sem precisar de um `SELECT` intermediário em `I_Material`.

### 5.2 Corpo da função — porte fiel da lógica legada, campos e tabelas novos

Esta seção foi reescrita na V4 a partir do código-fonte real de `YYPCL_DETERMINA_LOTE`, não mais de um pseudocódigo genérico. A tabela abaixo resume exatamente o que é **fidelidade ao legado** (preservar o comportamento de negócio já validado) e o que é **correção deliberada** (bugs reais do legado que a EF exige corrigir):

| Ponto | Legado (`YYPCL_DETERMINA_LOTE`) | V4 | Motivo |
|---|---|---|---|
| Busca de grupo/estrutura | `FOR ALL ENTRIES` + tabela interna + `SORT` + `READ TABLE INDEX 1` | `SELECT SINGLE` direto | `MTART` e `GRPMA` são chave única nas CDS novas — o workaround de ordenação não é mais necessário |
| Lock no branch mensal | `ENQUEUE_EY_YYPCL_CNTLOTE` / `DEQUEUE_EY_YYPCL_CNTLOTE`, mas **`DEQUEUE` não é chamado se o contador vier vazio** (lock vazado) | `ENQUEUE`/`DEQUEUE` simétricos, `DEQUEUE` garantido em todo caminho de saída | Bug real do legado; a EF exige liberação mesmo em erro tratado |
| Lock no branch anual | `SELECT SINGLE FOR UPDATE` implícito, sem `DEQUEUE` (libera só no `COMMIT WORK` do chamador) | Objeto de bloqueio explícito `/ACHE/EMMLOTEANO`, com `DEQUEUE` garantido | Uniformiza o mecanismo de lock entre os dois branches, elimina dependência do timing de commit do chamador |
| Validação de range | **Não existe** — sequencial pode crescer indefinidamente | `IF lv_seq > lv_seq_limite` antes de montar o lote e a cada nova tentativa de duplicidade | EF seção 2.5 e CTN05 exigem isso explicitamente; é requisito novo, não presente no legado |
| Exceção "tipo sem parametrização" | `NOT_FOUND` é declarada mas **nunca é levantada** em nenhum ponto do código | `RAISE sem_parametrizacao` de fato, com mensagem `001` | Correção de lacuna do legado |
| Verificação de duplicidade | `SELECT charg FROM mcha WHERE charg = yycharg` (tabela raw) | Recomendado: `I_BatchPlant`/`I_BatchCrossPlant` (Released, Clean Core) | EF seção 1.8.1 |
| Fórmula de montagem do lote (YY/MM/sequencial por `SEQLOTE`) | Ver seção 5.3 abaixo | **Idêntica ao legado** | Regra de negócio validada — não é bug, é para preservar |
| Persistência do contador | `TABLES: yypcl_cntlote(mes)` + `MODIFY` implícito (sintaxe clássica, obsoleta) | `MODIFY /ache/mmt10x FROM ls_contador` (Open SQL moderno) | `TABLES:` para acesso a dados é considerado obsoleto desde ABAP 7.40+ |

> **Atenção — nomes de campo da CDS ≠ nomes de campo da tabela física.** As CDS Views `/ACHE/I_MMCDS_1001` a `1004` **renomeiam** os campos ao expor (`gjahr as FiscalYear`, `grpma as MaterialGroup`, `mtart as MaterialType`, `seqlote as BatchNumericLength`, `seqmensal as MonthlyBreak`, `seq05/06/08 as Sequence05/06/08` — confirme pelos prints das CDS). Ou seja: **todo `SELECT` feito na CDS usa os nomes em inglês** (`materialgroup`, `materialtype`, `fiscalyear`, `fiscalperiod`, `sequence05/06/08`, `batchnumericlength`, `monthlybreak`); **todo `MODIFY` feito na tabela física** (`/ache/mmt103`/`/ache/mmt104`) **usa os nomes técnicos curtos** (`grpma`, `gjahr`, `monat`, `seq05/06/08`). São dois "alfabetos" de nome para o mesmo dado — o código abaixo lê num, calcula, e só **traduz campo a campo** pro outro na hora de gravar. Não dá pra usar a estrutura da CDS direto num `MODIFY` da tabela.

```abap
  DATA: lv_grpma         TYPE /ache/mmt100-grpma,   " confirmar elemento de dados exato com o dev do RAP App
        ls_agruplotes    TYPE /ache/i_mmcds_1002,    " lido via CDS — campos: materialgroup, batchnumericlength, monthlybreak
        ls_cntlotemes    TYPE /ache/i_mmcds_1003,    " lido via CDS — campos: fiscalyear, fiscalperiod, materialgroup, sequence05/06/08
        ls_cntlote       TYPE /ache/i_mmcds_1004,    " lido via CDS — campos: fiscalyear, materialgroup, sequence05/06/08
        ls_cntlotemes_db TYPE /ache/mmt103,          " estrutura da TABELA física — só para o MODIFY final
        ls_cntlote_db    TYPE /ache/mmt104,          " idem
        lv_gjahr         TYPE gjahr,
        lv_monat         TYPE monat,
        lv_seq_limite    TYPE i,
        lv_lote          TYPE charg_d,
        lv_existe        TYPE abap_bool.

  CLEAR: e_lote, e_status, e_msg.

* ------------------------------------------------------------------
* REGRA 1 (obrigatória, primeira validação): preservar lote manual.
* Se o lote já veio preenchido, o enhancement NUNCA altera, recalcula
* ou sobrescreve o valor. Sai imediatamente.
* ------------------------------------------------------------------
  IF i_lote_informado IS NOT INITIAL.
    e_lote   = i_lote_informado.
    e_status = 'N'.
    MESSAGE i007(/ache/mm_lote) INTO e_msg. "log informativo, não bloqueante
    RETURN.
  ENDIF.

  TRY.
* ------------------------------------------------------------------
* Buscar grupo de regra por tipo de material.
* Réplica de: SELECT * FROM yypcl_agrupmtart WHERE mtart = yymtart.
* (legado usava FOR ALL ENTRIES + tabela interna porque YYMTART podia,
* em tese, casar com mais de uma linha; como MTART é chave única em
* /ACHE/I_MMCDS_1001, SELECT SINGLE é equivalente e mais simples.)
* ------------------------------------------------------------------
  SELECT SINGLE materialgroup FROM /ache/i_mmcds_1001
    INTO lv_grpma
    WHERE materialtype = i_mtart.
  IF sy-subrc <> 0.
    e_status = 'E'.
    MESSAGE e001(/ache/mm_lote) WITH i_mtart INTO e_msg.
    RAISE sem_parametrizacao.
    " nota: a FM legada declarava a exceção NOT_FOUND mas não a
    " levantava em nenhum ponto do código-fonte — isto é uma correção
    " deliberada em relação ao legado, não uma fidelidade a ele.
  ENDIF.

* ------------------------------------------------------------------
* Buscar estrutura do lote (mensal/anual, tamanho do sequencial).
* Réplica de: SELECT * FROM yypcl_agruplotes WHERE zzgrpma = ...
* (legado fazia SORT + READ TABLE INDEX 1 por causa do FOR ALL
* ENTRIES; MATERIALGROUP é chave única em /ACHE/I_MMCDS_1002, então
* SELECT SINGLE substitui o workaround sem mudar o resultado.)
* ------------------------------------------------------------------
  SELECT SINGLE * FROM /ache/i_mmcds_1002
    INTO ls_agruplotes
    WHERE materialgroup = lv_grpma.
  IF sy-subrc <> 0.
    e_status = 'E'.
    MESSAGE e002(/ache/mm_lote) WITH lv_grpma INTO e_msg.
    RAISE sem_estrutura.
  ENDIF.

  lv_gjahr = i_data_base(4).
  lv_monat = i_data_base+4(2).

* ------------------------------------------------------------------
* Determinar o limite de range conforme SEQLOTE (novo em relação ao
* legado — EF seção 2.5 / CTN05, sem equivalente na FM original).
* Confirme o tamanho exato de SEQ05/SEQ06/SEQ08 no Dictionary antes
* de fixar estes limites (ver aviso na seção 2.2 deste guia).
* ------------------------------------------------------------------
  CASE ls_agruplotes-batchnumericlength.
    WHEN '5'. lv_seq_limite = 99999.
    WHEN '6'. lv_seq_limite = 999999.
    WHEN '8'. lv_seq_limite = 99999999.
    WHEN OTHERS.
      e_status = 'E'.
      MESSAGE e002(/ache/mm_lote) WITH lv_grpma INTO e_msg.
      RAISE sem_estrutura.
  ENDCASE.

* ------------------------------------------------------------------
* Bloquear + ler contador + montar lote (mensal ou anual).
* Réplica de: IF NOT it_yypcl_agruplotes-zzseqmensal IS INITIAL.
* Lock/DEQUEUE continuam usando os nomes de campo da TABELA física
* (lv_grpma/lv_gjahr/lv_monat), porque o objeto de bloqueio foi
* criado em cima de /ache/mmt103//ache/mmt104, não da CDS.
* ------------------------------------------------------------------
  IF ls_agruplotes-monthlybreak IS NOT INITIAL.

    CALL FUNCTION '/ACHE/ENQUEUE_EMMLOTEMES'   " confirmar nome exato gerado pela SE11
      EXPORTING
        mandt   = sy-mandt
        grpma   = lv_grpma
        gjahr   = lv_gjahr
        monat   = lv_monat
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      e_status = 'E'.
      MESSAGE e004(/ache/mm_lote) INTO e_msg.
      RAISE lock_indisponivel.
    ENDIF.

    SELECT SINGLE * FROM /ache/i_mmcds_1003
      INTO ls_cntlotemes
      WHERE materialgroup = lv_grpma AND fiscalyear = lv_gjahr AND fiscalperiod = lv_monat.
    IF sy-subrc <> 0.
      " Correção V4: no legado, este DEQUEUE não era chamado quando o
      " SELECT vinha vazio (lock vazado). Aqui é sempre chamado.
      CALL FUNCTION '/ACHE/DEQUEUE_EMMLOTEMES'
        EXPORTING mandt = sy-mandt grpma = lv_grpma gjahr = lv_gjahr monat = lv_monat.
      e_status = 'E'.
      MESSAGE e003(/ache/mm_lote) WITH lv_grpma lv_gjahr lv_monat INTO e_msg.
      RAISE contador_inexistente. " ou criar contador zerado — decisão de arquitetura, ver seção 6
    ENDIF.

    PERFORM f_montar_lote_mensal USING ls_agruplotes-batchnumericlength lv_gjahr lv_monat
                                 CHANGING ls_cntlotemes lv_lote.

  ELSE.

    CALL FUNCTION '/ACHE/ENQUEUE_EMMLOTEANO'   " confirmar nome exato gerado pela SE11
      EXPORTING
        mandt = sy-mandt
        grpma = lv_grpma
        gjahr = lv_gjahr
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      e_status = 'E'.
      MESSAGE e004(/ache/mm_lote) INTO e_msg.
      RAISE lock_indisponivel.
    ENDIF.

    SELECT SINGLE * FROM /ache/i_mmcds_1004
      INTO ls_cntlote
      WHERE materialgroup = lv_grpma AND fiscalyear = lv_gjahr.
    IF sy-subrc <> 0.
      CALL FUNCTION '/ACHE/DEQUEUE_EMMLOTEANO'
        EXPORTING mandt = sy-mandt grpma = lv_grpma gjahr = lv_gjahr.
      e_status = 'E'.
      MESSAGE e003(/ache/mm_lote) WITH lv_grpma lv_gjahr '' INTO e_msg.
      RAISE contador_inexistente.
    ENDIF.

    PERFORM f_montar_lote_anual USING ls_agruplotes-batchnumericlength lv_gjahr
                                CHANGING ls_cntlote lv_lote.

  ENDIF.

* ------------------------------------------------------------------
* Validar range + duplicidade — enquanto existir ou passar do limite.
* Réplica do WHILE de duplicidade do legado (lá contra MCHA; aqui,
* recomendado contra I_BatchPlant/I_BatchCrossPlant — Clean Core,
* EF seção 1.8.1). Validação de range é ADIÇÃO da V4 (ver tabela acima).
* ------------------------------------------------------------------
  PERFORM f_lote_existe USING lv_lote CHANGING lv_existe.
  WHILE lv_existe = abap_true.

    DATA(lv_seq_atual) = COND i( WHEN ls_agruplotes-monthlybreak IS NOT INITIAL THEN
                                   COND #( WHEN ls_agruplotes-batchnumericlength = '5' THEN ls_cntlotemes-sequence05
                                           WHEN ls_agruplotes-batchnumericlength = '6' THEN ls_cntlotemes-sequence06
                                           WHEN ls_agruplotes-batchnumericlength = '8' THEN ls_cntlotemes-sequence08 )
                                 ELSE
                                   COND #( WHEN ls_agruplotes-batchnumericlength = '5' THEN ls_cntlote-sequence05
                                           WHEN ls_agruplotes-batchnumericlength = '6' THEN ls_cntlote-sequence06
                                           WHEN ls_agruplotes-batchnumericlength = '8' THEN ls_cntlote-sequence08 ) ).

    IF lv_seq_atual >= lv_seq_limite.
      IF ls_agruplotes-monthlybreak IS NOT INITIAL.
        CALL FUNCTION '/ACHE/DEQUEUE_EMMLOTEMES'
          EXPORTING mandt = sy-mandt grpma = lv_grpma gjahr = lv_gjahr monat = lv_monat.
      ELSE.
        CALL FUNCTION '/ACHE/DEQUEUE_EMMLOTEANO'
          EXPORTING mandt = sy-mandt grpma = lv_grpma gjahr = lv_gjahr.
      ENDIF.
      e_status = 'E'.
      MESSAGE e005(/ache/mm_lote) WITH lv_grpma lv_gjahr INTO e_msg.
      RAISE range_esgotado.
    ENDIF.

    IF ls_agruplotes-monthlybreak IS NOT INITIAL.
      PERFORM f_montar_lote_mensal USING ls_agruplotes-batchnumericlength lv_gjahr lv_monat
                                   CHANGING ls_cntlotemes lv_lote.
    ELSE.
      PERFORM f_montar_lote_anual USING ls_agruplotes-batchnumericlength lv_gjahr
                                  CHANGING ls_cntlote lv_lote.
    ENDIF.

    PERFORM f_lote_existe USING lv_lote CHANGING lv_existe.
  ENDWHILE.

* ------------------------------------------------------------------
* Persistir contador (dentro da mesma LUW do processo chamador —
* SEM COMMIT WORK próprio, conforme premissa da EF). Substitui o
* MODIFY implícito via TABLES: do legado por Open SQL direto.
*
* IMPORTANTE: ls_cntlotemes/ls_cntlote são estruturas da CDS (campos
* em inglês) — não dá pra usar direto num MODIFY da tabela física
* (campos técnicos). Traduz campo a campo antes de gravar.
* ------------------------------------------------------------------
  IF ls_agruplotes-monthlybreak IS NOT INITIAL.
    CLEAR ls_cntlotemes_db.
    ls_cntlotemes_db-mandt = sy-mandt.
    ls_cntlotemes_db-gjahr = ls_cntlotemes-fiscalyear.
    ls_cntlotemes_db-monat = ls_cntlotemes-fiscalperiod.
    ls_cntlotemes_db-grpma = ls_cntlotemes-materialgroup.
    ls_cntlotemes_db-seq05 = ls_cntlotemes-sequence05.
    ls_cntlotemes_db-seq06 = ls_cntlotemes-sequence06.
    ls_cntlotemes_db-seq08 = ls_cntlotemes-sequence08.
    MODIFY /ache/mmt103 FROM ls_cntlotemes_db.
    CALL FUNCTION '/ACHE/DEQUEUE_EMMLOTEMES'
      EXPORTING mandt = sy-mandt grpma = lv_grpma gjahr = lv_gjahr monat = lv_monat.
  ELSE.
    CLEAR ls_cntlote_db.
    ls_cntlote_db-mandt = sy-mandt.
    ls_cntlote_db-gjahr = ls_cntlote-fiscalyear.
    ls_cntlote_db-grpma = ls_cntlote-materialgroup.
    ls_cntlote_db-seq05 = ls_cntlote-sequence05.
    ls_cntlote_db-seq06 = ls_cntlote-sequence06.
    ls_cntlote_db-seq08 = ls_cntlote-sequence08.
    MODIFY /ache/mmt104 FROM ls_cntlote_db.
    CALL FUNCTION '/ACHE/DEQUEUE_EMMLOTEANO'
      EXPORTING mandt = sy-mandt grpma = lv_grpma gjahr = lv_gjahr.
  ENDIF.

  e_lote   = lv_lote.
  e_status = 'S'.

  CATCH cx_root INTO DATA(lx_root).
* ------------------------------------------------------------------
* Rede de segurança para a mensagem/exceção 006 (ERRO_GERAL), que a
* EF prevê (seção 2.6) como fallback para erro genérico tratado. Sem
* este TRY/CATCH, ERRO_GERAL ficava declarada na assinatura mas nunca
* era de fato levantada — mesmo tipo de furo que o NOT_FOUND do
* legado, só que este era meu, não do código original. Cobre, por
* exemplo, erro de conversão ao fatiar I_DATA_BASE ou overflow ao
* incrementar o contador.
* ------------------------------------------------------------------
    e_status = 'E'.
    MESSAGE e006(/ache/mm_lote) WITH i_mtart INTO e_msg.
    RAISE erro_geral.
  ENDTRY.

ENDFUNCTION.
```

> **O `TRY`/`CATCH cx_root` acima envolve toda a lógica a partir da busca de grupo de regra** (não reproduzi a reindentação de cada linha no bloco de código deste guia para não inflar demais o diff — ao codificar de verdade, rode o **Pretty Printer** do ABAP para reindentar corretamente dentro do `TRY`). O ponto importante é a estrutura: tudo entre `TRY.` e o `CATCH cx_root` fica dentro do bloco protegido, e qualquer exceção de runtime não tratada (`CX_SY_*` etc.) cai no fallback de `ERRO_GERAL` em vez de estourar sem controle.

> **Não faça `COMMIT WORK` dentro desta função.** A EF (seção 1.5) é explícita: o enhancement deve respeitar a LUW do processo SAP que o chamou (MIGO, ordem de processo, coletor). Um commit próprio aqui quebraria o tratamento de erro do processo standard e poderia liberar o lock antes da hora. O `MODIFY` acima grava no buffer da LUW atual; o `COMMIT` é responsabilidade do processo chamador.

> **`MODIFY /ache/mmt10x` grava direto na tabela física, não pela CDS.** Pergunte ao dev do RAP App se existe alguma validação/ação exposta pelo BO que você deveria usar em vez de escrever direto na tabela — isso evita pular alguma regra que o app de manutenção dele espera garantir.

### 5.3 Fórmula de montagem do lote — fiel ao legado, inclusive a assimetria

Este é o ponto mais importante para preservar o comportamento de negócio: **o mês só entra na composição do lote quando `SEQLOTE = '6'` E o grupo é mensal.** No branch anual, mesmo com `SEQLOTE = '6'`, o mês **não** entra — exatamente como no código legado (confira: no branch `ELSE` do legado, o `CASE '6'` concatena só `yydatum+2(2)` + contador, sem `yydatum+4(2)`).

> As `FORM`s abaixo recebem/alteram a estrutura **da CDS** (`ls_cntlotemes`/`ls_cntlote`, campos em inglês), não a da tabela física — a tradução pra tabela só acontece uma vez, no `MODIFY` final (seção 5.2). `SEQLOTE`/`SEQMENSAL` na tabela = `BatchNumericLength`/`MonthlyBreak` na CDS (seção 2.1).

| `SEQMENSAL` (`MonthlyBreak`) | `SEQLOTE` (`BatchNumericLength`) | Fórmula (legado, preservada na V4) | Campo de contador (nome CDS) |
|---|---|---|---|
| Mensal (`X`) | `5` | `YY` + `SEQ05` | `ls_cntlotemes-sequence05` |
| Mensal (`X`) | `6` | `YY` + `MM` + `SEQ06` | `ls_cntlotemes-sequence06` |
| Mensal (`X`) | `8` | `YY` + `SEQ08` | `ls_cntlotemes-sequence08` |
| Anual (vazio) | `5` | `YY` + `SEQ05` | `ls_cntlote-sequence05` |
| Anual (vazio) | `6` | `YY` + `SEQ05`* | `ls_cntlote-sequence06` |
| Anual (vazio) | `8` | `YY` + `SEQ08` | `ls_cntlote-sequence08` |

\* Sim, `SEQLOTE = '6'` no branch anual usa a mesma fórmula de 2 campos (`YY` + sequencial) que o `'5'` e o `'8'` — a diferença de 5/6/8 dígitos nesse caso vem do comprimento do próprio campo `SEQ05`/`SEQ06`/`SEQ08` (zero-pad do tipo NUMC), não da composição. **Confirme o comprimento exato desses campos no Dictionary** (aviso na seção 2.2) antes de considerar isso fechado — é a única suposição desta seção que não vem 100% literal do código-fonte, porque o comprimento do campo não aparece no código, só o resultado do `CONCATENATE`.

```abap
FORM f_montar_lote_mensal USING    u_seqlote     TYPE /ache/i_mmcds_1002-batchnumericlength
                                    u_gjahr       TYPE gjahr
                                    u_monat       TYPE monat
                           CHANGING c_cntlotemes  TYPE /ache/i_mmcds_1003
                                    c_lote        TYPE charg_d.

  CASE u_seqlote.
    WHEN '5'.
      c_cntlotemes-sequence05 = c_cntlotemes-sequence05 + 1.
      CONCATENATE u_gjahr+2(2) c_cntlotemes-sequence05 INTO c_lote.
    WHEN '6'.
      c_cntlotemes-sequence06 = c_cntlotemes-sequence06 + 1.
      CONCATENATE u_gjahr+2(2) u_monat c_cntlotemes-sequence06 INTO c_lote.
    WHEN '8'.
      c_cntlotemes-sequence08 = c_cntlotemes-sequence08 + 1.
      CONCATENATE u_gjahr+2(2) c_cntlotemes-sequence08 INTO c_lote.
  ENDCASE.

ENDFORM.

FORM f_montar_lote_anual USING    u_seqlote  TYPE /ache/i_mmcds_1002-batchnumericlength
                                   u_gjahr    TYPE gjahr
                          CHANGING c_cntlote  TYPE /ache/i_mmcds_1004
                                   c_lote     TYPE charg_d.

  CASE u_seqlote.
    WHEN '5'.
      c_cntlote-sequence05 = c_cntlote-sequence05 + 1.
      CONCATENATE u_gjahr+2(2) c_cntlote-sequence05 INTO c_lote.
    WHEN '6'.
      c_cntlote-sequence06 = c_cntlote-sequence06 + 1.
      CONCATENATE u_gjahr+2(2) c_cntlote-sequence06 INTO c_lote.   " sem mês, fiel ao legado
    WHEN '8'.
      c_cntlote-sequence08 = c_cntlote-sequence08 + 1.
      CONCATENATE u_gjahr+2(2) c_cntlote-sequence08 INTO c_lote.
  ENDCASE.

ENDFORM.
```

> Note que `u_gjahr` aqui é o ano completo (`GJAHR`, 4 dígitos) e o legado usa `yydatum+2(2)` (2 últimos dígitos do ano a partir da data, não do `GJAHR` já calculado) — no seu `FUNCTION` principal, `lv_gjahr` já foi derivado de `i_data_base(4)`, então para reproduzir exatamente `yydatum+2(2)` você deve concatenar `lv_gjahr+2(2)`, não `lv_gjahr` inteiro. Ajustei as `FORM`s acima para receber `u_gjahr` como o campo `GJAHR` completo e fatiar `+2(2)` internamente — confirme que esse fatiamento bate com o formato de `GJAHR` da CDS antes de codificar (`GJAHR` normalmente é `NUMC(4)`, então `+2(2)` extrai os 2 últimos dígitos corretamente, igual ao legado).

### 5.4 Verificação de duplicidade

```abap
FORM f_lote_existe USING    u_lote   TYPE charg_d
                   CHANGING c_existe TYPE abap_bool.

  DATA lv_charg TYPE charg_d.

* Legado verificava direto contra MCHA. Recomendado pela EF (seção
* 1.8.1, Clean Core): usar o objeto Released equivalente.
  SELECT SINGLE batch FROM i_batchplant     " ou I_BatchCrossPlant, conforme escopo (por centro x todos os centros)
    INTO lv_charg
    WHERE batch = u_lote.

  c_existe = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

ENDFORM.
```

> **Sempre libere o lock**, inclusive no caminho de erro (a EF exige isso explicitamente na "Regra de Concorrência": *"O bloqueio deverá ser liberado mesmo em caso de erro tratado"*). No corpo da função acima, todo `RAISE` depois do `ENQUEUE` é precedido por um `DEQUEUE` correspondente — isso corrige o bug real que existia no legado (ver tabela no início da seção 5.2).

---

## 6. Passo 6 — Decisão de arquitetura pendente: contador inexistente

A EF deixa esse ponto em aberto (pseudocódigo, seção 2.5): *"Se contador não existir: Emitir erro bloqueante **ou** criar contador inicial conforme decisão de arquitetura."*

Isso precisa ser decidido (por você + arquitetura/cliente) antes de fechar o desenvolvimento:

- **Opção A (mais segura, alinhada ao restante da EF)**: contador inexistente é sempre erro bloqueante (mensagem `003` da classe `/ACHE/MM_LOTE`), e a criação do registro de contador para o período é responsabilidade da manutenção via app Fiori (RAP App do outro desenvolvedor). Isso é consistente com a premissa da EF de que "o usuário final não deverá possuir autorização para alterar diretamente contadores de lote" — ou seja, a criação de contador deve ser um ato deliberado de parametrização, não um efeito colateral automático do primeiro lote do período.
- **Opção B**: a função central cria o contador zerado na primeira chamada do período. Mais conveniente, mas foge do controle de parametrização restrita mencionado na EF (seção 2.7).

Recomendação: **Opção A**, por aderência à seção 2.7 da EF ("manutenção das tabelas de parametrização restrita a usuários autorizados"). Confirme essa leitura com o arquiteto do projeto antes de implementar — é uma decisão de negócio, não só técnica.

---

## 7. Passo 7 — Implementar as BAdIs BEFORE + AFTER (Entrada de Mercadoria + Ordem de Processo)

Esta seção foi reescrita na V3 do guia a partir do template real gerado pela SE24 no sistema (a suposição da V1/V2 sobre a assinatura estava incorreta — o método `BEFORE_NUMBER_ASSIGNMENT` **não** te dá um campo para preencher o lote diretamente).

### 7.1 Localizar e validar a assinatura do BEFORE

1. Abra **SE18**.
2. Enhancement Spot: `LOBM_BATCH_EXT` → **Exibir**.
3. Localize a BAdI Definition `LOBM_BEFORE_BATCH_NUMBER_INT`.
4. Abra a interface associada via **SE24**: `IF_LOBM_BEFORE_BATCH_NMBR_INT`, método `BEFORE_NUMBER_ASSIGNMENT`.

Assinatura real (confirmada em sistema):

| Parâmetro | Tipo | Direção | Descrição |
|---|---|---|---|
| `BATCH_ALLOCATION` | `IF_LOBM_BATCH_NUMBER=>TY_BATCH_ALLOCATION` | Importing | Dados da aplicação do cenário (material, centro, grupo de material, ordem de venda etc.) |
| `INTERNALNUMBERASSGMTISSKIPPED` | `BATCH_NO_INT_NUMBER_ASSIGNMENT` | Changing | Indica se a numeração interna standard deve ser pulada |
| `CUSTOMBONUMBERASSGMTISSKIPPED` | `BATCH_NO_INT_NUMBER_ASSIGNMENT` OPTIONAL | Changing | Indica se a numeração interna via Custom Business Object deve ser pulada |
| `NUMBERRANGE` | `IF_LOBM_BATCH_NUMBER=>TY_NUMBER_RANGE` OPTIONAL | Changing | Range de número a usar, **se** você optar por deixar o SAP standard gerar (não é o seu caso — ver abaixo) |
| `CX_BLE_RUNTIME_ERROR` | — | Raising | Exceção para re-sinalizar erro da extensão |

**O que isso muda na prática**: este método não serve para "escrever o lote". Ele serve para **desviar o SAP standard do caminho dele**, avisando que a numeração interna (e a de Custom BO) não deve rodar para este material — porque quem vai determinar o lote é a sua lógica Aché, na BAdI **AFTER** (seção 7.5).

> **Antes de codificar**: dê duplo clique em `IF_LOBM_BATCH_NUMBER=>TY_BATCH_ALLOCATION` na SE24 e confirme os nomes exatos dos componentes (material, centro, tipo de material, lote já atribuído se houver etc.) — o esqueleto abaixo usa nomes prováveis (`-material`, `-plant`, `-material_type`) que **precisam ser conferidos**, não assuma.

### 7.2 Código do método BEFORE — decidir se pula a numeração standard

```abap
METHOD if_lobm_before_batch_nmbr_int~before_number_assignment.

  DATA: lv_grpma TYPE /ache/mmt100-grpma.   " confirmar elemento de dados com o dev do RAP App

* ------------------------------------------------------------------
* Só desvia o SAP standard se o tipo de material estiver parametrizado
* para geração automática Aché. Se não estiver, não faz nada — deixa
* o SAP standard seguir o fluxo normal dele.
* Nomes de campo em inglês porque a leitura é via CDS (seção 2.1) —
* não confunda com os nomes técnicos da tabela física.
* ------------------------------------------------------------------
  SELECT SINGLE materialgroup FROM /ache/i_mmcds_1001
    INTO lv_grpma
    WHERE materialtype = batch_allocation-material_type.       " nome do componente a confirmar via SE24

  IF sy-subrc = 0.
* Material parametrizado para lote Aché: ninguém mais deve gerar o
* número (nem numeração interna standard, nem Custom BO). O valor
* definitivo é calculado na BAdI AFTER (seção 7.5), chamando a função
* central.
    internalnumberassgmtisskipped = abap_true.
    custombonumberassgmtisskipped = abap_true.
  ENDIF.

ENDMETHOD.
```

> **Sobre a regra de preservação de lote manual**: você não precisa checar aqui "o lote já está preenchido?" — o próprio SAP só aciona esta BAdI quando a numeração interna *seria* necessária, ou seja, quando o lote **ainda está vazio** e o material está configurado para numeração interna. Se o lote já veio manual, o SAP nem chama este método. Ainda assim, confirme esse comportamento no seu release (via teste, seção 10) antes de assumir como garantido.

> Este método não deveria, na prática, lançar `CX_BLE_RUNTIME_ERROR` — a única coisa que ele faz é um `SELECT SINGLE` de leitura. Se quiser blindar contra erro inesperado, envolva em `TRY/CATCH` e relance como `CX_BLE_RUNTIME_ERROR`, mas isso é opcional aqui (o tratamento de erro "de verdade" acontece no AFTER, seção 7.5).

### 7.3 Criar a implementação (cobre as duas BAdIs)

1. Abra **SE19**.
2. Tipo de enhancement implementation: **BAdI Nova**, no Enhancement Spot `LOBM_BATCH_EXT`.
3. Nome da implementação: `/ACHE/MM_LOTE_BADI` (WORKBOOK SAPHIRA §5/§9 — `/ACHE/XX_<Descrição>`).
4. Adicione as duas BAdI Definitions do spot à mesma implementação: `LOBM_BEFORE_BATCH_NUMBER_INT` e a BAdI **AFTER** (nome exato a confirmar — seção 7.5). A SE19 normalmente permite agrupar BAdIs do mesmo enhancement spot numa única implementação, com uma classe implementando as duas interfaces.
5. Nome da classe implementadora: `/ACHE/CLMM_LOTE_BADI` (WORKBOOK SAPHIRA §5 — `/ACHE/CLXX_<Descrição>`).
6. Grave, ative.
7. Abra a classe gerada pela **SE24** e implemente os dois métodos (7.2 e 7.5).

### 7.4 Criar a classe wrapper — necessária por restrição de Extensibilidade/Cloud

**Achado em campo**: a implementação da BAdI está sob restrição de linguagem ABAP Cloud/Extensibilidade (coerente com os prints da seção 2 — as CDS estão liberadas com "Use in Cloud Development: Yes" / "Use in Key User Apps: Yes", ou seja, o enhancement spot está no mesmo contrato de release restrito). Nesse modo, o compilador **não deixa** chamar `CALL FUNCTION` de uma function module não liberada diretamente de dentro do método da BAdI.

A solução padrão SAP pra isso é um **wrapper liberado**: uma classe global, escrita em ABAP clássico (que pode conter `CALL FUNCTION` livremente), que você libera formalmente via contrato de release (mesmo mecanismo "Use System-Internally (Contract C1): Released" que aparece na aba **API State** das CDS Views que você me mostrou). Uma vez liberada, a BAdI (Cloud-restrita) pode chamar essa classe normalmente — a restrição é sobre *o que* você chama, não sobre *quem* está escrito em ABAP clássico por trás.

1. Abra **SE24**, crie a classe `/ACHE/CLMM_LOTE_DETERMINAR` (WORKBOOK SAPHIRA §5 — `/ACHE/CLXX_<Descrição>`; nome espelha a FM `/ACHE/MMF_LOTE_DETERMINAR` que ela encapsula).
2. **Language Version da classe**: ABAP clássico (Standard ABAP) — não marque como "ABAP for Cloud Development". É isso que permite o `CALL FUNCTION` dentro dela.
3. Crie um método estático público (ex. `DETERMINAR`) com a mesma assinatura da FM central, **sem** `EXCEPTIONS` clássicas no método (a checagem de erro fica só em `E_STATUS`/`E_MSG`, que o chamador já sabe interpretar):

```abap
CLASS /ache/clmm_lote_determinar DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS determinar
      IMPORTING
        i_mtart          TYPE mtart
        i_data_base      TYPE sy-datum
        i_lote_informado TYPE charg_d OPTIONAL
        i_matnr          TYPE matnr OPTIONAL
        i_werks          TYPE werks_d OPTIONAL
      EXPORTING
        e_lote           TYPE charg_d
        e_status         TYPE char1
        e_msg            TYPE bapi_msg.
ENDCLASS.

CLASS /ache/clmm_lote_determinar IMPLEMENTATION.
  METHOD determinar.
    CALL FUNCTION '/ACHE/MMF_LOTE_DETERMINAR'
      EXPORTING
        i_mtart          = i_mtart
        i_data_base      = i_data_base
        i_lote_informado = i_lote_informado
        i_matnr          = i_matnr
        i_werks          = i_werks
      IMPORTING
        e_lote   = e_lote
        e_status = e_status
        e_msg    = e_msg
      EXCEPTIONS
        sem_parametrizacao   = 1
        sem_estrutura        = 2
        contador_inexistente = 3
        lock_indisponivel    = 4
        range_esgotado       = 5
        erro_geral           = 6
        OTHERS               = 7.
    " Não precisa checar sy-subrc aqui: a função central sempre grava
    " E_STATUS = 'E' antes de qualquer RAISE (seção 5.2) — EXPORTING
    " já vem preenchido mesmo no caminho de exceção clássica.
  ENDMETHOD.
ENDCLASS.
```

4. Grave, ative.
5. **Libere a classe**: no SE24 (ou no ABAP Development Tools), aba de liberação/API state — mesmo mecanismo que a CDS já usa (Contract C1 "Use System-Internally"). Sem isso, a BAdI Cloud-restrita continua sem poder chamar a classe, mesmo ela existindo e estando ativa.

> Isso é só para a **BAdI AFTER** (seção 7.5) — o **Coletor de Recebimento** (seção 8) é desenvolvimento customizado clássico, não está sob a mesma restrição de Extensibilidade, então pode continuar chamando `/ACHE/MMF_LOTE_DETERMINAR` diretamente, sem passar pela classe wrapper.
>
> Isso também pode explicar as classes `/ACHE/CLMM_LOTE01` a `LOTE04` que apareceram no seu pacote e que eu tinha sinalizado como propósito incerto — vale conferir se alguma delas já é exatamente esse tipo de wrapper (talvez uma por CDS, ou uma génerica) antes de criar `/ACHE/CLMM_LOTE_DETERMINAR` do zero, pra não duplicar.

### 7.5 Localizar e implementar a BAdI AFTER — onde o lote é gravado

1. Volte na **SE18**, Enhancement Spot `LOBM_BATCH_EXT`, e localize a BAdI irmã de "after" (o nome provável, por simetria com `LOBM_BEFORE_BATCH_NUMBER_INT`, é `LOBM_AFTER_BATCH_NUMBER_INT` — **confirme o nome exato no seu sistema**, não assuma).
2. Abra a interface associada via **SE24** (provável `IF_LOBM_AFTER_BATCH_NMBR_INT`, método `AFTER_NUMBER_ASSIGNMENT`) e **confirme toda a assinatura antes de codificar** — diferente do BEFORE (que já validamos com print de tela), esta ainda não foi conferida em sistema.

O esqueleto abaixo chama a classe wrapper da seção 7.4 (não a FM diretamente) — é uma expectativa razoável por simetria com o BEFORE (importa/altera `BATCH_ALLOCATION`, permite escrever no campo de lote dentro dela, e usa a mesma exceção `CX_BLE_RUNTIME_ERROR`) — **trate como rascunho até confirmar na SE24**:

```abap
METHOD if_lobm_after_batch_nmbr_int~after_number_assignment.  " nome do método a confirmar

  DATA: lv_lote   TYPE charg_d,
        lv_status TYPE char1,
        lv_msg    TYPE bapi_msg.

  /ache/clmm_lote_determinar=>determinar(
    EXPORTING
      i_mtart          = batch_allocation-material_type    " confirmar nome do componente — mesmo usado no BEFORE (7.2)
      i_data_base      = sy-datum                          " confirmar origem correta por cenário —
                                                            " ver EF seção 2.2, "Campos de Entrada
                                                            " do Serviço" / "Data base"
      i_lote_informado = batch_allocation-batch             " confirmar nome do componente (lote já
                                                            " atribuído até aqui, se houver)
      i_matnr          = batch_allocation-material          " opcional, só para log — confirmar nome do componente
    IMPORTING
      e_lote   = lv_lote
      e_status = lv_status
      e_msg    = lv_msg ).

  IF lv_status = 'E'.
    " Erro bloqueante: propague via a exceção da própria interface.
    " Confirme na SE24 como CX_BLE_RUNTIME_ERROR aceita a mensagem
    " (TEXTID, IF_T100_MESSAGE, ou construtor próprio) para propagar
    " a mensagem da classe /ACHE/MM_LOTE corretamente.
    RAISE EXCEPTION TYPE cx_ble_runtime_error
      EXPORTING
        textid = VALUE #( ).   " ajustar conforme constructor real
  ENDIF.

  IF lv_status = 'S'.
    batch_allocation-batch = lv_lote.   " confirmar nome exato do componente de saída do lote
  ENDIF.
  " status 'N' = lote já era manual, nada a fazer.

ENDMETHOD.
```

### 7.6 Regra de preservação de lote manual — onde ela vive de verdade agora

Na V1/V2 essa checagem existia duas vezes (BAdI + função central). Na V3, o desenho ficou assim:

- **BEFORE**: não precisa checar — o SAP só chama esse método quando o lote ainda está vazio (ver nota na seção 7.2).
- **AFTER**: passa `batch_allocation-batch` (o que estiver ali até aquele ponto) como `i_lote_informado` para a função central — que já faz a checagem obrigatória internamente (seção 5.2) e devolve `status = 'N'` sem recalcular nada se já houver valor. Essa é a garantia real, porque é a mesma função central que o Coletor de Recebimento (seção 8) chama por um caminho de código totalmente diferente.

Não remova a checagem de dentro da função central achando redundante — ela é a única garantia que vale para **todos** os chamadores (BAdI AFTER e Coletor).

---

## 8. Passo 8 — Coletor de Recebimento (reuso, não é BAdI)

A EF (seção 2.4, Enhancement 3) é explícita: esse cenário reutiliza a mesma lógica central, mas é acionado pelo fluxo específico do GAP334/391 — **não** pelo enhancement spot `LOBM_BATCH_EXT`.

Condição de disparo específica deste cenário: o usuário responde **"Sim"** à pergunta **"Deseja gerar Lote Aché?"** ao salvar a tela do Coletor.

Passos:

1. Localize o programa/classe do Coletor de Recebimento (desenvolvimento do GAP334/391). Se não souber o nome exato, use **SE80** → Ferramentas → Localizar objeto do repositório, ou busque no código-fonte pelo texto literal `Deseja gerar Lote Ach` (sem acento, para pegar variações de codificação de caractere).
2. Dentro desse fluxo, localize o ponto onde hoje (se já existir) é chamada `YYPCL_DETERMINA_LOTE` — pelo que a EF e o código-fonte legado indicam, é bem provável que o coletor **já chame essa FM diretamente** hoje. Se for o caso, é uma substituição de chamada 1:1: mesma ideia (`YYMTART`→`I_MTART`, `YYDATUM`→`I_DATA_BASE`, `YYCHARG`→`E_LOTE`), tabelas/campos novos.
3. Substitua (ou insira) a chamada para `/ACHE/MMF_LOTE_DETERMINAR` **diretamente** (o Coletor não está sob a restrição de Cloud/Extensibilidade da BAdI — não precisa passar pela classe wrapper da seção 7.4), com a mesma assinatura usada na BAdI AFTER (seção 7.5 — note que o parâmetro chave agora é `I_MTART`, direto, sem depender de `MATNR`), passando a data-base correta do fluxo do coletor (a EF não especifica qual campo de data o coletor usa — confirme com quem mantém o GAP334/391).
4. Trate os códigos de retorno (`E_STATUS`, exceções) da mesma forma que no BAdI: erro bloqueante impede a gravação da tela do coletor; sucesso preenche o campo de lote.

> **Não assuma** que existe um ponto de extensão formal (BAdI/exit) no fluxo do coletor — a EF avisa que esse fluxo é customizado e pode exigir alteração direta no código do GAP334/391 (dentro do escopo deste enhancement) em vez de um enhancement point. Confirme isso ao abrir o programa.

---

## 9. Passo 9 — Regra de range (estouro de sequencial)

Já coberta na função central (seção 5.2, `lv_seq_limite`), mas os limites conceituais exatos, conforme EF:

| Sequencial | Limite |
|---|---|
| 5 dígitos | 99999 |
| 6 dígitos | 999999 |
| 8 dígitos | 99999999 |

O tamanho aplicável por grupo vem de `SEQLOTE` em `/ACHE/I_MMCDS_1002` (confirmado na seção 2.1 — campo sem prefixo `ZZ`). Ao atingir o limite, bloqueie a geração e emita a mensagem `005` da classe `/ACHE/MM_LOTE` — não tente "dar a volta" (wrap-around) para 1, a EF não prevê isso e criaria duplicidade certa com lotes já emitidos no início do range. **Lembre-se**: essa validação de range **não existe na FM legada** — é um requisito novo da EF (seção 6 do guia já cobria isso, e o mapeamento com o legado confirma que é mesmo uma lacuna a preencher, não uma regra a copiar).

---

## 10. Plano de testes do enhancement (adaptado da EF seção 4)

Estes são os cenários de teste da EF, reescritos com foco no que você testa (a função central + o BAdI + o gatilho do coletor) — não inclui testes do RAP App/Fiori, que são do outro desenvolvedor.

### 10.1 Positivos

| Caso | O que validar | Como testar no seu escopo |
|---|---|---|
| CT01 | Entrada de mercadoria com lote automático | MIGO com material parametrizado, campo lote vazio → lote preenchido, contador incrementado, sem duplicidade |
| CT02 | Ordem de processo com lote automático | Criar ordem de processo, campo lote de produção vazio → lote determinado conforme regra do tipo de material |
| CT03 | Coletor de recebimento com lote automático | Responder "Sim" na pergunta do coletor → lote gerado com mesma regra dos demais processos |
| CT04 | Lote manual não é alterado | Informar lote manualmente em qualquer um dos 3 fluxos → gravado exatamente como informado, função central não executa a lógica de geração |
| CT05 | Sequencial mensal | Grupo com `SEQMENSAL = X` → lote contém ano/mês corretos, contador mensal incrementado |
| CT06 | Sequencial anual | Grupo sem quebra mensal → lote contém ano + sequencial, contador anual incrementado |
| CT07 | Duplicidade de lote | Forçar cenário onde o próximo sequencial calculado já existe como lote → sistema pula e gera o próximo livre, contador final reflete o último valor realmente utilizado (não o primeiro tentado) |

### 10.2 Negativos

| Caso | O que validar | Mensagem esperada |
|---|---|---|
| CTN01 | Tipo de material sem parametrização em `/ACHE/I_MMCDS_1001` | `/ACHE/MM_LOTE` 001, bloqueante |
| CTN02 | Grupo sem estrutura em `/ACHE/I_MMCDS_1002` | `/ACHE/MM_LOTE` 002, bloqueante |
| CTN03 | Contador mensal/anual inexistente para o período | `/ACHE/MM_LOTE` 003, bloqueante (ver decisão de arquitetura, seção 6) |
| CTN04 | Lock do contador indisponível (concorrência — dois processos simultâneos) | `/ACHE/MM_LOTE` 004, bloqueante, sem duplicidade gerada por nenhum dos dois processos |
| CTN05 | Range esgotado (sequencial no limite) | `/ACHE/MM_LOTE` 005, bloqueante |

Para CTN04 especificamente: o teste real exige dois processos concorrentes tentando gerar lote para o **mesmo grupo + mesmo período** ao mesmo tempo (ex. duas sessões MIGO em paralelo). Teste unitário isolado não pega esse cenário — vale simular chamando a função central duas vezes sem liberar o lock da primeira, para confirmar que a segunda chamada recebe `LOCK_INDISPONIVEL` e não trava indefinidamente.

---

## 11. Checklist final antes de considerar o desenvolvimento pronto

- [ ] Pacote definitivo confirmado com o COE (seção 0.1) — `/ACHE/DEV_OLD` é a sugestão, não use `ZDEV` sem aprovação
- [ ] Componentes exatos de `IF_LOBM_BATCH_NUMBER=>TY_BATCH_ALLOCATION` confirmados via SE24 (o guia usa nomes prováveis — seção 7.1)
- [ ] Nome exato da BAdI/interface/método **AFTER** confirmado via SE18/SE24 (o guia assume `LOBM_AFTER_BATCH_NUMBER_INT` / `IF_LOBM_AFTER_BATCH_NMBR_INT` por simetria, não confirmado em sistema — seção 7.5)
- [ ] Construtor de `CX_BLE_RUNTIME_ERROR` confirmado via SE24 — como propagar a mensagem da classe `/ACHE/MM_LOTE` através dessa exceção (seção 7.5)
- [ ] **(V5)** Classe wrapper `/ACHE/CLMM_LOTE_DETERMINAR` (seção 7.4) criada, ativa e **liberada** (API State/Contract C1) — sem a liberação, a BAdI Cloud-restrita continua sem poder chamá-la mesmo com a classe existindo. Confirmar antes se alguma das classes `/ACHE/CLMM_LOTE01`–`LOTE04` já preenche esse papel, pra não duplicar
- [ ] Comportamento confirmado em teste: o SAP realmente não chama `BEFORE_NUMBER_ASSIGNMENT` quando o lote já vem preenchido manualmente (seção 7.2, CT04)
- [ ] Nomes finais das tabelas/CDS de parametrização confirmados com o dev do RAP App (seção 2)
- [ ] Decisão de arquitetura sobre contador inexistente (seção 6) confirmada com o arquiteto/negócio
- [ ] Objetos de bloqueio `/ACHE/EMMLOTEMES` / `/ACHE/EMMLOTEANO` criados, nome confirmado com o COE (workbook não cobre esse tipo de objeto — seção 3) e testados sob concorrência real (CTN04)
- [ ] Mensagens 001–007 criadas na SE91 na classe `/ACHE/MM_LOTE`, com os textos exatos da EF
- [ ] Nenhum `COMMIT WORK` dentro da função central ou dos `PERFORM`s de atualização de contador
- [ ] Todo caminho de erro após `ENQUEUE` passa por `DEQUEUE` antes de sair
- [ ] Validação de lote existente feita contra os objetos Released (`I_BatchPlant`/`I_BatchCrossPlant`), não diretamente contra `MCHA`/`MCH1` (aderência Clean Core, EF seção 1.8.1)
- [ ] Ponto de integração no Coletor de Recebimento (GAP334/391) localizado e confirmado com quem mantém aquele desenvolvimento
- [ ] CT01–CT07 e CTN01–CTN05 executados manualmente no seu ambiente de teste
- [ ] **(V4)** Comprimento exato dos campos `SEQ05`/`SEQ06`/`SEQ08` confirmado no Dictionary — a fórmula de montagem do lote (seção 5.3) depende do zero-pad desses campos, e isso não estava visível no código-fonte legado, só o resultado
- [ ] **(V4)** Confirmado com o dev do RAP App se existe alguma ação/BO exposta para incrementar o contador, em vez de `MODIFY` direto nas tabelas `/ache/mmt103`/`/ache/mmt104`
- [ ] **(V4)** Verificado o propósito real das classes já existentes no pacote (`/ACHE/CLMM_LOTE01` a `LOTE04`) — não ficou claro se são parte da arquitetura deste enhancement ou resíduo/exemplo; se forem parte do design, revisitar esta seção 5 antes de fechar a implementação
- [ ] **(V5)** Nomes de campo da CDS (`MaterialGroup`, `MaterialType`, `FiscalYear`, `FiscalPeriod`, `Sequence05/06/08`, `BatchNumericLength`, `MonthlyBreak`) conferidos contra a definição real da CDS antes de compilar — a seção 5.2 traduz explicitamente para os nomes da tabela física (`GRPMA`, `MTART`, `GJAHR`, `MONAT`, `SEQ05/06/08`, `SEQLOTE`, `SEQMENSAL`) antes do `MODIFY`; não reutilize a estrutura da CDS direto num `MODIFY` de tabela

---

## 12. Referências citadas na EF (não técnicas, mas relevantes ao desenvolvimento)

- **DQ0011** — documento de qualidade que define as regras de codificação de lote que a função central deve respeitar.
- **POP0067** — procedimento operacional que define quais áreas ficam responsáveis pelos cenários de lote manual (Full Service, reprocesso, RNC, RDF, validação LIMS) — útil para confirmar com o negócio quais tipos de material devem **permanecer fora** da parametrização de geração automática.
- **GAP334/391** — desenvolvimento do Coletor de Recebimento, ponto de integração do cenário 3 (seção 8 deste guia).
- **WORKBOOK_SAPHIRA_ACHE_V1 (20260317)** — convenção de nomenclatura de objetos SAP do projeto, fonte dos nomes definitivos usados neste guia (seção 0.2). Para dúvidas de ABAP Clássico ou pacote, o próprio workbook indica o COE técnico: André Alvarez / Eder Marcelino.
