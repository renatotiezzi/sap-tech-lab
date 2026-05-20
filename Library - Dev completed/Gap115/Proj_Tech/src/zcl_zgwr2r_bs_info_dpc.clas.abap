class ZCL_ZGWR2R_BS_INFO_DPC definition
  public
  inheriting from /IWBEP/CL_MGW_PUSH_ABS_DATA
  abstract
  create public .

public section.

  interfaces /IWBEP/IF_SB_DPC_COMM_SERVICES .
  interfaces /IWBEP/IF_SB_GEN_DPC_INJECTION .

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~UPDATE_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~DELETE_ENTITY
    redefinition .
protected section.

  data mo_injection type ref to /IWBEP/IF_SB_GEN_DPC_INJECTION .
  data GT_AREA_ADVERT type ZCL_TVARVC_RANGE=>TY_RANGE_TABLE .
  data GT_BLOQ_PAGTO type ZCL_TVARVC_RANGE=>TY_RANGE_TABLE .
  data GT_CREDITO type ZCL_TVARVC_RANGE=>TY_RANGE_TABLE .
  data GT_DEBITO type ZCL_TVARVC_RANGE=>TY_RANGE_TABLE .
  data GT_LOCAL_NEG type ZCL_TVARVC_RANGE=>TY_RANGE_TABLE .
  data GT_MET_PAGTO type ZCL_TVARVC_RANGE=>TY_RANGE_TABLE .
  data GT_STAT_ITEM type ZCL_TVARVC_RANGE=>TY_RANGE_TABLE .
  data GT_TP_DOC_NOTA_CRED type ZCL_TVARVC_RANGE=>TY_RANGE_TABLE .

  methods ZSTR2R_BS_INFOSE_CREATE_ENTITY
    importing
      !IV_ENTITY_NAME type STRING
      !IV_ENTITY_SET_NAME type STRING
      !IV_SOURCE_NAME type STRING
      !IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR
      !IO_TECH_REQUEST_CONTEXT type ref to /IWBEP/IF_MGW_REQ_ENTITY_C optional
      !IT_NAVIGATION_PATH type /IWBEP/T_MGW_NAVIGATION_PATH
      !IO_DATA_PROVIDER type ref to /IWBEP/IF_MGW_ENTRY_PROVIDER optional
    exporting
      !ER_ENTITY type ZCL_ZGWR2R_BS_INFO_MPC=>TS_ZSTR2R_BS_INFO
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION
      /IWBEP/CX_MGW_TECH_EXCEPTION .
  methods ZSTR2R_BS_INFOSE_DELETE_ENTITY
    importing
      !IV_ENTITY_NAME type STRING
      !IV_ENTITY_SET_NAME type STRING
      !IV_SOURCE_NAME type STRING
      !IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR
      !IO_TECH_REQUEST_CONTEXT type ref to /IWBEP/IF_MGW_REQ_ENTITY_D optional
      !IT_NAVIGATION_PATH type /IWBEP/T_MGW_NAVIGATION_PATH
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION
      /IWBEP/CX_MGW_TECH_EXCEPTION .
  methods ZSTR2R_BS_INFOSE_GET_ENTITY
    importing
      !IV_ENTITY_NAME type STRING
      !IV_ENTITY_SET_NAME type STRING
      !IV_SOURCE_NAME type STRING
      !IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR
      !IO_REQUEST_OBJECT type ref to /IWBEP/IF_MGW_REQ_ENTITY optional
      !IO_TECH_REQUEST_CONTEXT type ref to /IWBEP/IF_MGW_REQ_ENTITY optional
      !IT_NAVIGATION_PATH type /IWBEP/T_MGW_NAVIGATION_PATH
    exporting
      !ER_ENTITY type ZCL_ZGWR2R_BS_INFO_MPC=>TS_ZSTR2R_BS_INFO
      !ES_RESPONSE_CONTEXT type /IWBEP/IF_MGW_APPL_SRV_RUNTIME=>TY_S_MGW_RESPONSE_ENTITY_CNTXT
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION
      /IWBEP/CX_MGW_TECH_EXCEPTION .
  methods ZSTR2R_BS_INFOSE_GET_ENTITYSET
    importing
      !IV_ENTITY_NAME type STRING
      !IV_ENTITY_SET_NAME type STRING
      !IV_SOURCE_NAME type STRING
      !IT_FILTER_SELECT_OPTIONS type /IWBEP/T_MGW_SELECT_OPTION
      !IS_PAGING type /IWBEP/S_MGW_PAGING
      !IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR
      !IT_NAVIGATION_PATH type /IWBEP/T_MGW_NAVIGATION_PATH
      !IT_ORDER type /IWBEP/T_MGW_SORTING_ORDER
      !IV_FILTER_STRING type STRING
      !IV_SEARCH_STRING type STRING
      !IO_TECH_REQUEST_CONTEXT type ref to /IWBEP/IF_MGW_REQ_ENTITYSET optional
    exporting
      !ET_ENTITYSET type ZCL_ZGWR2R_BS_INFO_MPC=>TT_ZSTR2R_BS_INFO
      !ES_RESPONSE_CONTEXT type /IWBEP/IF_MGW_APPL_SRV_RUNTIME=>TY_S_MGW_RESPONSE_CONTEXT
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION
      /IWBEP/CX_MGW_TECH_EXCEPTION .
  methods ZSTR2R_BS_INFOSE_UPDATE_ENTITY
    importing
      !IV_ENTITY_NAME type STRING
      !IV_ENTITY_SET_NAME type STRING
      !IV_SOURCE_NAME type STRING
      !IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR
      !IO_TECH_REQUEST_CONTEXT type ref to /IWBEP/IF_MGW_REQ_ENTITY_U optional
      !IT_NAVIGATION_PATH type /IWBEP/T_MGW_NAVIGATION_PATH
      !IO_DATA_PROVIDER type ref to /IWBEP/IF_MGW_ENTRY_PROVIDER optional
    exporting
      !ER_ENTITY type ZCL_ZGWR2R_BS_INFO_MPC=>TS_ZSTR2R_BS_INFO
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION
      /IWBEP/CX_MGW_TECH_EXCEPTION .

  methods CHECK_SUBSCRIPTION_AUTHORITY
    redefinition .
