CLASS zcl_q2c_desc_estorno DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS pode_estornar
      IMPORTING
        is_descarga   TYPE zi_q2c_descarga
      RETURNING
        VALUE(rv_ok)  TYPE abap_bool.

    METHODS realizar_estorno
      IMPORTING
        iv_shnumber     TYPE oig_shnum
        iv_remessa      TYPE vbeln_vl
        iv_item_remessa TYPE posnr_vl
      EXPORTING
        et_return       TYPE bapiret2_t
        ev_sucesso      TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS estorno_01_chegada
      IMPORTING
        is_descarga      TYPE zi_q2c_descarga
      EXPORTING
        et_return        TYPE bapiret2_t
        ev_sucesso       TYPE abap_bool
        ev_status_novo   TYPE zdeq2c_desc_status
        ev_docs          TYPE char255.

    METHODS estorno_02_amostra
      IMPORTING is_descarga    TYPE zi_q2c_descarga
      EXPORTING et_return      TYPE bapiret2_t
                ev_sucesso     TYPE abap_bool
                ev_status_novo TYPE zdeq2c_desc_status
                ev_docs        TYPE char255.

    METHODS estorno_03_tanque
      IMPORTING is_descarga    TYPE zi_q2c_descarga
      EXPORTING et_return      TYPE bapiret2_t
                ev_sucesso     TYPE abap_bool
                ev_status_novo TYPE zdeq2c_desc_status
                ev_docs        TYPE char255.

    METHODS estorno_04_medicao
      IMPORTING is_descarga    TYPE zi_q2c_descarga
      EXPORTING et_return      TYPE bapiret2_t
                ev_sucesso     TYPE abap_bool
                ev_status_novo TYPE zdeq2c_desc_status
                ev_docs        TYPE char255.

    METHODS estorno_05_entrada_merc
      IMPORTING is_descarga    TYPE zi_q2c_descarga
      EXPORTING et_return      TYPE bapiret2_t
                ev_sucesso     TYPE abap_bool
                ev_status_novo TYPE zdeq2c_desc_status
                ev_docs        TYPE char255.

    METHODS estorno_06_conclusao
      IMPORTING is_descarga    TYPE zi_q2c_descarga
      EXPORTING et_return      TYPE bapiret2_t
                ev_sucesso     TYPE abap_bool
                ev_status_novo TYPE zdeq2c_desc_status
                ev_docs        TYPE char255.

    METHODS gravar_log
      IMPORTING
        is_descarga     TYPE zi_q2c_descarga
        iv_status_novo  TYPE zdeq2c_desc_status
        iv_docs         TYPE char255
        iv_tipo_msg     TYPE char1
        iv_mensagem     TYPE char255.

ENDCLASS.



