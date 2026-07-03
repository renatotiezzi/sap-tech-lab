*&---------------------------------------------------------------------*
* Object Name    : ZRQ2C_DESC_RET_GRANEL
* Object Title   : Runner de retorno Descarga PCS -> SAP
* WRICEF ID      : Q2C265I005 / Q2C265I006
* Author         : GitHub Copilot
* Date           : 03/07/2026
*-----------------------------------------------------------------------*
REPORT zrq2c_desc_ret_granel LINE-SIZE 1000.

DATA: go_desc_ret TYPE REF TO zclq2c_265_desc_ret_granel,
      gt_msg      TYPE zclq2c_265_desc_common=>tt_message.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-s01.
  PARAMETERS:
    p_job TYPE abap_bool AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.
  CREATE OBJECT go_desc_ret EXPORTING iv_job = p_job.
  go_desc_ret->execute( CHANGING ct_msg = gt_msg ).
