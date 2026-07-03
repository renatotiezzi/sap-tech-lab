CLASS zclq2c_265_desc_ret_granel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_u301_h,
             ordernum  TYPE string,
             trkintwt  TYPE string,
             trkfnlwt  TYPE string,
             lineemty  TYPE string,
             pt_yrn    TYPE string,
             desttyrn  TYPE string,
             prodnumb  TYPE string,
             line2use  TYPE string,
             trkidy2n  TYPE string,
             clrhose   TYPE string,
             avveryrn  TYPE string,
             compdrop  TYPE string,
             trkgdryn  TYPE string,
             trkbkact  TYPE string,
             trkmtoff  TYPE string,
             labinfo   TYPE string,
             avverend  TYPE string,
             starttme  TYPE string,
             endtime   TYPE string,
             supname   TYPE string,
             opsname   TYPE string,
           END OF ty_u301_h.

    TYPES: BEGIN OF ty_u301_s,
             sordrnm  TYPE string,
             sealcode TYPE string,
             sealyrn  TYPE string,
           END OF ty_u301_s.

    TYPES tt_u301_s TYPE STANDARD TABLE OF ty_u301_s WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        iv_job TYPE abap_bool DEFAULT abap_false.

    METHODS execute
      CHANGING
        ct_msg TYPE zclq2c_265_desc_common=>tt_message.

  PRIVATE SECTION.

    DATA mv_job TYPE abap_bool.
    DATA mv_in_dir TYPE string.
    DATA mv_ok_dir TYPE string.
    DATA mv_err_dir TYPE string.

    METHODS load_tvarvc
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS get_directory_files
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

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

    METHODS update_retorno
      CHANGING ct_msg TYPE zclq2c_265_desc_common=>tt_message.

    METHODS update_historico
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
    IF ct_msg IS NOT INITIAL.
      RETURN.
    ENDIF.

    get_directory_files( CHANGING ct_msg = ct_msg ).
    update_retorno( CHANGING ct_msg = ct_msg ).
    update_historico( CHANGING ct_msg = ct_msg ).

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
    CALL FUNCTION 'EPS2_GET_DIRECTORY_LISTING'
      EXPORTING
        iv_dir_name            = mv_in_dir
      TABLES
        dir_list               = lt_dir_list
      EXCEPTIONS
        OTHERS                 = 1.

    LOOP AT lt_dir_list INTO DATA(ls_dir).
      process_single_file(
        EXPORTING iv_file_path = |{ mv_in_dir }{ ls_dir-name }|
                  iv_file_name = ls_dir-name
        CHANGING  ct_msg       = ct_msg ).
    ENDLOOP.
  ENDMETHOD.

  METHOD process_single_file.
    read_al11_file( iv_file_path = iv_file_path ).

    IF iv_file_name(6) = 'U301-H'.
      read_u301_h_file( iv_file_name = iv_file_name ).
    ELSEIF iv_file_name(6) = 'U301-S'.
      read_u301_s_file( iv_file_name = iv_file_name ).
    ENDIF.
  ENDMETHOD.

  METHOD read_al11_file.
    DATA lv_line TYPE string.
    OPEN DATASET iv_file_path FOR INPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DO.
      READ DATASET iv_file_path INTO lv_line.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
    ENDDO.
    CLOSE DATASET iv_file_path.
  ENDMETHOD.

  METHOD read_u301_h_file.
    " Estrutura reservada para parse e persistencia do header de retorno.
    " O desenho final deve espelhar a rotina read_l301_h_file da carga.
  ENDMETHOD.

  METHOD read_u301_s_file.
    " Estrutura reservada para parse dos lacres de retorno.
  ENDMETHOD.

  METHOD update_retorno.
    " Atualizar tabela Z oficial do processo de Descarga.
    " O objeto final deve gravar header + lacres de forma idempotente.
  ENDMETHOD.

  METHOD update_historico.
    " Atualizar historico e status seguindo o padrao da carga.
  ENDMETHOD.

  METHOD display_file_summary.
    " Resumo final para job, espelhando a saida do retorno da carga.
  ENDMETHOD.

ENDCLASS.