CLASS zcl_q2c_desc_estorno IMPLEMENTATION.

  METHOD pode_estornar.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~pode_estornar
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Valida autorizacao p/ estornar (autor OU supervisor)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    rv_ok = abap_false.

    "Supervisor
    AUTHORITY-CHECK OBJECT 'ZQ2C_DESC' ID 'ACTVT' FIELD '85'.
    IF sy-subrc = 0.
      rv_ok = abap_true.
      RETURN.
    ENDIF.

    DATA(lv_autor) = SWITCH uname( is_descarga-Status
                                   WHEN '01' THEN is_descarga-UsuarioChegada
                                   WHEN '02' THEN is_descarga-UsuarioAmostra
                                   WHEN '04' THEN is_descarga-UsuarioMedicao
                                   ELSE space ).

    IF lv_autor IS NOT INITIAL AND lv_autor = sy-uname.
      rv_ok = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD realizar_estorno.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~realizar_estorno
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Orquestrador do estorno (reversao LIFO)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso.

    SELECT SINGLE * FROM zi_q2c_descarga
      WHERE Shnumber    = @iv_shnumber
        AND Remessa     = @iv_remessa
        AND ItemRemessa = @iv_item_remessa
      INTO @DATA(ls_desc).

    IF sy-subrc <> 0.
      APPEND VALUE #( type = 'E' message = 'Registro de descarga nao encontrado.'(004) ) TO et_return.
      RETURN.
    ENDIF.

    IF ls_desc-Status NOT IN VALUE rsdsselopt_t(
         sign = 'I' option = 'BT' ( low = '01' high = '06' ) ).
      APPEND VALUE #( type = 'E' message = 'TD nao esta em status estornavel.'(002) ) TO et_return.
      RETURN.
    ENDIF.

    IF pode_estornar( ls_desc ) = abap_false.
      APPEND VALUE #( type = 'E' message = 'Sem autorizacao p/ estornar este passo.'(003) ) TO et_return.
      RETURN.
    ENDIF.

    DATA: lt_ret      TYPE bapiret2_t,
          lv_ok       TYPE abap_bool,
          lv_st_novo  TYPE zdeq2c_desc_status,
          lv_docs     TYPE char255.

    CASE ls_desc-Status.
      WHEN '01'.
        estorno_01_chegada( EXPORTING is_descarga = ls_desc
                            IMPORTING et_return = lt_ret ev_sucesso = lv_ok
                                      ev_status_novo = lv_st_novo ev_docs = lv_docs ).
      WHEN '02'.
        estorno_02_amostra( EXPORTING is_descarga = ls_desc
                            IMPORTING et_return = lt_ret ev_sucesso = lv_ok
                                      ev_status_novo = lv_st_novo ev_docs = lv_docs ).
      WHEN '03'.
        estorno_03_tanque( EXPORTING is_descarga = ls_desc
                           IMPORTING et_return = lt_ret ev_sucesso = lv_ok
                                     ev_status_novo = lv_st_novo ev_docs = lv_docs ).
      WHEN '04'.
        estorno_04_medicao( EXPORTING is_descarga = ls_desc
                            IMPORTING et_return = lt_ret ev_sucesso = lv_ok
                                      ev_status_novo = lv_st_novo ev_docs = lv_docs ).
      WHEN '05'.
        estorno_05_entrada_merc( EXPORTING is_descarga = ls_desc
                                 IMPORTING et_return = lt_ret ev_sucesso = lv_ok
                                           ev_status_novo = lv_st_novo ev_docs = lv_docs ).
      WHEN '06'.
        estorno_06_conclusao( EXPORTING is_descarga = ls_desc
                              IMPORTING et_return = lt_ret ev_sucesso = lv_ok
                                        ev_status_novo = lv_st_novo ev_docs = lv_docs ).
    ENDCASE.

    et_return  = lt_ret.
    ev_sucesso = lv_ok.

    DATA(lv_msg) = COND char255( WHEN lt_ret IS NOT INITIAL THEN lt_ret[ 1 ]-message ELSE space ).
    gravar_log( is_descarga    = ls_desc
                iv_status_novo = COND #( WHEN lv_ok = abap_true THEN lv_st_novo ELSE ls_desc-Status )
                iv_docs        = lv_docs
                iv_tipo_msg    = COND #( WHEN lv_ok = abap_true THEN 'S' ELSE 'E' )
                iv_mensagem    = lv_msg ).
  ENDMETHOD.

  METHOD estorno_01_chegada.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_01_chegada
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 01 Chegada (DELETE da linha -> 00)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.

    MODIFY ENTITIES OF zi_q2c_descarga
      ENTITY descarga
      DELETE FROM VALUE #( ( Shnumber    = is_descarga-Shnumber
                             Remessa     = is_descarga-Remessa
                             ItemRemessa = is_descarga-ItemRemessa ) )
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-descarga IS NOT INITIAL.
      APPEND VALUE #( type = 'E' message = 'Falha ao excluir registro de descarga.'(005) ) TO et_return.
      LOOP AT ls_reported-descarga INTO DATA(ls_rep).
        IF ls_rep-%msg IS BOUND.
          APPEND VALUE #( type = 'E' message = ls_rep-%msg->if_message~get_text( ) ) TO et_return.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    ev_status_novo = '00'.
    ev_sucesso     = abap_true.
    APPEND VALUE #( type = 'S' message = 'Estorno da chegada realizado.'(001) ) TO et_return.
  ENDMETHOD.

  METHOD estorno_02_amostra.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_02_amostra
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 02 Amostra (a implementar)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.
    APPEND VALUE #( type = 'E' message = 'Estorno deste passo nao implementado.'(006) ) TO et_return.
  ENDMETHOD.

  METHOD estorno_03_tanque.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_03_tanque
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 03 Tanque (a implementar)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.
    APPEND VALUE #( type = 'E' message = 'Estorno deste passo nao implementado.'(006) ) TO et_return.
  ENDMETHOD.

  METHOD estorno_04_medicao.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_04_medicao
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 04 Medicao (a implementar)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.
    APPEND VALUE #( type = 'E' message = 'Estorno deste passo nao implementado.'(006) ) TO et_return.
  ENDMETHOD.

  METHOD estorno_05_entrada_merc.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_05_entrada_merc
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 05 Entrada Merc.+311 (a implementar)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.
    APPEND VALUE #( type = 'E' message = 'Estorno deste passo nao implementado.'(006) ) TO et_return.
  ENDMETHOD.

  METHOD estorno_06_conclusao.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_06_conclusao
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 06 Conclusao (a implementar)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.
    APPEND VALUE #( type = 'E' message = 'Estorno deste passo nao implementado.'(006) ) TO et_return.
  ENDMETHOD.

  METHOD gravar_log.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~gravar_log
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Grava entrada no log de estornos (ZTBQ2C_LOG_EST)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    DATA lv_uuid TYPE sysuuid_x16.
    TRY.
        lv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        CLEAR lv_uuid.
    ENDTRY.

    GET TIME STAMP FIELD DATA(lv_ts).

    INSERT ztbq2c_log_est FROM @( VALUE #(
      log_id          = lv_uuid
      shnumber        = is_descarga-Shnumber
      remessa         = is_descarga-Remessa
      item_remessa    = is_descarga-ItemRemessa
      status_anterior = is_descarga-Status
      status_novo     = iv_status_novo
      docs_estornados = iv_docs
      tipo_msg        = iv_tipo_msg
      mensagem        = iv_mensagem
      usuario         = sy-uname
      criado_em       = lv_ts ) ).
  ENDMETHOD.

ENDCLASS.
