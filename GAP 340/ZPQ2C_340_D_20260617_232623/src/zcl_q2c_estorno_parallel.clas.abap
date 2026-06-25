CLASS zcl_q2c_estorno_parallel DEFINITION
  PUBLIC
  INHERITING FROM cl_abap_parallel
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_input,
        action  TYPE char20,
        mblnr TYPE mblnr,
        mjahr TYPE mjahr,
        lote_qm TYPE qplos,
        ud_code TYPE zz1_8d05c26e3b4f-low,
      END OF ty_input.

    TYPES:
      BEGIN OF ty_output,
        return      TYPE bapiret2,
        doc_estorno TYPE mblnr,
      END OF ty_output.

    METHODS execute_cancel
      IMPORTING is_input  TYPE ty_input
      EXPORTING es_output TYPE ty_output.

    METHODS execute_qm_cancel
      IMPORTING iv_lote_qm TYPE qplos
      EXPORTING es_output  TYPE ty_output.

    METHODS execute_qm_ud
      IMPORTING iv_lote_qm TYPE qplos
                iv_ud_code TYPE zz1_8d05c26e3b4f-low
      EXPORTING es_output  TYPE ty_output.

    METHODS do REDEFINITION.

ENDCLASS.



CLASS zcl_q2c_estorno_parallel IMPLEMENTATION.

  METHOD execute_cancel.
    DATA lt_in     TYPE cl_abap_parallel=>t_in_tab.
    DATA lv_buffer TYPE xstring.

    CLEAR es_output.

    DATA(ls_input) = is_input.
    IF ls_input-action IS INITIAL.
      ls_input-action = 'GM_CANCEL'.
    ENDIF.

    EXPORT buffer_task = ls_input TO DATA BUFFER lv_buffer.
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

  METHOD execute_qm_cancel.
    DATA lt_in     TYPE cl_abap_parallel=>t_in_tab.
    DATA lv_buffer TYPE xstring.

    CLEAR es_output.

    DATA(ls_input) = VALUE ty_input( action = 'QM_CANCEL'
                                     lote_qm = iv_lote_qm ).

    EXPORT buffer_task = ls_input TO DATA BUFFER lv_buffer.
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

  METHOD execute_qm_ud.
    DATA lt_in     TYPE cl_abap_parallel=>t_in_tab.
    DATA lv_buffer TYPE xstring.

    CLEAR es_output.

    DATA(ls_input) = VALUE ty_input( action = 'QM_UD'
                                     lote_qm = iv_lote_qm
                                     ud_code = iv_ud_code ).

    EXPORT buffer_task = ls_input TO DATA BUFFER lv_buffer.
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

    CASE ls_input-action.
      WHEN 'GM_CANCEL'.
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

        LOOP AT lt_return INTO DATA(ls_ret_err_gm) WHERE type CA 'EAX'.
          ls_output-return = ls_ret_err_gm.
          EXIT.
        ENDLOOP.

        IF ls_output-return-type CA 'EAX'.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = abap_true.

          READ TABLE lt_return INTO DATA(ls_ret_ok_gm) WITH KEY type = 'S'.
          IF sy-subrc = 0.
            ls_output-return = ls_ret_ok_gm.
            FIND FIRST OCCURRENCE OF REGEX '\\d{10}' IN ls_ret_ok_gm-message SUBMATCHES ls_output-doc_estorno.
          ELSE.
            ls_output-return-type = 'S'.
            ls_output-return-message = 'Estorno executado com sucesso.'(003).
          ENDIF.
        ENDIF.

      WHEN 'QM_CANCEL'.
        IF ls_input-lote_qm IS INITIAL.
          ls_output-return-type = 'E'.
          ls_output-return-message = 'Lote QM invalido para estorno.'(004).
          EXPORT buffer_task = ls_output TO DATA BUFFER p_out.
          RETURN.
        ENDIF.

        ls_output-return-type = 'S'.
        ls_output-return-message = 'Cancelamento de lote QM nao necessario no novo modelo.'.

      WHEN 'QM_UD'.
        IF ls_input-lote_qm IS INITIAL OR ls_input-ud_code IS INITIAL.
          ls_output-return-type = 'E'.
          ls_output-return-message = 'Dados de UD invalidos para estorno QM.'(005).
          EXPORT buffer_task = ls_output TO DATA BUFFER p_out.
          RETURN.
        ENDIF.

        CALL FUNCTION 'BAPI_INSPLOT_USAGE_DECISION'
          EXPORTING
            inspectionlot = ls_input-lote_qm
            ud_code       = ls_input-ud_code
          TABLES
            return        = lt_return.

        LOOP AT lt_return INTO DATA(ls_ret_err_qm_ud) WHERE type CA 'EAX'.
          ls_output-return = ls_ret_err_qm_ud.
          EXIT.
        ENDLOOP.

        IF ls_output-return-type CA 'EAX'.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = abap_true.

          READ TABLE lt_return INTO DATA(ls_ret_ok_qm_ud) WITH KEY type = 'S'.
          IF sy-subrc = 0.
            ls_output-return = ls_ret_ok_qm_ud.
          ELSE.
            ls_output-return-type = 'S'.
            ls_output-return-message = 'Estorno executado com sucesso.'(003).
          ENDIF.
        ENDIF.

      WHEN OTHERS.
        ls_output-return-type = 'E'.
        ls_output-return-message = 'Acao paralela de estorno invalida.'(006).
    ENDCASE.

    EXPORT buffer_task = ls_output TO DATA BUFFER p_out.
  ENDMETHOD.

ENDCLASS.
