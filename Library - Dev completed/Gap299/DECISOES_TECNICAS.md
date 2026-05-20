# Gap299 — Decisões Técnicas e Justificativas

## 1. Acesso direto à tabela BSEG (ATC Warning)

### Contexto
Durante a análise ATC do projeto foi apontado acesso direto à tabela transparente `BSEG`
na view `ZI_R2R_AR_POSITION`. A recomendação padrão da SAP é substituir acessos a `BSEG`
por CDS views standard (ex.: `I_OperationalAcctgDocItem`, `I_JournalEntry`).

### Tentativa de substituição
Foi verificado se os campos necessários estavam disponíveis nas seguintes CDS standard:

| CDS verificada                  | Resultado           |
|---------------------------------|---------------------|
| `I_OperationalAcctgDocItem`     | campos ausentes     |
| `I_JournalEntry`                | campos ausentes     |
| `I_AccountingDocumentItem`      | campos ausentes     |
| `I_JournalEntryItem`            | campos ausentes     |

### Campos que exigem BSEG
Os dois campos consumidos da `BSEG` **não estão expostos em nenhuma CDS standard SAP FI**:

| Campo BSEG | Significado                              | Disponível em CDS standard? |
|------------|------------------------------------------|-----------------------------|
| `ANFBN`    | Número do documento de referência base   | **NÃO**                     |
| `ANFBJ`    | Ano fiscal do documento de referência    | **NÃO**                     |

Adicionalmente, o campo `KOART` (tipo de conta) é usado como **filtro de JOIN** para
limitar as linhas lidas do BSEG apenas ao tipo de conta relevante (parametrizado via
TVARV `Z_R2R_AR_POSITION_KOART`). Esse campo também não está exposto como campo filtrável
nas CDS standard de documentos contábeis.

### Decisão
Manter o `left outer join bseg` na `ZI_R2R_AR_POSITION`.  
O warning ATC deve ser documentado como **falso positivo justificado** (pseudo-commentary),
com a seguinte justificativa:

```abap
"#EC CI_NOWHERE  "campos ANFBN/ANFBJ/KOART não disponíveis em CDS FI standard
```

---

## 2. SELECT direto em DD07L / DD07T (Value Helps de Domínio)

### Contexto
As views de Value Help `ZI_R2R_ITEMCAT_VH` e `ZI_R2R_STATUS_VH` leem
os valores fixos dos domínios Z diretamente das tabelas DDIC:

```abap
select from dd07l
  inner join dd07t
    on  dd07t.domname    = dd07l.domname
    and dd07t.domvalue_l = dd07l.domvalue_l
    and dd07t.ddlanguage = $session.system_language
where dd07l.domname  = 'ZDO_R2R_ITEM_CATEGORY'  -- ou 'ZDO_R2R_STATUS_DOC'
  and dd07l.as4local = 'A'
```

### Tentativa de substituição por CDS standard
Foi tentada a substituição pelo uso de CDS standard SAP para leitura de valores fixos
de domínio (ex.: `I_DomainFixedValue`, `I_DomainFixedValueText` ou equivalentes).

**Resultado: nenhum dado retornado.**

### Causa raiz
As CDS SAP standard de valores de domínio:
- Podem não incluir **domínios Z** no escopo de suas views (dependem de replicação de
  metadados ou de configuração adicional no sistema).
- Em sistemas com configuração de idioma restrita, a junção interna por idioma não
  encontra entradas para os domínios customizados.
- O `$session.system_language` no join com `dd07t` retorna dados **somente se existir
  tradução do texto do domínio no idioma da sessão** — comportamento idêntico ao da CDS
  standard, confirmando que o problema não era a origem da leitura, mas sim a ausência
  de textos do domínio no idioma esperado.

### Decisão
Manter o acesso direto a `dd07l` / `dd07t`:
- É o padrão utilizado pela SAP internamente em diversas CDS de Value Help.
- É compatível com HANA e com o modo CDS (não é acesso a tabela de cluster).
- `dd07l` e `dd07t` são tabelas de metadados DDIC, **não tabelas de negócio** — acesso
  direto é aceito pela própria SAP para cenários de Value Help.
- A substituição por CDS standard **não resolveu o problema** (sem retorno de dados) e
  adicionaria uma dependência desnecessária a objetos que podem variar entre releases.

### Observação sobre idioma
Garantir que os textos dos domínios `ZDO_R2R_ITEM_CATEGORY` e `ZDO_R2R_STATUS_DOC`
estejam mantidos no idioma padrão do sistema (SE61 → manter textos do domínio no SE11
para o idioma correto). Caso o Value Help apareça vazio em produção, a causa mais
provável é a ausência de textos do domínio no idioma da sessão do usuário.

---

*Documento gerado em: 05/05/2026*  
*Projeto: GAP-299 — AR Position Report (R2R)*
