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
*&  FIX 3 — Pivot substituído por flags booleanas → V2 estende para
*&           uso dinâmico dos IDs via I_ClfnCharcDesc.
*&
*& Ajuste V2 (REQ1):
*&  Substitui CASE hardcoded WHEN '991'/'998'/'1031' por busca dinâmica
*&  em I_ClfnCharcDesc (Language='P', CharcDescription='Grp Receita Mestre',
*&  datas válidas, IsDeleted='').
*&  A condição de inclusão passa a ser: todos os IDs retornados pela CDS
*&  estão presentes no lote (lv_ok_count = lv_charcs_count).
*&---------------------------------------------------------------------*

    DATA ls_materiais_compat TYPE ztbs2m_mat_compa.

    DATA: lv_ok_count    TYPE i,
          lv_charcs_count TYPE i.

    DATA: lv_tabix TYPE sy-tabix.

*&---------------------------------------------------------------------*
*& V2 — REQ1: Buscar charcinternalids válidos dinamicamente
*&---------------------------------------------------------------------*
    TYPES: BEGIN OF ty_charc,
             charcinternalid TYPE i_clfncharcdesc-charcinternalid,
           END OF ty_charc.
    DATA lt_valid_charcs TYPE TABLE OF ty_charc.
    DATA lr_valid_charc  TYPE RANGE OF i_clfncharcdesc-charcinternalid.

    SELECT charcinternalid
      FROM i_clfncharcdesc
      WHERE language          =  'P'
        AND charcdescription  =  'Grp Receita Mestre'
        AND validitystartdate <= @sy-datum
        AND validityenddate   >= @sy-datum
        AND isdeleted         =  ''
      INTO TABLE @lt_valid_charcs.

    " Fail-safe: se não houver IDs válidos na CDS, não há o que processar
    IF lt_valid_charcs IS INITIAL.
      RETURN.
    ENDIF.

    lv_charcs_count = lines( lt_valid_charcs ).

    lr_valid_charc = VALUE #(
      FOR lv IN lt_valid_charcs
      ( sign = 'I' option = 'EQ' low = lv-charcinternalid )
    ).

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

*&---------------------------------------------------------------------*
*& V2 — REQ1: Pivot dinâmico usando IDs de I_ClfnCharcDesc
*& (substitui CASE WHEN '991'/'998'/'1031' por verificação contra range)
*&---------------------------------------------------------------------*
    LOOP AT lt_materiais_aux ASSIGNING FIELD-SYMBOL(<fs_materiais_aux>).
      lv_tabix = sy-tabix.
      CLEAR: lv_ok_count.
      ls_materiais_compat = CORRESPONDING #( <fs_materiais_aux> ).

      LOOP AT lt_materiais ASSIGNING FIELD-SYMBOL(<fs_grupo_mat>)
        WHERE material          = <fs_materiais_aux>-material
          AND centro            = <fs_materiais_aux>-centro
          AND billofoperationstype = <fs_materiais_aux>-billofoperationstype
          AND grupo             = <fs_materiais_aux>-grupo
          AND lote              = <fs_materiais_aux>-lote
          AND deposito          = <fs_materiais_aux>-deposito.

*       V2: checar se o charcinternalid atual é um ID válido de 'Grp Receita Mestre'
        IF <fs_grupo_mat>-charcinternalid IN lr_valid_charc.
          lv_ok_count = lv_ok_count + 1.
*         Armazenar em charcinternalid / charcinternalid2 / charcinternalid3
*         conforme posição sequencial (compatível com buffer existente)
          CASE lv_ok_count.
            WHEN 1.
              ls_materiais_compat-charcinternalid  = <fs_grupo_mat>-charcinternalid.
            WHEN 2.
              ls_materiais_compat-charcinternalid2 = <fs_grupo_mat>-charcinternalid.
            WHEN 3.
              ls_materiais_compat-charcinternalid3 = <fs_grupo_mat>-charcinternalid.
          ENDCASE.
        ENDIF.

      ENDLOOP.

*     V2: incluir somente se TODOS os IDs válidos foram encontrados no lote
      IF lv_ok_count = lv_charcs_count.
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
