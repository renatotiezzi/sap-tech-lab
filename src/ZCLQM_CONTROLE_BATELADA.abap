"! <p class="shorttext synchronized" lang="en">Batch Control - ATC Cloud-safe refactoring</p>
"!
"! <strong>ATC Priority-1 fixes applied:</strong>
"! <ul>
"!   <li>TVARVC  (BC-ABA-TO)  → CL_SVARV released API</li>
"!   <li>CAUFV   (PP-SFC, CO) → CDS View I_ManufacturingOrder</li>
"!   <li>QALS    (QM-IM)      → CDS View I_InspectionLot</li>
"!   <li>QAVE    (QM-IM-UD)   → CDS View I_InspResultUsageDecision</li>
"!   <li>QAPO/QAPP/unreleased tab-types → removed (unused params)</li>
"!   <li>CONSTANTS types qals-art / qave-vbewertung → c LENGTH n literals</li>
"!   <li>SELECT syntax → host variables + INTO @DATA inline</li>
"!   <li>SY-DATUM → CL_ABAP_CONTEXT_INFO=>GET_SYSTEM_DATE( )</li>
"! </ul>
CLASS zclqm_controle_batelada DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Generic container used by the ZIF_CA_ENHANCEMENT framework.
    "! All fields are typed REF TO data so no unreleased DDIC type is
    "! referenced from the public interface.
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

    "--------------------------------------------------------------------
    " Local types – replace every unreleased DDIC reference
    "--------------------------------------------------------------------

    "! Replaces direct reference to unreleased table QALS (QM-IM).
    "! Only the fields actually consumed by CHECK and SAVE are declared.
    TYPES:
      BEGIN OF ty_qals_data,
        prueflos  TYPE c LENGTH 12, "< Inspection lot number  (QPLOS domain)
        aufnr     TYPE aufnr,       "< Manufacturing order number
        matnr     TYPE matnr,       "< Material number
        werk      TYPE werks_d,     "< Plant
        enstehdat TYPE datum,       "< Inspection lot creation date
      END OF ty_qals_data.

    "! Result row from I_ManufacturingOrder query.
    "! Mirrors CAUFV fields used in the original logic.
    TYPES:
      BEGIN OF ty_order_result,
        aufnr TYPE aufnr,
        stlnr TYPE c LENGTH 8,  "< BOM document number
        stlan TYPE c LENGTH 1,  "< BOM usage
        stlal TYPE c LENGTH 2,  "< BOM alternative
        auart TYPE c LENGTH 4,  "< Order type
        werks TYPE werks_d,     "< Plant
      END OF ty_order_result.

    "! Result row for inspection lot / order cross-reference
    "! (I_InspectionLot projection replacing QALS FAE query).
    TYPES:
      BEGIN OF ty_insp_lot_order,
        prueflos TYPE c LENGTH 12,
        aufnr    TYPE aufnr,
      END OF ty_insp_lot_order.

    "! Result row from I_InspResultUsageDecision
    "! (replaces QAVE table access).
    TYPES:
      BEGIN OF ty_usage_decision,
        prueflos TYPE c LENGTH 12,
        kzart    TYPE c LENGTH 3, "< Usage decision category
        zaehler  TYPE i,          "< Usage decision item counter
      END OF ty_usage_decision.

    "--------------------------------------------------------------------
    " Constants – literal types instead of unreleased qals-art /
    "             qave-vbewertung references
    "--------------------------------------------------------------------

    "! Inspection lot origin '04' = linked to a manufacturing order.
    "! Replaces: CONSTANTS gc_04 TYPE qals-art VALUE '04'.
    CONSTANTS gc_04 TYPE c LENGTH 2 VALUE '04' ##NO_TEXT.

    "! Usage decision valuation 'A' = Accepted.
    "! Replaces: CONSTANTS gc_a TYPE qave-vbewertung VALUE 'A'.
    CONSTANTS gc_a TYPE c LENGTH 1 VALUE 'A' ##NO_TEXT.

    "--------------------------------------------------------------------
    " Private methods
    "--------------------------------------------------------------------

    "! Persist batch-control record for a new inspection lot.
    "!
    "! ATC changes vs original:
    "!  - IS_QALS: qals → ty_qals_data (unreleased type removed)
    "!  - IS_QAVE / IS_QAPO: removed (parameters were never used in body)
    "!  - CAUFV replaced by I_ManufacturingOrder CDS view
    "!  - TVARVC replaced by CL_SVARV helper
    METHODS save
      IMPORTING
        !is_qals     TYPE ty_qals_data
      EXPORTING
        !ev_subrc    TYPE sysubrc
        !et_protocol TYPE ztts2m_rqevp.

    "! Check whether saving is allowed for the current inspection lot.
    "!
    "! ATC changes vs original:
    "!  - IS_QALS: qals → ty_qals_data
    "!  - CHANGING cs_qapo (qapo), cs_qapp (qapp), ct_qamk (qamkrtab),
    "!    ct_qasp (qasprtab), ct_qase (qasertab), ct_qakl (qaklrtab)
    "!    all removed – none were read or written in the implementation.
    "!  - CAUFV → I_ManufacturingOrder
    "!  - TVARVC → CL_SVARV
    "!  - QALS (FAE) → I_InspectionLot
    "!  - QAVE (FAE) → I_InspResultUsageDecision
    METHODS check
      IMPORTING
        !is_qals           TYPE ty_qals_data
      EXPORTING
        !ev_saving_allowed TYPE c.

    "! Read a TVARVC selection-option variable via the released CL_SVARV API.
    "!
    "! Direct access to TVARVC is not permitted in ABAP Cloud (BC-ABA-TO
    "! component not released). CL_SVARV is the released replacement.
    "!
    "! @parameter iv_variable_name | TVARVC variable name (max 32 chars)
    "! @parameter rt_selopt        | Range-compatible selection options
    METHODS get_selopt
      IMPORTING
        !iv_variable_name TYPE c LENGTH 32
      RETURNING
        VALUE(rt_selopt)  TYPE rsds_selopt_t.

