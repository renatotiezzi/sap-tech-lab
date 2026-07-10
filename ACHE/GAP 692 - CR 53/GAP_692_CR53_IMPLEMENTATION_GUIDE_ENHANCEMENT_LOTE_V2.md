# GAP 692 / CR 53 — Guia Técnico de Implementação do Enhancement de Geração Automática de Lote (Aché)

> **Escopo deste guia**: cobre exclusivamente o enhancement ABAP (BAdI + lógica central de determinação de lote) que você é responsável por implementar. A criação das tabelas customizadas, CDS Views, RAP App (BDEF/SDEF/Service Binding) e app Fiori de manutenção dos parâmetros é responsabilidade de outro desenvolvedor — este guia trata os nomes dessas tabelas/CDS como **dependências externas a confirmar**, não como objetos que você vai criar.
>
> Fonte: `ACHE_EF_MM_GAP_692_CR53Geracao_Numeracao_Lote_Ache.pdf` (EF GAP 692 / CR 53, V1, 14/06/2026).
>
> Nomenclatura dos objetos ABAP deste guia segue `WORKBOOK_SAPHIRA_ACHE_V1 (20260317)` — Convenção de Nomenclaturas para Objetos SAP do projeto SAPHIRA. Onde o workbook não cobre um tipo de objeto específico do seu escopo (ex. Lock Object), isso é sinalizado explicitamente como pendência de confirmação com o COE.

---

## 0. Visão geral do que você vai construir

Três pontos de disparo, uma lógica central:

| # | Cenário | Ponto técnico | Tipo de integração |
|---|---------|----------------|---------------------|
| 1 | Entrada de mercadoria | Enhancement Spot `LOBM_BATCH_EXT` → BAdI `LOBM_BEFORE_BATCH_NUMBER_INT` → método `BEFORE_NUMBER_ASSIGNMENT` | BAdI standard SAP |
| 2 | Criação de ordem de processo | Mesmo Enhancement Spot / BAdI / método do item 1 | BAdI standard SAP (mesma implementação) |
| 3 | Coletor de Recebimento | Fluxo custom do GAP334/391 (pergunta "Deseja gerar Lote Aché?") | Reuso da lógica central via chamada de função — **não é BAdI** |

Os itens 1 e 2 são acionados pelo **mesmo** enhancement spot/BAdI/método — não são duas implementações diferentes. O SAP standard chama esse BAdI sempre que a determinação interna de número de lote é necessária, independente da transação de origem. Você não precisa (e não deve) diferenciar o fluxo de negócio dentro do método; a regra de geração é orientada por parametrização do tipo de material, não pela transação chamadora.

O item 3 **não passa pelo BAdI standard** — é um desenvolvimento custom (coletor de recebimento). Para esse cenário, a EF pede reuso da mesma lógica central, acionada pelo fluxo específico do GAP334/391. Trate isso como "chamar a mesma função central a partir de um ponto diferente do código", não como um enhancement novo.

Arquitetura recomendada:

```text
BAdI: LOBM_BEFORE_BATCH_NUMBER_INT / BEFORE_NUMBER_ASSIGNMENT  ─┐
                                                                  ├──► FUNCTION /ACHE/MMF_LOTE_DETERMINAR (lógica central)
Coletor de Recebimento (GAP334/391, ponto a localizar)   ───────┘
```

Toda a regra de negócio (validação de lote manual, parametrização, contador, lock, montagem do número, duplicidade, range) fica **dentro da função central**. O BAdI e o coletor são apenas chamadores finos.

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
| Classe de mensagens (SE91) | §7 `/ACHE/XX_<Descrição>` | `/ACHE/MM_LOTE` (mensagens continuam numeradas 001–007) |
| Objeto de bloqueio mensal (SE11) | não coberto pelo workbook | `/ACHE/EMMLOTEMES` (sugestão — ver seção 3 deste guia) |
| Objeto de bloqueio anual (SE11) | não coberto pelo workbook | `/ACHE/EMMLOTEANO` (sugestão — ver seção 3 deste guia) |

Também se aplicam ao seu código (WORKBOOK seção 8.5 — prefixo de parâmetros): parâmetros de function module usam `I_`/`E_`/`C_` (não `IV_`/`EV_`/`CV_`), e rotinas internas (`PERFORM`) usam prefixo `F_`. Já ajustei isso nos esqueletos de código deste guia (seções 5 e 7). Variáveis e estruturas locais (`LV_`/`LS_`/`LT_`) já seguiam o padrão e não mudaram.

