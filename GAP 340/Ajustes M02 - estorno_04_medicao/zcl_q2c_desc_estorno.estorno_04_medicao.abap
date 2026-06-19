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