private section.

  methods GET_TVARV .
ENDCLASS.



CLASS ZCL_ZGWR2R_BS_INFO_DPC IMPLEMENTATION.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_ENTITY.
*&----------------------------------------------------------------------------------------------*
*&  Include           /IWBEP/DPC_TEMP_CRT_ENTITY_BASE
*&* This class has been generated on 30.01.2026 11:22:28 in client 100
*&*
*&*       WARNING--> NEVER MODIFY THIS CLASS <--WARNING
*&*   If you want to change the DPC implementation, use the
*&*   generated methods inside the DPC provider subclass - ZCL_ZGWR2R_BS_INFO_DPC_EXT
*&-----------------------------------------------------------------------------------------------*

 DATA zstr2r_bs_infose_create_entity TYPE zcl_zgwr2r_bs_info_mpc=>ts_zstr2r_bs_info.
 DATA lv_entityset_name TYPE string.

lv_entityset_name = io_tech_request_context->get_entity_set_name( ).

CASE lv_entityset_name.
*-------------------------------------------------------------------------*
*             EntitySet -  ZSTR2R_BS_INFOSet
*-------------------------------------------------------------------------*
     WHEN 'ZSTR2R_BS_INFOSet'.
*     Call the entity set generated method
    zstr2r_bs_infose_create_entity(
         EXPORTING iv_entity_name     = iv_entity_name
                   iv_entity_set_name = iv_entity_set_name
                   iv_source_name     = iv_source_name
                   io_data_provider   = io_data_provider
                   it_key_tab         = it_key_tab
                   it_navigation_path = it_navigation_path
                   io_tech_request_context = io_tech_request_context
       	 IMPORTING er_entity          = zstr2r_bs_infose_create_entity
    ).
*     Send specific entity data to the caller interfaces
    copy_data_to_ref(
      EXPORTING
        is_data = zstr2r_bs_infose_create_entity
      CHANGING
        cr_data = er_entity
   ).

  when others.
    super->/iwbep/if_mgw_appl_srv_runtime~create_entity(
       EXPORTING
         iv_entity_name = iv_entity_name
         iv_entity_set_name = iv_entity_set_name
         iv_source_name = iv_source_name
         io_data_provider   = io_data_provider
         it_key_tab = it_key_tab
         it_navigation_path = it_navigation_path
      IMPORTING
        er_entity = er_entity
  ).
ENDCASE.
  endmethod.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~DELETE_ENTITY.
*&----------------------------------------------------------------------------------------------*
*&  Include           /IWBEP/DPC_TEMP_DEL_ENTITY_BASE
*&* This class has been generated on 30.01.2026 11:22:28 in client 100
*&*
*&*       WARNING--> NEVER MODIFY THIS CLASS <--WARNING
*&*   If you want to change the DPC implementation, use the
*&*   generated methods inside the DPC provider subclass - ZCL_ZGWR2R_BS_INFO_DPC_EXT
*&-----------------------------------------------------------------------------------------------*

 DATA lv_entityset_name TYPE string.

lv_entityset_name = io_tech_request_context->get_entity_set_name( ).

CASE lv_entityset_name.
*-------------------------------------------------------------------------*
*             EntitySet -  ZSTR2R_BS_INFOSet
*-------------------------------------------------------------------------*
      when 'ZSTR2R_BS_INFOSet'.