> As tabelas/CDS de parametrização (`/ACHE/AGRUPMTART`, `/ACHE/AGRUPLOTES`, `/ACHE/CNTLOTEMES`, `/ACHE/CNTLOTE`) continuam como dependência do outro desenvolvedor (seção 2) — não recebi o guia de implementação dele nesta revisão, então os nomes seguem como placeholder a confirmar. Se o padrão dele seguir o workbook, o esperado é CDS View `/ACHE/MMCDS_NNNN` (SQL view por trás `/ACHE/MM_NNNN`, seção 6 do workbook) — confirme com ele.

---

## 1. Passo 1 — Reconhecer o legado antes de codificar

Existe hoje uma função custom `YYPCL_DETERMINA_LOTE` que já faz determinação automática de lote por tipo de material (ambiente As Is / ECC legado citado na EF, seção 1.1 e 1.8.2).

1. Abra **SE37**.
2. Informe `YYPCL_DETERMINA_LOTE` → **Exibir**.
3. Leia a lógica: como ela consulta as tabelas de parametrização atuais, como monta o lote (ano/mês/sequencial), como trata mensal vs. anual.
4. Anote as diferenças entre a estrutura legada e o novo modelo de dados (seção 2 abaixo) — a EF deixa claro que o novo desenvolvimento usa **novas tabelas** (`/ACHE/*`), não as tabelas legadas `YYPCL_*`. `YYPCL_DETERMINA_LOTE` serve só como referência de comportamento, não é para ser chamada pelo novo enhancement.

Isso evita reinventar regras que o Aché já validou (ex.: como a quebra mensal/anual afeta o zero-padding do sequencial).

---

## 2. Passo 2 — Confirmar as dependências de dados (outro desenvolvedor)

Estas tabelas/CDS **não são suas para criar** — são do desenvolvedor do RAP App. Mas sua função central depende delas para `SELECT`, então confirme com ele os nomes finais e os tipos de dados antes de codificar os `SELECT`s.

| Tabela (nome final a confirmar) | CDS View (Z) | Finalidade | Campos-chave citados na EF |
|---|---|---|---|
| `/ACHE/AGRUPMTART` | `ZI_MM_AgrupTpMat` | Tipo de material → grupo de regra | `MANDT`, `MTART`, `ZZGRPMA` |
| `/ACHE/AGRUPLOTES` | `ZI_MM_AgrupLotes` | Estrutura do lote por grupo (mensal/anual, tamanho do sequencial) | `ZZGRPMA`, `ZZSEQLOTE` (tamanho: 5/6/8), indicador de sequência mensal, campos de composição |
| `/ACHE/CNTLOTEMES` | `ZI_MM_CntLoteMes` | Contador de sequencial — quebra mensal | `MANDT`, `ZZGRPMA`, `GJAHR`, `MONAT`, `ZZSEQ05`, `ZZSEQ06`, `ZZSEQ08` |
| `/ACHE/CNTLOTE` | `ZI_MM_CntLoteAno` | Contador de sequencial — quebra anual | `MANDT`, `ZZGRPMA`, `GJAHR`, `ZZSEQ05`, `ZZSEQ06`, `ZZSEQ08` |

> ⚠️ **Ponto em aberto na própria EF**: a seção 1.8.2 lista os nomes de tabela como `YYPCL_AGRUPMTART`, `YYPCL_AGRUPLOTES`, `YYPCL_CNTLOTEMES`, `YYPCL_CNTLOTE` (nomenclatura legada/As Is), enquanto a seção 2.2 (Modelo de Dados) usa `/ACHE/*AGRUPMTART`, `/ACHE/*AGRUPLOTES`, `/ACHE/*CNTLOTEMES`, `/ACHE/*CNTLOTE` (nomenclatura nova). **Confirme com o desenvolvedor do RAP App qual é o nome definitivo das tabelas Z/​`/ACHE/`** antes de fixar os `SELECT`s na função central — trate os nomes acima como placeholder até essa confirmação.

