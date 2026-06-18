CLASS lhc_descarga DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Descarga RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Descarga RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ Descarga RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Descarga.

    METHODS registrarChegadaCompra FOR MODIFY
      IMPORTING keys FOR ACTION Descarga~registrarChegadaCompra RESULT result.

    METHODS registrarChegadaRetorno FOR MODIFY
      IMPORTING keys FOR ACTION Descarga~registrarChegadaRetorno RESULT result.

    METHODS registrarChegadaTransferencia FOR MODIFY
      IMPORTING keys FOR ACTION Descarga~registrarChegadaTransferencia RESULT result.

    METHODS realizarEstorno FOR MODIFY
      IMPORTING keys FOR ACTION Descarga~realizarEstorno RESULT result.

    METHODS registrarAmostra FOR MODIFY
      IMPORTING keys FOR ACTION Descarga~registrarAmostra RESULT result.

    " Guard de concorrencia/etapa: valida que o TD esta no status que a acao exige ANTES de executar.
    " Protege o cenario de 2 usuarios com a tela aberta: um avanca a etapa, o outro (tela antiga)
    " submete -> o status real nao condiz -> erro claro pedindo p/ atualizar a tela.
    " iv_status_esperado = '00' significa "linha NAO pode existir na ZTBQ2C_DESCARGA" (chegada).
    METHODS etapa_valida
      IMPORTING iv_shnumber   TYPE oig_shnum
                iv_remessa    TYPE vbeln_vl
                iv_item       TYPE posnr_vl
                iv_status_esp TYPE zdeq2c_desc_status
      RETURNING VALUE(rv_erro) TYPE string.

ENDCLASS.