*     Call the entity set generated method
     zstr2r_bs_infose_delete_entity(
          EXPORTING iv_entity_name     = iv_entity_name
                    iv_entity_set_name = iv_entity_set_name
                    iv_source_name     = iv_source_name
                    it_key_tab         = it_key_tab
                    it_navigation_path = it_navigation_path
                    io_tech_request_context = io_tech_request_context
     ).

   when others.
     super->/iwbep/if_mgw_appl_srv_runtime~delete_entity(
        EXPORTING
          iv_entity_name = iv_entity_name
          iv_entity_set_name = iv_entity_set_name
          iv_source_name = iv_source_name
          it_key_tab = it_key_tab
          it_navigation_path = it_navigation_path
 ).
 ENDCASE.
  endmethod.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITY.
*&-----------------------------------------------------------------------------------------------*
*&  Include           /IWBEP/DPC_TEMP_GETENTITY_BASE
*&* This class has been generated  on 30.01.2026 11:22:28 in client 100
*&*
*&*       WARNING--> NEVER MODIFY THIS CLASS <--WARNING
*&*   If you want to change the DPC implementation, use the
*&*   generated methods inside the DPC provider subclass - ZCL_ZGWR2R_BS_INFO_DPC_EXT
*&-----------------------------------------------------------------------------------------------*

 DATA zstr2r_bs_infose_get_entity TYPE zcl_zgwr2r_bs_info_mpc=>ts_zstr2r_bs_info.
 DATA lv_entityset_name TYPE string.
 DATA lr_entity TYPE REF TO data.       "#EC NEEDED

lv_entityset_name = io_tech_request_context->get_entity_set_name( ).

CASE lv_entityset_name.
*-------------------------------------------------------------------------*
*             EntitySet -  ZSTR2R_BS_INFOSet
*-------------------------------------------------------------------------*
      WHEN 'ZSTR2R_BS_INFOSet'.
*     Call the entity set generated method
          zstr2r_bs_infose_get_entity(
               EXPORTING iv_entity_name     = iv_entity_name
                         iv_entity_set_name = iv_entity_set_name
                         iv_source_name     = iv_source_name
                         it_key_tab         = it_key_tab
                         it_navigation_path = it_navigation_path
                         io_tech_request_context = io_tech_request_context
             	 IMPORTING er_entity          = zstr2r_bs_infose_get_entity
                         es_response_context = es_response_context
          ).

        IF zstr2r_bs_infose_get_entity IS NOT INITIAL.
*     Send specific entity data to the caller interface
          copy_data_to_ref(
            EXPORTING
              is_data = zstr2r_bs_infose_get_entity
            CHANGING
              cr_data = er_entity
          ).
        ELSE.
*         In case of initial values - unbind the entity reference
          er_entity = lr_entity.
        ENDIF.

      WHEN OTHERS.
        super->/iwbep/if_mgw_appl_srv_runtime~get_entity(
           EXPORTING
             iv_entity_name = iv_entity_name
             iv_entity_set_name = iv_entity_set_name
             iv_source_name = iv_source_name
             it_key_tab = it_key_tab
             it_navigation_path = it_navigation_path
          IMPORTING
            er_entity = er_entity
    ).
 ENDCASE.
  endmethod.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET.
*&----------------------------------------------------------------------------------------------*
*&  Include           /IWBEP/DPC_TMP_ENTITYSET_BASE
*&* This class has been generated on 30.01.2026 11:22:28 in client 100
*&*
*&*       WARNING--> NEVER MODIFY THIS CLASS <--WARNING
*&*   If you want to change the DPC implementation, use the
*&*   generated methods inside the DPC provider subclass - ZCL_ZGWR2R_BS_INFO_DPC_EXT
*&-----------------------------------------------------------------------------------------------*
 DATA zstr2r_bs_infose_get_entityset TYPE zcl_zgwr2r_bs_info_mpc=>tt_zstr2r_bs_info.
 DATA lv_entityset_name TYPE string.

lv_entityset_name = io_tech_request_context->get_entity_set_name( ).

CASE lv_entityset_name.
*-------------------------------------------------------------------------*
*             EntitySet -  ZSTR2R_BS_INFOSet
*-------------------------------------------------------------------------*
   WHEN 'ZSTR2R_BS_INFOSet'.
*     Call the entity set generated method
      zstr2r_bs_infose_get_entityset(
        EXPORTING
         iv_entity_name = iv_entity_name
         iv_entity_set_name = iv_entity_set_name
         iv_source_name = iv_source_name
         it_filter_select_options = it_filter_select_options
         it_order = it_order
         is_paging = is_paging
         it_navigation_path = it_navigation_path
         it_key_tab = it_key_tab
         iv_filter_string = iv_filter_string
         iv_search_string = iv_search_string
         io_tech_request_context = io_tech_request_context
       IMPORTING
         et_entityset = zstr2r_bs_infose_get_entityset
         es_response_context = es_response_context
       ).
