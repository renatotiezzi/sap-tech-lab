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
*& RTiezzi
*&   V05 - Ajuste funcional de elegibilidade para remarcacao:
*&   - nao listar o material original da reserva como candidato.
*&   - manter somente materiais substitutos no resultado final.
*&
*&   Rota correta: SELECT direto em ZI_S2M_MATERIAIS_COMPAT pelo
*&   material componente (antes: I_MasterRecipeMaterialAssgmt retornava
*&   grupos da receita do produto - grupo errado para o componente).
*&
*&   Buffer: DELETE antes do MODIFY em insert_ordem/insert_materiais
*&   para evitar dados obsoletos de execucoes anteriores.
*&
*&   charcinternalid lido de I_ClfnCharcDesc (Grp Receita Mestre)
*&   em vez de valores hardcoded. Fail-safe: sem IDs ativos -> RETURN.
*&---------------------------------------------------------------------*

    DATA ls_materiais_compat TYPE ztbs2m_mat_compa.
    DATA: lv_ok_count     TYPE i,
          lv_charcs_count TYPE i.
    DATA lv_tabix TYPE sy-tabix.

*   RTiezzi: buscar IDs de 'Grp Receita Mestre' via I_ClfnCharcDesc
    TYPES: BEGIN OF ty_charc,
             charcinternalid TYPE i_clfncharcdesc-charcinternalid,
           END OF ty_charc.
    DATA lt_valid_charcs TYPE TABLE OF ty_charc.
    DATA lr_valid_charc  TYPE RANGE OF i_clfncharcdesc-charcinternalid.

    SELECT charcinternalid
      FROM i_clfncharcdesc
      WHERE language          = 'P'
        AND charcdescription  = 'Grp Receita Mestre'
        AND validitystartdate <= @sy-datum
        AND validityenddate   >= @sy-datum
        AND isdeleted         = ''
      INTO TABLE @lt_valid_charcs.

    " Fail-safe: sem IDs validos -> nao ha o que processar
    IF lt_valid_charcs IS INITIAL.
      RETURN.
    ENDIF.

    lv_charcs_count = lines( lt_valid_charcs ).

    lr_valid_charc = VALUE #(
      FOR lv IN lt_valid_charcs
      ( sign = 'I' option = 'EQ' low = lv-charcinternalid )
    ).

*   RTiezzi: buscar grupos de compatibilidade direto pelo material componente
    SELECT DISTINCT material AS material,
                    grupo    AS grupo
      FROM zi_s2m_materiais_compat
      WHERE centro   IN @ir_plant
        AND material IN @ir_material
      INTO TABLE @DATA(lt_grupo_compat).

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    SORT lt_grupo_compat BY grupo.
    DELETE ADJACENT DUPLICATES FROM lt_grupo_compat COMPARING grupo.

    " Buscar todos os materiais substitutos desses grupos
    SELECT *
      FROM zi_s2m_materiais_compat
      FOR ALL ENTRIES IN @lt_grupo_compat
      WHERE grupo = @lt_grupo_compat-grupo
      INTO TABLE @DATA(lt_materiais).

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    " V05 - IMPORTANTE:
    " Foi removida a exclusao global por ir_material neste ponto, pois ela
    " removia substitutos validos de outras ordens na mesma execucao.
    " Linha antiga (desativada propositalmente):
  *   DELETE lt_materiais WHERE material IN ir_material.
    " A exclusao do material original agora e feita por ordem no map_atom
    " (AND material <> <fs_comp_monitor>-material).

    IF lt_materiais IS INITIAL.
      RETURN.
    ENDIF.

    " Base para pivot: dedup por combinacao chave
    DATA(lt_materiais_aux) = lt_materiais.
    SORT lt_materiais_aux BY material centro billofoperationstype grupo lote deposito.
    DELETE ADJACENT DUPLICATES FROM lt_materiais_aux
      COMPARING material centro billofoperationstype grupo lote deposito.

    SORT lt_materiais BY material centro billofoperationstype grupo lote deposito.

