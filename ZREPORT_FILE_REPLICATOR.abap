*&---------------------------------------------------------------------*
*& Report  ZREPORT_FILE_REPLICATOR
*&
*& Purpose : Lists TXT files in a source directory, reads each file
*&           in binary mode and replicates it 4 times to a target
*&           directory using _COPY1 ... _COPY4 suffixes.
*&---------------------------------------------------------------------*
REPORT zreport_file_replicator.

*----------------------------------------------------------------------*
* TYPES
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_log,
    source_file TYPE string,
    target_file TYPE string,
    status      TYPE c LENGTH 1,   " S = Success, E = Error
    message     TYPE string,
  END OF ty_log.

*----------------------------------------------------------------------*
* CONSTANTS
*----------------------------------------------------------------------*
CONSTANTS:
  gc_copy_count     TYPE i VALUE 4,
  gc_path_sep       TYPE string VALUE '\',
  gc_file_filter    TYPE string VALUE '*.txt',
  gc_status_success TYPE c LENGTH 1 VALUE 'S',
  gc_status_error   TYPE c LENGTH 1 VALUE 'E'.

*----------------------------------------------------------------------*
* SELECTION SCREEN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-t01.
  PARAMETERS: p_srcdir TYPE string DEFAULT 'D:\BCDIncoming'  LOWER CASE,
              p_tgtdir TYPE string DEFAULT 'D:\BCDOutgoing'  LOWER CASE.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-t02.
  PARAMETERS: p_test TYPE abap_bool AS CHECKBOX DEFAULT abap_false.
SELECTION-SCREEN END OF BLOCK b02.

*----------------------------------------------------------------------*
* DATA
*----------------------------------------------------------------------*
DATA:
  lt_dir_list    TYPE STANDARD TABLE OF eps2fili,
  ls_dir_entry   TYPE eps2fili,
  lt_log         TYPE STANDARD TABLE OF ty_log,
  ls_log         TYPE ty_log,
  lv_xstring     TYPE xstring,
  lv_files_found TYPE i,
  lv_copies_ok   TYPE i,
  lv_copies_err  TYPE i.

*----------------------------------------------------------------------*
* SELECTION-SCREEN VALIDATION
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF p_srcdir IS INITIAL.
    MESSAGE 'Source directory must not be empty.' TYPE 'E'.
  ENDIF.
  IF p_tgtdir IS INITIAL.
    MESSAGE 'Target directory must not be empty.' TYPE 'E'.
  ENDIF.

*======================================================================*
* START-OF-SELECTION
*======================================================================*
START-OF-SELECTION.

  PERFORM f_print_header.
  PERFORM f_list_directory.

*======================================================================*
* END-OF-SELECTION
*======================================================================*
END-OF-SELECTION.

  PERFORM f_print_summary.


