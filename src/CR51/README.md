# CR 051 — Gap 014: Reprocessamento MGR (Q2C)

## Package: `ZPQ2C_014`

Documentação dos objetos DDIC do Gap 014 - CR 051.  
Todos os objetos seguem o padrão de nomenclatura do projeto:

| Tipo | Abreviação | Padrão |
|------|-----------|--------|
| Package | P | `ZPMMM_XXXXXXXXXX` |
| Table | TB | `ZTBMMM_XXXXXXXXX` |
| Data Element | DE | `ZDEMMM_XXXXXXXXXX` |
| Domain | DO | `ZDOMMM_XXXXXXXXXX` |

> **MMM** = `Q2C` (módulo Quote-to-Cash)

---

## Objetos criados

### Domains (`database/`)

| Objeto | Status | Descrição |
|--------|--------|-----------|
| `ZDOQ2C_ETAPA` | ✅ Ativo | Etapa do processamento (1–6) |
| `ZDOQ2C_STATUS` | 🔲 Criar | Status do arquivo MGR (1–4) |

### Data Elements (`database/`)

| Objeto | Status | Label | Base |
|--------|--------|-------|------|
| `ZDEQ2C_ETAPA` | ✅ Ativo | Etapa | `ZDOQ2C_ETAPA` |
| `ZDEQ2C_ID_LOG` | ✅ Ativo | ID Log | NUMC 10 |
| `ZDEQ2C_ID_REF` | ✅ Ativo | ID_Referência | NUMC 10 |
| `ZDEQ2C_ID_ARQ` | 🔲 Criar | ID Arquivo | NUMC 10 |
| `ZDEQ2C_TIPO_DOC` | 🔲 Criar | Tipo Doc. Vendas | CHAR 4 |
| `ZDEQ2C_CABEC_ARQ` | 🔲 Criar | Cabeçalho Arquivo | CHAR 100 |
| `ZDEQ2C_BANDEIRA` | 🔲 Criar | Bandeira | CHAR 10 |
| `ZDEQ2C_CONTEUDO` | 🔲 Criar | Conteúdo | RAWSTRING |
| `ZDEQ2C_STATUS_MGR` | 🔲 Criar | Status MGR | `ZDOQ2C_STATUS` |
| `ZDEQ2C_TENTATIVAS` | 🔲 Criar | Nº Tentativas | INT4 |
| `ZDEQ2C_ULTIMO_ERR` | 🔲 Criar | Último Erro | CHAR 255 |
| `ZDEQ2C_MENSAGEM` | 🔲 Criar | Mensagem | STRING |

### Tabelas (`database/`)

| Objeto | Status | Descrição |
|--------|--------|-----------|
| `ZTBQ2C_ARQ_MGR` | 🔲 Criar | Arquivos de entrada recebidos da MGR |
| `ZTBQ2C_LOG_MGR` | 🔲 Criar | Log de processamento por etapa |
