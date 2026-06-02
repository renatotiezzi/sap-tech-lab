# Ajustes V11 - De-Para Bandeira via TVARVC

## Objetivo
Remover o **hardcode** do de-para introduzido na V10. A tradução `tipoArquivo → operacao` passa a ser lida da tabela de variáveis customizáveis `ZZ1_TVARVC_Q2C` (a mesma já usada pelo job de cleanup `ZCL_Q2C_ARQ_CLEANUP` para o parâmetro `ZZ_GAP014_ARQ_DIAS`).

## Como funciona
`ZI_Q2C_ARQ_MGR` agora faz `LEFT OUTER TO ONE JOIN` em `ZZ1_TVARVC_Q2C`:

```
NAME = 'ZZ_GAP014_BAND_DEPARA'
TYPE = 'S'
LOW  = tipoArquivo (ex.: PMDREN)
HIGH = operacao    (ex.: DSH_Renault)
```

`BandeiraDesc = coalesce( dep.high, arq.bandeira )` — sem entrada cadastrada exibe a própria Bandeira (fallback seguro).

A coluna no Fiori continua usando `@ObjectModel.text.element: ['BandeiraDesc']` + `@UI.textArrangement: #TEXT_ONLY` (sem mudança no DDLX).

## Objeto alterado (1)
- **ZI_Q2C_ARQ_MGR.ddls.txt** — substituído `CASE` hardcoded por join à `ZZ1_TVARVC_Q2C`.

## Pré-requisito de carga (SM30 ou maintenance da tabela)

Inserir as entradas abaixo em `ZZ1_TVARVC_Q2C` (NUMB sequencial, MANDT do client):

| NAME                   | TYPE | NUMB | LOW         | HIGH          |
|------------------------|------|------|-------------|---------------|
| ZZ_GAP014_BAND_DEPARA  | S    | 0001 | PMDDSOP     | PFCO_Volvo    |
| ZZ_GAP014_BAND_DEPARA  | S    | 0002 | PMDDSOX     | PRCO_Volvo    |
| ZZ_GAP014_BAND_DEPARA  | S    | 0003 | PMDDAFDSOP  | PFCO_Daf      |
| ZZ_GAP014_BAND_DEPARA  | S    | 0004 | PMDDAFDSOX  | PRCO_Daf      |
| ZZ_GAP014_BAND_DEPARA  | S    | 0005 | PMDVOLV     | DSH_Volvo     |
| ZZ_GAP014_BAND_DEPARA  | S    | 0006 | PMDREN      | DSH_Renault   |
| ZZ_GAP014_BAND_DEPARA  | S    | 0007 | PMDFORD     | DSH_Ford      |
| ZZ_GAP014_BAND_DEPARA  | S    | 0008 | PMDDPASC    | DSH_DPaschoal |
| ZZ_GAP014_BAND_DEPARA  | S    | 0009 | PMDJCB      | DSH_JCB       |
| ZZ_GAP014_BAND_DEPARA  | S    | 0010 | PMDDASA     | DSH_DASA      |
| ZZ_GAP014_BAND_DEPARA  | S    | 0011 | PMDHYDRO    | DSH_HYDRO     |

> Para adicionar/alterar bandeiras no futuro: somente manter a tabela. **Sem retransporte de código.**

## Deploy
1. Carregar entradas na `ZZ1_TVARVC_Q2C` (acima).
2. Ativar `ZI_Q2C_ARQ_MGR`.
3. `ZC_Q2C_ARQ_MGR_APP` e `ZC_Q2C_ARQ_MGR_APP_MDE` permanecem como na V10 (não precisam reativar).

Sem republicar serviço — contrato OData inalterado.
