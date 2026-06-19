METHOD estorno_02_amostra.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_02_amostra
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 02 Amostra (101 + lote QM -> 01)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.

    DATA: lv_budat_amostra TYPE budat,
          lv_mblnr_amostra TYPE mblnr,
          lv_mjahr_amostra TYPE mjahr,
          lv_doc_estorno   TYPE mblnr,
          lt_ret_bapi      TYPE bapiret2_t.

    lv_mblnr_amostra = is_descarga-DocMaterialAmostra.

    IF lv_mblnr_amostra IS INITIAL.
      APPEND VALUE #( type = 'E' message = 'Documento da amostra nao informado para estorno.'(006) ) TO et_return.
      RETURN.
    ENDIF.

    lv_budat_amostra = COND #( WHEN is_descarga-DtAmostra IS NOT INITIAL THEN is_descarga-DtAmostra ELSE sy-datum ).

    SELECT SINGLE mjahr
      FROM mkpf
      WHERE mblnr = @lv_mblnr_amostra
        AND budat = @lv_budat_amostra
      INTO @lv_mjahr_amostra.

    IF sy-subrc <> 0.
      APPEND VALUE #( type = 'E' message = |{ 'Nao foi possivel derivar o ano do documento'(007) } { lv_mblnr_amostra } { 'para estorno.'(036) }| ) TO et_return.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAPI_GOODSMVT_CANCEL_OIL'
      EXPORTING
        materialdocument = lv_mblnr_amostra
        matdocumentyear  = lv_mjahr_amostra
      TABLES
        return           = lt_ret_bapi.

    LOOP AT lt_ret_bapi INTO DATA(ls_ret_101) WHERE type CA 'EAX'.
      APPEND VALUE #( type = ls_ret_101-type message = ls_ret_101-message ) TO et_return.
      EXIT.
    ENDLOOP.

    READ TABLE lt_ret_bapi INTO DATA(ls_ret_ok_02) WITH KEY type = 'S'.
    IF sy-subrc = 0.
      FIND FIRST OCCURRENCE OF REGEX '\d{10}' IN ls_ret_ok_02-message SUBMATCHES lv_doc_estorno.
    ENDIF.

    IF et_return IS NOT INITIAL.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      RETURN.
    ENDIF.

    IF is_descarga-LoteQm IS NOT INITIAL.
      CLEAR lt_ret_bapi.

      IF is_descarga-DuQm IS INITIAL.
        CALL FUNCTION 'BAPI_INSPLOT_CANCEL'
          EXPORTING
            number = is_descarga-LoteQm
          TABLES
            return = lt_ret_bapi.
      ELSE.
        DATA(lv_ud_code) = VALUE zz1_8d05c26e3b4f-low( ).

        SELECT SINGLE low
          FROM zz1_8d05c26e3b4f
          WHERE name = 'ZQ2C340_UD_ESTORNO'
            AND type = 'P'
            AND numb = '1'
          INTO @lv_ud_code.

        IF lv_ud_code IS INITIAL.
          APPEND VALUE #( type = 'E' message = 'Parametro ZZ1_TVARVC_Q2C ZQ2C340_UD_ESTORNO nao configurado.'(041) ) TO et_return.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          RETURN.
        ENDIF.

        CALL FUNCTION 'BAPI_INSPLOT_USAGE_DECISION'
          EXPORTING
            inspectionlot = is_descarga-LoteQm
            ud_code       = lv_ud_code
          TABLES
            return        = lt_ret_bapi.
      ENDIF.

      LOOP AT lt_ret_bapi INTO DATA(ls_ret_qm) WHERE type CA 'EAX'.
        APPEND VALUE #( type = ls_ret_qm-type message = ls_ret_qm-message ) TO et_return.
        EXIT.
      ENDLOOP.

      IF et_return IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        RETURN.
      ENDIF.
    ENDIF.

    MODIFY ENTITIES OF zi_q2c_descarga
      ENTITY descarga
      UPDATE FIELDS ( Status
                      QtdAmostra
                      UmAmostra
                      Compartimento
                      PontoAmostragem
                      LgortAmostra
                      DocMaterialAmostra
                      LoteMaterialAmostra
                      UsuarioAmostra
                      LoteQm
                      DuQm
                      DtAmostra
                      HrAmostra
                      Aenam
                      Aedat
)
      WITH VALUE #( ( Shnumber            = is_descarga-Shnumber
                      Remessa             = is_descarga-Remessa
                      ItemRemessa         = is_descarga-ItemRemessa
                      Status              = '01'
                      QtdAmostra          = 0
                      UmAmostra           = space
                      Compartimento       = space
                      PontoAmostragem     = space
                      LgortAmostra        = space
                      DocMaterialAmostra  = space
                      LoteMaterialAmostra = space
                      UsuarioAmostra      = space
                      LoteQm              = space
                      DuQm                = space
                      DtAmostra           = '00000000'
                      HrAmostra           = '000000'
                      Aenam               = sy-uname
                      Aedat               = sy-datum
) )
      FAILED   DATA(ls_failed_02)
      REPORTED DATA(ls_reported_02).

    IF ls_failed_02-descarga IS NOT INITIAL.
      APPEND VALUE #( type = 'E' message = 'Falha ao atualizar a ZDESCARGA no estorno da amostra.'(009) ) TO et_return.
      LOOP AT ls_reported_02-descarga INTO DATA(ls_rep_02).
        IF ls_rep_02-%msg IS BOUND.
          APPEND VALUE #( type = 'E' message = ls_rep_02-%msg->if_message~get_text( ) ) TO et_return.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    ev_status_novo = '01'.
    ev_sucesso     = abap_true.
    ev_docs        = |101:{ lv_mblnr_amostra }/{ lv_mjahr_amostra };REV:{ lv_doc_estorno };QM:{ is_descarga-LoteQm }|.

    APPEND VALUE #( type = 'S' message = |{ 'Amostra do TD'(010) } { is_descarga-Shnumber } { 'estornada. Documento'(011) } { lv_mblnr_amostra } { 'cancelado e lote QM anulado.'(012) }| ) TO et_return.
  ENDMETHOD.
