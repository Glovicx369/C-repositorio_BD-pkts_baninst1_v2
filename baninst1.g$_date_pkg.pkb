DROP PACKAGE BODY BANINST1.G$_DATE_PKG;

CREATE OR REPLACE PACKAGE BODY BANINST1.g$_date_pkg AS
--AUDIT_TRAIL_MSGKEY_UPDATE
-- PROJECT : MSGKEY
-- MODULE  : GOKDATE
-- SOURCE  : enUS
-- TARGET  : I18N
-- DATE    : Thu Feb 26 11:03:48 2015
-- MSGSIGN : #6fb738a3f61f55f7
--TMI18N.ETR DO NOT CHANGE--
--AUDIT_TRAIL_SCB
-- Solution Centre Baseline
-- PROJECT : B70MNLS
-- MODULE  : GOKDATE
-- SOURCE  : USen
-- TARGET  : I18N
-- DATE    : Fri Apr 22 16:08:03 2005
--TMI18N.ETR DO NOT CHANGE--
--
-- FILE NAME..: gokdate.sql
-- RELEASE....: 8.7.5
-- OBJECT NAME: G$_DATE_PKG
-- PRODUCT....: GENERAL
-- COPYRIGHT..: Copyright 2004 - 2015 Ellucian Company L.P. and its affiliates.
--
-- Declare the structure of the PL/SQL table which will hold
-- the masks. Then declare the table itself.
--
  TYPE mask_tabtype IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
  fmts mask_tabtype;
--
  pivot_year   NUMBER;
--
  def_format   VARCHAR2(15);
  v_century    VARCHAR2(15) := '-19';

-- Monday 1st Jan 2001 is Julian 2451911

  julian_mon CONSTANT number:=2451911;
  julian_tue CONSTANT number:=2451912;
  julian_wed CONSTANT number:=2451913;
  julian_thu CONSTANT number:=2451914;
  julian_fri CONSTANT number:=2451915;
  julian_sat CONSTANT number:=2451916;
  julian_sun CONSTANT number:=2451917;
  nls_cal1 varchar2(20):='''Gregorian''';
  nls_cal2 varchar2(20):='''Gregorian''';
  nls_date_format varchar2(20):='DD-MON-RRRR';
  nls_date_format_session varchar2(20):=nls_date_format;
  temp_char varchar2(50):='';
  temp_date date:=sysdate;

  type elements_type is table of varchar2(10);
  l_elt_type elements_type;
  l_elt_src elements_type;
  l_elt_tgt elements_type;
  --Always write the following elements in upper case
  l_norm_upper elements_type :=/*Do not Translate!*/ elements_type ('RR','YY','MI','MM','DD','AM','A.M.');


----
--
-- Declare local routines.
--
-- Preload pl/sql table with DMY formats.
--
  PROCEDURE day_first IS
  BEGIN
    fmts(1)  := 'DD';
    fmts(2)  := 'DDMM';
    fmts(3)  := 'DDMMRR';
    fmts(4)  := 'DDMMRRRR';
    fmts(5)  := 'DDMON';
    fmts(6)  := 'DDMONRR';
    fmts(7)  := 'DDMONRRRR';
    fmts(8)  := 'DD/MM';
    fmts(9)  := 'DD/MM/RR';
    fmts(10) := 'DD/MM/RRRR';
    fmts(11) := 'DD/MON';
    fmts(12) := 'DD/MON/RR';
    fmts(13) := 'DD/MON/RRRR';
    fmts(14) := nls_date_format;
  END day_first;
--
----
--
-- Preload pl/sql table with MDY formats.
--
  PROCEDURE month_first IS
  BEGIN
    fmts(1)  := 'DD';
    fmts(2)  := 'MMDD';
    fmts(3)  := 'MMDDRR';
    fmts(4)  := 'MMDDRRRR';
    fmts(5)  := 'MON';
    fmts(6)  := 'MONDD';
    fmts(7)  := 'MONDDRR';
    fmts(8)  := 'MONDDRRRR';
    fmts(9)  := 'MM/DD';
    fmts(10) := 'MM/DD/RR';
    fmts(11) := 'MM/DD/RRRR';
    fmts(12) := 'MON/DD';
    fmts(13) := 'MON/DD/RR';
    fmts(14) := 'MON/DD/RRRR';
    fmts(15) := nls_date_format;
  END month_first;
