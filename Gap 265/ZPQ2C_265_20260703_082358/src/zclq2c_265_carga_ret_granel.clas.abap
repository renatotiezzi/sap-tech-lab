*&---------------------------------------------------------------------*
*& Class ZCLQ2C_SALES_ORDER_CREATION
*&---------------------------------------------------------------------*
class zclq2c_265_carga_ret_granel definition
  public
  final
  create public .

  public section.

    types:
      begin of ty_dir_entry,
        name type eps2filnam,
      end of ty_dir_entry .
    types:
      begin of ty_l300_h,
        shnumber         type oig_shnum,
        strttact         type char20,
        name             type eps2filnam,
        l300_h           type char1,
        l301_C           type char1,
        l301_h           type char1,
        status           type zdeq2c_status_moni,
        Shnumber_nofound type char1,
        upd_already      type char1,
        ret_process      type char1,
      end of ty_l300_h .
    types:
      begin of ty_l301_C,
        shnumber    type oig_shnum,
        com_number  type char3,
        o2          type char5,
        hydrocar    type char3,
        temp        type char5,
        name        type eps2filnam,
        l300_h      type char1,
        l301_C      type char1,
        l301_h      type char1,
        status      type zdeq2c_status_moni,
        upd_already type char1,

      end of ty_l301_c .
    types:
      begin of ty_l301_h,
        data        type zstq2c_ret_granel_l301_h,
        name        type eps2filnam,
        l300_h      type char1,
        l301_c      type char1,
        l301_h      type char1,
        status      type zdeq2c_status_moni,
        upd_already type char1,

      end of ty_l301_h .
    types:
      " Mensagens
      begin of ty_message,
        name       type eps2filnam,
        shnumber   type oig_shnum,
        com_number type oig_cmpnmr,
        id         type symsgid,
        number     type symsgno,
        type       type symsgty,
        severity   type if_abap_behv_message=>t_severity,
        v1         type string,
        v2         type string,
        v3         type string,
        v4         type string,
      end of ty_message .
    types ty_pcs_hdr type zi_q2c_pcs_itm .
    types:
      tt_pcs_det type standard table of ztq2c_pcs_det with empty key .
    types:
      tt_pcs_hdr type standard table of ty_pcs_hdr with empty key .
    types:
      tt_message type standard table of ty_message with empty key .
    types:
      tt_l300_h type standard table of ty_l300_h with empty key .
    types:
      tt_l301_C type standard table of ty_l301_C with empty key .
    types:
      tt_l301_h type standard table of ty_l301_h with empty key .

    types: begin of ty_file_log,
             id_int          type zdeca_id_interface,
             int_type        type zdeca_int_type,
             file_name       type zdeca_file_name,
*             file_step       type zdeca_file_step,
             file_status     type zdeca_status,
             last_changed_at type abp_lastchange_tstmpl,
           end of ty_file_log.

    methods constructor
      importing
        !iv_folder     type string default '/int/cifs/sap/DS4/tmp'
        !iv_shnumber   type oig_shnum optional
        !iv_com_number type oig_cmpnmr optional
        !iv_job        type char1 .
    methods execute
      changing
        !ct_msg type tt_message optional .
  PROTECTED SECTION.

private section.

  "----------------------------------------------------------------------
  " Instance Attributes - Parameters
  "----------------------------------------------------------------------
  data GV_SHOWSM type CHAR1 .
  data GV_FOLDER type STRING .
  data GV_MVFILE type STRING .
  data:
    "----------------------------------------------------------------------
    " Instance Attributes - File Processing
    "----------------------------------------------------------------------
    gt_file_raw     type standard table of string .
  data GV_RAW_LINE type STRING .
  data:
*    "----------------------------------------------------------------------
*    " Instance Attributes - Directory Processing
*    "----------------------------------------------------------------------
    gt_dir_files    type standard table of ty_dir_entry .
  data GS_DIR_ENTRY type TY_DIR_ENTRY .
  data GV_CURRENT_FILE type STRING .
  data GV_L300_H type TT_L300_H .
  data GV_L301_C type TT_L301_C .
  data GV_L301_H type TT_L301_H .
  data GV_FILE_L300_H type STRING .
  data GV_FILE_L301_C type STRING .
  data GV_FILE_L301_H type STRING .
  data GV_JOB type CHAR1 .
  data GT_PCS_DET type TT_PCS_DET .
  data GV_STATUS type CHAR1 .
  data GV_SHNUMBER type OIG_SHNUM .

  methods MOVE_INPUT_FILE
    changing
      !CT_MSG type TT_MESSAGE .
  methods UPDATE_HISTORICO .
  methods LOAD_DATA
    changing
      !CT_MSG type TT_MESSAGE .
  "----------------------------------------------------------------------
  " Private Methods
  "----------------------------------------------------------------------
  methods LOAD_STVARV_VALUES
    changing
      !CT_MSG type TT_MESSAGE optional .
  methods GET_DIRECTORY_FILES .
  methods PROCESS_SINGLE_FILE
    importing
      !IV_FILE_PATH type STRING
      !IV_FILE_NAME type EPS2FILNAM
    changing
      !CT_MSG type TT_MESSAGE .
  methods READ_AL11_FILE
    importing
      !IV_FILE_PATH type STRING .
  methods DISPLAY_FILE_SUMMARY
    importing
      !IV_FILE_PATH type STRING
    changing
      !CT_MSG type TT_MESSAGE .
  methods CLEAR_FILE_DATA .
  methods READ_L300_H_FILE
    importing
      !IV_FILE_PATH type STRING
      !IV_FILE_NAME type EPS2FILNAM .
  methods READ_L301_C_FILE
    importing
      !IV_FILE_PATH type STRING
      !IV_FILE_NAME type EPS2FILNAM .
  methods READ_L301_H_FILE
    importing
      !IV_FILE_PATH type STRING
      !IV_FILE_NAME type EPS2FILNAM .
  methods UPDATE_RETORNO
    changing
      !CT_MSG type TT_MESSAGE .
  methods VALIDA_ARQUIVOS
    changing
      !CT_MSG type TT_MESSAGE optional .
  methods DISPLAY_MAIN_HEADER .
  methods ERROR_HANDLING
    changing
      !CT_MSG type TT_MESSAGE optional .
  methods UPDATE_LOG
    importing
      !IV_FILE_PATH type STRING
    changing
      !CT_MSG type TT_MESSAGE .
ENDCLASS.



CLASS ZCLQ2C_265_CARGA_RET_GRANEL IMPLEMENTATION.


  METHOD CLEAR_FILE_DATA.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    CLEAR: gt_file_raw.
  ENDMETHOD.


  METHOD CONSTRUCTOR.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    gv_folder       = iv_folder.
    gv_shnumber     = iv_shnumber.
