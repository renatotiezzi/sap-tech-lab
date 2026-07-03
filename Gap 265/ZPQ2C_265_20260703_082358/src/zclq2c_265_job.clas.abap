CLASS zclq2c_265_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_templ_val,
        selname(8) TYPE  c,
        kind(1)    TYPE  c,
        sign(1)    TYPE  c,
        option(2)  TYPE  c,
        low        TYPE  rvari_val_255,
        high       TYPE  rvari_val_255,
      END OF ty_templ_val,

      tt_templ_val TYPE STANDARD TABLE OF ty_templ_val WITH NON-UNIQUE KEY selname,

      BEGIN OF ty_message,
        name       TYPE eps2filnam,
        shnumber   TYPE oig_shnum,
        com_number TYPE oig_cmpnmr,
        id         TYPE symsgid,
        number     TYPE symsgno,
        type       TYPE symsgty,
        severity   TYPE if_abap_behv_message=>t_severity,
        v1         TYPE string,
        v2         TYPE string,
        v3         TYPE string,
        v4         TYPE string,
      END OF ty_message .
    TYPES:
      tt_message TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY .


ENDCLASS.



CLASS zclq2c_265_job IMPLEMENTATION.


  METHOD if_apj_dt_exec_object~get_parameters.

    et_parameter_def  = VALUE #( ( selname = 'PATH'
                                   kind = if_apj_dt_exec_object=>parameter
                                   datatype = 'C'
                                   length = '255'
                                   param_text = 'Pasta Arquivo'
                                   lowercase_ind = abap_true
                                   changeable_ind = abap_true )

                                   ( selname = 'SHP_DOC'
                                   kind = if_apj_dt_exec_object=>parameter
                                   datatype = 'C'
                                   length = '10'
                                   param_text = 'Documentos Remessa'
                                   changeable_ind = abap_true )

                                   ( selname = 'COMP_NUM'
                                   kind = if_apj_dt_exec_object=>parameter
                                   datatype = 'C'
                                   length = '3'
                                   param_text = 'Compartimento'
                                   changeable_ind = abap_true ) ).

  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.

    DATA: lt_param            TYPE tt_templ_val,
          lt_msg              TYPE tt_message,
          lo_carga_ret_granel TYPE REF TO zclq2c_265_carga_ret_granel.

    DATA: lv_path     TYPE string,
          lv_shp_num  TYPE oig_shnum,
          lv_comp_num TYPE oig_cmpnmr.

    lt_param = it_parameters.

    lv_path = VALUE #( lt_param[ selname = 'PATH' ]-low OPTIONAL ).

    lv_shp_num = VALUE #( lt_param[ selname = 'SHP_DOC' ]-low OPTIONAL ).

    lv_comp_num = VALUE #( lt_param[ selname = 'COMP_NUM' ]-low OPTIONAL ).


    CREATE OBJECT lo_carga_ret_granel
      EXPORTING
        iv_folder     = lv_path
        iv_shnumber   = lv_shp_num
        iv_com_number = lv_comp_num
        iv_job        = abap_true.

    lo_carga_ret_granel->execute( CHANGING ct_msg = lt_msg ).

  ENDMETHOD.
ENDCLASS.
