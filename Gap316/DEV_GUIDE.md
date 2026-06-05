# GAP 316 — Guia Técnico de Desenvolvimento

## Visão Geral

App Fiori RAP para **Monitor de Componentes de Ordens de Produção** com substituição de materiais por compatibilidade (remarcação). O usuário abre o monitor, vê os componentes das reservas, navega para a object page de cada reserva, visualiza os materiais compatíveis (substitutos) e executa a ação "Remarcar" para trocar o componente na ordem.

---

## Stack de Objetos

### Tabelas Buffer (dados transicionais, não é dado mestre)

| Tabela | Propósito |
|--------|-----------|
| `ZTBS2M_ORDEM` | Buffer de reservas/ordens para o monitor (populado pela SADL exit) |
| `ZTBS2M_ORDEMD` | Draft table de `ZTBS2M_ORDEM` |
| `ZTBS2M_MAT_COMPA` | Buffer de materiais compatíveis por reserva (populado pela SADL exit) |
| `ZTBS2M_MAT_COMPD` | Draft table de `ZTBS2M_MAT_COMPA` |

### CDS Stack — Monitor (lista principal)

```
ZC_S2M_PO_COMP_MONITOR  (Projection — consumida pelo Fiori)
  └── ZR_S2M_PO_COMP_MONITOR  (Transactional Root)
        └── ZI_S2M_PO_COMP_MONITOR  (Basic View)
              ├── ZTBS2M_ORDEM  (buffer de ordens)
              └── ZR_S2M_ORDEM  (view transacional de ordens ativas)
                    └── ZI_S2M_ORDEM  (basic, lê I_MfgOrderComponentWithStatus)
```

### CDS Stack — Materiais Compatíveis (object page / aba Materiais)

```
ZC_S2M_MATERIAIS_COMPATIVEIS  (Projection — consumida pelo Fiori)
  └── ZR_S2M_MATERIAIS_COMPATIVEIS  (Transactional, SELECT DISTINCT)
        └── ZI_S2M_MATERIAIS_COMPATIVEIS  (Basic View, lê do buffer ZTBS2M_MAT_COMPA)
```

### CDS de Dado Mestre — Compatibilidade

```
ZI_S2M_MATERIAIS_COMPAT  (view de dado mestre — SEM chave de reserva)
  ├── I_MasterRecipeMaterialAssgmt  (atribuição de material a receita/grupo)
  ├── ZI_S2M_PRODUCTIONVERSION     (versão de produção e validade)
  ├── R_BatchCharacteristicValueTP (características de lote: 991/998/1031)
  └── nsdm_e_mchb                  (estoque por lote/depósito — filtra clabs > 0)
```

---

## SADL Exit — Fluxo de População do Buffer

### Gatilho

O campo virtual `UPDATETABLE` em `ZC_S2M_PO_COMP_MONITOR` está anotado com:
```cds
@ObjectModel: {
  virtualElement: true,
  virtualElementCalculatedBy: 'ABAP:ZCLS2M_MAT_CARACT_CALC',
  filter.transformedBy: 'ABAP:ZCLS2M_MAT_CARACT_CALC'
}
```
Isso faz com que **a cada abertura do app** o método `map_atom` da classe `ZCLS2M_MAT_CARACT_CALC` seja chamado **antes** do SELECT principal da CDS.

### Classe `ZCLS2M_MAT_CARACT_CALC` (IF_SADL_EXIT_FILTER_TRANSFORM~MAP_ATOM)

