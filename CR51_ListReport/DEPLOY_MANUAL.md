# CR51 - Manual de Deploy da App Fiori (LR)

## Visão Geral

Este manual cobre o deploy completo da app Fiori Elements (List Report) do CR51 —
do repositório Git até o tile visível no Fiori Launchpad.

**App:** Monitor Q2C ARQ Manager — List Report (page única)
**Service Binding:** `ZSB_Q2C_MGRLR_APP` (OData V4 - UI)
**Service Definition:** `ZSD_Q2C_MGRLR_APP`
**Entity principal:** `ArqMgrApp`

---

## 1. Referência de Valores da App

Estes valores devem ser alinhados com o time antes do deploy. Use o padrão abaixo.

| Campo                      | Valor                                  |
|----------------------------|----------------------------------------|
| Module Name                | `iconic_q2c_arqlr_mgr`                 |
| App Namespace              | `ziconic.q2c.arqlr_mgr`               |
| SAPUI5 ABAP Repository     | `ZZ1_Q2C_ARQLR_MGR`                   |
| BSP Application (gerado)   | `ZZ1_Q2C_ARQLR_MGR`                   |
| App ID (manifest.json)     | `ziconic.q2c.arqlr_mgr.iconicq2carqlrmgr` |
| Catalog (FLP)              | `ZTCQ2C_ARQLR_MGR`                    |
| Semantic Object (FLP)      | `ZSO_Q2C_ARQLR_MGR`                   |
| Grupo (FLP)                | `ZGRQ2C_ARQLR_MGR`                    |
| Host ABAP                  | `[PREENCHER — ex: https://host:44380/]`|

> **Padrão de referência:** App ar_position usa `iconic_r2r_ar_position` / `ZZ1_AR_POSITION` / `ZTCR2R_AR_POSITION`.
> Adapte o padrão de nomes para Q2C/LR conforme alinhado com o time.

---

## 2. Pré-requisitos Locais

- Node.js instalado (verificar com `node -v`)
- `@ui5/cli` instalado globalmente: `npm install -g @ui5/cli`
- `@sap/ux-ui5-tooling` instalado globalmente: `npm install -g @sap/ux-ui5-tooling`
- Acesso à rede ABAP (VPN/Zscaler ativo se ambiente on-premise)
- Credenciais ABAP com permissão de deploy (role `/UI5/UI5_REPOSITORY_ADMIN` ou equivalente)

---

## 3. Estrutura do Projeto Frontend

O projeto SAPUI5 deve seguir esta estrutura mínima:

```
iconic_q2c_arqlr_mgr/
├── webapp/
│   ├── manifest.json
│   ├── index.html
│   └── Component.js
├── ui5.yaml
├── ui5-deploy.yaml
└── package.json
```

### manifest.json — campos críticos

```json
{
  "sap.app": {
    "id": "ziconic.q2c.arqlr_mgr.iconicq2carqlrmgr",
    "type": "application",
    "title": "Monitor Q2C ARQ Manager",
    "dataSources": {
      "mainService": {
        "uri": "/sap/opu/odata4/sap/zsb_q2c_mgrlr_app/srvd/sap/zsd_q2c_mgrlr_app/0001/",
        "type": "OData",
        "settings": { "odataVersion": "4.0" }
      }
    }
  },
  "sap.ui5": {
    "models": {
      "": {
        "dataSource": "mainService",
        "settings": { "synchronizationMode": "None" }
      }
    }
  }
}
```

---

## 4. Configurar ui5-deploy.yaml

Criar o arquivo `ui5-deploy.yaml` na raiz do projeto. Ativar `deploymnet configuration: YES`.

```yaml
specVersion: "3.1"
metadata:
  name: iconic_q2c_arqlr_mgr
type: application
builder:
  customTasks:
    - name: deploy-to-abap
      afterTask: generateCachebusterInfo
      configuration:
        target:
          url: https://[HOST]:44380
          ignoreCertErrors: true          # linha 14 — manter sempre
          client: "100"                   # ajustar conforme mandante
        app:
          name: ZZ1_Q2C_ARQLR_MGR
          description: "Monitor Q2C ARQ Manager LR"
          package: ZPQ2C_CR51
          transport: [NUMERO_DO_TRANSPORTE]
        exclude:
          - /test/
```

> **Atenção:** `ignoreCertErrors: true` é obrigatório em ambientes com certificado self-signed (padrão do ambiente Iconic). Referência de padrão: app ar_position usa o mesmo flag na linha 14.

---

## 5. Repositório Git — Setup Inicial

