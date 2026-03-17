*&---------------------------------------------------------------------*
*& Include          ZXEDFU02
*&---------------------------------------------------------------------*
*& Purpose : EDI user exit include for IDoc partner determination.
*&           When an inbound IDoc contains an RS partner whose number
*&           matches a configured list (TVARV / ZEDI_SG11_PARTN) AND
*&           the purchasing organisation of the referenced PO matches a
*&           configured list (TVARV / ZEDI_SG11_EKORG), the RS partner
*&           number is replaced with the vendor (LIFNR) read from EKKO.
*&
*& Context : Called from user-exit include within EDI function module
*&           (e.g. EXIT_SAPLEINM_001).  The internal table INT_EDIDD
*&           (type STANDARD TABLE OF EDIDD) is provided by the framework.
*&---------------------------------------------------------------------*

" -----------------------------------------------------------------------
" Local type: internal table used to hold TVARV configuration values
" -----------------------------------------------------------------------
TYPES: tt_tvarv_values TYPE STANDARD TABLE OF tvarv WITH DEFAULT KEY.

" -----------------------------------------------------------------------
" Step 1 – Read the Purchase Order number from segment E1EDK02.
"          QUALF = '002' identifies the PO reference qualifier;
"          BELNR carries the actual PO number.
" -----------------------------------------------------------------------
DATA(lv_ebeln) = VALUE ebeln( ).

LOOP AT int_edidd INTO DATA(ls_idoc_data)
     WHERE segnam = 'E1EDK02'.

  " Cast raw SDATA string directly into the typed segment structure
  DATA(ls_e1edk02) = CORRESPONDING e1edk02( ls_idoc_data-sdata ).

  IF ls_e1edk02-qualf = '002'.
    lv_ebeln = ls_e1edk02-belnr.
    EXIT. " Only one PO reference is expected per IDoc
  ENDIF.

ENDLOOP.

" -----------------------------------------------------------------------
" Step 2 – Fetch vendor (LIFNR) and purchasing organisation (EKORG)
"          from EKKO using the PO number found above.
"          Both fields are needed for the replacement decision.
" -----------------------------------------------------------------------
DATA(lv_lifnr) = VALUE lifnr( ).
DATA(lv_ekorg) = VALUE ekorg( ).

IF lv_ebeln IS NOT INITIAL.

  SELECT SINGLE lifnr, ekorg
    FROM ekko
    WHERE ebeln = @lv_ebeln
    INTO  @DATA(ls_ekko).                         "#EC CI_GENBUFF

  IF sy-subrc = 0.
    lv_lifnr = ls_ekko-lifnr.
    lv_ekorg = ls_ekko-ekorg.
  ENDIF.

ENDIF.

" -----------------------------------------------------------------------
" Step 3 – Load replacement configuration from TVARV.
"
"   ZEDI_SG11_PARTN : partner numbers (PARTN) that trigger replacement.
"                     Each row stores one partner number in field LOW.
"   ZEDI_SG11_EKORG : purchasing organisations that trigger replacement.
"                     Each row stores one EKORG value in field LOW.
"
"   Both tables are read once here, before the loop, to avoid repeated
"   database access for every E1EDKA1 segment in the IDoc.
" -----------------------------------------------------------------------
SELECT *
  FROM tvarv
  WHERE name = 'ZEDI_SG11_PARTN'
  INTO TABLE @DATA(lt_partn_cfg).                  "#EC CI_NOFIRST

SELECT *
  FROM tvarv
  WHERE name = 'ZEDI_SG11_EKORG'
  INTO TABLE @DATA(lt_ekorg_cfg).                  "#EC CI_NOFIRST

" -----------------------------------------------------------------------
" Step 4 – Loop over all E1EDKA1 segments and apply partner replacement.
"
"   ASSIGNING FIELD-SYMBOL enables direct in-place modification of the
"   SDATA field inside INT_EDIDD, avoiding a separate MODIFY statement.
" -----------------------------------------------------------------------
LOOP AT int_edidd ASSIGNING FIELD-SYMBOL(<ls_edidd>)
     WHERE segnam = 'E1EDKA1'.

  " Cast raw SDATA directly into the typed segment structure
  DATA(ls_e1edka1) = CORRESPONDING e1edka1( <ls_edidd>-sdata ).

  " Only process partner role 'RS' (Ordering Address / Ship-from)
  IF ls_e1edka1-parvw = 'RS'.

    " Determine whether the current partner number is in the trigger
    " list (ZEDI_SG11_PARTN).  xsdbool() + line_exists() is the
    " idiomatic modern-ABAP way to produce an abap_bool result.
    DATA(lv_partn_found) = xsdbool(
      line_exists( lt_partn_cfg[ low = ls_e1edka1-partn ] ) ).

    " Determine whether the PO's purchasing organisation is in the
    " trigger list (ZEDI_SG11_EKORG).
    DATA(lv_ekorg_found) = xsdbool(
      line_exists( lt_ekorg_cfg[ low = lv_ekorg ] ) ).

    " All three conditions must be met before PARTN is replaced:
    "   1. Partner number is in the ZEDI_SG11_PARTN trigger list
    "   2. Purchasing organisation is in the ZEDI_SG11_EKORG trigger list
    "   3. A vendor was successfully read from EKKO (lv_lifnr not initial)
    IF     lv_partn_found = abap_true
       AND lv_ekorg_found = abap_true
       AND lv_lifnr       IS NOT INITIAL.

      " Replace the IDoc partner number with the vendor from the PO
      ls_e1edka1-partn = lv_lifnr.

      " Write the modified structure back into the IDoc segment data.
      " Because <ls_edidd> is a field-symbol, this updates INT_EDIDD
      " directly without a separate MODIFY statement.
      <ls_edidd>-sdata = ls_e1edka1.

    ENDIF. " all replacement conditions met

  ENDIF. " PARVW = 'RS'

ENDLOOP. " E1EDKA1 segments