```
1. SELECT * FROM ZR_S2M_ORDEM WHERE reservation IS NOT INITIAL
   → lt_comp_monitor: lista de todas as reservas/itens + material + plant

2. Constrói range de plantas (lr_plant) e materiais (lr_material) a partir de lt_comp_monitor

3. Chama ZCLS2M_MATERIAIS_ORDEM->get_materiais_ordem(
     ir_plant    = lr_plant
     ir_material = lr_material
   )
   → retorna et_materiais_compat: lista flat de materiais substitutos (SEM chave de reserva)

4. LOOP AT lt_comp_monitor  [cada reserva]
     ls_ordem ← dados da reserva (reservation, item, material, plant, OP, etc.)
     LOOP AT lt_materiais_compat  [todos os compatíveis — BUG: sem filtro por material]
       ls_mat_compativeis ← cópia do compatível
       ls_mat_compativeis-reservation      = ls_ordem-reservation   ← atribuição manual da chave
       ls_mat_compativeis-reservation_item = ls_ordem-reservation_item
       APPEND → lt_mat_compativeis
     ENDLOOP
   ENDLOOP

5. INSERT lt_ordem        INTO ZTBS2M_ORDEM     (via ZCLS2M_MATERIAIS_ORDEM->insert_ordem)
   INSERT lt_mat_compativeis INTO ZTBS2M_MAT_COMPA (via insert_materiais)

6. Retorna filtro dummy: PLANT IS NOT NULL
   (garante que o SELECT da CDS não seja bloqueado e rode após a população do buffer)
```

### Classe `ZCLS2M_MATERIAIS_ORDEM` — Método `GET_MATERIAIS_ORDEM`

```
1. SELECT DISTINCT billofoperationsgroup
     FROM I_MasterRecipeMaterialAssgmt
     WHERE plant IN ir_plant AND material IN ir_material
   → lt_grupo_mat: grupos da RECEITA de fabricação para o material

2. SELECT * FROM ZI_S2M_MATERIAIS_COMPAT
     FOR ALL ENTRIES IN lt_grupo_mat
     WHERE grupo = lt_grupo_mat-billofoperationsgroup
   → lt_materiais: todos os materiais compatíveis dos grupos encontrados
     (já filtrado por características 991/998/1031, validade, estoque > 0)

3. Pivot manual: para cada combinação única (material+centro+grupo+lote+deposito)
   verifica se os 3 charcinternalid estão presentes (991 + 998 + 1031 → lv_ok = 3)
   → Mantém somente registros com as 3 características → et_materiais_compat
```

---

## RAP Behavior Definition (`ZR_S2M_PO_COMP_MONITOR.bdef`)

```
unmanaged implementation in class zbp_r_s2m_po_comp_monitor unique
strict(2)
with draft

ZR_S2M_PO_COMP_MONITOR:
  - lock master / draft table: ZTBS2M_ORDEMD
  - association _Materiais { internal create; with draft; }
  - internal create/update/delete
  - draft actions: Prepare, Activate, Discard, Edit, Resume

ZR_S2M_MATERIAIS_COMPATIVEIS:
  - draft table: ZTBS2M_MAT_COMPD
  - lock/auth dependent by _Componente
  - update (campo QUANTIDADE editável)
  - action Remarcar
```

### Behavior Handler (`zbp_r_s2m_po_comp_monitor.clas.locals_imp`)

**Classe `lhc_zr_s2m_materiais_compative`** — handler de ZR_S2M_MATERIAIS_COMPATIVEIS:

| Método | Função |
|--------|--------|
| `read` | SELECT * FROM ZR_S2M_MATERIAIS_COMPATIVEIS BY keys |
| `update` | Atualiza QUANTIDADE em ZTBS2M_MAT_COMPA; valida que soma não ultrapassa RequiredQuantity |
| `remarcar` | Executa substituição do componente na OP via BAPI |
| `delete` | Vazio (não implementado) |

**Ação REMARCAR — Fluxo Completo:**

