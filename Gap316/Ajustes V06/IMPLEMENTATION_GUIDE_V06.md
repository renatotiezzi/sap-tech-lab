# GAP316 - Guia de Implementacao V06 (mesma EF)

## Objetivo
Consolidar todos os ajustes da mesma EF somente em:
- raiz tecnica: `Gap316/ZPS2M_316E001_20260604_132249/src/`
- snapshot historico: `Gap316/Ajustes V06/`

Sem criar V07, V08 ou V09 para esta EF.

## O que foi pedido
1. Manter uma unica trilha de versao para a mesma EF (somente V06).
2. Aplicar o ajuste na raiz e espelhar no V06.
3. Deixar comentarios claros no codigo no padrao:
	 - `V7 - Rtiezzi - Start - ...`
	 - `V7 - End`
4. Documentar no V06 o que foi alterado e em qual objeto/linha.

## Implementacao aplicada

### 1) Classe de carga de materiais compativeis
Objeto: `ZCLS2M_MATERIAIS_ORDEM`
Arquivo raiz: `Gap316/ZPS2M_316E001_20260604_132249/src/zcls2m_materiais_ordem.clas.abap`

- Ajuste 1 (deduplicacao final do lote):
	- Linha de comentario start: linha 165
	- Linha de codigo: linha 166
	- Linha de comentario end: linha 167
	- Implementacao:
		- Mantida deduplicacao neutra por `material + centro + lote + deposito`.
		- `SORT` usado: `SORT et_materiais_compat BY material centro lote deposito grupo.`
	- Motivo:
		- Regra de bloqueio de versao deve ficar na origem da busca (CDS), nao no desempate local da deduplicacao.

- Ajuste 2 (limpeza de buffer antes de gravar materiais):
	- Linha de comentario start: linha 214
	- Linha de codigo: linha 215
	- Linha de comentario end: linha 216
	- Implementacao:
		- `DELETE FROM ztbs2m_mat_compa WHERE reservation IN @lr_reservation_m.`
		- Depois `MODIFY` para gravar estado atual.
	- Motivo:
		- Evitar dados obsoletos/duplicados no buffer da mesma reserva.

### 2) Classe de acao de remarcacao
Objeto: `ZBP_R_S2M_PO_COMP_MONITOR` (locals implementation)
Arquivo raiz: `Gap316/ZPS2M_316E001_20260604_132249/src/zbp_r_s2m_po_comp_monitor.clas.locals_imp.abap`

- Validacoes funcionais com comentarios V7 Start/End:
	- Selecao multipla bloqueada: linhas 60 a 69
	- Quantidade insuficiente bloqueada antes da BAPI: linhas 123 a 132
	- Mensagem funcional de sucesso: linhas 185 a 190

## Filtro de versao bloqueada (origem dos dados)
Objeto: `ZI_S2M_MATERIAIS_COMPAT`
Arquivo raiz: `Gap316/ZPS2M_316E001_20260604_132249/src/zi_s2m_materiais_compat.ddls.asddls`

- Linha 43: `ProductionVersionIsLocked = ''`
- Linha 44: `ValidityEndDate > $session.system_date`

Esse objeto e usado na busca de materiais compativeis e ja contem filtro de versao bloqueada e validade.

## Espelhamento no V06
Arquivos espelhados da raiz para o snapshot V06:
- `Gap316/Ajustes V06/zcls2m_materiais_ordem.clas.abap`
- `Gap316/Ajustes V06/zbp_r_s2m_po_comp_monitor.clas.locals_imp.abap`

## Observacao de governanca
Para esta EF, o versionamento correto permanece em V06.
As pastas V07/V08/V09 foram removidas para nao quebrar a trilha unica da mesma EF.