*     Send specific entity data to the caller interface
      copy_data_to_ref(
        EXPORTING
          is_data = zstr2r_bs_infose_get_entityset
        CHANGING
          cr_data = er_entityset
      ).

    WHEN OTHERS.
      super->/iwbep/if_mgw_appl_srv_runtime~get_entityset(
        EXPORTING
          iv_entity_name = iv_entity_name
          iv_entity_set_name = iv_entity_set_name
          iv_source_name = iv_source_name
          it_filter_select_options = it_filter_select_options
          it_order = it_order
          is_paging = is_paging
          it_navigation_path = it_navigation_path
          it_key_tab = it_key_tab
          iv_filter_string = iv_filter_string
          iv_search_string = iv_search_string
          io_tech_request_context = io_tech_request_context
       IMPORTING
         er_entityset = er_entityset ).
 ENDCASE.
  endmethod.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~UPDATE_ENTITY.
*&----------------------------------------------------------------------------------------------*
*&  Include           /IWBEP/DPC_TEMP_UPD_ENTITY_BASE
*&* This class has been generated on 30.01.2026 11:22:28 in client 100
*&*
*&*       WARNING--> NEVER MODIFY THIS CLASS <--WARNING
*&*   If you want to change the DPC implementation, use the
*&*   generated methods inside the DPC provider subclass - ZCL_ZGWR2R_BS_INFO_DPC_EXT
*&-----------------------------------------------------------------------------------------------*

 DATA zstr2r_bs_infose_update_entity TYPE zcl_zgwr2r_bs_info_mpc=>ts_zstr2r_bs_info.
 DATA lv_entityset_name TYPE string.
 DATA lr_entity TYPE REF TO data. "#EC NEEDED

lv_entityset_name = io_tech_request_context->get_entity_set_name( ).

CASE lv_entityset_name.
*-------------------------------------------------------------------------*
*             EntitySet -  ZSTR2R_BS_INFOSet
*-------------------------------------------------------------------------*
      WHEN 'ZSTR2R_BS_INFOSet'.
*     Call the entity set generated method
          zstr2r_bs_infose_update_entity(
               EXPORTING iv_entity_name     = iv_entity_name
                         iv_entity_set_name = iv_entity_set_name
                         iv_source_name     = iv_source_name
                         io_data_provider   = io_data_provider
                         it_key_tab         = it_key_tab
                         it_navigation_path = it_navigation_path
                         io_tech_request_context = io_tech_request_context
             	 IMPORTING er_entity          = zstr2r_bs_infose_update_entity
          ).
       IF zstr2r_bs_infose_update_entity IS NOT INITIAL.
*     Send specific entity data to the caller interface
          copy_data_to_ref(
            EXPORTING
              is_data = zstr2r_bs_infose_update_entity
            CHANGING
              cr_data = er_entity
          ).
        ELSE.
*         In case of initial values - unbind the entity reference
          er_entity = lr_entity.
        ENDIF.
      WHEN OTHERS.
        super->/iwbep/if_mgw_appl_srv_runtime~update_entity(
           EXPORTING
             iv_entity_name = iv_entity_name
             iv_entity_set_name = iv_entity_set_name
             iv_source_name = iv_source_name
             io_data_provider   = io_data_provider
             it_key_tab = it_key_tab
             it_navigation_path = it_navigation_path
          IMPORTING
            er_entity = er_entity
    ).
 ENDCASE.
  endmethod.


  method /IWBEP/IF_SB_DPC_COMM_SERVICES~COMMIT_WORK.
* Call RFC commit work functionality
DATA lt_message      TYPE bapiret2. "#EC NEEDED
DATA lv_message_text TYPE BAPI_MSG.
DATA lo_logger       TYPE REF TO /iwbep/cl_cos_logger.
DATA lv_subrc        TYPE syst-subrc.

lo_logger = /iwbep/if_mgw_conv_srv_runtime~get_logger( ).

  IF iv_rfc_dest IS INITIAL OR iv_rfc_dest EQ 'NONE'.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
      wait   = abap_true
    IMPORTING
      return = lt_message.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      DESTINATION iv_rfc_dest
    EXPORTING
      wait                  = abap_true
    IMPORTING
      return                = lt_message
    EXCEPTIONS
      communication_failure = 1000 MESSAGE lv_message_text
      system_failure        = 1001 MESSAGE lv_message_text
      OTHERS                = 1002.

  IF sy-subrc <> 0.
    lv_subrc = sy-subrc.
    /iwbep/cl_sb_gen_dpc_rt_util=>rfc_exception_handling(
        EXPORTING
          iv_subrc            = lv_subrc
          iv_exp_message_text = lv_message_text
          io_logger           = lo_logger ).
  ENDIF.
  ENDIF.
  endmethod.


  method /IWBEP/IF_SB_DPC_COMM_SERVICES~GET_GENERATION_STRATEGY.