Por que três campos de contador (`ZZSEQ05`, `ZZSEQ06`, `ZZSEQ08`) em vez de um só: a regra de range (EF seção 2.5) prevê sequenciais de 5, 6 ou 8 dígitos dependendo do grupo. Cada grupo usa **um** desses campos (definido por `ZZSEQLOTE` em `/ACHE/AGRUPLOTES`); os outros dois ficam em branco/zero para aquele grupo. Sua função central deve ler o campo certo com base em `ZZSEQLOTE`, não os três.

Enquanto as tabelas reais não existem no seu sistema, você pode desenvolver a função central contra uma estrutura local (`TYPES`) espelhando os campos acima, e trocar pelos `SELECT`s reais assim que as tabelas existirem — isso permite que os dois desenvolvimentos avancem em paralelo.

---

## 3. Passo 3 — Criar o objeto de bloqueio (lock) para concorrência

A EF exige (seção "Regra de Concorrência") bloqueio técnico do contador antes do incremento, para evitar lote duplicado sob concorrência.

1. Abra **SE11**.
2. Selecione **Objeto de bloqueio** (Lock Object) → nome sugerido `/ACHE/EMMLOTEMES`.
3. Tabela de bloqueio primária: aponte para a tabela de contador mensal (`/ACHE/CNTLOTEMES`, a confirmar).
4. Campos de bloqueio: `MANDT`, `ZZGRPMA`, `GJAHR`, `MONAT` (bloqueio mensal — conforme EF).
5. Crie um segundo objeto de bloqueio `/ACHE/EMMLOTEANO` sobre `/ACHE/CNTLOTE`, campos `MANDT`, `ZZGRPMA`, `GJAHR` (bloqueio anual — conforme EF).
6. Ative. O SAP gera automaticamente as function modules de enqueue/dequeue com base nesse nome (algo como `/ACHE/ENQUEUE_EMMLOTEMES` / `/ACHE/DEQUEUE_EMMLOTEMES`, e o par `_EMMLOTEANO`) — **confirme o nome exato gerado após ativar**, o padrão pode variar com o namespace.

> ⚠️ O WORKBOOK SAPHIRA não define um padrão específico para Objetos de Bloqueio (Lock Objects) — não há linha equivalente na seção 4 (Dicionário de Dados). O nome sugerido acima segue apenas a regra técnica obrigatória do SAP (todo lock object começa com `E`) dentro do namespace `/ACHE/`. Confirme com o COE (André Alvarez / Eder Marcelino) antes de criar, para alinhar com qualquer padrão interno não documentado no workbook.

> Por que dois objetos de bloqueio e não um genérico: a EF diferencia explicitamente os campos de bloqueio mensal (inclui `MONAT`) dos anuais (sem `MONAT`) — um único objeto de bloqueio com campo opcional geraria granularidade errada (bloquearia o ano inteiro mesmo em regra mensal, ou vice-versa).

---

## 4. Passo 4 — Criar a classe de mensagens `/ACHE/MM_LOTE`

1. Abra **SE91**.
2. Classe de mensagens: `/ACHE/MM_LOTE` (padrão WORKBOOK SAPHIRA §7 — `/ACHE/XX_<Descrição>`).
3. Cadastre as mensagens conforme a EF (seção 2.6), mantendo a numeração 001–007:

| Nº | Tipo | Texto | Quando ocorre |
|---|---|---|---|
| 001 | E | Tipo de material &1 sem regra de geração de lote. | Não existe registro em `/ACHE/AGRUPMTART` para o `MTART`. |
| 002 | E | Grupo &1 sem estrutura de lote parametrizada. | Não existe registro em `/ACHE/AGRUPLOTES` para o grupo. |
| 003 | E | Contador de lote não mantido para grupo &1, ano &2, mês &3. | Não existe linha de contador em `/ACHE/CNTLOTEMES` ou `/ACHE/CNTLOTE` para o período. |
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

Parâmetros seguem o prefixo do WORKBOOK SAPHIRA §8.5 (`I_`/`E_` em vez de `IV_`/`EV_`):

