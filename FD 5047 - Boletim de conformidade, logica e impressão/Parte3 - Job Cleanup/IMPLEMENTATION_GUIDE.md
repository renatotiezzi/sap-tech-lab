# IMPLEMENTATION GUIDE – Parte 3: Job de Limpeza DMS (D-15)

## Visão Geral

`ZFD5047_CERT_CLEANUP` é um report ABAP agendado como job periódico.  
Remove do DMS certificados com mais de **15 dias** (configurável via TVARVC).

---

## Pré-Requisito: TVARVC

Antes de agendar o job, criar a entrada na TVARVC via **SM30**:

| Campo | Valor |
|-------|-------|
| Name  | `ZFD5047_CLEANUP_DAYS` |
| Type  | `P` (Single value) |
| Low   | `15` |

Sem esta entrada, o report usa o padrão hard-coded de 15 dias.

---

## Execução Manual (Teste)

1. SE38 → `ZFD5047_CERT_CLEANUP`
2. Preencher tela de seleção:
   - **Modo Test** (`P_TEST = X`): lista documentos que seriam deletados, SEM deletar
   - **Dias de retenção** (`P_DAYS`): sobrescreve o TVARVC para este run (opcional)
3. Verificar lista antes de executar sem modo test

---

## Agendamento (SM36)

| Item | Valor |
|------|-------|
| Job Name | `ZFD5047_CERT_CLEANUP` |
| Step | ABAP Program: `ZFD5047_CERT_CLEANUP` |
| Frequência | 2x por mês (datas 1 e 15) |
| Horário | 02:00 |
| Usuário de execução | Usuário técnico batch (com autorização SM59 ZDMS5047_DEST) |

---

## Saída do Job

O report emite um relatório simples com:
- Quantidade de documentos encontrados (candidatos à deleção)
- Quantidade deletados com sucesso
- Quantidade com erro (lista de IDs e mensagens)
- Data/hora de execução e parâmetro D-dias utilizado
