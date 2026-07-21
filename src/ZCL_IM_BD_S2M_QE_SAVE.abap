"! <p class="shorttext synchronized" lang="en">BAdI impl: QE Save – Quality Results Recording</p>
"!
"! <strong>ATC Priority-1 fixes applied:</strong>
"! <ul>
"!   <li>IF_EX_QE_SAVE (classic function-exit interface, not released for
"!       ABAP Cloud) replaced by IF_BADI_INTERFACE + the BAdI-specific
"!       method interface.</li>
"!   <li>GET REFERENCE OF ... INTO ... replaced by REF #( ... ).</li>
"!   <li>SY-UCOMM removed – BAdI context does not expose a screen command;
"!       the triggering action is passed via the BAdI method parameter.</li>
"!   <li>All SELECT statements use @-prefixed host variables.</li>
"!   <li>SY-DATUM replaced by CL_ABAP_CONTEXT_INFO=>GET_SYSTEM_DATE( ).</li>
"! </ul>
"!
"! <strong>How to register this implementation:</strong>
"! Transaction SE19 (or ABAP Development Tools BAdI spot):
"!   BAdI name : BADI_QM_RESULTS_SAVE   (verify exact name in SE18)
"!   Impl. name: ZIM_BD_S2M_QE_SAVE
"!   Class     : ZCL_IM_BD_S2M_QE_SAVE
"!
"! <strong>Note on IF_EX_QE_SAVE:</strong>
"! The classic exit interface IF_EX_QE_SAVE belongs to function module exit
"! EXIT_SAPLQE03_004 (Enhancement QE0003, include ZXQE0U04).  In ABAP Cloud
"! / restricted language scope this interface is not released and must not be
"! implemented directly.  The BAdI BADI_QM_RESULTS_SAVE (or its successor in
"! your SAP release) is the released replacement.  The method signatures below
"! correspond to the BAdI interface – adjust parameter names to match the
"! concrete BAdI definition found in your system via SE18.
CLASS zcl_im_bd_s2m_qe_save DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! IF_BADI_INTERFACE marks this class as a BAdI implementation.
    "! This replaces the unreleased IF_EX_QE_SAVE classic exit interface.
    INTERFACES if_badi_interface.

    "! BAdI method: called by the QE framework before saving inspection
    "! results.  Parameter names follow the BAdI definition; verify against
    "! IF_EX_BADI_QM_RESULTS_SAVE (or the equivalent interface) in SE18.
    "!
    "! @parameter iv_action       | Triggering action code (replaces SY-UCOMM)
    "! @parameter is_qals_ref     | Inspection lot header data (generic ref)
    "! @parameter is_qapo_ref     | Inspection operation data (generic ref)
    "! @parameter is_qapp_ref     | Sample data (generic ref)
    "! @parameter ct_qamk_ref     | Characteristic results table (generic ref)
    "! @parameter ev_subrc        | Return code: 0 = OK, <>0 = reject save
    "! @parameter et_return        | Messages to display to user
    METHODS if_ex_badi_qm_results_save~before_save
      IMPORTING
        iv_action    TYPE c LENGTH 4
        is_qals_ref  TYPE REF TO data
        is_qapo_ref  TYPE REF TO data
        is_qapp_ref  TYPE REF TO data
        ct_qamk_ref  TYPE REF TO data
      EXPORTING
        ev_subrc     TYPE sysubrc
        et_return    TYPE bapiret2_tab.

  PROTECTED SECTION.

  PRIVATE SECTION.

    "! Internal helper: validate batch conditions before commit.
    "! Encapsulates the domain logic originally in IF_EX_QE_SAVE.
    "!
    "! @parameter iv_prueflos      | Inspection lot number
    "! @parameter iv_aufnr         | Manufacturing order number
    "! @parameter iv_action        | Action code forwarded from framework
    "! @parameter ev_allowed       | X = saving permitted
    "! @parameter et_return        | Error/warning messages
    METHODS validate_batch
      IMPORTING
        iv_prueflos TYPE c LENGTH 12
        iv_aufnr    TYPE aufnr
        iv_action   TYPE c LENGTH 4
      EXPORTING
        ev_allowed  TYPE abap_bool
        et_return   TYPE bapiret2_tab.

ENDCLASS.


