*======================================================================*
* VALIDAÇÃO MIGO – Bloquear POST quando nem todas as linhas têm OK     *
*======================================================================*
* Regra de negócio:                                                     *
*   Ao tentar postar um Goods Receipt na MIGO, todas as linhas          *
*   obrigatórias (linhas com tipo de movimento preenchido) precisam     *
*   estar marcadas no checkbox "OK" (campo XSTGE = 'X').                *
*   Se qualquer linha obrigatória não estiver marcada, o POST deve      *
*   ser bloqueado e uma mensagem de erro exibida ao usuário.            *
*                                                                        *
* Ponto técnico correto:                                                 *
*   BAdI : MB_MIGO_BADI                                                 *
*   Método: LINE_MODIFY                                                  *
*                                                                        *
* Por que NÃO usar POST_DOCUMENT:                                        *
*   POST_DOCUMENT é chamado APÓS o documento ser gerado com sucesso.    *
*   Nesse ponto é impossível bloquear o POST – documento já existe.     *
*                                                                        *
* Por que LINE_MODIFY funciona:                                          *
*   Durante o ciclo de validação pré-POST, a MIGO percorre cada item    *
*   e chama LINE_MODIFY individualmente. A emissão de MESSAGE TYPE 'E'  *
*   dentro do método levanta uma exceção que a MIGO trata, exibindo a   *
*   mensagem na área de log padrão e abortando o postagem.              *
*                                                                        *
* Estratégia de buffer:                                                  *
*   Como LINE_MODIFY é chamado item a item, acumulamos os itens em uma  *
*   tabela de instância. A cada chamada com OKCODE de POST, validamos   *
*   o estado acumulado. Assim que qualquer item não-OK é detectado,     *
*   a mensagem de erro é emitida e o POST é interrompido.               *
*======================================================================*


*======================================================================*
* 1. DEFINIÇÃO DA CLASSE DE IMPLEMENTAÇÃO DA BAdI                      *
*======================================================================*
CLASS zcl_im_mb_migo_badi_val DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_mb_migo_badi.

  PRIVATE SECTION.
    "*----------------------------------------------------------------*
    "* Buffer de itens: acumulado durante o ciclo LINE_MODIFY do POST  *
    "* Chave por ZEILE (número sequencial da linha no grid da MIGO)    *
    "*----------------------------------------------------------------*
    DATA: mt_item_buffer TYPE TABLE OF mgo_goitem
                         WITH NON-UNIQUE KEY zeile,
          mv_error_sent  TYPE abap_bool VALUE abap_false.

ENDCLASS.


*======================================================================*
* 2. IMPLEMENTAÇÃO DA CLASSE                                           *
*======================================================================*
CLASS zcl_im_mb_migo_badi_val IMPLEMENTATION.

