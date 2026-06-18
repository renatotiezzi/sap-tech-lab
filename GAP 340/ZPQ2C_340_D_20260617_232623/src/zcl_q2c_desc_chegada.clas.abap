CLASS zcl_q2c_desc_chegada DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF co_tipo,
        compra  TYPE char20 VALUE 'COMPRA',
        retorno TYPE char20 VALUE 'RETORNO',
      END OF co_tipo.

    METHODS registrar_chegada
      IMPORTING
        iv_tipo_processo TYPE char20
        iv_shnumber      TYPE oig_shnum
        iv_remessa       TYPE vbeln_vl
        iv_item_remessa  TYPE posnr_vl
        iv_chave_nfe     TYPE edoc_accesskey
      EXPORTING
        et_return        TYPE bapiret2_t
        ev_sucesso       TYPE abap_bool.

    METHODS registrar_chegada_transf
      IMPORTING
        iv_shnumber     TYPE oig_shnum
        iv_remessa      TYPE vbeln_vl
        iv_item_remessa TYPE posnr_vl
        iv_chave_nfe    TYPE edoc_accesskey
      EXPORTING
        et_return       TYPE bapiret2_t
        ev_sucesso      TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS ler_qtd_nfe_drc
      IMPORTING
        iv_edoc_guid TYPE edoc_guid
      EXPORTING
        ev_qtde      TYPE menge_d
        ev_unidade   TYPE meins.
ENDCLASS.



