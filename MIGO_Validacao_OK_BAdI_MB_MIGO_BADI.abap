*----------------------------------------------------------------------*
* BAdI  : MB_CHECK_LINE                                               *
* Method: CHECK_LINE                                                  *
*                                                                     *
* Triggered by [Check] and [Post] in MIGO.                           *
* I_GOITEM is passed directly — no extra FM needed.                  *
* Errors appended to CT_MESSAGES block posting (red traffic light).  *
*                                                                     *
* "Item OK" field: GOITEM-TAKE_IT (Data Element: MB_TAKE_IT)         *
*----------------------------------------------------------------------*
CLASS zcl_im_mb_check_line DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_mb_check_line.

ENDCLASS.

CLASS zcl_im_mb_check_line IMPLEMENTATION.

  METHOD if_ex_mb_check_line~check_line.
    DATA ls_msg TYPE bapiret2.

    " Skip lines with no movement type (incomplete / header-only rows)
    CHECK i_goitem-bwart IS NOT INITIAL.

    " Skip lines not flagged as "Item OK" — they will not be posted
    CHECK i_goitem-take_it = 'X'.

    " --- Add your business-rule validations below ---
    " Each failing rule fills LS_MSG and appends to CT_MESSAGES.
    " Appending an 'E' type message blocks posting and shows a red
    " traffic-light entry in the MIGO message log (no popup).
    "
    " Template:
    "   IF <condition fails>.
    "     ls_msg-type       = 'E'.
    "     ls_msg-id         = 'ZMM'.    " your message class (SE91)
    "     ls_msg-number     = '001'.
    "     ls_msg-message_v1 = i_goitem-matnr.
    "     APPEND ls_msg TO ct_messages.
    "     CLEAR ls_msg.
    "   ENDIF.

  ENDMETHOD.

ENDCLASS.