*----------------------------------------------------------------------*
* MÉTODO: LINE_MODIFY                                                  *
* Chamado pela MIGO para cada linha durante o ciclo de check/post.    *
* É aqui que ocorre a validação que bloqueia o POST.                  *
*----------------------------------------------------------------------*
  METHOD if_ex_mb_migo_badi~line_modify.

    FIELD-SYMBOLS: <ls_buf> TYPE mgo_goitem.

    DATA: lv_total     TYPE i,
          lv_ok_count  TYPE i.

    "*----------------------------------------------------------------*
    "* PASSO 1: Atualiza o buffer com o estado atual do item          *
    "*                                                                 *
    "* Campos principais de MGO_GOITEM úteis para debug/extensão:     *
    "*   ZEILE  - número sequencial da linha no grid                  *
    "*   XSTGE  - checkbox OK: 'X' = marcado  |  ' ' = não marcado  *
    "*   BWART  - tipo de movimento (linha relevante se preenchido)  *
    "*   MENGE  - quantidade (pode ser usada como filtro adicional)  *
    "*   MATNR  - material                                            *
    "*   WEMPF  - indicador de recebimento de mercadoria             *
    "*   ERFME  - unidade de medida                                   *
    "*----------------------------------------------------------------*
    READ TABLE mt_item_buffer ASSIGNING <ls_buf>
      WITH KEY zeile = c_goitem-zeile.
    IF sy-subrc = 0.
      " Atualiza o item já existente no buffer (p.ex. usuário editou a linha)
      <ls_buf> = c_goitem.
    ELSE.
      " Insere novo item no buffer
      APPEND c_goitem TO mt_item_buffer.
    ENDIF.

    "*----------------------------------------------------------------*
    "* PASSO 2: Executa a validação somente durante o ciclo de POST   *
    "*                                                                 *
    "* COMO IDENTIFICAR O OKCODE CORRETO NO DEBUG:                    *
    "*   1. Ative ABAP Debugger em SE80 ou /h na barra de comandos    *
    "*   2. Abra a MIGO, carregue a PO, marque os itens               *
    "*   3. Coloque um BREAK-POINT no início deste método              *
    "*   4. Clique no botão "Postar" (ícone de disquete/salvar)        *
    "*   5. Verifique o conteúdo de: I_PARAMETER-OKCODE               *
    "*                                                                 *
    "* Valores mais comuns por versão SAP:                             *
    "*   'WA01' - ECC 6.0 / S/4HANA (variante mais comum)            *
    "*   'WA0A' - variação em alguns sistemas                         *
    "*   'WPOS' - em releases mais antigos                            *
    "*   Ajuste a condição abaixo após confirmar no debug             *
    "*----------------------------------------------------------------*
    CHECK i_parameter-okcode = 'WA01'
       OR i_parameter-okcode = 'WA0A'
       OR i_parameter-okcode = 'WPOS'.

    " Evita emitir a mesma mensagem múltiplas vezes no mesmo ciclo de POST
    " (caso a MIGO continue chamando LINE_MODIFY após um MESSAGE E)
    CHECK mv_error_sent = abap_false.

    "*----------------------------------------------------------------*
    "* PASSO 3: Conta linhas obrigatórias × linhas com OK marcado     *
    "*                                                                 *
    "* Critério de relevância padrão: BWART IS NOT INITIAL            *
    "* (linhas sem tipo de movimento são linhas de display / cabeçalho*
    "*  e não precisam ser confirmadas)                               *
    "*                                                                 *
    "* Ajuste se necessário:                                           *
    "*   - Filtrar por movimento específico: WHERE bwart = '101'      *
    "*   - Filtrar por quantidade > 0:       WHERE menge > 0          *
    "*   - Usar campo WEMPF para relevância                           *
    "*----------------------------------------------------------------*
    CLEAR: lv_total, lv_ok_count.

    LOOP AT mt_item_buffer ASSIGNING <ls_buf>
      WHERE bwart IS NOT INITIAL.          " Linhas relevantes (com tipo de movimento)
      lv_total = lv_total + 1.
      IF <ls_buf>-xstge = abap_true.       " XSTGE = 'X': checkbox OK marcado
        lv_ok_count = lv_ok_count + 1.
      ENDIF.
    ENDLOOP.

    "*----------------------------------------------------------------*
    "* PASSO 4: Bloqueia o POST se nem todas as linhas estão OK       *
    "*                                                                 *
    "* O MESSAGE TYPE 'E' aqui lança uma exceção ABAP que a MIGO      *
    "* captura e exibe na área de mensagens padrão (rodapé do MIGO),  *
    "* interrompendo o ciclo de POST sem criar popup customizado.      *
    "*                                                                 *
    "* Alternativa com message class customizada:                      *
    "*   MESSAGE e001(zmigo_msg) WITH 'text' TYPE 'E'.                *
    "*----------------------------------------------------------------*
    IF lv_total > 0 AND lv_ok_count < lv_total.
      mv_error_sent = abap_true.
      MESSAGE 'All required items must be selected before posting.'
        TYPE 'E'.
    ENDIF.

  ENDMETHOD.


*----------------------------------------------------------------------*
* MÉTODO: HEADER_MODIFY                                                *
* Chamado quando o cabeçalho do documento é modificado ou quando um   *
* novo documento é carregado na MIGO. Limpa o buffer de itens para    *
* evitar que dados de uma sessão anterior contaminem a próxima.       *
*----------------------------------------------------------------------*
  METHOD if_ex_mb_migo_badi~header_modify.

    CLEAR mt_item_buffer.
    CLEAR mv_error_sent.

  ENDMETHOD.


*----------------------------------------------------------------------*
* MÉTODO: CHECK_ITEM_OK                                                *
* Chamado para cada item quando a MIGO verifica se o item pode ser    *
* marcado como OK (checkbox).                                          *
*                                                                       *
* Parâmetros disponíveis para debug / extensões futuras:              *
*   I_GOITEM - dados do item sendo verificado (read-only)             *
*   E_OK     - retornar SPACE para impedir que o item seja marcado OK *
*                                                                       *
* Nesta implementação a validação principal ocorre em LINE_MODIFY.    *
* Mantemos CHECK_ITEM_OK sem lógica customizada para não interferir   *
* no comportamento padrão de marcação do checkbox OK pelo usuário.    *
*----------------------------------------------------------------------*
  METHOD if_ex_mb_migo_badi~check_item_ok.
    " Sem lógica customizada – comportamento padrão SAP
  ENDMETHOD.