```
Para cada key selecionado pelo usuário:
  1. READ ENTITIES → ls_material_comp (dados do material compatível)
  2. AT FIRST:
     - READ ENTITIES → ls_po_comp_monitor (dados da reserva/ordem)
     - SELECT FROM I_ReservationDocumentItem → ls_resb (StorageLocation, Batch do componente original)
     - SELECT FROM ZR_S2M_ORDEM → lv_manufacturingordersequence
     - Monta lt_resbkeys (chave RESB do componente a ser deletado)
     - lv_call_delete = 'X' (só deleta na primeira iteração)

  3. SELECT FROM MCHB → ls_mchb (localização do lote do substituto)

  4. Chama ZCLS2M_REMARCACAO_PARALLEL->executar_bapi():
     - CO_XT_COMPONENT_ADD: adiciona o componente substituto na OP
     - CO_XT_COMPONENTS_DELETE (se call_delete='X'): remove o componente original
     - CO_ZV_ORDER_POST: posta as alterações na OP
     - COMMIT WORK AND WAIT + BAPI_TRANSACTION_COMMIT

  5. Se soma das quantidades < RequiredQuantity:
     Chama executar_bapi para o material ORIGINAL com a quantidade restante
     (re-adiciona o original com a diferença — substitição parcial)
```

---

## ZI_S2M_MATERIAIS_COMPAT — Filtros da View

```sql
WHERE ZI_S2M_PRODUCTIONVERSION.sub NOT IN ('DES','REP','REM','GRA')  -- status de versão
  AND ZI_S2M_PRODUCTIONVERSION.ProductionVersionIsLocked = ''         -- versão não bloqueada
  AND ZI_S2M_PRODUCTIONVERSION.ValidityEndDate > $session.system_date -- versão válida
  AND R_BatchCharacteristicValueTP.ClassType = '023'                   -- tipo de classe lote
  AND R_BatchCharacteristicValueTP.CharcInternalID IN ('0000001031','0000000991','0000000998')
  AND nsdm_e_mchb.clabs > 0                                           -- estoque livre > 0
```

---

## ZR_S2M_ORDEM — Filtros

```sql
INNER JOIN I_Product ON Material = Product
  AND I_Product.ZZ1_Gr_aproveitamento_PRD != '0'  -- só materiais com grupo de aproveitamento
WHERE I_MfgOrderStatus.OrderIsCreated = 'X'        -- somente ordens em status Criado
```

---

## Bugs Conhecidos (análise detalhada em `get_materiais_ordem_analise.txt`)

### BUG 1 — Cross-join no loop interno (MAP_ATOM)
```abap
" CÓDIGO ATUAL (errado):
LOOP AT lt_comp_monitor ASSIGNING <fs_comp_monitor>.
  LOOP AT lt_materiais_compat ASSIGNING <fs_materiais_compat>.  " SEM filtro por material
    " → vincula TODOS os compatíveis a TODA reserva → dados errados no buffer
```

### BUG 2 — Rota via receita (incorreta para alguns cenários)
```abap
" PASSO 1: busca grupos DA RECEITA do produto (I_MasterRecipeMaterialAssgmt)
" PASSO 2: usa esses grupos para filtrar ZI_S2M_MATERIAIS_COMPAT
" PROBLEMA: para alguns materiais, o grupo de compatibilidade é diferente
"           do grupo da receita → material não aparece na tela
```

### BUG 3 — Sem DELETE antes do INSERT no buffer
```abap
" ATUAL: MODIFY ztbs2m_mat_compa (UPDATE OR INSERT)
" PROBLEMA: execuções repetidas acumulam dados obsoletos / duplicatas
```

### BUG 4 — lv_ok com WHEN OTHERS
```abap
" WHEN OTHERS: lv_ok = lv_ok + 1  → características não mapeadas também incrementam
" → se houver charcinternalid diferente de 991/998/1031, lv_ok pode exceder 3
" → a condição IF lv_ok > 3 / EXIT pode pular características válidas
```

---

## Fluxo de Dados Resumido