CLASS lhc_descarga IMPLEMENTATION.

  METHOD get_instance_features.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~get_instance_features
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Feature control das acoes (chegada/estorno) por status
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*

    READ ENTITIES OF zi_q2c_moni_descarga IN LOCAL MODE
      ENTITY Descarga
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_descarga).

    result = VALUE #( FOR ls IN lt_descarga
      ( %tky                                             = ls-%tky
        %features-%action-registrarChegadaCompra         = COND #( WHEN ls-Status = '00'
                                                                   THEN if_abap_behv=>fc-o-enabled
                                                                   ELSE if_abap_behv=>fc-o-disabled )
        %features-%action-registrarChegadaRetorno        = COND #( WHEN ls-Status = '00'
                                                                   THEN if_abap_behv=>fc-o-enabled
                                                                   ELSE if_abap_behv=>fc-o-disabled )
        %features-%action-registrarChegadaTransferencia  = COND #( WHEN ls-Status = '00'
                                                                   THEN if_abap_behv=>fc-o-enabled
                                                                   ELSE if_abap_behv=>fc-o-disabled )
        %features-%action-registrarAmostra                = COND #( WHEN ls-Status = '01'
                                                                   THEN if_abap_behv=>fc-o-enabled
                                                                   ELSE if_abap_behv=>fc-o-disabled ) ) ).

    DATA(lo_est) = NEW zcl_q2c_desc_estorno( ).

    LOOP AT lt_descarga INTO DATA(ls_d).
      DATA(lv_enab) = if_abap_behv=>fc-o-disabled.

      IF ls_d-Status BETWEEN '01' AND '06'.
        DATA(lv_shnumber) = ls_d-Shnumber.
        DATA(lv_remessa)  = ls_d-DeliveryNumber.
        DATA(lv_item)     = ls_d-DeliveryItem.

        SELECT SINGLE * FROM zi_q2c_descarga
          WHERE Shnumber    = @lv_shnumber
            AND Remessa     = @lv_remessa
            AND ItemRemessa = @lv_item
          INTO @DATA(ls_pers).

        IF sy-subrc = 0 AND lo_est->pode_estornar( ls_pers ) = abap_true.
          lv_enab = if_abap_behv=>fc-o-enabled.
        ENDIF.
      ENDIF.

      ASSIGN result[ %tky = ls_d-%tky ] TO FIELD-SYMBOL(<res>).
      IF sy-subrc = 0.
        <res>-%features-%action-realizarEstorno = lv_enab.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_authorizations.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~get_instance_authorizations
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Autorizacao de instancia (liberada no monitor)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
  ENDMETHOD.

  METHOD read.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~read
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : READ do BO monitor (SELECT da view, reconstroi %tky)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    SELECT * FROM zi_q2c_moni_descarga
      FOR ALL ENTRIES IN @keys
      WHERE Shnumber       = @keys-Shnumber
        AND DeliveryNumber = @keys-DeliveryNumber
        AND DeliveryItem   = @keys-DeliveryItem
      INTO TABLE @DATA(lt_data).

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE lt_data INTO DATA(ls_data)
        WITH KEY Shnumber       = ls_key-Shnumber
                 DeliveryNumber = ls_key-DeliveryNumber
                 DeliveryItem   = ls_key-DeliveryItem.
      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_data ) TO result ASSIGNING FIELD-SYMBOL(<fs>).
        <fs>-%tky = ls_key-%tky.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~lock
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : LOCK do BO monitor (no-op; lock no BO de persistencia)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
  ENDMETHOD.

  METHOD etapa_valida.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~etapa_valida
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : Guard de etapa/concorrencia: status real x status exigido
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    CLEAR rv_erro.

    SELECT SINGLE Status FROM zi_q2c_descarga
      WHERE Shnumber    = @iv_shnumber
        AND Remessa     = @iv_remessa
        AND ItemRemessa = @iv_item
      INTO @DATA(lv_status_atual).
    DATA(lv_existe) = xsdbool( sy-subrc = 0 ).

    " Status '00' = pendente: a linha NAO pode existir na ZTBQ2C_DESCARGA (so e criada a partir do 01).
    IF iv_status_esp = '00'.
      IF lv_existe = abap_true.
        rv_erro = |A chegada deste TD ja foi registrada (etapa atual { lv_status_atual }). | &&
                  |Atualize a tela (a informacao exibida esta desatualizada).|.
      ENDIF.
      RETURN.
    ENDIF.

    " Demais etapas: a linha precisa existir E estar exatamente no status exigido.
    IF lv_existe = abap_false.
      rv_erro = |Registro de descarga nao encontrado para este TD. Atualize a tela.|.
    ELSEIF lv_status_atual <> iv_status_esp.
      rv_erro = |A etapa atual do TD ({ lv_status_atual }) nao permite esta acao | &&
                |(esperado { iv_status_esp }). Atualize a tela (a informacao exibida esta desatualizada).|.
    ENDIF.
  ENDMETHOD.

  METHOD registrarChegadaCompra.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~registrarchegadacompra
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Handler da acao Registrar Chegada - Compra Fornecedor
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    " Le os dados da linha (a chave da NF-e ja esta no campo ChaveNfe, unificado via coalesce DRC/ZDESCARGA).
    READ ENTITIES OF zi_q2c_moni_descarga IN LOCAL MODE
      ENTITY Descarga
      FIELDS ( Shnumber DeliveryNumber DeliveryItem ChaveNfe )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_linha).

    DATA(lo_chegada) = NEW zcl_q2c_desc_chegada( ).

    LOOP AT lt_linha INTO DATA(ls_linha).
      DATA(lv_guard) = etapa_valida( iv_shnumber = ls_linha-Shnumber
                                     iv_remessa  = ls_linha-DeliveryNumber
                                     iv_item     = ls_linha-DeliveryItem
                                     iv_status_esp = '00' ).
      IF lv_guard IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_linha-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_guard ) ) TO reported-descarga.
        APPEND VALUE #( %tky = ls_linha-%tky ) TO failed-descarga.
        CONTINUE.
      ENDIF.

      lo_chegada->registrar_chegada(
        EXPORTING
          iv_tipo_processo = zcl_q2c_desc_chegada=>co_tipo-compra
          iv_shnumber      = ls_linha-Shnumber
          iv_remessa       = ls_linha-DeliveryNumber
          iv_item_remessa  = ls_linha-DeliveryItem
          iv_chave_nfe     = ls_linha-ChaveNfe
        IMPORTING
          et_return        = DATA(lt_return)
          ev_sucesso       = DATA(lv_ok) ).

      LOOP AT lt_return INTO DATA(ls_ret).
        " So mensagens de ERRO viram state message da acao. Sucesso/aviso (ex.: divergencia
        " NF-e x remessa) sao exibidos pelo popup do app, evitando o dialog de confirmacao
        " de advertencias do Fiori Elements (que mostra o nome tecnico da acao).
        CHECK ls_ret-type CA 'EAX'.
        APPEND VALUE #( %tky = ls_linha-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = ls_ret-message ) ) TO reported-descarga.
      ENDLOOP.

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = ls_linha-%tky ) TO failed-descarga.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zi_q2c_moni_descarga IN LOCAL MODE
      ENTITY Descarga
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_read).
    result = VALUE #( FOR ls IN lt_read ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.

  METHOD registrarChegadaRetorno.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~registrarchegadaretorno
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Handler da acao Registrar Chegada - Retorno Armazenagem
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    DATA(lo_chegada) = NEW zcl_q2c_desc_chegada( ).

    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_guard) = etapa_valida( iv_shnumber = ls_key-Shnumber
                                     iv_remessa  = ls_key-DeliveryNumber
                                     iv_item     = ls_key-DeliveryItem
                                     iv_status_esp = '00' ).
      IF lv_guard IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_guard ) ) TO reported-descarga.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-descarga.
        CONTINUE.
      ENDIF.

      lo_chegada->registrar_chegada(
        EXPORTING
          iv_tipo_processo = zcl_q2c_desc_chegada=>co_tipo-retorno
          iv_shnumber      = ls_key-Shnumber
          iv_remessa       = ls_key-DeliveryNumber
          iv_item_remessa  = ls_key-DeliveryItem
          iv_chave_nfe     = ls_key-%param-chaveNfe
        IMPORTING
          et_return        = DATA(lt_return)
          ev_sucesso       = DATA(lv_ok) ).

      LOOP AT lt_return INTO DATA(ls_ret).
        " So mensagens de ERRO viram state message da acao (ver comentario no fluxo Compra).
        CHECK ls_ret-type CA 'EAX'.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = ls_ret-message ) ) TO reported-descarga.
      ENDLOOP.

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-descarga.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zi_q2c_moni_descarga IN LOCAL MODE
      ENTITY Descarga
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_read_ret).
    result = VALUE #( FOR ls IN lt_read_ret ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.

  METHOD registrarChegadaTransferencia.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~registrarchegadatransferencia
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Handler da acao Registrar Chegada - Transferencia
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    READ ENTITIES OF zi_q2c_moni_descarga IN LOCAL MODE
      ENTITY Descarga
      FIELDS ( Shnumber DeliveryNumber DeliveryItem ChaveNfe )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_linha).

    DATA(lo_chegada) = NEW zcl_q2c_desc_chegada( ).

    LOOP AT lt_linha INTO DATA(ls_linha).
      DATA(lv_guard) = etapa_valida( iv_shnumber = ls_linha-Shnumber
                                     iv_remessa  = ls_linha-DeliveryNumber
                                     iv_item     = ls_linha-DeliveryItem
                                     iv_status_esp = '00' ).
      IF lv_guard IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_linha-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_guard ) ) TO reported-descarga.
        APPEND VALUE #( %tky = ls_linha-%tky ) TO failed-descarga.
        CONTINUE.
      ENDIF.

      lo_chegada->registrar_chegada_transf(
        EXPORTING
          iv_shnumber     = ls_linha-Shnumber
          iv_remessa      = ls_linha-DeliveryNumber
          iv_item_remessa = ls_linha-DeliveryItem
          iv_chave_nfe    = ls_linha-ChaveNfe
        IMPORTING
          et_return       = DATA(lt_return)
          ev_sucesso      = DATA(lv_ok) ).

      LOOP AT lt_return INTO DATA(ls_ret).
        " So mensagens de ERRO viram state message da acao (ver comentario no fluxo Compra).
        CHECK ls_ret-type CA 'EAX'.
        APPEND VALUE #( %tky = ls_linha-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = ls_ret-message ) ) TO reported-descarga.
      ENDLOOP.

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = ls_linha-%tky ) TO failed-descarga.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zi_q2c_moni_descarga IN LOCAL MODE
      ENTITY Descarga
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_read_transf).
    result = VALUE #( FOR ls IN lt_read_transf ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.

  METHOD realizarEstorno.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~realizarestorno
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 16/06/2026
* Gap ID        : 340
* Description   : Handler da acao de estorno (reversao LIFO)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 16/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    DATA(lo_est) = NEW zcl_q2c_desc_estorno( ).

    LOOP AT keys INTO DATA(ls_key).
      lo_est->realizar_estorno(
        EXPORTING
          iv_shnumber     = ls_key-Shnumber
          iv_remessa      = ls_key-DeliveryNumber
          iv_item_remessa = ls_key-DeliveryItem
        IMPORTING
          et_return       = DATA(lt_return)
          ev_sucesso      = DATA(lv_ok) ).

      LOOP AT lt_return INTO DATA(ls_ret).
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = COND #( WHEN ls_ret-type CA 'EAX' THEN if_abap_behv_message=>severity-error
                                             WHEN ls_ret-type = 'W'     THEN if_abap_behv_message=>severity-warning
                                             WHEN ls_ret-type = 'S'     THEN if_abap_behv_message=>severity-success
                                             ELSE                            if_abap_behv_message=>severity-information )
                          text     = ls_ret-message ) ) TO reported-descarga.
      ENDLOOP.

      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-descarga.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zi_q2c_moni_descarga IN LOCAL MODE
      ENTITY Descarga
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_read_est).
    result = VALUE #( FOR ls IN lt_read_est ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.

  METHOD registrarAmostra.
