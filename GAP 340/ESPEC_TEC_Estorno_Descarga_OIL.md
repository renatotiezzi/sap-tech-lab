# Especificação Técnica para o Copilot — Método de Estorno (APP 340 Descarga OIL)

> Fonte: EF `Q2C340A002 / Q2C340E002 v3.1`, seção "Botão: Realizar Estorno".
> Esta é a especificação que o Copilot deve seguir para implementar o método de estorno. Ela descreve O QUE fazer, QUAIS objetos usar (BAPIs, tabelas, campos, movimentos, status) e QUAL o resultado esperado. A escrita do código ABAP é responsabilidade do Copilot.

---

## 1. Escopo desta entrega

O orquestrador do estorno já existe e despacha para o tratamento correto conforme o `STATUS` da linha em `ZDESCARGA`. Esta entrega cobre a implementação do tratamento de estorno para os status abaixo:

| Implementar nesta entrega | Status de origem | Passo que está sendo revertido | Status de destino |
|---|---|---|---|
| Sim | `02` Amostra Retirada | 1.1.4 Registrar Amostra | `01` |
| Sim | `03` Tanque Final Selecionado | 1.1.5 Escolher Tanque | `02` |
| Sim | `04` Em Descarga / Medição Registrada | 1.1.6 Registrar Medição | `03` |
| Sim | `05` Transferido para Tanque | 1.1.7 Entrada Mercadoria + Transferência 311 | `04` |
| Sim | `06` Concluído | 1.1.7 Finalização (confirmação do TD) | `05` |
| Não (referência) | `01` Entrada Realizada | 1.1.3 Registrar Chegada | `00` |

O estorno do status `01` já está implementado e aparece neste documento apenas como referência de padrão, na seção 9.

Resultado esperado pela EF: ao final de cada estorno bem sucedido, o TD volta ao status anterior, as movimentações de estoque do passo são revertidas quando houver, os campos do passo são limpos na `ZDESCARGA`, a auditoria é atualizada e o evento é logado.

---

## 2. Regras que valem para todos os status (princípios da EF)

1. Estorno é sempre LIFO. Só se estorna o passo mais recente concluído. Para voltar do `04` ao `02`, o operador clica Estornar duas vezes.
2. Toda execução depende de confirmação explícita do operador no popup. O backend só executa quando recebe a confirmação do front.
3. Cada estorno faz duas coisas: (a) reversão física quando aplicável (cancelamento de movimento de material, anulação de lote QM) e (b) atualização da `ZDESCARGA` gravando o status anterior, limpando os campos do passo estornado e atualizando `AENAM = SY-UNAME` e `AEDAT = SY-DATUM`. Os campos de auditoria do passo original também são limpos (por exemplo `USUARIO_AMOSTRA`, `USUARIO_MEDICAO`).
4. Se a reversão física falhar, abortar e exibir a mensagem retornada pela BAPI/SAP. Não atualizar a `ZDESCARGA`.
5. Autorização: o estorno só é permitido para quem registrou o passo (campo de usuário do passo igual a `SY-UNAME`, por exemplo `AENAM`, `USUARIO_AMOSTRA`, `USUARIO_MEDICAO`) ou para perfil de Supervisor, controlado pelo objeto de autorização `ZS2M_DESC` com `ATIVIDADE = 'EST'`. Para os demais usuários o botão fica desabilitado.
6. Bloqueios de estorno: (a) status `06` com período contábil de `MBLNR_EM` já fechado; (b) status `05` com o produto já consumido em descarga posterior (a `ZMM_PROD_TANQUE` foi atualizada por outro TD depois deste).
7. Após qualquer estorno bem sucedido, registrar a auditoria descrita na seção 8.

---

## 3. Estorno do Status `02` (Registro da Amostra)

Reverte o passo 1.1.4. Tem reversão física: cancelamento do movimento 101 da amostra e anulação do lote de inspeção QM.

### 3.1 Pré-condições e validações
- Validar autorização (princípio 5).
- A linha deve existir em `ZDESCARGA` com `STATUS = 02`.