*    gv_file_l300_h  = iv_file_l300_h.
*    gv_file_l301_c  = iv_file_l301_c.
*    gv_file_l301_h  = iv_file_l301_h.
    gv_job          = iv_job.
  ENDMETHOD.


  method display_file_summary.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    if gv_job = abap_true.
      write: / '============================================================='.
      write: / '=== RESUMO DO PROCESSAMENTO DE ARQUIVOS ==='.
      write: / '============================================================='.
      write: / TEXT-002, iv_file_path. "'Diretório:'
      write: / sy-datum.
      write: / sy-uzeit.
      write: /5  TEXT-003, "'Nome do Arquivo'
              30 TEXT-004, "'Numero da Ordem'(
              45 TEXT-005, "'Tp. Msg.'
              55 TEXT-006, "'Mensagem Processamento de arquivo',
              100 TEXT-007. "'Mensagem move arquivo processado'(007).
      loop at ct_msg assigning field-symbol(<fs_msg>).
        write: /5  <fs_msg>-name,
                30 <fs_msg>-shnumber,
                45 <fs_msg>-type,
                55 <fs_msg>-v1,
                100 <fs_msg>-v2.
      endloop.
    endif.
  endmethod.


  METHOD DISPLAY_MAIN_HEADER.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    IF gv_job = abap_true.
      WRITE: / '============================================================='.
      WRITE: / '=== Carga Retorno de Granel - Processamento de Arquivos ==='.
      WRITE: / '============================================================='.
      WRITE: / TEXT-010, sy-datum, TEXT-011, sy-uzeit. "'Data de Execução:' 'Hora:'
      WRITE: / TEXT-012, gv_current_file. "'Pasta de Input:'
      WRITE: / TEXT-013, gv_mvfile. "'Mover Arquivo Importado:'
      SKIP.
    ENDIF.
  ENDMETHOD.


  method error_handling.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    loop at gv_l300_h assigning field-symbol(<fs_l300_h>).
      if <fs_l300_h>-l300_h = abap_true and  <fs_l300_h>-l301_c = abap_true and <fs_l300_h>-l301_h = abap_true.
        if <fs_l300_h>-shnumber_nofound = abap_true.
            <fs_l300_h>-ret_process = abap_true.
            modify gv_l300_h from <fs_l300_h> index sy-tabix.
            append value #(
              shnumber = <fs_l300_h>-shnumber
              type     = 'E'
              v1       = TEXT-023 "'Ordem de transporte não encontrada'(023)
            ) to ct_msg.
        else.
          if <fs_l300_h>-status ne gv_status and <fs_l300_h>-upd_already = abap_false.
            <fs_l300_h>-ret_process = abap_true.
            modify gv_l300_h from <fs_l300_h> index sy-tabix.
            append value #(
              shnumber = <fs_l300_h>-shnumber
              type     = 'S'
              v1       = text-016 "'Carga retorno processada com sucesso'(016)
            ) to ct_msg.
          else.
            append value #(
              shnumber = <fs_l300_h>-shnumber
              type     = 'E'
              v1       = text-017 "'Status do transporte diferente de 4 ou já existem valores preenchidos previamente'(017)
            ) to ct_msg.
          endif.
        endif.
      else.
        append value #(
          shnumber = <fs_l300_h>-shnumber
          type     = 'E'
          v1       = text-018 "'Carga retorno não processada - não encontrado arquivos equivalentes L300_H, L_301_C, L_301_H'(018)
        ) to ct_msg.
      endif.
    endloop.


    loop at gv_l301_c assigning field-symbol(<fs_l301_c>).
      if <fs_l301_c>-l300_h = abap_false or  <fs_l301_c>-l301_c = abap_false or  <fs_l301_c>-l301_h = abap_false.
        append value #(
          shnumber = <fs_l301_c>-shnumber
          name     = <fs_l301_c>-name
          type     = 'E'
          v1       = text-017 "'Carga retorno não processada - não encontrado arquivos equivalentes L300_H, L_301_C, L_301_H'(018)
        ) to ct_msg.
      endif.
    endloop.

    loop at gv_l301_h assigning field-symbol(<fs_l301_h>).
      if <fs_l301_h>-l300_h = abap_false or  <fs_l301_h>-l301_c = abap_false or  <fs_l301_h>-l301_h = abap_false.
        append value #(
          shnumber = <fs_l301_h>-data-shnumber
          name     = <fs_l301_h>-name
          type     = 'E'
          v1       = text-018 "'Carga retorno não processada - não encontrado arquivos equivalentes L300_H, L_301_C, L_301_H'(018)
        ) to ct_msg.
      endif.
    endloop.

  endmethod.


  method execute.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
* Read TVARV
    load_stvarv_values( changing ct_msg = ct_msg ).
* Display JOB report (when JOB flagged)
    display_main_header( ).
    if gv_job is not initial and ct_msg is not initial.
      display_file_summary(
      exporting
         iv_file_path = gv_current_file
      changing
        ct_msg = ct_msg
         ).
      return.
    endif.

*Read files
    get_directory_files(  ).
    if gt_dir_files is initial.
      append value #(
        v1       = |{ text-001 } { gv_current_file }| "'Não foram encontrados arquivos no diretório'
      ) to ct_msg.
      if gv_job is not initial.
        display_file_summary(
        exporting
           iv_file_path = gv_current_file
        changing
          ct_msg = ct_msg
           ).
        return.
      endif.
      return.
    endif.

* Processing files
    loop at gt_dir_files into gs_dir_entry.
      data(lv_single_file) = |{ gv_current_file }{ gs_dir_entry-name }|.
      process_single_file(
      exporting
         iv_file_path = lv_single_file
         iv_file_name = gs_dir_entry-name
       changing
        ct_msg = ct_msg ).
    endloop.
    if gv_l300_h is not initial and gv_l301_c is not initial and gv_l301_h is not initial.
* File validate - files equivalence l300_h, l301_c e l301_h
      valida_arquivos( ).
* Load additional data
      load_data( changing ct_msg = ct_msg ).
* Update Z tab Retorno de Granel
      update_retorno( changing ct_msg = ct_msg ).
* Error handling
      error_handling( changing ct_msg = ct_msg ).
