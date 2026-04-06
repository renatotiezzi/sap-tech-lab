*======================================================================*
* BAdI: MB_MIGO_BADI  |  Método: LINE_MODIFY                          *
* Bloqueia POST se alguma linha relevante não estiver com OK marcado  *
*======================================================================*
CLASS zcl_im_mb_migo_badi_val DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_mb_migo_badi.

ENDCLASS.

CLASS zcl_im_mb_migo_badi_val IMPLEMENTATION.

  METHOD if_ex_mb_migo_badi~line_modify.
    " Executa somente no ciclo de POST (confirmar OKCODE no debug)
    CHECK i_parameter-okcode = 'WA01'
       OR i_parameter-okcode = 'WA0A'
       OR i_parameter-okcode = 'WPOS'.

    " Bloqueia se o item for relevante e não estiver com OK marcado
    IF c_goitem-bwart IS NOT INITIAL
   AND c_goitem-xstge <> 'X'.
      MESSAGE 'All required items must be selected before posting.'
        TYPE 'E'.
    ENDIF.
  ENDMETHOD.

  METHOD if_ex_mb_migo_badi~header_modify.
  ENDMETHOD.

  METHOD if_ex_mb_migo_badi~check_item_ok.
  ENDMETHOD.

  METHOD if_ex_mb_migo_badi~post_document.
  ENDMETHOD.

ENDCLASS.

* Debug: confirmar I_PARAMETER-OKCODE ao clicar "Postar" (break-point no inicio de LINE_MODIFY)
* Debug: C_GOITEM-XSTGE = 'X' (OK marcado) | SPACE (nao marcado); C_GOITEM-BWART = tipo de movimento
* Config: SE18 -> MB_MIGO_BADI -> criar impl. ZIM_MB_MIGO_BADI_VAL, filtro BUSTYPEID = 'WE', ativar no SE19
