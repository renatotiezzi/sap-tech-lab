CLASS zcl_q2c_desc_amostra DEFINITION
  PUBLIC
  INHERITING FROM cl_abap_parallel
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_amostra,
        shnumber         TYPE oig_shnum,
        remessa          TYPE vbeln_vl,
        item_remessa     TYPE posnr_vl,
        matnr            TYPE matnr,
        werks            TYPE werks_d,
        pedido_compra    TYPE ebeln,
        item_pedido      TYPE ebelp,
        qtd_amostra      TYPE menge_d,
        um_amostra       TYPE meins,
        lgort_amostra    TYPE lgort_d,
        compartimento    TYPE char10,
        ponto_amostragem TYPE char20,
        densidade_nfe    TYPE oib_tdich,
        usuario          TYPE uname,
      END OF ty_amostra.

    TYPES:
      BEGIN OF ty_result,
        return        TYPE bapiret2,
        mblnr         TYPE mblnr,
        mjahr         TYPE mjahr,
        lote_qm       TYPE qplos,
        lote_material TYPE charg_d,
      END OF ty_result.

    METHODS execute_process
      IMPORTING is_amostra TYPE ty_amostra
      EXPORTING es_result  TYPE ty_result.

    METHODS do REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS get_param
      IMPORTING iv_name       TYPE clike
      RETURNING VALUE(rv_low) TYPE char40.

    METHODS get_grupo_conversao
      IMPORTING iv_matnr      TYPE matnr
                iv_werks      TYPE werks_d
      RETURNING VALUE(rv_grp) TYPE oib_umrsl.

    METHODS converte_l20
      IMPORTING is_amostra TYPE ty_amostra
      EXPORTING ev_qtd20   TYPE oib_adqnt
                es_return  TYPE bapiret2.

    METHODS executa_mov_101
      IMPORTING is_amostra       TYPE ty_amostra
      RETURNING VALUE(rs_result) TYPE ty_result.

    METHODS obter_lote_qm
      IMPORTING iv_mblnr    TYPE mblnr
                iv_mjahr    TYPE mjahr
      EXPORTING ev_lote_qm  TYPE qplos
                ev_lote_mat TYPE charg_d.

    METHODS grava_amostra
      IMPORTING is_amostra TYPE ty_amostra
                is_result  TYPE ty_result.

ENDCLASS.



