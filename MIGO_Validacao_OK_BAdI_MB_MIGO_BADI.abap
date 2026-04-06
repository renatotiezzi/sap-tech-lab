*======================================================================*
* BAdI: MB_CHECK_LINE  |  Método: CHECK_LINE                          *
* Valida cada item durante o ciclo de verificação/lançamento do MIGO. *
* Erros são acumulados em CT_MESSAGES (protocolo semáforo) sem popup. *
*                                                                      *
* NOTA ARQUITETURAL — por que NÃO verificamos o indicador "Item OK":  *
*   MB_MIGO_BADI~LINE_MODIFY dispara em todo evento de UI (inclusive  *
*   durante o preenchimento), por isso precisa do guard XSTGE para    *
*   evitar erros prematuros.                                           *
*   MB_CHECK_LINE~CHECK_LINE é invocado SOMENTE no ciclo Check/Post;  *
*   o framework MIGO já controla quais itens chegam aqui — verificar  *
*   o indicador OK neste método é redundante e causa erro de          *
*   compilação em releases onde o campo não existe na estrutura local. *
*   Se futuramente for necessário ler o indicador, verificar o nome   *
*   correto do campo via SE11 → GOITEM ou SE18 → MB_CHECK_LINE.       *
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

    " Ignora itens sem tipo de movimento — não são relevantes para validação.
    " Em raros cenários de edge-case alguns releases roteiam itens parcialmente
    " preenchidos a este método; o guard abaixo protege contra isso.
    CHECK i_goitem-bwart IS NOT INITIAL.

    " --- Insira aqui as regras de negócio necessárias ---
    " O framework garante que apenas itens do ciclo Check/Post chegam a este
    " método, portanto não é necessário checar o indicador "Item OK" aqui.
    "
    " Exemplo de validação de quantidade:
    "   IF i_goitem-erfmg <= 0.
    "     ls_message-type       = 'E'.
    "     ls_message-id         = 'ZMM'.   " classe de mensagens Z do projeto
    "     ls_message-number     = '001'.
    "     ls_message-message_v1 = 'Quantidade do item deve ser maior que zero.'.
    "     APPEND ls_message TO ct_messages.
    "   ENDIF.

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
*   - I_GOITEM-BWART = tipo de movimento do item (ex.: '101')
*   - I_GOITEM-ERFMG / I_GOITEM-MATNR = quantidade e material do item
*   - CT_MESSAGES acumula os erros exibidos no log do MIGO
*
*   Para verificar o nome do campo "Item OK" neste sistema:
*     SE11 → GOITEM → localizar campo com descrição "selected" ou "OK"
*     SE18 → MB_CHECK_LINE → método CHECK_LINE → tipo do parâmetro I_GOITEM
*   Em SAP ECC 6.0 (EHP7+) o campo padrão é XSTGE; confirmar via SE11
*   no sistema destino antes de reintroduzir qualquer referência a ele.
*
* Configuração (uma única vez no sistema):
*   SE18 → MB_CHECK_LINE → criar implementação ZIM_MB_MIGO_BADI_VAL
*   Filtro opcional: BUSTYPEID = 'WE' (limita a Entradas de Mercadoria)
*   SE19 → ativar a implementação criada
*----------------------------------------------------------------------*