Executar na pasta do projeto frontend:

```powershell
cd "C:\Users\[SEU_USUARIO]\projects\iconic_q2c_arqlr_mgr"

# Verificar se já tem .git
dir -Force .git

# Se não tiver, inicializar
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/20230262812_EYGS/iconic_q2c_arqlr_mgr.git
git push -u origin main
```

Para deploys subsequentes:

```powershell
git add .
git commit -m "deploy: [descricao da alteracao]"
git push
```

---

## 6. Executar o Deploy no ABAP

```powershell
# Na raiz do projeto
npm run deploy
# ou diretamente:
npx fiori deploy --config ui5-deploy.yaml
```

O processo vai:
1. Fazer build da app (`npm run build`)
2. Conectar no ABAP via RFC/HTTP
3. Criar ou atualizar a BSP Application `ZZ1_Q2C_ARQLR_MGR`
4. Vincular ao transporte informado

Se pedir credenciais interativamente, informar usuário/senha do ABAP.

---

## 7. Criar o Tile no Fiori Launchpad

### 7.1 Acessar o Customizing do FLP

Existem dois caminhos para acessar a configuração do Launchpad:

**Opção A — Transação direta:**
```
/UI2/FLPD_CUST
```

**Opção B — Via SPRO:**
```
SPRO > SAP NetWeaver > UI Technologies > SAP Fiori > SAP Fiori Launchpad > Configure Launchpad Content
```

**Opção C — Via browser (se ativo):**
```
https://[HOST]:44380/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?#Shell-config
```

---

### 7.2 Criar o Catalog

1. Em `/UI2/FLPD_CUST`, ir em **Catalogs > New**
2. Preencher:
   - **ID:** `ZTCQ2C_ARQLR_MGR`
   - **Title:** `Q2C ARQ Manager - Monitor LR`
3. Salvar

---

### 7.3 Criar o Semantic Object (Target Mapping)

Dentro do catalog criado, ir em **Target Mappings > New**:

| Campo           | Valor                                      |
|-----------------|--------------------------------------------|
| Semantic Object | `ZSO_Q2C_ARQLR_MGR`                       |
| Action          | `display`                                  |
| Title           | `Monitor Q2C ARQ Manager`                  |
| Application Type| `SAPUI5`                                   |
| App ID          | `ziconic.q2c.arqlr_mgr.iconicq2carqlrmgr` |
| URL             | `/sap/bc/ui5_ui5/sap/zz1_q2c_arqlr_mgr/`  |

Salvar e ativar.

---

### 7.4 Criar o App Tile dentro do Catalog

No mesmo catalog, ir em **Apps > New**:

| Campo           | Valor                                      |
|-----------------|--------------------------------------------|
| Title           | `Monitor Q2C ARQ Manager`                  |
| Subtitle        | `Reprocessamento e Cancelamento`           |
| Semantic Object | `ZSO_Q2C_ARQLR_MGR`                       |
| Action          | `display`                                  |
| Icon            | `sap-icon://monitor-payments` (ou similar) |

---

### 7.5 Criar o Grupo e Adicionar o Tile

1. Em `/UI2/FLPD_CUST`, ir em **Groups > New**
2. Preencher:
   - **ID:** `ZGRQ2C_ARQLR_MGR`
   - **Title:** `Q2C Manager`
3. Dentro do grupo, clicar em **Apps > Add Reference** e vincular o tile criado acima
4. Salvar

---

### 7.6 Atribuir o Catalog ao Role (PFCG)

Para que os usuários vejam o tile:

1. Transação `PFCG`
2. Abrir o role do perfil Q2C (ex: `ZROLE_Q2C_USER`)
3. Aba **Menu**
4. Adicionar o catalog `ZTCQ2C_ARQLR_MGR` como **SAP Fiori Launchpad Catalog**
5. Gerar perfil e salvar
6. Comparar/gerar perfil de autorização

---

## 8. Verificação Pós-Deploy

### 8.1 Checar BSP no ABAP
```
SE80 > BSP Applications > ZZ1_Q2C_ARQLR_MGR
```
Confirmar que os arquivos `.js`, `.xml`, `manifest.json` estão presentes e com a versão correta.

### 8.2 Testar Metadata OData
Acessar no browser:
```
https://[HOST]:44380/sap/opu/odata4/sap/zsb_q2c_mgrlr_app/srvd/sap/zsd_q2c_mgrlr_app/0001/$metadata
```
Deve retornar XML sem erro, com `ArqMgrApp` e `StatusVH` listados.

