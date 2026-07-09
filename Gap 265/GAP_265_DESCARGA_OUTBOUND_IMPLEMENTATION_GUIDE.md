# GAP 265 - Descarga Outbound - Implementation Guide

Author: RTiezzi  
Request/CHARM: ZPQ2C_265_20260703_082358

---

## 1. Objetivo

Garantir a ativação e execução do fluxo Descarga Outbound, responsável por gerar
os arquivos `U200-H` e `U200-S` a partir de uma ordem de descarga SAP com status `03`.

---

## 2. Objetos do Outbound Descarga

| Ordem | Objeto | Tipo | Ação | Observação |
|---|---|---|---|---|
| 1 | `ZCLQ2C_265_DESCARGA_GRANEL` | Classe | Ativar | Classe principal do Outbound |
| 2 | `ZRQ2C_DESCARGA_GRANEL` | Report | Ativar/testar | Runner manual do Outbound |
| 3 | `ZQ2C_DESCARGA_PCS_OUT` | TVARVC | Configurar | Diretório AL11 de saída |
| 4 | `ZI_Q2C_DESCARGA` | CDS View | Verificar ativo | Fonte de dados da descarga (GAP 340) |
| 5 | `ZI_Q2C_MONI_DESCARGA` | CDS View | Verificar ativo | Fonte de monitoramento (GAP 340) |

> Data Elements do payload U200-H/U200-S estão documentados em
> [`objetos_comuns/OBJETOS_COMUNS_IMPLEMENTATION_GUIDE.md`](objetos_comuns/OBJETOS_COMUNS_IMPLEMENTATION_GUIDE.md).

---

## 3. Classe Outbound

| Objeto | Ação | Detalhe |
|---|---|---|
| `ZCLQ2C_265_DESCARGA_GRANEL` | Ativar | Monta `TY_U200_H`/`TY_U200_S` e grava arquivos no diretório TVARVC |

Nenhuma alteração de código necessária.

---

## 4. Runner Outbound

| Objeto | Ação | Detalhe |
|---|---|---|
| `ZRQ2C_DESCARGA_GRANEL` | Ativar/testar | Executa o Outbound Descarga; parâmetros: referência da ordem e flag de job |

---

## 5. Configuração

| Item | Tipo | Ação | Observação |
|---|---|---|---|
| `ZQ2C_DESCARGA_PCS_OUT` | TVARVC | Configurar | Diretório AL11 onde U200-H e U200-S serão gravados |
| `ZI_Q2C_DESCARGA` | CDS View (GAP 340) | Verificar ativo | Fonte principal de dados da ordem de descarga |
| `ZI_Q2C_MONI_DESCARGA` | CDS View (GAP 340) | Verificar ativo | Fonte de monitoramento (veículo, lote, produto) |

---

## 6. Ordem de execução

1. Importar `objetos_comuns/` via abapGit pull (ativa DTELs, message class e `ZCLQ2C_265_DESC_COMMON`).
2. Verificar CDS `ZI_Q2C_DESCARGA` e `ZI_Q2C_MONI_DESCARGA` ativas (GAP 340).
3. Configurar TVARVC `ZQ2C_DESCARGA_PCS_OUT` com o diretório AL11 de saída.
4. Ativar `ZCLQ2C_265_DESCARGA_GRANEL`.
5. Ativar `ZRQ2C_DESCARGA_GRANEL`.
6. Executar teste com uma referência de descarga válida (status `03`).
7. Validar geração dos arquivos U200-H e U200-S na AL11.

---

## 7. Checklist final

- [ ] Objetos comuns ativos (ver `objetos_comuns/OBJETOS_COMUNS_IMPLEMENTATION_GUIDE.md`)
- [ ] CDS `ZI_Q2C_DESCARGA` e `ZI_Q2C_MONI_DESCARGA` ativas
- [ ] TVARVC `ZQ2C_DESCARGA_PCS_OUT` configurada
- [ ] `ZCLQ2C_265_DESCARGA_GRANEL` ativa
- [ ] `ZRQ2C_DESCARGA_GRANEL` ativo
- [ ] U200-H gerado
- [ ] U200-S gerado
