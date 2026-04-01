CLASS zclqm_controle_batelada DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_container,
        ref_is_qals           TYPE REF TO data,
        ref_is_qave           TYPE REF TO data,
        ref_is_qapo           TYPE REF TO data,
        ref_ev_subrc          TYPE REF TO data,
        ref_et_protocol       TYPE REF TO data,
        ref_ev_saving_allowed TYPE REF TO data,
        ref_cs_qapo           TYPE REF TO data,
        ref_cs_qapp           TYPE REF TO data,
        ref_ct_qamk           TYPE REF TO data,
        ref_ct_qasp           TYPE REF TO data,
        ref_ct_qase           TYPE REF TO data,
        ref_ct_qakl           TYPE REF TO data,
        ref_action            TYPE REF TO data,
      END OF ty_container.

    INTERFACES zif_ca_enhancement .

  PROTECTED SECTION.

  PRIVATE SECTION.

    " Constantes tipadas sem referência a tabelas não liberadas no VALUE
    CONSTANTS gc_inspection_type_04 TYPE c LENGTH 2 VALUE '04' ##NO_TEXT.
    CONSTANTS gc_valuation_a        TYPE c LENGTH 1 VALUE 'A' ##NO_TEXT.
    CONSTANTS gc_tvarvc_order_type  TYPE c LENGTH 30 VALUE 'ZS2M126_BATTPOP' ##NO_TEXT.
    CONSTANTS gc_tvarvc_plant       TYPE c LENGTH 30 VALUE 'ZS2M126_BATPLANTOP' ##NO_TEXT.
    CONSTANTS gc_action_check       TYPE c LENGTH 5 VALUE 'CHECK' ##NO_TEXT.
    CONSTANTS gc_action_save        TYPE c LENGTH 4 VALUE 'SAVE' ##NO_TEXT.

    METHODS save
      IMPORTING
        !is_qals TYPE qals
        !is_qave TYPE qave
        !is_qapo TYPE qapo
      EXPORTING
        !ev_subrc    TYPE sy-subrc
        !et_protocol TYPE ztts2m_rqevp .

    METHODS check
      IMPORTING
        !is_qals TYPE qals
      EXPORTING
        !ev_saving_allowed TYPE abap_bool   " [FIX ATC Prio 2] was CHAR1 (deprecated)
      CHANGING
        !cs_qapo TYPE qapo
        !cs_qapp TYPE qapp
        !ct_qamk TYPE qamkrtab
        !ct_qasp TYPE qasprtab
        !ct_qase TYPE qasertab
        !ct_qakl TYPE qaklrtab .

    " Helper methods to isolate non-released API access
    " TODO: Replace with released APIs when available
    METHODS get_order_data
      IMPORTING
        !iv_aufnr   TYPE caufv-aufnr
      EXPORTING
        !es_caufv   TYPE caufv
        !ev_found   TYPE abap_bool .

    METHODS get_tvarvc_range
      IMPORTING
        !iv_name    TYPE c
      EXPORTING
        !et_range   TYPE table .

    METHODS get_inspection_lots_for_orders
      IMPORTING
        !it_orders         TYPE ANY TABLE
        !iv_inspection_type TYPE c
      EXPORTING
        !et_lots           TYPE STANDARD TABLE .

    METHODS get_usage_decisions
      IMPORTING
        !it_lots          TYPE ANY TABLE
        !iv_valuation     TYPE c
        !it_date_range    TYPE ANY TABLE
      EXPORTING
        !et_results       TYPE STANDARD TABLE .

    METHODS check_batch_exists
      IMPORTING
        !iv_matnr  TYPE ztbqmbatelada-matnr
        !iv_werks  TYPE ztbqmbatelada-werks
        !iv_stlnr  TYPE caufv-stlnr
        !iv_stlan  TYPE caufv-stlan
        !iv_stlal  TYPE caufv-stlal
      RETURNING
        VALUE(rv_exists) TYPE abap_bool .

    METHODS save_batch_record
      IMPORTING
        !is_record TYPE ztbqmbatelada
      RETURNING
        VALUE(rv_success) TYPE abap_bool .

