DROP PACKAGE BODY BANINST1.G$_FOREIGN_SQL_PKG;

CREATE OR REPLACE PACKAGE BODY BANINST1.g$_foreign_sql_pkg AS
-- Solution Centre Baseline
-- PROJECT : MSGKEY
-- MODULE  : GSPFRNS
-- SOURCE  : enUS
-- TARGET  : I18N
-- DATE    : Thu May 22 05:40:48 2008
-- MSGSIGN : #96bd83750772195b
--TMI18N.ETR DO NOT CHANGE--
--
-- FILE NAME..: gspfrns.sql
-- RELEASE....: 7.1
-- OBJECT NAME: G$_FOREIGN_SQL_PKG
-- PRODUCT....: GENERAL
-- USAGE......: Package contains a routine used by the BANSECR maintenance.
-- COPYRIGHT..: Copyright (C) SunGard Corporation 2004. All rights reserved.
--
  ret_code INTEGER := 0;
--
  FUNCTION g$_foreign_sql_fnc (in_sql VARCHAR2) RETURN INTEGER IS
--
-- Error codes used in this routine
--
    uerr_not_bansecr     INTEGER := -20101;
  BEGIN
--
-- The only user authorized to use this procedure is BANSECR.
--
    IF SUBSTR(USER,1,7) <> 'BANSECR' THEN
      RAISE_APPLICATION_ERROR(uerr_not_bansecr,
        G$_NLS.Get('GSPFRNS-0000','SQL',
                   'This procedure may only be used by a BANSECR account.'));
    END IF;
--
-- Execute the passed SQL with my ORACLE privileges.
--
    EXECUTE IMMEDIATE in_sql;
--
-- This is left for backward compatibility.
--
    RETURN(ret_code);
  END g$_foreign_sql_fnc;
--
END g$_foreign_sql_pkg;
/

DROP PUBLIC SYNONYM BANINST1_SQL_PKG;

CREATE OR REPLACE PUBLIC SYNONYM BANINST1_SQL_PKG FOR BANINST1.G$_FOREIGN_SQL_PKG;


GRANT EXECUTE ON BANINST1.G$_FOREIGN_SQL_PKG TO BANSECR;