*--------------------------------------------------------------------*
* Program       : lhc_descarga~registraramostra
* Program Type  : Method
* Author        : CPPACH
* Creation Date : 17/06/2026
* Gap ID        : 340
* Description   : Handler da acao Registrar Amostra (mov.101 + lote QM)
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author   Request    Description
* 000 17/06/2026 CPPACH   DS4K908763 Initial Version
*--------------------------------------------------------------------*
    DATA(lv_usuario) = cl_abap_context_info=>get_user_technical_name( ).

    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_guard) = etapa_valida( iv_shnumber = ls_key-Shnumber
                                     iv_remessa  = ls_key-DeliveryNumber
                                     iv_item     = ls_key-DeliveryItem
                                     iv_status_esp = '01' ).
      IF lv_guard IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_guard ) ) TO reported-descarga.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-descarga.
        CONTINUE.
      ENDIF.

      SELECT SINGLE Matnr, Werks, PedidoCompra, ItemPedidoCompra,
                    QtdeNfe, UmNfe, QtdeRemessa, UniMedRemessa
        FROM zi_q2c_descarga
        WHERE Shnumber    = @ls_key-Shnumber
          AND Remessa     = @ls_key-DeliveryNumber
          AND ItemRemessa = @ls_key-DeliveryItem
        INTO @DATA(ls_desc).

      " Validacao de negocio ANTES de disparar a LUW paralela: valores fora de faixa
      " razoavel estouram a conversao volumetrica OIL (CONVT_OVERFLOW) ou a BAPI. So
      " entra na classe paralela o que REALMENTE pode ser gravado.
      DATA lv_erro TYPE string.
      DATA(lv_um_ref) = COND meins( WHEN ls_desc-UmNfe IS NOT INITIAL THEN ls_desc-UmNfe
                                    WHEN ls_desc-UniMedRemessa IS NOT INITIAL THEN ls_desc-UniMedRemessa
                                    ELSE 'L' ).
      DATA(lv_qtd_max) = COND menge_d( WHEN ls_desc-QtdeRemessa > 0 THEN ls_desc-QtdeRemessa
                                       WHEN ls_desc-QtdeNfe > 0 THEN ls_desc-QtdeNfe
                                       ELSE 0 ).

      CLEAR lv_erro.
      IF ls_key-%param-qtdAmostra <= 0.
        lv_erro = 'Quantidade da amostra deve ser maior que zero.'(020).
      ELSEIF lv_qtd_max > 0 AND ls_key-%param-qtdAmostra > lv_qtd_max.
        lv_erro = |Quantidade da amostra nao pode exceder a quantidade do TD ({ lv_qtd_max NUMBER = USER } { lv_um_ref }).|.
      ELSEIF ls_key-%param-umAmostra <> lv_um_ref.
        lv_erro = |Unidade da amostra deve ser { lv_um_ref } (igual a do TD).|.
      ELSEIF ls_key-%param-densidadeNfe < '0.1' OR ls_key-%param-densidadeNfe > '2.0'.
        lv_erro = 'Densidade NF-e fora da faixa valida (0,1 a 2,0).'(021).
      ELSEIF ls_key-%param-lgortAmostra IS INITIAL.
        lv_erro = 'Informe o deposito da amostra.'(022).
      ENDIF.

      IF lv_erro IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = lv_erro ) ) TO reported-descarga.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-descarga.
        CONTINUE.
      ENDIF.

      DATA(ls_amostra) = VALUE zcl_q2c_desc_amostra=>ty_amostra(
        shnumber         = ls_key-Shnumber
        remessa          = ls_key-DeliveryNumber
        item_remessa     = ls_key-DeliveryItem
        matnr            = ls_desc-Matnr
        werks            = ls_desc-Werks
        pedido_compra    = ls_desc-PedidoCompra
        item_pedido      = ls_desc-ItemPedidoCompra
        qtd_amostra      = ls_key-%param-qtdAmostra
        um_amostra       = ls_key-%param-umAmostra
        lgort_amostra    = ls_key-%param-lgortAmostra
        compartimento    = ls_key-%param-compartimento
        ponto_amostragem = ls_key-%param-pontoAmostragem
        densidade_nfe    = ls_key-%param-densidadeNfe
        usuario          = lv_usuario ).

      NEW zcl_q2c_desc_amostra( )->execute_process(
        EXPORTING is_amostra = ls_amostra
        IMPORTING es_result  = DATA(ls_result) ).

      IF ls_result-return-type CA 'EAX'.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = ls_result-return-message ) ) TO reported-descarga.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-descarga.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zi_q2c_moni_descarga IN LOCAL MODE
      ENTITY Descarga
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_read_amo).
    result = VALUE #( FOR ls IN lt_read_amo ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.

ENDCLASS.