--
----
--
-- Preload pl/sql table with YMD formats.
--
  PROCEDURE year_first IS
  BEGIN
    fmts(1)  := 'DD';
    fmts(2)  := 'RRMM';
    fmts(3)  := 'RRMMDD';
    fmts(4)  := 'RRRRMMDD';
    fmts(5)  := 'RRMON';
    fmts(6)  := 'RRMONDD';
    fmts(7)  := 'RRRRMON';
    fmts(8)  := 'RRRRMONDD';
    fmts(9)  := 'RR/MM';
    fmts(10) := 'RR/MM/DD';
    fmts(11) := 'RRRR/MM';
    fmts(12) := 'RRRR/MM/DD';
    fmts(13) := 'RR/MON';
    fmts(14) := 'RR/MON/DD';
    fmts(15) := 'RRRR/MON';
    fmts(16) := 'RRRR/MON/DD';
    fmts(17) := nls_date_format;
  END year_first;
--
----
--
-- Get institutional settings.
--
  PROCEDURE set_defaults IS
--
    CURSOR gubinst_pivot IS
      SELECT GUBINST_CENTURY_PIVOT,
             GUBINST_DATE_DEFAULT_FORMAT
        FROM GUBINST
       WHERE GUBINST_KEY = 'INST';
--
  BEGIN
    OPEN gubinst_pivot;
    FETCH gubinst_pivot INTO pivot_year, def_format;
    CLOSE gubinst_pivot;
--
    IF pivot_year is NULL OR
       def_format IS NULL THEN
      RAISE_APPLICATION_ERROR(-20101, G$_NLS.Get('GOKDATE-0000', 'SQL','*ERROR* Missing institutional settings.') );
    END IF;
  END set_defaults;
--
----
--
-- Date format routine.
--
  PROCEDURE date_format (value_in  IN  VARCHAR2,
			 value_out OUT VARCHAR2,
			 time_ind  IN  VARCHAR2,
			 msg_out   OUT VARCHAR2) IS
--
    char_var       VARCHAR2(200);
    time_tmp       VARCHAR2(10);
    date_tmp       VARCHAR2(20);
    date_var       DATE := NULL;
    time_var       DATE := NULL;
    err_msg        VARCHAR2(200) :=  G$_NLS.Get('GOKDATE-0001', 'SQL','*ERROR* Invalid date value or format.') ;
--
    value_sep      INTEGER := 0;
    mask_sep       INTEGER := 0;
--
    mask_index     INTEGER := 1;     -- Loop index for the mask array
--
    date_converted BOOLEAN := FALSE; -- Boolean to terminate loop
    change_century BOOLEAN := TRUE;  -- Boolean to determine if changing
--                                      century required
  BEGIN
--
-- Verify data is passed in correctly.
--
    IF value_in IS NULL THEN
      RETURN;
    END IF;
--
-- Initialization section.
--
    set_defaults;
    IF def_format = '1' THEN
      month_first;
      err_msg :=  G$_NLS.Get('GOKDATE-0002', 'SQL',
	'%01%  Entry format is MDY.', err_msg );
    ELSIF def_format = '2' THEN
      day_first;
      err_msg :=  G$_NLS.Get('GOKDATE-0003', 'SQL',
	'%01%  Entry format is DMY.', err_msg );
    ELSE
      year_first;
      err_msg :=  G$_NLS.Get('GOKDATE-0004', 'SQL',
	'%01%  Entry format is YMD.', err_msg );
    END IF;
--
-- Check for sysdate request.
--
    IF LENGTH(value_in) = 1 AND
          value_in NOT IN('0','1','2','3','4','5','6','7','8','9') THEN
      date_converted := TRUE;
      date_var :=  SYSDATE;
--
-- Try to validate the date.
--
    ELSE