### 3.2 Texto do popup de confirmação (exibido pelo front)
> "Confirma o estorno do Registro da Amostra para o TD `<var_td>`? O documento de material da amostra (`<DOC_MATERIAL_AMOSTRA>`) sera cancelado, o lote QM (`<LOTE_QM>`) sera anulado e os campos da amostra serao limpos. O TD voltara ao Status 01."
> Botões: [Sim, estornar] [Cancelar]

### 3.3 Sequência de reversão (ordem obrigatória)

**Passo 1 — Cancelar o movimento 101 da amostra**
- BAPI: `BAPI_GOODSMVT_CANCEL_OIL`.
- Parâmetros de entrada:

| Parâmetro da BAPI | Origem |
|---|---|
| Documento de material | `ZDESCARGA-DOC_MATERIAL_AMOSTRA` |
| Ano do documento (MJAHR) | ver ponto em aberto P1 na seção 10 |

- Tratar a tabela `RETURN`. Em mensagem tipo `E` ou `A`, abortar todo o estorno e exibir a mensagem da BAPI. Não seguir para o passo 2.

**Passo 2 — Anular o lote de inspeção QM**
- Se a Decisão de Uso (`ZDESCARGA-DU_QM`) ainda NÃO foi gravada: usar `BAPI_INSPLOT_CANCEL` passando `PRUEFLOS = ZDESCARGA-LOTE_QM`.
- Se a Decisão de Uso JÁ existe: usar `BAPI_INSPLOT_USAGE_DECISION` para gravar uma UD de cancelamento, com o código de UD parametrizado na TVARV `ZS2M_UD_ESTORNO` (ver ponto em aberto P5).
- Tratar a tabela `RETURN`. Em erro, abortar e exibir a mensagem.

**Passo 3 — Atualizar a ZDESCARGA**
- Limpar (deixar em branco) os campos do passo de amostra:

| Campos a limpar na `ZDESCARGA` |
|---|
| `QTD_AMOSTRA`, `UM_AMOSTRA`, `COMPARTIMENTO`, `PONTO_AMOSTRAGEM`, `LGORT_AMOSTRA`, `DOC_MATERIAL_AMOSTRA`, `LOTE_MATERIAL_AMOSTRA`, `USUARIO_AMOSTRA`, `LOTE_QM`, `DU_QM` |

- Gravar `STATUS = '01 - Entrada Realizada (Veículo Chegou)'`.
- Atualizar `AENAM = SY-UNAME`, `AEDAT = SY-DATUM`.
- Persistir a alteração.

### 3.4 Mensagens
- Sucesso: "Amostra do TD `<var_td>` estornada. Documento `<DOC_MATERIAL_AMOSTRA>` cancelado e lote QM anulado. Status retornado para '01 - Entrada Realizada'."
- Erro: exibir a mensagem retornada pela BAPI que falhou e abortar sem atualizar a `ZDESCARGA`.

### 3.5 Resultado esperado
TD volta ao status `01`. Os campos de amostra aparecem em branco na tela. O movimento 101 da amostra está cancelado e o lote QM anulado.

---

## 4. Estorno do Status `03` (Escolha do Tanque)

Reverte o passo 1.1.5. NÃO tem reversão física de estoque: o passo só gravou campos na `ZDESCARGA`.

### 4.1 Pré-condições e validações
- Validar autorização (princípio 5).
- A linha deve existir em `ZDESCARGA` com `STATUS = 03`.

### 4.2 Texto do popup de confirmação (exibido pelo front)
> "Confirma o estorno da Escolha do Tanque para o TD `<var_td>`? Os campos de tanque, linha, plataforma e mangote serao limpos. Nenhum movimento de estoque sera revertido (este passo ainda nao gerou movimentacao). O TD voltara ao Status 02."
> Botões: [Sim, estornar] [Cancelar]

### 4.3 Sequência de reversão
**Passo único — Atualizar a ZDESCARGA**
- Limpar os campos do passo de escolha de tanque:

| Campos a limpar na `ZDESCARGA` |
|---|
| `LGORT_DESTINO`, `LINHA_DESCARGA`, `PLATAFORMA`, `MANGOTE`, `QTDE_SER_DESCARREGADA`, `MATERIAL_COMPATIVEL` |

- Gravar `STATUS = '02 - Amostra Retirada'`.
- Atualizar `AENAM = SY-UNAME`, `AEDAT = SY-DATUM`.
- Persistir a alteração.