CLASS zcl_q2c_desc_amostra IMPLEMENTATION.

  METHOD execute_process.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_amostra~execute_process
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : Dispara a task paralela (LUW isolada) e devolve result
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    DATA lt_in     TYPE cl_abap_parallel=>t_in_tab.
    DATA lv_buffer TYPE xstring.

    EXPORT buffer_task = is_amostra TO DATA BUFFER lv_buffer.
    INSERT lv_buffer INTO TABLE lt_in.

    me->run( EXPORTING p_in_tab  = lt_in
             IMPORTING p_out_tab = DATA(lt_out) ).

    LOOP AT lt_out INTO DATA(ls_out).
      IMPORT buffer_task = es_result FROM DATA BUFFER ls_out-result.
      EXIT.
    ENDLOOP.
  ENDMETHOD.

  METHOD do.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_amostra~do
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : Roda na LUW isolada: BAPI 101 + lote QM + grava status 02
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    DATA ls_amostra TYPE ty_amostra.
    DATA ls_result  TYPE ty_result.

    IMPORT buffer_task = ls_amostra FROM DATA BUFFER p_in.

    IF ls_amostra IS NOT INITIAL.
      ls_result = me->executa_mov_101( ls_amostra ).

      IF ls_result-return-type NA 'EAX'.
        me->obter_lote_qm(
          EXPORTING iv_mblnr   = ls_result-mblnr
                    iv_mjahr   = ls_result-mjahr
          IMPORTING ev_lote_qm = ls_result-lote_qm
                    ev_lote_mat = ls_result-lote_material ).

        me->grava_amostra( is_amostra = ls_amostra
                           is_result  = ls_result ).
      ENDIF.
    ENDIF.

    EXPORT buffer_task = ls_result TO DATA BUFFER p_out.
  ENDMETHOD.

  METHOD get_param.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_amostra~get_param
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : Le parametro (TYPE P) do CBO Q2C ZZ1_TVARVC_Q2C
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    SELECT SINGLE low FROM zz1_8d05c26e3b4f
      WHERE name = @iv_name AND type = 'P' AND numb = '1'
      INTO @rv_low.
  ENDMETHOD.

  METHOD get_grupo_conversao.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_amostra~get_grupo_conversao
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : Le grupo conversao OIL (UMRSL) por material/centro
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    SELECT SINGLE umrsl FROM i_productplant
      WHERE product = @iv_matnr AND plant = @iv_werks
      INTO @rv_grp.
  ENDMETHOD.

  METHOD converte_l20.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_amostra~converte_l20
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : Converte a qtd informada (L) para a base L20 (OIL)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: ev_qtd20, es_return.

    DATA(lv_grp) = get_grupo_conversao( iv_matnr = is_amostra-matnr
                                        iv_werks = is_amostra-werks ).

    DATA(ls_params) = VALUE oib_a04( tdich = is_amostra-densidade_nfe
                                     tstmp = '20.00'
                                     tsteh = 'CEL'
                                     mttmp = '20.00'
                                     mtteh = 'CEL' ).
    DATA lt_ret TYPE TABLE OF bapiret2.

    DATA lv_l20 TYPE meins VALUE 'L20'.

    CALL FUNCTION 'OIB_QCI_CONVERSION_SIMPLE'
      EXPORTING
        i_conversiongroup        = lv_grp
        i_uom                    = CONV meins( COND #( WHEN is_amostra-um_amostra IS INITIAL THEN 'L' ELSE is_amostra-um_amostra ) )
        i_quantity               = CONV oib_adqnt( is_amostra-qtd_amostra )
        i_targetuom              = lv_l20
        i_parameters             = ls_params
        i_material               = is_amostra-matnr
        i_plant                  = is_amostra-werks
      IMPORTING
        e_quantity               = ev_qtd20
      TABLES
        t_return                 = lt_ret
      EXCEPTIONS
        calculation_failure      = 1
        inconsistent_data        = 2
        inconsistent_customizing = 3
        trans_uom_not_found      = 4
        OTHERS                   = 5.

    IF sy-subrc <> 0.
      es_return = COND #( WHEN lt_ret IS NOT INITIAL THEN lt_ret[ 1 ]
                          ELSE VALUE #( type = 'E' message = 'Falha na conversao para L20'(001) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD executa_mov_101.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_amostra~executa_mov_101
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : BAPI_GOODSMVT_CREATE_OIL mov.101 amostra (params CBO)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    DATA ls_header TYPE bapioil2017_gm_head_create.
    DATA ls_code   TYPE bapi2017_gm_code.
    DATA lt_item   TYPE TABLE OF bapioil2017_gm_itm_crte_01.
    DATA lt_param  TYPE TABLE OF bapioil2017_gm_itm_crte_param.
    DATA lt_quan   TYPE TABLE OF bapioil2017_gm_itm_crte_quan.
    DATA lt_return TYPE TABLE OF bapiret2.

    converte_l20( EXPORTING is_amostra = is_amostra
                  IMPORTING ev_qtd20   = DATA(lv_qtd20)
                            es_return  = DATA(ls_conv_ret) ).
    IF ls_conv_ret-type CA 'EAX'.
      rs_result-return = ls_conv_ret.
      RETURN.
    ENDIF.

    DATA(lv_uom)  = CONV meins( COND #( WHEN is_amostra-um_amostra IS INITIAL THEN 'L' ELSE is_amostra-um_amostra ) ).
    DATA(lv_mtype) = CONV bwart( get_param( 'ZQ2C340_AMOSTRA_MOVE_TYPE' ) ).
    DATA(lv_mind)  = CONV kzbew( get_param( 'ZQ2C340_AMOSTRA_MVT_IND' ) ).

    ls_header-pstng_date = sy-datum.
    ls_header-doc_date   = sy-datum.
    ls_header-pr_uname   = is_amostra-usuario.
    ls_header-header_txt = is_amostra-shnumber.

    ls_code-gm_code = get_param( 'ZQ2C340_AMOSTRA_GM_CODE' ).

    APPEND VALUE #( line_id   = '0001'
                    material  = is_amostra-matnr
                    plant     = is_amostra-werks
                    stge_loc  = is_amostra-lgort_amostra
                    move_type = lv_mtype
                    mvt_ind   = lv_mind
                    entry_qnt = is_amostra-qtd_amostra
                    entry_uom = lv_uom
                    po_number = is_amostra-pedido_compra
                    po_item   = is_amostra-item_pedido ) TO lt_item.

    APPEND VALUE #( line_id              = '0001'
                    conversiongroup      = get_grupo_conversao( iv_matnr = is_amostra-matnr
                                                                iv_werks = is_amostra-werks )
                    usedefaultparameters = abap_true ) TO lt_param.

    APPEND VALUE #( line_id        = '0001'
                    quantitycheck  = abap_true
                    quantityuom    = 'L20'
                    quantitypacked = lv_qtd20
                    quantityfloat  = lv_qtd20 ) TO lt_quan.

    CALL FUNCTION 'BAPI_GOODSMVT_CREATE_OIL'
      EXPORTING
        goodsmvt_header     = ls_header
        goodsmvt_code       = ls_code
      IMPORTING
        materialdocument    = rs_result-mblnr
        matdocumentyear     = rs_result-mjahr
      TABLES
        goodsmvt_item_01    = lt_item
        goodsmvt_item_param = lt_param
        goodsmvt_item_quan  = lt_quan
        return              = lt_return.

    LOOP AT lt_return INTO DATA(ls_ret) WHERE type CA 'EAX'.
      rs_result-return = ls_ret.
      EXIT.
    ENDLOOP.

    IF rs_result-return-type CA 'EAX'.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      CLEAR: rs_result-mblnr, rs_result-mjahr.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
      rs_result-return-type = 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD obter_lote_qm.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_amostra~obter_lote_qm
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : Le lote QM (I_InspectionLot) e lote material (MSEG) do doc
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: ev_lote_qm, ev_lote_mat.

    SELECT SINGLE inspectionlot FROM i_inspectionlot
      WHERE materialdocument     = @iv_mblnr
        AND materialdocumentyear = @iv_mjahr
      INTO @ev_lote_qm.

    SELECT SINGLE batch FROM i_materialdocumentitemtp
      WHERE materialdocument     = @iv_mblnr
        AND materialdocumentyear = @iv_mjahr
      INTO @ev_lote_mat.
  ENDMETHOD.

  METHOD grava_amostra.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_amostra~grava_amostra
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : UPDATE ZTBQ2C_DESCARGA status 02 + campos amostra (DML)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    UPDATE ztbq2c_descarga
      SET status                = '02',
          qtd_amostra           = @is_amostra-qtd_amostra,
          um_amostra            = @is_amostra-um_amostra,
          lgort_amostra         = @is_amostra-lgort_amostra,
          compartimento         = @is_amostra-compartimento,
          ponto_amostragem      = @is_amostra-ponto_amostragem,
          densidade_nfe         = @is_amostra-densidade_nfe,
          doc_material_amostra  = @is_result-mblnr,
          lote_material_amostra = @is_result-lote_material,
          lote_qm               = @is_result-lote_qm,
          usuario_amostra       = @is_amostra-usuario,
          dt_amostra            = @sy-datum,
          hr_amostra            = @sy-uzeit,
          aenam                 = @is_amostra-usuario,
          aedat                 = @sy-datum
      WHERE shnumber     = @is_amostra-shnumber
        AND remessa      = @is_amostra-remessa
        AND item_remessa = @is_amostra-item_remessa.

    COMMIT WORK.
  ENDMETHOD.

ENDCLASS.
