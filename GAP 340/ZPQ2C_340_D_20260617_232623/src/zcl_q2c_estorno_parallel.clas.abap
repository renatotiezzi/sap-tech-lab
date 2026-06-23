CLASS zcl_q2c_estorno_parallel DEFINITION
  PUBLIC
  INHERITING FROM cl_abap_parallel
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_input,
        mblnr TYPE mblnr,
        mjahr TYPE mjahr,
      END OF ty_input.

    TYPES:
      BEGIN OF ty_output,
        return      TYPE bapiret2,
        doc_estorno TYPE mblnr,
      END OF ty_output.

    METHODS execute_cancel
      IMPORTING is_input  TYPE ty_input
      EXPORTING es_output TYPE ty_output.

    METHODS do REDEFINITION.

ENDCLASS.



CLASS zcl_q2c_estorno_parallel IMPLEMENTATION.

  METHOD execute_cancel.
    DATA lt_in     TYPE cl_abap_parallel=>t_in_tab.
    DATA lv_buffer TYPE xstring.

    CLEAR es_output.

    EXPORT buffer_task = is_input TO DATA BUFFER lv_buffer.
    INSERT lv_buffer INTO TABLE lt_in.

    me->run( EXPORTING p_in_tab  = lt_in
             IMPORTING p_out_tab = DATA(lt_out) ).

    LOOP AT lt_out INTO DATA(ls_out).
      IMPORT buffer_task = es_output FROM DATA BUFFER ls_out-result.
      EXIT.
    ENDLOOP.

    IF es_output-return-type IS INITIAL.
      es_output-return-type = 'E'.
      es_output-return-message = 'Falha ao executar task paralela de estorno.'(001).
    ENDIF.
  ENDMETHOD.

  METHOD do.
    DATA ls_input  TYPE ty_input.
    DATA ls_output TYPE ty_output.
    DATA lt_return TYPE bapiret2_t.

    IMPORT buffer_task = ls_input FROM DATA BUFFER p_in.

    IF ls_input-mblnr IS INITIAL OR ls_input-mjahr IS INITIAL.
      ls_output-return-type = 'E'.
      ls_output-return-message = 'Documento/ano invalido para estorno.'(002).
      EXPORT buffer_task = ls_output TO DATA BUFFER p_out.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAPI_GOODSMVT_CANCEL_OIL'
      EXPORTING
        materialdocument = ls_input-mblnr
        matdocumentyear  = ls_input-mjahr
      TABLES
        return           = lt_return.

    LOOP AT lt_return INTO DATA(ls_ret_err) WHERE type CA 'EAX'.
      ls_output-return = ls_ret_err.
      EXIT.
    ENDLOOP.

    IF ls_output-return-type CA 'EAX'.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      READ TABLE lt_return INTO DATA(ls_ret_ok) WITH KEY type = 'S'.
      IF sy-subrc = 0.
        ls_output-return = ls_ret_ok.
        FIND FIRST OCCURRENCE OF REGEX '\\d{10}' IN ls_ret_ok-message SUBMATCHES ls_output-doc_estorno.
      ELSE.
        ls_output-return-type = 'S'.
        ls_output-return-message = 'Estorno executado com sucesso.'(003).
      ENDIF.
    ENDIF.

    EXPORT buffer_task = ls_output TO DATA BUFFER p_out.
  ENDMETHOD.

ENDCLASS.