* Get generation strategy
  rv_generation_strategy = '1'.
  endmethod.


  method /IWBEP/IF_SB_DPC_COMM_SERVICES~LOG_MESSAGE.
* Log message in the application log
DATA lo_logger TYPE REF TO /iwbep/cl_cos_logger.
DATA lv_text TYPE /iwbep/sup_msg_longtext.

  MESSAGE ID iv_msg_id TYPE iv_msg_type NUMBER iv_msg_number
    WITH iv_msg_v1 iv_msg_v2 iv_msg_v3 iv_msg_v4 INTO lv_text.

  lo_logger = mo_context->get_logger( ).
  lo_logger->log_message(
    EXPORTING
     iv_msg_type   = iv_msg_type
     iv_msg_id     = iv_msg_id
     iv_msg_number = iv_msg_number
     iv_msg_text   = lv_text
     iv_msg_v1     = iv_msg_v1
     iv_msg_v2     = iv_msg_v2
     iv_msg_v3     = iv_msg_v3
     iv_msg_v4     = iv_msg_v4
     iv_agent      = 'DPC' ).
  endmethod.


  method /IWBEP/IF_SB_DPC_COMM_SERVICES~RFC_EXCEPTION_HANDLING.
* RFC call exception handling
DATA lo_logger  TYPE REF TO /iwbep/cl_cos_logger.

lo_logger = /iwbep/if_mgw_conv_srv_runtime~get_logger( ).

/iwbep/cl_sb_gen_dpc_rt_util=>rfc_exception_handling(
  EXPORTING
    iv_subrc            = iv_subrc
    iv_exp_message_text = iv_exp_message_text
    io_logger           = lo_logger ).
  endmethod.


  method /IWBEP/IF_SB_DPC_COMM_SERVICES~RFC_SAVE_LOG.
  DATA lo_logger  TYPE REF TO /iwbep/cl_cos_logger.
  DATA lo_message_container TYPE REF TO /iwbep/if_message_container.

  lo_logger = /iwbep/if_mgw_conv_srv_runtime~get_logger( ).
  lo_message_container = /iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  " Save the RFC call log in the application log
  /iwbep/cl_sb_gen_dpc_rt_util=>rfc_save_log(
    EXPORTING
      is_return            = is_return
      iv_entity_type       = iv_entity_type
      it_return            = it_return
      it_key_tab           = it_key_tab
      io_logger            = lo_logger
      io_message_container = lo_message_container ).
  endmethod.


  method /IWBEP/IF_SB_DPC_COMM_SERVICES~SET_INJECTION.
* Unit test injection
  IF io_unit IS BOUND.
    mo_injection = io_unit.
  ELSE.
    mo_injection = me.
  ENDIF.
  endmethod.


  method CHECK_SUBSCRIPTION_AUTHORITY.
  RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
    EXPORTING
      textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
      method = 'CHECK_SUBSCRIPTION_AUTHORITY'.
  endmethod.


  method GET_TVARV.

    FIELD-SYMBOLS <gt_range> TYPE zcl_tvarvc_range=>ty_range_table.

    CLEAR: gt_area_advert,
           gt_bloq_pagto,
           gt_credito,
           gt_debito,
           gt_local_neg,
           gt_met_pagto,
           gt_stat_item,
           gt_tp_doc_nota_cred.

    DATA(lt_names) = VALUE string_table(
      ( `ZR2R115_AREA_ADVERT` )
      ( `ZR2R115_BLOQ_PAGTO` )
      ( `ZR2R115_CREDITO` )
      ( `ZR2R115_DEBITO` )
      ( `ZR2R115_LOCAL_NEG` )
      ( `ZR2R115_MET_PAGTO` )
      ( `ZR2R115_STAT_ITEM` )
      ( `ZR2R115_TP_DOC_NOTA_CRED` ) ).

    SELECT name,
           opti,
           low,
           high
      FROM zz1_tvarvc_r2r
      INTO TABLE @DATA(lt_tvarvc)
      FOR ALL ENTRIES IN @lt_names
     WHERE name = @lt_names-table_line.

    LOOP AT lt_tvarvc INTO DATA(ls_entry).
      ASSIGN SWITCH #( ls_entry-name
        WHEN 'ZR2R115_AREA_ADVERT'     THEN gt_area_advert
        WHEN 'ZR2R115_BLOQ_PAGTO'      THEN gt_bloq_pagto
        WHEN 'ZR2R115_CREDITO'         THEN gt_credito
        WHEN 'ZR2R115_DEBITO'          THEN gt_debito
        WHEN 'ZR2R115_LOCAL_NEG'       THEN gt_local_neg
        WHEN 'ZR2R115_MET_PAGTO'       THEN gt_met_pagto
        WHEN 'ZR2R115_STAT_ITEM'       THEN gt_stat_item
        WHEN 'ZR2R115_TP_DOC_NOTA_CRED' THEN gt_tp_doc_nota_cred ) TO <gt_range>.
      IF <gt_range> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( sign   = 'I'
                      option = ls_entry-opti
                      low    = ls_entry-low
                      high   = ls_entry-high ) TO <gt_range>.
      UNASSIGN <gt_range>.
    ENDLOOP.

  endmethod.


  method ZSTR2R_BS_INFOSE_CREATE_ENTITY.
  RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
    EXPORTING
      textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
      method = 'ZSTR2R_BS_INFOSE_CREATE_ENTITY'.
  endmethod.


  method ZSTR2R_BS_INFOSE_DELETE_ENTITY.
  RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
    EXPORTING
      textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
      method = 'ZSTR2R_BS_INFOSE_DELETE_ENTITY'.
  endmethod.


  method ZSTR2R_BS_INFOSE_GET_ENTITY.
  RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
    EXPORTING
      textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
      method = 'ZSTR2R_BS_INFOSE_GET_ENTITY'.
  endmethod.


  METHOD zstr2r_bs_infose_get_entityset.
