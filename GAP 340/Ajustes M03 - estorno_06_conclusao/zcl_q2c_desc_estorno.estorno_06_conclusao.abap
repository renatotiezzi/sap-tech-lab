METHOD estorno_06_conclusao.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_06_conclusao
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 06 Conclusao (reabre TD -> 05)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.

    DATA: lv_budat_em   TYPE budat,
          lv_cur_period TYPE monat,
          lv_cur_year   TYPE gjahr.

    IF is_descarga-MblnrEm IS NOT INITIAL AND is_descarga-MjahrEm IS NOT INITIAL.
      SELECT SINGLE budat
        FROM mkpf
        WHERE mblnr = @is_descarga-MblnrEm
          AND mjahr = @is_descarga-MjahrEm
        INTO @lv_budat_em.

      IF sy-subrc = 0.
        SELECT SINGLE bukrs
          FROM t001w
          WHERE werks = @is_descarga-CentroDescarregamento
          INTO @DATA(lv_bukrs_06).

        IF sy-subrc = 0 AND lv_bukrs_06 IS NOT INITIAL.
          SELECT SINGLE lfmon, lfgja
            FROM mmrv
            WHERE bukrs = @lv_bukrs_06
            INTO (@lv_cur_period, @lv_cur_year).
        ENDIF.

        IF sy-subrc <> 0 OR
           lv_cur_year > lv_budat_em(4) OR
           ( lv_cur_year = lv_budat_em(4) AND lv_cur_period > lv_budat_em+4(2) ).
          APPEND VALUE #( type = 'E' message = 'Nao e possivel reabrir TD concluido, periodo contabil ja encerrado.'(032) ) TO et_return.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    MODIFY ENTITIES OF zi_q2c_descarga
      ENTITY descarga
      UPDATE FIELDS ( Status
                      TdichConf
                      TstmpConf
                      DtConf
                      HrConf
                      DtFim
                      HrFim
                      StatusTd
)
      WITH VALUE #( ( Shnumber    = is_descarga-Shnumber
                      Remessa     = is_descarga-Remessa
                      ItemRemessa = is_descarga-ItemRemessa
                      Status      = '05'
                      TdichConf   = space
                      TstmpConf   = space
                      DtConf      = '00000000'
                      HrConf      = '000000'
                      DtFim       = '00000000'
                      HrFim       = '000000'
                      StatusTd    = space
) )
      FAILED   DATA(ls_failed_06)
      REPORTED DATA(ls_reported_06).

    IF ls_failed_06-descarga IS NOT INITIAL.
      APPEND VALUE #( type = 'E' message = 'Falha ao reabrir o TD na ZDESCARGA.'(033) ) TO et_return.
      LOOP AT ls_reported_06-descarga INTO DATA(ls_rep_06).
        IF ls_rep_06-%msg IS BOUND.
          APPEND VALUE #( type = 'E' message = ls_rep_06-%msg->if_message~get_text( ) ) TO et_return.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    ev_status_novo = '05'.
    ev_sucesso     = abap_true.
    APPEND VALUE #( type = 'S' message = |{ 'TD'(034) } { is_descarga-Shnumber } { 'reaberto. Status retornado para 05.'(035) }| ) TO et_return.
  ENDMETHOD.
