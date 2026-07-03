CLASS zclq2c_265_carga_granel DEFINITION
*-------------------------------------------------------------*
* PROGRAMA: zclq2c_265_carga_granel
* TITULO: Carga Granel e Cancelamento Carga Granel
* DESENVOLVEDOR: Thayná Mendonça (TMSILVA)
* DATA: 14/01/2026
* ID GAP: 265
*-------------------------------------------------------------*
* MOD  DATA         AUTOR           REQUEST/CHARM DESCRIÇÃO
*
***************************************************************
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS gc_msgid TYPE symsgid VALUE 'ZCL_Q2C_265_MSG_CG'.

    " Estrutura L200-H
    TYPES: BEGIN OF ty_l200_h,
             shnumber TYPE oig_shnum,
             ordernum TYPE zdeq2c_265_order_num,
             origordn TYPE zdeq2c_265_origordn,
             loadqty  TYPE zdeq2c_265_load_qty,
             sourcet  TYPE zdeq2c_265_sourcet,
             prodnum  TYPE zdeq2c_265_prod_num,
             prodname TYPE zdeq2c_265_prod_name,
             prodden  TYPE zdeq2c_265_prod_den,
             loadline TYPE zdeq2c_265_load_line,
             loadptfm TYPE zdeq2c_265_load_ptfm,
             drivernm TYPE zdeq2c_265_driver_nm,
             truckid  TYPE zdeq2c_265_truck_id,
             clrhose  TYPE zdeq2c_265_clr_hose,
             msgrcvtm TYPE zdeq2c_265_msgrcvtm,
             pprdname TYPE zdeq2c_265_pprd_name,
             pprodnum TYPE zdeq2c_265_pprd_num,
             tankinsp TYPE zdeq2c_265_tankinsp,
             flusharm TYPE zdeq2c_265_flush_arm,
             fabs     TYPE zdeq2c_265_fabs,
             sealclr  TYPE zdeq2c_265_sealclr,
             sealnum  TYPE zdeq2c_265_seal_num,
             sealqty  TYPE zdeq2c_265_seal_qty,
             grpname  TYPE zdeq2c_265_grp_name,
           END OF ty_l200_h.


    " Estrutura L200-C
    TYPES: BEGIN OF ty_l200_c,
             shnumber      TYPE oig_shnum,
             comp_number   TYPE i,
             comp_capacity TYPE i,
             prev_prod_nm  TYPE zdeq2c_265_pprd_name,
             prev_prod_cd  TYPE zdeq2c_265_pprd_num,
           END OF ty_l200_c.

    TYPES tt_l200_c TYPE STANDARD TABLE OF ty_l200_c WITH EMPTY KEY.


    " Mensagens
    TYPES: BEGIN OF ty_message,
             id       TYPE symsgid,
             number   TYPE symsgno,
             severity TYPE if_abap_behv_message=>t_severity,
             v1       TYPE string,
             v2       TYPE string,
             v3       TYPE string,
             v4       TYPE string,
           END OF ty_message.

    TYPES tt_message TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.


    " Método principal
    METHODS init
      IMPORTING
        is_l200_h   TYPE ty_l200_h OPTIONAL
        it_l200_c   TYPE tt_l200_c OPTIONAL
        iv_l201_c   TYPE oig_shnum OPTIONAL
      EXPORTING
        et_messages TYPE tt_message.

  PRIVATE SECTION.

    CONSTANTS:
      gc_dir_out TYPE string VALUE 'outbound/'.

    METHODS get_base_dir
      CHANGING ct_msg TYPE tt_message
      RETURNING VALUE(rv_dir) TYPE string.

    METHODS validate_l200_h
      IMPORTING is_l200_h TYPE ty_l200_h
      CHANGING  ct_msg   TYPE tt_message.

    METHODS validate_l200_c
      IMPORTING is_l200_c TYPE ty_l200_c
      CHANGING  ct_msg   TYPE tt_message.

    METHODS build_line_h
      IMPORTING is_l200_h TYPE ty_l200_h
      RETURNING VALUE(rv_line) TYPE string.

    METHODS build_line_c
      IMPORTING is_l200_c TYPE ty_l200_c
      RETURNING VALUE(rv_line) TYPE string.

    METHODS save_file
      IMPORTING
        iv_filename TYPE string
        iv_content  TYPE string
      CHANGING
        ct_msg      TYPE tt_message.

ENDCLASS.



CLASS ZCLQ2C_265_CARGA_GRANEL IMPLEMENTATION.


  METHOD init.

    DATA lv_content TYPE string.

*    validate_l200_h( EXPORTING is_l200_h = is_l200_h CHANGING ct_msg = et_messages ).

*    LOOP AT it_l200_c INTO DATA(ls_c).
*      validate_l200_c( EXPORTING is_l200_c = ls_c CHANGING ct_msg = et_messages ).
*    ENDLOOP.

*    IF et_messages IS NOT INITIAL.
*      RETURN.
*    ENDIF.

    " L200-H
    IF ( is_l200_h IS NOT INITIAL
         AND it_l200_c IS NOT INITIAL ).
    lv_content = build_line_h( is_l200_h ) && cl_abap_char_utilities=>cr_lf.

    save_file(
      EXPORTING
        iv_filename = |L200_H_CG{ is_l200_h-shnumber }_{ sy-datum }{ sy-uzeit }.TXT|
        iv_content  = lv_content
      CHANGING
        ct_msg      = et_messages
    ).


    " L200-C
    CLEAR lv_content.

    LOOP AT it_l200_c INTO DATA(ls_comp).
      lv_content = lv_content
        && build_line_c( ls_comp )
        && cl_abap_char_utilities=>cr_lf.
    ENDLOOP.

    save_file(
      EXPORTING
        iv_filename = |L200_C_CG{ is_l200_h-shnumber }_{ sy-datum }{ sy-uzeit }.TXT|
        iv_content  = lv_content
      CHANGING
        ct_msg      = et_messages
    ).

    ELSEIF iv_l201_c IS NOT INITIAL.

    save_file(
      EXPORTING
        iv_filename = |L201_CG{ iv_l201_c }_{ sy-datum }{ sy-uzeit }.TXT|
        iv_content  = |CG{ iv_l201_c }|
      CHANGING
        ct_msg      = et_messages
    ).

    ENDIF.

  ENDMETHOD.


  METHOD get_base_dir.

    SELECT SINGLE low