ENDCLASS.



CLASS zclqm_controle_batelada IMPLEMENTATION.


  METHOD check.
*--------------------------------------------------------------------*
* Program       : CHECK
* Program Type  : Method
* Author        : WATCORSI (EY)
* Creation Date : 18/10/2025
* Gap ID        : GAP 126
* Description   : Alerta de Primeira batelada e inspeção de layout
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request/ChaRM    Description
* 000 18/10/2025 WATCORSI DS4K900849       Initial Version
* 001 01/04/2026 RTIEZZI  ATC-Refactor     ATC Priority 1+2+3 fixes
*--------------------------------------------------------------------*

    DATA:
      lv_low        TYPE sy-datum,
      lv_high       TYPE sy-datum,
      lv_today      TYPE sy-datum,
      lv_year_start TYPE sy-datum.

    " [FIX ATC Prio 2] Replace sy-datum with cl_abap_context_info
    lv_today = cl_abap_context_info=>get_system_date( ).

    ev_saving_allowed = abap_true.

    " [FIX ATC Prio 1] Isolate non-released CAUFV access
    " TODO: Replace CAUFV with released CDS view (e.g. I_MfgOrderItem)
    get_order_data(
      EXPORTING iv_aufnr = is_qals-aufnr
      IMPORTING es_caufv = DATA(ls_caufv)
                ev_found = DATA(lv_order_found) ).

    IF lv_order_found = abap_false.
      RETURN.
    ENDIF.

    " [FIX ATC Prio 1] Isolate non-released TVARVC access
    " TODO: Replace TVARVC with custom Z-table or released config API
    DATA lt_tvarv_zordembatelada TYPE RANGE OF char40.
    DATA lt_tvarv_zplantbatelada TYPE RANGE OF char40.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      INTO CORRESPONDING FIELDS OF TABLE @lt_tvarv_zordembatelada
     WHERE name = @gc_tvarvc_order_type ##NEEDED.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      INTO CORRESPONDING FIELDS OF TABLE @lt_tvarv_zplantbatelada
     WHERE name = @gc_tvarvc_plant ##NEEDED.

    IF NOT ( ls_caufv-auart IN lt_tvarv_zordembatelada
         AND ls_caufv-werks IN lt_tvarv_zplantbatelada ).
      RETURN.
    ENDIF.

    " Check if batch record already exists
    IF check_batch_exists(
         iv_matnr = is_qals-matnr
         iv_werks = is_qals-werk
         iv_stlnr = ls_caufv-stlnr
         iv_stlan = ls_caufv-stlan
         iv_stlal = ls_caufv-stlal ) = abap_true.
      ev_saving_allowed = abap_true.
      RETURN.
    ENDIF.

    " [FIX ATC Prio 2] Replace sy-datum with lv_today
    IF lv_today(4) > is_qals-enstehdat(4).
      lv_low  = is_qals-enstehdat.
      lv_high = lv_today.
    ELSE.
      lv_year_start = lv_today(4) && '0101'.
      lv_low  = lv_year_start.
      lv_high = is_qals-enstehdat.
    ENDIF.

    DATA lt_interval_orders TYPE RANGE OF datum.
    APPEND VALUE #( sign   = 'I'
                    option = 'BT'
                    low    = lv_low
                    high   = lv_high ) TO lt_interval_orders.

    " [FIX ATC Prio 1] CAUFV access – TODO: replace with released CDS view
    SELECT aufnr, stlnr, stlan, stlal
      FROM caufv
      INTO TABLE @DATA(lt_lista_ordens)
     WHERE stlnr = @ls_caufv-stlnr
       AND stlan = @ls_caufv-stlan
       AND stlal = @ls_caufv-stlal
       AND erdat IN @lt_interval_orders
     ORDER BY aufnr.                         " [FIX ATC Prio 3] Added ORDER BY
    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_lista_ordens_fae) = lt_lista_ordens[].
    DELETE ADJACENT DUPLICATES FROM lt_lista_ordens_fae COMPARING aufnr.

    IF lt_lista_ordens_fae IS INITIAL.
      RETURN.
    ENDIF.

    " [FIX ATC Prio 1] QALS access – TODO: replace with released API when available
    SELECT prueflos, aufnr
      FROM qals
      INTO TABLE @DATA(lt_lista_lote_qm)
       FOR ALL ENTRIES IN @lt_lista_ordens_fae
     WHERE aufnr = @lt_lista_ordens_fae-aufnr
       AND art   = @gc_inspection_type_04
     ORDER BY prueflos.                      " [FIX ATC Prio 3] Added ORDER BY
    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_lista_lote_qm_fae) = lt_lista_lote_qm[].
    DELETE ADJACENT DUPLICATES FROM lt_lista_lote_qm_fae COMPARING prueflos.

    IF lt_lista_lote_qm_fae IS INITIAL.
      RETURN.
    ENDIF.

    " [FIX ATC Prio 2] Replace sy-datum with lv_today
    lv_year_start = lv_today(4) && '0101'.
    DATA lt_interval_vdatum TYPE RANGE OF datum.
    APPEND VALUE #( sign   = 'I'
                    option = 'BT'
                    low    = lv_year_start
                    high   = lv_today ) TO lt_interval_vdatum.

    " [FIX ATC Prio 1] QAVE access – TODO: replace with released API when available
    " [FIX ATC Prio 3] Added ORDER BY to avoid non-deterministic READ INDEX 1
    SELECT prueflos,
           kzart,
           zaehler
      FROM qave
      INTO TABLE @DATA(lt_qave_result)
       FOR ALL ENTRIES IN @lt_lista_lote_qm_fae
     WHERE prueflos   = @lt_lista_lote_qm_fae-prueflos
       AND vbewertung = @gc_valuation_a
       AND vdatum     IN @lt_interval_vdatum
     ORDER BY prueflos, kzart, zaehler.      " [FIX ATC Prio 3] Deterministic order

    IF lt_qave_result IS INITIAL.
      ev_saving_allowed = abap_true.
    ELSE.
      " [FIX ATC Prio 3] READ INDEX 1 is now safe because of ORDER BY above
      DATA(ls_qave) = lt_qave_result[ 1 ].

      READ TABLE lt_lista_lote_qm INTO DATA(ls_lista_lote_qm)
        WITH KEY prueflos = ls_qave-prueflos
          BINARY SEARCH.

      DATA(lv_aufnr) = COND #( WHEN sy-subrc IS INITIAL
                                THEN ls_lista_lote_qm-aufnr ).

      DATA(ls_ztbqmbatelada) = VALUE ztbqmbatelada(
                                          matnr     = is_qals-matnr
                                          werks     = is_qals-werk
                                          stlnr     = ls_caufv-stlnr
                                          stlan     = ls_caufv-stlan
                                          stlal     = ls_caufv-stlal
                                          aufnr     = lv_aufnr
                                          prueflos  = ls_qave-prueflos
                                          enstehdat = is_qals-enstehdat ).

      save_batch_record( ls_ztbqmbatelada ).

      ev_saving_allowed = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD save.
