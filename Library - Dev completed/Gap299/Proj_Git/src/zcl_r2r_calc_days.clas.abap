CLASS zcl_r2r_calc_days DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  INTERFACES if_sadl_exit_calc_element_read.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_r2r_calc_days IMPLEMENTATION.
METHOD if_sadl_exit_calc_element_read~calculate.
*--------------------------------------------------------------------*
* Program       : if_sadl_exit_calc_element_read~calculate
* Program Type  : Method
* Frequency     : N/A
* Processing    : Foreground/Background
* Author        : RTiezzi
* Creation Date : 07/01/2026
* Gap ID        : 299
* Description   : Relatório de Débito(Cliente)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request/ChaRM    Description
* 000 07/01/2025 Rtiezzi  DS4K906021       Initial Version
*--------------------------------------------------------------------*

    DATA lt_data TYPE STANDARD TABLE OF zc_r2r_ar_position WITH EMPTY KEY.

    lt_data = CORRESPONDING #( it_original_data ).

    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<fs_row>).
      DATA: lv_begda TYPE d,
            lv_endda TYPE d,
            lv_days  TYPE i.

      IF <fs_row>-NetDueDate IS NOT INITIAL.
        lv_begda = <fs_row>-NetDueDate + 1.
      ENDIF.

      IF <fs_row>-ClearingJournalEntry IS INITIAL.
        lv_endda = cl_abap_context_info=>get_system_date( ).
      ELSE.
        lv_endda = <fs_row>-ClearingDate.
      ENDIF.

      IF lv_begda IS NOT INITIAL AND lv_endda IS NOT INITIAL.
        CALL FUNCTION 'HR_99S_INTERVAL_BETWEEN_DATES'
          EXPORTING
            begda = lv_begda
            endda = lv_endda
          IMPORTING
            days  = lv_days.

        <fs_row>-DaysOverdue = lv_days.
      ENDIF.
    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( lt_data ).

  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
*--------------------------------------------------------------------*
* Program       : if_sadl_exit_calc_element_read~get_calculation_info
* Program Type  : Method
* Frequency     : N/A
* Processing    : Foreground/Background
* Author        : RTiezzi
* Creation Date : 07/01/2026
* Gap ID        : 299
* Description   : Relatório de Débito(Cliente)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request/ChaRM    Description
* 000 07/01/2025 Rtiezzi  DS4K906021       Initial Version
*--------------------------------------------------------------------*

    INSERT conv #( 'NETDUEDATE' )           INTO TABLE et_requested_orig_elements.
    INSERT conv #( 'CLEARINGDATE' )         INTO TABLE et_requested_orig_elements.
    INSERT conv #( 'CLEARINGJOURNALENTRY' ) INTO TABLE et_requested_orig_elements.

  ENDMETHOD.
ENDCLASS.
