# Job App - Example - Objects Guide

Este guia lista os objetos minimos para gerar um App Job no padrao da classe `ZCL_R2R_ENTRADA_FATURA_JOB_APP`.

## 1) Classe ABAP (runtime + design-time)

- Classe: `ZCL_R2R_ENTRADA_FATURA_JOB_APP`
- Interfaces obrigatorias:
  - `IF_APJ_DT_EXEC_OBJECT` (define parametros/template)
  - `IF_APJ_RT_EXEC_OBJECT` (execucao)
- Metodos minimos:
  - `IF_APJ_DT_EXEC_OBJECT~GET_PARAMETERS`
  - `IF_APJ_RT_EXEC_OBJECT~EXECUTE`

## 2) Application Log (SLG1)

- Objeto de log: `ZR2RL_046`
- Subobjeto: `ENT_FAT`
- Uso no codigo via BALI:
  - `CL_BALI_HEADER_SETTER`
  - `CL_BALI_LOG`
  - `CL_BALI_LOG_DB`

## 3) Message Class (SE91)

- Classe de mensagem: `ZR2R_JOB`
- Mensagens minimas sugeridas:
  - `001` Inicio da execucao
  - `002` Modo teste ativo
  - `003` Quantidade de candidatos
  - `099` Fim da execucao

## 4) Application Job Catalog Entry

- Exemplo: `ZR2RCE_046`
- Deve apontar para a classe ABAP acima.

## 5) Application Job Template

- Exemplo: `ZR2RTE_046`
- Deve consumir os parametros definidos em `GET_PARAMETERS`.

## 6) Parametros de App Job (padrao do exemplo)

- `P_BUKRS` (select-option)
- `P_BUDAT` (select-option)
- `P_TESTE` (checkbox)

## 7) Dependencias funcionais

- Views/API CDS usadas no exemplo:
  - `I_SupplierInvoiceAPI01`
  - `I_SuplrInvcItemPurOrdRefAPI01`
  - `I_OperationalAcctgDocItem`
- FM de compensacao usada no exemplo:
  - `POSTING_INTERFACE_CLEARING`

## 8) Checklist de geracao

1. Criar/ativar classe.
2. Criar objeto/subobjeto de log.
3. Criar classe de mensagem.
4. Criar Job Catalog Entry.
5. Criar Job Template.
6. Testar em modo `P_TESTE = X`.
7. Validar logs no SLG1.
