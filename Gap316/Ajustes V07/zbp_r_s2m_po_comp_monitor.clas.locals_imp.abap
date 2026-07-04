CLASS lhc_zr_s2m_materiais_compative DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zr_s2m_materiais_compativeis RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ zr_s2m_materiais_compativeis RESULT result.

    METHODS rba_componente FOR READ
      IMPORTING keys_rba FOR READ zr_s2m_materiais_compativeis\_componente FULL result_requested RESULT result LINK association_links.

    METHODS remarcar FOR MODIFY IMPORTING keys FOR ACTION zr_s2m_materiais_compativeis~remarcar.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zr_s2m_materiais_compativeis.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zr_s2m_materiais_compativeis.



ENDCLASS.

CLASS lhc_zr_s2m_materiais_compative IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.

    SELECT * FROM zr_s2m_materiais_compativeis "#EC CI_ALL_FIELDS_NEEDED
              FOR ALL ENTRIES IN @keys
              WHERE reservationitem = @keys-reservationitem
              AND reservation = @keys-reservation
              AND reservationrecordtype = @keys-reservationrecordtype
              AND material = @keys-material
              AND centro = @keys-centro
              AND billofoperationstype = @keys-billofoperationstype
              AND grupo = @keys-grupo
              AND billofoperationsvariant = @keys-billofoperationsvariant
              AND bootomaterialinternalid = @keys-bootomaterialinternalid
              AND boomatlinternalversioncounter = @keys-boomatlinternalversioncounter
              AND deposito = @keys-deposito
              AND charg = @keys-charg
              INTO CORRESPONDING FIELDS OF TABLE @result.

  ENDMETHOD.

  METHOD rba_componente.
  ENDMETHOD.

  METHOD remarcar.

    DATA(lo_remarcacao_parallel) = NEW zcls2m_remarcacao_parallel(  ).

    DATA: lt_resbkeys TYPE coxt_t_resbdel.
    " V7 - RTIEZZI - DEF174 - INICIO - Tipagem explicita para evitar erros de parser/ativacao em cascata
    TYPES: BEGIN OF ty_mchb_lote,
             plant           TYPE werks_d,
             storagelocation TYPE lgort_d,
             batch           TYPE charg_d,
             clabs           TYPE mchb-clabs,
           END OF ty_mchb_lote.

    DATA: ls_mchb     TYPE ty_mchb_lote,
          lt_bapi_ret TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.
    " V7 - RTIEZZI - DEF174 - FIM - Tipagem explicita para evitar erros de parser/ativacao em cascata

" V6 - RTIEZZI - DEF174 - Permite apenas um lote por remarcacao
    IF lines( keys ) > 1.
      APPEND VALUE #( %key = keys[ 1 ]-%key ) TO failed-zr_s2m_materiais_compativeis.
      APPEND VALUE #( %key = keys[ 1 ]-%key
                      %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                    text = TEXT-002 ) )
        TO reported-zr_s2m_materiais_compativeis.
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>). ##EML_IN_LOOP_OK

      READ ENTITIES OF zr_s2m_po_comp_monitor IN LOCAL MODE ##EML_IN_LOOP_OK
      ENTITY zr_s2m_materiais_compativeis
      ALL FIELDS
  WITH VALUE #( ( %key = <fs_key>-%key
                  ) )
      RESULT DATA(lt_material_comp).

      " V6 - RTIEZZI - DEF174 - Sem material elegivel: nao existe grupo de receita valido
      IF lt_material_comp IS INITIAL.
        APPEND VALUE #( %key = <fs_key>-%key ) TO failed-zr_s2m_materiais_compativeis.
        APPEND VALUE #( %key = <fs_key>-%key
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text = TEXT-005 ) )
          TO reported-zr_s2m_materiais_compativeis.
        RETURN.
      ENDIF.

      DATA(ls_material_comp) = lt_material_comp[ 1 ].

      AT FIRST.

        DATA(lv_call_delete) = 'X'.

        READ ENTITIES OF zr_s2m_po_comp_monitor IN LOCAL MODE
    ENTITY zr_s2m_po_comp_monitor
    ALL FIELDS
WITH VALUE #( (
                %key-reservation = <fs_key>-reservation
                %key-reservationitem = <fs_key>-reservationitem
                 %key-reservationrecordtype = <fs_key>-reservationrecordtype
                ) )
    RESULT DATA(lt_po_comp_monitor).

        " V7 - RTIEZZI - DEF174 - INICIO - Evita dump quando contexto da ordem nao existe mais
        IF lt_po_comp_monitor IS INITIAL.
          APPEND VALUE #( %key = <fs_key>-%key ) TO failed-zr_s2m_materiais_compativeis.
          RETURN.
        ENDIF.
        " V7 - RTIEZZI - DEF174 - FIM - Evita dump quando contexto da ordem nao existe mais

        DATA(ls_po_comp_monitor) = lt_po_comp_monitor[ 1 ].

