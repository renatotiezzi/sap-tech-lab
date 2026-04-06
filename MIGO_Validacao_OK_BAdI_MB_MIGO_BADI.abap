*======================================================================*
* BAdI: MB_CHECK_LINE  |  Método: CHECK_LINE                          *
* Bloqueia o lançamento se algum item relevante não estiver com       *
* o indicador OK (XSTGE) marcado. Os erros são acumulados na lista    *
* de mensagens do MIGO (protocolo semáforo), sem exibir popup.        *
*======================================================================*
" Nota: o nome da classe mantém o sufixo histórico (_mb_migo_badi_val) por
" compatibilidade com os objetos de Workbench já transportados. Para novos
" projetos, prefira um nome alinhado ao BAdI, ex.: ZCL_IM_MB_CHECK_LINE_VAL.
CLASS zcl_im_mb_migo_badi_val DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_mb_check_line.

ENDCLASS.

CLASS zcl_im_mb_migo_badi_val IMPLEMENTATION.

  METHOD if_ex_mb_check_line~check_line.
    " Variável local para montar a mensagem de erro no formato BAPIRET2
    DATA ls_message TYPE bapiret2.

    " Ignora itens sem tipo de movimento — não são relevantes para validação
    CHECK i_goitem-bwart IS NOT INITIAL.

    " Verifica se o indicador OK está desmarcado no item
    CHECK i_goitem-xstge <> 'X'.

    " Monta a mensagem de erro.
    " TODO: Para suporte a múltiplos idiomas, criar uma classe de mensagens Z
    "       (ex.: ZMM, transação SE91) e substituir o bloco abaixo por:
    "         MESSAGE e001(zmm) INTO ls_message-message.
    "         ls_message-type   = 'E'.
    "         ls_message-id     = sy-msgid.
    "         ls_message-number = sy-msgno.
    " Por enquanto, utiliza texto livre via MESSAGE_V1 (classe '00', msg '001').
    ls_message-type      = 'E'.
    ls_message-id        = '00'.
    ls_message-number    = '001'.
    ls_message-message_v1 =
      'Todos os itens obrigatórios devem estar marcados como OK antes de lançar.'.

    " Acumula o erro na lista de mensagens do MIGO (semáforo vermelho)
    APPEND ls_message TO ct_messages.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Debug:
*   - Break-point no início de CHECK_LINE para inspecionar I_GOITEM
*   - I_GOITEM-XSTGE = 'X' (OK marcado) | SPACE (não marcado)
*   - I_GOITEM-BWART = tipo de movimento do item (ex.: '101')
*   - CT_MESSAGES acumula os erros exibidos no log do MIGO
*
* Configuração (uma única vez no sistema):
*   SE18 → MB_CHECK_LINE → criar implementação ZIM_MB_MIGO_BADI_VAL
*   Filtro opcional: BUSTYPEID = 'WE' (limita a Entradas de Mercadoria)
*   SE19 → ativar a implementação criada
*----------------------------------------------------------------------*