* Update Z tab status e historico
      update_historico( ).
* Move processed files
*    move_input_file( changing ct_msg = ct_msg ).
    else.
      append value #(
      v1       = |{ text-025 } { gv_current_file }| "'Não foram encontrados arquivos equivalentes para ordem no diretório
    ) to ct_msg.
    endif.

* Update logs
*        update_log(
*      exporting
*         iv_file_path = gv_current_file
*      changing
*        ct_msg = ct_msg
*         ).
* Print status in case JOB process
    sort ct_msg by shnumber.
    if gv_job is not initial.
      display_file_summary(
      exporting
         iv_file_path = gv_current_file
      changing
        ct_msg = ct_msg
         ).
    endif.
  endmethod.


  method get_directory_files.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    data: lt_dir_list type table of eps2fili,
          ls_dir_list type eps2fili,
          lv_dir_name type eps2filnam.

    clear gt_dir_files.

    lv_dir_name = gv_current_file.

    call function 'EPS2_GET_DIRECTORY_LISTING'
      exporting
        iv_dir_name            = lv_dir_name
      tables
        dir_list               = lt_dir_list
      exceptions
        invalid_eps_subdir     = 1
        sapgparam_failed       = 2
        build_directory_failed = 3
        no_authorization       = 4
        read_directory_failed  = 5
        too_many_read_errors   = 6
        empty_directory_list   = 7
        others                 = 8.

    if sy-subrc = 0.

      loop at lt_dir_list into ls_dir_list.
        if ls_dir_list-name(3) <> 'L30'.
          continue.
        endif.

        if ls_dir_list-size > 0.
          clear gs_dir_entry.
          gs_dir_entry-name = ls_dir_list-name.
          append gs_dir_entry to gt_dir_files.
        endif.
      endloop.
    endif.
  endmethod.


  method load_data.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*

    field-symbols: <fs_l300_h> type ty_l300_h.
    field-symbols: <fs_l301_c> type ty_l301_c.
    field-symbols: <fs_l301_h> type ty_l301_h.
    data: lt_shnumber type range of ztq2c_pcs_det-shnumber.
    data: lo_status_granel type ref to zclq2c_status_granel.

    loop at gv_l300_h assigning <fs_l300_h>.
      lt_shnumber = value #(
        ( sign = 'I' option = 'EQ' low = <fs_l300_h>-shnumber ) ).
    endloop.

    if gv_l300_h is not initial.

      select *
        from ztq2c_pcs_det
        where shnumber in @lt_shnumber
        into table @gt_pcs_det. "#EC CI_NOORDER

      select *
        from oigsvcc
        where shnumber in @lt_shnumber
        into table @data(it_oigsvcc). "#EC CI_NOORDER

* captura status do transporte, valida Shnumber existe e atualiza tabelas de dados dos arquivos
      loop at gv_l300_h assigning <fs_l300_h>.
        read table it_oigsvcc assigning field-symbol(<fs_oigsvcc>) with key Shnumber = <fs_l300_h>-Shnumber.
        if sy-subrc ne 0.
          <fs_l300_h>-Shnumber_nofound = abap_true.
          modify gv_l300_h from <fs_l300_h>.
          return.
        endif.
        lo_status_granel = new zclq2c_status_granel( iv_shnumber = <fs_l300_h>-Shnumber ).
        lo_status_granel->get_status_moni_proc( receiving rs_status_moni = <fs_l300_h>-status ).

        modify gv_l300_h from <fs_l300_h>.
        loop at gv_l301_c assigning <fs_l301_c> where Shnumber = <fs_l300_h>-Shnumber.
          <fs_l301_c>-status = <fs_l300_h>-status.
          modify gv_l301_c from <fs_l301_c>.
          loop at gv_l301_h assigning <fs_l301_h> where data-Shnumber = <fs_l300_h>-Shnumber.
            <fs_l301_h>-status = <fs_l300_h>-status.
            modify gv_l301_h from <fs_l301_h>.
          endloop.
        endloop.
      endloop.