*      FROM tvarvc
       FROM zz1_tvarvc_q2c
      WHERE name = 'Z_Q2C_265_CARGA_GRANEL'
        AND type = 'P'
      INTO @rv_dir.

    IF sy-subrc <> 0 OR rv_dir IS INITIAL.
      APPEND VALUE #(
        id       = gc_msgid
        number   = '005'
        severity = if_abap_behv_message=>severity-error
        v1       = 'Z_Q2C_265_CARGA_GRANEL'
      ) TO ct_msg.
    ENDIF.

  ENDMETHOD.


  METHOD validate_l200_h.

    FIELD-SYMBOLS <fs> TYPE any.
    DATA lv_field TYPE string.

    DATA lt_fields TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    APPEND 'SHNUMBER' TO lt_fields.
    APPEND 'ORDERNUM' TO lt_fields.
    APPEND 'ORIGORDN' TO lt_fields.
    APPEND 'LOADQTY'  TO lt_fields.
    APPEND 'SOURCET'  TO lt_fields.
    APPEND 'PRODNUM'  TO lt_fields.
    APPEND 'PRODNAME' TO lt_fields.
    APPEND 'PRODDEN'  TO lt_fields.
    APPEND 'LOADLINE' TO lt_fields.
    APPEND 'LOADPTFM' TO lt_fields.
    APPEND 'DRIVERNM' TO lt_fields.
    APPEND 'TRUCKID'  TO lt_fields.
    APPEND 'CLRHOSE'  TO lt_fields.
    APPEND 'MSGRCVTM' TO lt_fields.

    LOOP AT lt_fields INTO lv_field.
      ASSIGN COMPONENT lv_field OF STRUCTURE is_l200_h TO <fs>.
      IF sy-subrc <> 0 OR <fs> IS INITIAL.
        APPEND VALUE #(
          id       = gc_msgid
          number   = '002'
          severity = if_abap_behv_message=>severity-error
          v1       = lv_field
        ) TO ct_msg.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD validate_l200_c.

    FIELD-SYMBOLS <fs> TYPE any.
    DATA lv_field TYPE string.

    DATA lt_fields TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    APPEND 'SHNUMBER'      TO lt_fields.
    APPEND 'COMP_NUMBER'   TO lt_fields.
    APPEND 'COMP_CAPACITY' TO lt_fields.

    LOOP AT lt_fields INTO lv_field.
      ASSIGN COMPONENT lv_field OF STRUCTURE is_l200_c TO <fs>.
      IF sy-subrc <> 0 OR <fs> IS INITIAL.
        APPEND VALUE #(
          id       = gc_msgid
          number   = '003'
          severity = if_abap_behv_message=>severity-error
          v1       = lv_field
        ) TO ct_msg.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD build_line_h.

    rv_line =
      |{ is_l200_h-shnumber };{ is_l200_h-ordernum };{ is_l200_h-origordn };|
    && |{ is_l200_h-loadqty };{ is_l200_h-sourcet };{ is_l200_h-prodnum };|
    && |{ is_l200_h-prodname };{ is_l200_h-prodden };{ is_l200_h-loadline };|
    && |{ is_l200_h-loadptfm };{ is_l200_h-drivernm };{ is_l200_h-truckid };|
    && |{ is_l200_h-clrhose };{ is_l200_h-pprdname };{ is_l200_h-pprodnum };|
    && |{ is_l200_h-tankinsp };{ is_l200_h-flusharm };{ is_l200_h-fabs };|
    && |{ is_l200_h-sealclr };{ is_l200_h-sealnum };{ is_l200_h-sealqty };|
    && |{ is_l200_h-msgrcvtm };{ is_l200_h-grpname }|.

  ENDMETHOD.


  METHOD build_line_c.

    rv_line =
      |{ is_l200_c-shnumber };|
    && |{ is_l200_c-comp_number   WIDTH = 2 PAD = '0' };|
    && |{ is_l200_c-comp_capacity WIDTH = 6 PAD = '0' };|
    && |{ is_l200_c-prev_prod_nm };{ is_l200_c-prev_prod_cd }|.

  ENDMETHOD.


  METHOD save_file.

    DATA lv_base TYPE string.
    DATA lv_path TYPE string.

    lv_base = get_base_dir( CHANGING ct_msg = ct_msg ).
    IF lv_base IS INITIAL.
      RETURN.
    ENDIF.

*    lv_path = |{ lv_base }{ gc_dir_out }{ iv_filename }|.
    lv_path = |{ lv_base }{ iv_filename }|.

    OPEN DATASET lv_path FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc <> 0.
      APPEND VALUE #(
        id       = gc_msgid
        number   = '004'
        severity = if_abap_behv_message=>severity-error
      ) TO ct_msg.
      RETURN.
    ENDIF.

    TRANSFER iv_content TO lv_path.
     IF sy-subrc EQ 0.
      APPEND VALUE #(
        id       = gc_msgid
        number   = '006'
        severity = if_abap_behv_message=>severity-success
      ) TO ct_msg.
     ENDIF.

    CLOSE DATASET lv_path.

  ENDMETHOD.
ENDCLASS.
