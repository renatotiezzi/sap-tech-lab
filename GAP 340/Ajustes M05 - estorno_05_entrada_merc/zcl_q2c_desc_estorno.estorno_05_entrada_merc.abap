
  METHOD estorno_05_entrada_merc.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_05_entrada_merc
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 05 Entrada Merc.+311 (reversao fisica -> 04)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.

    DATA: lv_budat_em     TYPE budat,
          lv_cur_period   TYPE monat,
          lv_cur_year     TYPE gjahr,
          lv_bukrs        TYPE bukrs,
          lv_doc          TYPE mblnr,
          lv_mjahr_doc    TYPE mjahr,
          lv_material_ant TYPE matnr,
          lv_mblnr_311    TYPE mblnr,
          lv_mjahr_311    TYPE mjahr,
          lv_mblnr_em     TYPE mblnr,
          lv_mjahr_em     TYPE mjahr,
          lv_mblnr_extra  TYPE mblnr,
          lv_mjahr_extra  TYPE mjahr,
          lv_doc_estorno  TYPE mblnr,
          lt_ret_bapi     TYPE bapiret2_t,
          lt_docs_rev     TYPE STANDARD TABLE OF char50 WITH EMPTY KEY,
          lt_perdas       TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    " Pre-validacao de periodo contabil por empresa do centro.
    SELECT SINGLE bukrs
      FROM t001w
      WHERE werks = @is_descarga-CentroDescarregamento
      INTO @lv_bukrs.

    IF sy-subrc <> 0 OR lv_bukrs IS INITIAL.
      APPEND VALUE #( type = 'E' message = |{ 'Nao e possivel estornar, periodo contabil'(019) } { is_descarga-CentroDescarregamento } { 'ja encerrado.'(020) }| ) TO et_return.
      RETURN.
    ENDIF.

    lv_mblnr_em = is_descarga-MblnrEm.
    lv_mjahr_em = is_descarga-MjahrEm.

    IF lv_mblnr_em IS NOT INITIAL AND lv_mjahr_em IS NOT INITIAL.
      SELECT SINGLE budat
        FROM mkpf
        WHERE mblnr = @lv_mblnr_em
          AND mjahr = @lv_mjahr_em
        INTO @lv_budat_em.

      IF sy-subrc = 0.
        APPEND VALUE #( type = 'E' message = 'Pendencia tecnica: validar API/CDS liberada para periodo contabil MM (substituir MMRV).'(042) ) TO et_return.
        RETURN.
      ENDIF.
    ENDIF.

    " Pre-validacao de tanque reusado por TD posterior (fallback via ZDESCARGA, pendencia P5).
    SELECT SINGLE shnumber
      FROM ztbq2c_descarga
      WHERE centro_descarregamento = @is_descarga-CentroDescarregamento
        AND lgort_destino          = @is_descarga-LgortDestino
        AND status                 IN ('05', '06')
        AND shnumber               <> @is_descarga-Shnumber
        AND ( dt_em > @is_descarga-DtEm
           OR ( dt_em = @is_descarga-DtEm AND hr_em > @is_descarga-HrEm ) )
      INTO @DATA(lv_td_posterior).

    IF sy-subrc = 0.
      APPEND VALUE #( type = 'E' message = |{ 'Nao e possivel estornar, o tanque'(021) } { is_descarga-LgortDestino } { 'ja recebeu descarga posterior do TD'(022) } { lv_td_posterior }.| ) TO et_return.
      RETURN.
    ENDIF.

    " Passo 1: cancela 311.
    lv_mblnr_311 = is_descarga-Mblnr311.
    IF lv_mblnr_311 IS NOT INITIAL.
      " P1: derivacao de MJAHR para docs sem ano persistido na ZDESCARGA.
      DATA(lv_budat_311) = COND budat( WHEN is_descarga-DtTransf IS NOT INITIAL THEN is_descarga-DtTransf ELSE sy-datum ).
      SELECT SINGLE mjahr
        FROM mkpf
        WHERE mblnr = @lv_mblnr_311
          AND budat = @lv_budat_311
        INTO @lv_mjahr_311.

      IF sy-subrc <> 0.
        APPEND VALUE #( type = 'E' message = |{ 'Falha no estorno do mov. 311:'(024) } { 'Nao foi possivel derivar o ano do documento'(007) } { lv_mblnr_311 } { 'para estorno.'(036) }| ) TO et_return.
        RETURN.
      ENDIF.

      CLEAR lt_ret_bapi.
      cancelar_doc_bapi(
        EXPORTING
          iv_mblnr       = lv_mblnr_311
          iv_mjahr       = lv_mjahr_311
        IMPORTING
          ev_ok          = DATA(lv_ok_311)
          ev_doc_estorno = lv_doc_estorno
          et_return      = lt_ret_bapi ).

      LOOP AT lt_ret_bapi INTO DATA(ls_ret_311) WHERE type CA 'EAX'.
        APPEND VALUE #( type = 'E' message = |{ 'Falha no estorno do mov. 311:'(024) } { ls_ret_311-message }| ) TO et_return.
        EXIT.
      ENDLOOP.

      IF et_return IS NOT INITIAL.
        DATA(lv_docs_fail_311) = build_docs_estornados( lt_docs_rev ).
        APPEND VALUE #( type = 'E' message = |{ 'Documentos estornados com sucesso ate a falha:'(038) } { COND string( WHEN lv_docs_fail_311 IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_311 ) }.| ) TO et_return.
        APPEND VALUE #( type = 'E' message = 'Contate o suporte para reconciliacao manual antes de nova tentativa de estorno.'(039) ) TO et_return.
        ev_docs = COND #( WHEN lv_docs_fail_311 IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_311 ).
        RETURN.
      ENDIF.

      APPEND |311:{ lv_mblnr_311 }/{ lv_mjahr_311 }->{ lv_doc_estorno }| TO lt_docs_rev.
    ENDIF.

    " Passo 2: cancela 101 da EM.
    IF lv_mblnr_em IS NOT INITIAL AND lv_mjahr_em IS NOT INITIAL.
      CLEAR lt_ret_bapi.
      cancelar_doc_bapi(
        EXPORTING
          iv_mblnr       = lv_mblnr_em
          iv_mjahr       = lv_mjahr_em
        IMPORTING
          ev_ok          = DATA(lv_ok_em)
          ev_doc_estorno = lv_doc_estorno
          et_return      = lt_ret_bapi ).

      LOOP AT lt_ret_bapi INTO DATA(ls_ret_101_em) WHERE type CA 'EAX'.
        APPEND VALUE #( type = 'E' message = |{ 'Falha no estorno do mov. 101 (EM):'(037) } { ls_ret_101_em-message }| ) TO et_return.
        EXIT.
      ENDLOOP.

      IF et_return IS NOT INITIAL.
        DATA(lv_docs_fail_em) = build_docs_estornados( lt_docs_rev ).
        APPEND VALUE #( type = 'E' message = |{ 'Documentos estornados com sucesso ate a falha:'(038) } { COND string( WHEN lv_docs_fail_em IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_em ) }.| ) TO et_return.
        APPEND VALUE #( type = 'E' message = 'Contate o suporte para reconciliacao manual antes de nova tentativa de estorno.'(039) ) TO et_return.
        ev_docs = COND #( WHEN lv_docs_fail_em IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_em ).
        RETURN.
      ENDIF.

      APPEND |101EM:{ lv_mblnr_em }/{ lv_mjahr_em }->{ lv_doc_estorno }| TO lt_docs_rev.
    ENDIF.

    " Passo 3: cancela 101 volume extra drenado.
    IF is_descarga-VolumeExtraDrenado > 0 AND is_descarga-DocMaterialExtraDrenado IS NOT INITIAL.
      lv_mblnr_extra = is_descarga-DocMaterialExtraDrenado.

      DATA(lv_budat_extra) = COND budat( WHEN is_descarga-DtEm IS NOT INITIAL THEN is_descarga-DtEm ELSE sy-datum ).
      SELECT SINGLE mjahr
        FROM mkpf
        WHERE mblnr = @lv_mblnr_extra
          AND budat = @lv_budat_extra
        INTO @lv_mjahr_extra.

      IF sy-subrc <> 0.
        APPEND VALUE #( type = 'E' message = |{ 'Falha no estorno do mov. extra drenado:'(026) } { 'Nao foi possivel derivar o ano do documento'(007) } { lv_mblnr_extra } { 'para estorno.'(036) }| ) TO et_return.
        DATA(lv_docs_fail_extra_y) = build_docs_estornados( lt_docs_rev ).
        APPEND VALUE #( type = 'E' message = |{ 'Documentos estornados com sucesso ate a falha:'(038) } { COND string( WHEN lv_docs_fail_extra_y IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_extra_y ) }.| ) TO et_return.
        APPEND VALUE #( type = 'E' message = 'Contate o suporte para reconciliacao manual antes de nova tentativa de estorno.'(039) ) TO et_return.
        ev_docs = COND #( WHEN lv_docs_fail_extra_y IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_extra_y ).
        RETURN.
      ENDIF.

      CLEAR lt_ret_bapi.
      cancelar_doc_bapi(
        EXPORTING
          iv_mblnr       = lv_mblnr_extra
          iv_mjahr       = lv_mjahr_extra
        IMPORTING
          ev_ok          = DATA(lv_ok_extra)
          ev_doc_estorno = lv_doc_estorno
          et_return      = lt_ret_bapi ).

      LOOP AT lt_ret_bapi INTO DATA(ls_ret_extra) WHERE type CA 'EAX'.
        APPEND VALUE #( type = 'E' message = |{ 'Falha no estorno do mov. extra drenado:'(026) } { ls_ret_extra-message }| ) TO et_return.
        EXIT.
      ENDLOOP.

      IF et_return IS NOT INITIAL.
        DATA(lv_docs_fail_extra) = build_docs_estornados( lt_docs_rev ).
        APPEND VALUE #( type = 'E' message = |{ 'Documentos estornados com sucesso ate a falha:'(038) } { COND string( WHEN lv_docs_fail_extra IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_extra ) }.| ) TO et_return.
        APPEND VALUE #( type = 'E' message = 'Contate o suporte para reconciliacao manual antes de nova tentativa de estorno.'(039) ) TO et_return.
        ev_docs = COND #( WHEN lv_docs_fail_extra IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_extra ).
        RETURN.
      ENDIF.

      APPEND |101EXTRA:{ lv_mblnr_extra }/{ lv_mjahr_extra }->{ lv_doc_estorno }| TO lt_docs_rev.
    ENDIF.

    " Passo 4: cancela perdas/sobras (lista separada por virgula).
    IF is_descarga-DocPerdasSobras IS NOT INITIAL.
      SPLIT is_descarga-DocPerdasSobras AT ',' INTO TABLE lt_perdas.

      LOOP AT lt_perdas INTO DATA(lv_doc_raw).
        DATA(lv_doc_txt) = lv_doc_raw.
        CONDENSE lv_doc_txt.
        lv_doc = lv_doc_txt.
        CHECK lv_doc IS NOT INITIAL.

        DATA(lv_budat_perda) = COND budat( WHEN is_descarga-DtEm IS NOT INITIAL THEN is_descarga-DtEm ELSE sy-datum ).
        SELECT SINGLE mjahr
          FROM mkpf
          WHERE mblnr = @lv_doc
            AND budat = @lv_budat_perda
          INTO @lv_mjahr_doc.

        IF sy-subrc <> 0.
          APPEND VALUE #( type = 'E' message = |{ 'Falha no estorno de perdas/sobras:'(028) } { 'Nao foi possivel derivar o ano do documento'(007) } { lv_doc } { 'para estorno.'(036) }| ) TO et_return.
          DATA(lv_docs_fail_perda_y) = build_docs_estornados( lt_docs_rev ).
          APPEND VALUE #( type = 'E' message = |{ 'Documentos estornados com sucesso ate a falha:'(038) } { COND string( WHEN lv_docs_fail_perda_y IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_perda_y ) }.| ) TO et_return.
          APPEND VALUE #( type = 'E' message = 'Contate o suporte para reconciliacao manual antes de nova tentativa de estorno.'(039) ) TO et_return.
          ev_docs = COND #( WHEN lv_docs_fail_perda_y IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_perda_y ).
          RETURN.
        ENDIF.

        CLEAR lt_ret_bapi.
        cancelar_doc_bapi(
          EXPORTING
            iv_mblnr       = lv_doc
            iv_mjahr       = lv_mjahr_doc
          IMPORTING
            ev_ok          = DATA(lv_ok_perda)
            ev_doc_estorno = lv_doc_estorno
            et_return      = lt_ret_bapi ).

        LOOP AT lt_ret_bapi INTO DATA(ls_ret_perda) WHERE type CA 'EAX'.
            APPEND VALUE #( type = 'E' message = |{ 'Falha no estorno de perdas/sobras:'(028) } { lv_doc }: { ls_ret_perda-message }| ) TO et_return.
          EXIT.
        ENDLOOP.

        IF et_return IS NOT INITIAL.
          DATA(lv_docs_fail_perda) = build_docs_estornados( lt_docs_rev ).
          APPEND VALUE #( type = 'E' message = |{ 'Documentos estornados com sucesso ate a falha:'(038) } { COND string( WHEN lv_docs_fail_perda IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_perda ) }.| ) TO et_return.
          APPEND VALUE #( type = 'E' message = 'Contate o suporte para reconciliacao manual antes de nova tentativa de estorno.'(039) ) TO et_return.
          ev_docs = COND #( WHEN lv_docs_fail_perda IS INITIAL THEN 'nenhum'(043) ELSE lv_docs_fail_perda ).
          RETURN.
        ENDIF.

        APPEND |PERDA:{ lv_doc }/{ lv_mjahr_doc }->{ lv_doc_estorno }| TO lt_docs_rev.
      ENDLOOP.
    ENDIF.

    " Passo 5: restaura produto anterior do tanque (P5: historico pode variar por ambiente).
    SELECT matnr
      FROM ztbq2c_descarga
      WHERE centro_descarregamento = @is_descarga-CentroDescarregamento
        AND lgort_destino          = @is_descarga-LgortDestino
        AND status                 IN ('05', '06')
        AND shnumber               <> @is_descarga-Shnumber
        AND ( dt_em < @is_descarga-DtEm
           OR ( dt_em = @is_descarga-DtEm AND hr_em < @is_descarga-HrEm ) )
      ORDER BY dt_em DESCENDING, hr_em DESCENDING
      INTO @lv_material_ant
      UP TO 1 ROWS.
    ENDSELECT.

    IF lv_material_ant IS NOT INITIAL.
      UPDATE zmm_prod_tanque
         SET matnr = @lv_material_ant
       WHERE werks = @is_descarga-CentroDescarregamento
         AND lgort = @is_descarga-LgortDestino.
    ELSE.
      APPEND VALUE #( type = 'W' message = 'Nao havia produto anterior para restaurar no tanque. Produto atual foi preservado.'(040) ) TO et_return.
    ENDIF.

    DATA(lv_docs_concat) = build_docs_estornados( lt_docs_rev ).

    MODIFY ENTITIES OF zi_q2c_descarga
      ENTITY descarga
      UPDATE FIELDS ( Status
                      MblnrEm
                      MjahrEm
                      LoteMaterialEm
                      QtdeEntradaMercadoria
                      VolumeExtraDrenado
                      DocMaterialExtraDrenado
                      LoteMaterialExtraDrenado
                      DocPerdasSobras
                      DtEm
                      HrEm
                      Mblnr311
                      DtTransf
                      HrTransf
                      Aenam
                      Aedat
)
      WITH VALUE #( ( Shnumber                 = is_descarga-Shnumber
                      Remessa                  = is_descarga-Remessa
                      ItemRemessa              = is_descarga-ItemRemessa
                      Status                   = '04'
                      MblnrEm                  = space
                      MjahrEm                  = space
                      LoteMaterialEm           = space
                      QtdeEntradaMercadoria    = 0
                      VolumeExtraDrenado       = 0
                      DocMaterialExtraDrenado  = space
                      LoteMaterialExtraDrenado = space
                      DocPerdasSobras          = space
                      DtEm                     = '00000000'
                      HrEm                     = '000000'
                      Mblnr311                 = space
                      DtTransf                 = '00000000'
                      HrTransf                 = '000000'
                      Aenam                   = sy-uname
                      Aedat                   = sy-datum
) )
      FAILED   DATA(ls_failed_05)
      REPORTED DATA(ls_reported_05).

    IF ls_failed_05-descarga IS NOT INITIAL.
      APPEND VALUE #( type = 'E' message = 'Falha ao atualizar a ZDESCARGA no estorno da entrada de mercadoria.'(029) ) TO et_return.
      LOOP AT ls_reported_05-descarga INTO DATA(ls_rep_05).
        IF ls_rep_05-%msg IS BOUND.
          APPEND VALUE #( type = 'E' message = ls_rep_05-%msg->if_message~get_text( ) ) TO et_return.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    ev_docs        = lv_docs_concat.
    ev_status_novo = '04'.
    ev_sucesso     = abap_true.

    APPEND VALUE #( type = 'S' message = |{ 'Entrada de Mercadoria e Transferencia 311 do TD'(030) } { is_descarga-Shnumber } { 'estornadas. Status retornado para 04.'(031) }| ) TO et_return.
  ENDMETHOD.