### 4.4 Tratamento do PCS (ponto em aberto P4)
Se o centro for base PCS, este passo gravou `ZDESCARGA-PCS_ORDERNUM` na chamada da interface GAP 265. A EF não define se o estorno deve cancelar a ordem PCS ou apenas limpar o campo. Recomendação técnica para o Copilot seguir por ora: **limpar também o campo `PCS_ORDERNUM` na ZDESCARGA** junto com os demais. Confirmar com o funcional se é preciso disparar cancelamento na interface PCS. Ver P4 na seção 10.

### 4.5 Mensagens
- Sucesso: "Escolha do tanque do TD `<var_td>` estornada. Status retornado para '02 - Amostra Retirada'."
- Erro: "Falha ao atualizar a ZDESCARGA. `<texto do erro>`."

### 4.6 Resultado esperado
TD volta ao status `02`. Campos de tanque, linha, plataforma, mangote e compatibilidade em branco.

---

## 5. Estorno do Status `04` (Registro da Medição)

Reverte o passo 1.1.6. NÃO tem reversão física de estoque: a medição só gravou pesos e volume na `ZDESCARGA`.

### 5.1 Pré-condições e validações
- Validar autorização (princípio 5).
- A linha deve existir em `ZDESCARGA` com `STATUS = 04`.

### 5.2 Texto do popup de confirmação (exibido pelo front)
> "Confirma o estorno do Registro da Medicao para o TD `<var_td>`? Os campos de pesos, densidade e volume descarregado serao limpos. Nenhum movimento de estoque sera revertido (a medicao ainda nao gerou Entrada de Mercadoria). O TD voltara ao Status 03."
> Botões: [Sim, estornar] [Cancelar]

### 5.3 Sequência de reversão
**Passo único — Atualizar a ZDESCARGA**
- Limpar os campos do passo de medição:

| Campos a limpar na `ZDESCARGA` |
|---|
| `PESO_INICIAL`, `PESO_FINAL`, `DENSIDADE`, `VOLUME_AMOSTRA`, `VOLUME_DESCARREGADO`, `QTDE_MEDIDA`, `UM_MEDIDA`, `USUARIO_MEDICAO` |

- Gravar `STATUS = '03 - Tanque Final Selecionado'`.
- Atualizar `AENAM = SY-UNAME`, `AEDAT = SY-DATUM`.
- Persistir a alteração.

### 5.4 Mensagens
- Sucesso: "Medição do TD `<var_td>` estornada. Status retornado para '03 - Tanque Final Selecionado'."
- Erro: "Falha ao atualizar a ZDESCARGA. `<texto do erro>`."

### 5.5 Resultado esperado
TD volta ao status `03`. Pesos, densidade e volume em branco.

> Nota para o Copilot: os status `03` e `04` seguem exatamente o mesmo padrão (somente `UPDATE` com limpeza de campos e troca de status, sem BAPI). A única diferença entre eles é a lista de campos limpos e os status de origem e destino.

---

## 6. Estorno do Status `05` (Entrada de Mercadoria + Transferência 311)

Reverte o passo 1.1.7. É o cenário mais complexo. Tem reversão física de vários movimentos e restauração da `ZMM_PROD_TANQUE`.

### 6.1 Pré-validações OBRIGATÓRIAS (antes de exibir o popup)
- Consultar `ZMM_PROD_TANQUE` para `WERKS = ZDESCARGA-CENTRO_DESCARREGAMENTO` e `LGORT = ZDESCARGA-LGORT_DESTINO`. Se o registro atual NÃO foi gravado por este TD (a origem aponta para outro `SHNUMBER`), abortar com: "Não é possível estornar, o tanque `<LGORT_DESTINO>` já recebeu descarga posterior do TD `<outro_td>`. Estorne o TD posterior antes deste."
- Verificar o período contábil de `MBLNR_EM` em `T001B` / `MMRV`. Se fechado, abortar com: "Não é possível estornar, período contábil de `<MBLNR_EM>` / `<MJAHR_EM>` já encerrado. Abrir chamado para reabertura."
- Validar autorização (princípio 5).