*----------------------------------------------------------------------*
*&      Form  F_PRINT_HEADER
*----------------------------------------------------------------------*
FORM f_print_header.

  WRITE: / 'ZREPORT_FILE_REPLICATOR - File Replication Report'.
  ULINE.
  WRITE: / 'Source directory :', p_srcdir.
  WRITE: / 'Target directory :', p_tgtdir.
  IF p_test = abap_true.
    WRITE: / 'Mode             : TEST RUN (no files will be written)'.
  ELSE.
    WRITE: / 'Mode             : PRODUCTIVE'.
  ENDIF.
  WRITE: / 'Copies per file  :', gc_copy_count.
  ULINE.
  SKIP.

ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_LIST_DIRECTORY
*----------------------------------------------------------------------*
FORM f_list_directory.

  DATA: lv_subrc TYPE sysubrc.

  WRITE: / 'Step 1 : Reading source directory...'.

  CALL FUNCTION 'EPS2_GET_DIRECTORY_LISTING'
    EXPORTING
      iv_dir_name            = p_srcdir
    TABLES
      dir_list               = lt_dir_list
    EXCEPTIONS
      invalid_eps_subdir     = 1
      sapgparam_failed       = 2
      build_directory_failed = 3
      no_authorization       = 4
      read_directory_failed  = 5
      too_many_read_errors   = 6
      empty_directory_list   = 7
      OTHERS                 = 8.

  lv_subrc = sy-subrc.

  IF lv_subrc <> 0.
    PERFORM f_write_error
      USING |EPS2_GET_DIRECTORY_LISTING failed for '{ p_srcdir }' | &
            |(sy-subrc = { lv_subrc })|.
    RETURN.
  ENDIF.

  IF lt_dir_list IS INITIAL.
    PERFORM f_write_warning USING |No entries found in '{ p_srcdir }'|.
    RETURN.
  ENDIF.

  WRITE: / 'Step 2 : Filtering TXT files and processing...'.
  SKIP.

  LOOP AT lt_dir_list INTO ls_dir_entry.

    CHECK ls_dir_entry-name IS NOT INITIAL.
    CHECK ls_dir_entry-name <> '.'.
    CHECK ls_dir_entry-name <> '..'.
    CHECK ls_dir_entry-name CP gc_file_filter.

    ADD 1 TO lv_files_found.

    PERFORM f_process_file USING ls_dir_entry-name.

  ENDLOOP.

  IF lv_files_found = 0.
    PERFORM f_write_warning
      USING |No TXT files found in '{ p_srcdir }'|.
  ENDIF.

ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_PROCESS_FILE
*----------------------------------------------------------------------*
FORM f_process_file USING iv_filename TYPE string.

  DATA:
    lv_source_path TYPE string,
    lv_copy_index  TYPE i,
    lv_target_name TYPE string,
    lv_target_path TYPE string.

  CONCATENATE p_srcdir gc_path_sep iv_filename
    INTO lv_source_path.

  WRITE: / |  Processing : { iv_filename }|.

  PERFORM f_read_file_binary
    USING    lv_source_path
    CHANGING lv_xstring.

  IF lv_xstring IS INITIAL.
    PERFORM f_write_warning
      USING |    => Skipped: file could not be read or is empty|.
    RETURN.
  ENDIF.

  WRITE: / |    Size     : { xstrlen( lv_xstring ) } byte(s)|.

  DO gc_copy_count TIMES.
    lv_copy_index = sy-index.

    PERFORM f_build_copy_name
      USING    iv_filename
               lv_copy_index
      CHANGING lv_target_name.

    CONCATENATE p_tgtdir gc_path_sep lv_target_name
      INTO lv_target_path.

    IF p_test = abap_true.
      PERFORM f_write_success
        USING |    [TEST] Would write { lv_target_name }|.

      ls_log-source_file = iv_filename.
      ls_log-target_file = lv_target_name.
      ls_log-status      = gc_status_success.
      ls_log-message     = 'Simulated (test mode)'.
      APPEND ls_log TO lt_log.
      ADD 1 TO lv_copies_ok.

    ELSE.
      PERFORM f_write_file_binary
        USING lv_source_path
              lv_target_path
              lv_target_name
              iv_filename
              lv_xstring.
    ENDIF.

  ENDDO.

  SKIP.

ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_READ_FILE_BINARY
*----------------------------------------------------------------------*
FORM f_read_file_binary
  USING    iv_path   TYPE string
  CHANGING cv_data   TYPE xstring.

  DATA:
    lv_raw_1024 TYPE x LENGTH 1024,
    lv_len      TYPE i,
    lv_subrc    TYPE sysubrc.

  CLEAR cv_data.

  OPEN DATASET iv_path FOR INPUT IN BINARY MODE.
  lv_subrc = sy-subrc.

  IF lv_subrc <> 0.
    PERFORM f_log_entry
      USING iv_path
            ''
            gc_status_error
            |Cannot open '{ iv_path }' for reading (sy-subrc = { lv_subrc })|.
    PERFORM f_write_error
      USING |    ERROR: Cannot open '{ iv_path }' (sy-subrc = { lv_subrc })|.
    RETURN.
  ENDIF.

  DO.
    CLEAR: lv_raw_1024, lv_len.

    READ DATASET iv_path INTO lv_raw_1024 ACTUAL LENGTH lv_len.

    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    IF lv_len > 0.
      cv_data = cv_data && lv_raw_1024(lv_len).
    ENDIF.
  ENDDO.

  CLOSE DATASET iv_path.

  IF cv_data IS INITIAL.
    PERFORM f_log_entry
      USING iv_path
            ''
            gc_status_error
            |File is empty: '{ iv_path }'|.
    PERFORM f_write_warning
      USING |    WARNING: File is empty: '{ iv_path }'|.
  ENDIF.

ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_WRITE_FILE_BINARY
*----------------------------------------------------------------------*
FORM f_write_file_binary
  USING iv_source_path TYPE string
        iv_target_path TYPE string
        iv_target_name TYPE string
        iv_source_name TYPE string
        iv_data        TYPE xstring.

  DATA:
    lv_subrc     TYPE sysubrc,
    lv_total_len TYPE i,
    lv_offset    TYPE i,
    lv_chunk_len TYPE i,
    lv_chunk_xs  TYPE xstring.

  CONSTANTS: lc_chunk_size TYPE i VALUE 1024.

  lv_total_len = xstrlen( iv_data ).

  OPEN DATASET iv_target_path FOR OUTPUT IN BINARY MODE.
  lv_subrc = sy-subrc.

  IF lv_subrc <> 0.
    PERFORM f_log_entry
      USING iv_source_name
            iv_target_name
            gc_status_error
            |Cannot open target '{ iv_target_path }' for writing | &
            |(sy-subrc = { lv_subrc })|.
    PERFORM f_write_error
      USING |    ERROR: Cannot write '{ iv_target_name }' | &
            |(sy-subrc = { lv_subrc })|.
    ADD 1 TO lv_copies_err.
    RETURN.
  ENDIF.

  lv_offset = 0.

  WHILE lv_offset < lv_total_len.

    lv_chunk_len = lv_total_len - lv_offset.
    IF lv_chunk_len > lc_chunk_size.
      lv_chunk_len = lc_chunk_size.
    ENDIF.

    lv_chunk_xs = iv_data+lv_offset(lv_chunk_len).
    TRANSFER lv_chunk_xs TO iv_target_path.

    lv_offset = lv_offset + lv_chunk_len.

  ENDWHILE.

  CLOSE DATASET iv_target_path.

  OPEN DATASET iv_target_path FOR INPUT IN BINARY MODE.
  lv_subrc = sy-subrc.
  IF lv_subrc = 0.
    CLOSE DATASET iv_target_path.
  ENDIF.

  IF lv_subrc = 0.
    PERFORM f_log_entry
      USING iv_source_name
            iv_target_name
            gc_status_success
            |OK - { lv_total_len } byte(s) written|.
    PERFORM f_write_success
      USING |    OK  => { iv_target_name } ({ lv_total_len } byte(s))|.
    ADD 1 TO lv_copies_ok.
  ELSE.
    PERFORM f_log_entry
      USING iv_source_name
            iv_target_name
            gc_status_error
            |Write appeared to succeed but target is not readable|.
    PERFORM f_write_error
      USING |    ERROR: Target '{ iv_target_name }' not readable after write|.
    ADD 1 TO lv_copies_err.
  ENDIF.

ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_BUILD_COPY_NAME
*&
*& Inserts _COPYn before the last dot.
*& Example: report.txt + 1  =>  report_COPY1.txt
*----------------------------------------------------------------------*
FORM f_build_copy_name
  USING    iv_original  TYPE string
           iv_index     TYPE i
  CHANGING cv_copy_name TYPE string.

  DATA:
    lv_dot_pos   TYPE i,
    lv_basename  TYPE string,
    lv_extension TYPE string,
    lv_len       TYPE i.

  lv_len = strlen( iv_original ).

  lv_dot_pos = 0.
  DO lv_len TIMES.
    DATA(lv_pos) = lv_len - sy-index.
    IF iv_original+lv_pos(1) = '.'.
      lv_dot_pos = lv_pos.
      EXIT.
    ENDIF.
  ENDDO.

  IF lv_dot_pos > 0.
    lv_basename  = iv_original(lv_dot_pos).
    lv_extension = iv_original+lv_dot_pos.
  ELSE.
    lv_basename  = iv_original.
    CLEAR lv_extension.
  ENDIF.

  cv_copy_name = |{ lv_basename }_COPY{ iv_index }{ lv_extension }|.

ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_LOG_ENTRY
*----------------------------------------------------------------------*
FORM f_log_entry
  USING iv_source  TYPE string
        iv_target  TYPE string
        iv_status  TYPE c
        iv_message TYPE string.

  DATA: ls_entry TYPE ty_log.

  ls_entry-source_file = iv_source.
  ls_entry-target_file = iv_target.
  ls_entry-status      = iv_status.
  ls_entry-message     = iv_message.

  APPEND ls_entry TO lt_log.

ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_WRITE_SUCCESS
*----------------------------------------------------------------------*
FORM f_write_success USING iv_text TYPE string.
  FORMAT COLOR COL_POSITIVE.
  WRITE: / iv_text.
  FORMAT COLOR OFF.
ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_WRITE_ERROR
*----------------------------------------------------------------------*
FORM f_write_error USING iv_text TYPE string.
  FORMAT COLOR COL_NEGATIVE.
  WRITE: / iv_text.
  FORMAT COLOR OFF.
ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_WRITE_WARNING
*----------------------------------------------------------------------*
FORM f_write_warning USING iv_text TYPE string.
  FORMAT COLOR COL_GROUP.
  WRITE: / iv_text.
  FORMAT COLOR OFF.