### 8.3 Testar App Direto (sem FLP)
```
https://[HOST]:44380/sap/bc/ui5_ui5/sap/zz1_q2c_arqlr_mgr/index.html
```

### 8.4 Testar via Launchpad
```
https://[HOST]:44380/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html
```
Verificar se o tile aparece no grupo `ZGRQ2C_ARQLR_MGR` e se abre o List Report.

---

## 9. Troubleshooting

| Sintoma                        | Ação                                                        |
|--------------------------------|-------------------------------------------------------------|
| Deploy falha com cert error    | Confirmar `ignoreCertErrors: true` no ui5-deploy.yaml       |
| App abre em branco             | Verificar console do browser (F12) e `/IWFND/ERROR_LOG`     |
| Tile não aparece no FLP        | Verificar atribuição do catalog ao role em PFCG             |
| Metadata retorna 404           | Confirmar que `ZSB_Q2C_MGRLR_APP` está publicado no ADT     |
| Metadata retorna 403           | Verificar autorização do usuário para o service binding     |
| Action Reprocess falha         | Verificar disponibilidade de `ZCL_Q2C_CPI_CALLER` no ambiente|
| Erro ST22 ao chamar Action     | Verificar dump via ST22, provável erro de configuração CPI  |
| Tile abre app errada           | Conferir App ID no target mapping vs. manifest.json         |

---

## 10. Notas de Teste — Connection Manager / Deploy (rascunho)

> Seção de trabalho — registrar aqui o que foi testado, o resultado e o que falta resolver.

### Ambiente
- Host: `https://vhilfws1wd01.sap.iconic.com.br:44380`
- Client: `100` (Iconic - DEV)
- Usuário: `RTIEZZI`

---

### Teste 1 — 2026-05-06
**O que foi feito:** Configurar Connection Manager no VS Code com host/client/user/pass.
**Resultado:** `This SAP system failed to return any services.`
**Erro no log:**
```
The V2 request failed: Client network socket disconnected before secure TLS connection was established.
The V4 request failed: Client network socket disconnected before secure TLS connection was established.
```
**Situação do Zscaler:**
- Iconic tenant: **ON**
- EY Main Tenant (Private Access): **TURN ON** (estava desligado)

**Hipóteses em aberto:**
- [ ] Ligar o EY Private Access e testar novamente
- [ ] Testar com NODE_TLS_REJECT_UNAUTHORIZED=0 (ver abaixo)
- [ ] Confirmar se o host responde via Invoke-WebRequest

---

### Checklist para próxima sessão de teste

**Passo 1 — Confirmar rede:**
```powershell
Invoke-WebRequest -Uri "https://vhilfws1wd01.sap.iconic.com.br:44380/sap/bc/adt/" -SkipCertificateCheck
```
- Se retornar **401** → rede OK, problema é TLS/cert no Node
- Se retornar **timeout** → Zscaler não está roteando o host

**Passo 2 — Se rede OK, testar com TLS desabilitado no Node:**
```powershell
$env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
code .
```
Depois de abrir o VS Code assim, testar o Connection Manager novamente.

**Passo 3 — Se ainda falhar, checar se o Zscaler Iconic intercepta TLS:**
O Zscaler pode fazer SSL inspection e quebrar o handshake. Nesse caso, a solução é
pedir ao admin do Zscaler para adicionar o host Iconic em bypass de SSL inspection.

**Passo 4 — Ligar EY Private Access:**
Na tela do Zscaler, clicar em **TURN ON** no Main Tenant (EY).
Alguns ambientes roteiam o tráfego SAP pelo túnel EY mesmo para tenants parceiros.

---

### Resultado dos testes (preencher conforme avançar)

| Data       | Teste                              | Resultado |
|------------|------------------------------------|-----------|
| 2026-05-06 | Connection Manager direto (hostname) | FALHOU — ERR_CONNECTION_CLOSED (DNS não resolvia) |
| 2026-05-06 | Connection Manager com IP direto   | FALHOU — cert mismatch: IP não está no SAN do cert `*.sap.iconic.com.br` |
| 2026-05-06 | Browser com IP `10.65.3.180:44380` | OK — Fiori carrega (browser ignora mismatch) |
| 2026-05-06 | certmgr                            | OK — cert `*.sap.iconic.com.br` já está como Raiz Confiável |
| -          | **Hosts fix + hostname no Connection Manager** | **PRÓXIMO PASSO** |