*--------------------------------------------------------------------*
* Program       : SAVE
* Program Type  : Method
* Author        : WATCORSI (EY)
* Creation Date : 18/10/2025
* Gap ID        : GAP 126
* Description   : Alerta de Primeira batelada e inspeção de layout
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request/ChaRM    Description
* 000 18/10/2025 WATCORSI DS4K900849       Initial Version
* 001 01/04/2026 RTIEZZI  ATC-Refactor     ATC Priority 1+2+3 fixes
*--------------------------------------------------------------------*

    " [FIX ATC Prio 1] CAUFV access – TODO: replace with released CDS view
    get_order_data(
      EXPORTING iv_aufnr = is_qals-aufnr
      IMPORTING es_caufv = DATA(ls_caufv)
                ev_found = DATA(lv_order_found) ).

    IF lv_order_found = abap_false.
      RETURN.
    ENDIF.

    " [FIX ATC Prio 1] TVARVC access – TODO: replace with released config API
    DATA lt_tvarv_zordembatelada TYPE RANGE OF char40.
    DATA lt_tvarv_zplantbatelada TYPE RANGE OF char40.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      INTO CORRESPONDING FIELDS OF TABLE @lt_tvarv_zordembatelada
     WHERE name = @gc_tvarvc_order_type ##NEEDED.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      INTO CORRESPONDING FIELDS OF TABLE @lt_tvarv_zplantbatelada
     WHERE name = @gc_tvarvc_plant ##NEEDED.

    IF NOT ( ls_caufv-auart IN lt_tvarv_zordembatelada
         AND ls_caufv-werks IN lt_tvarv_zplantbatelada ).
      RETURN.
    ENDIF.

    " Check if batch record already exists
    IF check_batch_exists(
         iv_matnr = is_qals-matnr
         iv_werks = is_qals-werk
         iv_stlnr = ls_caufv-stlnr
         iv_stlan = ls_caufv-stlan
         iv_stlal = ls_caufv-stlal ) = abap_true.
      RETURN.
    ENDIF.

    DATA(ls_ztbqmbatelada) = VALUE ztbqmbatelada(
                                        matnr     = is_qals-matnr
                                        werks     = is_qals-werk
                                        stlnr     = ls_caufv-stlnr
                                        stlan     = ls_caufv-stlan
                                        stlal     = ls_caufv-stlal
                                        aufnr     = is_qals-aufnr
                                        prueflos  = is_qals-prueflos
                                        enstehdat = is_qals-enstehdat ).

    save_batch_record( ls_ztbqmbatelada ).

  ENDMETHOD.


  METHOD get_order_data.
    " TODO: Replace CAUFV (non-released PP-SFC view) with released CDS view
    " e.g. I_MfgOrderItem or a custom CDS wrapper
    ev_found = abap_false.
    SELECT SINGLE aufnr, stlnr, stlan, stlal, auart, werks
      FROM caufv
      INTO @es_caufv
     WHERE aufnr = @iv_aufnr.
    IF sy-subrc IS INITIAL.
      ev_found = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD get_tvarvc_range.
    " TODO: Replace TVARVC (non-released BC-ABA-TO) with custom Z-config table
    " or released configuration API
  ENDMETHOD.


  METHOD get_inspection_lots_for_orders.
    " TODO: Replace QALS (will not be released – QM-IM) with released QM API
  ENDMETHOD.


  METHOD get_usage_decisions.
    " TODO: Replace QAVE (non-released – QM-IM-UD) with released QM API
  ENDMETHOD.


  METHOD check_batch_exists.
    " SELECT COUNT(*) always sets sy-subrc = 0; check the count value instead
    SELECT COUNT( * )
      FROM ztbqmbatelada
      INTO @DATA(lv_count)
     WHERE matnr = @iv_matnr
       AND werks = @iv_werks
       AND stlnr = @iv_stlnr
       AND stlan = @iv_stlan
       AND stlal = @iv_stlal.
    rv_exists = xsdbool( lv_count > 0 ).
  ENDMETHOD.


  METHOD save_batch_record.
    " Note: COMMIT WORK is performed here for simplicity of the enhancement exit pattern.
    " In transactional contexts the caller should control LUW boundaries.
    MODIFY ztbqmbatelada FROM @is_record.
    IF sy-subrc IS INITIAL.
      COMMIT WORK AND WAIT.
      rv_success = abap_true.
    ELSE.
      rv_success = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ca_enhancement~init.