*        SELECT SINGLE lgort, charg          "#EC CI_NOORDER "#EC WARNOK
*        FROM resb
*        WHERE rsnum = @ls_po_comp_monitor-reservation
*        AND rspos = @ls_po_comp_monitor-reservationitem
*        AND matnr =  @ls_po_comp_monitor-material
*        INTO @DATA(ls_resb).

        SELECT SINGLE StorageLocation, Batch          "#EC CI_NOORDER "#EC WARNOK
          FROM I_ReservationDocumentItem
         WHERE Reservation     EQ @ls_po_comp_monitor-reservation
           AND ReservationItem EQ @ls_po_comp_monitor-reservationitem
           AND Product         EQ @ls_po_comp_monitor-material
          INTO @DATA(ls_resb).

        SELECT SINGLE manufacturingordersequence  FROM zr_s2m_ordem     "#EC CI_ALL_FIELDS_NEEDED
        WHERE reservation = @ls_po_comp_monitor-reservation
        AND reservationitem = @ls_po_comp_monitor-reservationitem
        AND reservationrecordtype = @ls_po_comp_monitor-reservationrecordtype
        INTO @DATA(lv_manufacturingordersequence).

        lt_resbkeys = VALUE #(
   ( rsnum = ls_po_comp_monitor-reservation
     rspos = ls_po_comp_monitor-reservationitem )
 ).

      ENDAT.


      IF lt_po_comp_monitor IS NOT INITIAL.

        " ATC - Change MCHB -> wrapper ZI_S2M_WRP_MCHB_LOTE
        SELECT SINGLE FROM zi_s2m_wrp_mchb_lote
          FIELDS Plant, StorageLocation, Batch, Clabs
          WHERE Material = @ls_material_comp-material
            AND Plant = @ls_material_comp-centro
            AND Batch = @ls_material_comp-charg
          INTO @ls_mchb.

        " V7 - RTIEZZI - DEF174 - INICIO - Quantidade de remarcacao nao pode seguir zerada
        DATA(lv_qtd_remarcacao) = COND nsdm_stock_qty_l1(
          WHEN ls_material_comp-quantidade IS INITIAL
            THEN ls_po_comp_monitor-requiredquantity
          ELSE ls_material_comp-quantidade ).
        " V7 - RTIEZZI - DEF174 - FIM - Quantidade de remarcacao nao pode seguir zerada

        " V7 - RTIEZZI - DEF174 - INICIO - Valida estoque em tempo real no wrapper MCHB
        IF ls_mchb IS INITIAL.
          APPEND VALUE #( %key = ls_material_comp-%key ) TO failed-zr_s2m_materiais_compativeis.
          RETURN.
        ENDIF.

        IF ls_mchb-Clabs < lv_qtd_remarcacao.
          APPEND VALUE #( %key = ls_material_comp-%key ) TO failed-zr_s2m_materiais_compativeis.
          APPEND VALUE #( %key = ls_material_comp-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text = TEXT-003 ) )
            TO reported-zr_s2m_materiais_compativeis.
          RETURN.
        ENDIF.
        " V7 - RTIEZZI - DEF174 - FIM - Valida estoque em tempo real no wrapper MCHB

        lo_remarcacao_parallel->executar_bapi( EXPORTING
           iv_order_key = ls_po_comp_monitor-manufacturingorder
           iv_material = lt_material_comp[ 1 ]-material
           is_requ_quan = VALUE coxt_s_quantity( quantity = lv_qtd_remarcacao )
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
            et_bapiret2 =  lt_bapi_ret ).

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
"         V6 - RTIEZZI - DEF174 - Substitui mensagem tecnica por mensagem funcional de sucesso
          APPEND VALUE #( %key = ls_material_comp-%key
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                          text = TEXT-004 ) )
            TO reported-zr_s2m_materiais_compativeis.
        ENDIF.

        FREE: lt_bapi_ret.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    DATA lv_soma_quantidade TYPE nsdm_stock_qty_l1 VALUE 0.

    READ ENTITIES OF zr_s2m_po_comp_monitor IN LOCAL MODE
      ENTITY zr_s2m_materiais_compativeis
      FIELDS ( quantidade )
           WITH CORRESPONDING #( entities )
      RESULT DATA(lt_material_comp).

    " V7 - RTIEZZI - DEF174 - INICIO - Evita dump quando entidade nao e encontrada no update
    IF lt_material_comp IS INITIAL.
      RETURN.
    ENDIF.
    " V7 - RTIEZZI - DEF174 - FIM - Evita dump quando entidade nao e encontrada no update

    DATA(ls_material_comp) = lt_material_comp[ 1 ].

    READ ENTITIES OF zr_s2m_po_comp_monitor IN LOCAL MODE
    ENTITY zr_s2m_po_comp_monitor
    FIELDS ( requiredquantity )
    WITH VALUE #( (
                %key-reservation = ls_material_comp-reservation
                %key-reservationitem = ls_material_comp-reservationitem
                 %key-reservationrecordtype = ls_material_comp-reservationrecordtype
                ) )
    RESULT DATA(lt_po_comp_monitor).

    " V7 - RTIEZZI - DEF174 - INICIO - Evita dump quando monitor nao e encontrado no update
    IF lt_po_comp_monitor IS INITIAL.
      RETURN.
    ENDIF.
    " V7 - RTIEZZI - DEF174 - FIM - Evita dump quando monitor nao e encontrado no update

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>).
      lv_soma_quantidade += <fs_entity>-quantidade.

      IF lt_po_comp_monitor[ 1 ]-requiredquantity < lv_soma_quantidade.

        APPEND VALUE #( %key =  ls_material_comp-%key ) TO failed-zr_s2m_materiais_compativeis.

        APPEND VALUE #( %tky = ls_material_comp-%tky
         %msg = new_message_with_text( severity =
                                        if_abap_behv_message=>severity-error
                                        text = TEXT-001 && space && ' ' && lt_po_comp_monitor[ 1 ]-requiredquantity "'Quantidade ultrapassa quantidade da ordem '
                                        )

         ) TO reported-zr_s2m_materiais_compativeis.

        RETURN.
      ENDIF.

    ENDLOOP.

    DATA ls_ztbs2m_mat_compa TYPE ztbs2m_mat_compa.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_key>).

      ls_ztbs2m_mat_compa = CORRESPONDING #( <fs_key> ).

      UPDATE ztbs2m_mat_compa SET quantidade = @<fs_key>-quantidade WHERE reservation = @<fs_key>-reservation
      AND reservation_item = @<fs_key>-reservationitem
      AND reservation_record_type = @<fs_key>-reservationrecordtype
      AND material = @<fs_key>-material
      AND centro = @<fs_key>-centro
      AND billofoperationstype = @<fs_key>-billofoperationstype
      AND grupo = @<fs_key>-grupo
      AND billofoperationsvariant = @<fs_key>-billofoperationsvariant
      AND bootomaterialinternalid = @<fs_key>-bootomaterialinternalid
      AND boomatlinternalversioncounter = @<fs_key>-boomatlinternalversioncounter
      AND deposito = @<fs_key>-deposito
      AND charg = @<fs_key>-charg
      .

    ENDLOOP.


  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.


