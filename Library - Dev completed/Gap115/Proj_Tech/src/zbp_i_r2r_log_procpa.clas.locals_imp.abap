CLASS lhc_ZI_R2R_LOG_PROCPA DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_r2r_log_procpa RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ zi_r2r_log_procpa RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zi_r2r_log_procpa.

    METHODS process FOR MODIFY
      IMPORTING keys FOR ACTION zi_r2r_log_procpa~process RESULT result.

ENDCLASS.

CLASS lhc_ZI_R2R_LOG_PROCPA IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD process.


*--------------------------------------------------------------------*
* Program       : *
* Program Type  : Method
* Frequency     : N/A
* Processing    : Foreground
* Author        : RTIEZZI (EY)
* Creation Date : 28/01/2026
* Gap ID        : 115
* Description   :  Geração de crédito financeiros
*--------------------------------------------------------------------*
* Change History Log
*--------------------------------------------------------------------*
* Mod Date       Author    Request/ChaRM    Description
* 000 28/01/2026 RTIEZZI   DS4K906217       Initial Version
*--------------------------------------------------------------------*

    "-----------------------------------------------------------------------
    " Process action payload and update Z table based on I_OperationalAcctgDocItem
    " Fixes:
    "  - No SELECT inside LOOP (bulk read)
    "  - AccountType 'D' comes from TVARV (no hardcode)
    "-----------------------------------------------------------------------

    " --- Bulk read from released CDS (no SELECT in loop)
    TYPES: BEGIN OF ty_std,
             companycode                 TYPE bukrs,
             accountingdocument          TYPE belnr_d,
             fiscalyear                  TYPE gjahr,
             customer                    TYPE kunnr,
             documentdate                TYPE bldat,
             postingdate                 TYPE budat,
             transactioncurrency         TYPE waers,
             amountincompanycodecurrency TYPE dmbtr,
             assignmentreference         TYPE bseg-zuonr,
             salesdocument               TYPE vbeln_va,
           END OF ty_std.

    " --- Collect payload keys to read standard CDS in bulk
    TYPES: BEGIN OF ty_req_key,
             companycode        TYPE bukrs,
             accountingdocument TYPE belnr_d,
             fiscalyear         TYPE gjahr,
           END OF ty_req_key.

    DATA: lt_std_raw  TYPE STANDARD TABLE OF ty_std WITH EMPTY KEY,
          lt_req_keys TYPE STANDARD TABLE OF ty_req_key WITH EMPTY KEY.

    CONSTANTS lc_tvarv_accttype TYPE tvarvc-name VALUE 'Z_R2R_LOG_PROCPA_ACCTTYPE_115'.

    " --- Read AccountType from TVARV (TVARVC)
    DATA: lv_acct_type TYPE c LENGTH 1,
          lv_msg       TYPE string.

    DATA: ls_payload TYPE zae_r2r_log_procpa_act,
          ls_db      TYPE ztr2r_log_procpa. " --- Persist in Z table (upsert)
    DATA(ls_result) = ls_payload.

    SELECT SINGLE Low
      FROM zi_r2r_tvarv
      WHERE Name = @lc_tvarv_accttype
        AND Type = 'P'
      INTO @lv_acct_type.

    IF sy-subrc <> 0 OR lv_acct_type IS INITIAL.
      " If TVARV is not maintained, do not process (avoid hardcode fallback)
      LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key_err>).
        FIELD-SYMBOLS <fs_param_err> TYPE zae_r2r_log_procpa_act.
        ASSIGN COMPONENT '%PARAM' OF STRUCTURE <fs_key_err> TO <fs_param_err>.
        IF <fs_param_err> IS NOT ASSIGNED.
          CONTINUE.
        ENDIF.

        DATA(ls_payload_err) = <fs_param_err>.
        DATA(ls_result_err)  = ls_payload_err.

        CLEAR: ls_result_err-Customer,
               ls_result_err-DocumentDate,
               ls_result_err-PostingDate,
               ls_result_err-Currency,
               ls_result_err-Amount,
               ls_result_err-Assignment,
               ls_result_err-SalesDocument,
               ls_result_err-Message,
               ls_result_err-Status.


        ls_result_err-Status = 'E'.

        MESSAGE ID 'ZR2R115' TYPE 'S' NUMBER '004'
          WITH lc_tvarv_accttype
          INTO lv_msg.

        ls_result_err-Message = lv_msg.

        APPEND VALUE #( %tky   = <fs_key_err>-%tky
                        %param = ls_result_err ) TO result.
      ENDLOOP.
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
      FIELD-SYMBOLS <fs_param> TYPE zae_r2r_log_procpa_act.
      ASSIGN COMPONENT '%PARAM' OF STRUCTURE <fs_key> TO <fs_param>.
      IF <fs_param> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      APPEND VALUE ty_req_key(
        companycode        = <fs_param>-CompanyCode
        accountingdocument = <fs_param>-AccountingDocument
        fiscalyear         = <fs_param>-FiscalYear
      ) TO lt_req_keys.
    ENDLOOP.

    SORT lt_req_keys BY companycode accountingdocument fiscalyear.
    DELETE ADJACENT DUPLICATES FROM lt_req_keys COMPARING companycode accountingdocument fiscalyear.


    IF lt_req_keys IS NOT INITIAL.
      SELECT
             CompanyCode,
             AccountingDocument,
             FiscalYear,
             Customer,
             DocumentDate,
             PostingDate,
             TransactionCurrency,
             AmountInCompanyCodeCurrency,
             AssignmentReference,
             SalesDocument
        FROM I_OperationalAcctgDocItem
        FOR ALL ENTRIES IN @lt_req_keys
        WHERE CompanyCode        = @lt_req_keys-companycode
          AND AccountingDocument = @lt_req_keys-accountingdocument
          AND FiscalYear         = @lt_req_keys-fiscalyear
          AND financialaccounttype        = @lv_acct_type
        INTO TABLE @lt_std_raw.
    ENDIF.

    " --- Hash for fast lookup
    DATA lt_std TYPE HASHED TABLE OF ty_std
                WITH UNIQUE KEY companycode accountingdocument fiscalyear.

    lt_std = lt_std_raw.

    " --- Process each action call
    LOOP AT keys ASSIGNING <fs_key>.

      FIELD-SYMBOLS <fs_param2> TYPE zae_r2r_log_procpa_act.
      ASSIGN COMPONENT '%PARAM' OF STRUCTURE <fs_key> TO <fs_param2>.


      IF <fs_param2> IS ASSIGNED.
        ls_payload = <fs_param2>.
      ELSE.
        CONTINUE.
      ENDIF.

      CLEAR: ls_result-Customer,
             ls_result-DocumentDate,
             ls_result-PostingDate,
             ls_result-Currency,
             ls_result-Amount,
             ls_result-Assignment,
             ls_result-SalesDocument,
             ls_result-Message,
             ls_result-Status.


      READ TABLE lt_std ASSIGNING FIELD-SYMBOL(<fs_std>) WITH TABLE KEY companycode        = ls_payload-CompanyCode
                                                                        accountingdocument = ls_payload-AccountingDocument
                                                                        fiscalyear         = ls_payload-FiscalYear.
      IF sy-subrc <> 0.
        ls_result-Status = 'E'.

        MESSAGE ID 'ZR2R115' TYPE 'S' NUMBER '001'
          WITH ls_payload-CompanyCode ls_payload-AccountingDocument ls_payload-FiscalYear
          INTO lv_msg.
        ls_result-Message = lv_msg.
      ELSE.
        ls_result-Customer      = <fs_std>-customer.
        ls_result-DocumentDate  = <fs_std>-documentdate.
        ls_result-PostingDate   = <fs_std>-postingdate.
        ls_result-Currency      = <fs_std>-transactioncurrency.
        ls_result-Amount        = <fs_std>-amountincompanycodecurrency.
        ls_result-Assignment    = <fs_std>-assignmentreference.
        ls_result-SalesDocument = <fs_std>-salesdocument.

        ls_result-Status = 'S'.

        MESSAGE ID 'ZR2R115' TYPE 'S' NUMBER '002'
          WITH ls_payload-CompanyCode ls_payload-AccountingDocument ls_payload-FiscalYear
          INTO lv_msg.
        ls_result-Message = lv_msg.

        ls_db-bukrs    = ls_payload-CompanyCode.
        ls_db-belnr    = ls_payload-AccountingDocument.
        ls_db-gjahr    = ls_payload-FiscalYear.
        ls_db-kunnr    = ls_result-Customer.
        ls_db-bldat    = ls_result-DocumentDate.
        ls_db-budat    = ls_result-PostingDate.
        ls_db-waers    = ls_result-Currency.
        ls_db-dmbtr    = ls_result-Amount.
        ls_db-zuonr    = ls_result-Assignment.
        ls_db-vbeln    = ls_result-SalesDocument.
        ls_db-mensagem = ls_result-Message.
        ls_db-status   = ls_result-Status.

        MODIFY ztr2r_log_procpa FROM @ls_db.
        IF sy-subrc <> 0.
          ls_result-Status = 'E'.
          MESSAGE ID 'ZR2R115' TYPE 'S' NUMBER '003'
            WITH ls_payload-CompanyCode ls_payload-AccountingDocument ls_payload-FiscalYear
            INTO lv_msg.
          ls_result-Message = lv_msg.
        ENDIF.
      ENDIF.

      APPEND VALUE #( %tky   = <fs_key>-%tky
                      %param = ls_result ) TO result.

    ENDLOOP.


  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_R2R_LOG_PROCPA DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_R2R_LOG_PROCPA IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
