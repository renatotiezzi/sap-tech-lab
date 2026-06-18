CLASS lhc_descarga DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setadminfields FOR DETERMINE ON SAVE
      IMPORTING keys FOR descarga~setadminfields.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR descarga RESULT result.
ENDCLASS.

CLASS lhc_descarga IMPLEMENTATION.

  METHOD get_instance_authorizations.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~get_instance_authorizations
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Autorizacao de instancia do BO de persistencia
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    " Autorizacao liberada no nivel do BO de persistencia.
    " O controle de quem pode executar cada etapa fica nas acoes do monitor.
    result = VALUE #( FOR key IN keys
                      ( %tky                 = key-%tky
                        %update              = if_abap_behv=>auth-allowed
                        %delete              = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.

  METHOD setadminfields.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~setadminfields
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Determination on save - campos de auditoria (idempotente)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*

    READ ENTITIES OF zi_q2c_descarga IN LOCAL MODE
      ENTITY descarga
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_descarga).

    DATA(lv_date) = cl_abap_context_info=>get_system_date( ).
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    DATA lt_update TYPE TABLE FOR UPDATE zi_q2c_descarga.

    LOOP AT lt_descarga INTO DATA(ls_descarga).

      DATA(lv_ernam) = COND #( WHEN ls_descarga-Ernam IS INITIAL THEN lv_user ELSE ls_descarga-Ernam ).
      DATA(lv_erdat) = COND #( WHEN ls_descarga-Erdat IS INITIAL THEN lv_date ELSE ls_descarga-Erdat ).

      IF ls_descarga-Ernam = lv_ernam AND
         ls_descarga-Erdat = lv_erdat AND
         ls_descarga-Aenam = lv_user  AND
         ls_descarga-Aedat = lv_date.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky           = ls_descarga-%tky
                      Ernam          = lv_ernam
                      Erdat          = lv_erdat
                      Aenam          = lv_user
                      Aedat          = lv_date
                      %control-Ernam = if_abap_behv=>mk-on
                      %control-Erdat = if_abap_behv=>mk-on
                      %control-Aenam = if_abap_behv=>mk-on
                      %control-Aedat = if_abap_behv=>mk-on ) TO lt_update.
    ENDLOOP.

    CHECK lt_update IS NOT INITIAL.

    MODIFY ENTITIES OF zi_q2c_descarga IN LOCAL MODE
      ENTITY descarga
      UPDATE FROM lt_update
      REPORTED DATA(lt_reported).
  ENDMETHOD.
ENDCLASS.
