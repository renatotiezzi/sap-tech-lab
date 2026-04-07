*----------------------------------------------------------------------*
* BAdI  : MB_MIGO_BADI                                               *
* TCode : SE19  (criar implementação para BAdI MB_MIGO_BADI)         *
*                                                                     *
* LINE_MODIFY  — chamado a cada alteração de linha no MIGO.          *
*               Recebe I_GOITEM diretamente → salva em cache.        *
*                                                                     *
* CHECK_ITEM   — chamado ao clicar [Check] ou [Post].                *
*               Recebe I_LINE_ID → lê cache → valida → preenche      *
*               ET_BAPIRET2 com 'E' para bloquear a postagem.        *
*----------------------------------------------------------------------*
CLASS zzcl_mb_migo_badi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_mb_migo_badi.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_cache,
             zeile  TYPE mseg-zeile,
             goitem TYPE goitem,
           END OF ty_cache.
    CLASS-DATA gt_cache TYPE HASHED TABLE OF ty_cache
                         WITH UNIQUE KEY zeile.

ENDCLASS.

CLASS zzcl_mb_migo_badi IMPLEMENTATION.

  METHOD if_ex_mb_migo_badi~line_modify.
    " Armazena os dados do item no cache (chave = número da linha)
    DATA ls_cache TYPE zzcl_mb_migo_badi=>ty_cache.
    ls_cache-zeile  = i_goitem-zeile.
    ls_cache-goitem = i_goitem.
    INSERT ls_cache INTO TABLE gt_cache.
    IF sy-subrc <> 0.
      MODIFY TABLE gt_cache FROM ls_cache.
    ENDIF.
  ENDMETHOD.

  METHOD if_ex_mb_migo_badi~check_item.
    " Chamado no [Check] / [Post] — aqui bloqueamos a postagem
    DATA: ls_cache TYPE zzcl_mb_migo_badi=>ty_cache,
          ls_msg   TYPE bapiret2.

    READ TABLE gt_cache INTO ls_cache
      WITH TABLE KEY zeile = i_line_id.
    CHECK sy-subrc = 0.

    " Ignora linhas sem tipo de movimento
    CHECK ls_cache-goitem-bwart IS NOT INITIAL.

    " === Suas validações de negócio aqui ===
    " Cada regra que falha → preenche LS_MSG e faz APPEND em ET_BAPIRET2.
    " Mensagem tipo 'E' bloqueia postagem (semáforo vermelho no MIGO).
    "
    " Exemplo:
    "   IF ls_cache-goitem-werks IS INITIAL.
    "     ls_msg-type       = 'E'.
    "     ls_msg-id         = 'ZMM'.    " classe de mensagem (SE91)
    "     ls_msg-number     = '001'.
    "     ls_msg-message_v1 = ls_cache-goitem-matnr.
    "     APPEND ls_msg TO et_bapiret2.
    "     CLEAR ls_msg.
    "   ENDIF.

  ENDMETHOD.

  " Métodos obrigatórios da interface — stubs vazios
  METHOD if_ex_mb_migo_badi~init.                  ENDMETHOD.
  METHOD if_ex_mb_migo_badi~pbo_detail.            ENDMETHOD.
  METHOD if_ex_mb_migo_badi~pai_detail.            ENDMETHOD.
  METHOD if_ex_mb_migo_badi~line_delete.           ENDMETHOD.
  METHOD if_ex_mb_migo_badi~reset.                 ENDMETHOD.
  METHOD if_ex_mb_migo_badi~post_document.         ENDMETHOD.
  METHOD if_ex_mb_migo_badi~mode_set.              ENDMETHOD.
  METHOD if_ex_mb_migo_badi~status_and_header.     ENDMETHOD.
  METHOD if_ex_mb_migo_badi~hold_data_save.        ENDMETHOD.
  METHOD if_ex_mb_migo_badi~hold_data_load.        ENDMETHOD.
  METHOD if_ex_mb_migo_badi~hold_data_delete.      ENDMETHOD.
  METHOD if_ex_mb_migo_badi~pbo_header.            ENDMETHOD.
  METHOD if_ex_mb_migo_badi~pai_header.            ENDMETHOD.
  METHOD if_ex_mb_migo_badi~check_header.          ENDMETHOD.
  METHOD if_ex_mb_migo_badi~publish_material_data. ENDMETHOD.
  METHOD if_ex_mb_migo_badi~propose_serialnumbers. ENDMETHOD.
  METHOD if_ex_mb_migo_badi~maa_line_id_adjust.    ENDMETHOD.

ENDCLASS.