***  RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
***    EXPORTING
***      textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
***      method = 'ZSTR2R_BS_INFOSE_GET_ENTITYSET'.

    DATA: lt_taxnumber_fae TYPE TABLE OF i_businesspartnertaxnumber,
          lt_cli_niden     TYPE TABLE OF ztbr2r_cli_niden.

    DATA: r_bptaxnumber TYPE RANGE OF i_businesspartnertaxnumber-bptaxnumber,
          r_bptaxtype   TYPE RANGE OF i_businesspartnertaxnumber-bptaxtype,
          r_stat_item   TYPE RANGE OF tvarvc-low,
          r_credito     TYPE RANGE OF tvarvc-low.

*** Busca parâmetros
    get_tvarv( ).
    r_stat_item = gt_stat_item[].
    r_credito   = gt_credito[].

    DATA(lv_shortid) = it_filter_select_options[ 1 ]-select_options[ 1 ]-low.

    SELECT bs~bankstatementshortid,
           bs~bankname,
           bsi~bankstatementitem,
           bsi~companycode,
           bsi~housebank,
           bsi~housebankaccount,
           bsi~bankstatement,
           bsi~bankstatementdate,
           bsi~currency,
           bsi~amountintransactioncurrency,
           bsi~bankinternalid,
           bsi~bankaccount,
           bsi~memoline1,
           bsi~paymentexternaltransactype,
           bsi~paymenttransactiondescription,
           bsi~bankpostingdate,
           bsi~postingdate,
           bsi~bankledgerdocument,
           bsi~fiscalyear,
           bsi~bankstatementitemdescription1,
           bsi~bankstatementitemdescription2,
           bsi~bankstatementitemlifecycsts,
           bsi~iscompleted,
           bsi~accountingexchangerate,
           bsi~bankstatementdatemonth,
           bsi~bankstatementdateyear,
           bsi~debitcreditcode,
           bsi~businesspartnername
      FROM i_arbankstatement AS bs INNER JOIN i_arbankstatementitem AS bsi
        ON bs~bankstatementshortid = bsi~bankstatementshortid
      INTO TABLE @DATA(lt_bs_info)
     WHERE bs~bankstatementshortid = @lv_shortid.
    IF sy-subrc = 0.

      DATA(lt_bs_info_cli_niden) = lt_bs_info[].
      DELETE lt_bs_info           WHERE businesspartnername IS INITIAL.      "Mantém apenas registros com informação fiscal (CPF/CNPJ)
      DELETE lt_bs_info_cli_niden WHERE businesspartnername IS NOT INITIAL.  "Mantém registros que o banco não enviou informação fiscal (CPF/CPNJ)
      DELETE lt_bs_info_cli_niden WHERE debitcreditcode     <> 'H'.           "Mantém apenas créditos (exclui tarifas e débitos)