*Captura se ja existem entradas anteriores para componente

      loop at gv_l300_h assigning <fs_l300_h>.
        loop at gv_l301_c assigning <fs_l301_c> where Shnumber = <fs_l300_h>-Shnumber.

          loop at gt_pcs_det assigning field-symbol(<fs_pcs_det>) where shnumber = <fs_l300_h>-shnumber and
                                                                        com_number = <fs_l301_c>-com_number.
            if <fs_pcs_det>-trkintwt is initial and <fs_pcs_det>-trkfnlwt  is initial and
               <fs_pcs_det>-lineused is initial and <fs_pcs_det>-qty2load  is initial and <fs_pcs_det>-sourstnk is initial and
               <fs_pcs_det>-prodnumb is initial and <fs_pcs_det>-line2use  is initial and <fs_pcs_det>-texaco3  is initial and
               <fs_pcs_det>-spillpro is initial and <fs_pcs_det>-gnrcon    is initial and <fs_pcs_det>-coloryn  is initial and
               <fs_pcs_det>-trkpos   is initial and <fs_pcs_det>-drainins  is initial and <fs_pcs_det>-tankins  is initial and
               <fs_pcs_det>-flushamt is initial and <fs_pcs_det>-fabs_yrn  is initial and <fs_pcs_det>-trkvlvbf is initial and
               <fs_pcs_det>-trkgdryn is initial and <fs_pcs_det>-starttme  is initial and <fs_pcs_det>-endtime is initial and
               <fs_pcs_det>-opsname  is initial and <fs_pcs_det>-sealqty   is initial.

            else.
              <fs_l300_h>-upd_already = abap_true.
              modify gv_l300_h from <fs_l300_h>.

              <fs_l301_c>-upd_already = abap_true.
              modify gv_l301_c from <fs_l301_c>.

              loop at gv_l301_h assigning <fs_l301_h> where data-Shnumber = <fs_l300_h>-Shnumber.
                <fs_l301_h>-upd_already = abap_true.
                modify gv_l301_h from <fs_l301_h>.
              endloop.
            endif.
          endloop.
        endloop.
      endloop.
    endif.



 endmethod.


  method load_stvarv_values.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*

    types: begin of ty_range_structure,
             sign   type sign,
             option type option,
             low    type tvarvc-low,
             high   type tvarvc-high,
           end of ty_range_structure.
    data: lt_range type table of ty_range_structure.
    data(lo_reader) = new zcl_tvarvc_range( ).

    data: lv_low type tvarvc-low.

*    " Load PCS in/out path
    clear lv_low.
*    select single low from tvarvc into lv_low
*      where name = 'ZQ2C_RETORNO_PCS_IN'
*        and type = 'P'. "#EC CI_NOORDER
    clear lt_range.
    lo_reader->get_range_for_name( exporting i_name   = 'ZQ2C_RETORNO_PCS_IN'
                                   changing  rt_range = lt_range  ).
    read table lt_range assigning field-symbol(<fs_range1>) index 1.

*    if sy-subrc ne 0.
    if <fs_range1> is assigned and <fs_range1>-low is not initial.
      append value #(
         v1       = text-008 "'Caminho do arquivo Retorno PCS "IN" não encontrado.TVARVC ZQ2C_RETORNO_PCS_IN'(008)
       ) to ct_msg.
      return.
    else.
      gv_current_file =  |{ lv_low case = lower }|.

    endif.

    clear lv_low.
*    select single low from tvarvc into lv_low
*      where name = 'ZQ2C_RETORNO_PCS_OUT'
*        and type = 'P'.                                 "#EC CI_NOORDER
    clear lt_range.
    lo_reader->get_range_for_name( exporting i_name   = 'ZQ2C_RETORNO_PCS_OUT'
                                   changing  rt_range = lt_range  ).
    read table lt_range assigning field-symbol(<fs_range2>) index 1.

*    if sy-subrc ne 0.
    if <fs_range2> is assigned and <fs_range2>-low is not initial.

      append value #(
        v1       = text-009 "'Caminho do arquivo Retorno PCS "OUT" não encontrado.TVARVC ZQ2C_RETORNO_PCS_OUT'(009)
      ) to ct_msg.
      return.
    else.
      gv_mvfile = |{ lv_low case = lower }|.
    endif.

    clear lv_low.
*    select single low from tvarvc into lv_low
*      where name = 'ZQ2C_RETORNO_PCS_STATUS'
*        and type = 'P'.                                 "#EC CI_NOORDER

    clear lt_range.
    lo_reader->get_range_for_name( exporting i_name   = 'ZQ2C_RETORNO_PCS_STATUS'
                                   changing  rt_range = lt_range  ).
    read table lt_range assigning field-symbol(<fs_range3>) index 1.