### 6.2 Texto do popup de confirmação (exibido pelo front)
> "Confirma o estorno da Entrada de Mercadoria + Transferencia ao Tanque para o TD `<var_td>`? Serao cancelados os documentos: Transferencia 311 `<MBLNR_311>`, Entrada de Mercadoria `<MBLNR_EM>`, Volume Extra Drenado `<DOC_MATERIAL_EXTRA_DRENADO>` (se houver) e Perdas/Sobras `<DOC_PERDAS_SOBRAS>`. O produto anterior do tanque sera restaurado em ZMM_PROD_TANQUE. O TD voltara ao Status 04."
> Botões: [Sim, estornar] [Cancelar]

### 6.3 Sequência de reversão (ordem reversa à 1.1.7, obrigatória)

**Passo 1 — Cancelar o movimento 311 (transferência ao tanque)**
- BAPI: `BAPI_GOODSMVT_CANCEL_OIL`.

| Parâmetro da BAPI | Origem |
|---|---|
| Documento de material | `ZDESCARGA-MBLNR_311` |
| Ano do documento (MJAHR) | ver ponto em aberto P1 na seção 10 |

- Tratar `RETURN`. Em erro, abortar e exibir a mensagem identificando a etapa: "Falha no estorno do mov. 311, `<texto da BAPI>`."

**Passo 2 — Cancelar o movimento 101 da Entrada de Mercadoria**
- BAPI: `BAPI_GOODSMVT_CANCEL_OIL`.

| Parâmetro da BAPI | Origem |
|---|---|
| Documento de material | `ZDESCARGA-MBLNR_EM` |
| Ano do documento (MJAHR) | `ZDESCARGA-MJAHR_EM` |

- Tratar `RETURN`. Em erro, abortar e exibir: "Falha no estorno do mov. 101, `<texto da BAPI>`."

**Passo 3 — Cancelar o movimento 101 do Volume Extra Drenado (condicional)**
- Executar somente se `ZDESCARGA-VOLUME_EXTRA_DRENADO > 0`.
- BAPI: `BAPI_GOODSMVT_CANCEL_OIL`.

| Parâmetro da BAPI | Origem |
|---|---|
| Documento de material | `ZDESCARGA-DOC_MATERIAL_EXTRA_DRENADO` |
| Ano do documento (MJAHR) | ver ponto em aberto P1 na seção 10 |

- Tratar `RETURN`.

**Passo 4 — Cancelar os movimentos de Perdas e Sobras (951 / 941) (condicional)**
- Executar somente se `ZDESCARGA-DOC_PERDAS_SOBRAS` estiver preenchido.
- Atenção: `DOC_PERDAS_SOBRAS` é uma lista de documentos de material separados por vírgula. É preciso separar a lista e cancelar cada documento individualmente.
- BAPI por documento: `BAPI_GOODSMVT_CANCEL_OIL`.

| Parâmetro da BAPI | Origem |
|---|---|
| Documento de material | cada item da lista `ZDESCARGA-DOC_PERDAS_SOBRAS` |
| Ano do documento (MJAHR) | ver ponto em aberto P1 na seção 10 |

- Tratar `RETURN` de cada cancelamento.

**Passo 5 — Restaurar a ZMM_PROD_TANQUE**
- Objetivo: devolver ao tanque o produto que estava lá antes desta descarga.
- Fonte do produto anterior, na ordem de preferência:
  1. Tabela auxiliar de histórico `ZMM_PROD_TANQUE_HIST`, se existir.
  2. Caso não exista histórico, o último TD anterior em `ZDESCARGA` para o mesmo `WERKS + LGORT_DESTINO` com `STATUS` em (`05`, `06`).
- Gravar o material anterior como produto corrente do tanque na `ZMM_PROD_TANQUE`.
- Se não houver histórico nenhum, deixar a `ZMM_PROD_TANQUE` em branco para aquele tanque.

**Passo 6 — Atualizar a ZDESCARGA**
- Limpar os campos do passo de entrada de mercadoria:

| Campos a limpar na `ZDESCARGA` |
|---|
| `MBLNR_EM`, `MJAHR_EM`, `LOTE_MATERIAL_EM`, `QTDE_ENTRADA_MERCADORIA`, `VOLUME_EXTRA_DRENADO`, `DOC_MATERIAL_EXTRA_DRENADO`, `LOTE_MATERIAL_EXTRA_DRENADO`, `DOC_PERDAS_SOBRAS`, `DT_EM`, `HR_EM` |

