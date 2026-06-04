CLASS zcls2m_remarcacao_parallel DEFINITION
  PUBLIC
  INHERITING FROM cl_abap_parallel
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS executar_bapi
      IMPORTING
        !iv_order_key         TYPE coxt_ord_key
        !iv_material          TYPE matnr
        !is_requ_quan         TYPE coxt_s_quantity
        !iv_operation         TYPE afvc-aplzl
        !iv_sequence          TYPE afvc-plnfl
        !is_storage_location  TYPE coxt_s_storage_location
        !is_storage_locationx TYPE coxt_s_storage_locationx
        !iv_batch             TYPE coxt_batch
        !iv_batchx            TYPE coxt_batchx
        !iv_postp             TYPE resb-postp
        !iv_posno             TYPE cif_r3res-positionno
        !it_resbkeys          TYPE coxt_t_resbdel
        !iv_call_delete       TYPE char1
      EXPORTING
        !et_bapiret2          TYPE ty_t_bapiret2 .

    METHODS executar_commmit
      EXPORTING
        !es_return TYPE bapiret2 .

    METHODS do
        REDEFINITION .

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES: BEGIN OF ty_container,
             action               TYPE char10,
             is_order_key         TYPE coxt_ord_key,
             material             TYPE matnr,
             requ_quan            TYPE coxt_s_quantity,
             operation            TYPE afvc-aplzl,
             sequence             TYPE afvc-plnfl,
             storage_location     TYPE coxt_s_storage_location,
             is_storage_locationx TYPE coxt_s_storage_locationx,
             iv_batch             TYPE coxt_batch,
             iv_batchx            TYPE coxt_batchx,
             iv_postp             TYPE resb-postp,
             iv_posno             TYPE cif_r3res-positionno,
             it_resbkeys          TYPE coxt_t_resbdel,
             iv_call_delete       TYPE char1,
           END OF ty_container ,

           BEGIN OF check_result,
             error_occurred TYPE abap_bool,
             messages       TYPE coxt_t_bapireturn,
           END OF check_result .

    TYPES: BEGIN OF ty_resb_bt.
             INCLUDE TYPE resbb.
    TYPES:   indold TYPE syst_tabix.
    TYPES: no_req_upd TYPE syst_datar.
    TYPES: END OF ty_resb_bt.

    TYPES tt_resb_bt TYPE TABLE OF ty_resb_bt.

    DATA lv_numc              TYPE numc4 VALUE 0.
    DATA: ls_container TYPE ty_container.
    DATA: ls_bapiret2  TYPE bapiret2.

ENDCLASS.