*    if sy-subrc ne 0.
    if <fs_range3> is assigned and <fs_range3>-low is not initial.
      append value #(
        v1       = text-024 "Não encontrado TVARV ZQ2C_RETORNO_PCS_STATUS para validar status da carga
      ) to ct_msg.
      return.
    else.
      gv_status = |{ lv_low case = lower }|.
    endif.

  endmethod.


  method move_input_file.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    data: lv_source_path  type string,
          lv_target_path  type string,
          lv_filename     type string,
          lv_line         type string,
          lt_file_content type standard table of string,
          lv_subrc        type sy-subrc.

    loop at ct_msg assigning field-symbol(<fs_msg>) .
      if <fs_msg>-shnumber is initial and <fs_msg>-name is not initial.
        lv_source_path = |{ gv_current_file }{ <fs_msg>-name }|.
        lv_target_path = |{ gv_mvfile }{ 'processado' }_{ <fs_msg>-name }_{ sy-datum }_{ sy-uzeit }_{ '.TXT' }|.

        open dataset lv_source_path for input in text mode encoding default.
        lv_subrc = sy-subrc.

        if lv_subrc <> 0.
          <fs_msg>-v2 = TEXT-019. "'ERRO: Não foi possível ler arquivo de origem para move-lo para processado'(019).
          modify ct_msg from <fs_msg>.
          return.
        endif.
        clear lt_file_content.
        do.
          read dataset lv_source_path into lv_line.
          if sy-subrc <> 0.
            exit.
          endif.
          append lv_line to lt_file_content.
        enddo.
        close dataset lv_source_path.

        open dataset lv_target_path for output in text mode encoding default.
        lv_subrc = sy-subrc.

        if lv_subrc <> 0.
          <fs_msg>-v2 = |{ TEXT-020  } { lv_target_path }|. ""'ERRO: Não foi possível ler diretório de destino para move-lo para processado'(020)
          modify ct_msg from <fs_msg>.
          return.
        endif.

        loop at lt_file_content into lv_line.
          transfer lv_line to lv_target_path.
        endloop.
        close dataset lv_target_path.
        delete dataset lv_source_path.
        lv_subrc = sy-subrc.

        if lv_subrc = 0.
          <fs_msg>-v2 = TEXT-021. "'Arquivo movido com sucesso'(021).
          modify ct_msg from <fs_msg>.
        else.
          <fs_msg>-v2 = TEXT-022. "'ATENÇÃO: Arquivo copiado mas arquivo de origem não foi deletado'(022).
          modify ct_msg from <fs_msg>.
        endif.
      endif.
    endloop.

  endmethod.


  method process_single_file.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    clear_file_data( ).

    read_al11_file( iv_file_path = iv_file_path ).

    if gt_file_raw is initial.
      append value #(
        name     = iv_file_name
        id       = ' '
        number   = ' '
        type     = 'E'
        v1       = TEXT-014 "'Upload de arquivo com erro'(014)
      ) to ct_msg.
      return.
    else.

      if iv_file_name(6) = 'L300_H'.
        read_l300_h_file(
          exporting
            iv_file_path = iv_file_path
            iv_file_name = iv_file_name ).
      elseif iv_file_name(6) = 'L301_C'.
        read_l301_c_file(
          exporting
            iv_file_path = iv_file_path
            iv_file_name = iv_file_name ).
      elseif iv_file_name(6) = 'L301_H'.
        read_l301_h_file(
          exporting
            iv_file_path = iv_file_path
            iv_file_name = iv_file_name ).
      endif.

      append value #(
        name     = iv_file_name
        id       = ' '
        number   = ' '
        type     = 'S'
        v1       = TEXT-015 "'Upload de arquivo OK'(015)
      ) to ct_msg.

    endif.

  endmethod.


  METHOD READ_AL11_FILE.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    DATA: lv_line  TYPE string,
          lv_msg   TYPE string,
          lv_subrc TYPE sy-subrc.

    CLEAR gt_file_raw.

    OPEN DATASET iv_file_path FOR INPUT IN TEXT MODE ENCODING DEFAULT.
    lv_subrc = sy-subrc.

    IF lv_subrc <> 0.
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


  method read_l300_h_file.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    data: gs_l300_h type ty_l300_h.
    loop at gt_file_raw into gv_raw_line.
      split gv_raw_line at ';' into gs_l300_h-shnumber
                                    gs_l300_h-strttact.

      if gv_shnumber is not initial and gv_shnumber ne gs_l300_h-shnumber.
        return.
      endif.
      gs_l300_h-name = iv_file_name.
      append gs_l300_h to gv_l300_h.
    endloop.
  endmethod.


  method read_l301_c_file.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    data: gs_l301_c type ty_l301_c.

    loop at gt_file_raw into gv_raw_line.
      split gv_raw_line at ';' into gs_l301_c-shnumber
                                    gs_l301_c-com_number
                                    gs_l301_c-o2
                                    gs_l301_c-hydrocar
                                    gs_l301_c-temp.

      if gv_shnumber is not initial and gv_showsm ne gs_l301_c-shnumber.
        return.
      endif.

      gs_l301_c-name = iv_file_name.
      append gs_l301_c to gv_l301_c.
    endloop.
  endmethod.


  method read_l301_h_file.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    data: gs_l301_h type ty_l301_h.

    loop at gt_file_raw into gv_raw_line.
      split gv_raw_line at ';' into gs_l301_h-data-shnumber
                                    gs_l301_h-data-trkintwt
                                    gs_l301_h-data-trkfnlwt
                                    gs_l301_h-data-lineemty
                                    gs_l301_h-data-lineused
                                    gs_l301_h-data-qty2load
                                    gs_l301_h-data-sourstnk
                                    gs_l301_h-data-prodnumb
                                    gs_l301_h-data-line2use
                                    gs_l301_h-data-texaco3
                                    gs_l301_h-data-spillpro
                                    gs_l301_h-data-gnrcon
                                    gs_l301_h-data-coloryn
                                    gs_l301_h-data-trkpos
                                    gs_l301_h-data-drainins
                                    gs_l301_h-data-tankins
                                    gs_l301_h-data-flushamt
                                    gs_l301_h-data-fabs_yrn
                                    gs_l301_h-data-trkvlvbf
                                    gs_l301_h-data-trkvlvaf
                                    gs_l301_h-data-trkgdryn
                                    gs_l301_h-data-starttme
                                    gs_l301_h-data-endtime
                                    gs_l301_h-data-opsname
                                    gs_l301_h-data-sealqty.


      if gv_shnumber is not initial and gv_showsm ne gs_l301_h-data-shnumber.
        return.
      endif.

      gs_l301_h-name = iv_file_name.
      append gs_l301_h to gv_l301_h.
    endloop.
  endmethod.


  method update_historico.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    data: lt_ISTMOVLIN type zts2m_histmovlin.
    field-symbols: <fs_histmovlin> type zts2m_histmovlin.
    data: lo_status_granel type ref to zclq2c_status_granel.
    loop at gv_l300_h assigning field-symbol(<fs_l300_h>).