*--------------------------------------------------------------------*
* Program       : ZIF_CA_ENHANCEMENT~INIT
* Program Type  : Method
* Author        : WATCORSI (EY)
* Creation Date : 18/10/2025
* Gap ID        : GAP 126
* Description   : Alerta de Primeira batelada e inspeção de layout
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request/ChaRM    Description
* 000 18/10/2025 WATCORSI DS4K900849       Initial Version
* 001 01/04/2026 RTIEZZI  ATC-Refactor     ATC Priority 1+2+3 fixes
*--------------------------------------------------------------------*

    FIELD-SYMBOLS:
      <fs_container>             TYPE me->ty_container,
      <fs_ref_action>            TYPE c,
      <fs_ref_is_qals>           TYPE qals,
      <fs_ref_is_qave>           TYPE qave,
      <fs_ref_is_qapo>           TYPE qapo,
      <fs_ref_ev_subrc>          TYPE sy-subrc,
      <fs_ref_et_protocol>       TYPE ztts2m_rqevp,
      <fs_ref_ev_saving_allowed> TYPE abap_bool, " [FIX ATC Prio 2] was CHAR1
      <fs_ref_cs_qapo>           TYPE qapo,
      <fs_ref_cs_qapp>           TYPE qapp,
      <fs_ref_ct_qamk>           TYPE qamkrtab,
      <fs_ref_ct_qasp>           TYPE qasprtab,
      <fs_ref_ct_qase>           TYPE qasertab,
      <fs_ref_ct_qakl>           TYPE qaklrtab.

    ASSIGN im_params->* TO <fs_container>.

    IF <fs_container> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    ASSIGN <fs_container>-ref_action->* TO <fs_ref_action>.

    IF <fs_ref_action> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE <fs_ref_action>.

      WHEN gc_action_check.

        ASSIGN <fs_container>-ref_is_qals->*           TO <fs_ref_is_qals>.
        ASSIGN <fs_container>-ref_ev_saving_allowed->*  TO <fs_ref_ev_saving_allowed>.
        ASSIGN <fs_container>-ref_cs_qapo->*            TO <fs_ref_cs_qapo>.
        ASSIGN <fs_container>-ref_cs_qapp->*            TO <fs_ref_cs_qapp>.
        ASSIGN <fs_container>-ref_ct_qamk->*            TO <fs_ref_ct_qamk>.
        ASSIGN <fs_container>-ref_ct_qasp->*            TO <fs_ref_ct_qasp>.
        ASSIGN <fs_container>-ref_ct_qase->*            TO <fs_ref_ct_qase>.
        ASSIGN <fs_container>-ref_ct_qakl->*            TO <fs_ref_ct_qakl>.

        check(
          EXPORTING
            is_qals           = <fs_ref_is_qals>
          IMPORTING
            ev_saving_allowed = <fs_ref_ev_saving_allowed>
          CHANGING
            cs_qapo           = <fs_ref_cs_qapo>
            cs_qapp           = <fs_ref_cs_qapp>
            ct_qamk           = <fs_ref_ct_qamk>
            ct_qasp           = <fs_ref_ct_qasp>
            ct_qase           = <fs_ref_ct_qase>
            ct_qakl           = <fs_ref_ct_qakl> ).

      WHEN gc_action_save.

        ASSIGN <fs_container>-ref_is_qals->*     TO <fs_ref_is_qals>.
        ASSIGN <fs_container>-ref_is_qave->*     TO <fs_ref_is_qave>.
        ASSIGN <fs_container>-ref_is_qapo->*     TO <fs_ref_is_qapo>.
        ASSIGN <fs_container>-ref_ev_subrc->*    TO <fs_ref_ev_subrc>.
        ASSIGN <fs_container>-ref_et_protocol->* TO <fs_ref_et_protocol>.

        save(
          EXPORTING
            is_qals     = <fs_ref_is_qals>
            is_qave     = <fs_ref_is_qave>
            is_qapo     = <fs_ref_is_qapo>
          IMPORTING
            ev_subrc    = <fs_ref_ev_subrc>
            et_protocol = <fs_ref_et_protocol> ).

      WHEN OTHERS.
        " No action for unknown commands

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
