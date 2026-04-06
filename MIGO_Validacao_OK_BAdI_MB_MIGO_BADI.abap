*----------------------------------------------------------------------*
* BAdI  : MB_MIGO_BADI                                                *
* Method: CHECK_ITEM                                                  *
*                                                                     *
* Triggered by the [Check] and [Post] buttons in MIGO (item level).  *
* Receives I_LINE_ID; item data is fetched via MB_MIGO_LINE_DATA_GET. *
* Errors are appended to ET_BAPIRET2 (red traffic light, no popup).  *
*                                                                     *
* "Item OK" field: GOITEM-TAKE_IT (Data Element: MB_TAKE_IT)         *
*----------------------------------------------------------------------*
CLASS zzcl_mb_migo_badi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_mb_migo_badi.

ENDCLASS.

CLASS zzcl_mb_migo_badi IMPLEMENTATION.

  METHOD if_ex_mb_migo_badi~check_item.
    DATA: ls_goitem TYPE goitem,
          ls_msg    TYPE bapiret2.

    " Retrieve full item structure for this line from the MIGO buffer
    CALL FUNCTION 'MB_MIGO_LINE_DATA_GET'
      EXPORTING
        i_line_id      = i_line_id
      IMPORTING
        e_goitem       = ls_goitem
      EXCEPTIONS
        line_not_found = 1
        OTHERS         = 2.

    CHECK sy-subrc = 0.

    " Skip lines with no movement type (incomplete / header-only rows)
    CHECK ls_goitem-bwart IS NOT INITIAL.

    " Skip lines not flagged as "Item OK" — they will not be posted
    CHECK ls_goitem-take_it = 'X'.

    " --- Add your business-rule validations below ---
    " Each failing rule fills LS_MSG and appends to ET_BAPIRET2.
    "
    " Template:
    "   IF <condition fails>.
    "     ls_msg-type       = 'E'.
    "     ls_msg-id         = 'ZMM'.    " your message class (SE91)
    "     ls_msg-number     = '001'.
    "     ls_msg-message_v1 = ls_goitem-matnr.
    "     APPEND ls_msg TO et_bapiret2.
    "     CLEAR ls_msg.
    "   ENDIF.

  ENDMETHOD.

ENDCLASS.