```abap
FUNCTION /ache/mmf_lote_determinar.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(I_MATNR) TYPE  MATNR
*"     REFERENCE(I_WERKS) TYPE  WERKS_D OPTIONAL
*"     REFERENCE(I_DATA_BASE) TYPE  SY-DATUM
*"     REFERENCE(I_LOTE_INFORMADO) TYPE  CHARG_D OPTIONAL
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

### 5.2 Corpo da função (regra por regra, seguindo o pseudocódigo da EF seção 2.5)

```abap
  DATA: lv_mtart      TYPE mtart,
        lv_zzgrpma    TYPE zzgrpma,          " confirmar domínio/tipo com o dev do RAP App
        ls_agruplotes TYPE /ache/agruplotes, " placeholder — ajustar ao nome final da tabela/CDS
        lv_gjahr      TYPE gjahr,
        lv_monat      TYPE monat,
        lv_seq        TYPE p,
        lv_seq_limite TYPE p,
        lv_lote       TYPE charg_d.

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

* ------------------------------------------------------------------
* Identificar material / tipo de material / data base
* ------------------------------------------------------------------
  SELECT SINGLE mtart FROM i_material
    INTO lv_mtart
    WHERE matnr = i_matnr.
  " se o tipo de material já vier de fora, prefira receber I_MTART
  " como parâmetro e evitar esse SELECT — a decidir com quem chama.

* ------------------------------------------------------------------
* Buscar grupo de regra por tipo de material
* ------------------------------------------------------------------
  SELECT SINGLE zzgrpma FROM /ache/agrupmtart   "nome a confirmar
    INTO lv_zzgrpma
    WHERE mtart = lv_mtart.
  IF sy-subrc <> 0.
    e_status = 'E'.
    MESSAGE e001(/ache/mm_lote) WITH lv_mtart INTO e_msg.
    RAISE sem_parametrizacao.
  ENDIF.

* ------------------------------------------------------------------
* Buscar estrutura do lote (mensal/anual, tamanho do sequencial)
* ------------------------------------------------------------------
  SELECT SINGLE * FROM /ache/agruplotes         "nome a confirmar
    INTO ls_agruplotes
    WHERE zzgrpma = lv_zzgrpma.
  IF sy-subrc <> 0.
    e_status = 'E'.
    MESSAGE e002(/ache/mm_lote) WITH lv_zzgrpma INTO e_msg.
    RAISE sem_estrutura.
  ENDIF.

  lv_gjahr = i_data_base(4).
  lv_monat = i_data_base+4(2).

* ------------------------------------------------------------------
* Bloquear + ler contador (mensal ou anual, conforme estrutura)
* ------------------------------------------------------------------
  IF ls_agruplotes-zzseqmensal = abap_true.
    CALL FUNCTION '/ACHE/ENQUEUE_EMMLOTEMES'   " confirmar nome exato gerado pela SE11
      EXPORTING
        mandt   = sy-mandt
        zzgrpma = lv_zzgrpma
        gjahr   = lv_gjahr
        monat   = lv_monat
      EXCEPTIONS
        foreign_lock = 1
        system_failure = 2
        OTHERS = 3.
    IF sy-subrc <> 0.
      e_status = 'E'.
      MESSAGE e004(/ache/mm_lote) INTO e_msg.
      RAISE lock_indisponivel.
    ENDIF.

    PERFORM f_ler_contador_mensal USING lv_zzgrpma lv_gjahr lv_monat
                                  CHANGING lv_seq lv_seq_limite.
    " FORM local que faz SELECT em /ache/cntlotemes e escolhe
    " ZZSEQ05 / ZZSEQ06 / ZZSEQ08 conforme ls_agruplotes-zzseqlote,
    " e devolve o limite conceitual (99999 / 999999 / 99999999)
    IF sy-subrc <> 0.
      CALL FUNCTION '/ACHE/DEQUEUE_EMMLOTEMES'
        EXPORTING mandt = sy-mandt zzgrpma = lv_zzgrpma gjahr = lv_gjahr monat = lv_monat.
      e_status = 'E'.
      MESSAGE e003(/ache/mm_lote) WITH lv_zzgrpma lv_gjahr lv_monat INTO e_msg.
      RAISE contador_inexistente. " ou criar contador zerado — decisão de arquitetura, ver seção 6 deste guia
    ENDIF.

  ELSE.
    CALL FUNCTION '/ACHE/ENQUEUE_EMMLOTEANO'   " confirmar nome exato gerado pela SE11
      EXPORTING
        mandt   = sy-mandt
        zzgrpma = lv_zzgrpma
        gjahr   = lv_gjahr
      EXCEPTIONS
        foreign_lock = 1
        system_failure = 2
        OTHERS = 3.
    IF sy-subrc <> 0.
      e_status = 'E'.
      MESSAGE e004(/ache/mm_lote) INTO e_msg.
      RAISE lock_indisponivel.
    ENDIF.

    PERFORM f_ler_contador_anual USING lv_zzgrpma lv_gjahr
                                 CHANGING lv_seq lv_seq_limite.
    IF sy-subrc <> 0.
      CALL FUNCTION '/ACHE/DEQUEUE_EMMLOTEANO'
        EXPORTING mandt = sy-mandt zzgrpma = lv_zzgrpma gjahr = lv_gjahr.
      e_status = 'E'.
      MESSAGE e003(/ache/mm_lote) WITH lv_zzgrpma lv_gjahr '' INTO e_msg.
      RAISE contador_inexistente.
    ENDIF.
  ENDIF.