ENDCLASS.

CLASS lhc_zr_s2m_po_comp_monitor DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zr_s2m_po_comp_monitor RESULT result.


    METHODS read FOR READ
      IMPORTING keys FOR READ zr_s2m_po_comp_monitor RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zr_s2m_po_comp_monitor.
    METHODS rba_materiais FOR READ
      IMPORTING keys_rba FOR READ zr_s2m_po_comp_monitor\_materiais FULL result_requested RESULT result LINK association_links.
    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE zr_s2m_po_comp_monitor.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zr_s2m_po_comp_monitor.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zr_s2m_po_comp_monitor.

    METHODS cba_materiais FOR MODIFY
      IMPORTING entities_cba FOR CREATE zr_s2m_po_comp_monitor\_materiais.

ENDCLASS.

CLASS lhc_zr_s2m_po_comp_monitor IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.

    SELECT * FROM zr_s2m_po_comp_monitor      "#EC CI_ALL_FIELDS_NEEDED
                FOR ALL ENTRIES IN @keys
                WHERE reservation = @keys-reservation
                AND reservationitem = @keys-reservationitem
                AND reservationrecordtype = @keys-reservationrecordtype
                INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_materiais.
  ENDMETHOD.

  METHOD create.
  ENDMETHOD.

  METHOD update.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_key>).

    ENDLOOP.

  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD cba_materiais.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zr_s2m_po_comp_monitor DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zr_s2m_po_comp_monitor IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
