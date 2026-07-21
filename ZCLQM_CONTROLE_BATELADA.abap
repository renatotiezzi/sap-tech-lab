*&---------------------------------------------------------------------*
*& Class:       ZCLQM_CONTROLE_BATELADA
*& Description: QM Batch Control – ATC Clean Core refactoring
*&---------------------------------------------------------------------*
*& Change History:
*& Date        | Author    | Request/ChaRM | Description
*& ------------|-----------|---------------|----------------------------
*& 18/10/2025  | WATCORSI  | DS4K900849    | Initial Version
*& 01/04/2026  | REFACTOR  | ATC           | ATC P1/P2 fixes:
*&             |           |               | TVARVC->cl_tvarvc,
*&             |           |               | CAUFV->I_ManufacturingOrder,
*&             |           |               | QALS->I_QualityInspectionLot,
*&             |           |               | QAVE->I_InspectionLotUsageDecision
*&             |           |               | SY-DATUM->get_system_date(),
*&             |           |               | GET REFERENCE->REF #(),
*&             |           |               | CHAR1->abap_bool,
*&             |           |               | unreleased types replaced
*&---------------------------------------------------------------------*
CLASS zclqm_controle_batelada DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "--- Container for dynamic parameter passing via zif_ca_enhancement ---
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

    INTERFACES zif_ca_enhancement.

  PROTECTED SECTION.

  PRIVATE SECTION.

    "--- Local structure types replacing unreleased DDIC types ---

    "- Replaces QALS fields used in logic -
    TYPES:
      BEGIN OF ty_qals,
        prueflos  TYPE prueflos,
        matnr     TYPE matnr,
        werk      TYPE werk,
        aufnr     TYPE aufnr,
        art       TYPE art,
        enstehdat TYPE enstehdat,
      END OF ty_qals.

    "- Replaces QAVE fields used in logic -
    TYPES:
      BEGIN OF ty_qave,
        prueflos   TYPE prueflos,
        kzart      TYPE kzart,
        zaehler    TYPE zaehler,
        vbewertung TYPE vbewertung,
        vdatum     TYPE vdatum,
      END OF ty_qave.

    "- Replaces QAPO fields used in logic -
    TYPES:
      BEGIN OF ty_qapo,
        prueflos TYPE prueflos,
        vornr    TYPE vornr,
        ktpnr    TYPE ktpnr,
      END OF ty_qapo.

    "- Replaces QAPP fields used in logic -
    TYPES:
      BEGIN OF ty_qapp,
        prueflos TYPE prueflos,
        vornr    TYPE vornr,
        lnr      TYPE lnr,
      END OF ty_qapp.

    "- Local table types replacing unreleased QAMKRTAB/QASPRTAB/QASERTAB/QAKLRTAB -
    TYPES:
      BEGIN OF ty_qamk,
        prueflos TYPE prueflos,
        mcode    TYPE mcode,
      END OF ty_qamk.
    TYPES tt_qamk TYPE STANDARD TABLE OF ty_qamk WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_qasp,
        prueflos TYPE prueflos,
        spezif   TYPE spezif,
      END OF ty_qasp.
    TYPES tt_qasp TYPE STANDARD TABLE OF ty_qasp WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_qase,
        prueflos TYPE prueflos,
        serdat   TYPE serdat,
      END OF ty_qase.
    TYPES tt_qase TYPE STANDARD TABLE OF ty_qase WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_qakl,
        prueflos TYPE prueflos,
        klasse   TYPE klasse,
      END OF ty_qakl.
    TYPES tt_qakl TYPE STANDARD TABLE OF ty_qakl WITH EMPTY KEY.

    "--- Local structure for I_ManufacturingOrder CDS result ---
    TYPES:
      BEGIN OF ty_mfg_order,
        aufnr TYPE aufnr,
        stlnr TYPE stlnr,
        stlan TYPE stlan,
        stlal TYPE stlal,
        auart TYPE auart,
        werks TYPE werks,
        erdat TYPE erdat,
      END OF ty_mfg_order.

    "--- Constants (P1 fix: no longer reference unreleased table field types) ---
    CONSTANTS gc_04 TYPE c LENGTH 2 VALUE '04' ##NO_TEXT.
    CONSTANTS gc_a  TYPE c LENGTH 1 VALUE 'A'  ##NO_TEXT.

    "--- Private Methods ---
    METHODS save
      IMPORTING
        !is_qals     TYPE ty_qals
        !is_qave     TYPE ty_qave
        !is_qapo     TYPE ty_qapo
      EXPORTING
        !ev_subrc    TYPE sy-subrc
        !et_protocol TYPE ztts2m_rqevp.

    METHODS check
      IMPORTING
        !is_qals           TYPE ty_qals
      EXPORTING
        !ev_saving_allowed TYPE abap_bool        "P2 fix: char1 -> abap_bool
      CHANGING
        !cs_qapo           TYPE ty_qapo          "P1 fix: qapo -> local ty_qapo
        !cs_qapp           TYPE ty_qapp          "P1 fix: qapp -> local ty_qapp
        !ct_qamk           TYPE tt_qamk          "P1 fix: qamkrtab -> local tt_qamk
        !ct_qasp           TYPE tt_qasp          "P1 fix: qasprtab -> local tt_qasp
        !ct_qase           TYPE tt_qase          "P1 fix: qasertab -> local tt_qase
        !ct_qakl           TYPE tt_qakl.         "P1 fix: qaklrtab -> local tt_qakl

    "--- Helper: read manufacturing order via released CDS I_ManufacturingOrder ---
    METHODS get_mfg_order
      IMPORTING
        !iv_aufnr     TYPE aufnr
      EXPORTING
        !es_mfg_order TYPE ty_mfg_order
        !ev_subrc     TYPE sy-subrc.

    "--- Helper: read TVARVC range via released cl_tvarvc (P1 fix) ---
    METHODS get_tvarvc_range
      IMPORTING
        !iv_name      TYPE tvarvc-name
      RETURNING
        VALUE(rt_range) TYPE RANGE OF c.

