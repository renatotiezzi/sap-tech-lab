# GAP 265 - Descarga Outbound - Implementation Guide

Author: RTiezzi  
Request/CHARM: ZPQ2C_265_20260703_082358

---

## 1. Objetivo

Garantir ativação e execução do fluxo Descarga Outbound, responsável pela geração
dos arquivos U200-H e U200-S.

---

## 2. Objetos ABAP do Outbound

| Ordem | Objeto | Tipo | Ação | Observação |
|---|---|---|---|---|
| 1 | `ZCLQ2C_265_DESCARGA_GRANEL` | Classe | Ativar/testar | Classe principal do Outbound Descarga |
| 2 | `ZRQ2C_DESCARGA_GRANEL` | Report | Ativar/testar | Runner manual do Outbound Descarga |

---

## 3. Objetos não ABAP necessários

| Ordem | Objeto | Tipo | Ação | Observação |
|---|---|---|---|---|
| 1 | Data Elements U200-H/U200-S | DDIC | Garantir no ambiente | Detalhados em `objetos_comuns/OBJETOS_COMUNS_IMPLEMENTATION_GUIDE.md` seção 2 |
| 2 | `ZQ2C_DESCARGA_PCS_OUT` | TVARVC | Configurar | Diretório AL11 de saída |
| 3 | `ZI_Q2C_DESCARGA` | CDS/View | Verificar ativo | Fonte de dados (GAP 340) |
| 4 | `ZI_Q2C_MONI_DESCARGA` | CDS/View | Verificar ativo | Fonte de dados (GAP 340) |

---

## 4. Ordem de execução

1. Garantir Data Elements do payload U200-H/U200-S no ambiente.
2. Configurar TVARVC `ZQ2C_DESCARGA_PCS_OUT`.
3. Verificar CDS/views de leitura.
4. Ativar `ZCLQ2C_265_DESCARGA_GRANEL`.
5. Ativar `ZRQ2C_DESCARGA_GRANEL`.
6. Executar teste com referência de descarga válida (status `03`).
7. Validar geração dos arquivos U200-H e U200-S na AL11.

---

## 5. Checklist final

- [ ] Data Elements do U200-H/U200-S disponíveis no SAP
- [ ] `ZQ2C_DESCARGA_PCS_OUT` configurada
- [ ] `ZI_Q2C_DESCARGA` ativa
- [ ] `ZI_Q2C_MONI_DESCARGA` ativa
- [ ] `ZCLQ2C_265_DESCARGA_GRANEL` ativa
- [ ] `ZRQ2C_DESCARGA_GRANEL` ativo
- [ ] U200-H gerado
- [ ] U200-S gerado