* set status do transporte retorno de carga na tabela de historico
      lo_status_granel = new zclq2c_status_granel( iv_shnumber = <fs_l300_h>-shnumber ).
      lo_status_granel->set_status_moni_proc( exporting iv_retorno_arq_pcs = <fs_l300_h>-ret_process ).
    endloop.

  endmethod.


  method update_retorno.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
    data: iv_file_l300_h type string,
          iv_file_l301_c type string,
          iv_file_l301_h type string.

    data: is_pcs_det type ztq2c_pcs_det.

    loop at gv_l300_h assigning field-symbol(<fs_l300_h>) where Shnumber_nofound = abap_false.
      loop at gv_l301_c assigning field-symbol(<fs_l301_c>) where shnumber = <fs_l300_h>-shnumber.
        read table gv_l301_h assigning field-symbol(<fs_l301_h>) with key data-shnumber = <fs_l301_c>-shnumber.
        if sy-subrc = 0.
*         update ...

          loop at gt_pcs_det assigning field-symbol(<fs_pcs_det>) where shnumber = <fs_l300_h>-shnumber and
                                                                        com_number = <fs_l301_c>-com_number.
            data(vl_tabix) = sy-tabix.
            if <fs_l300_h>-status <> gv_status and <fs_l300_h>-upd_already = abap_false.
              move-corresponding <fs_l301_c> to <fs_pcs_det>.
              move-corresponding <fs_l301_h>-data to <fs_pcs_det>.