* ------------------------------------------------------------------
* Incrementar sequencial + validar range
* ------------------------------------------------------------------
  lv_seq = lv_seq + 1.
  IF lv_seq > lv_seq_limite.
    PERFORM f_liberar_lock USING ls_agruplotes-zzseqmensal lv_zzgrpma lv_gjahr lv_monat.
    e_status = 'E'.
    MESSAGE e005(/ache/mm_lote) WITH lv_zzgrpma lv_gjahr INTO e_msg.
    RAISE range_esgotado.
  ENDIF.

* ------------------------------------------------------------------
* Montar o número do lote conforme estrutura
* ------------------------------------------------------------------
  PERFORM f_montar_lote USING ls_agruplotes lv_gjahr lv_monat lv_seq
                         CHANGING lv_lote.
  " Ano + Mês + Sequencial quando ls_agruplotes-zzseqmensal = 'X'
  " Ano + Sequencial quando não houver quebra mensal
  " Zero-pad do sequencial conforme ZZSEQLOTE (5, 6 ou 8 dígitos)

* ------------------------------------------------------------------
* Validar duplicidade — enquanto existir, incrementa e revalida range
* ------------------------------------------------------------------
  WHILE f_lote_existe( lv_lote ) = abap_true.
    lv_seq = lv_seq + 1.
    IF lv_seq > lv_seq_limite.
      PERFORM f_liberar_lock USING ls_agruplotes-zzseqmensal lv_zzgrpma lv_gjahr lv_monat.
      e_status = 'E'.
      MESSAGE e005(/ache/mm_lote) WITH lv_zzgrpma lv_gjahr INTO e_msg.
      RAISE range_esgotado.
    ENDIF.
    PERFORM f_montar_lote USING ls_agruplotes lv_gjahr lv_monat lv_seq
                           CHANGING lv_lote.
  ENDWHILE.
  " f_lote_existe(): validar em I_BatchPlant / I_BatchCrossPlant (sucessores
  " Released de MCHA/MCH1 — ver seção 1.8.1 da EF, Clean Core)

* ------------------------------------------------------------------
* Persistir contador (dentro da mesma LUW do processo chamador —
* SEM COMMIT WORK próprio, conforme premissa da EF)
* ------------------------------------------------------------------
  PERFORM f_atualizar_contador USING ls_agruplotes-zzseqmensal
                                      lv_zzgrpma lv_gjahr lv_monat lv_seq.

  PERFORM f_liberar_lock USING ls_agruplotes-zzseqmensal lv_zzgrpma lv_gjahr lv_monat.

  e_lote   = lv_lote.
  e_status = 'S'.

