METHOD load_order_data.
  DATA lv_reference TYPE string.
  DATA ls_moni_descarga TYPE zi_q2c_moni_descarga.
  DATA lv_lab_date TYPE string.
  DATA lv_lab_time TYPE string.

  CLEAR: cs_u200_h, ct_u200_s.
  CLEAR ms_descarga.
  lv_reference = iv_reference.

  SELECT SINGLE *
    FROM zi_q2c_descarga
    WHERE pcsordernum = @lv_reference
    INTO @ms_descarga.

  IF sy-subrc <> 0.
    SELECT SINGLE *
      FROM zi_q2c_descarga
      WHERE shnumber = @lv_reference
      INTO @ms_descarga.
  ENDIF.

  IF sy-subrc <> 0.
    zclq2c_265_desc_common=>add_error( EXPORTING iv_number = '030' iv_v1 = |Referencia nao encontrada: { lv_reference }| CHANGING ct_message = ct_msg ).
    RETURN.
  ENDIF.

  SELECT SINGLE *
    FROM zi_q2c_moni_descarga
    WHERE shnumber       = @ms_descarga-shnumber
      AND deliverynumber = @ms_descarga-remessa
      AND deliveryitem   = @ms_descarga-itemremessa
    INTO @ls_moni_descarga.

  " Base existente
  cs_u200_h-ordernum = ms_descarga-pcsordernum.
  cs_u200_h-invoqtyl = ms_descarga-qtdenfe.
  cs_u200_h-invoqtykg = ms_descarga-pesobrutonfe.
  cs_u200_h-desttank = ms_descarga-lgortdestino.
  cs_u200_h-prodnum = ms_descarga-matnr.
  cs_u200_h-prodname = ls_moni_descarga-arktx.
  cs_u200_h-unloadln = ms_descarga-linhadescarga.
  cs_u200_h-unloadpt = ms_descarga-plataforma.
  cs_u200_h-coloryn = ms_descarga-mangote.
  cs_u200_h-truckid = ls_moni_descarga-vehicle.
  cs_u200_h-cartid = ls_moni_descarga-vehid.
  cs_u200_h-batchids = ls_moni_descarga-charg.
  cs_u200_h-invoicen = ms_descarga-nfnum.
  cs_u200_h-msgrcvtm = |{ sy-datum } { sy-uzeit }|.

  " Campos adicionais U200-H
  " PRODDEN: prioriza densidade medida; fallback para densidade da NF-e.
  cs_u200_h-prodden = COND #( WHEN ms_descarga-densidade IS NOT INITIAL
                              THEN ms_descarga-densidade
                              ELSE ms_descarga-densidadenfe ).

  " PPRDNAME/PPRODNUM: sem origem comprovada nas CDS atuais; manter em branco ate definicao funcional.
  CLEAR: cs_u200_h-pprdname,
         cs_u200_h-pprodnum.

  " SAMPLEYN: indica se houve amostra no processo.
  cs_u200_h-sampleyn = COND #( WHEN ms_descarga-qtdamostra IS NOT INITIAL
                                 OR ms_descarga-volumeamostra IS NOT INITIAL
                               THEN 'Y'
                               ELSE 'N' ).

  " LABMAN: prioriza usuario da amostra; fallback para usuario da medicao.
  cs_u200_h-labman = COND #( WHEN ms_descarga-usuarioamostra IS NOT INITIAL
                             THEN ms_descarga-usuarioamostra
                             ELSE ms_descarga-usuariomedicao ).

  " LADAPPTM: prioriza data/hora de confirmacao; fallback para data/hora de amostra.
  IF ms_descarga-dtconf IS NOT INITIAL OR ms_descarga-hrconf IS NOT INITIAL.
    lv_lab_date = |{ ms_descarga-dtconf }|.
    lv_lab_time = |{ ms_descarga-hrconf }|.
  ELSE.
    lv_lab_date = |{ ms_descarga-dtamostra }|.
    lv_lab_time = |{ ms_descarga-hramostra }|.
  ENDIF.
  cs_u200_h-ladapptm = |{ lv_lab_date } { lv_lab_time }|.

  IF ms_descarga-quantidadelacrefornecedor IS NOT INITIAL
     OR ms_descarga-codelacrefornecedor IS NOT INITIAL
     OR ms_descarga-corlacrefornecedor IS NOT INITIAL.
    APPEND VALUE #( sordrnm  = cs_u200_h-ordernum
                    sealcode = ''
                    scolor   = ms_descarga-corlacrefornecedor
                    ssealid  = ms_descarga-codelacrefornecedor
                    ssealqty = ms_descarga-quantidadelacrefornecedor ) TO ct_u200_s.
  ENDIF.
ENDMETHOD.