CLASS ZCLS2M_REMARCACAO_PARALLEL IMPLEMENTATION.


  METHOD executar_bapi.

    ls_container-action = 'ACTION_1'.
    ls_container-is_order_key  = iv_order_key.
    ls_container-material  = iv_material.
    ls_container-requ_quan  = is_requ_quan.
    ls_container-operation  = iv_operation.
    ls_container-sequence  = iv_sequence.
    ls_container-storage_location  = is_storage_location.
    ls_container-is_storage_locationx  = CORRESPONDING #( is_storage_locationx ) .
    ls_container-iv_batch  = iv_batch.
    ls_container-iv_batchx  = iv_batchx.
    ls_container-iv_postp  = iv_postp.
    ls_container-iv_posno  = iv_posno.
    ls_container-it_resbkeys  = it_resbkeys.
    ls_container-iv_call_delete  = iv_call_delete.

    DATA: lt_parallel_task_in     TYPE cl_abap_parallel=>t_in_tab,
          lv_parallel_task_buffer TYPE xstring.

    EXPORT buffer_task = ls_container TO DATA BUFFER lv_parallel_task_buffer.

    INSERT lv_parallel_task_buffer INTO TABLE lt_parallel_task_in.

    me->run( EXPORTING p_in_tab  = lt_parallel_task_in
             IMPORTING p_out_tab = DATA(lt_output) ).

    LOOP AT lt_output ASSIGNING FIELD-SYMBOL(<fs_output>).
      IMPORT buffer_task = ls_bapiret2 FROM DATA BUFFER <fs_output>-result.
      APPEND ls_bapiret2 TO et_bapiret2.
    ENDLOOP.
  ENDMETHOD.


  METHOD do.
    DATA: ls_container TYPE ty_container,
          ls_output    TYPE bapiret2.

    DATA lt_result TYPE check_result.
    DATA: ls_return TYPE coxt_bapireturn.
    DATA: ls_messages_fuba TYPE bapiret2.
    DATA lv_error_occurred TYPE c.
    DATA: ls_resbd_created TYPE resbd.
    DATA: lt_resbb TYPE TABLE OF resbb .

    DATA lv_aufnr TYPE aufk-aufnr.
    DATA: lt_ord_key_map TYPE TABLE OF caufvdn.
    DATA lv_tabix TYPE sy-tabix.

    FIELD-SYMBOLS: <ft_resb_bt> TYPE tt_resb_bt,

                   <fs_resb_bt> TYPE ty_resb_bt.

    IMPORT buffer_task = ls_container FROM DATA BUFFER p_in.

    IF ls_container IS NOT INITIAL.


      CASE ls_container-action.
        WHEN 'ACTION_1'.

          CALL FUNCTION 'CO_XT_COMPONENT_ADD'
            EXPORTING
              is_order_key         = ls_container-is_order_key
              i_material           = ls_container-material
              is_requ_quan         = ls_container-requ_quan
              i_operation          = ls_container-operation
              i_sequence           = ls_container-sequence
              is_storage_location  = ls_container-storage_location
              is_storage_locationx = ls_container-is_storage_locationx
              i_batch              = ls_container-iv_batch
              i_batchx             = ls_container-iv_batchx
              i_postp              = ls_container-iv_postp
              i_posno              = ls_container-iv_posno
            IMPORTING
              es_bapireturn        = ls_return
              e_error_occurred     = lv_error_occurred
              es_resbd_created     = ls_resbd_created
            TABLES
              resbt_exp            = lt_resbb.

          IF sy-subrc EQ 0 AND lv_error_occurred IS INITIAL.

            ASSIGN ('(SAPLCOBC)RESB_BT[]') TO <ft_resb_bt>.

            IF <ft_resb_bt> IS ASSIGNED.
              SORT <ft_resb_bt> BY posnr DESCENDING.
              lv_numc = <ft_resb_bt>[ 1 ]-posnr + 10.
            ENDIF.

            LOOP AT <ft_resb_bt> ASSIGNING <fs_resb_bt> WHERE posnr IS INITIAL.
              <fs_resb_bt>-posnr = lv_numc.
              CLEAR lv_numc.
            ENDLOOP.
          ELSEIF sy-subrc <> 0 OR lv_error_occurred IS NOT INITIAL.
            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            ls_output-message_v1 = sy-msgv1.
            ls_output-message_v2 = sy-msgv2.
            ls_output-message_v3 = sy-msgv3.

            IF ls_output IS INITIAL.
              ls_output-message = TEXT-002."Erro ao executar BAPI
            ENDIF.
            ls_output-id = sy-msgid.
            ls_output-log_msg_no = sy-msgno.
            ls_output-log_no = sy-msgno.

            ls_output-type    = 'E'.
          ENDIF.

          IF ls_container-iv_call_delete EQ 'X'.

            DATA lt_coxt_t_bapireturn TYPE coxt_t_bapireturn.

            CALL FUNCTION 'CO_XT_COMPONENTS_DELETE'
              EXPORTING
                it_resbkeys_to_delete = ls_container-it_resbkeys
              IMPORTING
                e_error_occurred      = lv_error_occurred
              TABLES
                ct_bapireturn         = lt_coxt_t_bapireturn
              EXCEPTIONS
                delete_failed         = 1
                OTHERS                = 2.

          ENDIF.

          IF lv_error_occurred IS INITIAL AND sy-subrc IS INITIAL.

            CALL FUNCTION 'CO_ZV_ORDER_POST'
              EXPORTING
                commit_flag    = space
                ext_flg        = 'X'
                trans_typ      = 'V'
                no_dialog      = 'X'
              IMPORTING
                first_aufnr    = lv_aufnr
              TABLES
                caufvd_num_exp = lt_ord_key_map
              EXCEPTIONS
                no_change      = 01
                update_reject  = 02
                error_message  = 03.

            IF sy-subrc EQ 0.

              COMMIT WORK AND WAIT.

              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
                IMPORTING
                  return = ls_messages_fuba.

              ls_output-type    = 'S'.
              ls_output-message_v1 = TEXT-001."BAPI executada com sucesso
              ls_output-message = TEXT-001."BAPI executada com sucesso


            ELSE.
              CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
              ls_output-message_v1 = sy-msgv1.
              ls_output-message_v2 = sy-msgv2.
              ls_output-message_v3 = sy-msgv3.

              IF ls_output IS INITIAL.
                ls_output-message = TEXT-002."Erro ao executar BAPI
              ENDIF.
              ls_output-id = sy-msgid.
              ls_output-log_msg_no = sy-msgno.
              ls_output-log_no = sy-msgno.

              ls_output-type    = 'E'.
            ENDIF.

          ELSE.

            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            ls_output-message_v1 = sy-msgv1.
            ls_output-message_v2 = sy-msgv2.
            ls_output-message_v3 = sy-msgv3.

            IF ls_return IS NOT INITIAL.
              ls_output = ls_return.
            ELSE.

              ls_output-message_v1 = sy-msgv1.
              ls_output-message_v2 = sy-msgv2.
              ls_output-message_v3 = sy-msgv3.

              IF ls_output IS INITIAL.
                ls_output-message = TEXT-002.
              ENDIF.
              ls_output-id = sy-msgid.
              ls_output-log_msg_no = sy-msgno.
              ls_output-log_no = sy-msgno.

            ENDIF.

            ls_output-type    = 'E'.

          ENDIF.
          EXPORT buffer_task = ls_output TO DATA BUFFER p_out.

        WHEN 'ACTION_2'.
          "---------------------------------------------------*
          "EXECUÇÃO DO ALGORITMO DO CENÁRIO 2 (BAPI, COMMIT...)
          "---------------------------------------------------*
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            IMPORTING
              return = ls_messages_fuba.

          ls_output-type    = 'S'.
          ls_output-message_v1 = TEXT-001.
          ls_output-message = ls_output-message_v1.

        WHEN 'ACTION_3'.
          "---------------------------------------------------*
          "EXECUÇÃO DO ALGORITMO DO CENÁRIO 3 (BAPI, COMMIT...)
          "---------------------------------------------------*
      ENDCASE.

    ENDIF.
  ENDMETHOD.


  METHOD executar_commmit.

    ls_container-action = 'ACTION_1'.

    DATA: lt_parallel_task_in     TYPE cl_abap_parallel=>t_in_tab,
          lv_parallel_task_buffer TYPE xstring.

    EXPORT buffer_task = ls_container TO DATA BUFFER lv_parallel_task_buffer.

    INSERT lv_parallel_task_buffer INTO TABLE lt_parallel_task_in.

    me->run( EXPORTING p_in_tab  = lt_parallel_task_in
             IMPORTING p_out_tab = DATA(lt_output) ).

    LOOP AT lt_output ASSIGNING FIELD-SYMBOL(<fs_output>).
      IMPORT buffer_task = ls_bapiret2 FROM DATA BUFFER <fs_output>-result.
      es_return = ls_bapiret2.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