- Gravar `STATUS = '04 - Em Descarga / Medição Registrada'`.
- Atualizar `AENAM = SY-UNAME`, `AEDAT = SY-DATUM`.
- Persistir a alteração.

### 6.4 Tratamento de estorno parcial (regra crítica da EF)
Se uma etapa intermediária já tiver sido executada com sucesso e a seguinte falhar (exemplo: 311 cancelado, mas o 101 falhou), NÃO tentar reaplicar o 311 automaticamente. Exibir alerta orientando contato com o suporte para reconciliação manual, identificando em qual movimento parou. Abortar sem prosseguir e sem atualizar a `ZDESCARGA`.

### 6.5 Mensagens
- Sucesso: "Entrada de Mercadoria e Transferência 311 do TD `<var_td>` estornadas. Documentos cancelados: `<MBLNR_311>`, `<MBLNR_EM>`, `<DOC_MATERIAL_EXTRA_DRENADO>`, `<DOC_PERDAS_SOBRAS>`. Produto anterior restaurado no tanque `<LGORT_DESTINO>`. Status retornado para '04'."
- Erro: mensagem específica da etapa que falhou (ver 6.3 e 6.4).

### 6.6 Resultado esperado
TD volta ao status `04`. Todos os movimentos de estoque do passo 1.1.7 cancelados, produto anterior restaurado no tanque, campos de entrada de mercadoria em branco.

---

## 7. Estorno do Status `06` (Concluído / Reabertura do TD)

Reverte a finalização do passo 1.1.7. NÃO tem reversão física de estoque: apenas reverte a confirmação lógica do TD. Para reverter a entrada de mercadoria, o operador precisa clicar Estornar de novo depois (cai no cenário do status `05`).

### 7.1 Pré-validação OBRIGATÓRIA (antes de exibir o popup)
- Verificar o período contábil de `MBLNR_EM` em `T001B` / `MMRV`. Se fechado, abortar com: "Não é possível reabrir TD concluído, período contábil já encerrado. Abrir chamado para reabertura."
- Validar autorização (princípio 5).

### 7.2 Texto do popup de confirmação (exibido pelo front)
> "Confirma a reabertura do TD `<var_td>` (estorno da conclusao)? Os indicadores de confirmacao (TDICH/TSTMP) e data/hora de finalizacao serao limpos. Nenhum movimento de estoque sera revertido nesta etapa, para estornar a Entrada de Mercadoria clique Estornar novamente apos esta operacao. O TD voltara ao Status 05."
> Botões: [Sim, reabrir] [Cancelar]

### 7.3 Sequência de reversão
**Passo único — Atualizar a ZDESCARGA**
- Limpar os campos de confirmação:

| Campos a limpar na `ZDESCARGA` |
|---|
| `TDICH_CONF`, `TSTMP_CONF`, `DT_CONF`, `HR_CONF`, `DT_FIM`, `HR_FIM`, `STATUS_TD` |

- Gravar `STATUS = '05 - Transferido para Tanque'`.
- Atualizar `AENAM = SY-UNAME`, `AEDAT = SY-DATUM`.
- Persistir a alteração.

### 7.4 Mensagens
- Sucesso: "TD `<var_td>` reaberto. Status retornado para '05 - Transferido para Tanque'. Para estornar a Entrada de Mercadoria, clique Estornar novamente."
- Erro: "Falha ao reabrir o TD. `<texto do erro>`."

### 7.5 Resultado esperado
TD volta ao status `05`. Indicadores de confirmação e datas de finalização em branco.

---

## 8. Auditoria (obrigatória em todos os status)

Após qualquer estorno bem sucedido:
1. A `ZDESCARGA` deve ter o registro de Change Document ativo em `CDHDR` / `CDPOS`, gravando automaticamente quem alterou, quando e quais campos mudaram.
2. Gravar uma entrada na tabela de log `ZS2M_LOG_ESTORNO` contendo: `SHNUMBER`, `REMESSA`, `STATUS_ANTERIOR`, `STATUS_NOVO`, documentos de material estornados, usuário (`SY-UNAME`), timestamp e a mensagem de retorno. Esse log é consultado pelo Supervisor no painel de operações.