ENDFUNCTION.
```

> **Não faça `COMMIT WORK` dentro desta função nem dentro do `PERFORM f_atualizar_contador`.** A EF (seção 1.5) é explícita: o enhancement deve respeitar a LUW do processo SAP que o chamou (MIGO, ordem de processo, coletor). Um commit próprio aqui quebraria o tratamento de erro do processo standard e poderia liberar o lock antes da hora.

> **Sempre libere o lock**, inclusive no caminho de erro (a EF exige isso explicitamente na "Regra de Concorrência": *"O bloqueio deverá ser liberado mesmo em caso de erro tratado"*). No esqueleto acima, todo `RAISE` depois do `ENQUEUE` é precedido por um `DEQUEUE` correspondente — confira isso com atenção ao implementar, é o erro mais fácil de introduzir aqui.

---

## 6. Passo 6 — Decisão de arquitetura pendente: contador inexistente

A EF deixa esse ponto em aberto (pseudocódigo, seção 2.5): *"Se contador não existir: Emitir erro bloqueante **ou** criar contador inicial conforme decisão de arquitetura."*

Isso precisa ser decidido (por você + arquitetura/cliente) antes de fechar o desenvolvimento:

- **Opção A (mais segura, alinhada ao restante da EF)**: contador inexistente é sempre erro bloqueante (mensagem `003` da classe `/ACHE/MM_LOTE`), e a criação do registro de contador para o período é responsabilidade da manutenção via app Fiori (RAP App do outro desenvolvedor). Isso é consistente com a premissa da EF de que "o usuário final não deverá possuir autorização para alterar diretamente contadores de lote" — ou seja, a criação de contador deve ser um ato deliberado de parametrização, não um efeito colateral automático do primeiro lote do período.
- **Opção B**: a função central cria o contador zerado na primeira chamada do período. Mais conveniente, mas foge do controle de parametrização restrita mencionado na EF (seção 2.7).

Recomendação: **Opção A**, por aderência à seção 2.7 da EF ("manutenção das tabelas de parametrização restrita a usuários autorizados"). Confirme essa leitura com o arquiteto do projeto antes de implementar — é uma decisão de negócio, não só técnica.

---

## 7. Passo 7 — Implementar o BAdI (Entrada de Mercadoria + Ordem de Processo)

### 7.1 Localizar e validar a assinatura

1. Abra **SE18**.
2. Enhancement Spot: `LOBM_BATCH_EXT` → **Exibir**.
3. Localize a BAdI Definition `LOBM_BEFORE_BATCH_NUMBER_INT`.
4. Abra a interface associada via **SE24** (tipicamente `IF_EX_LOBM_BEFORE_BATCH_NUMBER_INT`) e exiba o método `BEFORE_NUMBER_ASSIGNMENT`.
5. **Confirme os nomes exatos dos parâmetros do método antes de codificar** — eles podem variar por release/SP. O esqueleto abaixo assume os nomes típicos (`IV_MATNR`, `IV_WERKS`, `CV_CHARG`); ajuste para o que a SE24 mostrar no seu sistema.

### 7.2 Criar a implementação

1. Abra **SE19**.
2. Tipo de enhancement implementation: **BAdI Nova**.
3. Nome da implementação: `/ACHE/MM_LOTE_BADI` (WORKBOOK SAPHIRA §5/§9 — `/ACHE/XX_<Descrição>`).
4. BAdI Definition: `LOBM_BEFORE_BATCH_NUMBER_INT`.
5. Nome da classe implementadora: `/ACHE/CLMM_LOTE_BADI` (WORKBOOK SAPHIRA §5 — `/ACHE/CLXX_<Descrição>`; o SE19 costuma sugerir um nome automático — substitua pelo nome definitivo acima antes de gravar).
6. Grave, ative.
7. Abra a classe gerada pela **SE24** e implemente o método.

### 7.3 Código do método (chamador fino da função central)

```abap
METHOD if_ex_lobm_before_batch_number_int~before_number_assignment.

  DATA: lv_lote   TYPE charg_d,
        lv_status TYPE char1,
        lv_msg    TYPE bapi_msg.

