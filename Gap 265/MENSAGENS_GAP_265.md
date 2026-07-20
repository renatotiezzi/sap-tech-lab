# GAP 265 - Inventario de Mensagens de Erro

## Objetivo

Este documento consolida as mensagens usadas no GAP 265, com foco em:

- mensagens do Outbound (`zclq2c_265_descarga_granel`)
- mensagens do Inbound (`zclq2c_265_desc_ret_granel`)
- helper comum de mensagens (`zclq2c_265_desc_common`)
- orientacao sobre a mensagem `012` do trecho:

```abap
IF iv_reference IS INITIAL.
  zclq2c_265_desc_common=>add_error(
    EXPORTING iv_number = '012'
              iv_v1     = 'Referencia da ordem nao informada'
    CHANGING  ct_message = ct_msg ).
  RETURN.
ENDIF.
```

## 1. Classes de mensagens identificadas

| Classe | Papel | Observacao |
|---|---|---|
| `ZCL_Q2C_265_MSG_CG` | Message Class da Carga | Existe no repo como `zcl_q2c_265_msg_cg.msag.xml` |
| `ZCL_Q2C_265_MSG_DG` | Message Class da Descarga | Referenciada pela classe comum `zclq2c_265_desc_common` |

## 2. Regra tecnica importante

A classe comum `zclq2c_265_desc_common` nao gera texto de mensagem por conta propria.
Ela so monta a estrutura de mensagem com:

- `id` = classe de mensagem
- `number` = numero da mensagem
- `type` = `E` ou `S`
- `severity`
- `v1` / `v2`

Isso significa que o numero usado no codigo precisa existir na Message Class associada.

## 2.1 Como interpretar a origem das mensagens

- `zclq2c_265_descarga_granel` e `zclq2c_265_desc_ret_granel` sao os emissores reais dos erros e sucessos.
- `zclq2c_265_desc_common` apenas centraliza o append na tabela de mensagens.
- No repo atual, a classe de mensagens efetivamente exportada para o SAP aparece como `ZCL_Q2C_265_MSG_CG`.
- A descarga referencia `ZCL_Q2C_265_MSG_DG` no helper comum, mas o `.msag.xml` dessa classe nao apareceu no repo; por isso, os numeros abaixo foram levantados do codigo-fonte e precisam ser conferidos no SE91.

## 3. Inventario de mensagens encontradas no codigo

### 3.0 Inventario consolidado

| Classe | Numero | Tipo | Texto recomendado / usado no codigo | Origem |
|---|---|---|---|---|
| `ZCL_Q2C_265_MSG_DG` | 011 | S | Arquivo gravado com sucesso / Arquivo processado com sucesso | Outbound / Inbound |
| `ZCL_Q2C_265_MSG_DG` | 012 | E | Referencia da ordem nao informada | Outbound |
| `ZCL_Q2C_265_MSG_DG` | 020 | E | Diretório/TVARVC obrigatorio nao preenchido | Outbound / Inbound |
| `ZCL_Q2C_265_MSG_DG` | 025 | E | Erro de conversao de peso / valor numerico | Inbound |
| `ZCL_Q2C_265_MSG_DG` | 030 | E | Referencia nao encontrada / ORDERNUM nao localizado | Outbound / Inbound |
| `ZCL_Q2C_265_MSG_DG` | 031 | E | Campo obrigatorio nao preenchido | Outbound |
| `ZCL_Q2C_265_MSG_DG` | 032 | E | Lacres da descarga nao informados | Outbound |
| `ZCL_Q2C_265_MSG_DG` | 033 | E | Status da ordem nao identificado | Outbound |
| `ZCL_Q2C_265_MSG_DG` | 034 | E | Status invalido para envio PCS | Outbound |
| `ZCL_Q2C_265_MSG_DG` | 035 | E | Cancelamento permitido apenas no status 03 | Outbound |
| `ZCL_Q2C_265_MSG_DG` | 036 | E | Referencia nao encontrada / ORDERNUM nao existe no SAP | Inbound |
| `ZCL_Q2C_265_MSG_DG` | 037 | E | Inconsistencia de arquivos de retorno | Inbound |
| `ZCL_Q2C_265_MSG_DG` | 040 | E | Erro ao gravar arquivo | Outbound |
| `ZCL_Q2C_265_MSG_DG` | 041 | E | Erro ao ler arquivo | Inbound |

### 3.1 Consolidado por classe e numero de uso

### 3.1 Outbound - `zclq2c_265_descarga_granel`

