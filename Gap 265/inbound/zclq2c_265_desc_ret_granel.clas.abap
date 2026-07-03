*&---------------------------------------------------------------------*
* Object Name    : ZCLQ2C_265_DESC_RET_GRANEL
* Object Title   : Retorno Descarga PCS -> SAP
* WRICEF ID      : Q2C265I005 / Q2C265I006
* Author         : GitHub Copilot
* Date           : 03/07/2026
*-----------------------------------------------------------------------*
CLASS zclq2c_265_desc_ret_granel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_u301_h,
             ordernum  TYPE zdeq2c_265_order_num,
             trkintwt  TYPE zdeq2c_265_desc_trkintwt,
             trkfnlwt  TYPE zdeq2c_265_desc_trkfnlwt,
             lineemty  TYPE zdeq2c_265_desc_lineemty,
             pt_yrn    TYPE zdeq2c_265_desc_pt_yrn,
             desttyrn  TYPE zdeq2c_265_desc_desttyrn,
             prodnumb  TYPE zdeq2c_265_prod_num,
             line2use  TYPE zdeq2c_265_load_line,
             trkidy2n  TYPE zdeq2c_265_desc_trkidy2n,
             clrhose   TYPE zdeq2c_265_clr_hose,
             avveryrn  TYPE zdeq2c_265_desc_avveryrn,
             compdrop  TYPE zdeq2c_265_desc_compdrop,
             trkgdryn  TYPE zdeq2c_265_desc_trkgdryn,
             trkbkact  TYPE zdeq2c_265_desc_trkbkact,
             trkmtoff  TYPE zdeq2c_265_desc_trkmtoff,
             labinfo   TYPE zdeq2c_265_desc_labinfo,
             avverend  TYPE zdeq2c_265_desc_avverend,
             starttme  TYPE zdeq2c_265_desc_starttme,
             endtime   TYPE zdeq2c_265_desc_endtime,
             supname   TYPE zdeq2c_265_desc_supname,
             opsname   TYPE zdeq2c_265_desc_opsname,
           END OF ty_u301_h.

    TYPES: BEGIN OF ty_u301_s,
             sordrnm  TYPE zdeq2c_265_order_num,
             sealcode TYPE zdeq2c_265_desc_sealcode,
             sealyrn  TYPE zdeq2c_265_desc_sealyrn,
           END OF ty_u301_s.

    TYPES tt_u301_h TYPE STANDARD TABLE OF ty_u301_h WITH EMPTY KEY.
    TYPES tt_u301_s TYPE STANDARD TABLE OF ty_u301_s WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        iv_job TYPE abap_bool DEFAULT abap_false.

    METHODS execute
      CHANGING
        ct_msg TYPE zclq2c_265_desc_common=>tt_message.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_dir_entry,
             name TYPE eps2filnam,
           END OF ty_dir_entry.
    TYPES tt_dir_entry TYPE STANDARD TABLE OF ty_dir_entry WITH EMPTY KEY.

    DATA mv_job TYPE abap_bool.
    DATA mv_in_dir TYPE string.
    DATA mv_ok_dir TYPE string.
    DATA mv_err_dir TYPE string.
    DATA gt_file_raw TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA gt_dir_files TYPE tt_dir_entry.
    DATA gt_u301_h TYPE tt_u301_h.
    DATA gt_u301_s TYPE tt_u301_s.

    METHODS load_tvarvc
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS get_directory_files
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS display_main_header.

    METHODS process_single_file
      IMPORTING
        iv_file_path TYPE string
        iv_file_name TYPE string
      CHANGING
        ct_msg       TYPE zclq2c_265_desc_common=>tt_message.

    METHODS read_al11_file
      IMPORTING iv_file_path TYPE string.

    METHODS read_u301_h_file
      IMPORTING iv_file_name TYPE string.

    METHODS read_u301_s_file
      IMPORTING iv_file_name TYPE string.

    METHODS valida_arquivos
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS update_retorno
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS update_historico
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS update_log
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS display_file_summary
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

ENDCLASS.



