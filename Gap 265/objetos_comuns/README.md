# objetos_comuns — GAP 265

Objetos técnicos de apoio **compartilhados** entre Descarga Outbound e Descarga
Inbound/Retorno do GAP 265.

## Conteúdo

| Tipo | Quantidade | Descrição |
|---|---|---|
| `.dtel.xml` | 29 | Data Elements dos payloads U200-H/U200-S (Outbound) e U301-H/U301-S (Inbound) |
| `.msag.xml` | 1 | Message Class `ZCL_Q2C_265_MSG_DG` |
| `.clas.abap` / `.clas.xml` | 1 | Classe comum `ZCLQ2C_265_DESC_COMMON` |

## Sobre os arquivos `.xml`

São artefatos técnicos de importação abapGit. Não editar manualmente.
Para importar no SAP, usar abapGit pull nesta pasta.

A documentação funcional e técnica está em:

→ [`OBJETOS_COMUNS_IMPLEMENTATION_GUIDE.md`](OBJETOS_COMUNS_IMPLEMENTATION_GUIDE.md)

## Regra de segregação

- lógica exclusiva do Outbound → pasta `outbound/`
- lógica exclusiva do Inbound → pasta `inbound/`
- DDIC, message class e classe comum → esta pasta
- se a logica e compartilhada ou transversal, fica aqui

## Repositorio tecnico

Usar a carga como referencia para evitar duplicacao desnecessaria:

- helper de parametrizacao via TVARVC
- padrao de mensagem e severity
- padrao de log e commit
- padrao de leitura/gravação de arquivos em AL11
