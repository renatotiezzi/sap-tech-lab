# V9 - Job App Cleanup - Objects Guide

Guia dos objetos necessarios para o Job App de limpeza do CR51.

## Objetos ABAP principais

- Classe runtime/design-time:
  - `ZCL_Q2C_ARQ_CLEANUP`
  - Interfaces:
    - `IF_APJ_DT_EXEC_OBJECT`
    - `IF_APJ_RT_EXEC_OBJECT`

- Programa seed de massa para teste:
  - `ZR_Q2C_CLEANUP_SEED_DATA`

- Programa executor direto (sem App Job):
  - `ZR_Q2C_CLEANUP_RUNNER`

## Tabelas utilizadas

- `ZTBQ2C_ARQ_MGR`
- `ZTBQ2C_LOG_MGR`
- `ZZ1_TVARVC_Q2C` (parametro de retencao)

## Application Log (SLG0/SLG1)

- Objeto: `ZQ2C_ARQ`
- Subobjeto: `CLEANUP`
- Persistencia via BALI (`CL_BALI_LOG_DB`)

### Pre-requisito obrigatorio no SAP

1. Acessar transacao `SLG0`.
2. Criar objeto de log `ZQ2C_ARQ`.
3. Criar subobjeto `CLEANUP` para o objeto acima.
4. Salvar em request e transportar para o ambiente alvo.
5. Validar em `SLG1` que objeto/subobjeto existem para selecao.

Sem esse cadastro no `SLG0`, a construcao/persistencia do log via BALI pode falhar em runtime.

## Text Symbols da classe ZCL_Q2C_ARQ_CLEANUP

- `001` `P_DIAS`
- `002` `P_TESTE`
- `003` `Retenção (dias)`
- `004` `Modo Teste (sem delete)`
- `005` `MODO TESTE ativo — nenhum registro foi deletado.`
- `006` `Nenhum registro elegível — nada a deletar.`
- `007` `CLEANUP_`
- `008` `Cleanup iniciado — Status: `
- `009` `, corte: `
- `010` ` dias)`
- `011` `Registros elegíveis → ARQ: `
- `012` ` / LOG: `
- `013` `Concluído — deletados: ARQ `
- `014` ` / LOG `

## Objetos de App Job no SAP (transacional)

1. Application Job Catalog Entry (referenciando a classe)
2. Application Job Template (parametros `P_DIAS` e `P_TESTE`)
3. Application Log Object/Subobject (`ZQ2C_ARQ` / `CLEANUP`)

## Fluxo de teste first-time-right

0. Confirmar pre-requisito de log no `SLG0` (`ZQ2C_ARQ` / `CLEANUP`).
1. Rodar `ZR_Q2C_CLEANUP_SEED_DATA` para gerar dados antigos (>90 dias).
2. Rodar `ZR_Q2C_CLEANUP_RUNNER` com `P_TESTE = X`.
3. Validar logs no SLG1.
4. Rodar novamente com `P_TESTE` em branco para efetivar delete.
5. Confirmar contagens em `ZTBQ2C_ARQ_MGR` e `ZTBQ2C_LOG_MGR`.
