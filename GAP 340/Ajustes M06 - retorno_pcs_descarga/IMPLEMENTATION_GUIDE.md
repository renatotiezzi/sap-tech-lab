# GAP 340 / M06 — Retorno PCS → SAP: Atualização de Pesos da Descarga

> Superseded: este fluxo foi substituido pelo pipeline do GAP 265 via zclq2c_265_desc_ret_granel / zclq2c_265_desc_job. Nao criar os objetos deste guia (passos 0 a 6); manter apenas como referencia historica.

**Classe:** `ZCL_Q2C_PCS_RETORNO`  
**Runner:** `ZR_Q2C_PCS_RETORNO_RUNNER`  
**Pacote sugerido:** `ZPQ2C_265` (confirmar com responsável do GAP 265)  
**Objetivo:** Job APJ que lê arquivos de retorno do PCS (layout U301-H), localiza a Descarga pelo `pcs_ordernum` e atualiza `peso_inicial` / `peso_final` na `ztbq2c_descarga`.

---

## Dependências antes de criar os objetos

| Dependência | Tipo | Observação |
|---|---|---|
| GAP 265 já entregue | Funcional | O `pcs_ordernum` deve estar gravado em `ztbq2c_descarga` pelo envio SAP → PCS |
| Campo `envia_pcs` em `ZI_Q2C_DESCARGA` | Campo DDIC | Confirmar nome com equipe GAP 265; método `validate_pcs_enabled` tem TODO apontando onde inserir a validação quando o campo existir |
| `ZZ1_TVARVC_Q2C` populada | Customizing | Tabela de parâmetros já usada em outros jobs do projeto |

---

## Objetos a criar

| # | Objeto | Tipo | Pacote |
|---|---|---|---|
| 0 | Entradas em `ZZ1_TVARVC_Q2C` | Customizing | — |
| 1 | `ZQ2C_PCS` / `RETORNO` | Application Log Object / Subobject (SLG0) | — |
| 2 | Classe de mensagem `ZQ2C_PCS` | SE91 | `ZPQ2C_265` |
| 3 | `ZCL_Q2C_PCS_RETORNO` | ABAP Class | `ZPQ2C_265` |
| 4 | `ZR_Q2C_PCS_RETORNO_RUNNER` | ABAP Report | `ZPQ2C_265` |
| 5 | `ZQ2C_PCS_RETORNO_CE` | Job Catalog Entry | `ZPQ2C_265` |
| 6 | `ZQ2C_PCS_RETORNO_JT` | Job Template | `ZPQ2C_265` |

---

## Passo 0 — Entradas na ZZ1_TVARVC_Q2C

Inserir os quatro parâmetros abaixo (TYPE = `P`):

| NAME | Valor de exemplo | Finalidade |
|---|---|---|
| `ZQ2C_PCS_RETURN_INPUT_DIR` | `/pcs/retorno/entrada` | Diretório AL11 dos arquivos recebidos do PCS |
| `ZQ2C_PCS_RETURN_PROCESSED_DIR` | `/pcs/retorno/processados` | Arquivos processados com sucesso |
| `ZQ2C_PCS_RETURN_ERROR_DIR` | `/pcs/retorno/erro` | Arquivos com erro de processamento |
| `ZQ2C_PCS_RETURN_FILE_MASK` | `*.txt` | Máscara de nome de arquivo (padrão `*.txt`) |

> Os três diretórios devem existir no servidor e ser acessíveis via AL11 (S_DATASET com ACTVT = '33' e '34').

---

## Passo 1 — Application Log Object (SLG0)

> Se `ZQ2C_PCS` já existir de outro desenvolvimento, apenas adicionar o subobject `RETORNO`.

**On-premise (SBAL_OBJECT) ou cloud (ADT → Manage Application Log Objects):**

| Campo | Valor |
|---|---|
| Object | `ZQ2C_PCS` |
| Description | `Q2C Interface PCS` |
| Subobject | `RETORNO` |
| Description | `Retorno PCS para SAP` |

---

## Passo 2 — Classe de Mensagem ZQ2C_PCS (SE91)

Criar com as mensagens abaixo. Os `&1..&4` são as variáveis de mensagem.