*** Verificar se foi enviado tipo de inscrição ou apenas número da inscrição (CPF ou CNPJ)
      LOOP AT lt_bs_info ASSIGNING FIELD-SYMBOL(<fs_bs_info>).

        IF strlen( <fs_bs_info>-businesspartnername ) = '12' OR
           strlen( <fs_bs_info>-businesspartnername ) = '15'.

          APPEND VALUE #(
            bptaxtype   = COND #( WHEN strlen( <fs_bs_info>-businesspartnername ) = '12' THEN 'BR2' ELSE 'BR1' )
            bptaxnumber = <fs_bs_info>-businesspartnername+1
          ) TO lt_taxnumber_fae.

          <fs_bs_info>-businesspartnername = <fs_bs_info>-businesspartnername+1.

        ELSEIF strlen( <fs_bs_info>-businesspartnername ) = '11' OR
               strlen( <fs_bs_info>-businesspartnername ) = '14'.

          APPEND VALUE #(
            bptaxtype   = COND #( WHEN strlen( <fs_bs_info>-businesspartnername ) = '11' THEN 'BR2' ELSE 'BR1' )
            bptaxnumber = <fs_bs_info>-businesspartnername
          ) TO lt_taxnumber_fae.
        ENDIF.

      ENDLOOP.

*** Recupera BP por CPF/CNPJ, junto com campo para verificar se cliente é PA
      IF lt_taxnumber_fae[] IS NOT INITIAL.

        SELECT bt~businesspartner,
               bt~bptaxtype,
               bt~bptaxnumber,
               cma~creditlimitiszero
          FROM i_businesspartnertaxnumber AS bt INNER JOIN i_creditmanagementaccount AS cma
            ON bt~businesspartner = cma~businesspartner
          INTO TABLE @DATA(lt_bus_partner)
           FOR ALL ENTRIES IN @lt_taxnumber_fae
         WHERE bptaxtype   = @lt_taxnumber_fae-bptaxtype
           AND bptaxnumber = @lt_taxnumber_fae-bptaxnumber.
        IF sy-subrc = 0.
          SORT lt_bus_partner BY bptaxnumber.
        ENDIF.
      ENDIF.

*** Recupera dados GLACCOUNT
      IF lt_bs_info[] IS NOT INITIAL.

        DATA(lt_bs_info_fae) = lt_bs_info[].
        SORT lt_bs_info_fae BY companycode housebank housebankaccount.
        DELETE ADJACENT DUPLICATES FROM lt_bs_info_fae COMPARING companycode housebank housebankaccount.

        SELECT zbukr,
               hbkid,
               hktid,
               ukont
          FROM t042i
          INTO TABLE @DATA(lt_t042i)
           FOR ALL ENTRIES IN @lt_bs_info_fae
         WHERE zbukr = @lt_bs_info_fae-companycode
           AND hbkid = @lt_bs_info_fae-housebank
           AND hktid = @lt_bs_info_fae-housebankaccount.
        IF sy-subrc = 0.
          SORT lt_t042i BY zbukr hbkid hktid.
        ENDIF.
      ENDIF.

*** Grava registros que banco não enviou CPF/CNPJ
      LOOP AT lt_bs_info_cli_niden INTO DATA(lw_bs_info_cli_niden).

        APPEND INITIAL LINE TO lt_cli_niden ASSIGNING FIELD-SYMBOL(<fs_cli_niden>).
        IF <fs_cli_niden> IS ASSIGNED.
          <fs_cli_niden>-amountintransactioncurrency   = lw_bs_info_cli_niden-amountintransactioncurrency.
          <fs_cli_niden>-bankaccount                   = lw_bs_info_cli_niden-bankaccount.
          <fs_cli_niden>-bankinternalid                = lw_bs_info_cli_niden-bankinternalid.
          <fs_cli_niden>-bankstatement                 = lw_bs_info_cli_niden-bankstatement.
          <fs_cli_niden>-bankstatementdate             = lw_bs_info_cli_niden-bankstatementdate.
          <fs_cli_niden>-bankstatementitemdescription2 = lw_bs_info_cli_niden-bankstatementitemdescription2.
          <fs_cli_niden>-bankstatementitem             = lw_bs_info_cli_niden-bankstatementitem.
          <fs_cli_niden>-bankstatementshortid          = lw_bs_info_cli_niden-bankstatementshortid.
          <fs_cli_niden>-currency                      = lw_bs_info_cli_niden-currency.
          <fs_cli_niden>-housebank                     = lw_bs_info_cli_niden-housebank.
          <fs_cli_niden>-housebankaccount              = lw_bs_info_cli_niden-housebankaccount.
        ENDIF.

      ENDLOOP.

*--------------------------------------------------------------------*
*     Appenda os dados de retorno
*--------------------------------------------------------------------*
      LOOP AT lt_bs_info INTO DATA(lw_bs_info).

