REPORT zrq2c_descarga_granel LINE-SIZE 1000.

DATA: go_descarga TYPE REF TO zclq2c_265_descarga_granel,
      gt_msg      TYPE zclq2c_265_desc_common=>tt_message.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-s01.
  PARAMETERS:
    p_ordnum TYPE string LOWER CASE OPTIONAL,
    p_job    TYPE abap_bool AS CHECKBOX DEFAULT abap_false.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.
  CREATE OBJECT go_descarga EXPORTING iv_job = p_job.
  go_descarga->execute(
    EXPORTING iv_ordernum = p_ordnum
    CHANGING  ct_msg      = gt_msg ).