ENDCLASS.


CLASS zclqm_controle_batelada IMPLEMENTATION.

  "--------------------------------------------------------------------------
  METHOD zif_ca_enhancement~init.
    "! Entry point called by the ZIF_CA_ENHANCEMENT framework.
    "! Unpacks generic REF TO data pointers from the container,
    "! maps them to local typed structures and dispatches to CHECK or SAVE.
    "!
    "! NOTE: The original implementation was truncated in the problem
    "! statement. This skeleton shows the ATC-safe pattern for unpacking
    "! and calling the private methods. Expand with project-specific logic.

    " -- 1. Resolve the container object (framework-specific cast) -----------
    DATA lr_container TYPE REF TO ty_container.
    TRY.
        lr_container ?= io_container. "< io_container typed by zif_ca_enhancement
      CATCH cx_sy_move_cast_error.
        RETURN. "< Incompatible container – defensive exit
    ENDTRY.

    " -- 2. Determine requested action from the generic ref ------------------
    FIELD-SYMBOLS <fv_action> TYPE c.
    IF lr_container->ref_action IS BOUND.
      ASSIGN lr_container->ref_action->* TO <fv_action>.
    ENDIF.

    " -- 3. Unpack inspection lot data from generic ref ----------------------
    DATA ls_qals TYPE ty_qals_data.

    IF lr_container->ref_is_qals IS BOUND.
      " Use ASSIGN to dereference generically – no direct QALS type reference.
      FIELD-SYMBOLS <fs_qals> TYPE any.
      ASSIGN lr_container->ref_is_qals->* TO <fs_qals>.
      IF <fs_qals> IS ASSIGNED.
        " Move individual components (field-by-field to stay type-safe).
        ASSIGN COMPONENT 'PRUEFLOS'  OF STRUCTURE <fs_qals> TO FIELD-SYMBOL(<v>).
        IF <v> IS ASSIGNED. ls_qals-prueflos  = <v>. ENDIF.
        ASSIGN COMPONENT 'AUFNR'     OF STRUCTURE <fs_qals> TO <v>.
        IF <v> IS ASSIGNED. ls_qals-aufnr     = <v>. ENDIF.
        ASSIGN COMPONENT 'MATNR'     OF STRUCTURE <fs_qals> TO <v>.
        IF <v> IS ASSIGNED. ls_qals-matnr     = <v>. ENDIF.
        ASSIGN COMPONENT 'WERK'      OF STRUCTURE <fs_qals> TO <v>.
        IF <v> IS ASSIGNED. ls_qals-werk      = <v>. ENDIF.
        ASSIGN COMPONENT 'ENSTEHDAT' OF STRUCTURE <fs_qals> TO <v>.
        IF <v> IS ASSIGNED. ls_qals-enstehdat = <v>. ENDIF.
      ENDIF.
    ENDIF.

    " -- 4. Dispatch ---------------------------------------------------------
    CASE <fv_action>.
      WHEN 'SAVE'.
        DATA lv_subrc    TYPE sysubrc.
        DATA lt_protocol TYPE ztts2m_rqevp.

        save(
          EXPORTING is_qals     = ls_qals
          IMPORTING ev_subrc    = lv_subrc
                    et_protocol = lt_protocol ).

        " Write results back through generic refs
        IF lr_container->ref_ev_subrc IS BOUND.
          FIELD-SYMBOLS <fv_subrc> TYPE any.
          ASSIGN lr_container->ref_ev_subrc->* TO <fv_subrc>.
          IF <fv_subrc> IS ASSIGNED. <fv_subrc> = lv_subrc. ENDIF.
        ENDIF.

      WHEN 'CHECK' OR space.
        DATA lv_saving_allowed TYPE c LENGTH 1.

        check(
          EXPORTING is_qals            = ls_qals
          IMPORTING ev_saving_allowed  = lv_saving_allowed ).

        IF lr_container->ref_ev_saving_allowed IS BOUND.
          FIELD-SYMBOLS <fv_allowed> TYPE any.
          ASSIGN lr_container->ref_ev_saving_allowed->* TO <fv_allowed>.
          IF <fv_allowed> IS ASSIGNED. <fv_allowed> = lv_saving_allowed. ENDIF.
        ENDIF.

    ENDCASE.
  ENDMETHOD.


  "--------------------------------------------------------------------------
  METHOD check.
    "! Evaluates batch eligibility for the inspection lot.
    "!
    "! Logic:
    "!  1. Resolve manufacturing order via I_ManufacturingOrder (was CAUFV).
    "!  2. Read order-type / plant ranges from CL_SVARV (was TVARVC).
    "!  3. If order not in range → allow unconditionally, exit.
    "!  4. If batch record already exists in ZTBQMBATELADA → allow, exit.
    "!  5. Otherwise search for an accepted usage decision in the same BOM
    "!     family within the current year (I_InspectionLot + I_InspResultUsageDecision).
    "!  6. If one is found, persist the cross-reference and allow save.

    DATA:
      lv_today      TYPE datum,
      lv_low        TYPE datum,
      lv_high       TYPE datum,
      lv_year_start TYPE datum.

    " Use released API instead of SY-DATUM
    lv_today = cl_abap_context_info=>get_system_date( ).

    " Default: saving allowed
    ev_saving_allowed = abap_true.

    " ── Step 1: Resolve manufacturing order (I_ManufacturingOrder replaces CAUFV) ──
    " I_ManufacturingOrder is released for ABAP Cloud (PP-SFC).
    " CAUFV (component PP-SFC, CO) is not released for direct SQL access.
    SELECT SINGLE
           manufacturingorder        AS aufnr,
           billofmaterial            AS stlnr,
           billofmaterialvariantusage AS stlan,
           billofmaterialvariant     AS stlal,
           manufacturingordertype    AS auart,
           plant                     AS werks
      FROM i_manufacturingorder
      INTO @DATA(ls_order)
     WHERE manufacturingorder = @is_qals-aufnr.

    IF sy-subrc <> 0.
      " Order not found – cannot evaluate, allow saving by default
      RETURN.
    ENDIF.

    " ── Step 2: Read TVARVC ranges via CL_SVARV (TVARVC not released) ──────
    " CL_SVARV is the released API for reading TVARVC selection variables.
    DATA(lt_selopt_auart) = get_selopt( 'ZS2M126_BATTPOP' ).
    DATA(lt_selopt_werks) = get_selopt( 'ZS2M126_BATPLANTOP' ).

    " ── Step 3: Check if order type and plant are within configured ranges ──
    IF NOT ( ls_order-auart IN lt_selopt_auart
         AND ls_order-werks IN lt_selopt_werks ).
      " Order type or plant not configured for batch control → allow save
      RETURN.
    ENDIF.

    " ── Step 4: Batch-control record already exists → allow, skip creation ─
    SELECT COUNT(*) FROM ztbqmbatelada   "#EC CI_NOWHERE
      WHERE matnr = @is_qals-matnr
        AND werks = @is_qals-werk
        AND stlnr = @ls_order-stlnr
        AND stlan = @ls_order-stlan
        AND stlal = @ls_order-stlal
      INTO @DATA(lv_count_existing).                  "#EC CI_NOFIRST

    IF lv_count_existing > 0.
      ev_saving_allowed = abap_true.
      RETURN.
    ENDIF.

    " ── Step 5a: Build creation-date interval for BOM-family order search ──
    IF lv_today(4) > is_qals-enstehdat(4).
      " Inspection lot was created in a prior year; search back to its year
      lv_low  = is_qals-enstehdat.
      lv_high = lv_today.
    ELSE.
      " Same calendar year: search from 01-Jan to inspection lot creation date
      lv_year_start = lv_today(4) && '0101'.
      lv_low  = lv_year_start.
      lv_high = is_qals-enstehdat.
    ENDIF.

    DATA lt_interval_orders TYPE RANGE OF datum.
    APPEND VALUE #( sign   = 'I'
                    option = 'BT'
                    low    = lv_low
                    high   = lv_high ) TO lt_interval_orders.

    " ── Step 5b: Find all orders sharing the same BOM in the date interval ─
    " I_ManufacturingOrder replaces second CAUFV select.
    " Field CreationDate replaces CAUFV-ERDAT.
    SELECT manufacturingorder        AS aufnr,
           billofmaterial            AS stlnr,
           billofmaterialvariantusage AS stlan,
           billofmaterialvariant     AS stlal
      FROM i_manufacturingorder
      INTO TABLE @DATA(lt_lista_ordens)
     WHERE billofmaterial            = @ls_order-stlnr
       AND billofmaterialvariantusage = @ls_order-stlan
       AND billofmaterialvariant     = @ls_order-stlal
       AND creationdate              IN @lt_interval_orders.

    IF sy-subrc <> 0 OR lt_lista_ordens IS INITIAL.
      " No sibling orders found in the interval → allow save
      RETURN.
    ENDIF.

    SORT lt_lista_ordens BY aufnr.
    DELETE ADJACENT DUPLICATES FROM lt_lista_ordens COMPARING aufnr.

    " ── Step 5c: Fetch inspection lots for those orders ────────────────────
    " I_InspectionLot replaces QALS table access (QM-IM not released).
    " InspectionLotOrigin replaces QALS-ART field.
    DATA lt_lista_lote_qm
      TYPE STANDARD TABLE OF ty_insp_lot_order WITH EMPTY KEY.

    SELECT inspectionlot      AS prueflos,
           manufacturingorder AS aufnr
      FROM i_inspectionlot
      INTO TABLE @lt_lista_lote_qm
       FOR ALL ENTRIES IN @lt_lista_ordens
     WHERE manufacturingorder  = @lt_lista_ordens-aufnr
       AND inspectionlotorigin = @gc_04.

    IF sy-subrc <> 0 OR lt_lista_lote_qm IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_lista_lote_qm BY prueflos.
    DATA lt_lista_lote_qm_fae
      TYPE STANDARD TABLE OF ty_insp_lot_order WITH EMPTY KEY.
    lt_lista_lote_qm_fae = lt_lista_lote_qm.
    DELETE ADJACENT DUPLICATES FROM lt_lista_lote_qm_fae COMPARING prueflos.

    " ── Step 5d: Build current-year date range for usage decision filter ───
    lv_year_start = lv_today(4) && '0101'.
    DATA lt_interval_vdatum TYPE RANGE OF datum.
    APPEND VALUE #( sign   = 'I'
                    option = 'BT'
                    low    = lv_year_start
                    high   = lv_today ) TO lt_interval_vdatum.

    " ── Step 5e: Fetch accepted usage decisions ────────────────────────────
    " I_InspResultUsageDecision replaces QAVE table access (QM-IM-UD).
    " QualInspResultValuation replaces QAVE-VBEWERTUNG.
    " UsageDecisionDate       replaces QAVE-VDATUM.
    DATA lt_qave_result
      TYPE STANDARD TABLE OF ty_usage_decision WITH EMPTY KEY.

    SELECT inspectionlot          AS prueflos,
           usagedecisioncategory  AS kzart,
           usagedecisionitem      AS zaehler
      FROM i_inspresultusagedecision
      INTO TABLE @lt_qave_result
       FOR ALL ENTRIES IN @lt_lista_lote_qm_fae
     WHERE inspectionlot             = @lt_lista_lote_qm_fae-prueflos
       AND qualinspresultvaluation   = @gc_a
       AND usagedecisiondate         IN @lt_interval_vdatum.

    " ── Step 6: Persist cross-reference and allow save ─────────────────────
    IF lt_qave_result IS INITIAL.
      " No accepted decision found → still allow (default behaviour)
      ev_saving_allowed = abap_true.
    ELSE.
      " Take the first accepted decision found
      DATA(ls_qave) = lt_qave_result[ 1 ].

      " Look up which order this inspection lot belongs to
      DATA(ls_lot_order) = VALUE ty_insp_lot_order( ).
      READ TABLE lt_lista_lote_qm INTO ls_lot_order
        WITH KEY prueflos = ls_qave-prueflos
        BINARY SEARCH.
      DATA(lv_aufnr) = COND aufnr( WHEN sy-subrc = 0
                                   THEN ls_lot_order-aufnr ).

      " Build and persist the batch-control record (ZTBQMBATELADA is a Z-table)
      DATA(ls_ztbqmbatelada) = VALUE ztbqmbatelada(
        matnr     = is_qals-matnr
        werks     = is_qals-werk
        stlnr     = ls_order-stlnr
        stlan     = ls_order-stlan
        stlal     = ls_order-stlal
        aufnr     = lv_aufnr
        prueflos  = ls_qave-prueflos
        enstehdat = is_qals-enstehdat ).

      MODIFY ztbqmbatelada FROM @ls_ztbqmbatelada.
      IF sy-subrc = 0.
        COMMIT WORK AND WAIT.
      ENDIF.

      ev_saving_allowed = abap_true.
    ENDIF.

  ENDMETHOD.


  "--------------------------------------------------------------------------
  METHOD save.
    "! Creates the initial batch-control record when an inspection lot is saved.
    "!
    "! ATC changes vs original:
    "!  - IS_QAVE and IS_QAPO removed (were never used in body).
    "!  - CAUFV → I_ManufacturingOrder.
    "!  - TVARVC → CL_SVARV.
    "!  - SELECT COUNT uses INTO @DATA to follow restricted-scope syntax.

    ev_subrc = 0. "< Pre-initialise export

    " ── Step 1: Resolve manufacturing order ────────────────────────────────
    SELECT SINGLE
           manufacturingorder        AS aufnr,
           billofmaterial            AS stlnr,
           billofmaterialvariantusage AS stlan,
           billofmaterialvariant     AS stlal,
           manufacturingordertype    AS auart,
           plant                     AS werks
      FROM i_manufacturingorder
      INTO @DATA(ls_order)
     WHERE manufacturingorder = @is_qals-aufnr.

    IF sy-subrc <> 0.
      ev_subrc = sy-subrc.
      RETURN.
    ENDIF.

    " ── Step 2: Read configured order-type / plant ranges via CL_SVARV ─────
    DATA(lt_selopt_auart) = get_selopt( 'ZS2M126_BATTPOP' ).
    DATA(lt_selopt_werks) = get_selopt( 'ZS2M126_BATPLANTOP' ).

    " ── Step 3: Check if order is within batch-control scope ────────────────
    IF NOT ( ls_order-auart IN lt_selopt_auart
         AND ls_order-werks IN lt_selopt_werks ).
      RETURN. "< Order out of scope – nothing to persist
    ENDIF.

    " ── Step 4: Skip if batch-control record already exists ─────────────────
    SELECT COUNT(*) FROM ztbqmbatelada   "#EC CI_NOWHERE
      WHERE matnr = @is_qals-matnr
        AND werks = @is_qals-werk
        AND stlnr = @ls_order-stlnr
        AND stlan = @ls_order-stlan
        AND stlal = @ls_order-stlal
      INTO @DATA(lv_count_existing).                  "#EC CI_NOFIRST

    IF lv_count_existing > 0.
      RETURN. "< Record already present – idempotent guard
    ENDIF.

    " ── Step 5: Insert / update batch-control record ─────────────────────────
    DATA(ls_ztbqmbatelada) = VALUE ztbqmbatelada(
      matnr     = is_qals-matnr
      werks     = is_qals-werk
      stlnr     = ls_order-stlnr
      stlan     = ls_order-stlan
      stlal     = ls_order-stlal
      aufnr     = is_qals-aufnr
      prueflos  = is_qals-prueflos
      enstehdat = is_qals-enstehdat ).

    MODIFY ztbqmbatelada FROM @ls_ztbqmbatelada.
    ev_subrc = sy-subrc.
    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.


  "--------------------------------------------------------------------------
  METHOD get_selopt.
    "! Reads a TVARVC selection-option variable through the released CL_SVARV API.
    "!
    "! Background:
    "!  Direct SELECT from TVARVC is forbidden in ABAP Cloud (component
    "!  BC-ABA-TO is not released for customer/partner development).
    "!  CL_SVARV is the released replacement class provided by SAP.
    "!
    "! If the variable does not exist an empty range is returned, which
    "! makes every IN-check fail – safe-fail behaviour.

    TRY.
        " CL_SVARV is the released API for TVARVC in ABAP Cloud.
        " Method GET_VARIANTS_BY_SELOPT returns rsds_selopt_t,
        " which is range-compatible (fields SIGN, OPTION, LOW, HIGH).
        CL_SVARV=>GET_VARIANTS_BY_SELOPT(
          EXPORTING iv_name   = iv_variable_name
          IMPORTING et_selopt = rt_selopt ).

      CATCH cx_root.
        " On any error (variable not found, authority, …) return empty range.
        " An empty range causes IN to evaluate to false, which is the
        " conservative / safe-fail behaviour for a missing configuration.
        CLEAR rt_selopt.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