| Numero | Tipo | Uso observado |
|---|---|---|
| 011 | S | Arquivo gravado com sucesso / mensagem de sucesso do processo |
| 012 | E | Referencia da ordem nao informada |
| 020 | E | TVARVC obrigatorio nao preenchido (`ZQ2C_DESCARGA_PCS_OUT`, `ZQ2C_DESCARGA_PCS_IN`) |
| 030 | E | Referencia nao encontrada / ORDERNUM nao localizado para cancelamento |
| 031 | E | Campo obrigatorio nao preenchido |
| 032 | E | Lacres da descarga nao informados |
| 033 | E | Status da ordem nao identificado |
| 034 | E | Status invalido para envio PCS |
| 035 | E | Cancelamento permitido apenas no status 03 |
| 040 | E | Erro ao gravar arquivo |

### 3.1.1 Como a mensagem deve ficar na pratica

Para cada chamada de `add_error` ou `add_success`, o numero indicado no codigo deve apontar para um texto T100 claro e curto. Exemplo:

| Numero | Texto sugerido |
|---|---|
| 012 | Referencia da ordem nao informada |
| 030 | Referencia nao encontrada: &1 |
| 040 | Erro ao gravar arquivo: &1 |

### 3.2 Inbound - `zclq2c_265_desc_ret_granel`

| Numero | Tipo | Uso observado |
|---|---|---|
| 011 | S | Arquivo processado com sucesso |
| 020 | E | TVARVC obrigatorio nao preenchido |
| 025 | E | Erro de conversao de peso / valor numerico |
| 030 | E | ORDERNUM nao localizado para cancelamento |
| 036 | E | Referencia nao encontrada / ORDERNUM nao existe no SAP |
| 037 | E | Inconsistencia de arquivos de retorno |
| 041 | E | Erro ao ler arquivo |

### 3.2.1 Como a mensagem deve ficar na pratica

| Numero | Texto sugerido |
|---|---|
| 011 | Arquivo &1 processado com sucesso |
| 025 | Erro de conversao de peso / valor numerico: &1 |
| 036 | ORDERNUM nao existe no SAP: &1 |
| 037 | Inconsistencia de arquivos de retorno: &1 |
| 041 | Erro ao ler arquivo: &1 |

## 4. Resposta objetiva sobre a mensagem 012

Sim, a mensagem `012` deve existir na Message Class do GAP 265 se o codigo continuar chamando:

```abap
zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '012' ... )
```

Se essa mensagem nao existir em `ZCL_Q2C_265_MSG_DG`, o runtime vai carregar um numero sem texto util.

### Recomendacao

- **Manter `012`** para nao quebrar o codigo existente.
- Criar a entrada T100 correspondente na classe de mensagens da Descarga (`ZCL_Q2C_265_MSG_DG`).

### Texto sugerido para a 012

| Numero | Tipo | Texto sugerido |
|---|---|---|
| 012 | E | Referencia da ordem nao informada |

### Regra pratica de numero

- Se o codigo ja chama um numero, o numero precisa existir na classe de mensagem.
- Se quiser padronizar melhor o GAP 265, a `012` pode ser mantida como numero funcional da Descarga.
- Nao ha evidência no repo de uma `ZCL_Q2C_265_MSG_DG.msag.xml`; entao a confirmacao final precisa ser feita no SE91.

## 5. Exemplo de padrao para classe de mensagem

Exemplo de convencao simples e direta:

| Numero | Tipo | Texto |
|---|---|---|
| 001 | E | Erro generico &1 |
| 002 | E | Campo obrigatorio nao preenchido: &1 |
| 003 | E | Referencia nao encontrada: &1 |

Esse padrao funciona, mas no GAP 265 o ideal e manter os numeros ja usados pelo codigo para nao exigir refatoracao desnecessaria.

## 6. Observacao importante

No repo atual existe o arquivo da Message Class da Carga (`ZCL_Q2C_265_MSG_CG`), mas nao apareceu um `.msag.xml` da Descarga (`ZCL_Q2C_265_MSG_DG`).

Conclusao pratica:

- a mensagem `012` precisa existir no SAP se o codigo continuar usando esse numero;
- se a classe `ZCL_Q2C_265_MSG_DG` ainda nao tiver sido exportada para o repo, ela deve ser conferida no sistema antes de concluir que a mensagem falta;
- a verificacao mais segura e abrir a Message Class no SE91 e confirmar os numeros 011, 012, 020, 030, 031, 032, 033, 034, 035, 040, 025, 036, 037 e 041.

## 7. Resposta curta para o caso do snippet

Sim, deve existir uma entrada de mensagem para `012` na classe de mensagens usada por `zclq2c_265_desc_common`.
Se voce quiser seguir o padrao mais limpo, esse `012` fica em `ZCL_Q2C_265_MSG_DG` com o texto:

- `Referencia da ordem nao informada`

Se preferir uma convencao mais semantica, poderia renumerar para `001`, mas isso exigiria ajustar o codigo que hoje chama `012`.
