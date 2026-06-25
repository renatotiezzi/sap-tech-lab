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

    TYPES ty_docs_rev_tt TYPE STANDARD TABLE OF char50 WITH EMPTY KEY.

    METHODS build_docs_estornados
      IMPORTING it_docs        TYPE ty_docs_rev_tt
      RETURNING VALUE(rv_docs) TYPE char255.

    METHODS cancelar_doc_bapi
      IMPORTING
        iv_mblnr       TYPE mblnr
        iv_mjahr       TYPE mjahr
      EXPORTING
        ev_ok          TYPE abap_bool
        ev_doc_estorno TYPE mblnr
        et_return      TYPE bapiret2_t.

    METHODS cancelar_lote_qm_bapi
      IMPORTING
        iv_lote_qm TYPE qplos
      EXPORTING
        ev_ok      TYPE abap_bool
        et_return  TYPE bapiret2_t.

    METHODS gravar_ud_qm_bapi
      IMPORTING
        iv_lote_qm TYPE qplos
        iv_ud_code TYPE zz1_8d05c26e3b4f-low
      EXPORTING
        ev_ok      TYPE abap_bool
        et_return  TYPE bapiret2_t.

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
            " Novo modelo: sem cancelamento explicito de lote QM quando nao ha UD.
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

    DATA(lv_autor_passo) = SWITCH uname( is_descarga-Status
                                         WHEN '01' THEN is_descarga-UsuarioChegada
                                         WHEN '02' THEN is_descarga-UsuarioAmostra
                                         WHEN '04' THEN is_descarga-UsuarioMedicao
                                         ELSE space ).

    DATA(lv_autor) = COND uname( WHEN lv_autor_passo IS NOT INITIAL
                                 THEN lv_autor_passo
                                 ELSE is_descarga-Aenam ).

    IF lv_autor IS NOT INITIAL AND lv_autor = sy-uname.
      rv_ok = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD build_docs_estornados.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~build_docs_estornados
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 19/06/2026
* Gap ID        : 340
* Description   : Monta lista de documentos (max 255) com reticencias
*--------------------------------------------------------------------*
    CONSTANTS lc_docs_max TYPE i VALUE 255.
    CONSTANTS lc_sufixo   TYPE string VALUE '...'.

    DATA lv_docs TYPE string.

    LOOP AT it_docs INTO DATA(lv_doc_log).
      DATA(lv_candidate_docs) = COND string( WHEN lv_docs IS INITIAL THEN lv_doc_log
                                             ELSE |{ lv_docs }, { lv_doc_log }| ).
      IF strlen( lv_candidate_docs ) <= lc_docs_max.
        lv_docs = lv_candidate_docs.
      ELSE.
        IF lv_docs IS INITIAL.
          lv_docs = lv_doc_log.
        ENDIF.

        DATA(lv_cut_len) = lc_docs_max - strlen( lc_sufixo ).
        IF lv_cut_len < 0.
          lv_cut_len = 0.
        ENDIF.
        IF strlen( lv_docs ) > lv_cut_len.
          lv_docs = lv_docs(lv_cut_len).
        ENDIF.

        lv_docs = |{ lv_docs }{ lc_sufixo }|.
        EXIT.
      ENDIF.
    ENDLOOP.

    rv_docs = lv_docs.
  ENDMETHOD.

  METHOD cancelar_doc_bapi.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~cancelar_doc_bapi
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 23/06/2026
* Gap ID        : 340
* Description   : Executa cancelamento em LUW paralela (CL_ABAP_PARALLEL)
*--------------------------------------------------------------------*
    CLEAR: ev_ok, ev_doc_estorno, et_return.

    DATA(lo_parallel) = NEW zcl_q2c_estorno_parallel( ).

    lo_parallel->execute_cancel(
      EXPORTING
        is_input  = VALUE #( mblnr = iv_mblnr
                             mjahr = iv_mjahr )
      IMPORTING
        es_output = DATA(ls_output) ).

    APPEND ls_output-return TO et_return.
    ev_doc_estorno = ls_output-doc_estorno.
    ev_ok = xsdbool( ls_output-return-type NA 'EAX' ).
  ENDMETHOD.

  METHOD cancelar_lote_qm_bapi.
    CLEAR: ev_ok, et_return.

    DATA(lo_parallel) = NEW zcl_q2c_estorno_parallel( ).

    lo_parallel->execute_qm_cancel(
      EXPORTING
        iv_lote_qm = iv_lote_qm
      IMPORTING
        es_output  = DATA(ls_output) ).

    APPEND ls_output-return TO et_return.
    ev_ok = xsdbool( ls_output-return-type NA 'EAX' ).
  ENDMETHOD.

  METHOD gravar_ud_qm_bapi.
    CLEAR: ev_ok, et_return.

    DATA(lo_parallel) = NEW zcl_q2c_estorno_parallel( ).

    lo_parallel->execute_qm_ud(
      EXPORTING
        iv_lote_qm = iv_lote_qm
        iv_ud_code = iv_ud_code
      IMPORTING
        es_output  = DATA(ls_output) ).

    APPEND ls_output-return TO et_return.
    ev_ok = xsdbool( ls_output-return-type NA 'EAX' ).
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

    cancelar_doc_bapi(
      EXPORTING
        iv_mblnr       = lv_mblnr_amostra
        iv_mjahr       = lv_mjahr_amostra
      IMPORTING
        ev_ok          = DATA(lv_ok_amostra)
        ev_doc_estorno = lv_doc_estorno
        et_return      = lt_ret_bapi ).

    LOOP AT lt_ret_bapi INTO DATA(ls_ret_101) WHERE type CA 'EAX'.
      APPEND VALUE #( type = ls_ret_101-type message = ls_ret_101-message ) TO et_return.
      EXIT.
    ENDLOOP.

    IF et_return IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF is_descarga-LoteQm IS NOT INITIAL.
      CLEAR lt_ret_bapi.

      IF is_descarga-DuQm IS INITIAL.
        cancelar_lote_qm_bapi(
          EXPORTING
            iv_lote_qm = is_descarga-LoteQm
          IMPORTING
            ev_ok      = DATA(lv_ok_qm_cancel)
            et_return  = lt_ret_bapi ).
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
          RETURN.
        ENDIF.

        gravar_ud_qm_bapi(
          EXPORTING
            iv_lote_qm = is_descarga-LoteQm
            iv_ud_code = lv_ud_code
          IMPORTING
            ev_ok      = DATA(lv_ok_qm_ud)
            et_return  = lt_ret_bapi ).
      ENDIF.

      LOOP AT lt_ret_bapi INTO DATA(ls_ret_qm) WHERE type CA 'EAX'.
        APPEND VALUE #( type = ls_ret_qm-type message = ls_ret_qm-message ) TO et_return.
        EXIT.
      ENDLOOP.

      IF et_return IS NOT INITIAL.
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

  METHOD estorno_03_tanque.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_03_tanque
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 03 Tanque (limpa campos -> 02)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.

    MODIFY ENTITIES OF zi_q2c_descarga
      ENTITY descarga
      UPDATE FIELDS ( Status
                      LgortDestino
                      LinhaDescarga
                      Plataforma
                      Mangote
                      QtdeSerDescarregada
                      MaterialCompativel
                      PcsOrdernum
                      Aenam
                      Aedat
)
      WITH VALUE #( ( Shnumber            = is_descarga-Shnumber
                      Remessa             = is_descarga-Remessa
                      ItemRemessa         = is_descarga-ItemRemessa
                      Status              = '02'
                      LgortDestino        = space
                      LinhaDescarga       = space
                      Plataforma          = space
                      Mangote             = space
                      QtdeSerDescarregada = 0
                      MaterialCompativel  = space
                      " P4: limpar PCS_ORDERNUM ate decisao funcional sobre cancelamento na interface PCS.
                      PcsOrdernum         = space
                      Aenam               = sy-uname
                      Aedat               = sy-datum
) )
      FAILED   DATA(ls_failed_03)
      REPORTED DATA(ls_reported_03).

    IF ls_failed_03-descarga IS NOT INITIAL.
      APPEND VALUE #( type = 'E' message = 'Falha ao atualizar a ZDESCARGA no estorno da escolha do tanque.'(013) ) TO et_return.
      LOOP AT ls_reported_03-descarga INTO DATA(ls_rep_03).
        IF ls_rep_03-%msg IS BOUND.
          APPEND VALUE #( type = 'E' message = ls_rep_03-%msg->if_message~get_text( ) ) TO et_return.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    ev_status_novo = '02'.
    ev_sucesso     = abap_true.
    APPEND VALUE #( type = 'S' message = |{ 'Escolha do tanque do TD'(014) } { is_descarga-Shnumber } { 'estornada. Status retornado para 02.'(015) }| ) TO et_return.
  ENDMETHOD.

  METHOD estorno_04_medicao.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_estorno~estorno_04_medicao
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Estorno passo 04 Medicao (limpa campos -> 03)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR: et_return, ev_sucesso, ev_status_novo, ev_docs.

    MODIFY ENTITIES OF zi_q2c_descarga
      ENTITY descarga
      UPDATE FIELDS ( Status
                      PesoInicial
                      PesoFinal
                      Densidade
                      VolumeAmostra
                      VolumeDescarregado
                      QtdeMedida
                      UmMedida
                      UsuarioMedicao
                      DtMedicao
                      HrMedicao
                      Aenam
                      Aedat
)
      WITH VALUE #( ( Shnumber           = is_descarga-Shnumber
                      Remessa            = is_descarga-Remessa
                      ItemRemessa        = is_descarga-ItemRemessa
                      Status             = '03'
                      PesoInicial        = 0
                      PesoFinal          = 0
                      Densidade          = 0
                      VolumeAmostra      = 0
                      VolumeDescarregado = 0
                      QtdeMedida         = 0
                      UmMedida           = space
                      UsuarioMedicao     = space
                      DtMedicao          = '00000000'
                      HrMedicao          = '000000'
                      Aenam              = sy-uname
                      Aedat              = sy-datum
) )
      FAILED   DATA(ls_failed_04)
      REPORTED DATA(ls_reported_04).

    IF ls_failed_04-descarga IS NOT INITIAL.
      APPEND VALUE #( type = 'E' message = 'Falha ao atualizar a ZDESCARGA no estorno da medicao.'(016) ) TO et_return.
      LOOP AT ls_reported_04-descarga INTO DATA(ls_rep_04).
        IF ls_rep_04-%msg IS BOUND.
          APPEND VALUE #( type = 'E' message = ls_rep_04-%msg->if_message~get_text( ) ) TO et_return.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    ev_status_novo = '03'.
    ev_sucesso     = abap_true.
    APPEND VALUE #( type = 'S' message = |{ 'Medicao do TD'(017) } { is_descarga-Shnumber } { 'estornada. Status retornado para 03.'(018) }| ) TO et_return.
  ENDMETHOD.

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
          lt_docs_rev     TYPE ty_docs_rev_tt,
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
          APPEND VALUE #( type = 'E' message = 'Pendencia tecnica: validar API/CDS liberada para periodo contabil MM (substituir MMRV).'(042) ) TO et_return.
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
                      Aenam
                      Aedat
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
                      Aenam       = sy-uname
                      Aedat       = sy-datum
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
