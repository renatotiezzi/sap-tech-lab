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
*&---------------------------------------------------------------------*
*& Ajuste V1:
*&  FIX 1 — Rota correta: consulta ZI_S2M_MATERIAIS_COMPAT diretamente
*&           pelo material (grupo de compatibilidade), eliminando a
*&           passagem por I_MasterRecipeMaterialAssgmt.
*&  FIX 3 — Pivot substituído por flags booleanas independentes
*&           (evita lv_ok > 3 por WHEN OTHERS).
*&  Material_fonte: retornado no et_materiais_compat para viabilizar
*&           o filtro correto no loop do MAP_ATOM (FIX 2).
*&---------------------------------------------------------------------*

    DATA ls_materiais_compat TYPE ztbs2m_mat_compa.

    DATA: lv_has_991  TYPE abap_bool,
          lv_has_998  TYPE abap_bool,
          lv_has_1031 TYPE abap_bool.

    DATA: lv_tabix TYPE sy-tabix.

*   FIX 1 — Buscar grupos de compatibilidade diretamente pelo material
*   (antes: passava por I_MasterRecipeMaterialAssgmt → grupos da receita)
    SELECT DISTINCT material AS material, grupo AS grupo
      FROM zi_s2m_materiais_compat
      WHERE centro   IN @ir_plant
        AND material IN @ir_material
      INTO TABLE @DATA(lt_grupo_compat).

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    SORT lt_grupo_compat BY grupo.
    DELETE ADJACENT DUPLICATES FROM lt_grupo_compat COMPARING grupo.

    " Buscar todos os materiais substitutos desses grupos de compatibilidade
    SELECT *
      FROM zi_s2m_materiais_compat
      FOR ALL ENTRIES IN @lt_grupo_compat
      WHERE grupo = @lt_grupo_compat-grupo
      INTO TABLE @DATA(lt_materiais).

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    " Dedup base para pivot
    DATA(lt_materiais_aux) = lt_materiais.
    SORT lt_materiais_aux BY material centro billofoperationstype grupo lote deposito.
    DELETE ADJACENT DUPLICATES FROM lt_materiais_aux
      COMPARING material centro billofoperationstype grupo lote deposito.

    SORT lt_materiais BY material centro billofoperationstype grupo lote deposito.

*   FIX 3 — Pivot com flags booleanas independentes (substitui lv_ok inteiro)
    LOOP AT lt_materiais_aux ASSIGNING FIELD-SYMBOL(<fs_materiais_aux>).
      lv_tabix = sy-tabix.
      CLEAR: lv_has_991, lv_has_998, lv_has_1031.
      ls_materiais_compat = CORRESPONDING #( <fs_materiais_aux> ).

      LOOP AT lt_materiais ASSIGNING FIELD-SYMBOL(<fs_grupo_mat>)
        WHERE material          = <fs_materiais_aux>-material
          AND centro            = <fs_materiais_aux>-centro
          AND billofoperationstype = <fs_materiais_aux>-billofoperationstype
          AND grupo             = <fs_materiais_aux>-grupo
          AND lote              = <fs_materiais_aux>-lote
          AND deposito          = <fs_materiais_aux>-deposito.

        CASE <fs_grupo_mat>-charcinternalid.
          WHEN '991'.
            ls_materiais_compat-charcinternalid  = <fs_grupo_mat>-charcinternalid.
            lv_has_991  = abap_true.
          WHEN '998'.
            ls_materiais_compat-charcinternalid2 = <fs_grupo_mat>-charcinternalid.
            lv_has_998  = abap_true.
          WHEN '1031'.
            ls_materiais_compat-charcinternalid3 = <fs_grupo_mat>-charcinternalid.
            lv_has_1031 = abap_true.
        ENDCASE.

      ENDLOOP.

      " Inclui somente se as 3 características estão presentes
      IF lv_has_991 = abap_true AND lv_has_998 = abap_true AND lv_has_1031 = abap_true.
        APPEND ls_materiais_compat TO et_materiais_compat.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD insert_ordem.
*&---------------------------------------------------------------------*
*& Ajuste V1 — FIX 3 (Buffer DELETE):
*&   Deletar registros existentes antes do MODIFY para evitar dados
*&   obsoletos de execuções anteriores.
*&---------------------------------------------------------------------*
    IF it_ordem IS NOT INITIAL.

      " Limpar buffer para as reservas que serão reinseridas
      DATA lr_reservation_o TYPE RANGE OF rsnum.
      lr_reservation_o = VALUE #( FOR ls IN it_ordem ( sign = 'I' option = 'EQ' low = ls-reservation ) ).
      DELETE FROM ztbs2m_ordem WHERE reservation IN @lr_reservation_o.

      MODIFY ztbs2m_ordem FROM TABLE @it_ordem.
      IF sy-subrc IS INITIAL.
        COMMIT WORK AND WAIT.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD insert_materiais.
*&---------------------------------------------------------------------*
*& Ajuste V1 — FIX 3 (Buffer DELETE):
*&   Deletar registros existentes antes do MODIFY para evitar dados
*&   obsoletos de execuções anteriores.
*&---------------------------------------------------------------------*
    IF it_mat_compativeis IS NOT INITIAL.

      " Limpar buffer para as reservas que serão reinseridas
      DATA lr_reservation_m TYPE RANGE OF rsnum.
      lr_reservation_m = VALUE #( FOR ls IN it_mat_compativeis ( sign = 'I' option = 'EQ' low = ls-reservation ) ).
      DELETE FROM ztbs2m_mat_compa WHERE reservation IN @lr_reservation_m.

      MODIFY ztbs2m_mat_compa FROM TABLE @it_mat_compativeis.
      IF sy-subrc IS INITIAL.
        COMMIT WORK AND WAIT.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