ENDFORM.


*----------------------------------------------------------------------*
*&      Form  F_PRINT_SUMMARY
*----------------------------------------------------------------------*
FORM f_print_summary.

  DATA: ls_entry     TYPE ty_log,
        lv_total_log TYPE i.

  lv_total_log = lines( lt_log ).

  SKIP.
  ULINE.
  WRITE: / 'SUMMARY'.
  ULINE.

  WRITE: / |  Source files found  : { lv_files_found }|.
  WRITE: / |  Copies written OK   : { lv_copies_ok }|.
  WRITE: / |  Copies with errors  : { lv_copies_err }|.
  WRITE: / |  Log entries total   : { lv_total_log }|.

  SKIP.

  IF lt_log IS NOT INITIAL.

    WRITE: /1  'St',
            4  'Source File',
            54 'Target File',
            104 'Message'.
    ULINE.

    LOOP AT lt_log INTO ls_entry.

      IF ls_entry-status = gc_status_success.
        FORMAT COLOR COL_POSITIVE.
        WRITE: /1  ls_entry-status,
                4  ls_entry-source_file(50),
               54  ls_entry-target_file(50),
               104 ls_entry-message(60).
        FORMAT COLOR OFF.
      ELSE.
        FORMAT COLOR COL_NEGATIVE.
        WRITE: /1  ls_entry-status,
                4  ls_entry-source_file(50),
               54  ls_entry-target_file(50),
               104 ls_entry-message(60).
        FORMAT COLOR OFF.
      ENDIF.

    ENDLOOP.

    ULINE.

  ENDIF.

  SKIP.
  IF lv_copies_err = 0 AND lv_copies_ok > 0.
    FORMAT COLOR COL_POSITIVE.
    WRITE: / 'Run completed successfully - all copies written.'.
    FORMAT COLOR OFF.
  ELSEIF lv_copies_ok = 0 AND lv_copies_err = 0.
    FORMAT COLOR COL_GROUP.
    WRITE: / 'Run completed - no files processed.'.
    FORMAT COLOR OFF.
  ELSE.
    FORMAT COLOR COL_NEGATIVE.
    WRITE: / |Run completed with { lv_copies_err } error(s). Check the log above.|.
    FORMAT COLOR OFF.
  ENDIF.

ENDFORM.