*   RTiezzi: pivot dinamico - verifica se TODOS os IDs validos estao presentes no lote
    LOOP AT lt_materiais_aux ASSIGNING FIELD-SYMBOL(<fs_materiais_aux>).
      lv_tabix = sy-tabix.
      CLEAR lv_ok_count.
      ls_materiais_compat = CORRESPONDING #( <fs_materiais_aux> ).

      LOOP AT lt_materiais ASSIGNING FIELD-SYMBOL(<fs_grupo_mat>)
        WHERE material             = <fs_materiais_aux>-material
          AND centro               = <fs_materiais_aux>-centro
          AND billofoperationstype = <fs_materiais_aux>-billofoperationstype
          AND grupo                = <fs_materiais_aux>-grupo
          AND lote                 = <fs_materiais_aux>-lote
          AND deposito             = <fs_materiais_aux>-deposito.

        IF <fs_grupo_mat>-charcinternalid IN lr_valid_charc.
          lv_ok_count = lv_ok_count + 1.
          " Armazena nos 3 campos do buffer conforme posicao sequencial
          CASE lv_ok_count.
            WHEN 1. ls_materiais_compat-charcinternalid  = <fs_grupo_mat>-charcinternalid.
            WHEN 2. ls_materiais_compat-charcinternalid2 = <fs_grupo_mat>-charcinternalid.
            WHEN 3. ls_materiais_compat-charcinternalid3 = <fs_grupo_mat>-charcinternalid.
          ENDCASE.
        ENDIF.

      ENDLOOP.

      " Inclui apenas se TODOS os IDs validos foram encontrados
      IF lv_ok_count = lv_charcs_count.
        APPEND ls_materiais_compat TO et_materiais_compat.
      ENDIF.

    ENDLOOP.

    " V05 - Eliminar duplicidade de lotes com multiplos grupos
    " Manter apenas a primeira ocorrencia de cada material/centro/lote/deposito
    IF et_materiais_compat IS NOT INITIAL.
      DATA lt_dedup_lote TYPE TABLE OF ztbs2m_mat_compa.
      DATA ls_last_lote TYPE ztbs2m_mat_compa.

*     V07 - RTIEZZI - Prioriza a versao de producao mais nova antes da deduplicacao final do lote.
      SORT et_materiais_compat BY material centro lote deposito productionversion DESCENDING grupo.

      CLEAR ls_last_lote.
      LOOP AT et_materiais_compat ASSIGNING FIELD-SYMBOL(<fs_compat>).
        IF ls_last_lote-material    <> <fs_compat>-material
        OR ls_last_lote-centro      <> <fs_compat>-centro
        OR ls_last_lote-lote        <> <fs_compat>-lote
        OR ls_last_lote-deposito    <> <fs_compat>-deposito.
          APPEND <fs_compat> TO lt_dedup_lote.
          ls_last_lote = <fs_compat>.
        ENDIF.
      ENDLOOP.

      et_materiais_compat = lt_dedup_lote.
    ENDIF.

  ENDMETHOD.


  METHOD insert_ordem.

*   RTiezzi: DELETE antes do MODIFY para evitar dados obsoletos no buffer
    IF it_ordem IS NOT INITIAL.

      DATA lr_reservation_o TYPE RANGE OF rsnum.
      lr_reservation_o = VALUE #(
        FOR ls IN it_ordem ( sign = 'I' option = 'EQ' low = ls-reservation )
      ).
      DELETE FROM ztbs2m_ordem WHERE reservation IN @lr_reservation_o.
      MODIFY ztbs2m_ordem FROM TABLE @it_ordem.
      IF sy-subrc IS INITIAL.
        COMMIT WORK AND WAIT.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD insert_materiais.

*   RTiezzi: DELETE antes do MODIFY para evitar dados obsoletos no buffer
    IF it_mat_compativeis IS NOT INITIAL.

      DATA lr_reservation_m TYPE RANGE OF rsnum.
      lr_reservation_m = VALUE #(
        FOR ls IN it_mat_compativeis ( sign = 'I' option = 'EQ' low = ls-reservation )
      ).

      DELETE FROM ztbs2m_mat_compa WHERE reservation IN @lr_reservation_m.
      MODIFY ztbs2m_mat_compa FROM TABLE @it_mat_compativeis.
      IF sy-subrc IS INITIAL.
        COMMIT WORK AND WAIT.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