| Nº | Texto | Uso |
|---|---|---|
| `001` | `Job PCS Retorno iniciado: dir &1` | Log start |
| `002` | `Modo Teste ativo - nenhuma alteracao sera gravada` | Test mode warning |
| `003` | `&1 arquivo(s) encontrado(s) para processamento` | File count |
| `010` | `Processando arquivo: &1` | Per-file start |
| `011` | `Arquivo &1 OK: Descarga &2/&3/&4 atualizada` | Per-file success |
| `020` | `Erro ao ler arquivo &1: &2` | Read error |
| `021` | `Layout invalido em &1: &2` | Parse error |
| `023` | `ORDERNUM &2 nao encontrado em ZI_Q2C_DESCARGA (arquivo &1)` | Not found |
| `024` | `Descarga &2/&3 sem PCS habilitado (arquivo &1)` | EnviaPcs vazio |
| `025` | `Peso invalido em &1: campo &2 = &3` | Weight conversion error |
| `026` | `Erro ao atualizar Descarga &2/&3 (arquivo &1): &4` | Update error |
| `099` | `Job PCS Retorno concluido: &1 OK / &2 erro(s)` | Log end |

---

## Passo 3 — Classe ZCL_Q2C_PCS_RETORNO

1. ADT → `Ctrl+N` → **ABAP Class**
2. Nome: `ZCL_Q2C_PCS_RETORNO`
3. Pacote: `ZPQ2C_265`
4. Copiar conteúdo de `ZCL_Q2C_PCS_RETORNO.clas.txt`
5. **Text elements obrigatórios** (ADT → Goto → Text Elements):

| ID | Valor (português) |
|---|---|
| `001` | `P_INDIR` |
| `002` | `P_PRODIR` |
| `003` | `P_ERRDIR` |
| `004` | `P_MASK` |
| `005` | `P_TESTE` |
| `011` | `Diretorio de entrada (AL11)` |
| `012` | `Diretorio de arquivos processados` |
| `013` | `Diretorio de arquivos com erro` |
| `014` | `Mascara de arquivo (ex: *.txt)` |
| `015` | `Modo Teste (sem update real)` |

6. Ativar a classe

**Atenção — `EPS2_GET_DIRECTORY_LISTING`:** Verificar no sistema de destino se o FM existe e se os parâmetros são `IV_DIR_NAME` / `IV_FILE_MASK` / `CT_DIR_LIST`. Em alguns releases o FM pode se chamar `EPS2_GET_DIR_LISTING` ou usar `DIR_NAME` (sem prefixo `IV_`). Ajustar o método `list_files` conforme necessário.

**Atenção — `validate_pcs_enabled`:** Método tem TODO pendente. Quando GAP 265 adicionar o campo `envia_pcs` em `ZI_Q2C_DESCARGA`, substituir o corpo do método pela leitura real do campo. O comentário no código explica exatamente o que colocar.

**Atenção — fallback sem `pcs_ordernum`:** O layout `U301-H` documentado neste ajuste não traz `shnumber`, `remessa` nem `item_remessa`. Portanto, nesta versão o processamento depende de `pcs_ordernum` preenchido no retorno. Se o PCS passar a enviar a chave da Descarga em versão futura, aí sim faz sentido implementar fallback técnico por esses três campos.

---

## Passo 4 — Report Runner ZR_Q2C_PCS_RETORNO_RUNNER

1. ADT → `Ctrl+N` → **ABAP Program**
2. Nome: `ZR_Q2C_PCS_RETORNO_RUNNER`
3. Pacote: `ZPQ2C_265`
4. Copiar conteúdo de `ZR_Q2C_PCS_RETORNO_RUNNER.txt`
5. Ativar

> O runner serve para execução manual e testes via SE38/SA38. O job de produção usa o Job Catalog Entry (passo 5).

---

## Passo 5 — Job Catalog Entry

1. ADT → `Ctrl+N` → Other → **Application Job Catalog Entry**
2. Preencher:
   - **Name:** `ZQ2C_PCS_RETORNO_CE`
   - **Description:** `Q2C - Retorno PCS: Atualizar pesos Descarga`
   - **Class:** `ZCL_Q2C_PCS_RETORNO`
3. Ativar e transportar

---

## Passo 6 — Job Template

1. ADT → `Ctrl+N` → Other → **Application Job Template**
2. Preencher:
   - **Name:** `ZQ2C_PCS_RETORNO_JT`
   - **Description:** `Q2C - Retorno PCS Descarga`
   - **Catalog Entry:** `ZQ2C_PCS_RETORNO_CE`
3. Configurar valores default dos parâmetros (conforme TVARV preenchida no passo 0)
4. Ativar

---

## Fluxo técnico da execução

