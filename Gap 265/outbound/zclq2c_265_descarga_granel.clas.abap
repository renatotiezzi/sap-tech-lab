*&---------------------------------------------------------------------*
* Object Name    : ZCLQ2C_265_DESCARGA_GRANEL
* Object Title   : Descarga Granel e Cancelamento Descarga
* WRICEF ID      : Q2C265I004
* Request/CHARM  : ZPQ2C_265_20260703_082358
* Author         : RTiezzi
* Date           : 03/07/2026
*-----------------------------------------------------------------------*
CLASS zclq2c_265_descarga_granel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_u200_h,
             ordernum  TYPE zdeq2c_265_order_num,
             invoqtyl  TYPE zdeq2c_265_desc_invoqtyl,
             invoqtykg TYPE zdeq2c_265_desc_invoqkg,
             desttank  TYPE zdeq2c_265_desc_desttank,
             prodnum   TYPE zdeq2c_265_prod_num,
             prodname  TYPE zdeq2c_265_prod_name,
             prodden   TYPE zdeq2c_265_prod_den,
             unloadln  TYPE zdeq2c_265_load_line,
             unloadpt  TYPE zdeq2c_265_load_ptfm,
             truckid   TYPE zdeq2c_265_truck_id,
             coloryn   TYPE zdeq2c_265_desc_coloryn,
             pprdname  TYPE zdeq2c_265_pprd_name,
             pprodnum  TYPE zdeq2c_265_pprd_num,
             sampleyn  TYPE zdeq2c_265_desc_sampleyn,
             labman    TYPE zdeq2c_265_desc_labman,
             ladapptm  TYPE zdeq2c_265_desc_ladapptm,
             invoicen  TYPE zdeq2c_265_desc_invoicen,
             batchids  TYPE zdeq2c_265_desc_batchids,
             msgrcvtm  TYPE zdeq2c_265_msgrcvtm,
             cartid    TYPE zdeq2c_265_desc_cartid,
           END OF ty_u200_h.

    TYPES: BEGIN OF ty_u200_s,
             sordrnm  TYPE zdeq2c_265_order_num,
             sealcode TYPE zdeq2c_265_desc_sealcode,
             scolor   TYPE zdeq2c_265_sealclr,
             ssealid  TYPE zdeq2c_265_seal_num,
             ssealqty TYPE zdeq2c_265_seal_qty,
           END OF ty_u200_s.

    TYPES tt_u200_s TYPE STANDARD TABLE OF ty_u200_s WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        iv_job TYPE abap_bool DEFAULT abap_false.

    METHODS execute
      IMPORTING
        iv_reference TYPE string OPTIONAL
        is_u200_h    TYPE ty_u200_h OPTIONAL
        it_u200_s    TYPE tt_u200_s OPTIONAL
      CHANGING
        ct_msg      TYPE zclq2c_265_desc_common=>tt_message.

    METHODS cancel_order
      IMPORTING
        iv_ordernum TYPE zdeq2c_265_order_num
      CHANGING
        ct_msg      TYPE zclq2c_265_desc_common=>tt_message.

  PRIVATE SECTION.

    DATA mv_job TYPE abap_bool.
    DATA ms_descarga TYPE zi_q2c_descarga.

    METHODS load_tvarvc
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS load_order_data
      IMPORTING iv_reference TYPE string
      CHANGING  cs_u200_h   TYPE ty_u200_h
                ct_u200_s    TYPE tt_u200_s
                ct_msg       TYPE zclq2c_265_desc_common=>tt_message.

    METHODS validate_order
      IMPORTING cs_u200_h TYPE ty_u200_h
                ct_u200_s TYPE tt_u200_s
      CHANGING  ct_msg    TYPE zclq2c_265_desc_common=>tt_message.

    METHODS validate_cancel
      IMPORTING iv_ordernum TYPE zdeq2c_265_order_num
      CHANGING  ct_msg      TYPE zclq2c_265_desc_common=>tt_message.

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
    DATA: lv_header  TYPE ty_u200_h,
          lt_seals   TYPE tt_u200_s,
          lv_content TYPE string,
          lv_ts      TYPE string.

    load_tvarvc( CHANGING ct_msg = ct_msg ).
    IF ct_msg IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF is_u200_h IS NOT INITIAL.
      lv_header = is_u200_h.
      lt_seals  = it_u200_s.
    ELSE.
      IF iv_reference IS INITIAL.
        zclq2c_265_desc_common=>add_error(
          EXPORTING iv_number = '012'
                    iv_v1     = 'Referencia da ordem nao informada'
          CHANGING  ct_message = ct_msg ).
        RETURN.
      ENDIF.

      load_order_data(
        EXPORTING iv_reference = iv_reference
        CHANGING  cs_u200_h    = lv_header
                  ct_u200_s    = lt_seals
                  ct_msg       = ct_msg ).
    ENDIF.

    validate_order( EXPORTING cs_u200_h = lv_header ct_u200_s = lt_seals CHANGING ct_msg = ct_msg ).
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
    DATA(lv_content) = |{ iv_ordernum }|.

    validate_cancel( EXPORTING iv_ordernum = iv_ordernum CHANGING ct_msg = ct_msg ).
    IF ct_msg IS NOT INITIAL.
      RETURN.
    ENDIF.

    save_file(
      EXPORTING iv_directory = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_OUT' )
                iv_filename  = |U201_{ iv_ordernum }|
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
    DATA lv_reference TYPE string.
    DATA ls_moni_descarga TYPE zi_q2c_moni_descarga.

    CLEAR: cs_u200_h, ct_u200_s.
    CLEAR ms_descarga.
    lv_reference = iv_reference.

    SELECT SINGLE *
      FROM zi_q2c_descarga
      WHERE pcsordernum = @lv_reference
      INTO @ms_descarga.

    IF sy-subrc <> 0.
      SELECT SINGLE *
        FROM zi_q2c_descarga
        WHERE shnumber = @lv_reference
        INTO @ms_descarga.
    ENDIF.

    IF sy-subrc <> 0.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '030' iv_v1 = |Referencia nao encontrada: { lv_reference }| CHANGING ct_message = ct_msg ).
      RETURN.
    ENDIF.

    SELECT SINGLE *
      FROM zi_q2c_moni_descarga
      WHERE shnumber       = @ms_descarga-shnumber
        AND deliverynumber = @ms_descarga-remessa
        AND deliveryitem   = @ms_descarga-itemremessa
      INTO @ls_moni_descarga.

    cs_u200_h-ordernum = ms_descarga-pcsordernum.
    cs_u200_h-invoqtyl = ms_descarga-qtdenfe.
    cs_u200_h-invoqtykg = ms_descarga-pesobrutonfe.
    cs_u200_h-desttank = ms_descarga-lgortdestino.
    cs_u200_h-prodnum = ms_descarga-matnr.
    cs_u200_h-prodname = ls_moni_descarga-arktx.
    cs_u200_h-unloadln = ms_descarga-linhadescarga.
    cs_u200_h-unloadpt = ms_descarga-plataforma.
    cs_u200_h-coloryn = ms_descarga-mangote.
    cs_u200_h-truckid = ls_moni_descarga-vehicle.
    cs_u200_h-cartid = ls_moni_descarga-vehid.
    cs_u200_h-batchids = ls_moni_descarga-charg.
    cs_u200_h-invoicen = ms_descarga-nfnum.
    cs_u200_h-msgrcvtm = |{ sy-datum } { sy-uzeit }|.

    IF ms_descarga-quantidadelacrefornecedor IS NOT INITIAL
       OR ms_descarga-codelacrefornecedor IS NOT INITIAL
       OR ms_descarga-corlacrefornecedor IS NOT INITIAL.
      APPEND VALUE #( sordrnm  = cs_u200_h-ordernum
                      sealcode = ''
                      scolor   = ms_descarga-corlacrefornecedor
                      ssealid  = ms_descarga-codelacrefornecedor
                      ssealqty = ms_descarga-quantidadelacrefornecedor ) TO ct_u200_s.
    ENDIF.
  ENDMETHOD.

  METHOD validate_order.
    FIELD-SYMBOLS <fs_value> TYPE any.
    DATA lt_fields TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_field TYPE string.

    APPEND 'ORDERNUM' TO lt_fields.
    APPEND 'DESTTANK' TO lt_fields.
    APPEND 'PRODNUM' TO lt_fields.
    APPEND 'UNLOADLN' TO lt_fields.
    APPEND 'UNLOADPT' TO lt_fields.
    APPEND 'TRUCKID' TO lt_fields.
    APPEND 'INVOQTYL' TO lt_fields.
    APPEND 'INVOQTYKG' TO lt_fields.

    LOOP AT lt_fields INTO lv_field.
      ASSIGN COMPONENT lv_field OF STRUCTURE cs_u200_h TO <fs_value>.
      IF sy-subrc <> 0 OR <fs_value> IS INITIAL.
        zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '031' iv_v1 = lv_field CHANGING ct_message = ct_msg ).
      ENDIF.
    ENDLOOP.

    IF ct_u200_s IS INITIAL.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '032' iv_v1 = cs_u200_h-ordernum CHANGING ct_message = ct_msg ).
    ENDIF.

    IF ms_descarga-status IS INITIAL.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '033' iv_v1 = cs_u200_h-ordernum CHANGING ct_message = ct_msg ).
    ELSEIF ms_descarga-status <> '03'.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '034' iv_v1 = ms_descarga-status CHANGING ct_message = ct_msg ).
    ENDIF.
  ENDMETHOD.

  METHOD validate_cancel.
    DATA ls_descarga TYPE zi_q2c_descarga.

    SELECT SINGLE *
      FROM zi_q2c_descarga
      WHERE pcsordernum = @iv_ordernum
      INTO @ls_descarga.

    IF sy-subrc <> 0.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '030' iv_v1 = |ORDERNUM nao localizado para cancelamento: { iv_ordernum }| CHANGING ct_message = ct_msg ).
      RETURN.
    ENDIF.

    IF ls_descarga-status <> '03'.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '035' iv_v1 = ls_descarga-status CHANGING ct_message = ct_msg ).
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