CLASS zclq2c_265_desc_ret_granel IMPLEMENTATION.

  METHOD constructor.
    mv_job = iv_job.
  ENDMETHOD.

  METHOD execute.
    load_tvarvc( CHANGING ct_msg = ct_msg ).
    display_main_header( ).
    IF ct_msg IS NOT INITIAL.
      IF mv_job = abap_true.
        display_file_summary( CHANGING ct_msg = ct_msg ).
      ENDIF.
      RETURN.
    ENDIF.

    get_directory_files( CHANGING ct_msg = ct_msg ).
    LOOP AT gt_dir_files INTO DATA(ls_file).
      process_single_file(
        EXPORTING iv_file_path = |{ mv_in_dir }{ ls_file-name }|
                  iv_file_name = ls_file-name
        CHANGING  ct_msg       = ct_msg ).
    ENDLOOP.

    valida_arquivos( CHANGING ct_msg = ct_msg ).
    update_retorno( CHANGING ct_msg = ct_msg ).
    update_historico( CHANGING ct_msg = ct_msg ).
    update_log( CHANGING ct_msg = ct_msg ).

    IF mv_job = abap_true.
      display_file_summary( CHANGING ct_msg = ct_msg ).
    ENDIF.
  ENDMETHOD.

  METHOD load_tvarvc.
    mv_in_dir  = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_IN' ).
    mv_ok_dir  = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_PROC' ).
    mv_err_dir = zclq2c_265_desc_common=>get_tvarvc_value( 'ZQ2C_DESCARGA_PCS_ERR' ).

    IF mv_in_dir IS INITIAL.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '020' iv_v1 = 'ZQ2C_DESCARGA_PCS_IN' CHANGING ct_message = ct_msg ).
    ENDIF.
  ENDMETHOD.

  METHOD get_directory_files.
    DATA lt_dir_list TYPE STANDARD TABLE OF eps2fili WITH EMPTY KEY.
    CLEAR gt_dir_files.

    CALL FUNCTION 'EPS2_GET_DIRECTORY_LISTING'
      EXPORTING
        iv_dir_name            = mv_in_dir
      TABLES
        dir_list               = lt_dir_list
      EXCEPTIONS
        OTHERS                 = 1.

    LOOP AT lt_dir_list INTO DATA(ls_dir).
      IF ls_dir-name(4) <> 'U301' OR ls_dir-size <= 0.
        CONTINUE.
      ENDIF.
      APPEND VALUE #( name = ls_dir-name ) TO gt_dir_files.
    ENDLOOP.
  ENDMETHOD.

  METHOD display_main_header.
    IF mv_job = abap_true.
      WRITE: / '============================================================='.
      WRITE: / '=== GAP 265 - RETORNO DESCARGA PCS -> SAP ==='.
      WRITE: / '============================================================='.
      WRITE: / 'Diretorio:', mv_in_dir.
      WRITE: / sy-datum, sy-uzeit.
    ENDIF.
  ENDMETHOD.

  METHOD process_single_file.
    read_al11_file( iv_file_path = iv_file_path ).

    IF gt_file_raw IS INITIAL.
      zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '040' iv_v1 = |Arquivo nao lido: { iv_file_name }| iv_name = iv_file_name CHANGING ct_message = ct_msg ).
      RETURN.
    ENDIF.

    IF iv_file_name(6) = 'U301-H'.
      read_u301_h_file( iv_file_name = iv_file_name ).
    ELSEIF iv_file_name(6) = 'U301-S'.
      read_u301_s_file( iv_file_name = iv_file_name ).
    ENDIF.

    zclq2c_265_desc_common=>add_success( EXPORTING iv_number = '011' iv_v1 = iv_file_name iv_name = iv_file_name CHANGING ct_message = ct_msg ).
  ENDMETHOD.

  METHOD read_al11_file.
    DATA lv_line TYPE string.
    CLEAR gt_file_raw.
    OPEN DATASET iv_file_path FOR INPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DO.
      READ DATASET iv_file_path INTO lv_line.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      APPEND lv_line TO gt_file_raw.
    ENDDO.
    CLOSE DATASET iv_file_path.
  ENDMETHOD.

  METHOD read_u301_h_file.
    DATA ls_header TYPE ty_u301_h.

    LOOP AT gt_file_raw INTO DATA(lv_raw_line).
      SPLIT lv_raw_line AT ';' INTO ls_header-ordernum
                                   ls_header-trkintwt
                                   ls_header-trkfnlwt
                                   ls_header-lineemty
                                   ls_header-pt_yrn
                                   ls_header-desttyrn
                                   ls_header-prodnumb
                                   ls_header-line2use
                                   ls_header-trkidy2n
                                   ls_header-clrhose
                                   ls_header-avveryrn
                                   ls_header-compdrop
                                   ls_header-trkgdryn
                                   ls_header-trkbkact
                                   ls_header-trkmtoff
                                   ls_header-labinfo
                                   ls_header-avverend
                                   ls_header-starttme
                                   ls_header-endtime
                                   ls_header-supname
                                   ls_header-opsname.
      APPEND ls_header TO gt_u301_h.
      CLEAR ls_header.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_u301_s_file.
    DATA ls_seal TYPE ty_u301_s.

    LOOP AT gt_file_raw INTO DATA(lv_raw_line).
      SPLIT lv_raw_line AT ';' INTO ls_seal-sordrnm
                                   ls_seal-sealcode
                                   ls_seal-sealyrn.
      APPEND ls_seal TO gt_u301_s.
      CLEAR ls_seal.
    ENDLOOP.
  ENDMETHOD.

  METHOD valida_arquivos.
    DATA lt_ordernum TYPE RANGE OF zdeq2c_265_order_num.

    LOOP AT gt_u301_h INTO DATA(ls_header).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_header-ordernum ) TO lt_ordernum.

      READ TABLE gt_u301_s WITH KEY sordrnm = ls_header-ordernum TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '030' iv_v1 = |U301-S nao encontrado para ORDERNUM { ls_header-ordernum }| CHANGING ct_message = ct_msg ).
      ENDIF.
    ENDLOOP.

    LOOP AT gt_u301_s INTO DATA(ls_seal).
      READ TABLE gt_u301_h WITH KEY ordernum = ls_seal-sordrnm TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '030' iv_v1 = |U301-H nao encontrado para ORDERNUM { ls_seal-sordrnm }| CHANGING ct_message = ct_msg ).
      ENDIF.
    ENDLOOP.

    IF lt_ordernum IS NOT INITIAL.
      SELECT pcsordernum
        FROM zi_q2c_descarga
        WHERE pcsordernum IN @lt_ordernum
        INTO TABLE @DATA(lt_existing).

      LOOP AT gt_u301_h INTO ls_header.
        READ TABLE lt_existing WITH KEY pcsordernum = ls_header-ordernum TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '030' iv_v1 = |ORDERNUM nao existe no SAP: { ls_header-ordernum }| CHANGING ct_message = ct_msg ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD update_retorno.
    DATA lt_hdr TYPE STANDARD TABLE OF zdescarga_interface_pcs WITH EMPTY KEY.
    DATA lt_itm TYPE STANDARD TABLE OF zdescarga_interface_pcs_i WITH EMPTY KEY.

    IF ct_msg IS NOT INITIAL.
      RETURN.
    ENDIF.

    LOOP AT gt_u301_h INTO DATA(ls_header).
      APPEND INITIAL LINE TO lt_hdr ASSIGNING FIELD-SYMBOL(<fs_hdr>).
      MOVE-CORRESPONDING ls_header TO <fs_hdr>.
    ENDLOOP.

    LOOP AT gt_u301_s INTO DATA(ls_seal).
      APPEND INITIAL LINE TO lt_itm ASSIGNING FIELD-SYMBOL(<fs_itm>).
      MOVE-CORRESPONDING ls_seal TO <fs_itm>.
    ENDLOOP.

    LOOP AT gt_u301_h INTO ls_header.
      DELETE FROM zdescarga_interface_pcs_i WHERE sordrnm = @ls_header-ordernum.
    ENDLOOP.

    IF lt_hdr IS NOT INITIAL.
      MODIFY zdescarga_interface_pcs FROM TABLE @lt_hdr.
    ENDIF.

    IF lt_itm IS NOT INITIAL.
      MODIFY zdescarga_interface_pcs_i FROM TABLE @lt_itm.
    ENDIF.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD update_historico.
    LOOP AT gt_u301_h INTO DATA(ls_header).
      UPDATE ztbq2c_descarga
        SET peso_inicial = @ls_header-trkintwt,
            peso_final   = @ls_header-trkfnlwt,
            aenam        = @sy-uname,
            aedat        = @sy-datum
        WHERE pcs_ordernum = @ls_header-ordernum.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_log.
    DATA ls_log TYPE ztbq2c_descgralog.
    DATA lv_ts TYPE timestamp.

    GET TIME STAMP FIELD lv_ts.

    LOOP AT ct_msg INTO DATA(ls_msg).
      CLEAR ls_log.
      ls_log-tmstmp = lv_ts.
      ls_log-intid = ls_msg-name.
      ls_log-intty = 'I'.
      ls_log-intst = COND #( WHEN ls_msg-type = 'E' THEN '2' ELSE '1' ).
      ls_log-msgty = ls_msg-type.
      ls_log-mensagem = |{ ls_msg-v1 } { ls_msg-v2 }|.
      MODIFY ztbq2c_descgralog FROM ls_log.
    ENDLOOP.
  ENDMETHOD.

  METHOD display_file_summary.
    DATA lv_ok TYPE i VALUE 0.
    DATA lv_err TYPE i VALUE 0.

    LOOP AT ct_msg INTO DATA(ls_msg).
      IF ls_msg-type = 'E'.
        lv_err = lv_err + 1.
      ELSEIF ls_msg-type = 'S'.
        lv_ok = lv_ok + 1.
      ENDIF.
      WRITE: /5  ls_msg-name,
              30 ls_msg-ordernum,
              45 ls_msg-type,
              55 ls_msg-v1,
              100 ls_msg-v2.
    ENDLOOP.

    WRITE: / '============================================================='.
    WRITE: / |Job Descarga concluido: { lv_ok } OK / { lv_err } erro(s)|.
  ENDMETHOD.

ENDCLASS.