* Regra 1, também validada aqui por segurança: se já veio preenchido,
* não chama a função central — apenas sai. (A função central já faz
* essa checagem, mas evitar a chamada quando não é necessário é mais
* barato e deixa a intenção explícita neste ponto de entrada.)
  IF cv_charg IS NOT INITIAL.
    RETURN.
  ENDIF.

  CALL FUNCTION '/ACHE/MMF_LOTE_DETERMINAR'
    EXPORTING
      i_matnr          = iv_matnr
      i_werks          = iv_werks
      i_data_base      = sy-datum   " confirmar origem correta da data-base
                                    " por cenário (data de lançamento do
                                    " documento de material vs. data da
                                    " ordem — ver EF seção 2.2, "Campos de
                                    " Entrada do Serviço" / "Data base")
      i_lote_informado = cv_charg
    IMPORTING
      e_lote   = lv_lote
      e_status = lv_status
      e_msg    = lv_msg
    EXCEPTIONS
      sem_parametrizacao   = 1
      sem_estrutura        = 2
      contador_inexistente = 3
      lock_indisponivel    = 4
      range_esgotado       = 5
      erro_geral           = 6
      OTHERS               = 7.

  IF sy-subrc <> 0.
    " Erro bloqueante: propague para o processo chamador. A forma exata
    " (MESSAGE ... RAISING, ou exceção da própria interface do BAdI)
    " depende do que a interface do método expõe — confirme na SE24.
    MESSAGE ID '/ACHE/MM_LOTE' TYPE 'E' NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3.
    RETURN.
  ENDIF.

  IF lv_status = 'S'.
    cv_charg = lv_lote.
  ENDIF.
  " status 'N' = lote já era manual, cv_charg já veio preenchido, nada a fazer.

