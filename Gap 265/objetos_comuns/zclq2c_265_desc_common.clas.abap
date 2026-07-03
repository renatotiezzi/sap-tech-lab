CLASS zclq2c_265_desc_common DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS gc_msgid TYPE symsgid VALUE 'ZCL_Q2C_265_MSG_DG'.

    TYPES: BEGIN OF ty_message,
             name     TYPE eps2filnam,
             ordernum TYPE string,
             id       TYPE symsgid,
             number   TYPE symsgno,
             type     TYPE symsgty,
             severity TYPE if_abap_behv_message=>t_severity,
             v1       TYPE string,
             v2       TYPE string,
             v3       TYPE string,
             v4       TYPE string,
           END OF ty_message.

    TYPES tt_message TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

    TYPES: BEGIN OF ty_tvarvc,
             name TYPE tvarvc-name,
             low  TYPE tvarvc-low,
             high TYPE tvarvc-high,
           END OF ty_tvarvc.

    TYPES tt_tvarvc TYPE STANDARD TABLE OF ty_tvarvc WITH EMPTY KEY.

    CLASS-METHODS get_tvarvc_value
      IMPORTING
        iv_name        TYPE tvarvc-name
      RETURNING
        VALUE(rv_low)  TYPE string.

    CLASS-METHODS add_error
      IMPORTING
        iv_number   TYPE symsgno
        iv_v1       TYPE string OPTIONAL
        iv_v2       TYPE string OPTIONAL
        iv_name     TYPE eps2filnam OPTIONAL
      CHANGING
        ct_message  TYPE tt_message.

    CLASS-METHODS add_success
      IMPORTING
        iv_number   TYPE symsgno
        iv_v1       TYPE string OPTIONAL
        iv_v2       TYPE string OPTIONAL
        iv_name     TYPE eps2filnam OPTIONAL
      CHANGING
        ct_message  TYPE tt_message.

  PRIVATE SECTION.
ENDCLASS.



CLASS zclq2c_265_desc_common IMPLEMENTATION.

  METHOD get_tvarvc_value.
    SELECT SINGLE low
      FROM zz1_tvarvc_q2c
      WHERE name = @iv_name
        AND type = 'P'
      INTO @rv_low.
  ENDMETHOD.

  METHOD add_error.
    APPEND VALUE #( name     = iv_name
                    id       = gc_msgid
                    number   = iv_number
                    type     = 'E'
                    severity = if_abap_behv_message=>severity-error
                    v1       = iv_v1
                    v2       = iv_v2 ) TO ct_message.
  ENDMETHOD.

  METHOD add_success.
    APPEND VALUE #( name     = iv_name
                    id       = gc_msgid
                    number   = iv_number
                    type     = 'S'
                    severity = if_abap_behv_message=>severity-success
                    v1       = iv_v1
                    v2       = iv_v2 ) TO ct_message.
  ENDMETHOD.

ENDCLASS.
