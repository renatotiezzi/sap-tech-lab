# GAP316 - IMPLEMENTATION GUIDE V06 - DEF174

## Escopo da EF
WRICEF: S2M316E001
Defeito: DEF174
Objetivo: corrigir selecao de grupo/lotes e mensagens funcionais sem hardcode.

## Onde cada regra foi tratada

### EF01 - Grupo de Receita valido
Objeto principal de busca: `ZI_S2M_MATERIAIS_COMPAT`
Arquivo: `Gap316/ZPS2M_316E001_20260604_132249/src/zi_s2m_materiais_compat.ddls.asddls`

Status nesta DEF174: **regra ajustada nesta entrega**.

- Join atualizado para `I_ProductionVersion` (sem dependencia de CDS custom nao versionada no repositorio).
- Filtro de bloqueio aplicado na origem:
  - `I_ProductionVersion.ProductionVersionIsLocked = ''`
- Filtro de validade mantido na origem:
  - `I_ProductionVersion.ValidityEndDate > $session.system_date`

Esse objeto e utilizado na busca dos grupos e materiais elegiveis.

Complemento aplicado na DEF174 para evitar grupo antigo residual em buffer:

Objeto: `ZCLS2M_MATERIAIS_ORDEM`
Arquivo: `Gap316/ZPS2M_316E001_20260604_132249/src/zcls2m_materiais_ordem.clas.abap`

- Linha 178:
  - `" V6 - RTIEZZI - DEF174 - Limpa buffer da reserva antes do MODIFY para nao manter grupo antigo/bloqueado`
- Linha 179:
  - `DELETE FROM ztbs2m_mat_compa WHERE reservation IN @lr_reservation_m.`

Motivo: garante que a carga atual substitui dados antigos no buffer.

### EF02 - Validacao de quantidade do lote
Objeto: `ZBP_R_S2M_PO_COMP_MONITOR` (locals implementation)
Arquivo: `Gap316/ZPS2M_316E001_20260604_132249/src/zbp_r_s2m_po_comp_monitor.clas.locals_imp.abap`

- Linha 132:
  - `" V6 - RTIEZZI - DEF174 - Valida quantidade disponivel do lote antes da BAPI`
- Linha 133:
  - comparacao aplicada: `IF ls_material_comp-clabs < ls_po_comp_monitor-requiredquantity.`
- Linha 137:
  - mensagem funcional sem hardcode via text element: `TEXT-003`

### EF03 - Bloqueio de multiplos lotes
Objeto: `ZBP_R_S2M_PO_COMP_MONITOR` (locals implementation)
Arquivo: `Gap316/ZPS2M_316E001_20260604_132249/src/zbp_r_s2m_po_comp_monitor.clas.locals_imp.abap`

- Linha 60:
  - `" V6 - RTIEZZI - DEF174 - Permite apenas um lote por remarcacao`
- Linha 61:
  - validacao: `IF lines( keys ) > 1.`
- Linha 65:
  - mensagem funcional sem hardcode via text element: `TEXT-002`

### EF04 - Mensagens funcionais
Objeto: `ZBP_R_S2M_PO_COMP_MONITOR` (locals implementation)
Arquivo: `Gap316/ZPS2M_316E001_20260604_132249/src/zbp_r_s2m_po_comp_monitor.clas.locals_imp.abap`

- Grupo sem elegivel:
  - Linha 79: comentario DEF174
  - Linha 84: mensagem `TEXT-005` (Nao existe Grupo de Receita valido)
- Sucesso:
  - Linha 189: comentario DEF174
  - Linha 192: mensagem `TEXT-004` (Remarcacao efetuada com sucesso)

Observacao: neste ajuste nao foi usado texto literal hardcoded nas mensagens funcionais; foram utilizados text elements.

## Espelhamento da V06
Arquivos mantidos identicos entre raiz e V06:

- `Gap316/ZPS2M_316E001_20260604_132249/src/zi_s2m_materiais_compat.ddls.asddls`
- `Gap316/Ajustes V06/zi_s2m_materiais_compat.ddls.asddls`
- `Gap316/ZPS2M_316E001_20260604_132249/src/zcls2m_materiais_ordem.clas.abap`
- `Gap316/Ajustes V06/zcls2m_materiais_ordem.clas.abap`
- `Gap316/ZPS2M_316E001_20260604_132249/src/zbp_r_s2m_po_comp_monitor.clas.locals_imp.abap`
- `Gap316/Ajustes V06/zbp_r_s2m_po_comp_monitor.clas.locals_imp.abap`

## Testes sugeridos da EF
1. CT01 - grupo bloqueado: deve usar apenas grupo liberado.
2. CT02 - lote insuficiente: bloquear com mensagem funcional.
3. CT03 - mais de um lote: bloquear com mensagem funcional.
4. CT04 - sucesso: exibir mensagem funcional de remarcacao e nao mensagem tecnica da BAPI.