ENDMETHOD.
```

> **Sobre a data-base**: a EF (seção 2.2) diz que a origem da "data base" muda por processo chamador — "data de lançamento, data da ordem ou data do processo". Dentro do método do BAdI você não sabe diretamente qual processo está chamando (é o mesmo BAdI para os dois cenários). Verifique, ao confirmar a assinatura na SE24, se o método recebe algum parâmetro de contexto/documento que permita ler a data correta; se não receber, `sy-datum` (data do sistema) é o fallback mais seguro, mas confirme com o time de negócio se isso atende ao requisito de "ano/mês do lote" em lançamentos com data de posição retroativa.

### 7.4 Regra de preservação de lote manual — onde ela vive de verdade

Você vai notar que a checagem "lote não vazio → sai" aparece **duas vezes**: no método do BAdI (7.3) e no início da função central (5.2). Isso é intencional, não duplicação por descuido:

- No BAdI: evita a chamada desnecessária à função central (barato, rápido, deixa a intenção clara no ponto de entrada).
- Na função central: é a garantia real, porque a função central também é chamada pelo coletor de recebimento (seção 8), que é um caminho de código diferente. Se você confiar só na checagem do BAdI, o coletor de recebimento fica desprotegido.

Não remova a checagem da função central achando que é redundante — ela é a única garantia que vale para **todos** os chamadores.

---

## 8. Passo 8 — Coletor de Recebimento (reuso, não é BAdI)

A EF (seção 2.4, Enhancement 3) é explícita: esse cenário reutiliza a mesma lógica central, mas é acionado pelo fluxo específico do GAP334/391 — **não** pelo enhancement spot `LOBM_BATCH_EXT`.

Condição de disparo específica deste cenário: o usuário responde **"Sim"** à pergunta **"Deseja gerar Lote Aché?"** ao salvar a tela do Coletor.

Passos:

1. Localize o programa/classe do Coletor de Recebimento (desenvolvimento do GAP334/391). Se não souber o nome exato, use **SE80** → Ferramentas → Localizar objeto do repositório, ou busque no código-fonte pelo texto literal `Deseja gerar Lote Ach` (sem acento, para pegar variações de codificação de caractere).
2. Dentro desse fluxo, localize o ponto onde hoje (se já existir) é chamada `YYPCL_DETERMINA_LOTE` ou lógica equivalente de geração de lote — ou, se essa integração ainda não existe, localize o ponto exato pós-confirmação de "Sim" onde o campo de lote do coletor é gravado.
3. Substitua (ou insira) a chamada para `/ACHE/MMF_LOTE_DETERMINAR`, com a mesma assinatura usada no BAdI (seção 7.3), passando a data-base correta do fluxo do coletor (a EF não especifica qual campo de data o coletor usa — confirme com quem mantém o GAP334/391).
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

O tamanho aplicável por grupo vem de `ZZSEQLOTE` em `/ACHE/AGRUPLOTES` (a confirmar nome final da tabela — seção 2 deste guia). Ao atingir o limite, bloqueie a geração e emita a mensagem `005` da classe `/ACHE/MM_LOTE` — não tente "dar a volta" (wrap-around) para 1, a EF não prevê isso e criaria duplicidade certa com lotes já emitidos no início do range.

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
| CT05 | Sequencial mensal | Grupo com `ZZSEQMENSAL = X` → lote contém ano/mês corretos, contador mensal incrementado |
| CT06 | Sequencial anual | Grupo sem quebra mensal → lote contém ano + sequencial, contador anual incrementado |
| CT07 | Duplicidade de lote | Forçar cenário onde o próximo sequencial calculado já existe como lote → sistema pula e gera o próximo livre, contador final reflete o último valor realmente utilizado (não o primeiro tentado) |

### 10.2 Negativos

| Caso | O que validar | Mensagem esperada |
|---|---|---|
| CTN01 | Tipo de material sem parametrização em `AGRUPMTART` | `/ACHE/MM_LOTE` 001, bloqueante |
| CTN02 | Grupo sem estrutura em `AGRUPLOTES` | `/ACHE/MM_LOTE` 002, bloqueante |
| CTN03 | Contador mensal/anual inexistente para o período | `/ACHE/MM_LOTE` 003, bloqueante (ver decisão de arquitetura, seção 6) |
| CTN04 | Lock do contador indisponível (concorrência — dois processos simultâneos) | `/ACHE/MM_LOTE` 004, bloqueante, sem duplicidade gerada por nenhum dos dois processos |
| CTN05 | Range esgotado (sequencial no limite) | `/ACHE/MM_LOTE` 005, bloqueante |

Para CTN04 especificamente: o teste real exige dois processos concorrentes tentando gerar lote para o **mesmo grupo + mesmo período** ao mesmo tempo (ex. duas sessões MIGO em paralelo). Teste unitário isolado não pega esse cenário — vale simular chamando a função central duas vezes sem liberar o lock da primeira, para confirmar que a segunda chamada recebe `LOCK_INDISPONIVEL` e não trava indefinidamente.

---

## 11. Checklist final antes de considerar o desenvolvimento pronto

- [ ] Pacote definitivo confirmado com o COE (seção 0.1) — `/ACHE/DEV_OLD` é a sugestão, não use `ZDEV` sem aprovação
- [ ] Assinatura real do método `BEFORE_NUMBER_ASSIGNMENT` confirmada via SE24 (não a assumida neste guia)
- [ ] Nomes finais das tabelas/CDS de parametrização confirmados com o dev do RAP App (seção 2)
- [ ] Decisão de arquitetura sobre contador inexistente (seção 6) confirmada com o arquiteto/negócio
- [ ] Objetos de bloqueio `/ACHE/EMMLOTEMES` / `/ACHE/EMMLOTEANO` criados, nome confirmado com o COE (workbook não cobre esse tipo de objeto — seção 3) e testados sob concorrência real (CTN04)
- [ ] Mensagens 001–007 criadas na SE91 na classe `/ACHE/MM_LOTE`, com os textos exatos da EF
- [ ] Nenhum `COMMIT WORK` dentro da função central ou dos `PERFORM`s de atualização de contador
- [ ] Todo caminho de erro após `ENQUEUE` passa por `DEQUEUE` antes de sair
- [ ] Validação de lote existente feita contra os objetos Released (`I_BatchPlant`/`I_BatchCrossPlant`), não diretamente contra `MCHA`/`MCH1` (aderência Clean Core, EF seção 1.8.1)
- [ ] Ponto de integração no Coletor de Recebimento (GAP334/391) localizado e confirmado com quem mantém aquele desenvolvimento
- [ ] CT01–CT07 e CTN01–CTN05 executados manualmente no seu ambiente de teste

---

## 12. Referências citadas na EF (não técnicas, mas relevantes ao desenvolvimento)

- **DQ0011** — documento de qualidade que define as regras de codificação de lote que a função central deve respeitar.
- **POP0067** — procedimento operacional que define quais áreas ficam responsáveis pelos cenários de lote manual (Full Service, reprocesso, RNC, RDF, validação LIMS) — útil para confirmar com o negócio quais tipos de material devem **permanecer fora** da parametrização de geração automática.
- **GAP334/391** — desenvolvimento do Coletor de Recebimento, ponto de integração do cenário 3 (seção 8 deste guia).
- **WORKBOOK_SAPHIRA_ACHE_V1 (20260317)** — convenção de nomenclatura de objetos SAP do projeto, fonte dos nomes definitivos usados neste guia (seção 0.2). Para dúvidas de ABAP Clássico ou pacote, o próprio workbook indica o COE técnico: André Alvarez / Eder Marcelino.