CLASS zcl_q2c_desc_chegada IMPLEMENTATION.

  METHOD registrar_chegada.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_chegada~registrar_chegada
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Registra chegada (Compra/Retorno) via DRC -> status 01
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*

    CLEAR: et_return, ev_sucesso.

    IF iv_chave_nfe IS INITIAL.
      APPEND VALUE #( type = 'E'
                      message = 'NF-e nao recebida no DRC para este TD.'(015) ) TO et_return.
      RETURN.
    ENDIF.

    IF strlen( iv_chave_nfe ) <> 44 OR iv_chave_nfe CN '0123456789'.
      APPEND VALUE #( type = 'E'
                      message = 'Chave de acesso invalida (44 digitos).'(001) ) TO et_return.
      RETURN.
    ENDIF.

    DATA(lo_edoc_db) = NEW cl_edocument_br_in_db( ).
    DATA(ls_incoming) = lo_edoc_db->if_edocument_br_in_db~select_edobrincoming_accesskey(
                          iv_access_key = iv_chave_nfe ).

    IF ls_incoming-edoc_guid IS INITIAL.
      APPEND VALUE #( type = 'E'
                      message = 'NF-e nao localizada no DRC.'(002) ) TO et_return.
      RETURN.
    ENDIF.

    IF ls_incoming-delnum IS INITIAL.
      APPEND VALUE #( type = 'E'
                      message = 'Nenhuma remessa encontrada para a NF-e no DRC.'(003) ) TO et_return.
      RETURN.
    ENDIF.

    IF ls_incoming-delnum <> iv_remessa.
      APPEND VALUE #( type = 'E'
                      message = 'NF-e vinculada a outra remessa.'(004) ) TO et_return.
      RETURN.
    ENDIF.

    DATA lv_po_num  TYPE ebeln.
    DATA lv_po_item TYPE ebelp.
    IF iv_tipo_processo = co_tipo-compra.
      DATA(ls_poassign) = lo_edoc_db->if_edocument_br_in_db~select_edocbrpoassign(
                            iv_edoc_guid = ls_incoming-edoc_guid
                            iv_xml_item  = '001' ).
      lv_po_num  = ls_poassign-po_num.
      lv_po_item = ls_poassign-po_item.
      IF lv_po_num IS INITIAL.
        APPEND VALUE #( type = 'E'
                        message = 'Pedido de compra nao encontrado no DRC.'(005) ) TO et_return.
        RETURN.
      ENDIF.
    ENDIF.

    SELECT SINGLE Matnr, Werks, Lfimg, Meins, Lifnr, LifnrName
      FROM zi_q2c_moni_descarga
      WHERE Shnumber       = @iv_shnumber
        AND DeliveryNumber = @iv_remessa
        AND DeliveryItem   = @iv_item_remessa
      INTO @DATA(ls_td).

    DATA(lv_tipo_txt) = COND char20(
      WHEN iv_tipo_processo = co_tipo-compra THEN 'COMPRA FORNECEDOR'
      ELSE 'RETORNO ARMAZENAGEM' ).

    DATA(lv_lifnr) = COND lifnr(
      WHEN ls_incoming-supplier IS NOT INITIAL THEN ls_incoming-supplier
      ELSE ls_td-Lifnr ).

    " Quantidade da NF-e (qCom) e unidade (uCom) lidas do XML do DRC
    DATA lv_qtde_nfe TYPE menge_d.
    DATA lv_um_nfe   TYPE meins.
    ler_qtd_nfe_drc(
      EXPORTING iv_edoc_guid = ls_incoming-edoc_guid
      IMPORTING ev_qtde      = lv_qtde_nfe
                ev_unidade   = lv_um_nfe ).

    IF lv_qtde_nfe IS NOT INITIAL AND lv_qtde_nfe <> ls_td-Lfimg.
      APPEND VALUE #( type = 'W'
                      message = 'Divergencia de quantidade entre NF-e e remessa.'(006) ) TO et_return.
    ENDIF.
    IF lv_um_nfe IS NOT INITIAL AND lv_um_nfe <> ls_td-Meins.
      APPEND VALUE #( type = 'W'
                      message = 'UM da NF-e difere da remessa.'(007) ) TO et_return.
    ENDIF.

    MODIFY ENTITIES OF zi_q2c_descarga
      ENTITY descarga
      CREATE FIELDS ( Shnumber Remessa ItemRemessa TipoProcesso Status
                      DtChegada HrChegada ChaveNfe Nfnum Lifnr LifnrName
                      Matnr Werks PedidoCompra ItemPedidoCompra
                      QtdeNfe UmNfe QtdeRemessa UniMedRemessa UsuarioChegada )
      WITH VALUE #( ( %cid             = 'CHEGADA'
                      Shnumber         = iv_shnumber
                      Remessa          = iv_remessa
                      ItemRemessa      = iv_item_remessa
                      TipoProcesso     = lv_tipo_txt
                      Status           = '01'
                      DtChegada        = cl_abap_context_info=>get_system_date( )
                      HrChegada        = cl_abap_context_info=>get_system_time( )
                      ChaveNfe         = iv_chave_nfe
                      Nfnum            = ls_incoming-nfenum
                      Lifnr            = lv_lifnr
                      LifnrName        = ls_td-LifnrName
                      Matnr            = ls_td-Matnr
                      Werks            = ls_td-Werks
                      PedidoCompra     = lv_po_num
                      ItemPedidoCompra = lv_po_item
                      QtdeNfe          = lv_qtde_nfe
                      UmNfe            = lv_um_nfe
                      QtdeRemessa      = ls_td-Lfimg
                      UniMedRemessa    = ls_td-Meins
                      UsuarioChegada   = cl_abap_context_info=>get_user_technical_name( ) ) )
      MAPPED   DATA(ls_mapped)
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-descarga IS NOT INITIAL.
      APPEND VALUE #( type = 'E'
                      message = 'Falha ao criar registro de descarga.'(012) ) TO et_return.
      LOOP AT ls_reported-descarga INTO DATA(ls_rep).
        IF ls_rep-%msg IS BOUND.
          APPEND VALUE #( type = 'E' message = ls_rep-%msg->if_message~get_text( ) ) TO et_return.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    ev_sucesso = abap_true.
    APPEND VALUE #( type = 'S'
                    message = |{ 'Chegada registrada com sucesso (status 01). TD:'(014) } { iv_shnumber ALPHA = OUT }| ) TO et_return.

  ENDMETHOD.


  METHOD registrar_chegada_transf.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_chegada~registrar_chegada_transf
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Registra chegada TRANSFERENCIA (NF-e saida) -> status 01
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*

    CLEAR: et_return, ev_sucesso.

    IF iv_chave_nfe IS INITIAL.
      APPEND VALUE #( type = 'E'
                      message = 'Nenhuma NF-e de saida vinculada a este TD.'(016) ) TO et_return.
      RETURN.
    ENDIF.

    IF strlen( iv_chave_nfe ) <> 44 OR iv_chave_nfe CN '0123456789'.
      APPEND VALUE #( type = 'E'
                      message = 'Chave de acesso invalida (44 digitos).'(001) ) TO et_return.
      RETURN.
    ENDIF.

    SELECT SINGLE br_notafiscal
      FROM i_br_nfelectronic_c
      WHERE br_nfeaccesskey = @iv_chave_nfe
      INTO @DATA(lv_docnum).

    IF sy-subrc <> 0 OR lv_docnum IS INITIAL.
      APPEND VALUE #( type = 'E'
                      message = 'NF-e de saida nao localizada.'(008) ) TO et_return.
      RETURN.
    ENDIF.

    SELECT SINGLE quantityinbaseunit, baseunit
      FROM i_br_nfitem
      WHERE br_notafiscal             = @lv_docnum
        AND br_nfsourcedocumenttype   = 'LI'
        AND br_nfsourcedocumentnumber = @iv_remessa
        AND br_nfsourcedocumentitem   = @iv_item_remessa
      INTO @DATA(ls_nfitem).

    IF sy-subrc <> 0.
      APPEND VALUE #( type = 'E'
                      message = 'Nenhuma remessa outbound na NF-e (Faturamento).'(009) ) TO et_return.
      RETURN.
    ENDIF.

    SELECT SINGLE br_nfenumber, headergrossweight, br_nfiscanceled
      FROM i_br_nfdocument
      WHERE br_notafiscal = @lv_docnum
      INTO @DATA(ls_nfhdr).

    IF ls_nfhdr-br_nfiscanceled = 'X'.
      APPEND VALUE #( type = 'E'
                      message = 'NF-e de saida esta cancelada.'(010) ) TO et_return.
      RETURN.
    ENDIF.

    SELECT SINGLE Matnr, Werks, Lfimg, Meins
      FROM zi_q2c_moni_descarga
      WHERE Shnumber       = @iv_shnumber
        AND DeliveryNumber = @iv_remessa
        AND DeliveryItem   = @iv_item_remessa
      INTO @DATA(ls_td).

    IF ls_nfitem-quantityinbaseunit <> ls_td-Lfimg.
      APPEND VALUE #( type = 'W'
                      message = 'Divergencia de quantidade entre NF-e e remessa.'(006) ) TO et_return.
    ENDIF.
    IF ls_nfitem-baseunit <> ls_td-Meins.
      APPEND VALUE #( type = 'W'
                      message = 'UM da NF-e difere da remessa.'(007) ) TO et_return.
    ENDIF.

    MODIFY ENTITIES OF zi_q2c_descarga
      ENTITY descarga
      CREATE FIELDS ( Shnumber Remessa ItemRemessa TipoProcesso Status
                      DtChegada HrChegada ChaveNfe Nfnum
                      Matnr Werks
                      QtdeNfe UmNfe QtdeRemessa UniMedRemessa
                      PesoBrutoNfe UsuarioChegada )
      WITH VALUE #( ( %cid          = 'CHEGADA_T'
                      Shnumber      = iv_shnumber
                      Remessa       = iv_remessa
                      ItemRemessa   = iv_item_remessa
                      TipoProcesso  = 'TRANSFERENCIA'
                      Status        = '01'
                      DtChegada     = cl_abap_context_info=>get_system_date( )
                      HrChegada     = cl_abap_context_info=>get_system_time( )
                      ChaveNfe      = iv_chave_nfe
                      Nfnum         = ls_nfhdr-br_nfenumber
                      Matnr         = ls_td-Matnr
                      Werks         = ls_td-Werks
                      QtdeNfe       = ls_nfitem-quantityinbaseunit
                      UmNfe         = ls_nfitem-baseunit
                      QtdeRemessa   = ls_td-Lfimg
                      UniMedRemessa = ls_td-Meins
                      PesoBrutoNfe  = ls_nfhdr-headergrossweight
                      UsuarioChegada = cl_abap_context_info=>get_user_technical_name( ) ) )
      MAPPED   DATA(ls_mapped)
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-descarga IS NOT INITIAL.
      APPEND VALUE #( type = 'E'
                      message = 'Falha ao criar registro de descarga.'(012) ) TO et_return.
      LOOP AT ls_reported-descarga INTO DATA(ls_rep).
        IF ls_rep-%msg IS BOUND.
          APPEND VALUE #( type = 'E' message = ls_rep-%msg->if_message~get_text( ) ) TO et_return.
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    ev_sucesso = abap_true.
    APPEND VALUE #( type = 'S'
                    message = |{ 'Chegada registrada com sucesso (status 01). TD:'(014) } { iv_shnumber ALPHA = OUT }| ) TO et_return.

  ENDMETHOD.


  METHOD ler_qtd_nfe_drc.