> **Diagnóstico final 2026-05-06:**
>
> Dois problemas encadeados:
> 1. DNS fora → hostname não resolvia → fix: entrada no hosts file
> 2. Ao usar IP direto no Connection Manager → cert `*.sap.iconic.com.br` não cobre o IP → Node.js rejeita
>
> O cert já é confiável no Windows (TrustSign BR RSA DV SSL CA 3, visível no certmgr).
> Usando o **hostname** com o hosts file ativo, o cert bate (`*.sap.iconic.com.br` cobre `vhilfws1wd01.sap.iconic.com.br`) e o Node.js aceita.

---

### Sequência correta para a máquina de trabalho

**Passo 1 — Adicionar no hosts file (como Administrador)**

Abrir Notepad como Administrador → `C:\Windows\System32\drivers\etc\hosts` → adicionar no final:
```
10.65.3.180     vhilfws1wd01.sap.iconic.com.br
```
Salvar.

**Passo 2 — Confirmar resolução DNS**
```powershell
Resolve-DnsName vhilfws1wd01.sap.iconic.com.br
```
Deve retornar `10.65.3.180`.

**Passo 3 — Usar o HOSTNAME (não o IP) no Connection Manager**

Na tela SAP System Details, garantir:
```
URL: https://vhilfws1wd01.sap.iconic.com.br:44380
```
> **NÃO usar o IP** (`https://10.65.3.180:44380`). O cert `*.sap.iconic.com.br` não cobre IPs — só cobre o hostname.

**Passo 4 — Test Connection**

Clicar em **Test Connection**. Deve conectar sem erros.

**Lembrete:** remover a linha do hosts quando o DNS da Iconic voltar ao normal.

> **Causa raiz confirmada 2026-05-06:**
> DNS do ambiente Iconic com indisponibilidade (TI Iconic comunicou: "falha parcial ABAP/JDE/Zscaler/Diretórios de Rede").
> Ver seção abaixo para a sequência correta de fix.

---

### Como aplicar o fix de DNS na máquina de trabalho

> Fazer isso na máquina onde o VS Code / Connection Manager está instalado.

**Passo 1 — Abrir o Notepad como Administrador**

1. Pressionar `Win`, digitar `notepad`
2. Clicar com botão direito → **Executar como administrador**

**Passo 2 — Abrir o arquivo hosts**

No Notepad: `Arquivo > Abrir` e navegar para:
```
C:\Windows\System32\drivers\etc\hosts
```
> Importante: no filtro de tipo de arquivo selecionar **Todos os arquivos (\*.\*)**, senão o arquivo não aparece.

**Passo 3 — Adicionar a linha no final do arquivo**

```
10.65.3.180     vhilfws1wd01.sap.iconic.com.br
```

Salvar (`Ctrl+S`) e fechar.

**Passo 4 — Verificar se funcionou**

Abrir o PowerShell e rodar:
```powershell
Resolve-DnsName vhilfws1wd01.sap.iconic.com.br
```
Deve retornar `10.65.3.180`. Se retornar, o hostname está resolvendo.

**Passo 5 — Testar no browser**

```
https://vhilfws1wd01.sap.iconic.com.br:44380/sap/bc/adt/
```
Deve aparecer tela de login SAP (pode dar aviso de certificado — aceitar e continuar).

**Passo 6 — Testar o Connection Manager no VS Code**

Clicar em **Test Connection** na tela do SAP System. Deve conectar.

**Lembrete:** quando o DNS da Iconic voltar ao normal, remover a linha adicionada do hosts file para não ter conflito futuro.

---

## 11. Referência de Nomes (padrão do projeto)

Baseado no padrão estabelecido pela app `ar_position`:

| Componente           | ar_position (referência)         | CR51 LR (este projeto)             |
|----------------------|----------------------------------|------------------------------------|
| Module Name          | `iconic_r2r_ar_position`         | `iconic_q2c_arqlr_mgr`             |
| Namespace            | `ziconic.r2r.ar_position`        | `ziconic.q2c.arqlr_mgr`            |
| ABAP Repository      | `ZZ1_AR_POSITION`                | `ZZ1_Q2C_ARQLR_MGR`                |
| Catalog              | `ZTCR2R_AR_POSITION`             | `ZTCQ2C_ARQLR_MGR`                 |
| Semantic Object      | `ZSO_R2R_AR_POSITION`            | `ZSO_Q2C_ARQLR_MGR`                |
| Grupo FLP            | `ZGRR2R_AR_POSITION`             | `ZGRQ2C_ARQLR_MGR`                 |
| CLI folder           | `iconic_r2r_cli_niden`           | `iconic_q2c_arqlr_mgr`             |
