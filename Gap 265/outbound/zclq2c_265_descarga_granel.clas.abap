CLASS zclq2c_265_descarga_granel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_u200_h,
             ordernum  TYPE string,
             invoqtyl  TYPE string,
             invoqtykg TYPE string,
             desttank  TYPE string,
             prodnum   TYPE string,
             prodname  TYPE string,
             prodden   TYPE string,
             unloadln  TYPE string,
             unloadpt  TYPE string,
             truckid   TYPE string,
             coloryn   TYPE string,
             pprdname  TYPE string,
             pprodnum  TYPE string,
             sampleyn  TYPE string,
             labman    TYPE string,
             ladapptm  TYPE string,
             invoicen  TYPE string,
             batchids  TYPE string,
             msgrcvtm  TYPE string,
             cartid    TYPE string,
           END OF ty_u200_h.

    TYPES: BEGIN OF ty_u200_s,
             sordrnm  TYPE string,
             sealcode TYPE string,
             scolor   TYPE string,
             ssealid  TYPE string,
             ssealqty TYPE string,
           END OF ty_u200_s.

    TYPES tt_u200_s TYPE STANDARD TABLE OF ty_u200_s WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        iv_job TYPE abap_bool DEFAULT abap_false.

    METHODS execute
      IMPORTING
        iv_ordernum TYPE string OPTIONAL
      CHANGING
        ct_msg      TYPE zclq2c_265_desc_common=>tt_message.

    METHODS cancel_order
      IMPORTING
        iv_ordernum TYPE string
      CHANGING
        ct_msg      TYPE zclq2c_265_desc_common=>tt_message.

  PRIVATE SECTION.

    DATA mv_job TYPE abap_bool.

    METHODS load_tvarvc
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS load_order_data
      IMPORTING iv_ordernum TYPE string
      CHANGING  cs_u200_h   TYPE ty_u200_h
                ct_u200_s    TYPE tt_u200_s
                ct_msg       TYPE zclq2c_265_desc_common=>tt_message.

    METHODS validate_order
      IMPORTING cs_u200_h TYPE ty_u200_h
      CHANGING  ct_msg    TYPE zclq2c_265_desc_common=>tt_message.

    METHODS build_line_h
      IMPORTING cs_u200_h TYPE ty_u200_h
      RETURNING VALUE(rv_line) TYPE string.

    METHODS build_line_s
      IMPORTING is_u200_s TYPE ty_u200_s
      RETURNING VALUE(rv_line) TYPE string.

    METHODS save_file
      IMPORTING
        iv_directory TYPE string
        iv_filename  TYPE string
        iv_content   TYPE string
      CHANGING
        ct_msg       TYPE zclq2c_265_desc_common=>tt_message.

ENDCLASS.