---

## 9. Referência: estorno do Status `01` (já implementado)

Serve de padrão para os demais. Reverte o passo 1.1.3. Não tem reversão física: a chegada só gravou na `ZDESCARGA`.
- Execução: `DELETE` da linha em `ZDESCARGA` pela chave `SHNUMBER + REMESSA + ITEM_REMESSA` e persistir.
- Status resultante: `00 - Pendente Descarga` (a linha deixa de existir e o TD volta a aparecer como pendente na listagem).
- Sucesso: "Chegada do TD `<var_td>` estornada. Linha removida da ZDESCARGA."

---

## 10. Pontos em aberto (recomendação técnica + confirmação do funcional)

Para cada item abaixo há uma recomendação para o Copilot seguir e não travar, e em paralelo uma pendência a confirmar com o funcional (Luis Tacioli). Onde o funcional confirmar diferente, ajustar.

| ID | Onde impacta | Lacuna na EF | Recomendação para seguir agora | A confirmar com o funcional |
|---|---|---|---|---|
| P1 | Status `02` e `05` | A `ZDESCARGA` guarda `MBLNR_311`, `DOC_MATERIAL_EXTRA_DRENADO`, `DOC_PERDAS_SOBRAS` e o documento da amostra, mas NÃO guarda o ano (MJAHR) desses documentos. A BAPI de cancelamento exige MBLNR e MJAHR. | Derivar o MJAHR lendo `MKPF` pelo `MBLNR` de cada documento no momento do estorno. | Se preferem acrescentar campos de ano na `ZDESCARGA` em vez de derivar do MKPF. |
| P2 | Status `02` e `05` | A EF cita `BAPI_GOODSMVT_CANCEL_OIL` para o cancelamento. Em alguns releases IS-Oil o estorno é feito por `BAPI_GOODSMVT_CREATE_OIL` com `GM_CODE = '06'` referenciando o documento original. | Usar `BAPI_GOODSMVT_CANCEL_OIL` conforme a EF. | Confirmar qual BAPI de estorno OIL está liberada e homologada no ambiente Iconic. Decisão mais importante dos status 02 e 05. |
| P3 | Status `02` | A EF menciona anular o lote QM, mas o código de UD de cancelamento não está definido. | Ler o código de UD de cancelamento da TVARV `ZS2M_UD_ESTORNO`. | Definir o código de UD de cancelamento e popular a TVARV. |
| P4 | Status `03` | Em base PCS o passo gravou `PCS_ORDERNUM` (interface GAP 265). A EF não diz se o estorno cancela a ordem PCS ou só limpa o campo. | Limpar o campo `PCS_ORDERNUM` na `ZDESCARGA` junto com os demais. | Se é necessário disparar cancelamento da ordem na interface PCS, ou se limpar o campo é suficiente. |
| P5 | Status `05` | A restauração da `ZMM_PROD_TANQUE` depende de um histórico (`ZMM_PROD_TANQUE_HIST`) cuja existência a EF não confirma. | Tentar a tabela de histórico, com fallback no último TD anterior em `ZDESCARGA` para o mesmo tanque, conforme passo 5 do status 05. | Confirmar se a `ZMM_PROD_TANQUE_HIST` existe e é mantida, ou se o fallback por `ZDESCARGA` é a fonte oficial. |
| P6 | Status `06` | O caso de teste `UT-11` da EF diz que descarga finalizada não pode ser cancelada, o que aparenta conflitar com o estorno do status `06` (reabertura permitida). | Implementar o status `06` como reabertura, conforme seção 7. | Esclarecer a fronteira entre "cancelar" (bloqueado pelo UT-11) e "estornar/reabrir" (permitido). Pode ser só diferença de terminologia. |
| P7 | Status `02` e `05` | A EF não detalha o nome da classe handler que recebe a action OData `CancelarDescarga` do serviço `ZS2M_DESCARGA_SRV`. | Implementar os tratamentos dentro do método já existente do orquestrador. | Confirmar o nome da classe handler para o Copilot apontar corretamente. |
