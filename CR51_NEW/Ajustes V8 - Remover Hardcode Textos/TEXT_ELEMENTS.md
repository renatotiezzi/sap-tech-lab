# Text Elements — V8 (Remover Hardcode de Textos)

Criar via **SE80 → Class/Interface → [Objeto] → Goto → Text Elements → Text Symbols**

---

## ZBP_I_Q2C_ARQ_MGR

> SE80 → Class/Interface → `ZBP_I_Q2C_ARQ_MGR` → Goto → Text Elements → Text Symbols

| Sym | Text                            | Usado em               |
|-----|---------------------------------|------------------------|
| 001 | `CANCELADO`                     | reprocess, cancel      |
| 002 | `PROCESSADO`                    | reprocess, cancel      |
| 003 | `EM_PROCESSAMENTO`              | reprocess              |
| 004 | `REPROCESSAMENTO`               | reprocess              |
| 005 | `Reprocessamento iniciado`      | reprocess              |
| 006 | `CPI_REPROCESS`                 | reprocess              |
| 007 | `CANCELAMENTO`                  | cancel                 |
| 008 | `Registro cancelado manualmente`                            | cancel                 |
| 009 | `Registro`                                                  | reprocess, cancel      |
| 010 | `não pode ser reprocessado (status:`                        | reprocess              |
| 011 | `já foi processado — reprocessamento não permitido`         | reprocess              |
| 012 | `já processado — cancelamento não permitido`                | cancel                 |

---

## ZCL_Q2C_CPI_CALLER

> SE80 → Class/Interface → `ZCL_Q2C_CPI_CALLER` → Goto → Text Elements → Text Symbols

| Sym | Text               | Usado em          |
|-----|--------------------|-------------------|
| 001 | `Content-Type`                                            | execute_http_call |
| 002 | `application/json`                                       | execute_http_call |
| 003 | `Destino RFC '`                                          | execute_http_call |
| 004 | `' não encontrado/acessível (subrc=`                     | execute_http_call |
| 005 | `Falha de comunicação HTTP ao enviar para CPI (subrc=`  | execute_http_call |
| 006 | `Falha ao receber resposta do CPI (subrc=`               | execute_http_call |
| 007 | `CPI HTTP `                                              | execute_http_call |

---

## ZCL_Q2C_ARQ_CLEANUP

> SE80 → Class/Interface → `ZCL_Q2C_ARQ_CLEANUP` → Goto → Text Elements → Text Symbols

| Sym | Text                                              | Usado em           |
|-----|---------------------------------------------------|--------------------|
| 001 | `P_DIAS`                                          | get_parameters, execute |
| 002 | `P_TESTE`                                         | get_parameters, execute |
| 003 | `Retenção (dias)`                                 | get_parameters     |
| 004 | `Modo Teste (sem delete)`                         | get_parameters     |
| 005 | `MODO TESTE ativo — nenhum registro foi deletado.`| execute            |
| 006 | `Nenhum registro elegível — nada a deletar.`      | execute            |