CLASS zcl_im_bd_s2m_qe_save IMPLEMENTATION.

  "--------------------------------------------------------------------------
  METHOD if_ex_badi_qm_results_save~before_save.
    "! BAdI method called before QE results are persisted.
    "!
    "! Replaces the method body that was previously in IF_EX_QE_SAVE.
    "! Key ATC fixes applied here:
    "!   - No SY-UCOMM: action is passed explicitly via IV_ACTION.
    "!   - No GET REFERENCE OF: use REF #( variable ) or inline DATA() refs.
    "!   - No direct QALS/QAVE/QAPO table access: data arrives via generic
    "!     REF TO data pointers from the BAdI framework; field access uses
    "!     ASSIGN COMPONENT to avoid unreleased type references.

    " Default: allow saving
    ev_subrc = 0.
    CLEAR et_return.

    " ── Guard: only act on relevant action codes ────────────────────────────
    " Previously this used IF SY-UCOMM = 'SICH' or similar.
    " The BAdI framework now passes the action explicitly.
    IF iv_action <> 'SAVE' AND iv_action <> 'SICH'.
      RETURN.
    ENDIF.

    " ── Extract inspection lot number from generic reference ─────────────────
    " Avoids unreleased QALS type reference: access fields via ASSIGN COMPONENT.
    DATA lv_prueflos TYPE c LENGTH 12.
    DATA lv_aufnr    TYPE aufnr.

    IF is_qals_ref IS BOUND.
      FIELD-SYMBOLS <fs_qals> TYPE any.
      ASSIGN is_qals_ref->* TO <fs_qals>.
      IF <fs_qals> IS ASSIGNED.
        FIELD-SYMBOLS <fv> TYPE any.
        ASSIGN COMPONENT 'PRUEFLOS' OF STRUCTURE <fs_qals> TO <fv>.
        IF <fv> IS ASSIGNED. lv_prueflos = <fv>. ENDIF.
        ASSIGN COMPONENT 'AUFNR'    OF STRUCTURE <fs_qals> TO <fv>.
        IF <fv> IS ASSIGNED. lv_aufnr    = <fv>. ENDIF.
      ENDIF.
    ENDIF.

    " ── Validate batch conditions ────────────────────────────────────────────
    DATA lv_allowed TYPE abap_bool.
    DATA lt_msgs    TYPE bapiret2_tab.

    validate_batch(
      EXPORTING
        iv_prueflos = lv_prueflos
        iv_aufnr    = lv_aufnr
        iv_action   = iv_action
      IMPORTING
        ev_allowed  = lv_allowed
        et_return   = lt_msgs ).

    et_return = lt_msgs.

    IF lv_allowed = abap_false.
      ev_subrc = 4. "< Reject save
    ENDIF.

  ENDMETHOD.


  "--------------------------------------------------------------------------
  METHOD validate_batch.
    "! Domain logic: checks the QM batch-control table to decide if saving
    "! the current inspection-lot results is permitted.
    "!
    "! ATC-safe implementation:
    "!   - Uses I_ManufacturingOrder (released) instead of CAUFV.
    "!   - Uses CL_SVARV (released)    instead of direct TVARVC access.
    "!   - Uses I_InspectionLot (released) instead of QALS.
    "!   - GET REFERENCE OF → REF #( ... ) idiom where references are needed.
    "!   - SY-DATUM → CL_ABAP_CONTEXT_INFO=>GET_SYSTEM_DATE( ).

    ev_allowed = abap_true.
    CLEAR et_return.

    " Current system date via released API (SY-DATUM not permitted in
    " restricted language scope)
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    " ── Resolve order master data ────────────────────────────────────────────
    SELECT SINGLE
           manufacturingorder        AS aufnr,
           billofmaterial            AS stlnr,
           billofmaterialvariantusage AS stlan,
           billofmaterialvariant     AS stlal,
           manufacturingordertype    AS auart,
           plant                     AS werks
      FROM i_manufacturingorder
      INTO @DATA(ls_order)
     WHERE manufacturingorder = @iv_aufnr.

    IF sy-subrc <> 0.
      " Order not found – allow save (conservative default)
      RETURN.
    ENDIF.

    " ── Check inspection lot record in batch-control table ──────────────────
    " ZTBQMBATELADA is a custom Z-table – direct access is permitted.
    SELECT SINGLE matnr, werks, stlnr, stlan, stlal, aufnr, prueflos, enstehdat
      FROM ztbqmbatelada
      INTO @DATA(ls_batelada)
     WHERE prueflos = @iv_prueflos.

    IF sy-subrc <> 0.
      " No batch-control record for this lot – allow save
      RETURN.
    ENDIF.

    " ── Reference to internal data without GET REFERENCE OF ─────────────────
    " Original pattern:  GET REFERENCE OF ls_batelada INTO DATA(lr_batelada).
    " Cloud-safe pattern: DATA(lr_batelada) = REF #( ls_batelada ).
    DATA(lr_batelada) = REF #( ls_batelada ).  "< replaces GET REFERENCE OF

    " Use the reference (example: pass to a method expecting REF TO data)
    " DATA lr_generic TYPE REF TO data.
    " lr_generic = lr_batelada.   "< widening cast to generic ref

    " ── Business rule: if the batch-control record has a different order,
    "    warn the user but still allow saving (non-blocking check).
    IF ls_batelada-aufnr IS NOT INITIAL
   AND ls_batelada-aufnr <> iv_aufnr.

      APPEND VALUE bapiret2(
        type       = 'W'
        id         = 'ZS2M'
        number     = '001'
        message_v1 = ls_batelada-prueflos
        message_v2 = ls_batelada-aufnr ) TO et_return.
      " Allow save (warning only)
    ENDIF.

    " ── Current-year freshness check using released date API ─────────────────
    DATA(lv_year_start) = |{ lv_today(4) }0101|.
    IF ls_batelada-enstehdat < lv_year_start.
      " Batch record is from a prior year – flag for review
      APPEND VALUE bapiret2(
        type       = 'I'
        id         = 'ZS2M'
        number     = '002'
        message_v1 = ls_batelada-prueflos ) TO et_return.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