*----------------------------------------------------------------------*
* MÉTODO: POST_DOCUMENT                                                *
* Chamado APÓS o documento de movimento ser postado com sucesso.      *
* NÃO serve para bloquear o POST (o documento já foi criado).        *
* Usamos apenas para limpar o buffer após postagem bem-sucedida.      *
*----------------------------------------------------------------------*
  METHOD if_ex_mb_migo_badi~post_document.

    CLEAR mt_item_buffer.
    CLEAR mv_error_sent.

  ENDMETHOD.

ENDCLASS.


*======================================================================*
* 3. INSTRUÇÕES DE CONFIGURAÇÃO NO SISTEMA SAP                        *
*======================================================================*
*                                                                      *
* PASSO 1 – Criar a classe ABAP:                                       *
*   - SE24 → criar classe ZCL_IM_MB_MIGO_BADI_VAL                     *
*   - Tipo: Classe de implementação (não final no SE24 – a cláusula   *
*     FINAL acima é opcional para BAdI implementations)               *
*   - Copiar o código acima para os métodos correspondentes           *
*                                                                      *
* PASSO 2 – Criar a implementação da BAdI:                             *
*   - SE18 → buscar BAdI: MB_MIGO_BADI                                *
*   - Botão "Criar Implementação" → nome: ZIM_MB_MIGO_BADI_VAL        *
*   - Descrição: "Validação OK obrigatório no POST MIGO"              *
*   - Classe de implementação: ZCL_IM_MB_MIGO_BADI_VAL               *
*                                                                      *
* PASSO 3 – Filtros da BAdI (MB_MIGO_BADI é filter-dependent):        *
*   - A BAdI MB_MIGO_BADI usa o filtro BUSTYPEID                      *
*   - Para GR contra PO (Goods Receipt): BUSTYPEID = 'WE'             *
*   - Para todas as transações MIGO: deixar filtro em branco (*) ou   *
*     verificar no SE18 quais valores de BUSTYPEID são aplicáveis     *
*   - Valores BUSTYPEID comuns:                                        *
*       'WE'  - Goods Receipt (Entrada de Mercadoria)                 *
*       'WA'  - Goods Issue (Saída de Mercadoria)                     *
*       'UM'  - Transfer Posting (Transferência)                      *
*       'KE'  - Return Delivery                                        *
*                                                                      *
* PASSO 4 – Ativar a implementação:                                    *
*   - SE19 → buscar implementação ZIM_MB_MIGO_BADI_VAL               *
*   - Ativar (botão Activate)                                         *
*                                                                      *
* PASSO 5 – Verificar OKCODE no debug (OBRIGATÓRIO):                  *
*   - Antes de ir para produção, confirme o valor de                   *
*     I_PARAMETER-OKCODE quando o usuário clica em "Postar"           *
*   - Ajuste a condição CHECK no método LINE_MODIFY se necessário     *
*                                                                      *
*======================================================================*


*======================================================================*
* 4. GUIA DE DEBUG – LOCALIZAR CAMPOS NO SISTEMA AO VIVO              *
*======================================================================*
*                                                                      *
* COMO DEPURAR A VALIDAÇÃO:                                           *
*                                                                      *
* A. Localizar o status do checkbox OK:                                *
*    - Variável: C_GOITEM-XSTGE                                        *
*    - 'X' = marcado / ' ' (SPACE) = não marcado                     *
*    - Verificar no watch list do debugger durante LINE_MODIFY         *
*                                                                      *
* B. Localizar linhas carregadas no grid:                              *
*    - Tabela interna: MT_ITEM_BUFFER (acumulada no método)           *
*    - Tabela global MIGO: GOITEM (acessível via debugger na           *
*      função group SAPLMBGD → variáveis globais)                     *
*    - Cada entrada representa uma linha do item overview              *
*                                                                      *
* C. Identificar linha/item relevante da MIGO:                         *
*    - C_GOITEM-ZEILE  : número da linha no grid                      *
*    - C_GOITEM-BWART  : tipo de movimento (ex: 101 = GR)             *
*    - C_GOITEM-MATNR  : material                                      *
*    - C_GOITEM-MENGE  : quantidade solicitada                        *
*    - C_GOITEM-EBELN  : número do Purchase Order                     *
*    - C_GOITEM-EBELP  : item do Purchase Order                       *
*                                                                      *
* D. Identificar o OKCODE do botão POST:                               *
*    - Break-point no início de LINE_MODIFY                           *
*    - Clicar em "Postar" na MIGO                                      *
*    - Verificar: I_PARAMETER-OKCODE                                  *
*    - Registrar o valor e ajustar o CHECK no PASSO 2 do método       *
*                                                                      *
* E. Verificar o fluxo completo na call stack:                         *
*    - Stack durante LINE_MODIFY deve mostrar chamada vinda de        *
*      programa SAPLMBGD (function group da MIGO)                     *
*    - Confirmar que I_PARAMETER-OKCODE é o código do botão POST      *
*    - Confirmar que C_GOITEM-XSTGE reflete o estado atual do item    *
*                                                                      *
*======================================================================*


