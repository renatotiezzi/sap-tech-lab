*&---------------------------------------------------------------------*
*& Report ZRQ2C_CARGA_RET_GRANEL
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*************************************************************************
* Object Name    : ZRQ2C_CARGA_RET_GRANEL                               *
* Object Title   : Carga Retorno Granel PCS -> SAP                      *
* WRICEF ID      : Q2C265I003_ Retorno Carga Granel PCS -> SAP          *                                       *
* Author         : Renata Barreto                                       *
* Date           : 27/01/2026                                           *
*-----------------------------------------------------------------------*
report zrq2c_carga_ret_granel LINE-SIZE 1000.

types:
  " Mensagens
  begin of ty_message,
    name       type eps2filnam,
    shnumber   type oig_shnum,
    com_number type oig_cmpnmr,
    id         type symsgid,
    number     type symsgno,
    type       type symsgty,
    severity   type if_abap_behv_message=>t_severity,
    v1         type string,
    v2         type string,
    v3         type string,
    v4         type string,
  end of ty_message .
types:
  tt_message type standard table of ty_message with empty key .

data: ct_msg   type tt_message.
*----------------------------------------------------------------------*
* Data Declarations - Execution Class
*----------------------------------------------------------------------*
data: go_carga_ret_granel type ref to zclq2c_265_carga_ret_granel.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
selection-screen begin of block b1 with frame title text-s01.
  parameters:
    p_folder type string lower case default '/int/cifs/sap/ds4/tmp/',
    p_SHNUM  type  oig_shnum,
    p_cmpnmr type  oig_cmpnmr,
*    p_L300_H type  string,
*    p_L301_C type  string,
*    p_L301_H type  string,
*    p_SHOWSM type  char1,
    p_JOB    type  char1 as checkbox default 'X'.
selection-screen end of block b1.


*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
start-of-selection.

  create object go_carga_ret_granel
    exporting
      iv_folder      = p_folder
      iv_shnumber    = p_SHNUM
      iv_com_number  = p_cmpnmr
*      iv_file_l300_h = p_L300_H
*      iv_file_l301_c = p_L301_C
*      iv_file_l301_h = p_L301_H
*      iv_showsm      = abap_true
      iv_job         = p_JOB.

  go_carga_ret_granel->execute( changing ct_msg = ct_msg ).