***     Verifica se encontra o BP
        READ TABLE lt_bus_partner INTO DATA(lw_bus_partner) WITH KEY
          bptaxnumber = lw_bs_info-businesspartnername
        BINARY SEARCH.
        IF sy-subrc <> 0.
          UNASSIGN <fs_cli_niden>.
          APPEND INITIAL LINE TO lt_cli_niden ASSIGNING <fs_cli_niden>.
          IF <fs_cli_niden> IS ASSIGNED.
            <fs_cli_niden>-amountintransactioncurrency   = lw_bs_info-amountintransactioncurrency.
            <fs_cli_niden>-bankaccount                   = lw_bs_info-bankaccount.
            <fs_cli_niden>-bankinternalid                = lw_bs_info-bankinternalid.
            <fs_cli_niden>-bankstatement                 = lw_bs_info-bankstatement.
            <fs_cli_niden>-bankstatementdate             = lw_bs_info-bankstatementdate.
            <fs_cli_niden>-bankstatementitemdescription2 = lw_bs_info-bankstatementitemdescription2.
            <fs_cli_niden>-bankstatementitem             = lw_bs_info-bankstatementitem.
            <fs_cli_niden>-bankstatementshortid          = lw_bs_info-bankstatementshortid.
            <fs_cli_niden>-currency                      = lw_bs_info-currency.
            <fs_cli_niden>-housebank                     = lw_bs_info-housebank.
            <fs_cli_niden>-housebankaccount              = lw_bs_info-housebankaccount.
            <fs_cli_niden>-businesspartnername           = lw_bs_info-businesspartnername.
          ENDIF.
          CONTINUE.
        ENDIF.

        IF lw_bs_info-bankstatementitemlifecycsts NOT IN r_stat_item[].
          CONTINUE.
        ENDIF.

        IF lw_bs_info-debitcreditcode NOT IN r_credito[].
          CONTINUE.
        ENDIF.

        IF lw_bs_info-iscompleted <> 'X'.
          CONTINUE.
        ENDIF.

        APPEND INITIAL LINE TO et_entityset ASSIGNING FIELD-SYMBOL(<fs_entityset>).
        IF <fs_entityset> IS ASSIGNED.
          <fs_entityset>-accountingdocumenttype        = gt_tp_doc_nota_cred[ 1 ]-low.
          <fs_entityset>-amountintransactioncurrency   = lw_bs_info-amountintransactioncurrency.
          <fs_entityset>-areaadvertencia               = gt_area_advert[ 1 ]-low.
          <fs_entityset>-bankname                      = lw_bs_info-bankname.
          <fs_entityset>-bankpostingdate               = lw_bs_info-bankpostingdate.
          <fs_entityset>-bankstatement                 = lw_bs_info-bankstatement.
          <fs_entityset>-bankstatementitem             = lw_bs_info-bankstatementitem.
          <fs_entityset>-bankstatementitemdescription1 = lw_bs_info-bankstatementitemdescription1.
          <fs_entityset>-bankstatementitemdescription2 = lw_bs_info-bankstatementitemdescription2.
          <fs_entityset>-bankstatementshortid          = lw_bs_info-bankstatementshortid.
          <fs_entityset>-companycode                   = lw_bs_info-companycode.
          <fs_entityset>-createdbyuser                 = sy-uname.
          <fs_entityset>-currency                      = lw_bs_info-currency.
          <fs_entityset>-deb_debitcreditcode           = gt_debito[ 1 ]-low.
          <fs_entityset>-item_debitcreditcode          = gt_credito[ 1 ]-low.
          <fs_entityset>-localneg                      = gt_local_neg[ 1 ]-low.
          <fs_entityset>-paymentblockreason            = gt_bloq_pagto[ 1 ]-low.
          <fs_entityset>-paymentmethod                 = gt_met_pagto[ 1 ]-low.
          <fs_entityset>-postingdate                   = lw_bs_info-postingdate.
          <fs_entityset>-businesspartner               = lw_bus_partner-businesspartner.

          IF lw_bus_partner-creditlimitiszero IS NOT INITIAL.
            <fs_entityset>-clientepa                 = 'X'.
          ENDIF.

          READ TABLE lt_t042i INTO DATA(lw_t042i) WITH KEY
            zbukr = lw_bs_info-companycode
            hbkid = lw_bs_info-housebank
            hktid = lw_bs_info-housebankaccount
          BINARY SEARCH.
          IF sy-subrc = 0.
            <fs_entityset>-ukont = lw_t042i-ukont.
            CLEAR lw_bus_partner.
          ENDIF.

          CLEAR lw_bus_partner.

        ENDIF.

      ENDLOOP.

*** Persiste clientes não identificados na tabela Z
      IF lt_cli_niden IS NOT INITIAL.
        MODIFY ztbr2r_cli_niden FROM TABLE lt_cli_niden.
      ENDIF.

    ENDIF.

  ENDMETHOD.


  method ZSTR2R_BS_INFOSE_UPDATE_ENTITY.
  RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
    EXPORTING
      textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
      method = 'ZSTR2R_BS_INFOSE_UPDATE_ENTITY'.
  endmethod.
ENDCLASS.
