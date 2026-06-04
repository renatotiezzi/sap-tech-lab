CLASS zcls2m_materiais_ordem DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .


  PUBLIC SECTION.
    METHODS: get_materiais_ordem
      IMPORTING ir_plant            TYPE t_range_werks
                ir_material         TYPE surdpt_material_range
      EXPORTING
                et_materiais_compat TYPE ztts2m_materiais_compativeis,

      insert_ordem
        IMPORTING it_ordem TYPE ztts2m_ordem,
      insert_materiais
        IMPORTING it_mat_compativeis TYPE ztts2m_materiais_compativeis
        .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCLS2M_MATERIAIS_ORDEM IMPLEMENTATION.


  METHOD get_materiais_ordem.

    DATA ls_materiais_compat TYPE ztbs2m_mat_compa.
    DATA lt_materiais_compat TYPE TABLE OF ztbs2m_mat_compa.

    DATA: lv_ok TYPE i VALUE 0.
    DATA: lv_tabix TYPE sy-tabix.

    SELECT DISTINCT billofoperationsgroup
          FROM i_masterrecipematerialassgmt
          WHERE plant IN @ir_plant
          AND material IN @ir_material
            INTO TABLE @DATA(lt_grupo_mat).


    IF sy-subrc IS INITIAL.

      SORT lt_grupo_mat BY billofoperationsgroup.
      DELETE ADJACENT DUPLICATES FROM lt_grupo_mat COMPARING billofoperationsgroup.

*Materiais do standard
      SELECT *
      FROM zi_s2m_materiais_compat
      FOR ALL ENTRIES IN @lt_grupo_mat
      WHERE grupo = @lt_grupo_mat-billofoperationsgroup
        INTO TABLE @DATA(lt_materiais).

      IF sy-subrc IS INITIAL.

        DATA(lt_materiais_aux) = lt_materiais.

        SORT lt_materiais_aux BY material centro billofoperationstype grupo lote deposito.
        DELETE ADJACENT DUPLICATES FROM lt_materiais_aux COMPARING material centro billofoperationstype grupo lote deposito.

        SORT lt_materiais BY material centro billofoperationstype grupo lote deposito.


        LOOP AT lt_materiais_aux ASSIGNING FIELD-SYMBOL(<fs_materiais_aux>).
          lv_tabix = sy-tabix.
          CLEAR lv_ok.
          ls_materiais_compat = CORRESPONDING #( <fs_materiais_aux> ).
          LOOP AT lt_materiais ASSIGNING FIELD-SYMBOL(<fs_grupo_mat>) WHERE material = <fs_materiais_aux>-material
                                                                      AND  centro = <fs_materiais_aux>-centro
                                                                      AND  billofoperationstype = <fs_materiais_aux>-billofoperationstype
                                                                      AND  grupo = <fs_materiais_aux>-grupo
                                                                      AND  lote = <fs_materiais_aux>-lote
                                                                      AND  deposito = <fs_materiais_aux>-deposito.

            CASE <fs_grupo_mat>-charcinternalid.
              WHEN '991'.
                ls_materiais_compat-charcinternalid = <fs_grupo_mat>-charcinternalid.
                lv_ok  = lv_ok  + 1.
              WHEN '998'.
                ls_materiais_compat-charcinternalid2 = <fs_grupo_mat>-charcinternalid.
                lv_ok  = lv_ok  + 1.
              WHEN '1031'.
                ls_materiais_compat-charcinternalid3 = <fs_grupo_mat>-charcinternalid.
                lv_ok = lv_ok + 1.
              WHEN OTHERS.
                lv_ok = lv_ok + 1.
            ENDCASE.

            IF lv_ok > 3.
              EXIT.
            ENDIF.

          ENDLOOP.
          IF lv_ok NE 3.
            DELETE lt_materiais WHERE material = <fs_materiais_aux>-material
                                                                      AND  centro = <fs_materiais_aux>-centro
                                                                      AND  billofoperationstype = <fs_materiais_aux>-billofoperationstype
                                                                      AND  grupo = <fs_materiais_aux>-grupo
                                                                      AND lote = <fs_materiais_aux>-lote
                                                                      AND deposito = <fs_materiais_aux>-deposito.
          ELSEIF lv_ok EQ 3.
            APPEND ls_materiais_compat TO et_materiais_compat.
          ENDIF.
        ENDLOOP.

      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD insert_ordem.

    IF it_ordem IS NOT INITIAL.

      MODIFY ztbs2m_ordem FROM TABLE @it_ordem.
      IF sy-subrc IS INITIAL.
        COMMIT WORK AND WAIT.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD insert_materiais.
    IF it_mat_compativeis IS NOT INITIAL.

      MODIFY ztbs2m_mat_compa FROM TABLE @it_mat_compativeis.
      IF sy-subrc IS INITIAL.
        COMMIT WORK AND WAIT.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