*              <fs_pcs_det>-ntgew = <fs_pcs_det>-btgew.
*              <fs_pcs_det>-itgew = <fs_pcs_det>-btgew.
*              <fs_pcs_det>-volume = <fs_pcs_det>-lfimg * <fs_pcs_det>-fator.
              modify gt_pcs_det from <fs_pcs_det> index vl_tabix.
            endif.
          endloop.
          if sy-subrc <> 0.
            <fs_l300_h>-Shnumber_nofound = abap_true.
            modify gv_l300_h from <fs_l300_h>.
*            clear is_pcs_det.
*            move-corresponding <fs_l301_c> to is_pcs_det.
*            move-corresponding <fs_l301_h> to is_pcs_det.
**            is_pcs_det-ntgew = is_pcs_det-btgew.
**            is_pcs_det-itgew = is_pcs_det-btgew.
**            is_pcs_det-volume = is_pcs_det-lfimg * is_pcs_det-fator.
*            modify gt_pcs_det from is_pcs_det.
          endif.
        endif.
      endloop.
    endloop.
    if gt_pcs_det is not initial.
      update ztq2c_pcs_det from table @gt_pcs_det.
      if sy-subrc eq 0.
        call function 'BAPI_TRANSACTION_COMMIT'
          exporting
            wait = abap_true.
       endif.
    endif.
  endmethod.


  method valida_arquivos.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*

* Verifica se todos os arquivos tem equivalencia l300_h, l301_c e l301_h
    loop at gv_l300_h assigning field-symbol(<fs_l300_h>).
      <fs_l300_h>-l300_h = abap_true.
      modify gv_l300_h from <fs_l300_h>.

      loop at gv_l301_c assigning field-symbol(<fs_l301_c>) where shnumber = <fs_l300_h>-shnumber.
        <fs_l300_h>-l301_c = abap_true.
        modify gv_l300_h from <fs_l300_h>.

        <fs_l301_c>-l300_h = abap_true.
        <fs_l301_c>-l301_c = abap_true.
        modify gv_l301_c from <fs_l301_c>.

        loop at gv_l301_h assigning field-symbol(<fs_l301_h>) where data-shnumber = <fs_l301_c>-shnumber.
          <fs_l300_h>-l301_h = abap_true.
          modify gv_l300_h from <fs_l300_h>.

          <fs_l301_c>-l301_h = abap_true.
          modify gv_l301_c from <fs_l301_c>.

          <fs_l301_h>-l300_h = abap_true.
          <fs_l301_h>-l301_c = abap_true.
          <fs_l301_h>-l301_h = abap_true.
          modify gv_l301_h from <fs_l301_h>.
        endloop.
      endloop.
    endloop.



  endmethod.


  method update_log.
*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*

    data: ls_retigratlog type ZTBQ2C_RETGRALOG.
    data: ls_files_log type ztca_files_log.

    loop at ct_msg assigning field-symbol(<fs_msg>).
      if <fs_msg>-name is not initial.
*        ls_medintlog-tmstmp   = iv_timestamp.
        ls_retigratlog-intid    = <fs_msg>-name(6).
        ls_retigratlog-intty    = 'I'.          "Inbound
        ls_retigratlog-intst    = '2'.
        ls_retigratlog-msgty    = <fs_msg>-type.
        ls_retigratlog-mensagem = |{ <fs_msg>-v1 }{ <fs_msg>-v2 }| .

        modify ZTBQ2C_RETGRALOG from ls_retigratlog.
      endif.
    endloop.

*    ls_files_log-client      = sy-mandt.
*    ls_files_log-id_int      = 'RET'.          "Retorno Granel
*    ls_files_log-int_type    = '1'.            "Inbound
*    ls_files_log-file_name   = <fs_msg>-name.
*    ls_files_log-file_status = <fs_msg>-type.
*
*    GET TIME STAMP FIELD ls_files_log-last_changed_at.
*
*    MODIFY ztca_files_log FROM ls_files_log.
*
*    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*      EXPORTING
*        wait = abap_true.
*    endif.
*      loop at ct_msg assigning field-symbol(<fs_msg>).
*        write: /5  <fs_msg>-name,
*                30 <fs_msg>-shnumber,
*                45 <fs_msg>-type,
*                55 <fs_msg>-v1,
*                100 <fs_msg>-v2.
*      endloop.

  endmethod.
ENDCLASS.