--
-- Check for a time part and save it off. Set date temp variable.
--
      IF NVL(time_ind,'N') = 'Y' THEN
        IF INSTR(value_in,' ') > 0 THEN
          time_tmp := SUBSTR(value_in,INSTR(value_in,' ')+1);
	  date_tmp := SUBSTR(value_in,1,INSTR(value_in,' ')-1);
	ELSE
	  date_tmp := value_in;
        END IF;
      ELSE
        date_tmp := value_in;
      END IF;
-- Seperator comparing removed for internationalised version
--
-- Count the number of seperators in the entered date value.
--
--          value_sep := NVL(LENGTH(REPLACE(TRANSLATE(UPPER(date_tmp),
--                           '1234567890JANFEBMRPYUNLGSPOCTNVDC',
--                           '000000000000000000000000000000000'),'0','')),0);
--
-- Loop through the rows in the table...  for Oracle below v7.3
-- use hardcoded number of masks (26) instead of fmts.count
--
      WHILE mask_index <= fmts.COUNT AND NOT date_converted LOOP
        BEGIN
--
-- Count the number of seperators in the format mask.
--
--          mask_sep  := NVL(LENGTH(REPLACE(TRANSLATE(fmts(mask_index),
--                           '1234567890JANFEBMRPYUNLGSPOCTNVDC',
--                           '000000000000000000000000000000000'),'0','')),0);
--
-- Verify that the mask has the same number of seperators.  Don't bother
-- trying ones which don't match.
--
--          IF value_sep <> mask_sep THEN
--            RAISE VALUE_ERROR;
--          END IF;
--
-- Verify that the length of the mask is the same as the date passed in.
-- Oracle 8 applies shorter masks without error causing a return value
-- which is different then what is expected.
--
          IF length(date_tmp) <> length(fmts(mask_index)) THEN
            RAISE VALUE_ERROR;
          END IF;
--
-- Try to convert string using mask in table row.
--
          date_var := TO_DATE(date_tmp, fmts(mask_index));
          date_converted := TRUE;
--
-- Date converted, so check the century.
--
          IF INSTR(fmts(mask_index),'RRRR') > 0 AND
             SUBSTR(TO_CHAR(date_var,'RRRR'),1,2) != '00' THEN
            change_century := FALSE;
          END IF;
--
-- Trap date conversion exceptions.
--
        EXCEPTION
          WHEN OTHERS THEN
            date_var := NULL;
            date_converted := FALSE;
            mask_index:= mask_index + 1;
	END;
      END LOOP;
    END IF;
--
-- If date was converted, format to display format.
--
    IF date_converted THEN
--
-- check for century
--
      IF change_century THEN
        IF TO_NUMBER(TO_CHAR(date_var,'YY')) > pivot_year THEN
          v_century := '-19';
        ELSE
          v_century := '-20';
        END IF;
--
        date_var := TO_CHAR(TO_DATE (TO_CHAR (date_var,'DD-MON') ||
                                      v_century ||
                                      TO_CHAR(date_var,'YY'
                                      ),
                             'DD-MON-RRRR'
                             ),
                      NLS_DATE_FORMAT
                    );

      END IF;
--
-- Check if time is to be appended and validate the value.
--
      IF NVL(time_ind,'N') = 'Y' THEN
	IF time_tmp IS NOT NULL THEN
	  BEGIN
            time_var := TO_DATE(time_tmp, 'HH24:MI:SS');
	    value_out := TO_CHAR(date_var, nls_date_format) || ' ' || time_tmp;
          EXCEPTION
            WHEN OTHERS THEN
              value_out := NULL;
              msg_out :=  G$_NLS.Get('GOKDATE-0005', 'SQL','*ERROR* Invalid time value or format.') ;
	  END;
	ELSE
	  value_out := TO_CHAR(date_var, nls_date_format) || ' 00:00:00';
	END IF;
      ELSE
	value_out := TO_CHAR(date_var, nls_date_format);
      END IF;

--
-- Date did not convert.
--
    ELSE
      value_out := NULL;
      msg_out := err_msg;
    END IF;
  END date_format;
