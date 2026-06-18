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
                      Aedat )
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
                      Aedat               = sy-datum ) )
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