*======================================================================*
* 5. ALTERNATIVA – ENHANCEMENT FRAMEWORK (se BAdI não for suficiente) *
*======================================================================*
*                                                                      *
* Se a abordagem via MB_MIGO_BADI → LINE_MODIFY não funcionar         *
* como esperado, a alternativa mais confiável é um Enhancement        *
* Spot diretamente no function group SAPLMBGD.                        *
*                                                                      *
* Como localizar o ponto correto:                                      *
*   1. SE37 → buscar FMs no grupo SAPLMBGD com "MIGO" e "POST"       *
*      (ex: MGOS_POST, MBGD_POST_DOCUMENT, ou similar)               *
*   2. SE80 → SAPLMBGD → localizar o form/FM chamado no POST          *
*   3. Adicionar Enhancement Spot ANTES da chamada ao FM de posting   *
*   4. No spot, acessar tabela global GOITEM do function group        *
*                                                                      *
* Código do Enhancement Spot (após localizar o ponto correto):        *
*                                                                      *
*   ENHANCEMENT z_migo_val_post_check SPOT es_saplmbgd.               *
*     DATA: lv_total    TYPE i,                                        *
*           lv_ok_count TYPE i.                                        *
*     FIELD-SYMBOLS: <ls_item> LIKE LINE OF goitem.                   *
*                                                                      *
*     LOOP AT goitem ASSIGNING <ls_item>                               *
*       WHERE bwart IS NOT INITIAL.                                    *
*       lv_total = lv_total + 1.                                       *
*       IF <ls_item>-xstge = abap_true.                                *
*         lv_ok_count = lv_ok_count + 1.                              *
*       ENDIF.                                                         *
*     ENDLOOP.                                                         *
*                                                                      *
*     IF lv_total > 0 AND lv_ok_count < lv_total.                     *
*       MESSAGE 'All required items must be selected before posting.'  *
*         TYPE 'E'.                                                    *
*     ENDIF.                                                           *
*   ENDENHANCEMENT.                                                    *
*                                                                      *
*======================================================================*


*======================================================================*
* 6. ANÁLISE DO PROBLEMA ATUAL (por que a solução anterior não passa)  *
*======================================================================*
*                                                                      *
* Causas mais comuns para a solução atual "não passar":               *
*                                                                      *
* CAUSA 1: Uso de POST_DOCUMENT                                        *
*   - Sintoma: código nunca bloqueia, documento é postado mesmo assim *
*   - Motivo: POST_DOCUMENT é chamado após o documento existir        *
*   - Solução: Migrar lógica para LINE_MODIFY (este arquivo)          *
*                                                                      *
* CAUSA 2: OKCODE errado na verificação de LINE_MODIFY                 *
*   - Sintoma: método é chamado em outras ações mas não no POST       *
*   - Motivo: verificação do OKCODE com valor incorreto               *
*   - Solução: Debugar e verificar I_PARAMETER-OKCODE no POST         *
*                                                                      *
* CAUSA 3: Filtro BUSTYPEID incorreto na implementação da BAdI        *
*   - Sintoma: BAdI nunca é chamada                                   *
*   - Motivo: filtro BUSTYPEID sem o valor correto para GR/PO         *
*   - Solução: SE19 → verificar filtros → ajustar BUSTYPEID = 'WE'   *
*                                                                      *
* CAUSA 4: Implementação da BAdI inativa                              *
*   - Sintoma: nenhum método da BAdI é chamado                        *
*   - Solução: SE19 → ativar a implementação                          *
*                                                                      *
* CAUSA 5: MESSAGE em contexto sem handler (BAdI não trata exceção)   *
*   - Sintoma: dump ABAP ao clicar Post                               *
*   - Solução: usar MESSAGE com message class Z ou usar               *
*     MESSAGE ... TYPE 'E' DISPLAY LIKE 'E'                           *
*                                                                      *
*======================================================================*