*--------------------------------------------------------------------*
* Program       : zcl_q2c_desc_chegada~ler_qtd_nfe_drc
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Le qCom/uCom do XML da NF-e no DRC (parse locale-safe)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*

    CLEAR: ev_qtde, ev_unidade.

    IF iv_edoc_guid IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE file_raw                              "#EC CI_NOORDER
      FROM edocumentfile
      WHERE edoc_guid = @iv_edoc_guid
        AND file_type = 'NFE_XML'
      INTO @DATA(lv_file_raw).

    IF sy-subrc <> 0 OR lv_file_raw IS INITIAL.
      RETURN.
    ENDIF.

    DATA lv_xml_string TYPE string.
    CALL FUNCTION 'ECATT_CONV_XSTRING_TO_STRING'
      EXPORTING
        im_xstring = lv_file_raw
      IMPORTING
        ex_string  = lv_xml_string.

    DATA(lr_ixml)     = cl_ixml=>create( ).
    DATA(lr_stream)   = lr_ixml->create_stream_factory( ).
    DATA(lr_istream)  = lr_stream->create_istream_string( lv_xml_string ).
    DATA(lr_document) = lr_ixml->create_document( ).
    DATA(lr_parser)   = lr_ixml->create_parser( stream_factory = lr_stream
                                                istream        = lr_istream
                                                document       = lr_document ).

    IF lr_parser->parse( ) <> 0.
      RETURN.
    ENDIF.

    DATA(lr_root) = lr_document->get_root_element( ).
    IF lr_root IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lr_qcoms) = lr_root->get_elements_by_tag_name( name = 'qCom' ).
    DATA(lr_qiter) = lr_qcoms->create_iterator( ).
    DATA(lr_qnode) = lr_qiter->get_next( ).

    DATA: lv_val  TYPE string,
          lv_int  TYPE string,
          lv_frac TYPE string,
          lv_num  TYPE decfloat34.

    WHILE lr_qnode IS BOUND.
      lv_val = lr_qnode->get_value( ).
      CONDENSE lv_val NO-GAPS.
      SPLIT lv_val AT '.' INTO lv_int lv_frac.
      lv_num = CONV decfloat34( lv_int ).
      IF lv_frac IS NOT INITIAL.
        lv_num = lv_num + CONV decfloat34( lv_frac ) / ipow( base = 10 exp = strlen( lv_frac ) ).
      ENDIF.
      ev_qtde = ev_qtde + lv_num.
      lr_qnode = lr_qiter->get_next( ).
    ENDWHILE.

    DATA(lr_ucoms) = lr_root->get_elements_by_tag_name( name = 'uCom' ).
    DATA(lr_unode) = lr_ucoms->create_iterator( )->get_next( ).
    IF lr_unode IS BOUND.
      ev_unidade = lr_unode->get_value( ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
