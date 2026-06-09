
      IF lt_po_comp_monitor IS NOT INITIAL.

        " ATC - Change MCHB -> wrapper ZI_S2M_WRP_MCHB_LOTE
        SELECT SINGLE Plant, StorageLocation, Batch
          FROM zi_s2m_wrp_mchb_lote
          WHERE Material = @ls_material_comp-material
            AND Plant = @ls_material_comp-centro
            AND Batch = @ls_material_comp-charg
          INTO @DATA(ls_mchb).



        lv_soma_quantidade += ls_material_comp-quantidade.

        lo_remarcacao_parallel->executar_bapi( EXPORTING
           iv_order_key = ls_po_comp_monitor-manufacturingorder
           iv_material = lt_material_comp[ 1 ]-material
           is_requ_quan = VALUE coxt_s_quantity( quantity = lt_material_comp[ 1 ]-quantidade )
           iv_operation = ls_po_comp_monitor-orderoperationinternalid
           iv_sequence = lv_manufacturingordersequence
           is_storage_location = VALUE coxt_s_storage_location( werks = ls_mchb-Plant lgort = ls_mchb-StorageLocation )
           is_storage_locationx = VALUE coxt_s_storage_locationx( werks = 'X' lgort = 'X' )
           iv_batch = ls_mchb-Batch
           iv_batchx = 'X'
           iv_postp = 'L'
           iv_posno = '10'
           it_resbkeys = lt_resbkeys
           iv_call_delete = lv_call_delete
        IMPORTING
            et_bapiret2 =  DATA(lt_bapi_ret) ).

        FREE: lv_call_delete.

        IF lt_bapi_ret IS NOT INITIAL AND line_exists( lt_bapi_ret[ type = 'E' ] ) .
          APPEND VALUE #( %key =  ls_material_comp-%key ) TO failed-zr_s2m_materiais_compativeis.
          APPEND VALUE #( %key = ls_material_comp-%key
                          %msg = new_message( id       = lt_bapi_ret[ 1 ]-id
                                              number   = lt_bapi_ret[ 1 ]-number
                                              v1       = lt_bapi_ret[ 1 ]-message_v1
                                              v2       = lt_bapi_ret[ 1 ]-message_v2
                                              v3       = lt_bapi_ret[ 1 ]-message_v3
                                              v4       = lt_bapi_ret[ 1 ]-message_v4
                                              severity = if_abap_behv_message=>severity-error
                                               ) ) TO reported-zr_s2m_materiais_compativeis.
          RETURN.

        ELSE.
          APPEND VALUE #( %key =  ls_material_comp-%key ) TO mapped-zr_s2m_materiais_compativeis.
          APPEND VALUE #( %key = ls_material_comp-%key
                            %msg = new_message( id       = '00'
                                                number   = 208
                                                v1       = lt_bapi_ret[ 1 ]-message_v1
                                                v2       = lt_bapi_ret[ 1 ]-message_v2
                                                v3       = lt_bapi_ret[ 1 ]-message_v3
                                                v4       = lt_bapi_ret[ 1 ]-message_v4
                                                severity = if_abap_behv_message=>severity-success
                                                 ) ) TO reported-zr_s2m_materiais_compativeis.
        ENDIF.

        FREE: lt_bapi_ret.

      ENDIF.

    ENDLOOP.

    IF lv_soma_quantidade < ls_po_comp_monitor-requiredquantity.

      lv_soma_quantidade = ls_po_comp_monitor-requiredquantity - lv_soma_quantidade.


      lo_remarcacao_parallel->executar_bapi( EXPORTING
         iv_order_key = ls_po_comp_monitor-manufacturingorder
         iv_material = ls_po_comp_monitor-material
         is_requ_quan = VALUE coxt_s_quantity( quantity = lv_soma_quantidade )
         iv_operation = ls_po_comp_monitor-orderoperationinternalid
         iv_sequence = lv_manufacturingordersequence
         is_storage_location = VALUE coxt_s_storage_location( werks = ls_mchb-Plant lgort = ls_resb-StorageLocation )
         is_storage_locationx = VALUE coxt_s_storage_locationx( werks = 'X' lgort = 'X' )
         iv_batch = ls_resb-Batch
         iv_batchx = 'X'
         iv_postp = 'L'
         iv_posno = '10'
         it_resbkeys = lt_resbkeys
         iv_call_delete = ''
      IMPORTING
          et_bapiret2 = lt_bapi_ret ).