```
Job (SM36 / APJ)
  → list_files: lista arquivos em P_INDIR com máscara P_MASK
  → para cada arquivo:
      → read_file: OPEN DATASET em TEXT MODE
      → parse_header: localiza linha U301-H, split por ';'
          → campos: pos0=U301-H, pos1=ORDERNUM, pos2=TRKINTWT, pos3=TRKFNLWT
      → find_descarga: SELECT SINGLE em ZI_Q2C_DESCARGA WHERE pcs_ordernum = ORDERNUM
      → validate_pcs_enabled: TODO — confirmar campo envia_pcs com GAP 265
      → convert_weight: CONV CHAR6 → QUAN(13,3)
      → update_descarga_weights: UPDATE ztbq2c_descarga SET peso_inicial, peso_final, aenam, aedat
          → COMMIT WORK AND WAIT
          → move_file → /processed
          → log msg 011 (success)
      → em qualquer erro: move_file → /error, log msg 02x/03x
  → save_log: CL_BALI_LOG_DB → SLG1
```

---

## Layout do arquivo esperado

**Arquivo:** texto delimitado por `;`, terminador CRLF.

**Linha header (obrigatória, exatamente uma por arquivo):**
```
U301-H;<ORDERNUM>;<TRKINTWT>;<TRKFNLWT>;<LINEEMTY>;<PT_YRN>;...
```

| Posição split | Campo PCS | Campo SAP | Tipo |
|---|---|---|---|
| 0 | `U301-H` | tipo de registro | identificador |
| 1 | `ORDERNUM` | `pcs_ordernum` | CHAR(9) |
| 2 | `TRKINTWT` | `peso_inicial` | NUMC(6) kg, ex: `012000` |
| 3 | `TRKFNLWT` | `peso_final` | NUMC(6) kg, ex: `008500` |
| 4–20 | demais campos operacionais | não atualizados nesta versão | — |

> Nesta versão não há campos de fallback para `shnumber` / `remessa` / `item_remessa` no header `U301-H` documentado. Sem esses dados, o fluxo correto e suportado é localizar a Descarga somente por `pcs_ordernum`.

**Linhas de lacre (opcionais):**
```
U301-S;<SORDRNM>;<SEALCODE>;<SEALYRN>
```
> Lacres não são persistidos nesta versão (escopo foco nos pesos). Implementar em versão futura com tabela de itens a confirmar.

---

## Idempotência

O `UPDATE ztbq2c_descarga SET peso_inicial = ..., peso_final = ...` é intrinsecamente idempotente: reprocessar o mesmo arquivo apenas regrava os mesmos valores. Não há risco de duplicidade.

---

## TODO pendente — EnviaPcs

O campo `envia_pcs` ainda não existe em `ZI_Q2C_DESCARGA` no release atual (backup 2026-06-17). Ele deve ser adicionado pelo GAP 265.

Quando disponível, substituir o corpo do método `validate_pcs_enabled` pelo trecho documentado dentro do próprio método (TODO no código).

Enquanto isso, a validação retorna `abap_true` — o que é seguro porque encontrar a Descarga pelo `pcs_ordernum` já implica que a planta foi configurada para PCS no momento do envio.

---

## Objeto de autorização — AL11

O job precisa de autorização `S_DATASET`:

| Campo | Valor |
|---|---|
| ACTVT | `33` (leitura) e `34` (escrita/delete) |
| FILENAME | diretórios configurados nas TVARV |

Verificar com Basis se o usuário de background (SM36) tem os objetos corretos.

---

## Checklist de geração

- [ ] Entradas em `ZZ1_TVARVC_Q2C` criadas (Passo 0)
- [ ] Diretórios AL11 criados e acessíveis (Passo 0)
- [ ] Log Object `ZQ2C_PCS` + Subobject `RETORNO` criados em SLG0 (Passo 1)
- [ ] Classe de mensagem `ZQ2C_PCS` criada com todas as mensagens (Passo 2)
- [ ] Classe `ZCL_Q2C_PCS_RETORNO` criada com text elements (Passo 3)
- [ ] FM `EPS2_GET_DIRECTORY_LISTING` verificado e ajustado se necessário
- [ ] Report `ZR_Q2C_PCS_RETORNO_RUNNER` criado (Passo 4)
- [ ] Teste manual com `P_TESTE = X` executado via runner
- [ ] Logs validados em SLG1 (Object: ZQ2C_PCS / Subobject: RETORNO)
- [ ] Teste real com arquivo de exemplo do PCS
- [ ] Job Catalog Entry `ZQ2C_PCS_RETORNO_CE` criado (Passo 5)
- [ ] Job Template `ZQ2C_PCS_RETORNO_JT` criado (Passo 6)
- [ ] Job agendado em SM36 / APJ em ambiente de teste
- [ ] TODO `validate_pcs_enabled` resolvido após confirmação GAP 265
