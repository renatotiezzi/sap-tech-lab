# Ajustes V10 - De-Para Bandeira

## Objetivo
Exibir, na coluna **Bandeira** do List Report e Object Page do Monitor de Arquivos (Arq - Monitor), a **operação** (nome amigável) em vez do **tipoArquivo** técnico vindo da integração.

A coluna continua sendo a chave técnica `Bandeira` (campo `ztbq2c_arq_mgr-bandeira`), mas o Fiori passa a renderizar somente o texto derivado via `@UI.textArrangement: #TEXT_ONLY` apontando para o novo elemento `BandeiraDesc`.

## Mapeamento aplicado

| tipoArquivo (de) | operação (para)  |
|------------------|------------------|
| PMDDSOP          | PFCO_Volvo       |
| PMDDSOX          | PRCO_Volvo       |
| PMDDAFDSOP       | PFCO_Daf         |
| PMDDAFDSOX       | PRCO_Daf         |
| PMDVOLV          | DSH_Volvo        |
| PMDREN           | DSH_Renault      |
| PMDFORD          | DSH_Ford         |
| PMDDPASC         | DSH_DPaschoal    |
| PMDJCB           | DSH_JCB          |
| PMDDASA          | DSH_DASA         |
| PMDHYDRO         | DSH_HYDRO        |

Valores não mapeados caem no `else` e exibem o próprio `Bandeira` (fallback seguro – linhas antigas/novos códigos não somem da tela).

## Objetos alterados (3)

1. **ZI_Q2C_ARQ_MGR.ddls.txt** – CDS interface
   - Adicionado elemento computado `BandeiraDesc` (`cast( case ... as abap.char(20) )`) com o de-para.
2. **ZC_Q2C_ARQ_MGR_APP.ddls.txt** – CDS projection (consumption)
   - Projetado o campo `BandeiraDesc`.
3. **ZC_Q2C_ARQ_MGR_APP_MDE.ddlx.txt** – Metadata Extension
   - `@ObjectModel.text.element: [ 'BandeiraDesc' ]` + `@UI.textArrangement: #TEXT_ONLY` em `Bandeira`.
   - `BandeiraDesc` marcado como `@UI.hidden: true` (não vira coluna própria).

## Sem mudança funcional
- Tabela `ztbq2c_arq_mgr` não muda (chave técnica preservada).
- Filtros, ações (Reprocess/Cancel), CPI caller, jobs e logs continuam usando `Bandeira` técnica.
- Não há alteração em behavior/handler.

## Deploy
Ativar nesta ordem:
1. `ZI_Q2C_ARQ_MGR` (DDLS)
2. `ZC_Q2C_ARQ_MGR_APP` (DDLS)
3. `ZC_Q2C_ARQ_MGR_APP_MDE` (DDLX)

Sem necessidade de republicar o serviço (`ZSB_Q2C_ARQ_MGR_APP`) – contrato OData inalterado, apenas anotações UI/text association.

## Como adicionar novas bandeiras no futuro
Editar somente o `CASE` de `ZI_Q2C_ARQ_MGR.ddls.txt`, ativar a view. Nenhum outro objeto precisa mexer.
