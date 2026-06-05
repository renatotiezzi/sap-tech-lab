# Ajustes V2 — charcinternalid dinâmico via I_ClfnCharcDesc

## Requisito
REQ 1 do checklist funcional: substituir CASE hardcoded com WHEN '991'/'998'/'1031'
por busca dinâmica na CDS `I_ClfnCharcDesc`.

## Problema atual
Dois lugares com os IDs fixos:
1. `ZCLS2M_MATERIAIS_ORDEM.get_materiais_ordem` — CASE WHEN '991' / '998' / '1031' no pivot
2. `ZI_S2M_MATERIAIS_COMPAT` — WHERE CharcInternalID IN ('0000001031','0000000991','0000000998')

Se os IDs mudarem no sistema (ex: novo grupo de características ou migração),
o código para de funcionar sem nenhum erro explícito — simplesmente não retorna materiais.

## Solução

### ABAP (zcls2m_materiais_ordem)
Antes do loop de pivot: SELECT charcinternalid FROM I_ClfnCharcDesc
WHERE Language='P' AND CharcDescription='Grp Receita Mestre'
AND ValidityStartDate <= sy-datum AND ValidityEndDate >= sy-datum AND IsDeleted=''.

No loop de pivot: substituir os 3 WHEN fixos por `IF ... IN lr_valid_charc`.
Os valores são armazenados dinamicamente em charcinternalid/charcinternalid2/charcinternalid3
usando um contador sequencial (ordem de chegada).

Condição de inclusão: `lv_ok_count = lv_charcs_count` (todos os IDs válidos estão presentes).

### CDS (zi_s2m_materiais_compat)
Substituir o OR hardcoded no WHERE por INNER JOIN com I_ClfnCharcDesc
usando os mesmos filtros (Language='P', CharcDescription='Grp Receita Mestre',
datas válidas, IsDeleted='').

## Arquivos alterados
| Arquivo | Tipo | Mudança |
|---------|------|---------|
| `zcls2m_materiais_ordem.clas.abap` | ABAP Class | CASE fixo → dinâmico via I_ClfnCharcDesc |
| `zi_s2m_materiais_compat.ddls.asddls` | CDS DDL | OR hardcoded → JOIN com I_ClfnCharcDesc |

## Dependências
- V1 deve estar aplicado (a classe já usa FIX 1-4 do V1)
- I_ClfnCharcDesc deve ter registro ativo com CharcDescription='Grp Receita Mestre' e Language='P'

## Impacto
- Se I_ClfnCharcDesc não tiver registros ativos → nenhum material é retornado (fail-safe)
- Backward compatible: enquanto os IDs 991/998/1031 existirem como 'Grp Receita Mestre', comportamento idêntico ao V1
