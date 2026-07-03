CLASS zclq2c_265_desc_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_templ_val,
             selname(8) TYPE c,
             kind(1)    TYPE c,
             sign(1)    TYPE c,
             option(2)  TYPE c,
             low        TYPE rvari_val_255,
             high       TYPE rvari_val_255,
           END OF ty_templ_val.

    TYPES tt_templ_val TYPE STANDARD TABLE OF ty_templ_val WITH NON-UNIQUE KEY selname.
ENDCLASS.



CLASS zclq2c_265_desc_job IMPLEMENTATION.

  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #(
      ( selname = 'PATH'     kind = if_apj_dt_exec_object=>parameter datatype = 'C' length = '255' param_text = 'Pasta Arquivo' lowercase_ind = abap_true changeable_ind = abap_true )
      ( selname = 'ORDERNUM' kind = if_apj_dt_exec_object=>parameter datatype = 'C' length = '20'  param_text = 'Order Number'  lowercase_ind = abap_true changeable_ind = abap_true ) ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    DATA lt_param TYPE tt_templ_val.
    DATA lv_ordernum TYPE string.
    DATA lo_desc TYPE REF TO zclq2c_265_desc_ret_granel.
    DATA lt_msg TYPE zclq2c_265_desc_common=>tt_message.

    lt_param = it_parameters.
    lv_ordernum = VALUE #( lt_param[ selname = 'ORDERNUM' ]-low OPTIONAL ).

    CREATE OBJECT lo_desc EXPORTING iv_job = abap_true.
    lo_desc->execute( CHANGING ct_msg = lt_msg ).
  ENDMETHOD.

ENDCLASS.
