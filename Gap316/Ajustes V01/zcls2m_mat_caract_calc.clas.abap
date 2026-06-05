CLASS zcls2m_mat_caract_calc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit .
    INTERFACES if_sadl_exit_filter_transform .
    INTERFACES if_sadl_exit_calc_element_read .

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF c_common_fields,
        updatetable TYPE string VALUE 'UPDATETABLE',
      END OF c_common_fields .

ENDCLASS.



CLASS zcls2m_mat_caract_calc IMPLEMENTATION.


  METHOD if_sadl_exit_calc_element_read~calculate.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
  ENDMETHOD.

  METHOD if_sadl_exit_filter_transform~map_atom.

    DATA(lo_cfac) = cl_sadl_cond_prov_factory_pub=>create_simple_cond_factory( ).

    DATA(lo_materiais_ordem) = NEW zcls2m_materiais_ordem( ).

    DATA: ls_ordem           TYPE ztbs2m_ordem.
    DATA: lt_ordem           TYPE TABLE OF ztbs2m_ordem.
    DATA: ls_mat_compativeis TYPE ztbs2m_mat_compa.
    DATA: lt_mat_compativeis TYPE TABLE OF ztbs2m_mat_compa.

    DATA lr_plant TYPE t_range_werks.

    CASE iv_element.

      WHEN c_common_fields-updatetable.

        SELECT *
          FROM zr_s2m_ordem
          WHERE reservation IS NOT INITIAL
          INTO TABLE @DATA(lt_comp_monitor).

        DATA(lt_plant) = lt_comp_monitor.
        SORT lt_plant BY plant.
        DELETE ADJACENT DUPLICATES FROM lt_plant COMPARING plant.

        lr_plant = VALUE t_range_werks(
          FOR ls IN lt_plant
          ( sign = 'I' option = 'EQ' low = ls-plant )
        ).

        DATA(lt_material) = lt_comp_monitor.
        SORT lt_material BY material.
        DELETE ADJACENT DUPLICATES FROM lt_material COMPARING material.

        DATA(lr_material) = VALUE surdpt_material_range(
          FOR ls IN lt_material
          ( sign = 'I' option = 'EQ' low = ls-material )
        ).

        DELETE lt_comp_monitor WHERE reservation IS INITIAL.

        lo_materiais_ordem->get_materiais_ordem(
          EXPORTING
            ir_plant    = lr_plant
            ir_material = lr_material
          IMPORTING
            et_materiais_compat = DATA(lt_materiais_compat)
        ).

*&---------------------------------------------------------------------*
*& FIX 2: Evitar cross-join no loop interno
*&
*& Problema original: LOOP AT lt_materiais_compat sem filtro vinculava
*& TODOS os compatíveis de TODAS as ordens a CADA reserva.
*&
*& Solução: obter mapeamento material_componente → grupo_compatibilidade
*& via ZI_S2M_MATERIAIS_COMPAT e usar loop triplo filtrado.
*& Cada reserva recebe apenas os compatíveis do SEU grupo.
*&---------------------------------------------------------------------*
        DATA: BEGIN OF ls_mat_grp,
                material TYPE ztbs2m_mat_compa-material,
                grupo    TYPE ztbs2m_mat_compa-grupo,
              END OF ls_mat_grp.
        DATA lt_mat_grupo_map LIKE TABLE OF ls_mat_grp.

        IF lr_material IS NOT INITIAL.
          SELECT DISTINCT material AS material,
                          grupo    AS grupo
            FROM zi_s2m_materiais_compat
            WHERE material IN @lr_material
            INTO CORRESPONDING FIELDS OF TABLE @lt_mat_grupo_map.
        ENDIF.

        IF lt_materiais_compat IS NOT INITIAL.

          LOOP AT lt_comp_monitor ASSIGNING FIELD-SYMBOL(<fs_comp_monitor>).

            ls_ordem-reservation              = <fs_comp_monitor>-reservation.
            ls_ordem-reservation_item         = <fs_comp_monitor>-reservationitem.
            ls_ordem-reservation_record_type  = <fs_comp_monitor>-reservationrecordtype.
            ls_ordem-material_group           = <fs_comp_monitor>-materialgroup.
            ls_ordem-material                 = <fs_comp_monitor>-material.
            ls_ordem-plant                    = <fs_comp_monitor>-plant.
            ls_ordem-manufacturing_order      = <fs_comp_monitor>-manufacturingorder.
            ls_ordem-orderoperationinternalid = <fs_comp_monitor>-orderoperationinternalid.

            APPEND ls_ordem TO lt_ordem.

*           FIX 2: iterar pelos grupos deste material componente
            LOOP AT lt_mat_grupo_map ASSIGNING FIELD-SYMBOL(<fs_mat_grp>)
              WHERE material = <fs_comp_monitor>-material.

*             FIX 2: filtrar compatíveis apenas pelo grupo do material
              LOOP AT lt_materiais_compat ASSIGNING FIELD-SYMBOL(<fs_materiais_compat>)
                WHERE grupo = <fs_mat_grp>-grupo.

                ls_mat_compativeis = CORRESPONDING #( <fs_materiais_compat> ).
                ls_mat_compativeis-reservation             = ls_ordem-reservation.
                ls_mat_compativeis-reservation_item        = ls_ordem-reservation_item.
                ls_mat_compativeis-reservation_record_type = ls_ordem-reservation_record_type.

                APPEND ls_mat_compativeis TO lt_mat_compativeis.

              ENDLOOP.

            ENDLOOP.

          ENDLOOP.

        ENDIF.

        IF lt_ordem IS NOT INITIAL.
          lo_materiais_ordem->insert_ordem( EXPORTING it_ordem = lt_ordem ).
        ENDIF.

        IF lt_mat_compativeis IS NOT INITIAL.
          lo_materiais_ordem->insert_materiais( EXPORTING it_mat_compativeis = lt_mat_compativeis ).
        ENDIF.

    ENDCASE.

    " Dummy filter para evitar DUMP. Objetivo: disparar update do buffer antes do SELECT principal
    DATA(lo_doccomp) = lo_cfac->element( 'PLANT' ).
    ro_condition = lo_doccomp->is_not_null( ).

  ENDMETHOD.

ENDCLASS.