--

-- NLS day of the week functions

  FUNCTION nls_mon RETURN varchar2 IS
  BEGIN
   RETURN RTRIM(TO_CHAR(TO_DATE(julian_mon,'J'),'DAY'));
  END;

  FUNCTION nls_tue RETURN varchar2 IS
  BEGIN
   RETURN RTRIM(TO_CHAR(TO_DATE(julian_tue,'J'),'DAY'));
  END;

  FUNCTION nls_wed RETURN varchar2 IS
  BEGIN
   RETURN RTRIM(TO_CHAR(TO_DATE(julian_wed,'J'),'DAY'));
  END;

  FUNCTION nls_thu RETURN varchar2 IS
  BEGIN
   RETURN RTRIM(TO_CHAR(TO_DATE(julian_thu,'J'),'DAY'));
  END;

  FUNCTION nls_fri RETURN varchar2 IS
  BEGIN
   RETURN RTRIM(TO_CHAR(TO_DATE(julian_fri,'J'),'DAY'));
  END;

  FUNCTION nls_sat RETURN varchar2 IS
  BEGIN
   RETURN RTRIM(TO_CHAR(TO_DATE(julian_sat,'J'),'DAY'));
  END;

  FUNCTION nls_sun RETURN varchar2 IS
  BEGIN
   RETURN RTRIM(TO_CHAR(TO_DATE(julian_sun,'J'),'DAY'));
  END;

  FUNCTION nls_abv_mon RETURN varchar2 IS
  BEGIN
   RETURN TO_CHAR(TO_DATE(julian_mon,'J'),'DY');
  END;

  FUNCTION nls_abv_tue RETURN varchar2 IS
  BEGIN
   RETURN TO_CHAR(TO_DATE(julian_tue,'J'),'DY');
  END;

  FUNCTION nls_abv_wed RETURN varchar2 IS
  BEGIN
   RETURN TO_CHAR(TO_DATE(julian_wed,'J'),'DY');
  END;

  FUNCTION nls_abv_thu RETURN varchar2 IS
  BEGIN
   RETURN TO_CHAR(TO_DATE(julian_thu,'J'),'DY');
  END;

  FUNCTION nls_abv_fri RETURN varchar2 IS
  BEGIN
   RETURN TO_CHAR(TO_DATE(julian_fri,'J'),'DY');
  END;

  FUNCTION nls_abv_sat RETURN varchar2 IS
  BEGIN
   RETURN TO_CHAR(TO_DATE(julian_sat,'J'),'DY');
  END;

  FUNCTION nls_abv_sun RETURN varchar2 IS
  BEGIN
   RETURN TO_CHAR(TO_DATE(julian_sun,'J'),'DY');
  END;

  FUNCTION nls_abv_day (day IN VARCHAR2) RETURN varchar2 IS
  BEGIN
   IF day='M' THEN
     temp_char:=g$_nls.get('GOKDATE-0006','SQL','_Monday');
   ELSIF day='T' THEN
     temp_char:=g$_nls.get('GOKDATE-0007','SQL','_Tuesday');
   ELSIF day='W' THEN
     temp_char:=g$_nls.get('GOKDATE-0008','SQL','_Wednesday');
   ELSIF day='R' THEN
     temp_char:=g$_nls.get('GOKDATE-0009','SQL','thu_Rsday');
   ELSIF day='F' THEN
     temp_char:=g$_nls.get('GOKDATE-0010','SQL','_Friday');
   ELSIF day='S' THEN
     temp_char:=g$_nls.get('GOKDATE-0011','SQL','_Saturday');
   ELSIF day='U' THEN
     temp_char:=g$_nls.get('GOKDATE-0012','SQL','s_Unday');
   ELSE
     temp_char:=null;
   END IF;
   IF temp_char is not null then
     temp_char:=SUBSTR(temp_char,INSTR(temp_char,'_')+1,1);
   END IF;
   RETURN temp_char;
  END;

  FUNCTION nls_deviate RETURN number IS
  BEGIN
   RETURN TO_NUMBER(TO_CHAR(TO_DATE(julian_mon,'J'),'D')) - 1;
  END;

  PROCEDURE set_nls_cal1 (cal1 IN VARCHAR2) IS
  BEGIN
   nls_cal1:=''''||cal1||'''';
  END;

  FUNCTION get_nls_cal1 RETURN varchar2 IS
  BEGIN
   RETURN nls_cal1;
  END;

  PROCEDURE set_nls_cal2 (cal2 IN VARCHAR2) IS
  BEGIN
   nls_cal2:=''''||cal2||'''';
  END;

  FUNCTION get_nls_cal2 RETURN varchar2 IS
  BEGIN
   RETURN nls_cal2;
  END;

  PROCEDURE set_nls_date_format (date_format IN VARCHAR2) IS
  BEGIN
   nls_date_format:=date_format;
   nls_date_format_session:=date_format;
   dbms_session.set_nls('NLS_DATE_FORMAT',''''||date_format||'''');
  END;

  FUNCTION get_nls_date_format RETURN varchar2 IS
  BEGIN
   RETURN nls_date_format;
  END;

  FUNCTION cal1_to_date (date_in IN VARCHAR2) RETURN date IS
  BEGIN
   select TO_DATE(date_in,nls_date_format,'NLS_CALENDAR='||nls_cal1) into temp_date from dual;
   RETURN temp_date;
  END;

  FUNCTION cal1_to_date (date_in IN VARCHAR2, mask_in IN VARCHAR2) RETURN date IS
  BEGIN
   select TO_DATE(date_in,mask_in,'NLS_CALENDAR='||nls_cal1) into temp_date from dual;
   RETURN temp_date;
  END;

  FUNCTION cal1_to_char (date_in IN DATE) RETURN varchar2 IS
  BEGIN
   select TO_CHAR(date_in,nls_date_format,'NLS_CALENDAR='||nls_cal1) into temp_char from dual;
   RETURN temp_char;
  END;

  FUNCTION cal1_to_char (date_in IN DATE, mask_in IN VARCHAR2) RETURN varchar2 IS
  BEGIN
   select TO_CHAR(date_in,mask_in,'NLS_CALENDAR='||nls_cal1) into temp_char from dual;
   RETURN temp_char;
  END;

  FUNCTION cal1_first_day (date_in IN DATE) RETURN date IS
  BEGIN
   select TO_DATE('01-'||TO_CHAR(date_in,'MM-RRRR','NLS_CALENDAR='||nls_cal1),'DD-MM-RRRR','NLS_CALENDAR='||nls_cal1) into temp_date from dual;
   RETURN temp_date;
  END;

  FUNCTION cal1_last_day (date_in IN DATE) RETURN date IS
  BEGIN
   select ''''||VALUE||'''' into temp_char from NLS_SESSION_PARAMETERS where PARAMETER='NLS_CALENDAR';
   dbms_session.set_nls('NLS_CALENDAR',nls_cal1);
   select LAST_DAY(date_in) into temp_date from dual;
   dbms_session.set_nls('NLS_CALENDAR',temp_char);
   dbms_session.set_nls('NLS_DATE_FORMAT',''''||nls_date_format_session||'''');
   RETURN temp_date;
  END;

  FUNCTION cal1_add_months (date_in IN DATE, months_in IN NUMBER) RETURN date IS
  BEGIN
   select ''''||VALUE||'''' into temp_char from NLS_SESSION_PARAMETERS where PARAMETER='NLS_CALENDAR';
   dbms_session.set_nls('NLS_CALENDAR',nls_cal1);
   select ADD_MONTHS(date_in, months_in) into temp_date from dual;
   dbms_session.set_nls('NLS_CALENDAR',temp_char);
   dbms_session.set_nls('NLS_DATE_FORMAT',''''||nls_date_format_session||'''');
   RETURN temp_date;
  END;

  FUNCTION cal2_to_date (date_in IN VARCHAR2) RETURN date IS
  BEGIN
   select TO_DATE(date_in,nls_date_format,'NLS_CALENDAR='||nls_cal2) into temp_date from dual;
   RETURN temp_date;
  END;

  FUNCTION cal2_to_date (date_in IN VARCHAR2, mask_in IN VARCHAR2) RETURN date IS
  BEGIN
   select TO_DATE(date_in,mask_in,'NLS_CALENDAR='||nls_cal2) into temp_date from dual;
   RETURN temp_date;
  END;

  FUNCTION cal2_to_char (date_in IN DATE) RETURN varchar2 IS
  BEGIN
   select TO_CHAR(date_in,nls_date_format,'NLS_CALENDAR='||nls_cal2) into temp_char from dual;
   RETURN temp_char;
  END;

  FUNCTION cal2_to_char (date_in IN DATE, mask_in IN VARCHAR2) RETURN varchar2 IS
  BEGIN
   select TO_CHAR(date_in,mask_in,'NLS_CALENDAR='||nls_cal2) into temp_char from dual;
   RETURN temp_char;
  END;

  FUNCTION cal2_first_day (date_in IN DATE) RETURN date IS
  BEGIN
   select TO_DATE('01-'||TO_CHAR(date_in,'MM-RRRR','NLS_CALENDAR='||nls_cal2),'DD-MM-RRRR','NLS_CALENDAR='||nls_cal2) into temp_date from dual;
   RETURN temp_date;
  END;

  FUNCTION cal2_last_day (date_in IN DATE) RETURN date IS
  BEGIN
   select ''''||VALUE||'''' into temp_char from NLS_SESSION_PARAMETERS where PARAMETER='NLS_CALENDAR';
   dbms_session.set_nls('NLS_CALENDAR',nls_cal2);
   select LAST_DAY(date_in) into temp_date from dual;
   dbms_session.set_nls('NLS_CALENDAR',temp_char);
   dbms_session.set_nls('NLS_DATE_FORMAT',''''||nls_date_format_session||'''');
   RETURN temp_date;
  END;

  FUNCTION cal2_add_months (date_in IN DATE, months_in IN NUMBER) RETURN date IS
  BEGIN
   select ''''||VALUE||'''' into temp_char from NLS_SESSION_PARAMETERS where PARAMETER='NLS_CALENDAR';
   dbms_session.set_nls('NLS_CALENDAR',nls_cal2);
   select ADD_MONTHS(date_in, months_in) into temp_date from dual;
   dbms_session.set_nls('NLS_CALENDAR',temp_char);
   dbms_session.set_nls('NLS_DATE_FORMAT',''''||nls_date_format_session||'''');
   RETURN temp_date;
  END;

  FUNCTION normalise_greg_date (date_in IN VARCHAR2, mask_in IN VARCHAR2) RETURN varchar2 IS
   temp_chr varchar2(50):=''; -- make local var so pragma WNPS is not violated
  BEGIN
   select TO_CHAR(TO_DATE(date_in,mask_in,'NLS_CALENDAR=''GREGORIAN'''),nls_date_format) into temp_chr from dual;
   RETURN temp_chr;
  END;

  FUNCTION translate_format (pOMask IN VARCHAR2) RETURN varchar2 IS
   l_result varchar2(128);
   l_temp   varchar2(128);
   l_elt_found elements_type;
   i integer;
   l_last_elt_type_replaced varchar2(1);
  BEGIN
   l_result:=nvl(pOMask,nls_date_format);
   for i in l_norm_upper.first..l_norm_upper.last loop
    l_result:=replace(l_result,lower(l_norm_upper(i)), l_norm_upper(i));
    l_result:=replace(l_result,initcap(l_norm_upper(i)), l_norm_upper(i));
   end loop;
   -- RR is not very understandable by humans
   l_result :=/*Do not Translate!*/ replace(l_result, 'RR', 'YY');
   --First replace US texts with <index> to avoid translations fitting a US pattern
   l_last_elt_type_replaced:=' ';
   l_elt_found := elements_type();
   l_elt_found.extend(l_elt_src.last);
   i:=l_elt_src.first;
   loop
    l_elt_found(i):='N';
    if l_elt_type(i)<>l_last_elt_type_replaced then --Only replace elt_types that have not been replaced
     l_temp:=replace(l_result,l_elt_src(i),'<'||i||'>');
     --dbms_output.put_line('Tested for Pattern '||l_elt_src(i));
     if l_temp<>l_result then
      l_result:=l_temp;
      l_elt_found(i):='Y';
      l_last_elt_type_replaced:=l_elt_type(i);
     end if;
    end if;
    exit when i=l_elt_src.last;
    i:=l_elt_src.next(i);
   end loop;
   --Now replace <index> with translation
   for i in l_elt_src.first..l_elt_src.last loop
    if l_elt_found(i)='Y' then
     l_result:=replace(l_result,'<'||i||'>',l_elt_tgt(i));
    end if;
   end loop;
   return l_result;
  END;

/* function is_valid_date

     This function is basically the same as the DATE_FORMAT procedue.
     The only difference is that it doesn't return the converted date
     but return a boolean TRUE to indicate that date passed can be
     converted and is correct. Otherwise, it will return FALSE.
  */
  FUNCTION is_valid_date (value_in IN VARCHAR2,
                          time_ind IN VARCHAR2 DEFAULT 'N' ) RETURN BOOLEAN
  IS
  	value_var    VARCHAR2(100)  := NULL;
  	msg_var      VARCHAR2(1000) := NULL;
  	return_value BOOLEAN := FALSE;
  BEGIN
  	date_format( value_in, value_var, time_ind, msg_var );
  	IF value_var IS NOT NULL THEN
  	  return_value := TRUE;
  	END IF;
  	RETURN return_value;
  END is_valid_date;

BEGIN
  select VALUE into nls_date_format_session from NLS_SESSION_PARAMETERS where PARAMETER='NLS_DATE_FORMAT';

  -- Give each element a type, a format should have max one element of the same type
  l_elt_type:=/*Do not Translate!*/elements_type(
   'M','M','M'
   ,'M','M'
   ,'Y','Y'
   ,'D'
   ,'H','I','S'
   ,'A','A');
  -- The elements we will translate in a format mask
  l_elt_src:=/*Do not Translate!*/ elements_type(
   'MONTH','Month'
   ,'MM','MON','Mon'
   ,'YYYY','YY'
   ,'DD'
   ,'HH', 'MI','SS'
   ,'AM','A.M.');
  -- The translations of the elements
  l_elt_tgt:=elements_type(g$_nls.get('GOKDATE-0013','SQL','MONTH'),g$_nls.get('GOKDATE-0014','SQL','Month')
   ,g$_nls.get('GOKDATE-0015','SQL','MM'),g$_nls.get('GOKDATE-0016','SQL','MON'),g$_nls.get('GOKDATE-0017','SQL','Mon')
   ,g$_nls.get('GOKDATE-0018','SQL','YYYY'),g$_nls.get('GOKDATE-0019','SQL','YY'),g$_nls.get('GOKDATE-0020','SQL','DD')
   ,g$_nls.get('GOKDATE-0021','SQL','HH'),g$_nls.get('GOKDATE-0022','SQL','MI'),g$_nls.get('GOKDATE-0023','SQL','SS')
   ,g$_nls.get('GOKDATE-0024','SQL','AM'),g$_nls.get('GOKDATE-0025','SQL','A.M.'));


END g$_date_pkg;
/

DROP PUBLIC SYNONYM G$_DATE;

CREATE OR REPLACE PUBLIC SYNONYM G$_DATE FOR BANINST1.G$_DATE_PKG;


GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO ALUMNI;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO BAN_CONEXION_UTEL;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO BANIMGR;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO FAISMGR;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO FIMSMGR;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO GENERAL;

GRANT EXECUTE, DEBUG ON BANINST1.G$_DATE_PKG TO NLSUSER;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO POSNCTL;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO SATURN;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO TAISMGR;

GRANT EXECUTE, DEBUG ON BANINST1.G$_DATE_PKG TO UPGRADE1;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO WFAUTO;

GRANT EXECUTE ON BANINST1.G$_DATE_PKG TO WTAILOR;