CLASS zclq2c_265_descarga_granel IMPLEMENTATION.

  METHOD constructor.
    mv_job = iv_job.
  ENDMETHOD.

  METHOD execute.
    DATA: lv_out_dir TYPE string,
          lv_header  TYPE ty_u200_h,
          lt_seals   TYPE tt_u200_s,
          lv_content TYPE string,
          lv_ts      TYPE string.

    load_tvarvc( CHANGING ct_msg = ct_msg ).
    IF ct_msg IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF iv_ordernum IS INITIAL.
      zclq2c_265_desc_common=>add_error(
        EXPORTING iv_number = '010'
                  iv_v1     = 'ORDERNUM nao informado'
        CHANGING  ct_message = ct_msg ).
      RETURN.
    ENDIF.

    load_order_data(
      EXPORTING iv_ordernum = iv_ordernum
      CHANGING  cs_u200_h   = lv_header
                ct_u200_s    = lt_seals
                ct_msg       = ct_msg ).

    validate_order( EXPORTING cs_u200_h = lv_header CHANGING ct_msg = ct_msg ).
    IF ct_msg IS NOT INITIAL.
      RETURN.
    ENDIF.

    lv_ts = |{ sy-datum }{ sy-uzeit }|.
    lv_content = build_line_h( lv_header ) && cl_abap_char_utilities=>cr_lf.
    save_file(
      EXPORTING iv_directory = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_OUT' )
                iv_filename  = |U200-H{ lv_ts }.TXT|
                iv_content   = lv_content
      CHANGING  ct_msg       = ct_msg ).

    CLEAR lv_content.
    LOOP AT lt_seals INTO DATA(ls_seal).
      lv_content = lv_content && build_line_s( ls_seal ) && cl_abap_char_utilities=>cr_lf.
    ENDLOOP.
    save_file(
      EXPORTING iv_directory = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_OUT' )
                iv_filename  = |U200-S{ lv_ts }.TXT|
                iv_content   = lv_content
      CHANGING  ct_msg       = ct_msg ).

    IF mv_job = abap_true.
      zclq2c_265_desc_common=>add_success(
        EXPORTING iv_number = '011'
                  iv_v1     = lv_header-ordernum
        CHANGING  ct_message = ct_msg ).
    ENDIF.
  ENDMETHOD.

  METHOD cancel_order.
    DATA(lv_ts) = |{ sy-datum }{ sy-uzeit }|.
    DATA(lv_content) = |{ iv_ordernum }|.

    save_file(
      EXPORTING iv_directory = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_OUT' )
                iv_filename  = |U201_{ iv_ordernum }_{ lv_ts }.TXT|
                iv_content   = lv_content
      CHANGING  ct_msg       = ct_msg ).
  ENDMETHOD.

  METHOD load_tvarvc.
    DATA(lv_in)  = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_IN' ).
    DATA(lv_out) = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_OUT' ).

    IF lv_out IS INITIAL.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '020' iv_v1 = 'ZQ2C_DESCARGA_PCS_OUT' CHANGING ct_message = ct_msg ).
    ENDIF.
    IF lv_in IS INITIAL.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '020' iv_v1 = 'ZQ2C_DESCARGA_PCS_IN' CHANGING ct_message = ct_msg ).
    ENDIF.
  ENDMETHOD.

  METHOD load_order_data.
    CLEAR: cs_u200_h, ct_u200_s.
    cs_u200_h-ordernum = iv_ordernum.
    cs_u200_h-invoicen = iv_ordernum.
    cs_u200_h-msgrcvtm = |{ sy-datum } { sy-uzeit }|.
    APPEND VALUE #( sordrnm = iv_ordernum
                    sealcode = ''
                    scolor   = ''
                    ssealid  = ''
                    ssealqty = '' ) TO ct_u200_s.
  ENDMETHOD.

  METHOD validate_order.
    IF cs_u200_h-ordernum IS INITIAL.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '030' iv_v1 = 'ORDERNUM vazio' CHANGING ct_message = ct_msg ).
    ENDIF.
  ENDMETHOD.

  METHOD build_line_h.
    rv_line = |{ cs_u200_h-ordernum };{ cs_u200_h-invoqtyl };{ cs_u200_h-invoqtykg };{ cs_u200_h-desttank };{ cs_u200_h-prodnum };{ cs_u200_h-prodname };{ cs_u200_h-prodden };{ cs_u200_h-unloadln };{ cs_u200_h-unloadpt };{ cs_u200_h-truckid };{ cs_u200_h-coloryn };{ cs_u200_h-pprdname };{ cs_u200_h-pprodnum };{ cs_u200_h-sampleyn };{ cs_u200_h-labman };{ cs_u200_h-ladapptm };{ cs_u200_h-invoicen };{ cs_u200_h-batchids };{ cs_u200_h-msgrcvtm };{ cs_u200_h-cartid }|.
  ENDMETHOD.

  METHOD build_line_s.
    rv_line = |{ is_u200_s-sordrnm };{ is_u200_s-sealcode };{ is_u200_s-scolor };{ is_u200_s-ssealid };{ is_u200_s-ssealqty }|.
  ENDMETHOD.

  METHOD save_file.
    DATA(lv_path) = |{ iv_directory }{ iv_filename }|.
    OPEN DATASET lv_path FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc <> 0.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '040' iv_v1 = lv_path CHANGING ct_message = ct_msg ).
      RETURN.
    ENDIF.

    TRANSFER iv_content TO lv_path.
    CLOSE DATASET lv_path.
  ENDMETHOD.

ENDCLASS.