ENDCLASS.


CLASS zclqm_controle_batelada IMPLEMENTATION.

  "==========================================================================
  " METHOD get_mfg_order
  " Purpose : Encapsulates production order master data access.
  "           P1 fix: replaces direct SELECT on unreleased view CAUFV with
  "           released CDS view I_ManufacturingOrder.
  "==========================================================================
  METHOD get_mfg_order.

    CLEAR: es_mfg_order, ev_subrc.

    SELECT SINGLE
        ManufacturingOrder      AS aufnr,
        ProductionBOMInternalID AS stlnr,
        BOMCategory             AS stlan,
        BOMAlternative          AS stlal,
        ManufacturingOrderType  AS auart,
        ProductionPlant         AS werks,
        CreationDate            AS erdat
      FROM I_ManufacturingOrder
      INTO @es_mfg_order
     WHERE ManufacturingOrder = @iv_aufnr.

    ev_subrc = sy-subrc.

  ENDMETHOD.


  "==========================================================================
  " METHOD get_tvarvc_range
  " Purpose : Reads selection variable from TVARVC via released class
  "           cl_tvarvc. P1 fix: replaces all direct SELECT on table TVARVC.
  "==========================================================================
  METHOD get_tvarvc_range.

    TRY.
        cl_tvarvc=>get_range(
          EXPORTING
            iv_name  = iv_name
          IMPORTING
            et_range = rt_range
        ).
      CATCH cx_tvarvc.
        CLEAR rt_range.
    ENDTRY.

  ENDMETHOD.


  "==========================================================================
  " METHOD check
  " Purpose : Validates whether saving the inspection result is allowed.
  "           P1 fix: all unreleased table/view accesses replaced with
  "           released CDS views (I_ManufacturingOrder, I_QualityInspectionLot,
  "           I_InspectionLotUsageDecision).
  "           P2 fix: SY-DATUM replaced with cl_abap_context_info=>get_system_date().
  "==========================================================================
  METHOD check.

    DATA lv_today      TYPE datum.
    DATA lv_low        TYPE datum.
    DATA lv_high       TYPE datum.
    DATA lv_year_start TYPE datum.

    ev_saving_allowed = abap_false.

    "P2 fix: SY-DATUM -> cl_abap_context_info=>get_system_date()
    lv_today = cl_abap_context_info=>get_system_date( ).

    "P1 fix: CAUFV -> I_ManufacturingOrder
    DATA ls_mfg_order TYPE ty_mfg_order.
    DATA lv_subrc     TYPE sy-subrc.

    me->get_mfg_order(
      EXPORTING iv_aufnr     = is_qals-aufnr
      IMPORTING es_mfg_order = ls_mfg_order
                ev_subrc     = lv_subrc
    ).
    IF lv_subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    "P1 fix: SELECT TVARVC -> cl_tvarvc=>get_range()
    DATA(lt_tvarv_zordembatelada) = me->get_tvarvc_range( iv_name = 'ZS2M126_BATTPOP'    ).
    DATA(lt_tvarv_zplantbatelada) = me->get_tvarvc_range( iv_name = 'ZS2M126_BATPLANTOP' ).

    IF NOT ( ls_mfg_order-auart IN lt_tvarv_zordembatelada
         AND ls_mfg_order-werks IN lt_tvarv_zplantbatelada ).
      RETURN.
    ENDIF.

    SELECT COUNT(*)
      FROM ztbqmbatelada
     WHERE matnr = @is_qals-matnr
       AND werks = @is_qals-werk
       AND stlnr = @ls_mfg_order-stlnr
       AND stlan = @ls_mfg_order-stlan
       AND stlal = @ls_mfg_order-stlal.
    IF sy-subrc IS INITIAL.
      ev_saving_allowed = abap_true.
      RETURN.
    ENDIF.

    "P2 fix: SY-DATUM -> lv_today
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

    "P1 fix: CAUFV -> I_ManufacturingOrder; ORDER BY added to avoid P3 READ TABLE INDEX issue
    TYPES: BEGIN OF ty_order_key,
             aufnr TYPE aufnr,
             stlnr TYPE stlnr,
             stlan TYPE stlan,
             stlal TYPE stlal,
           END OF ty_order_key.

    DATA lt_lista_ordens     TYPE STANDARD TABLE OF ty_order_key WITH EMPTY KEY.
    DATA lt_lista_ordens_fae TYPE STANDARD TABLE OF ty_order_key WITH EMPTY KEY.

    SELECT
        ManufacturingOrder      AS aufnr,
        ProductionBOMInternalID AS stlnr,
        BOMCategory             AS stlan,
        BOMAlternative          AS stlal
      FROM I_ManufacturingOrder
      INTO TABLE @lt_lista_ordens
     WHERE ProductionBOMInternalID = @ls_mfg_order-stlnr
       AND BOMCategory             = @ls_mfg_order-stlan
       AND BOMAlternative          = @ls_mfg_order-stlal
       AND CreationDate            IN @lt_interval_orders
     ORDER BY ManufacturingOrder.

    IF sy-subrc IS INITIAL.
      lt_lista_ordens_fae = lt_lista_ordens.
      SORT lt_lista_ordens_fae BY aufnr.
      DELETE ADJACENT DUPLICATES FROM lt_lista_ordens_fae COMPARING aufnr.
    ENDIF.

    CHECK lt_lista_ordens_fae IS NOT INITIAL.

    "P1 fix: QALS -> I_QualityInspectionLot
    TYPES: BEGIN OF ty_lot_key,
             prueflos TYPE prueflos,
             aufnr    TYPE aufnr,
           END OF ty_lot_key.

    DATA lt_lista_lote_qm     TYPE STANDARD TABLE OF ty_lot_key WITH EMPTY KEY.
    DATA lt_lista_lote_qm_fae TYPE STANDARD TABLE OF ty_lot_key WITH EMPTY KEY.

    SELECT
        InspectionLot      AS prueflos,
        ManufacturingOrder AS aufnr
      FROM I_QualityInspectionLot
      INTO TABLE @lt_lista_lote_qm
       FOR ALL ENTRIES IN @lt_lista_ordens_fae
     WHERE ManufacturingOrder   = @lt_lista_ordens_fae-aufnr
       AND InspectionLotOrigin  = @gc_04
     ORDER BY InspectionLot.

    IF sy-subrc IS INITIAL.
      SORT lt_lista_lote_qm BY prueflos.
      lt_lista_lote_qm_fae = lt_lista_lote_qm.
      DELETE ADJACENT DUPLICATES FROM lt_lista_lote_qm_fae COMPARING prueflos.
    ENDIF.

    CHECK lt_lista_lote_qm_fae IS NOT INITIAL.

    "P2 fix: SY-DATUM -> lv_today
    lv_year_start = lv_today(4) && '0101'.
    DATA lt_interval_vdatum TYPE RANGE OF datum.
    APPEND VALUE #( sign   = 'I'
                    option = 'BT'
                    low    = lv_year_start
                    high   = lv_today ) TO lt_interval_vdatum.

    "P1 fix: QAVE -> I_InspectionLotUsageDecision; ORDER BY ensures deterministic first row
    TYPES: BEGIN OF ty_ud_result,
             prueflos TYPE prueflos,
             kzart    TYPE kzart,
             zaehler  TYPE zaehler,
           END OF ty_ud_result.

    DATA lt_qave_result TYPE STANDARD TABLE OF ty_ud_result WITH EMPTY KEY.

    SELECT
        InspectionLot             AS prueflos,
        InspectionLotType         AS kzart,
        InspLotUsageDecisionCount AS zaehler
      FROM I_InspectionLotUsageDecision
      INTO TABLE @lt_qave_result
       FOR ALL ENTRIES IN @lt_lista_lote_qm_fae
     WHERE InspectionLot         = @lt_lista_lote_qm_fae-prueflos
       AND UsageDecisionValuation = @gc_a
       AND UsageDecisionDate      IN @lt_interval_vdatum
     ORDER BY InspectionLot.

    IF lt_qave_result IS INITIAL.
      ev_saving_allowed = abap_true.
    ELSE.
      "First row is deterministic due to ORDER BY above (P3 fix)
      DATA(ls_qave) = lt_qave_result[ 1 ].

      SORT lt_lista_lote_qm BY prueflos.
      READ TABLE lt_lista_lote_qm INTO DATA(ls_lista_lote_qm)
        WITH KEY prueflos = ls_qave-prueflos
        BINARY SEARCH.

      DATA(lv_aufnr) = COND aufnr(
                              WHEN sy-subrc IS INITIAL
                              THEN ls_lista_lote_qm-aufnr ).

      DATA(ls_ztbqmbatelada) = VALUE ztbqmbatelada(
          matnr     = is_qals-matnr
          werks     = is_qals-werk
          stlnr     = ls_mfg_order-stlnr
          stlan     = ls_mfg_order-stlan
          stlal     = ls_mfg_order-stlal
          aufnr     = lv_aufnr
          prueflos  = ls_qave-prueflos
          enstehdat = is_qals-enstehdat
      ).

      MODIFY ztbqmbatelada FROM @ls_ztbqmbatelada.
      IF sy-subrc IS INITIAL.
        COMMIT WORK AND WAIT.
      ENDIF.

      ev_saving_allowed = abap_true.
    ENDIF.

  ENDMETHOD.


  "==========================================================================
  " METHOD save
  " Purpose : Creates a new batch control entry when none exists.
  "           P1 fix: CAUFV -> I_ManufacturingOrder, TVARVC -> cl_tvarvc.
  "==========================================================================
  METHOD save.

    CLEAR: ev_subrc, et_protocol.

    "P1 fix: CAUFV -> I_ManufacturingOrder
    DATA ls_mfg_order TYPE ty_mfg_order.
    DATA lv_subrc     TYPE sy-subrc.

    me->get_mfg_order(
      EXPORTING iv_aufnr     = is_qals-aufnr
      IMPORTING es_mfg_order = ls_mfg_order
                ev_subrc     = lv_subrc
    ).
    IF lv_subrc IS NOT INITIAL.
      ev_subrc = lv_subrc.
      RETURN.
    ENDIF.

    "P1 fix: SELECT TVARVC -> cl_tvarvc=>get_range()
    DATA(lt_tvarv_zordembatelada) = me->get_tvarvc_range( iv_name = 'ZS2M126_BATTPOP'    ).
    DATA(lt_tvarv_zplantbatelada) = me->get_tvarvc_range( iv_name = 'ZS2M126_BATPLANTOP' ).

    IF NOT ( ls_mfg_order-auart IN lt_tvarv_zordembatelada
         AND ls_mfg_order-werks IN lt_tvarv_zplantbatelada ).
      RETURN.
    ENDIF.

    SELECT COUNT(*)
      FROM ztbqmbatelada
     WHERE matnr = @is_qals-matnr
       AND werks = @is_qals-werk
       AND stlnr = @ls_mfg_order-stlnr
       AND stlan = @ls_mfg_order-stlan
       AND stlal = @ls_mfg_order-stlal.
    IF sy-subrc IS INITIAL.
      RETURN.
    ENDIF.

    DATA(ls_ztbqmbatelada) = VALUE ztbqmbatelada(
        matnr     = is_qals-matnr
        werks     = is_qals-werk
        stlnr     = ls_mfg_order-stlnr
        stlan     = ls_mfg_order-stlan
        stlal     = ls_mfg_order-stlal
        aufnr     = is_qals-aufnr
        prueflos  = is_qals-prueflos
        enstehdat = is_qals-enstehdat
    ).

    MODIFY ztbqmbatelada FROM @ls_ztbqmbatelada.
    ev_subrc = sy-subrc.
    IF sy-subrc IS INITIAL.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.


  "==========================================================================
  " METHOD zif_ca_enhancement~init
  " Purpose : Receives dynamically-bound parameters via the enhancement
  "           framework container. Stores REF TO data pointers for execute().
  "           P2 fix: GET REFERENCE OF <fs> INTO ref -> ref = REF #( <fs> )
  "==========================================================================
  METHOD zif_ca_enhancement~init.

    FIELD-SYMBOLS:
      <fs_qals>        TYPE ty_qals,
      <fs_qave>        TYPE ty_qave,
      <fs_qapo>        TYPE ty_qapo,
      <fs_ev_subrc>    TYPE sy-subrc,
      <fs_et_protocol> TYPE ztts2m_rqevp,
      <fs_ev_saving>   TYPE abap_bool,
      <fs_cs_qapo>     TYPE ty_qapo,
      <fs_cs_qapp>     TYPE ty_qapp,
      <fs_ct_qamk>     TYPE tt_qamk,
      <fs_ct_qasp>     TYPE tt_qasp,
      <fs_ct_qase>     TYPE tt_qase,
      <fs_ct_qakl>     TYPE tt_qakl,
      <fs_action>      TYPE data.

    IF cs_container-ref_is_qals IS BOUND.
      ASSIGN cs_container-ref_is_qals->* TO <fs_qals>.
      IF <fs_qals> IS ASSIGNED.
        cs_container-ref_is_qals = REF #( <fs_qals> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_is_qave IS BOUND.
      ASSIGN cs_container-ref_is_qave->* TO <fs_qave>.
      IF <fs_qave> IS ASSIGNED.
        cs_container-ref_is_qave = REF #( <fs_qave> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_is_qapo IS BOUND.
      ASSIGN cs_container-ref_is_qapo->* TO <fs_qapo>.
      IF <fs_qapo> IS ASSIGNED.
        cs_container-ref_is_qapo = REF #( <fs_qapo> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_ev_subrc IS BOUND.
      ASSIGN cs_container-ref_ev_subrc->* TO <fs_ev_subrc>.
      IF <fs_ev_subrc> IS ASSIGNED.
        cs_container-ref_ev_subrc = REF #( <fs_ev_subrc> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_et_protocol IS BOUND.
      ASSIGN cs_container-ref_et_protocol->* TO <fs_et_protocol>.
      IF <fs_et_protocol> IS ASSIGNED.
        cs_container-ref_et_protocol = REF #( <fs_et_protocol> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_ev_saving_allowed IS BOUND.
      ASSIGN cs_container-ref_ev_saving_allowed->* TO <fs_ev_saving>.
      IF <fs_ev_saving> IS ASSIGNED.
        cs_container-ref_ev_saving_allowed = REF #( <fs_ev_saving> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_cs_qapo IS BOUND.
      ASSIGN cs_container-ref_cs_qapo->* TO <fs_cs_qapo>.
      IF <fs_cs_qapo> IS ASSIGNED.
        cs_container-ref_cs_qapo = REF #( <fs_cs_qapo> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_cs_qapp IS BOUND.
      ASSIGN cs_container-ref_cs_qapp->* TO <fs_cs_qapp>.
      IF <fs_cs_qapp> IS ASSIGNED.
        cs_container-ref_cs_qapp = REF #( <fs_cs_qapp> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_ct_qamk IS BOUND.
      ASSIGN cs_container-ref_ct_qamk->* TO <fs_ct_qamk>.
      IF <fs_ct_qamk> IS ASSIGNED.
        cs_container-ref_ct_qamk = REF #( <fs_ct_qamk> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_ct_qasp IS BOUND.
      ASSIGN cs_container-ref_ct_qasp->* TO <fs_ct_qasp>.
      IF <fs_ct_qasp> IS ASSIGNED.
        cs_container-ref_ct_qasp = REF #( <fs_ct_qasp> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_ct_qase IS BOUND.
      ASSIGN cs_container-ref_ct_qase->* TO <fs_ct_qase>.
      IF <fs_ct_qase> IS ASSIGNED.
        cs_container-ref_ct_qase = REF #( <fs_ct_qase> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_ct_qakl IS BOUND.
      ASSIGN cs_container-ref_ct_qakl->* TO <fs_ct_qakl>.
      IF <fs_ct_qakl> IS ASSIGNED.
        cs_container-ref_ct_qakl = REF #( <fs_ct_qakl> ).
      ENDIF.
    ENDIF.

    IF cs_container-ref_action IS BOUND.
      ASSIGN cs_container-ref_action->* TO <fs_action>.
      IF <fs_action> IS ASSIGNED.
        cs_container-ref_action = REF #( <fs_action> ).
      ENDIF.
    ENDIF.

  ENDMETHOD.


  "==========================================================================
  " METHOD zif_ca_enhancement~execute
  " Purpose : Dereferences stored REF TO data pointers and calls the core
  "           check() or save() method depending on the action flag.
  "==========================================================================
  METHOD zif_ca_enhancement~execute.

    IF cs_container-ref_is_qals IS NOT BOUND.
      RETURN.
    ENDIF.

    FIELD-SYMBOLS <fs_qals> TYPE ty_qals.
    ASSIGN cs_container-ref_is_qals->* TO <fs_qals>.
    IF <fs_qals> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    FIELD-SYMBOLS <fs_cs_qapo> TYPE ty_qapo.
    IF cs_container-ref_cs_qapo IS BOUND.
      ASSIGN cs_container-ref_cs_qapo->* TO <fs_cs_qapo>.
    ENDIF.

    FIELD-SYMBOLS <fs_cs_qapp> TYPE ty_qapp.
    IF cs_container-ref_cs_qapp IS BOUND.
      ASSIGN cs_container-ref_cs_qapp->* TO <fs_cs_qapp>.
    ENDIF.

    FIELD-SYMBOLS <fs_ct_qamk> TYPE tt_qamk.
    IF cs_container-ref_ct_qamk IS BOUND.
      ASSIGN cs_container-ref_ct_qamk->* TO <fs_ct_qamk>.
    ENDIF.

    FIELD-SYMBOLS <fs_ct_qasp> TYPE tt_qasp.
    IF cs_container-ref_ct_qasp IS BOUND.
      ASSIGN cs_container-ref_ct_qasp->* TO <fs_ct_qasp>.
    ENDIF.

    FIELD-SYMBOLS <fs_ct_qase> TYPE tt_qase.
    IF cs_container-ref_ct_qase IS BOUND.
      ASSIGN cs_container-ref_ct_qase->* TO <fs_ct_qase>.
    ENDIF.

    FIELD-SYMBOLS <fs_ct_qakl> TYPE tt_qakl.
    IF cs_container-ref_ct_qakl IS BOUND.
      ASSIGN cs_container-ref_ct_qakl->* TO <fs_ct_qakl>.
    ENDIF.

    FIELD-SYMBOLS <fs_ev_saving> TYPE abap_bool.
    IF cs_container-ref_ev_saving_allowed IS BOUND.
      ASSIGN cs_container-ref_ev_saving_allowed->* TO <fs_ev_saving>.
    ENDIF.

    DATA lv_action TYPE c LENGTH 10.
    FIELD-SYMBOLS <fs_action> TYPE data.
    IF cs_container-ref_action IS BOUND.
      ASSIGN cs_container-ref_action->* TO <fs_action>.
      IF <fs_action> IS ASSIGNED.
        lv_action = <fs_action>.
      ENDIF.
    ENDIF.

    CASE lv_action.

      WHEN 'CHECK'.
        DATA ls_qapo_local TYPE ty_qapo.
        DATA ls_qapp_local TYPE ty_qapp.
        DATA lt_qamk_local TYPE tt_qamk.
        DATA lt_qasp_local TYPE tt_qasp.
        DATA lt_qase_local TYPE tt_qase.
        DATA lt_qakl_local TYPE tt_qakl.
        DATA lv_saving_flag TYPE abap_bool.

        me->check(
          EXPORTING
            is_qals           = <fs_qals>
          IMPORTING
            ev_saving_allowed = lv_saving_flag
          CHANGING
            cs_qapo = COND #( WHEN <fs_cs_qapo> IS ASSIGNED THEN <fs_cs_qapo> ELSE ls_qapo_local )
            cs_qapp = COND #( WHEN <fs_cs_qapp> IS ASSIGNED THEN <fs_cs_qapp> ELSE ls_qapp_local )
            ct_qamk = COND #( WHEN <fs_ct_qamk> IS ASSIGNED THEN <fs_ct_qamk> ELSE lt_qamk_local )
            ct_qasp = COND #( WHEN <fs_ct_qasp> IS ASSIGNED THEN <fs_ct_qasp> ELSE lt_qasp_local )
            ct_qase = COND #( WHEN <fs_ct_qase> IS ASSIGNED THEN <fs_ct_qase> ELSE lt_qase_local )
            ct_qakl = COND #( WHEN <fs_ct_qakl> IS ASSIGNED THEN <fs_ct_qakl> ELSE lt_qakl_local )
        ).

        IF <fs_ev_saving> IS ASSIGNED.
          <fs_ev_saving> = lv_saving_flag.
        ENDIF.

      WHEN 'SAVE'.
        FIELD-SYMBOLS <fs_qave> TYPE ty_qave.
        IF cs_container-ref_is_qave IS BOUND.
          ASSIGN cs_container-ref_is_qave->* TO <fs_qave>.
        ENDIF.

        FIELD-SYMBOLS <fs_qapo> TYPE ty_qapo.
        IF cs_container-ref_is_qapo IS BOUND.
          ASSIGN cs_container-ref_is_qapo->* TO <fs_qapo>.
        ENDIF.

        IF <fs_qave> IS NOT ASSIGNED OR <fs_qapo> IS NOT ASSIGNED.
          RETURN.
        ENDIF.

        DATA lv_ev_subrc    TYPE sy-subrc.
        DATA lt_et_protocol TYPE ztts2m_rqevp.

        me->save(
          EXPORTING
            is_qals     = <fs_qals>
            is_qave     = <fs_qave>
            is_qapo     = <fs_qapo>
          IMPORTING
            ev_subrc    = lv_ev_subrc
            et_protocol = lt_et_protocol
        ).

        FIELD-SYMBOLS <fs_ev_subrc> TYPE sy-subrc.
        IF cs_container-ref_ev_subrc IS BOUND.
          ASSIGN cs_container-ref_ev_subrc->* TO <fs_ev_subrc>.
          IF <fs_ev_subrc> IS ASSIGNED.
            <fs_ev_subrc> = lv_ev_subrc.
          ENDIF.
        ENDIF.

        FIELD-SYMBOLS <fs_et_protocol> TYPE ztts2m_rqevp.
        IF cs_container-ref_et_protocol IS BOUND.
          ASSIGN cs_container-ref_et_protocol->* TO <fs_et_protocol>.
          IF <fs_et_protocol> IS ASSIGNED.
            <fs_et_protocol> = lt_et_protocol.
          ENDIF.
        ENDIF.

      WHEN OTHERS.
        "Unknown action – no operation performed
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