```
[Abertura do App]
      │
      ▼
SADL Exit map_atom
      │
      ├── ZR_S2M_ORDEM ──────────────────────────────────────► lt_comp_monitor
      │   (componentes de ordens ativas com Gr.Aproveitamento)
      │
      ├── ZCLS2M_MATERIAIS_ORDEM::get_materiais_ordem
      │       │
      │       ├── I_MasterRecipeMaterialAssgmt ─► grupos da receita
      │       └── ZI_S2M_MATERIAIS_COMPAT ──────► materiais compatíveis (pivot 3 características)
      │
      ├── Loop: vincula materiais compatíveis a cada reserva (BUG: cross-join)
      │
      ├── INSERT ZTBS2M_ORDEM        (buffer de ordens)
      └── INSERT ZTBS2M_MAT_COMPA    (buffer de materiais compatíveis)

[SELECT principal da CDS]
      │
      ├── ZI_S2M_PO_COMP_MONITOR ◄── JOIN ZTBS2M_ORDEM + ZR_S2M_ORDEM
      │   → Lista do monitor
      │
      └── ZI_S2M_MATERIAIS_COMPATIVEIS ◄── ZTBS2M_MAT_COMPA (buffer)
          → Aba de materiais na object page

[Ação Remarcar]
      │
      ├── CO_XT_COMPONENT_ADD   → adiciona substituto na OP
      ├── CO_XT_COMPONENTS_DELETE → remove original da OP  
      └── CO_ZV_ORDER_POST       → posta alterações
```

---

## Objetos por Categoria

### Classes ABAP
| Classe | Responsabilidade |
|--------|-----------------|
| `ZCLS2M_MAT_CARACT_CALC` | SADL Exit — popula buffer na abertura do app |
| `ZCLS2M_MATERIAIS_ORDEM` | Lógica de busca de materiais compatíveis e INSERT no buffer |
| `ZCLS2M_REMARCACAO_PARALLEL` | Execução da BAPI de remarcação via cl_abap_parallel |
| `ZBP_R_S2M_PO_COMP_MONITOR` | RAP Behavior Provider (handler RAP + ação Remarcar) |

### CDS Views
| Objeto | Tipo | Função |
|--------|------|--------|
| `ZI_S2M_ORDEM` | Basic | Componentes de ordens (standard I_MfgOrderComponentWithStatus) |
| `ZR_S2M_ORDEM` | Transactional | Ordens filtradas por status e grupo de aproveitamento |
| `ZI_S2M_PO_COMP_MONITOR` | Basic | Monitor — buffer + ordens |
| `ZR_S2M_PO_COMP_MONITOR` | Transactional Root | Monitor com composição para materiais |
| `ZC_S2M_PO_COMP_MONITOR` | Projection | Monitor consumido pelo Fiori (contém campo virtual UPDATETABLE) |
| `ZI_S2M_MATERIAIS_COMPAT` | Basic | Dado mestre de compatibilidade (sem chave reserva) |
| `ZI_S2M_MATERIAIS_COMPATIVEIS` | Basic | Materiais compatíveis — lê do buffer com chave reserva |
| `ZR_S2M_MATERIAIS_COMPATIVEIS` | Transactional | Com association parent + action Remarcar |
| `ZC_S2M_MATERIAIS_COMPATIVEIS` | Projection | Consumida pelo Fiori (object page) |
| `ZI_S2M_DEPOSITO_TANQUE` | Basic | Filtro de depósitos (tanque) |

### Tabelas
| Tabela | Tipo | Conteúdo |
|--------|------|----------|
| `ZTBS2M_ORDEM` | Buffer | Reservas/ordens ativas no momento |
| `ZTBS2M_ORDEMD` | Draft | Rascunho de ZTBS2M_ORDEM |
| `ZTBS2M_MAT_COMPA` | Buffer | Materiais compatíveis com chave reserva+item |
| `ZTBS2M_MAT_COMPD` | Draft | Rascunho de ZTBS2M_MAT_COMPA |

### Serviço OData
| Objeto | Descrição |
|--------|-----------|
| `ZUI_S2M_PO_COMP_MONITOR_04` | Service Definition + Service Binding |
| `ZZ1_COMP_MONIT` | App Fiori (BSP/SAPUI5) |
