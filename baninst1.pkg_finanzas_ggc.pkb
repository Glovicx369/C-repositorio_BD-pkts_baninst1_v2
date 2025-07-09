DROP PACKAGE BODY BANINST1.PKG_FINANZAS_GGC;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_FINANZAS_GGC" AS
/******************************************************************************
   NAME:       BANINST1.PKG_FINANZAS_GGC
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        01/07/2021      ggarcica       1. Created this package.
   1.1        28/11/2023      omar.meza	     2.- Implementacion de Doble Diplomado
******************************************************************************/

-- Nueva funcion para obtener la parcialidad (cuota de colegiatura) cuando sean DIPLOMADOS
-- OMS Sep/2023
FUNCTION F_PARCIALIDAD_ECONTINUA (P_PIDM NUMBER, P_FECHA DATE, P_PROGRAMA IN VARCHAR2 DEFAULT NULL,
                                  P_STUDY_PATH IN NUMBER   DEFAULT NULL,
                                  P_JORNADA    IN VARCHAR2 DEFAULT NULL) RETURN NUMBER IS

-- Variables
   VL_PARCIALIDAD NUMBER;

BEGIN  

  DBMS_OUTPUT.PUT_LINE('PARCIALIDAD P_STUDY_PATH = ' || P_STUDY_PATH);
  DBMS_OUTPUT.PUT_LINE('PARCIALIDAD P_JORNADA    = ' || P_JORNADA);
  DBMS_OUTPUT.PUT_LINE('PARCIALIDAD P_PROGRAMA   = ' || P_PROGRAMA);
  DBMS_OUTPUT.PUT_LINE('PARCIALIDAD P_FECHA      = ' || P_FECHA);


  BEGIN
        SELECT DISTINCT
               ROUND(((SELECT  A.SFRRGFE_MAX_CHARGE
               FROM SFRRGFE A , TBBDETC
               WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
               AND  A.SFRRGFE_TERM_CODE= PERIODO
               AND A.SFRRGFE_TYPE = 'STUDENT'
               AND A.SFRRGFE_ENTRY_TYPE = 'R'
               AND A.SFRRGFE_LEVL_CODE = NIVEL
               AND A.SFRRGFE_CAMP_CODE = CAMPUS
               AND A.SFRRGFE_ATTS_CODE = P_JORNADA
               AND A.SFRRGFE_RATE_CODE = RATE
               AND NVL(A.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
               AND NVL(A.SFRRGFE_PROGRAM,'SIN') = PRO_SFR
               AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND NVL(A1.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
                                      AND NVL(A1.SFRRGFE_PROGRAM,'SIN') = PRO_SFR)) - NVL(MONTO_DSI,0) - NVL(((SELECT A.SFRRGFE_MAX_CHARGE
               FROM SFRRGFE A , TBBDETC
               WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
               AND  A.SFRRGFE_TERM_CODE= PERIODO
               AND A.SFRRGFE_TYPE = 'STUDENT'
               AND A.SFRRGFE_ENTRY_TYPE = 'R'
               AND A.SFRRGFE_LEVL_CODE = NIVEL
               AND A.SFRRGFE_CAMP_CODE = CAMPUS
               AND A.SFRRGFE_ATTS_CODE = P_JORNADA
               AND A.SFRRGFE_RATE_CODE = RATE
               AND NVL(A.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
               AND NVL(A.SFRRGFE_PROGRAM,'SIN') = PRO_SFR
               AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND NVL(A1.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
                                      AND NVL(A1.SFRRGFE_PROGRAM,'SIN') = PRO_SFR))*DESCUENTO/100),0))/NUM_PAG)PARCIALIDAD
        INTO VL_PARCIALIDAD
        FROM(SELECT DISTINCT
                SORLCUR_PIDM PIDM,
                SORLCUR_KEY_SEQNO STUDY,
                SORLCUR_PROGRAM PROGRAMA,
                SORLCUR_RATE_CODE RATE,
                SORLCUR_CAMP_CODE CAMPUS,
                SPRIDEN_ID,
                SORLCUR_START_DATE,
                SORLCUR_LEVL_CODE NIVEL,
                SFRSTCR_TERM_CODE PERIODO,
                SFRSTCR_PTRM_CODE PPARTE,
                SSBSECT_PTRM_START_DATE FECHA,
                NVL((SELECT NVL(SFRRGFE_PROGRAM,'SIN')
                FROM SFRRGFE A , TBBDETC
                WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
                AND  A.SFRRGFE_TERM_CODE= F.SFRSTCR_TERM_CODE
                AND A.SFRRGFE_TYPE = 'STUDENT'
                AND A.SFRRGFE_ENTRY_TYPE = 'R'
                AND A.SFRRGFE_LEVL_CODE = A.SORLCUR_LEVL_CODE
                AND A.SFRRGFE_CAMP_CODE = A.SORLCUR_CAMP_CODE
                AND A.SFRRGFE_ATTS_CODE = (SELECT MAX (T.SGRSATT_ATTS_CODE)
                                            FROM SGRSATT T
                                            WHERE T.SGRSATT_PIDM = A.SORLCUR_PIDM
                                            AND T.SGRSATT_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                            AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
                                            AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                            AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                                               FROM SGRSATT TT
                                                                               WHERE  TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                                               AND  TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                                               AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                                               AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]'))
                                            AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                                                           FROM SGRSATT T1
                                                                           WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                                                           AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                                           AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                                           AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                                           AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')))
                AND A.SFRRGFE_RATE_CODE = A.SORLCUR_RATE_CODE
                AND nvl(A.SFRRGFE_DEPT_CODE,0) = nvl((SELECT DISTINCT NVL(SORLCUR_SITE_CODE,0)
                                          FROM SORLCUR CUR
                                          WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                          AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                          AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                                   FROM SORLCUR CUR2
                                                                   WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                                   AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE)),'0')
                AND A.SFRRGFE_PROGRAM = A.SORLCUR_PROGRAM
                AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND nvl(A1.SFRRGFE_DEPT_CODE,0) = nvl((SELECT DISTINCT NVL(SORLCUR_SITE_CODE,'0')
                                                                  FROM SORLCUR CUR
                                                                  WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                  AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                                                  AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                                                           FROM SORLCUR CUR2
                                                                                           WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                                                           AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE)),'0')
                                      AND A1.SFRRGFE_PROGRAM = A.SORLCUR_PROGRAM)),'SIN')PRO_SFR,
                (SELECT DISTINCT NVL(SORLCUR_SITE_CODE,0)
                              FROM SORLCUR CUR
                              WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                              AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                              AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                       FROM SORLCUR CUR2
                                                       WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                       AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO,

-- Version TZTDMTO (Descuento)
                (SELECT DISTINCT TZTDMTO_PORCENTAJE_ECONTINUA
                FROM TZTDMTO A
                WHERE A.TZTDMTO_PIDM   = A.SORLCUR_PIDM
                AND   A.TZTDMTO_CAMP_CODE = A.SORLCUR_CAMP_CODE
                AND  A.TZTDMTO_NIVEL  = A.SORLCUR_LEVL_CODE
                AND A.TZTDMTO_PROGRAMA =  A.SORLCUR_PROGRAM
                AND A.TZTDMTO_IND = 1
                AND A.TZTDMTO_STUDY_PATH = A.SORLCUR_KEY_SEQNO
                AND ( A.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                     OR A.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                               FROM TZTDMTO TZT
                                               WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                               AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                               AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                               AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                               AND TZT.TZTDMTO_IND = 1
                                               AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                               AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE))
                AND A.TZTDMTO_ACTIVITY_DATE = (SELECT MAX (A1.TZTDMTO_ACTIVITY_DATE)
                                                FROM TZTDMTO A1
                                                WHERE A1.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                AND   A1.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                AND  A1.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                AND A1.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                AND A1.TZTDMTO_IND = 1
                                                AND A1.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                AND ( A1.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                                                      OR A1.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                                 FROM TZTDMTO TZT
                                                                                 WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                                 AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                                 AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                                 AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                                 AND TZT.TZTDMTO_IND = 1
                                                                                 AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                                 AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE)))
                 AND A.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE
                 AND ROWNUM = 1)DESCUENTO,
                (SELECT DISTINCT TZTDMTO_MONTO
                FROM TZTDMTO A
                WHERE A.TZTDMTO_PIDM   = A.SORLCUR_PIDM
                AND   A.TZTDMTO_CAMP_CODE = A.SORLCUR_CAMP_CODE
                AND  A.TZTDMTO_NIVEL  = A.SORLCUR_LEVL_CODE
                AND A.TZTDMTO_PROGRAMA =  A.SORLCUR_PROGRAM
                AND A.TZTDMTO_IND = 1
                AND A.TZTDMTO_STUDY_PATH = A.SORLCUR_KEY_SEQNO
                AND ( A.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                     OR A.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                               FROM TZTDMTO TZT
                                               WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                               AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                               AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                               AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                               AND TZT.TZTDMTO_IND = 1
                                               AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                               AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE))
                AND A.TZTDMTO_ACTIVITY_DATE = (SELECT MAX (A1.TZTDMTO_ACTIVITY_DATE)
                                                FROM TZTDMTO A1
                                                WHERE A1.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                AND   A1.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                AND  A1.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                AND A1.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                AND A1.TZTDMTO_IND = 1
                                                AND A1.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                AND ( A1.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                                                      OR A1.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                                 FROM TZTDMTO TZT
                                                                                 WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                                 AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                                 AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                                 AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                                 AND TZT.TZTDMTO_IND = 1
                                                                                 AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                                 AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE)))
                 AND A.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE
                 AND ROWNUM = 1)MONTO_DSI,
                CASE
                SUBSTR (SORLCUR_RATE_CODE, 1, 1)
                WHEN  ('P') THEN SUBSTR (SORLCUR_RATE_CODE, 2, 2)
                WHEN  ('C') THEN SUBSTR (SORLCUR_RATE_CODE, 3, 1)-- Se agrega
                WHEN  ('J') THEN SUBSTR (SORLCUR_RATE_CODE, 3, 1)
                END NUM_PAG,
                SFRSTCR_VPDI_CODE FOLIO
        FROM SORLCUR A, SPRIDEN D, SFRSTCR F, SSBSECT G, SZTDTEC E
        WHERE A.SORLCUR_PIDM = D.SPRIDEN_PIDM
        AND A.SORLCUR_LMOD_CODE = 'LEARNER'
        AND A.SORLCUR_ROLL_IND  = 'Y'
        AND A.SORLCUR_CACT_CODE = 'ACTIVE'
        AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                               FROM SORLCUR A1
                               WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                               AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                               AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                               AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                               AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
        AND A.SORLCUR_TERM_CODE_CTLG = E.SZTDTEC_TERM_CODE
        AND D.SPRIDEN_CHANGE_IND IS NULL
        AND F.SFRSTCR_PIDM = A.SORLCUR_PIDM
        AND F.SFRSTCR_RSTS_CODE = 'RE'
        AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
        AND F.SFRSTCR_TERM_CODE = G.SSBSECT_TERM_CODE
        AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
        AND (SFRSTCR_RESERVED_KEY NOT IN ('M1HB401', 'CP001', 'CPB13001') OR SFRSTCR_RESERVED_KEY IS NULL )
        AND (F.SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL)
        AND (F.SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
        AND (F.SFRSTCR_USER_ID != 'MIGRA_D' OR F.SFRSTCR_USER_ID IS NULL)
        AND F.SFRSTCR_CRN = G.SSBSECT_CRN
        AND F.SFRSTCR_PTRM_CODE = G.SSBSECT_PTRM_CODE
        AND G.SSBSECT_PTRM_START_DATE = P_FECHA
        AND D.SPRIDEN_PIDM = P_PIDM 
        AND A.SORLCUR_PROGRAM = P_PROGRAMA);

        DBMS_OUTPUT.PUT_LINE('PARCIALIDAD (OK) = ' || VL_PARCIALIDAD);

  EXCEPTION
  WHEN OTHERS THEN
       VL_PARCIALIDAD:=0;
       DBMS_OUTPUT.PUT_LINE('PARCIALIDAD (EXECPTION) = ' || VL_PARCIALIDAD || ' --> ' || SQLERRM);
  END;
  RETURN(VL_PARCIALIDAD);
END F_PARCIALIDAD_ECONTINUA;


FUNCTION F_SALDO_VENCIDO_CURSERA (P_PIDM NUMBER) RETURN VARCHAR2 IS
/*FUNCION CON RETORNO BOOLEAN DETERMINA SI CUENTA CON SALDO VENCIDO Y PRESENTA EL CODIGO DE COURSERA*/

VL_EXISTE  NUMBER;
VL_ERROR   VARCHAR2(500);
VL_SALDO   NUMBER;

  BEGIN

    BEGIN
       SELECT COUNT (TBRACCD_DETAIL_CODE)
         INTO VL_EXISTE
         FROM TBRACCD
        WHERE     TBRACCD_PIDM = P_PIDM
              AND TBRACCD_DETAIL_CODE = '47YO'
              AND (TBRACCD_DOCUMENT_NUMBER !='WCANCE' OR TBRACCD_DOCUMENT_NUMBER IS NULL)
--              AND TBRACCD_CREATE_SOURCE LIKE 'TZFEDCA%'
              AND TRUNC (TBRACCD_EFFECTIVE_DATE) <= TRUNC (SYSDATE)
              AND TBRACCD_STSP_KEY_SEQUENCE IN (SELECT MAX(SORLCUR_KEY_SEQNO)
                                                    FROM SORLCUR A
                                                   WHERE     SORLCUR_PIDM = P_PIDM
--                                                         AND A.SORLCUR_PROGRAM = P_PROGRAMA
                                                         AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                                                         AND A.SORLCUR_ROLL_IND = 'Y'
                                                         AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                                                         AND A.SORLCUR_SEQNO = (SELECT MAX (A1.SORLCUR_SEQNO)
                                                                                   FROM SORLCUR A1
                                                                                  WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                                        AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND
                                                                                        AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
--                                                                                        AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                                                        AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE));

     EXCEPTION
     WHEN OTHERS THEN
     VL_EXISTE:=0;
     END;

    IF VL_EXISTE > 0 THEN

    BEGIN
      SELECT SUM (TBRACCD_BALANCE)
        INTO VL_SALDO
        FROM TBRACCD A
       WHERE TBRACCD_PIDM = P_PIDM
       --AND TBRACCD_DOCUMENT_NUMBER IS NULL
       AND TRUNC (TBRACCD_EFFECTIVE_DATE) <= TRUNC (SYSDATE);
    END;

     IF VL_SALDO <= 0 THEN
     VL_ERROR:='EXITO';
     ELSE
     VL_ERROR:='NO APLICA';
     END IF;
     ELSE
     VL_ERROR:='NO APLICA';
     END IF;

   --DBMS_OUTPUT.PUT_LINE('Entra ='||VL_ERROR);

    RETURN (VL_ERROR);
    END F_SALDO_VENCIDO_CURSERA;

FUNCTION F_AVANCE_DATOS (P_PIDM NUMBER, P_PROGRAMA VARCHAR2) RETURN PKG_FINANZAS_GGC.CURSOR_AVANCE_OUT AS
AVANCE_OUT PKG_FINANZAS_GGC.CURSOR_AVANCE_OUT;
/*FUNCION CURSOR RETORNA AVANCE Y ESTATUS*/
VL_STUDY   NUMBER;
VL_AVANCE  NUMBER;
VL_STATUS  VARCHAR2(20);
VL_ERROR   VARCHAR2(100);

BEGIN

   BEGIN
        SELECT DISTINCT SORLCUR_KEY_SEQNO
          INTO VL_STUDY
          FROM SORLCUR A
         WHERE     A.SORLCUR_PIDM = P_PIDM
               AND A.SORLCUR_PROGRAM = P_PROGRAMA
               AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                         FROM SORLCUR A1
                                        WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                              AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM);

      EXCEPTION WHEN OTHERS THEN
      VL_ERROR := 'ERROR EN SORLCUR = '|| SQLERRM;
      END;
   DBMS_OUTPUT.PUT_LINE('study ='||VL_STUDY);

    IF VL_ERROR IS NULL THEN


      BEGIN
         OPEN AVANCE_OUT FOR
         SELECT ROUND (SZTHITA_AVANCE) AVANCE,
                       SZTHITA_STATUS STATUS
                 INTO VL_AVANCE,VL_STATUS
                 FROM SZTHITA
                WHERE SZTHITA_PIDM = P_PIDM
                      AND SZTHITA_PROG = P_PROGRAMA
                      AND SZTHITA_STUDY  = VL_STUDY;

        EXCEPTION WHEN OTHERS THEN
        VL_ERROR :=  'szthita = '||SQLERRM;
        END;

   END IF;

DBMS_OUTPUT.PUT_LINE('avance = '||VL_AVANCE||' '||'status = '||VL_STATUS);

 RETURN (AVANCE_OUT);

END F_AVANCE_DATOS;

FUNCTION F_COSTO_MEMBRESIA (P_PIDM NUMBER) RETURN VARCHAR2 IS

VL_ENTRA            NUMBER;
VL_COD_ACC          VARCHAR2(5);
VL_DESCRI_ACC       VARCHAR2(35);
VL_DESCUENTO_ACC    NUMBER;
VL_ERROR            VARCHAR2(900);
VL_PORCE_DESC       NUMBER;
VL_DESCUE_SW        NUMBER;
VL_MONTO_ACC        NUMBER;
VL_COD_DESCUENTO    VARCHAR2(5);
VL_AJUSTE           NUMBER;
VL_DESCRI_DESCUENTO VARCHAR2(35);


 BEGIN

   BEGIN
       SELECT COUNT(*)
         INTO VL_ENTRA
         FROM SZTUTLX X
        WHERE     1 = 1
              AND X.SZTUTLX_PIDM = P_PIDM
              AND X.SZTUTLX_DISABLE_IND = 'I'
              AND X.SZTUTLX_SEQ_NO = ( SELECT MAX (SZTUTLX_SEQ_NO)
                                         FROM SZTUTLX
                                        WHERE SZTUTLX_PIDM = X.SZTUTLX_PIDM)
              AND X.SZTUTLX_PIDM IN ( SELECT TZFACCE_PIDM
                                        FROM TZFACCE
                                       WHERE     TZFACCE_PIDM = X.SZTUTLX_PIDM
                                             AND SUBSTR(TZFACCE_DETAIL_CODE,3,2) = ('QI'));

   EXCEPTION WHEN
   OTHERS THEN
   VL_ENTRA:=0;
   END;


     IF VL_ENTRA>0 THEN


      BEGIN
              SELECT DISTINCT TZFACCE_DETAIL_CODE,TBBDETC_DESC,TBBDETC_AMOUNT,SZTUTLX_ROW3
                INTO VL_COD_ACC,VL_DESCRI_ACC,VL_MONTO_ACC,VL_DESCUENTO_ACC
                FROM TZFACCE E,SZTUTLX X,TBBDETC
               WHERE     E.TZFACCE_PIDM = X.SZTUTLX_PIDM
                     AND E.TZFACCE_PIDM = P_PIDM
                     AND E.TZFACCE_DETAIL_CODE = TBBDETC_DETAIL_CODE
                     AND SUBSTR(E.TZFACCE_DETAIL_CODE,3,2) IN ('QI')
                     AND E.TZFACCE_SEC_PIDM = (SELECT MAX(TZFACCE_SEC_PIDM)
                                                 FROM TZFACCE
                                                 WHERE TZFACCE_PIDM = E.TZFACCE_PIDM
                                                       AND SUBSTR(TZFACCE_DETAIL_CODE,3,2) IN ('QI'))
                     AND X.SZTUTLX_SEQ_NO = ( SELECT MAX (SZTUTLX_SEQ_NO)
                                                FROM SZTUTLX
                                               WHERE SZTUTLX_PIDM = X.SZTUTLX_PIDM);
       EXCEPTION
       WHEN OTHERS THEN
       VL_ERROR:='ERROR EN CALCULAR CODIGO '||SQLERRM;
       END;

      BEGIN
          SELECT SWTMDAC_PERCENT_DESC, SWTMDAC_AMOUNT_DESC, SWTMDAC_DETAIL_CODE_DESC,TBBDETC_DESC
            INTO VL_PORCE_DESC,VL_DESCUE_SW,VL_COD_DESCUENTO,VL_DESCRI_DESCUENTO
            FROM SWTMDAC A,TBBDETC
           WHERE     SUBSTR(A.SWTMDAC_DETAIL_CODE_ACC,3,2) IN ('QI')
                 AND A.SWTMDAC_DETAIL_CODE_DESC = TBBDETC_DETAIL_CODE
                 AND A.SWTMDAC_PIDM = P_PIDM
                 AND A.SWTMDAC_SEC_PIDM = (SELECT MAX(SWTMDAC_SEC_PIDM)
                                             FROM SWTMDAC
                                            WHERE     SWTMDAC_PIDM = A.SWTMDAC_PIDM
                                                  AND SUBSTR(SWTMDAC_DETAIL_CODE_ACC,3,2) IN ('QI'));
      EXCEPTION
      WHEN OTHERS THEN
      VL_ERROR:='ERROR EN CALCULAR CODIGO SW'||SQLERRM;
      END;

      IF VL_PORCE_DESC IS NOT NULL AND (VL_DESCUE_SW IS NULL OR VL_DESCUE_SW = 0 ) THEN

                 VL_AJUSTE := VL_MONTO_ACC*(VL_PORCE_DESC/100);

              ELSIF VL_DESCUE_SW IS NOT NULL AND (VL_PORCE_DESC IS NULL OR VL_PORCE_DESC = 0) THEN

                 VL_AJUSTE := VL_DESCUE_SW;

      END IF;

      VL_MONTO_ACC:=VL_MONTO_ACC - VL_AJUSTE;

--      IF VL_ERROR IS NULL THEN
--
--       RETURN VL_MONTO_ACC;
--
--       ELSE
--
--       RETURN VL_ERROR;
--
--       END IF;

      ELSE

       VL_ERROR:='ERROR AL CALCULAR STATUS MEMBRESIA';

   END IF;

   IF VL_ERROR IS NULL THEN

    RETURN VL_MONTO_ACC;

    ELSE

    RETURN VL_ERROR;

   END IF;

END F_COSTO_MEMBRESIA;

FUNCTION BAJA_STATUS_BA (P_PIDM NUMBER, P_FECHA_INICIO DATE, P_PARC_XVEN VARCHAR2 ) RETURN VARCHAR2 IS

/*FUNCION AJUSTA STATUS BA
AUTOR GGARICA*/



VL_NUMPAG            NUMBER:=0;
VL_EXISTE_DETAIL     VARCHAR2(6);
VL_EXIS_CONTRA_2     NUMBER;
VL_DIAS_AJUSTE       NUMBER;
VL_TRANSACCION       NUMBER;
VL_PERIODO           VARCHAR2(6);
VL_AJUSTA            NUMBER;
VL_CAN_BECA          VARCHAR2(500);
VL_PROMOCION         NUMBER;
VL_PROMOCION_MONTO   NUMBER;
VL_PROMOCION_TRAN    NUMBER;
VL_PROMOCION_VIG     DATE;
VL_PROMOCION_PERIODO VARCHAR2(6);
VL_APL_AJUSTE        VARCHAR2(500);
VL_ERROR             VARCHAR2(900);



  BEGIN

       FOR ADEUDO IN (

               SELECT B.TBRACCD_PIDM PIDM,
                                  B.TBRACCD_AMOUNT MONTO,
                                  B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                  (B.TBRACCD_AMOUNT- NVL((SELECT SUM(TBRACCD_AMOUNT)
                                                           FROM TBRACCD
                                                          WHERE     TBRACCD_PIDM = B.TBRACCD_PIDM
                                                                AND TBRACCD_CREATE_SOURCE = 'CANCELA DINA'
                                                                AND TBRACCD_TRAN_NUMBER_PAID = B.TBRACCD_TRAN_NUMBER
                                                                ),0))*(100/100) DESCUENTO, ----AGREGAR DATO A LA TABLA
                                  SPRIDEN_ID ID,
                                  TBRACCD_STSP_KEY_SEQUENCE,
                                  TBRACCD_PERIOD PARTE, --RLS20180131,
                                  TBRACCD_TERM_CODE PERIODO,
                                  TBRACCD_EFFECTIVE_DATE FECHA_EFFECTIVA,
                                  TBRACCD_RECEIPT_NUMBER
                             FROM TBRACCD B, SPRIDEN
                            WHERE     B.TBRACCD_PIDM = P_PIDM
                                  AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                  FROM TBBDETC
                                                                 WHERE     TBBDETC_DCAT_CODE = 'COL'
                                                                       AND SUBSTR (TBBDETC_DETAIL_CODE,1,2)  = SUBSTR (B.TBRACCD_TERM_CODE,1,2)
                                                                       AND TBBDETC_DETC_ACTIVE_IND = 'Y' )
                                  AND B.TBRACCD_EFFECTIVE_DATE >= P_FECHA_INICIO
                                  AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                  AND SPRIDEN_CHANGE_IND IS NULL
                                  AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                  AND B.TBRACCD_TRAN_NUMBER = (SELECT MAX (TBRACCD_TRAN_NUMBER)
                                                              FROM TBRACCD
                                                             WHERE TBRACCD_PIDM = B.TBRACCD_PIDM
                                                                   AND TBRACCD_CREATE_SOURCE = B.TBRACCD_CREATE_SOURCE
                                                                   AND TBRACCD_DOCUMENT_NUMBER IS NULL)
        ORDER BY B.TBRACCD_TRAN_NUMBER



    )LOOP

    VL_NUMPAG            :=NULL;
    VL_EXISTE_DETAIL     :=NULL;
    VL_EXIS_CONTRA_2     :=NULL;
    VL_DIAS_AJUSTE       :=NULL;
    VL_TRANSACCION       :=NULL;
    VL_PERIODO           :=NULL;
    VL_AJUSTA            :=NULL;
    VL_CAN_BECA          :=NULL;
    VL_PROMOCION         :=NULL;
    VL_PROMOCION_MONTO   :=NULL;
    VL_PROMOCION_TRAN    :=NULL;
    VL_PROMOCION_VIG     :=NULL;
    VL_PROMOCION_PERIODO :=NULL;
    VL_APL_AJUSTE        :=NULL;


--    DBMS_OUTPUT.PUT_LINE('POR VENCER -'||ADEUDO.SECUENCIA
--                                           ||'-'||ADEUDO.PIDM
--                                           ||'-'||P_PARC_XVEN
--                                           ||'-'||ADEUDO.DESCUENTO
--                                           ||'-'||ADEUDO.FECHA_EFFECTIVA);

      BEGIN
        SELECT NVL(MAX(A1.TBRAPPL_PAY_TRAN_NUMBER),0)
          INTO VL_NUMPAG
          FROM TBRAPPL A1
         WHERE A1.TBRAPPL_PIDM = P_PIDM
           AND A1.TBRAPPL_CHG_TRAN_NUMBER = ADEUDO.SECUENCIA
           AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                            FROM TBRAPPL A
                                           WHERE A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                             AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
      EXCEPTION
      WHEN OTHERS THEN
      VL_NUMPAG :=0;
      END;

--      DBMS_OUTPUT.PUT_LINE(ADEUDO.PIDM||'-'||ADEUDO.SECUENCIA||'/'||VL_NUMPAG);

      BEGIN
        SELECT B.TBRACCD_DETAIL_CODE
          INTO VL_EXISTE_DETAIL
          FROM TBRACCD B
         WHERE B.TBRACCD_PIDM = ADEUDO.PIDM
           AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;

      EXCEPTION
      WHEN OTHERS THEN
      VL_EXISTE_DETAIL :=0;
      END;

--         DBMS_OUTPUT.PUT_LINE(VL_EXISTE_DETAIL);

---   -      BEGIN
---   -       DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_CONCEPTO_PARC_VEN||'/'||VL_EXISTE_DETAIL);

      IF P_PARC_XVEN <> VL_EXISTE_DETAIL THEN
---   -      IF '01Y4' <> '01M3' THEN
--         DBMS_OUTPUT.PUT_LINE ('ENTRA AL IF =' ||VL_EXISTE_DETAIL);
        BEGIN
          SELECT COUNT (ZSTPARA_PARAM_VALOR)
            INTO VL_EXIS_CONTRA_2
            FROM ZSTPARA
           WHERE     ZSTPARA_MAPA_ID = 'DET_CODE_CART'
                 AND ZSTPARA_PARAM_ID = 'PARC_ANTERIOR'
                 AND ZSTPARA_PARAM_VALOR = SUBSTR(VL_EXISTE_DETAIL,3,2);
        EXCEPTION
        WHEN OTHERS THEN
        VL_EXIS_CONTRA_2:=0;
        END;

--        DBMS_OUTPUT.PUT_LINE ('VL_EXIS_CONTRA_2 =' ||VL_EXIS_CONTRA_2);

        IF VL_EXIS_CONTRA_2 = 0 THEN
--        DBMS_OUTPUT.PUT_LINE ('VL_EXIS_CONTRA_2 =' ||VL_EXIS_CONTRA_2);
--       DBMS_OUTPUT.PUT_LINE(P_PARC_XVEN||'/'||VL_EXISTE_DETAIL);

          BEGIN
            SELECT TO_NUMBER(ZSTPARA_PARAM_VALOR)
              INTO VL_DIAS_AJUSTE
              FROM ZSTPARA
             WHERE     ZSTPARA_MAPA_ID = 'DIAS_BAJADT'
                   AND ZSTPARA_PARAM_ID = 'GENERAL';

          END;
--         DBMS_OUTPUT.PUT_LINE ('VL_DIAS_AJUSTE =' ||VL_DIAS_AJUSTE);

          IF TRUNC(SYSDATE) <= TRUNC(TRUNC(SYSDATE)-(TO_CHAR(TRUNC(SYSDATE),'DD')-1))+VL_DIAS_AJUSTE THEN
            VL_AJUSTA:= 1;
            ELSE
            VL_AJUSTA:= 0;
          END IF;

--         DBMS_OUTPUT.PUT_LINE ('VL_AJUSTA_4=' ||VL_AJUSTA);

        END IF;

      END IF;


      IF VL_AJUSTA = 1 THEN
--      DBMS_OUTPUT.PUT_LINE ('VL_AJUSTA_5=' ||VL_AJUSTA);

          VL_CAN_BECA:= PKG_FINANZAS_REZA.F_AJ_CAN_BECA ( P_PIDM,
                                                          ADEUDO.SECUENCIA,
                                                          P_FECHA_INICIO,
                                                          'CANCELACION');

        BEGIN
          SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
            INTO VL_TRANSACCION
            FROM TBRACCD
           WHERE TBRACCD_PIDM=ADEUDO.PIDM;
        EXCEPTION
        WHEN OTHERS THEN
        VL_TRANSACCION:=0;
        END;

        BEGIN
          SELECT FGET_PERIODO_GENERAL(SUBSTR(ADEUDO.ID,1,2))
            INTO VL_PERIODO
            FROM DUAL;
        EXCEPTION
        WHEN OTHERS THEN
        VL_PERIODO := '000000';
        END;

--        DBMS_OUTPUT.PUT_LINE(VL_PERIODO||'<<<<'||ADEUDO.ID);

        PKG_FINANZAS.P_DESAPLICA_PAGOS (ADEUDO.PIDM, ADEUDO.SECUENCIA) ;

--        DBMS_OUTPUT.PUT_LINE('entra desaplica pagos');

        BEGIN

            INSERT
              INTO TBRACCD
            VALUES (
                       ADEUDO.PIDM,                        -- TBRACCD_PIDM
                       VL_TRANSACCION,                     --TBRACCD_TRAN_NUMBER
                       ADEUDO.PERIODO,                     -- TBRACCD_TERM_CODE
                       P_PARC_XVEN,                        --TBRACCD_DETAIL_CODE
                       USER,                               --TBRACCD_USER
                       SYSDATE,                            --TBRACCD_ENTRY_DATE
                       NVL(ADEUDO.DESCUENTO,0),            --TBRACCD_AMOUNT
                       NVL(ADEUDO.DESCUENTO,0) * -1,       --TBRACCD_BALANCE
                       SYSDATE,                            -- TBRACCD_EFFECTIVE_DATE
                       NULL,                               --TBRACCD_BILL_DATE
                       NULL,                               --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                      'AJUSTE BAJA TEMPORAL',              -- TBRACCD_DESC
                       ADEUDO.TBRACCD_RECEIPT_NUMBER,      --TBRACCD_RECEIPT_NUMBER
                       ADEUDO.SECUENCIA,                   --TBRACCD_TRAN_NUMBER_PAID
                       NULL,                               --TBRACCD_CROSSREF_PIDM
                       NULL,                               --TBRACCD_CROSSREF_NUMBER
                       NULL,                               --TBRACCD_CROSSREF_DETAIL_CODE
                       'T',                                --TBRACCD_SRCE_CODE
                       'Y',                                --TBRACCD_ACCT_FEED_IND
                       SYSDATE,                            --TBRACCD_ACTIVITY_DATE
                       0,                                  --TBRACCD_SESSION_NUMBER
                       NULL,                               -- TBRACCD_CSHR_END_DATE
                       NULL,                               --TBRACCD_CRN
                       NULL,                               --TBRACCD_CROSSREF_SRCE_CODE
                       NULL,                               -- TBRACCD_LOC_MDT
                       NULL,                               --TBRACCD_LOC_MDT_SEQ
                       NULL,                               -- TBRACCD_RATE
                       NULL,                               --TBRACCD_UNITS
                       NULL,                               -- TBRACCD_DOCUMENT_NUMBER
                       SYSDATE,                            -- TBRACCD_TRANS_DATE
                       NULL,                               -- TBRACCD_PAYMENT_ID
                       NULL,                               -- TBRACCD_INVOICE_NUMBER
                       NULL,                               -- TBRACCD_STATEMENT_DATE
                       NULL,                               -- TBRACCD_INV_NUMBER_PAID
                       'MXN',                              -- TBRACCD_CURR_CODE
                       NULL,                               -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                       NULL,                               -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                       NULL,                               -- TBRACCD_LATE_DCAT_CODE
                       P_FECHA_INICIO,                     -- TBRACCD_FEED_DATE
                       NULL,                               -- TBRACCD_FEED_DOC_CODE
                       NULL,                               -- TBRACCD_ATYP_CODE
                       NULL,                               -- TBRACCD_ATYP_SEQNO
                       NULL,                               -- TBRACCD_CARD_TYPE_VR
                       NULL,                               -- TBRACCD_CARD_EXP_DATE_VR
                       NULL,                               -- TBRACCD_CARD_AUTH_NUMBER_VR
                       NULL,                               -- TBRACCD_CROSSREF_DCAT_CODE
                       NULL,                               -- TBRACCD_ORIG_CHG_IND
                       NULL,                               -- TBRACCD_CCRD_CODE
                       NULL,                               -- TBRACCD_MERCHANT_ID
                       NULL,                               -- TBRACCD_TAX_REPT_YEAR
                       NULL,                               -- TBRACCD_TAX_REPT_BOX
                       NULL,                               -- TBRACCD_TAX_AMOUNT
                       NULL,                               -- TBRACCD_TAX_FUTURE_IND
                       'AUTOMATICOa',                      -- TBRACCD_DATA_ORIGIN
                       'AUTOMATICOa',                      -- TBRACCD_CREATE_SOURCE
                       NULL,                               -- TBRACCD_CPDT_IND
                       NULL,                               --TBRACCD_AIDY_CODE
                       ADEUDO.TBRACCD_STSP_KEY_SEQUENCE,   -- TBRACCD_STSP_KEY_SEQUENCE
                       ADEUDO.PARTE,                       -- TBRACCD_PERIOD
                       NULL,                               --TBRACCD_SURROGATE_ID
                       NULL,                               -- TBRACCD_VERSION
                       USER,                               --TBRACCD_USER_ID
                       NULL );                             --TBRACCD_VPDI_CODE

        EXCEPTION
        WHEN OTHERS THEN
        VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para ADEUDOidad en TBRACCD '||SQLERRM;
        END;

--        DBMS_OUTPUT.PUT_LINE('EXITO TBRACCD PRCIALIDADES VENCIDAS');

        BEGIN
          SELECT COUNT(*)
            INTO VL_PROMOCION
            FROM TBRACCD
           WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                 AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                 AND TBRACCD_TRAN_NUMBER_PAID = ADEUDO.SECUENCIA;
        END;

        IF VL_PROMOCION > 0 THEN


          BEGIN
            SELECT TBRACCD_AMOUNT,TBRACCD_TRAN_NUMBER,TBRACCD_EFFECTIVE_DATE,TBRACCD_TERM_CODE
              INTO VL_PROMOCION_MONTO,VL_PROMOCION_TRAN,VL_PROMOCION_VIG,VL_PROMOCION_PERIODO
              FROM TBRACCD
             WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                   AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                   AND TBRACCD_TRAN_NUMBER_PAID = ADEUDO.SECUENCIA;
          END;

          IF VL_PROMOCION_VIG <= TRUNC(SYSDATE) THEN
              VL_PROMOCION_VIG:= TRUNC(SYSDATE);
          ELSE
              VL_PROMOCION_VIG:=VL_PROMOCION_VIG;
          END IF;

          VL_APL_AJUSTE:= PKG_FINANZAS.SP_APLICA_AJUSTE ( ADEUDO.PIDM,
                                                          VL_PROMOCION_TRAN,
                                                          SUBSTR(ADEUDO.PERIODO,1,2)||'ON',
                                                          VL_PROMOCION_MONTO,
                                                          VL_PROMOCION_PERIODO,
                                                          'CANCELACION DE PROMOCION',
                                                          SYSDATE,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          'SZFABCC');

          BEGIN
            UPDATE TBRACCD
               SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
             WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                   AND TBRACCD_DETAIL_CODE = SUBSTR(ADEUDO.PERIODO,1,2)||'ON'
                   AND TBRACCD_USER = 'SZFABCC'
                   AND TRUNC(TBRACCD_EFFECTIVE_DATE) = VL_PROMOCION_VIG;
          EXCEPTION
          WHEN OTHERS THEN
           VL_ERROR :=' Errror al actualizar saldo Saldo>>  ' || SQLERRM ;
          END;

        END IF;

        IF  ADEUDO.DESCUENTO = ADEUDO.MONTO THEN

          BEGIN
            UPDATE TBRACCD
               SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
             WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                   AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
          END;

          BEGIN
            UPDATE TBRACCD
               SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC',
                   TBRACCD_TRAN_NUMBER_PAID = NULL
             WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                   AND TBRACCD_TRAN_NUMBER = ADEUDO.SECUENCIA;
          END;

          BEGIN
            UPDATE TBRACCD
               SET TBRACCD_TRAN_NUMBER_PAID = NULL
             WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                   AND TBRACCD_TRAN_NUMBER_PAID = ADEUDO.SECUENCIA
                   AND (TBRACCD_CREATE_SOURCE != 'CANCELA DINA' OR TBRACCD_CREATE_SOURCE IS NULL)
                   AND TBRACCD_TRAN_NUMBER != VL_TRANSACCION;
          END;

        END IF;

      END IF;

      IF VL_ERROR IS NULL THEN
        VL_ERROR:= 'EXITO';
      ELSE
        VL_ERROR:=VL_ERROR;
      END IF;

    END LOOP;

    RETURN(VL_ERROR);

   COMMIT;

  END BAJA_STATUS_BA;

FUNCTION F_DIPLOMADO_CARG_02 (P_PIDM          NUMBER
                          ,P_FECHA         DATE
                          ,p_Study_Path IN NUMBER DEFAULT NULL
                          ) RETURN VARCHAR2 IS
/*******************************************************************************
   Nombre:    Generacion de cargos por Diplomado.     
   Proposito: Se generar  cargos en el Edo. de Cta. del matriculado por
              Diplomado.

   Revisiones:
   Ver.       Fecha.      Autor.           Descripcion.
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/10/2022  FND@Create       1. Creaci n de la funcion.
   2.0        14/02/2023  FND@Update       2. Actualizacion de la funcion.

   Notas:     

******************************************************************************   
   Marcas de cambio:
   No. 1
   Clave de cambio: 001-14022023-FND
   Autor: FND@Update
   Descripci n: Concatenaci n de caracteres para el concepto de colegiatura
                Col + (Nombre del programa del Dipl. o Curso.).
******************************************************************************
   No. 2
   Clave de cambio: 002-22052023-FND
   Autor: FND@Update
   Descripci n: Alineaci n de Study Path, entre las tablas TZTPROG y TZTDMTO,
                en caso de ser diferentes, se actualizar  el Study Path de la  
                tabla TZTDMTO valor de la tabla TZTPROG. 
****************************************************************************** 
   No. 3
   Clave de cambio: 003-22052023-FND
   Autor: FND@Update
   Descripci n: Definici n de criterios para el c lculo de descuento del cargo 
                a partir de los accesorios escalonados (TZFACCE). 
******************************************************************************   

******************************************************************************/

--DECLARE
---- Parametros de entrada. 
--P_PIDM          NUMBER          := FGET_PIDM('020605554');
--P_FECHA         DATE            := TO_DATE('26/06/2023','DD/MM/YYYY');

-- Variables del proceso.
VL_PARCIALIDAD  NUMBER;
VL_PROMOCION    NUMBER          := 0;
VL_SECUEN       NUMBER;
VL_SECUENCIA    NUMBER;
VL_ERROR        VARCHAR2(1000);
VL_MONEDA       VARCHAR2(3);
VL_DESCRIP      VARCHAR2(40);
VL_CODIGO       VARCHAR2(5);
VL_INSERT       VARCHAR2(900);
VL_PERIODO      VARCHAR2(6)     := NULL;
VL_PARTE        VARCHAR2(4)     := NULL; 
VL_CARGO_DESC   VARCHAR2(40); 
VL_PROG         NUMBER          := 0;
VL_DMTO         NUMBER          := 0;
VL_MONTO_DSI    NUMBER          := 0;
VL_SEC_FACE     NUMBER          := 0;

Vm_Contador     NUMBER (4) := 1; -- Contador de Iteraciones en el paquete OMS 10/Nov/2023

   Vm_Jornada     SGRSATT.SGRSATT_ATTS_CODE%TYPE := NULL;
   Vm_CuentaSFRSTCR NUMBER := 0;


BEGIN


-- Graba en la bitacora de entrada OMS 23/ABRIL/2024
BEGIN
  SELECT Count(*) INTO Vm_CuentaSFRSTCR FROM SFRSTCR WHERE SFRSTCR_pidm = p_pidm;
EXCEPTION WHEN OTHERS THEN Vm_CuentaSFRSTCR := 0;
END;

/*
INSERT INTO TMP_BITACORA_PKG Values (sysdate, USER,
       ' --> P_PIDM = ' || P_PIDM || ' --> P_FECHA = ' || TO_CHAR (P_FECHA, 'dd/fmMonth/yyyy hh24:mi') || 
       ' --> p_Study_Path = ' || p_Study_Path || ' --> Registros SFRSTCR = ' || Vm_CuentaSFRSTCR);
--COMMIT;
*/

-- Cursor para la obtenci n de los datos del matriculado que tiene uno o m s programas de Diplomado.
    DBMS_OUTPUT.PUT_LINE('(Cur.) Obtenci n de los datos del matriculado que tiene uno o m s programas de Diplomado.'||CHR(10));

    FOR X IN (
                SELECT SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB    SECT_MATERIA 
                       ,SFRSTCR_PIDM                            STCR_PIDM  
                       ,SSBSECT_PTRM_START_DATE                 SECT_FECHA_INICIO 
                       ,SFRSTCR_TERM_CODE                       STCR_PERIODO 
                       ,SFRSTCR_PTRM_CODE                       STCR_PARTE_PERIODO
                       ,SFRSTCR_VPDI_CODE                       STCR_ORDEN 
                       ,SFRSTCR_STSP_KEY_SEQUENCE               STCR_STUDY_PATH
                       ,SGBSTDN_CAMP_CODE                       STDN_CAMPUS
                       ,SUBSTR (SGBSTDN_RATE_CODE, 2, 2)        NUM_PAGOS
                       ,(DECODE (SUBSTR (SGBSTDN_RATE_CODE, 4, 1), 'A', 15, 'B', '30')) VENCIMIENTO
                       ,SUBSTR (SGBSTDN_RATE_CODE, 1, 1)        TIPO_PAGO
                       ,SGBSTDN_RATE_CODE                       RATE                       
                       ,SGBSTDN_LEVL_CODE                       STDN_NIVEL
                       ,SORLCUR_PROGRAM                         SORL_PROGRAMA
                       ,SORLCUR_START_DATE                      SORL_FECHA_INICIO
                       ,SORLCUR_VPDI_CODE                       SORL_PARTE_PERIODO
                   FROM SFRSTCR STCR
                        JOIN SSBSECT SECT ON SECT.SSBSECT_TERM_CODE = STCR.SFRSTCR_TERM_CODE 
                                    AND SECT.SSBSECT_CRN = STCR.SFRSTCR_CRN 
                                    AND TRUNC(SECT.SSBSECT_PTRM_START_DATE) = P_FECHA
                        JOIN SGBSTDN STDN ON STDN.SGBSTDN_PIDM = STCR.SFRSTCR_PIDM       
                        JOIN SORLCUR SORL ON SORL.SORLCUR_PIDM = STCR.SFRSTCR_PIDM
                                         AND SORL.SORLCUR_LMOD_CODE = 'LEARNER'
                                         AND SORL.SORLCUR_TERM_CODE = STCR.SFRSTCR_TERM_CODE 
                                         AND SORL.SORLCUR_START_DATE = SECT.SSBSECT_PTRM_START_DATE
                                         AND SORL.SORLCUR_KEY_SEQNO = STCR.SFRSTCR_STSP_KEY_SEQUENCE 
                   WHERE 1 = 1
                     AND STCR.SFRSTCR_PIDM = P_PIDM
                     AND STCR.SFRSTCR_RSTS_CODE ='RE' 
                     AND STCR.SFRSTCR_STSP_KEY_SEQUENCE = NVL (p_Study_Path, STCR.SFRSTCR_STSP_KEY_SEQUENCE)
              )LOOP                             


     -- Se Obtiene la VM_JORNADA
     BEGIN
        SELECT T.SGRSATT_ATTS_CODE
          INTO Vm_Jornada 
          FROM SGRSATT T
         WHERE T.SGRSATT_PIDM              = X.STCR_PIDM
           AND T.SGRSATT_STSP_KEY_SEQUENCE = X.STCR_STUDY_PATH
           AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
           AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
           AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                             FROM SGRSATT TT
                                            WHERE TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                              AND TT.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                              AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                              AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
           AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                            FROM SGRSATT T1
                                           WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                             AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                             AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                             AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                             AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]'))
                                               ;

     EXCEPTION
        WHEN OTHERS THEN
             BEGIN
               -- Si no encuentra el registro del STUDY PATH; se toma el maximo del surrogate
               SELECT T.SGRSATT_ATTS_CODE
                 INTO Vm_Jornada 
                 FROM SGRSATT T
                WHERE T.SGRSATT_PIDM              = X.STCR_PIDM      
               -- AND T.SGRSATT_STSP_KEY_SEQUENCE = p_study_path     
                  AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
                  AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                  AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                    FROM SGRSATT TT
                                                   WHERE TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                  -- AND TT.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                     AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                     AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
                 AND T.SGRSATT_SURROGATE_ID = (SELECT MAX(SGRSATT_SURROGATE_ID)
                                                 FROM SGRSATT T1
                                                WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                               -- AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                  AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                  AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                  AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]'))
                                                    ;

             EXCEPTION 
                WHEN OTHERS THEN
                Vm_Jornada := NULL;
             END;
     END;



              -- Resultado del cursor del matriculado de uno o m s diplomados. 
                /*
                DBMS_OUTPUT.PUT_LINE('-> Resultado del cursor del matriculado de uno o m s diplomado.'||CHR(10));                  
                DBMS_OUTPUT.PUT_LINE('   Materia            ->  (X.SECT_MATERIA )       : '||X.SECT_MATERIA ||CHR(10)
                                   ||'   Pidm               ->  (X.STCR_PIDM)           : '||X.STCR_PIDM||CHR(10)
                                   ||'   Fecha de inicio    ->  (X.SECT_FECHA_INICIO)   : '||TO_DATE(X.SECT_FECHA_INICIO,'DD/MM/*YYYY')||CHR(10)
                                   ||'   Periodo            ->  (X.STCR_PERIODO)        : '||X.STCR_PERIODO||CHR(10)                                   
                                   ||'   Parte periodo      ->  (X.STCR_PARTE_PERIODO)  : '||X.STCR_PARTE_PERIODO||CHR(10)
                                   ||'   Folio              ->  (X.STCR_ORDEN)          : '||X.STCR_ORDEN||CHR(10)                                   
                                   ||'   Study path         ->  (X.STCR_STUDY_PATH )    : '||X.STCR_STUDY_PATH ||CHR(10)
                                   ||'   Campus             ->  (X.STDN_CAMPUS)         : '||X.STDN_CAMPUS||CHR(10)
                                   ||'   No. de pagos       ->  (X.NUM_PAGOS)           : '||X.NUM_PAGOS||CHR(10)
                                   ||'   D a Vencimiento    ->  (X.VENCIMIENTO)         : '||X.VENCIMIENTO||CHR(10) 
                                   ||'   Tipo de pago       ->  (X.TIPO_PAGO)           : '||X.TIPO_PAGO||CHR(10) 
                                   ||'   Plan (Rate)        ->  (X.RATE)                : '||X.RATE||CHR(10)
                                   ||'   Nivel              ->  (X.STDN_NIVEL)          : '||X.STDN_NIVEL||CHR(10)                                                                                                                                          
                                   ||'   Programa           ->  (X.SORL_PROGRAMA)       : '||X.SORL_PROGRAMA||CHR(10)
                                   ||'   Fecha de inicio    ->  (X.SORL_FECHA_INICIO)   : '||X.SORL_FECHA_INICIO||CHR(10)
                                   ||'   Parte periodo      ->  (X.SORL_PARTE_PERIODO)  : '||X.SORL_PARTE_PERIODO||CHR(10)
                                   ||'   Jornada            ->  (Vm_Jornada)            : '||Vm_Jornada||CHR(10)||CHR(10));
                */

                -- Validaci n: Existencia en TZTPROG.
                    BEGIN

                        -- DBMS_OUTPUT.PUT_LINE('Validaci n de existencia de registro en TZTPROG para la matricula '||GB_COMMON.F_GET_ID(P_PIDM)||CHR(10));

                        SELECT COUNT(1)
                          INTO VL_PROG
                          FROM TZTPROG
                         WHERE 1 = 1
                           AND CAMPUS = X.STDN_CAMPUS
                           AND NIVEL = X.STDN_NIVEL
                           AND ESTATUS = 'MA'
                           AND PROGRAMA = X.SORL_PROGRAMA
                           AND SP = X.STCR_STUDY_PATH
                           AND FECHA_INICIO = X.SORL_FECHA_INICIO
                           AND PIDM = X.STCR_PIDM
                           AND MATRICULA = GB_COMMON.F_GET_ID(X.STCR_PIDM);

                        -- DBMS_OUTPUT.PUT_LINE('-->   (Qry.)  Existencia de registro en TZTPROG?: '||VL_PROG||CHR(10));                           

                    END;

                -- Validaci n: Existencia en TZTDMTO.
                    BEGIN

                        -- DBMS_OUTPUT.PUT_LINE('Validaci n de existencia de registro en TZTDMTO para la matricula '||GB_COMMON.F_GET_ID(P_PIDM)||CHR(10));

                        SELECT COUNT (1)
                          INTO VL_DMTO
                          FROM TZTDMTO DMTO
                         WHERE 1 = 1 
                           AND DMTO.TZTDMTO_CAMP_CODE = X.STDN_CAMPUS
                           AND DMTO.TZTDMTO_NIVEL = X.STDN_NIVEL
                           AND DMTO.TZTDMTO_STUDY_PATH = X.STCR_STUDY_PATH
                           AND DMTO.TZTDMTO_TERM_CODE = X.STCR_PERIODO
                           AND DMTO.TZTDMTO_PROGRAMA = X.SORL_PROGRAMA
                           AND DMTO.TZTDMTO_PIDM = X.STCR_PIDM
                           AND DMTO.TZTDMTO_ID = GB_COMMON.F_GET_ID(X.STCR_PIDM);  

                        -- DBMS_OUTPUT.PUT_LINE('-->   (Qry.)  Existencia de registro en TZTDMTO?: '||VL_DMTO||CHR(10));       

                    END;    

                -- Si el valor de TZTPROG es diferente de TZTDMTO entonces... 
                    IF VL_PROG != VL_DMTO THEN

                        -- DBMS_OUTPUT.PUT_LINE('Si el valor de TZTPROG es diferente de TZTDMTO entonces...  '||CHR(10));

                     -- Se alinear  el valor del Study Path de TZTDMTO con el valor del Study Path de TZTPROG.
                        BEGIN

                            -- DBMS_OUTPUT.PUT_LINE('Se alinear  el valor del Study Path de TZTDMTO con el valor del Study Path de TZTPROG. '||CHR(10));

                            UPDATE TZTDMTO DMTO
                               SET DMTO.TZTDMTO_STUDY_PATH = X.STCR_STUDY_PATH
                             WHERE 1 = 1
                               AND DMTO.TZTDMTO_CAMP_CODE  = X.STDN_CAMPUS
                               AND DMTO.TZTDMTO_NIVEL      = X.STDN_NIVEL
                               AND DMTO.TZTDMTO_TERM_CODE  = X.STCR_PERIODO
                               AND DMTO.TZTDMTO_PROGRAMA   = X.SORL_PROGRAMA
                               AND DMTO.TZTDMTO_PIDM       = X.STCR_PIDM
                               AND DMTO.TZTDMTO_ID         = GB_COMMON.F_GET_ID(X.STCR_PIDM);

                            -- DBMS_OUTPUT.PUT_LINE('-->   (Qry.) Study Path alineado/actualizado en TZTDMTO con  xito... '||CHR(10)); 

                      --      COMMIT;

                        EXCEPTION
                            WHEN OTHERS THEN
                                VL_ERROR := '-->    (Exc.) Error al alinear/actualizar Study Path en TZTDMTO... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10)||CHR(10);
                                    -- DBMS_OUTPUT.PUT_LINE (VL_ERROR||CHR(10)||CHR(10));
                        END; 

                    END IF;

                -- Obteni n del monto DSI del alumno.
                    BEGIN

                        -- DBMS_OUTPUT.PUT_LINE('Obteni n del monto DSI del alumno.'||CHR(10));

                        SELECT DISTINCT DMTO.TZTDMTO_MONTO
                           INTO VL_MONTO_DSI
                           FROM TZTDMTO DMTO
                          WHERE 1 = 1
                            AND DMTO.TZTDMTO_PIDM = X.STCR_PIDM
                            AND DMTO.TZTDMTO_CAMP_CODE = X.STDN_CAMPUS
                            AND DMTO.TZTDMTO_NIVEL  = X.STDN_NIVEL
                            AND DMTO.TZTDMTO_PROGRAMA =  X.SORL_PROGRAMA
                            AND DMTO.TZTDMTO_IND = 1
                            AND DMTO.TZTDMTO_STUDY_PATH = X.STCR_STUDY_PATH
                            AND (DMTO.TZTDMTO_TERM_CODE  = X.STCR_PERIODO
                                 OR DMTO.TZTDMTO_TERM_CODE = (SELECT MAX (DMTO1.TZTDMTO_TERM_CODE)
                                                                FROM TZTDMTO DMTO1
                                                               WHERE 1 = 1
                                                                 AND DMTO1.TZTDMTO_PIDM = DMTO.TZTDMTO_PIDM
                                                                 AND DMTO1.TZTDMTO_CAMP_CODE = DMTO.TZTDMTO_CAMP_CODE
                                                                 AND DMTO1.TZTDMTO_NIVEL = DMTO.TZTDMTO_NIVEL
                                                                 AND DMTO1.TZTDMTO_PROGRAMA = DMTO.TZTDMTO_PROGRAMA
                                                                 AND DMTO1.TZTDMTO_IND = 1
                                                                 AND DMTO1.TZTDMTO_STUDY_PATH = DMTO.TZTDMTO_STUDY_PATH
                                                                 AND DMTO1.TZTDMTO_TERM_CODE  <= X.STCR_PERIODO))
                            AND DMTO.TZTDMTO_ACTIVITY_DATE = (SELECT MAX (DMTO2.TZTDMTO_ACTIVITY_DATE)
                                                                FROM TZTDMTO DMTO2
                                                               WHERE 1 = 1
                                                                 AND DMTO2.TZTDMTO_PIDM = DMTO.TZTDMTO_PIDM
                                                                 AND DMTO2.TZTDMTO_CAMP_CODE = DMTO.TZTDMTO_CAMP_CODE
                                                                 AND DMTO2.TZTDMTO_NIVEL = DMTO.TZTDMTO_NIVEL
                                                                 AND DMTO2.TZTDMTO_PROGRAMA = DMTO.TZTDMTO_PROGRAMA
                                                                 AND DMTO2.TZTDMTO_IND = 1
                                                                 AND DMTO2.TZTDMTO_STUDY_PATH = DMTO.TZTDMTO_STUDY_PATH
                                                                 AND (DMTO2.TZTDMTO_TERM_CODE  = X.STCR_PERIODO
                                                                      OR DMTO2.TZTDMTO_TERM_CODE = (SELECT MAX (DMTO3.TZTDMTO_TERM_CODE)
                                                                                                   FROM TZTDMTO DMTO3
                                                                                                  WHERE 1 = 1
                                                                                                    AND DMTO3.TZTDMTO_PIDM = DMTO.TZTDMTO_PIDM
                                                                                                    AND DMTO3.TZTDMTO_CAMP_CODE = DMTO.TZTDMTO_CAMP_CODE
                                                                                                    AND DMTO3.TZTDMTO_NIVEL = DMTO.TZTDMTO_NIVEL
                                                                                                    AND DMTO3.TZTDMTO_PROGRAMA = DMTO.TZTDMTO_PROGRAMA
                                                                                                    AND DMTO3.TZTDMTO_IND = 1
                                                                                                    AND DMTO3.TZTDMTO_STUDY_PATH = DMTO.TZTDMTO_STUDY_PATH
                                                                                                    AND DMTO3.TZTDMTO_TERM_CODE  <= X.STCR_PERIODO)));

                        -- DBMS_OUTPUT.PUT_LINE('     (Qry.) Monto DSI: '||TO_CHAR(VL_MONTO_DSI,'$999,999.00')||CHR(10)||CHR(10));       

                    EXCEPTION   
                        WHEN OTHERS THEN 
                            NULL;
                                -- DBMS_OUTPUT.PUT_LINE('     (Exc.) Monto DSI: '||TO_CHAR(VL_MONTO_DSI,'$999,999.00')||CHR(10)||CHR(10));                                                                                                    
                    END;

                -- Seteo de variables a NULO.    
                    -- DBMS_OUTPUT.PUT_LINE('Seteo de variables a NULO:'||CHR(10));

                    VL_PARCIALIDAD  := NULL;

                    -- DBMS_OUTPUT.PUT_LINE('   Parcialidad                  ->  (VL_PARCIALIDAD): '||NVL(TO_CHAR(VL_PARCIALIDAD,NULL),'Vac o / Nulo.'));

                    VL_SECUEN       := NULL;

                    -- DBMS_OUTPUT.PUT_LINE('   Folio                        ->  (VL_SECUEN)     : '||NVL(TO_CHAR(VL_SECUEN,NULL),'Vac o / Nulo.'));

                    VL_SECUENCIA    := NULL;

                    -- DBMS_OUTPUT.PUT_LINE('   No. de reg. del Edo. de Cta. ->  (VL_SECUENCIA)  : '||NVL(TO_CHAR(VL_SECUENCIA,NULL),'Vac o / Nulo.'));

                    VL_ERROR        := NULL;

                    -- DBMS_OUTPUT.PUT_LINE('   Error                        ->  (VL_ERROR)      : '||NVL(TO_CHAR(VL_ERROR,NULL),'Vac o / Nulo.'));

                    VL_MONEDA       := NULL;

                    -- DBMS_OUTPUT.PUT_LINE('   Divisa                       ->  (VL_MONEDA)     : '||NVL(TO_CHAR(VL_MONEDA,NULL),'Vac o / Nulo.'));

                    VL_CODIGO       := NULL;

                    -- DBMS_OUTPUT.PUT_LINE('   Cod. de detalle              ->  (VL_CODIGO)     : '||NVL(TO_CHAR(VL_CODIGO,NULL),'Vac o / Nulo.')||CHR(10)||CHR(10));


                -- C lculo de parcialidad.
                    -- DBMS_OUTPUT.PUT_LINE('-> C lculo de parcialidad correspondiente(PKG_FINANZAS_GGC.F_PARCIALIDAD_ECONTINUA) para el matriculado '||GB_COMMON.F_GET_ID(X.STCR_PIDM)||', '||CHR(10)||'   en donde se pide el Pidm del alumno('||X.STCR_PIDM||') y la fecha de inicio de actividades('||X.SORL_FECHA_INICIO||').'||CHR(10));

                    VL_PARCIALIDAD := PKG_FINANZAS_GGC.F_PARCIALIDAD_ECONTINUA (X.STCR_PIDM                                                                 ,X.SORL_FECHA_INICIO, X.SORL_PROGRAMA, X.STCR_STUDY_PATH, Vm_Jornada);     -- OMS 11/Agosto/2023

                    -- DBMS_OUTPUT.PUT_LINE('   (Fnc.) Parcialidad correspondiente: '||TO_CHAR(VL_PARCIALIDAD,'$999,999.00')||CHR(10)||CHR(10));                                                                      

                -- Seteo de variable para c lculo de promoci n.    
                    -- DBMS_OUTPUT.PUT_LINE('-> Seteo de variable para c lculo de promoci n a 0.'||CHR(10));

                    VL_PROMOCION := 0;

                    -- DBMS_OUTPUT.PUT_LINE('   Promoci n    ->  (VL_PROMOCION) : '||VL_PROMOCION||CHR(10)||CHR(10));

                -- Descuento por promocion de inscripcion (M3).
                    -- DBMS_OUTPUT.PUT_LINE('-> Descuento por promocion de inscripcion (M3) para el matriculado('||GB_COMMON.F_GET_ID(X.STCR_PIDM)||').'||CHR(10));       

                    BEGIN                                                                         
                       -- Nueva Version para obtener el descuento 13/Nov/2023 OMS
                       SELECT DISTINCT NVL (TZFACCE_AMOUNT,0), FACE.TZFACCE_SEC_PIDM
                         INTO VL_PROMOCION, VL_SEC_FACE
                         FROM TZFACCE FACE 
                        WHERE 1 = 1
                          AND FACE.TZFACCE_PIDM = X.STCR_PIDM                  
                          AND SUBSTR(FACE.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                          AND FACE.TZFACCE_FLAG  = 0
                          AND FACE.TZFACCE_STUDY = X.STCR_STUDY_PATH
                          AND FACE.TZFACCE_EFFECTIVE_DATE = (SELECT MIN(FACE1.TZFACCE_EFFECTIVE_DATE)
                                                               FROM TZFACCE FACE1
                                                              WHERE 1 = 1
                                                                AND FACE1.TZFACCE_PIDM = X.STCR_PIDM
                                                                AND SUBSTR (FACE1.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                                                                AND FACE1.TZFACCE_FLAG  = 0
                                                                AND FACE1.TZFACCE_STUDY = FACE.TZFACCE_STUDY);

                        -- DBMS_OUTPUT.PUT_LINE('   (Qry) Descuento por promocion de inscripcion (M3)(VL_PROMOCION): '||TO_CHAR(VL_PROMOCION,'$999,999.00')||CHR(10)||CHR(10));    

                    EXCEPTION    
                        WHEN OTHERS THEN
                            VL_PROMOCION := 0;
                               -- DBMS_OUTPUT.PUT_LINE('   (Exc.) Descuento por promocion de inscripcion (M3)(VL_PROMOCION): '||TO_CHAR(VL_PROMOCION,'$999,999.00')||CHR(10)||CHR(10));

                    END;      

                -- Si hay descuento por promoci n de inscripcion, entonces...                                 
                    IF VL_PROMOCION > 0 THEN 

                        -- DBMS_OUTPUT.PUT_LINE('-> Si hay descuento por promoci n de inscripcion, entonces...'||CHR(10));

                    -- Actualizaci n de promoci n consumida a 1.                        
                        BEGIN 

                            -- DBMS_OUTPUT.PUT_LINE('Consume el registro de promoci n de inscripcion en los accesorios escalonados(TZFACCE)'||CHR(10));

                            UPDATE TZFACCE FACE
                               SET FACE.TZFACCE_FLAG = 1
                             WHERE 1 = 1
                               AND FACE.TZFACCE_PIDM     = X.STCR_PIDM
                               AND FACE.TZFACCE_SEC_PIDM = VL_SEC_FACE
                               AND SUBSTR(FACE.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                               AND FACE.TZFACCE_FLAG      = 0
                               AND FACE.TZFACCE_STUDY     = X.STCR_STUDY_PATH;

                            -- DBMS_OUTPUT.PUT_LINE('     (Qry.) Actualiza el registro de promoci n de inscripcion en los accesorios escalonados(TZFACCE) a consumido(1)'||CHR(10)||CHR(10));       

                        EXCEPTION   
                            WHEN OTHERS THEN 
                                NULL;
                                    DBMS_OUTPUT.PUT_LINE('     (Exc.) No se actualiza el registro de promoci n a consumido.'||CHR(10)||CHR(10));
                        END;

                    END IF; 

                -- Si hay parcialidad, entonces... 
                    IF VL_PARCIALIDAD IS NOT NULL THEN

                        -- DBMS_OUTPUT.PUT_LINE('-> Si hay parcialidad, entonces... '||CHR(10));

                    -- Setea la variable del No. de reg. del Edo. de Cta. a 0.
                        -- DBMS_OUTPUT.PUT_LINE('   Setea la variable del No. de reg. del Edo. de Cta. a 0.'||CHR(10));

                        VL_SECUENCIA := 0;

                        -- DBMS_OUTPUT.PUT_LINE('   No. de reg. del Edo. de Cta. ->  (VL_SECUENCIA): '||VL_SECUENCIA||CHR(10)||CHR(10));

                    -- N mero siguiente de registro en el Edo. de Cta. (TBRACCD).                        
                        BEGIN

                            -- DBMS_OUTPUT.PUT_LINE('-> Consulta del No. m ximo de registro en el Edo. de Cta. del matriculado.'||CHR(10));

                            SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) + 1
                              INTO VL_SECUENCIA
                              FROM TBRACCD
                             WHERE 1 = 1
                               AND TBRACCD_PIDM = X.STCR_PIDM;

                            -- DBMS_OUTPUT.PUT_LINE('   (Qry.)  No. m ximo de registro del Edo. de Cta. del matriculado (VL_SECUENCIA)?: '||VL_SECUENCIA||CHR(10)||CHR(10));

                        EXCEPTION
                            WHEN OTHERS THEN
                                VL_SECUENCIA := 1;
                                       DBMS_OUTPUT.PUT_LINE('   (Exc.)  No. m ximo de registro del Edo. de Cta. del matriculado (VL_SECUENCIA)?: '||VL_SECUENCIA||CHR(10)||CHR(10));
                        END;

                    -- Si el No. de folio / orden es nulo, entonces... 
                        IF X.STCR_ORDEN IS NULL THEN

                            -- DBMS_OUTPUT.PUT_LINE('-> Si el No. de folio / orden(X.FOLIO) es Nulo o vac o, entonces...'||CHR(10));                            

                            BEGIN 

                                -- DBMS_OUTPUT.PUT_LINE('Se obtiene el nuevo No. de folio / orden para ser registrado la tabla de ordenes(TZTORDR).'||CHR(10));
                                SELECT TZTORDR_CONTADOR
                                  INTO VL_SECUEN
                                  FROM TZTORDR
                                 WHERE 1 = 1
                                   AND TZTORDR_CAMPUS = X.STDN_CAMPUS
                                   AND TZTORDR_NIVEL  = X.STDN_NIVEL
                                   AND TZTORDR_PIDM   = X.STCR_PIDM
                                   AND TRUNC (TZTORDR_FECHA_INICIO) = X.SORL_FECHA_INICIO
                                   AND TZTORDR_ESTATUS = 'S'; 

                            -- DBMS_OUTPUT.PUT_LINE('   (Qry.)  No. de folio / orden nuevo(VL_SECUEN)?: '||VL_SECUEN||CHR(10)||CHR(10));       

                            EXCEPTION
                                WHEN OTHERS THEN 
                                    VL_SECUEN := NULL;
                                           DBMS_OUTPUT.PUT_LINE('   (Exc.)  No. de folio / orden nuevo(VL_SECUEN)?: '||VL_SECUEN||CHR(10)||CHR(10));
                            END;

                        -- Si el No. de folio / orden est  vac o o nulo, entonces...                                     
                            IF VL_SECUEN IS NULL THEN 

                                -- DBMS_OUTPUT.PUT_LINE('Si el No. de folio / orden est  vac o o nulo, entonces...'||CHR(10));

                                BEGIN

                                    -- DBMS_OUTPUT.PUT_LINE('Se obtiene el nuevo No. de folio / orden m s 1. '||CHR(10));

                                    SELECT MAX(TZTORDR_CONTADOR) + 1
                                      INTO VL_SECUEN
                                      FROM TZTORDR
                                     WHERE 1 = 1;

                                    -- DBMS_OUTPUT.PUT_LINE('  (Qry.) Nuevo No. de folio / orden: '||VL_SECUEN||CHR(10)||CHR(10));     

                                EXCEPTION
                                    WHEN OTHERS THEN
                                        VL_SECUEN := NULL;
                                            -- DBMS_OUTPUT.PUT_LINE('  (Exc.) Nuevo No. de folio / orden: '||VL_SECUEN||CHR(10)||CHR(10));
                                END;

                            -- Inserta registro del nuevo No. de orden en la tabla de  folios / ordenes (TZTORDR).                                                    
                                BEGIN

                                    -- DBMS_OUTPUT.PUT_LINE('Inserta registro del nuevo No. de orden en la tabla de  folios / ordenes (TZTORDR). '||CHR(10));

                                    INSERT INTO TZTORDR(TZTORDR_CAMPUS
                                                       ,TZTORDR_NIVEL
                                                       ,TZTORDR_CONTADOR
                                                       ,TZTORDR_PROGRAMA
                                                       ,TZTORDR_PIDM
                                                       ,TZTORDR_ID
                                                       ,TZTORDR_ESTATUS
                                                       ,TZTORDR_ACTIVITY_DATE
                                                       ,TZTORDR_USER
                                                       ,TZTORDR_DATA_ORIGIN
                                                       ,TZTORDR_NO_REGLA
                                                       ,TZTORDR_FECHA_INICIO
                                                       ,TZTORDR_RATE
                                                       ,TZTORDR_JORNADA
                                                       ,TZTORDR_DSI
                                                       ,TZTORDR_TERM_CODE)
                                                 VALUES(X.STDN_CAMPUS
                                                       ,X.STDN_NIVEL
                                                       ,VL_SECUEN
                                                       ,X.SORL_PROGRAMA
                                                       ,X.STCR_PIDM
                                                       ,GB_COMMON.F_GET_ID(X.STCR_PIDM)
                                                       ,'S'
                                                       ,SYSDATE
                                                       ,USER
                                                       ,'TZTFEDCA'
                                                       ,NULL
                                                       ,X.SORL_FECHA_INICIO
                                                       ,X.RATE
                                                       ,Vm_Jornada
                                                       ,VL_MONTO_DSI
                                                       ,X.STCR_PERIODO);

                                    /*
                                    DBMS_OUTPUT.PUT_LINE('->((Qry.) Inserta el folio /No. de orden en TZTORDR con  xito, con los siguientes datos: '||CHR(10)
                                                       ||'TZTORDR_CAMPUS            --> X.STDN_CAMPUS                       : '||X.STDN_CAMPUS                   ||CHR(10)
                                                       ||'TZTORDR_NIVEL             --> X.STDN_NIVEL                        : '||X.STDN_NIVEL                    ||CHR(10)
                                                       ||'TZTORDR_CONTADOR          --> VL_SECUEN                           : '||VL_SECUEN                       ||CHR(10)
                                                       ||'TZTORDR_PROGRAMA          --> X.SORL_PROGRAMA                     : '||X.SORL_PROGRAMA                 ||CHR(10)
                                                       ||'TZTORDR_PIDM              --> X.STCR_PIDM                         : '||X.STCR_PIDM                     ||CHR(10)
                                                       ||'TZTORDR_ID                --> GB_COMMON.F_GET_ID(X.STCR_PIDM)     : '||GB_COMMON.F_GET_ID(X.STCR_PIDM) ||CHR(10)
                                                       ||'TZTORDR_ESTATUS           --> S                                   : '||'S'                             ||CHR(10)
                                                       ||'TZTORDR_ACTIVITY_DATE     --> SYSDATE                             : '||SYSDATE                         ||CHR(10)
                                                       ||'TZTORDR_USER              --> USER                                : '||USER                            ||CHR(10)
                                                       ||'TZTORDR_DATA_ORIGIN       --> TZTFEDCA                            : '||'TZTFEDCA'                      ||CHR(10)
                                                       ||'TZTORDR_NO_REGLA          --> NULL                                : '||NULL                            ||CHR(10)
                                                       ||'TZTORDR_FECHA_INICIO      --> X.SORL_FECHA_INICIO                 : '||X.SORL_FECHA_INICIO             ||CHR(10)
                                                       ||'TZTORDR_RATE              --> X.RATE                              : '||X.RATE                          ||CHR(10)
                                                       ||'TZTORDR_JORNADA           --> Vm_Jornada                           : '||Vm_Jornada                       ||CHR(10)
                                                       ||'TZTORDR_DSI               --> VL_MONTO_DSI                        : '||VL_MONTO_DSI                    ||CHR(10)
                                                       ||'TZTORDR_TERM_CODE         --> X.STCR_PERIODO                      : '||X.STCR_PERIODO                  ||CHR(10)||CHR(10));
                                    */

                                EXCEPTION
                                    WHEN OTHERS THEN
                                        VL_ERROR := 'Error al calcular el folio /No. de orden... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10);
                                            -- DBMS_OUTPUT.PUT_LINE(VL_ERROR||CHR(10)||CHR(10));
                                END;

                            END IF;

                        END IF;

                    -- Si no hay error, entonces... 
                        IF VL_ERROR IS NULL THEN

                            -- DBMS_OUTPUT.PUT_LINE('Si no hay error en el proceso, entonces... '||CHR(10));

                        -- Calcula el Cod. de Detalle, Descripci n del detalle y la moneda.
                            BEGIN

                                -- DBMS_OUTPUT.PUT_LINE('Calcula el Cod. de detalle, concepto y la moneda. '||CHR(10));

                                SELECT TBBDETC_DETAIL_CODE
                                      ,TBBDETC_DESC
                                      ,TVRDCTX_CURR_CODE
                                  INTO VL_CODIGO
                                      ,VL_DESCRIP
                                      ,VL_MONEDA
                                  FROM TBBDETC
                                      ,TVRDCTX
                                 WHERE 1 = 1
                                   AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE                              
                                   AND TBBDETC_DETAIL_CODE = SUBSTR(GB_COMMON.F_GET_ID(X.STCR_PIDM),1,2)||CASE
                                                                                                            WHEN SUBSTR(X.SORL_PROGRAMA,4,2) = 'DI' THEN
                                                                                                                'NR'
                                                                                                            WHEN SUBSTR(X.SORL_PROGRAMA,4,2) = 'CU' THEN
                                                                                                                'NQ'
                                                                                                          END;    

                                /*
                                DBMS_OUTPUT.PUT_LINE('Resultado del Cod. de detalle, concepto y moneda: '||CHR(10)
                                                   ||'Cod. de detalle   (VL_CODIGO)     : '||VL_CODIGO||CHR(10)
                                                   ||'Conceto           (VL_DESCRIP)    : '||VL_DESCRIP||CHR(10)
                                                   ||'Moneda            (VL_MONEDA)     : '||VL_MONEDA ||CHR(10)||CHR(10));
                                */

                            EXCEPTION
                                WHEN OTHERS THEN
                                    VL_ERROR := '-> (Exc.) Error al calcular el Cod. de Detalle, Descripci n del detalle y/o la moneda... Favor de revisar...'||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM;
                                           -- DBMS_OUTPUT.PUT_LINE(VL_ERROR||CHR(10));
                            END;

                        -- Concatenaci n de la descripci n: COL. + "Nombre del programa" para cargo en el Edo. de Cta.                             
                            BEGIN

                                -- DBMS_OUTPUT.PUT_LINE('Concatenaci n de la descripci n: COL. + Nombre del programa para cargo en el Edo. de Cta.'||CHR(10));

                                SELECT TBBDETC_DESC
                                    -- OMS 23/Nov/2023
                                    -- Se elimina el cambio de agregar el nombre del diplomado en la descripcion de la cartera
                                    -- SUBSTR(TBBDETC_DESC,1,3)||'. '||REGEXP_SUBSTR(TBBDETC_DESC, '[^ ]+', 1,2)||' '||X.SORL_PROGRAMA
                                  INTO VL_CARGO_DESC
                                  FROM TBBDETC
                                 WHERE 1 = 1
                                   AND TBBDETC_DETAIL_CODE = VL_CODIGO
                                   AND TBBDETC_DETAIL_CODE = SUBSTR(GB_COMMON.F_GET_ID(X.STCR_PIDM),1,2)||CASE
                                                                                                            WHEN SUBSTR(X.SORL_PROGRAMA,4,2) = 'DI' THEN
                                                                                                                'NR'
                                                                                                            WHEN SUBSTR(X.SORL_PROGRAMA,4,2) = 'CU' THEN
                                                                                                                'NQ'
                                                                                                          END;

                                -- DBMS_OUTPUT.PUT_LINE('  (Qry.) Nuevo nombre de cargo: '||VL_CARGO_DESC||CHR(10));                                        

                            EXCEPTION
                                WHEN OTHERS THEN
                                    VL_CARGO_DESC := 'SIN DESCRIPCION';
                                           -- DBMS_OUTPUT.PUT_LINE('   (Exc.) Nuevo nombre del cargo: '||VL_CARGO_DESC||CHR(10)); 
                            END;                                                                                                                                                               

                        -- Seteo de variables para el periodo y la parte periodo a vac o / nulo. 
                            -- DBMS_OUTPUT.PUT_LINE('Seteo de variables para el periodo y la parte periodo a vac o / nulo. '||CHR(10));

                            VL_PERIODO := NULL;
                            -- DBMS_OUTPUT.PUT_LINE('Valor -> Variable periodo (VL_PERIODO): '||VL_PERIODO||CHR(10));

                            VL_PARTE   := NULL;   
                            -- DBMS_OUTPUT.PUT_LINE('Valor -> Variable parte periodo (VL_PARTE): '||VL_PARTE||CHR(10)||CHR(10));     

                        -- Obtenci n del peroido y parte periodo a partir de la fecha de inicio del alumno.                                                            
                            BEGIN 

                            -- DBMS_OUTPUT.PUT_LINE('Obtenci n del peroido y parte periodo a partir de la fecha de inicio del alumno. '||CHR(10));

                                SELECT DISTINCT SSBSECT_TERM_CODE
                                      ,SSBSECT_PTRM_CODE
                                  INTO VL_PERIODO
                                      ,VL_PARTE 
                                  FROM SFRSTCR
                                    JOIN SSBSECT ON SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE 
                                                AND  SSBSECT_CRN = SFRSTCR_CRN  
                                 WHERE 1 = 1
                                   AND SFRSTCR_PIDM = X.STCR_PIDM
                                   AND SFRSTCR_RSTS_CODE ='RE'
                                   AND TRUNC (SSBSECT_PTRM_START_DATE) = X.SORL_FECHA_INICIO
                                   AND SFRSTCR_STSP_KEY_SEQUENCE       = X.STCR_STUDY_PATH;     -- OMS 08/ABRIL/2024

                                -- DBMS_OUTPUT.PUT_LINE('  (Qry.) Periodo: '||VL_PERIODO||CHR(10)
                                --                   ||'         Parte periodo: '||VL_PARTE||CHR(10)||CHR(10));       


                            EXCEPTION        
                                WHEN OTHERS THEN                   
                                    VL_PERIODO := NULL; 
                                    VL_PARTE   := NULL;
                                        -- DBMS_OUTPUT.PUT_LINE('  (Exc.) Periodo: '||VL_PERIODO||CHR(10)
                                        --                    ||'         Parte periodo: '||VL_PARTE||CHR(10)||CHR(10)); 
                            END;                           

                        -- Si hay periodo y parte periodo, entonces...                                                            
                            IF  VL_PERIODO IS NOT NULL AND  VL_PARTE IS NOT NULL THEN    

                                -- DBMS_OUTPUT.PUT_LINE('Si hay periodo y parte periodo, entonces... '||CHR(10));         

                                BEGIN
                                   -- OMS 22/Marzo/2024  --> Localiza el numero de orden en caso de ser NULL                                                                     
                                   SELECT MAX(SFRSTCR_VPDI_CODE) nOrden
                                     INTO VL_SECUEN
                                     FROM SFRSTCR f
                                    WHERE SFRSTCR_pidm              = X.STCR_PIDM              -- pidm
                                      AND SFRSTCR_stsp_key_sequence = X.STCR_STUDY_PATH        -- Study-Path
                                      AND SFRSTCR_term_code         = VL_PERIODO               -- Periodo
                                      AND SFRSTCR_ptrm_code         = VL_PARTE                 -- Parte de Periodo
                                        ;
                                EXCEPTION WHEN OTHERS THEN VL_SECUEN := NULL;
                                END;

                            -- Inserta el cargo del(los) programa(s) diplomado(s) en el Edo. de Cta. del alumno.                                                                 
                                BEGIN

                                    -- DBMS_OUTPUT.PUT_LINE('Inserta el cargo del(los) programa(s) diplomado(s) en el Edo. de Cta. del alumno. '||CHR(10));

                                    INSERT INTO TBRACCD 
                                         VALUES(X.STCR_PIDM
                                               ,VL_SECUENCIA
                                               ,VL_PERIODO
                                               ,VL_CODIGO
                                               ,USER
                                               ,SYSDATE
                                               ,(VL_PARCIALIDAD - VL_PROMOCION)
                                               ,(VL_PARCIALIDAD - VL_PROMOCION)
                                               ,X.SORL_FECHA_INICIO
                                               ,NULL
                                               ,NULL
                                               ,VL_CARGO_DESC || ' --> p_fecha = ' || p_fecha
-- PRUEBAS 14/Nov/2023    ,REPLACE (VL_CARGO_DESC,'COL. DIPLOMADO UTS',NULL) || ' > F' || p_Contador || ' P' || Vm_Contador
-- PRUEBAS 14/Nov/2023                                                       || ' PR' || VL_PROMOCION || ' S' || VL_SEC_FACE || ' SP' || X.STCR_STUDY_PATH
                                               ,VL_SECUEN
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,'T'
                                               ,'Y'
                                               ,SYSDATE
                                               ,0
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,X.SORL_FECHA_INICIO
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,VL_MONEDA
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,X.SORL_FECHA_INICIO
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,'TZFEDCA (PARC)'
                                               ,'TZFEDCA (PARC)'
                                               ,NULL
                                               ,NULL
                                               ,X.STCR_STUDY_PATH
                                               ,VL_PARTE
                                               ,NULL
                                               ,NULL
                                               ,USER
                                               ,NULL);                                            

                                /*
                                DBMS_OUTPUT.PUT_LINE('(Qry.) Inserta cargos en el Edo. de Cta. con los siguientes datos:'||CHR(10)                                
                                                   ||'TBRACCD_PIDM                 : '||X.STCR_PIDM||CHR(10)    
                                                   ||'TBRACCD_TRAN_NUMBER          : '||VL_SECUENCIA||CHR(10)
                                                   ||'TBRACCD_TERM_CODE            : '||VL_PERIODO||CHR(10)
                                                   ||'TBRACCD_DETAIL_CODE          : '||VL_CODIGO||CHR(10)
                                                   ||'TBRACCD_USER                 : '||USER||CHR(10)
                                                   ||'TBRACCD_ENTRY_DATE           : '||SYSDATE||CHR(10)
                                                   ||'TBRACCD_AMOUNT               : '||(VL_PARCIALIDAD - VL_PROMOCION)||CHR(10)
                                                   ||'TBRACCD_BALANCE              : '||(VL_PARCIALIDAD - VL_PROMOCION)||CHR(10)
                                                   ||'TBRACCD_EFFECTIVE_DATE       : '||X.SORL_FECHA_INICIO||CHR(10)
                                                   ||'TBRACCD_BILL_DATE            : '||NULL||CHR(10)
                                                   ||'TBRACCD_DUE_DATE             : '||NULL||CHR(10)
                                                   ||'TBRACCD_DESC                 : '||VL_CARGO_DESC||CHR(10)
                                                   ||'TBRACCD_RECEIPT_NUMBER       : '||VL_SECUEN||CHR(10)
                                                   ||'TBRACCD_TRAN_NUMBER_PAID     : '||NULL||CHR(10)
                                                   ||'TBRACCD_CROSSREF_PIDM        : '||NULL||CHR(10)
                                                   ||'TBRACCD_CROSSREF_NUMBER      : '||NULL||CHR(10)
                                                   ||'TBRACCD_CROSSREF_DETAIL_CODE : '||NULL||CHR(10)
                                                   ||'TBRACCD_SRCE_CODE            : '||'T'||CHR(10)
                                                   ||'TBRACCD_ACCT_FEED_IND        : '||'Y'||CHR(10)
                                                   ||'TBRACCD_ACTIVITY_DATE        : '||SYSDATE||CHR(10)
                                                   ||'TBRACCD_SESSION_NUMBER       : '||0||CHR(10)
                                                   ||'TBRACCD_CSHR_END_DATE        : '||NULL||CHR(10)
                                                   ||'TBRACCD_CRN                  : '||NULL||CHR(10)
                                                   ||'TBRACCD_CROSSREF_SRCE_CODE   : '||NULL||CHR(10)
                                                   ||'TBRACCD_LOC_MDT              : '||NULL||CHR(10)
                                                   ||'TBRACCD_LOC_MDT_SEQ          : '||NULL||CHR(10)
                                                   ||'TBRACCD_RATE                 : '||NULL||CHR(10)
                                                   ||'TBRACCD_UNITS                : '||NULL||CHR(10)
                                                   ||'TBRACCD_DOCUMENT_NUMBER      : '||NULL||CHR(10)
                                                   ||'TBRACCD_TRANS_DATE           : '||X.SORL_FECHA_INICIO||CHR(10)
                                                   ||'TBRACCD_PAYMENT_ID           : '||NULL||CHR(10)
                                                   ||'TBRACCD_INVOICE_NUMBER       : '||NULL||CHR(10)
                                                   ||'TBRACCD_STATEMENT_DATE       : '||NULL||CHR(10)
                                                   ||'TBRACCD_INV_NUMBER_PAID      : '||NULL||CHR(10)
                                                   ||'TBRACCD_CURR_CODE            : '||VL_MONEDA||CHR(10)
                                                   ||'TBRACCD_EXCHANGE_DIFF        : '||NULL||CHR(10)
                                                   ||'TBRACCD_FOREIGN_AMOUNT       : '||NULL||CHR(10)
                                                   ||'TBRACCD_LATE_DCAT_CODE       : '||NULL||CHR(10)
                                                   ||'TBRACCD_FEED_DATE            : '||X.SORL_FECHA_INICIO||CHR(10)
                                                   ||'TBRACCD_FEED_DOC_CODE        : '||NULL||CHR(10)
                                                   ||'TBRACCD_ATYP_CODE            : '||NULL||CHR(10)
                                                   ||'TBRACCD_ATYP_SEQNO           : '||NULL||CHR(10)
                                                   ||'TBRACCD_CARD_TYPE_VR         : '||NULL||CHR(10)
                                                   ||'TBRACCD_CARD_EXP_DATE_VR     : '||NULL||CHR(10)
                                                   ||'TBRACCD_CARD_AUTH_NUMBER_VR  : '||NULL||CHR(10)
                                                   ||'TBRACCD_CROSSREF_DCAT_CODE   : '||NULL||CHR(10)
                                                   ||'TBRACCD_ORIG_CHG_IND         : '||NULL||CHR(10)
                                                   ||'TBRACCD_CCRD_CODE            : '||NULL||CHR(10)
                                                   ||'TBRACCD_MERCHANT_ID          : '||NULL||CHR(10)
                                                   ||'TBRACCD_TAX_REPT_YEAR        : '||NULL||CHR(10)
                                                   ||'TBRACCD_TAX_REPT_BOX         : '||NULL||CHR(10)
                                                   ||'TBRACCD_TAX_AMOUNT           : '||NULL||CHR(10)
                                                   ||'TBRACCD_TAX_FUTURE_IND       : '||NULL||CHR(10)
                                                   ||'TBRACCD_DATA_ORIGIN          : '||'TZFEDCA (PARC)'||CHR(10)
                                                   ||'TBRACCD_CREATE_SOURCE        : '||'TZFEDCA (PARC)'||CHR(10)
                                                   ||'TBRACCD_CPDT_IND             : '||NULL||CHR(10)
                                                   ||'TBRACCD_AIDY_CODE            : '||NULL||CHR(10)
                                                   ||'TBRACCD_STSP_KEY_SEQUENCE    : '||X.STCR_STUDY_PATH||CHR(10)
                                                   ||'TBRACCD_PERIOD               : '||VL_PARTE||CHR(10)
                                                   ||'TBRACCD_SURROGATE_ID         : '||NULL||CHR(10)
                                                   ||'TBRACCD_VERSION              : '||NULL||CHR(10)
                                                   ||'TBRACCD_USER_ID              : '||USER||CHR(10)
                                                   ||'TBRACCD_VPDI_CODE            : '||NULL||CHR(10)||CHR(10));
                                  */

                                EXCEPTION
                                    WHEN OTHERS THEN
                                        VL_ERROR := '(Exc.) Error al insertar cargos en el Edo. de Cta... Favor de revisar...'||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10);                                         
                                            -- DBMS_OUTPUT.PUT_LINE(VL_ERROR||CHR(10));
                                END;                                         

                            -- Actualiza materias / horarios.
                                BEGIN

                                    -- DBMS_OUTPUT.PUT_LINE('Actualiza materias / horarios (SFRSTCR) '||CHR(10));

                                    UPDATE SFRSTCR
                                       SET SFRSTCR_VPDI_CODE = VL_SECUEN
                                     WHERE 1 = 1
                                       AND SFRSTCR_PIDM              = X.STCR_PIDM
                                       AND SFRSTCR_TERM_CODE         = X.STCR_PERIODO
                                       AND SFRSTCR_PTRM_CODE         = X.STCR_PARTE_PERIODO
                                       AND SFRSTCR_STSP_KEY_SEQUENCE = X.STCR_STUDY_PATH
                                       AND SFRSTCR_VPDI_CODE IS NULL;

                                    -- DBMS_OUTPUT.PUT_LINE('(Qry.) -> Actualiza materias / horarios con  xito.'||CHR(10)||CHR(10));                                       

                                EXCEPTION
                                    WHEN OTHERS THEN
                                        NULL;
                                            -- DBMS_OUTPUT.PUT_LINE('(Exc.) -> No actualiza materias / horarios. '||CHR(10)||CHR(10));
                                END;

                            -- Si no hay errores en el proceso, entonces...                                                    
                                IF VL_ERROR IS NULL THEN 

                                    -- DBMS_OUTPUT.PUT_LINE('Si no hay errores en el proceso, entonces... '||CHR(10));

                                    VL_ERROR := 'EXITO' ;

                                    --COMMIT;

                                    -- DBMS_OUTPUT.PUT_LINE('Confirma(COMMIT) las operaciones / transacciones del proceso(VL_ERRROR):  '||VL_ERROR||CHR(10)||CHR(10));

                            -- Si no...                                                                 
                                ELSE

                                    -- DBMS_OUTPUT.PUT_LINE('Si hay errores en el proceso, entonces... '||CHR(10));

                                    ROLLBACK;

                                    -- DBMS_OUTPUT.PUT_LINE('Reversa(ROLLBACK) las operaciones / transacciones del proceso(VL_ERRROR):  '||VL_ERROR||CHR(10)||CHR(10));

                                END IF;

                            END IF;

                        END IF;

                    END IF;

Vm_Contador := Vm_Contador + 1; -- Contador de Iteraciones en el LOOP OMS 10/Nov/2023

              END LOOP;

    RETURN(VL_ERROR);
    --DBMS_OUTPUT.PUT_LINE(VL_ERROR);

END F_DIPLOMADO_CARG_02;
-- End:   Version de Flavio-MIGR + MEZCLADO OMS


FUNCTION  CANCELA_DIPLOMADO (P_PIDM NUMBER) RETURN VARCHAR2 is

VL_TRAN          NUMBER;
VL_TRAN_NUM      NUMBER:= 1;
VL_APLICA        VARCHAR2(10);
VL_ERROR         VARCHAR2(900);
VL_SECUENCIA     NUMBER;
VL_COD_CANCE     VARCHAR2(10);
VL_DESC          VARCHAR2(50);
VL_MONEDA        VARCHAR2(3);
VL_BALANCE       NUMBER;


BEGIN

     FOR X IN (  

                SELECT 
                      SORLCUR_CAMP_CODE CAMPUS,
                      SORLCUR_LEVL_CODE NIVEL,
                      SORLCUR_PROGRAM PROGRAMA,
                      SORLCUR_RATE_CODE RATE,
                      TBRACCD_PIDM PIDM,
                      TBRACCD_DETAIL_CODE CODIGO,
                      TBRACCD_DESC DESCRIPCION,
                      TBRACCD_EFFECTIVE_DATE FECHA,
                      TO_CHAR(TBRACCD_EFFECTIVE_DATE,'DD')VENCIMIENTO,
                      TBRACCD_AMOUNT MONTO,
                      TBRACCD_TERM_CODE PERIODO,
                      TBRACCD_PERIOD PARTE,
                      TBRACCD_STSP_KEY_SEQUENCE STUDY,
                      TBRACCD_RECEIPT_NUMBER ORDEN,
                      SORLCUR_START_DATE INICIO
                 FROM SORLCUR S,TBRACCD T
                WHERE     S.SORLCUR_PIDM = T.TBRACCD_PIDM
                      AND S.SORLCUR_KEY_SEQNO = T.TBRACCD_STSP_KEY_SEQUENCE
                      AND T.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                      AND T.TBRACCD_DOCUMENT_NUMBER IS NULL
                      AND S.SORLCUR_PIDM= P_PIDM                                            
                      AND T.TBRACCD_EFFECTIVE_DATE = (SELECT MAX(DISTINCT TBRACCD_EFFECTIVE_DATE)
                                                        FROM TBRACCD
                                                       WHERE     TBRACCD_PIDM = T.TBRACCD_PIDM
                                                             AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                                             AND TBRACCD_STSP_KEY_SEQUENCE = T.TBRACCD_STSP_KEY_SEQUENCE
                                                             AND TBRACCD_DOCUMENT_NUMBER IS NULL )
--                      AND S.SORLCUR_PIDM = (SELECT A.SGBSTDN_PIDM
--                                              FROM SGBSTDN A
--                                             WHERE     A.SGBSTDN_PIDM = S.SORLCUR_PIDM
--                                                   AND A.SGBSTDN_STST_CODE = 'BT'
--                                                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT SGBSTDN_TERM_CODE_EFF
--                                                                                    FROM SGBSTDN
--                                                                                   WHERE    SGBSTDN_PIDM = A.SGBSTDN_PIDM
--                                                                                        AND SGBSTDN_STST_CODE = 'BT'))
                      AND S.SORLCUR_LMOD_CODE = 'LEARNER'
                      AND S.SORLCUR_CACT_CODE = 'INACTIVE'
                      AND S.SORLCUR_CAMP_CODE = 'UTS'
                      AND S.SORLCUR_LEVL_CODE = 'EC'                       
                      AND SUBSTR(S.SORLCUR_RATE_CODE,3,1) != 1 
                      AND S.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                FROM SORLCUR A1
                                               WHERE     A1.SORLCUR_PIDM = S.SORLCUR_PIDM
                                                     AND A1.SORLCUR_CACT_CODE = S.SORLCUR_CACT_CODE
                                                     AND A1.SORLCUR_PROGRAM = S.SORLCUR_PROGRAM
                                                     AND A1.SORLCUR_CAMP_CODE = S.SORLCUR_CAMP_CODE
                                                     AND A1.SORLCUR_LEVL_CODE = S.SORLCUR_LEVL_CODE
                                                     AND A1.SORLCUR_LMOD_CODE = S.SORLCUR_LMOD_CODE)                                                      
--                      AND S.SORLCUR_PIDM IN (SELECT GORADID_PIDM
--                                               FROM GORADID
--                                              WHERE    GORADID_PIDM = S.SORLCUR_PIDM
--                                                   AND GORADID_ADID_CODE = 'BIDI')


    )LOOP    

    VL_TRAN_NUM   := NULL;
    VL_APLICA     := NULL;
    VL_ERROR      := NULL;
    VL_SECUENCIA  := NULL;
    VL_COD_CANCE  := NULL;
    VL_MONEDA     := NULL;
    VL_DESC       := NULL;
    VL_BALANCE    := NULL;
    VL_TRAN       := NULL;


        FOR C IN ( 
                   SELECT TBRACCD_TRAN_NUMBER,
                          TBRACCD_BALANCE,
                          TBBDETC_TYPE_IND,
                          TBRACCD_AMOUNT
                     FROM TBRACCD,TBBDETC
                    WHERE     TBRACCD_PIDM = X.PIDM
                          AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                          AND TBRACCD_FEED_DATE = X.INICIO
                          AND TBRACCD_CREATE_SOURCE LIKE 'TZFEDCA%'
                          AND TBRACCD_DOCUMENT_NUMBER IS NULL              
                          AND TBRACCD_EFFECTIVE_DATE >= TRUNC(SYSDATE)
                          AND TBBDETC_DCAT_CODE NOT IN ('DSI','LPC','TUI','DSP') 

      )LOOP


        IF C.TBBDETC_TYPE_IND = 'C' THEN
         VL_BALANCE     := C.TBRACCD_AMOUNT*-1;
         VL_COD_CANCE   := SUBSTR(X.PERIODO,1,2)||'61';
         VL_TRAN:= NULL;

        ELSIF C.TBBDETC_TYPE_IND = 'P' THEN

         VL_BALANCE:= C.TBRACCD_AMOUNT;
         VL_COD_CANCE   := SUBSTR(X.PERIODO,1,2)||'BU';
         VL_TRAN:= C.TBRACCD_TRAN_NUMBER;
        END IF;


        BEGIN
          SELECT TBBDETC_DESC,TVRDCTX_CURR_CODE
          INTO VL_DESC,VL_MONEDA
          FROM TBBDETC,TVRDCTX
          WHERE TBBDETC_DETAIL_CODE = VL_COD_CANCE
                AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE;              
        EXCEPTION
        WHEN OTHERS THEN
        VL_DESC:=NULL;
        END;


        IF C.TBBDETC_TYPE_IND = 'P' THEN

         PKG_FINANZAS.P_DESAPLICA_PAGOS(X.PIDM,C.TBRACCD_TRAN_NUMBER);

        END IF;


        FOR I IN 1..1 LOOP


          IF VL_TRAN_NUM = 1 AND TO_CHAR(TRUNC(SYSDATE),'DD') < 20 THEN VL_APLICA:= 'APLICA';

           ELSE VL_APLICA:= 'APLICA';

          END IF;

          VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (X.PIDM);

          IF VL_APLICA = 'APLICA' THEN


            BEGIN

              INSERT
                INTO TBRACCD
              VALUES ( X.PIDM,                         -- TBRACCD_PIDM
                       VL_SECUENCIA,                   -- TBRACCD_TRAN_NUMBER
                       X.PERIODO,                      -- TBRACCD_TERM_CODE
                       VL_COD_CANCE,                   -- TBRACCD_DETAIL_CODE
                       USER,                           -- TBRACCD_USER
                       SYSDATE,                        -- TBRACCD_ENTRY_DATE
                       NVL(C.TBRACCD_AMOUNT,0),        -- TBRACCD_AMOUNT
                       VL_BALANCE,                     -- TBRACCD_BALANCE
                       TO_DATE(TRUNC(SYSDATE),'DD/MM/RRRR'),  -- TBRACCD_EFFECTIVE_DATE
                       NULL,                           -- TBRACCD_BILL_DATE
                       NULL,                           -- TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                       VL_DESC,                        -- TBRACCD_DESC
                       X.ORDEN,                        -- TBRACCD_RECEIPT_NUMBER
                       VL_TRAN,                        -- TBRACCD_TRAN_NUMBER_PAID
                       NULL,                           -- TBRACCD_CROSSREF_PIDM
                       NULL,                           -- TBRACCD_CROSSREF_NUMBER
                       NULL,                           -- TBRACCD_CROSSREF_DETAIL_CODE
                       'T',                            -- TBRACCD_SRCE_CODE
                       'Y',                            -- TBRACCD_ACCT_FEED_IND
                       SYSDATE,                        -- TBRACCD_ACTIVITY_DATE
                       0,                              -- TBRACCD_SESSION_NUMBER
                       NULL,                           -- TBRACCD_CSHR_END_DATE
                       NULL,                           -- TBRACCD_CRN
                       NULL,                           -- TBRACCD_CROSSREF_SRCE_CODE
                       NULL,                           -- TBRACCD_LOC_MDT
                       NULL,                           -- TBRACCD_LOC_MDT_SEQ
                       NULL,                           -- TBRACCD_RATE
                       NULL,                           -- TBRACCD_UNITS
                       NULL,                           -- TBRACCD_DOCUMENT_NUMBER
                       TO_DATE(TRUNC(SYSDATE),'DD/MM/RRRR'),  -- TBRACCD_TRANS_DATE
                       NULL,                           -- TBRACCD_PAYMENT_ID
                       NULL,                           -- TBRACCD_INVOICE_NUMBER
                       NULL,                           -- TBRACCD_STATEMENT_DATE
                       NULL,                           -- TBRACCD_INV_NUMBER_PAID
                       VL_MONEDA ,                     -- TBRACCD_CURR_CODE
                       NULL,                           -- TBRACCD_EXCHANGE_DIFF
                       NULL,                           -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                       NULL,                           -- TBRACCD_LATE_DCAT_CODE
                       X.INICIO           ,            -- TBRACCD_FEED_DATE
                       NULL,                           --TBRACCD_FEED_DOC_CODE-----POR AHORA
                       NULL,                           -- TBRACCD_ATYP_CODE
                       NULL,                           -- TBRACCD_ATYP_SEQNO
                       NULL,                           -- TBRACCD_CARD_TYPE_VR
                       NULL,                           -- TBRACCD_CARD_EXP_DATE_VR
                       NULL,                           -- TBRACCD_CARD_AUTH_NUMBER_VR
                       NULL,                           -- TBRACCD_CROSSREF_DCAT_CODE
                       NULL,                           -- TBRACCD_ORIG_CHG_IND
                       NULL,                           -- TBRACCD_CCRD_CODE
                       NULL,                           -- TBRACCD_MERCHANT_ID
                       NULL,                           -- TBRACCD_TAX_REPT_YEAR
                       NULL,                           -- TBRACCD_TAX_REPT_BOX
                       NULL,                           -- TBRACCD_TAX_AMOUNT
                       NULL,                           -- TBRACCD_TAX_FUTURE_IND
                       'CANCE',                        -- TBRACCD_DATA_ORIGIN
                       'CANCE',                        -- TBRACCD_CREATE_SOURCE
                       NULL,                           -- TBRACCD_CPDT_IND
                       NULL,                           -- TBRACCD_AIDY_CODE
                       X.STUDY,                        -- TBRACCD_STSP_KEY_SEQUENCE
                       X.PARTE,                        -- TBRACCD_PERIOD
                       NULL,                           -- TBRACCD_SURROGATE_ID
                       NULL,                           -- TBRACCD_VERSION
                       USER,                           -- TBRACCD_USER_ID
                       NULL);                          -- TBRACCD_VPDI_CODE


            EXCEPTION
            WHEN OTHERS THEN
            VL_ERROR := 'Se presento error al insertar en TBRACCD '||SQLERRM;
            END;

             VL_TRAN_NUM:= VL_TRAN_NUM + 1;

          END IF;


          IF VL_ERROR IS NULL THEN 

            UPDATE TBRACCD 
               SET TBRACCD_DOCUMENT_NUMBER = 'CANCE'
             WHERE TBRACCD_PIDM = X.PIDM   
                   AND TBRACCD_TRAN_NUMBER = C.TBRACCD_TRAN_NUMBER;

             UPDATE TVRACCD 
                SET TVRACCD_DOCUMENT_NUMBER = 'CANCE'
             WHERE TVRACCD_PIDM = X.PIDM   
                   AND TVRACCD_ACCD_TRAN_NUMBER = C.TBRACCD_TRAN_NUMBER;

          END IF;

        END LOOP;

      END LOOP;          

    END LOOP;

    IF VL_ERROR IS NULL THEN 
    VL_ERROR:= 'EXITO';    
    END IF;

   COMMIT; 
     DBMS_OUTPUT.PUT_LINE('SALIDA ='||VL_ERROR);
   RETURN(VL_ERROR);

END;
-----
-----




FUNCTION F_DIPLOMADO_CARGO_TRG (p_PIDM       IN NUMBER,
                                p_FECHA      IN DATE,
                                p_Study_Path IN NUMBER   DEFAULT NULL,
                                P_Periodo    IN VARCHAR2 DEFAULT NULL,
                                p_PTRM_CODE  IN VARCHAR2 DEFAULT NULL,
                                p_VPDI_CODE  IN VARCHAR2 DEFAULT NULL,
                                p_CRN        IN VARCHAR2 DEFAULT NULL,
                                P_RSTS_CODE    IN VARCHAR2 DEFAULT NULL, 
                                P_RESERVED_KEY IN VARCHAR2 DEFAULT NULL, 
                                P_DATA_ORIGIN  IN VARCHAR2 DEFAULT NULL, 
                                P_USER_ID      IN VARCHAR2 DEFAULT NULL,
                                P_Materia      IN VARCHAR2 DEFAULT NULL
                               ) RETURN VARCHAR2 IS

-- Descripci n: Aplica el Cargo de la Colegiatrua de Diplomado, a partir del trigger en la tabla de Horarios
-- Variables del proceso.
VL_PARCIALIDAD  NUMBER;
VL_SECUEN       NUMBER;
VL_SECUENCIA    NUMBER;
VL_ERROR        VARCHAR2(1000);
VL_MONEDA       VARCHAR2(3);
VL_DESCRIP      VARCHAR2(40);
VL_CODIGO       VARCHAR2(5);
VL_INSERT       VARCHAR2(900);
VL_PERIODO      VARCHAR2(6)     := NULL;
VL_PARTE        VARCHAR2(4)     := NULL; 
VL_CARGO_DESC   VARCHAR2(40)    := NULL; 
VL_PROMOCION    NUMBER          := 0;
VL_PROG         NUMBER          := 0;
VL_DMTO         NUMBER          := 0;
VL_MONTO_DSI    NUMBER          := 0;
VL_SEC_FACE     NUMBER          := 0;
-------------
VL_PRIM_PAGO    NUMBER          := 0;
VL_SEC_PAGO     NUMBER          := 0;
vl_solicitud    number          :=0;
vl_pagos        number          :=0;

   Vm_Contador      NUMBER (4)  := 1; -- Contador de Iteraciones en el paquete OMS 10/Nov/2023
   Vm_Jornada       SGRSATT.SGRSATT_ATTS_CODE%TYPE := NULL;

BEGIN

--   INSERT INTO TMP_BITACORA_PKG Values (sysdate, USER,
--          ' --> P_PIDM = ' || P_PIDM || ' --> P_FECHA = ' || TO_CHAR (P_FECHA, 'dd/fmMonth/yyyy hh24:mi') || 
--          ' --> p_Study_Path = ' || p_Study_Path);

-- Cursor para la obtenci n de los datos del matriculado que tiene uno o m s programas de Diplomado.
    DBMS_OUTPUT.PUT_LINE('(Cur.) Obtenci n de los datos del matriculado que tiene uno o m s programas de Diplomado. xxxxx'||CHR(10));

    FOR X IN ( 

                select pidm, matricula, estatus,campus, nivel, programa, pkg_utilerias.f_calcula_rate(pidm, programa) rate, (DECODE (SUBSTR (pkg_utilerias.f_calcula_rate(pidm, programa), 4, 1), 'A', 15, 'B', '30')) vencimiento,
                SUBSTR (pkg_utilerias.f_calcula_rate(pidm, programa), 1, 1) TIPO_PAGO, SUBSTR (pkg_utilerias.f_calcula_rate(pidm, programa), 2, 2) NUM_PAGOS, sp
                from tztprog
                where 1=1
                and pidm = p_PIDM
                and sp = p_Study_Path

              )LOOP                             


     -- Se Obtiene la VM_JORNADA
     BEGIN
        SELECT T.SGRSATT_ATTS_CODE
          INTO Vm_Jornada 
          FROM SGRSATT T
         WHERE T.SGRSATT_PIDM              = p_PIDM 
           AND T.SGRSATT_STSP_KEY_SEQUENCE = p_Study_Path
           AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
           AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
           AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                             FROM SGRSATT TT
                                            WHERE TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                              AND TT.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                              AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                              AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
           AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                            FROM SGRSATT T1
                                           WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                             AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                             AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                             AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                             AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]'))
                                               ;

     EXCEPTION
        WHEN OTHERS THEN
             BEGIN
               -- Si no encuentra el registro del STUDY PATH; se toma el maximo del surrogate
               SELECT T.SGRSATT_ATTS_CODE
                 INTO Vm_Jornada 
                 FROM SGRSATT T
                WHERE T.SGRSATT_PIDM              =p_PIDM    
                  AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
                  AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                  AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                    FROM SGRSATT TT
                                                   WHERE TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                     AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                     AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
                 AND T.SGRSATT_SURROGATE_ID = (SELECT MAX(SGRSATT_SURROGATE_ID)
                                                 FROM SGRSATT T1
                                                WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                                  AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                  AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                  AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]'))
                                                    ;

             EXCEPTION 
                WHEN OTHERS THEN
                Vm_Jornada := NULL;
             END;
     END;


                -- Validaci n: Existencia en TZTDMTO.
                   VL_DMTO:=0;
                    BEGIN
                        -- DBMS_OUTPUT.PUT_LINE('Validaci n de existencia de registro en TZTDMTO para la matricula '||GB_COMMON.F_GET_ID(P_PIDM)||CHR(10));
                          SELECT count(1)
                            Into VL_DMTO
                         FROM TZTDMTO DMTO
                         WHERE 1 = 1 
                           AND DMTO.TZTDMTO_CAMP_CODE = X.campus
                           AND DMTO.TZTDMTO_NIVEL = X.nivel
                           AND DMTO.TZTDMTO_PROGRAMA = X.programa
                           AND DMTO.TZTDMTO_PIDM = X.pidm
                           And TZTDMTO_IND = 1;
                    Exception
                        When others then
                            VL_DMTO:=0;
                        -- DBMS_OUTPUT.PUT_LINE('-->   (Qry.)  Existencia de registro en TZTDMTO?: '||VL_DMTO||CHR(10));       

                    END;    

                        ---DBMS_OUTPUT.PUT_LINE('OMS --> Linea 2,254'||CHR(10));



                    IF VL_DMTO >= 1  THEN

                        -- DBMS_OUTPUT.PUT_LINE('Si el valor de TZTPROG es diferente de TZTDMTO entonces...  '||CHR(10));

                     -- Se alinear  el valor del Study Path de TZTDMTO con el valor del Study Path de TZTPROG.
                        BEGIN

                            -- DBMS_OUTPUT.PUT_LINE('Se alinear  el valor del Study Path de TZTDMTO con el valor del Study Path de TZTPROG. '||CHR(10));

                            UPDATE TZTDMTO DMTO
                               SET DMTO.TZTDMTO_STUDY_PATH = X.sp
                             WHERE 1 = 1
                               AND DMTO.TZTDMTO_CAMP_CODE  = X.campus
                               AND DMTO.TZTDMTO_NIVEL      = X.nivel
                               AND DMTO.TZTDMTO_PROGRAMA   = X.programa
                               AND DMTO.TZTDMTO_PIDM       = X.pidm
                               And TZTDMTO_IND = 1;
                            -- DBMS_OUTPUT.PUT_LINE('-->   (Qry.) Study Path alineado/actualizado en TZTDMTO con  xito... '||CHR(10)); 

                        EXCEPTION
                            WHEN OTHERS THEN
                                VL_ERROR := '-->    (Exc.) Error al alinear/actualizar Study Path en TZTDMTO... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10)||CHR(10);
                                    -- DBMS_OUTPUT.PUT_LINE (VL_ERROR||CHR(10)||CHR(10));
                        END; 

                    END IF;

                -- Obteni n del monto DSI del alumno.
                    BEGIN

                        DBMS_OUTPUT.PUT_LINE('Obteni n del monto DSI del alumno.'||CHR(10));

                        SELECT DISTINCT DMTO.TZTDMTO_MONTO
                           INTO VL_MONTO_DSI
                           FROM TZTDMTO DMTO
                          WHERE 1 = 1
                            AND DMTO.TZTDMTO_PIDM = X.pidm
                            AND DMTO.TZTDMTO_CAMP_CODE = X.campus
                            AND DMTO.TZTDMTO_NIVEL  = X.nivel
                            AND DMTO.TZTDMTO_PROGRAMA =  X.programa
                            AND DMTO.TZTDMTO_IND = 1
                            AND DMTO.TZTDMTO_STUDY_PATH = X.sp
                                 OR DMTO.TZTDMTO_TERM_CODE = (SELECT MAX (DMTO1.TZTDMTO_TERM_CODE)
                                                                FROM TZTDMTO DMTO1
                                                               WHERE 1 = 1
                                                                 AND DMTO1.TZTDMTO_PIDM = DMTO.TZTDMTO_PIDM
                                                                 AND DMTO1.TZTDMTO_CAMP_CODE = DMTO.TZTDMTO_CAMP_CODE
                                                                 AND DMTO1.TZTDMTO_NIVEL = DMTO.TZTDMTO_NIVEL
                                                                 AND DMTO1.TZTDMTO_PROGRAMA = DMTO.TZTDMTO_PROGRAMA
                                                                 AND DMTO1.TZTDMTO_IND = 1
                                                                 AND DMTO1.TZTDMTO_STUDY_PATH = DMTO.TZTDMTO_STUDY_PATH
                                                                 )
                            AND DMTO.TZTDMTO_ACTIVITY_DATE = (SELECT MAX (DMTO2.TZTDMTO_ACTIVITY_DATE)
                                                                FROM TZTDMTO DMTO2
                                                               WHERE 1 = 1
                                                                 AND DMTO2.TZTDMTO_PIDM = DMTO.TZTDMTO_PIDM
                                                                 AND DMTO2.TZTDMTO_CAMP_CODE = DMTO.TZTDMTO_CAMP_CODE
                                                                 AND DMTO2.TZTDMTO_NIVEL = DMTO.TZTDMTO_NIVEL
                                                                 AND DMTO2.TZTDMTO_PROGRAMA = DMTO.TZTDMTO_PROGRAMA
                                                                 AND DMTO2.TZTDMTO_IND = 1
                                                                 AND DMTO2.TZTDMTO_STUDY_PATH = DMTO.TZTDMTO_STUDY_PATH
                                                                 and DMTO2.TZTDMTO_TERM_CODE = (SELECT MAX (DMTO3.TZTDMTO_TERM_CODE)
                                                                                                   FROM TZTDMTO DMTO3
                                                                                                  WHERE 1 = 1
                                                                                                    AND DMTO3.TZTDMTO_PIDM = DMTO.TZTDMTO_PIDM
                                                                                                    AND DMTO3.TZTDMTO_CAMP_CODE = DMTO.TZTDMTO_CAMP_CODE
                                                                                                    AND DMTO3.TZTDMTO_NIVEL = DMTO.TZTDMTO_NIVEL
                                                                                                    AND DMTO3.TZTDMTO_PROGRAMA = DMTO.TZTDMTO_PROGRAMA
                                                                                                    AND DMTO3.TZTDMTO_IND = 1
                                                                                                    AND DMTO3.TZTDMTO_STUDY_PATH = DMTO.TZTDMTO_STUDY_PATH
                                                                                                    ));

                        -- DBMS_OUTPUT.PUT_LINE('     (Qry.) Monto DSI: '||TO_CHAR(VL_MONTO_DSI,'$999,999.00')||CHR(10)||CHR(10));       

                    EXCEPTION   
                        WHEN OTHERS THEN 
                            NULL;
                                -- DBMS_OUTPUT.PUT_LINE('     (Exc.) Monto DSI: '||TO_CHAR(VL_MONTO_DSI,'$999,999.00')||CHR(10)||CHR(10));                                                                                                    
                    END;

                -- Seteo de variables a NULO.    
                    -- DBMS_OUTPUT.PUT_LINE('Seteo de variables a NULO:'||CHR(10));

                    VL_PARCIALIDAD  := NULL;
                    -- DBMS_OUTPUT.PUT_LINE('   Parcialidad                  ->  (VL_PARCIALIDAD): '||NVL(TO_CHAR(VL_PARCIALIDAD,NULL),'Vac o / Nulo.'));
                    VL_SECUEN       := NULL;
                    -- DBMS_OUTPUT.PUT_LINE('   Folio                        ->  (VL_SECUEN)     : '||NVL(TO_CHAR(VL_SECUEN,NULL),'Vac o / Nulo.'));
                    VL_SECUENCIA    := NULL;
                    -- DBMS_OUTPUT.PUT_LINE('   No. de reg. del Edo. de Cta. ->  (VL_SECUENCIA)  : '||NVL(TO_CHAR(VL_SECUENCIA,NULL),'Vac o / Nulo.'));
                    VL_ERROR        := NULL;
                    -- DBMS_OUTPUT.PUT_LINE('   Error                        ->  (VL_ERROR)      : '||NVL(TO_CHAR(VL_ERROR,NULL),'Vac o / Nulo.'));
                    VL_MONEDA       := NULL;
                    -- DBMS_OUTPUT.PUT_LINE('   Divisa                       ->  (VL_MONEDA)     : '||NVL(TO_CHAR(VL_MONEDA,NULL),'Vac o / Nulo.'));
                    VL_CODIGO       := NULL;
                    -- DBMS_OUTPUT.PUT_LINE('   Cod. de detalle              ->  (VL_CODIGO)     : '||NVL(TO_CHAR(VL_CODIGO,NULL),'Vac o / Nulo.')||CHR(10)||CHR(10));


                -- C lculo de parcialidad.
                    -- DBMS_OUTPUT.PUT_LINE('-> C lculo de parcialidad correspondiente(PKG_FINANZAS_GGC.F_PARCIALIDAD_ECONTINUA) para el matriculado '||GB_COMMON.F_GET_ID(X.STCR_PIDM)||', '||CHR(10)||'   en donde se pide el Pidm del alumno('||X.STCR_PIDM||') y la fecha de inicio de actividades('||X.SORL_FECHA_INICIO||').'||CHR(10));

                    VL_PARCIALIDAD := PKG_FINANZAS_GGC.F_PARCIALIDAD_ECONTINUA_TGR (X.pidm,
                                                                                p_FECHA, 
                                                                                X.programa, 
                                                                                X.sp, 
                                                                                Vm_Jornada,
                                                                                P_Periodo,
                                                                                p_CRN, 
                                                                                p_PTRM_CODE, 
                                                                                P_RSTS_CODE,
                                                                                P_RESERVED_KEY, 
                                                                                P_DATA_ORIGIN, 
                                                                                P_USER_ID,   
                                                                                p_VPDI_CODE
                                                                                );   -- OMS 07/Junio/2024

                     DBMS_OUTPUT.PUT_LINE('   (Fnc.) Parcialidad correspondiente: '||TO_CHAR(VL_PARCIALIDAD,'$999,999.00')||CHR(10)||CHR(10));                                                                      

                -- Seteo de variable para c lculo de promoci n.    
                    -- DBMS_OUTPUT.PUT_LINE('-> Seteo de variable para c lculo de promoci n a 0.'||CHR(10));



                    -- DBMS_OUTPUT.PUT_LINE('   Promoci n    ->  (VL_PROMOCION) : '||VL_PROMOCION||CHR(10)||CHR(10));

                -- Descuento por promocion de inscripcion (M3).
                    -- DBMS_OUTPUT.PUT_LINE('-> Descuento por promocion de inscripcion (M3) para el matriculado('||GB_COMMON.F_GET_ID(X.STCR_PIDM)||').'||CHR(10));       

                    VL_PROMOCION := 0;
                    VL_SEC_FACE := 0;

                    --------------------- Se recupara el numbero de solicitud para hacer match contra el SP ------------------
                    vl_solicitud:=0;
                    Begin

                        select distinct SOLICITUD
                            Into vl_solicitud
                        from SZTACTU a
                        where 1=1
                        and pidm = x.pidm
                        and programa = x.programa 
                        and ESTATUS = 3
                        And evento = 7

                        -- OMS 12/Mayo/2025
                        -- Soluciona el problema registros DUPLICADOS con decision 35 para el mismo programa
                        and TRUNC (fecha_registro) = (SELECT MAX (TRUNC (b.Fecha_Registro))
                                                        FROM sztactu b
                                                       WHERE b.pidm     = a.pidm
                                                         AND b.programa = a.programa
                                                         AND b.estatus  = 3
                                                         AND b.evento   = 7)
                        ;
                    Exception
                        When Others then 
                            vl_solicitud:=0;
                    End;

                     DBMS_OUTPUT.PUT_LINE(' Recupera el numero de solicitud de SZTACTU '||vl_solicitud);              

                    VL_PROMOCION :=0;
                    VL_SEC_FACE :=0;

                    If vl_solicitud > 0 then 

                            BEGIN                                                                         
                               -- Nueva Version para obtener el descuento 13/Nov/2023 OMS
                               SELECT DISTINCT NVL (TZFACCE_AMOUNT,0), FACE.TZFACCE_SEC_PIDM
                                 INTO VL_PROMOCION, VL_SEC_FACE
                                 FROM TZFACCE FACE 
                                WHERE 1 = 1
                                  AND FACE.TZFACCE_PIDM = X.pidm                  
                                  AND SUBSTR(FACE.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                                  AND FACE.TZFACCE_FLAG  = 0
                                  AND FACE.TZFACCE_STUDY = vl_solicitud
                                  AND FACE.TZFACCE_EFFECTIVE_DATE = (SELECT MIN(FACE1.TZFACCE_EFFECTIVE_DATE)
                                                                       FROM TZFACCE FACE1
                                                                      WHERE 1 = 1
                                                                        AND FACE1.TZFACCE_PIDM = X.pidm
                                                                        AND SUBSTR (FACE1.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                                                                        AND FACE1.TZFACCE_FLAG  = 0
                                                                        AND FACE1.TZFACCE_STUDY = FACE.TZFACCE_STUDY)

                                    -- OMS 29/MAYO/2025 : No toma en cuenta fechas pasadas (60 Dias de Tolerancia)
                                    AND TRUNC (FACE.TZFACCE_EFFECTIVE_DATE) >= TRUNC (sysdate - 60);

                                -- DBMS_OUTPUT.PUT_LINE('   (Qry) Descuento por promocion de inscripcion (M3)(VL_PROMOCION): '||TO_CHAR(VL_PROMOCION,'$999,999.00')||CHR(10)||CHR(10));    

                            EXCEPTION    
                                WHEN OTHERS THEN
                                    VL_PROMOCION := 0;
                                    VL_SEC_FACE :=0;
                                       -- DBMS_OUTPUT.PUT_LINE('   (Exc.) Descuento por promocion de inscripcion (M3)(VL_PROMOCION): '||TO_CHAR(VL_PROMOCION,'$999,999.00')||CHR(10)||CHR(10));
                            END;      

                        -- Si hay descuento por promoci n de inscripcion, entonces...                                 
                            IF VL_PROMOCION > 0 THEN 

                                -- DBMS_OUTPUT.PUT_LINE('-> Si hay descuento por promoci n de inscripcion, entonces...'||CHR(10));

                            -- Actualizaci n de promoci n consumida a 1.                        
                                BEGIN 

                                    -- DBMS_OUTPUT.PUT_LINE('Consume el registro de promoci n de inscripcion en los accesorios escalonados(TZFACCE)'||CHR(10));

                                    UPDATE TZFACCE FACE
                                       SET FACE.TZFACCE_FLAG = 1
                                     WHERE 1 = 1
                                       AND FACE.TZFACCE_PIDM     = X.pidm
                                       AND FACE.TZFACCE_SEC_PIDM = VL_SEC_FACE
                                       AND SUBSTR(FACE.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                                       AND FACE.TZFACCE_FLAG      = 0
                                       AND FACE.TZFACCE_STUDY     = vl_solicitud;

                                    -- DBMS_OUTPUT.PUT_LINE('     (Qry.) Actualiza el registro de promoci n de inscripcion en los accesorios escalonados(TZFACCE) a consumido(1)'||CHR(10)||CHR(10));       

                                EXCEPTION   
                                    WHEN OTHERS THEN 
                                        NULL;
                                            DBMS_OUTPUT.PUT_LINE('     (Exc.) No se actualiza el registro de promoci n a consumido.'||CHR(10)||CHR(10));
                                END;

                            END IF; 


                    ----------------------------------------- Primner Pago --------------------------------------------


                            VL_PRIM_PAGO := 0;
                            VL_SEC_PAGO := 0;

                            DBMS_OUTPUT.PUT_LINE(' Datos para recuperar el  monto de primer Cargo '||X.pidm  ||'*'||X.sp);  

                            BEGIN                                                                         
                               -- Nueva Version para obtener el descuento 13/Nov/2023 OMS
                               SELECT DISTINCT NVL (TZFACCE_AMOUNT,0), FACE.TZFACCE_SEC_PIDM
                                 INTO VL_PRIM_PAGO, VL_SEC_PAGO
                                 FROM TZFACCE FACE 
                                WHERE 1 = 1
                                  AND FACE.TZFACCE_PIDM = X.pidm                  
                                  AND FACE.TZFACCE_DETAIL_CODE = 'PRIM'
                                  AND FACE.TZFACCE_FLAG  = 0
                                  AND FACE.TZFACCE_STUDY = vl_solicitud
                                  AND FACE.TZFACCE_EFFECTIVE_DATE = (SELECT MIN(FACE1.TZFACCE_EFFECTIVE_DATE)
                                                                       FROM TZFACCE FACE1
                                                                      WHERE 1 = 1
                                                                        AND FACE1.TZFACCE_PIDM = X.pidm
                                                                        AND FACE1.TZFACCE_DETAIL_CODE = 'PRIM'
                                                                        AND FACE1.TZFACCE_FLAG  = 0
                                                                        AND FACE1.TZFACCE_STUDY = FACE.TZFACCE_STUDY)

                                    -- OMS 29/MAYO/2025 : No toma en cuenta fechas pasadas (60 Días de Tolerancia)
                                    AND TRUNC (FACE.TZFACCE_EFFECTIVE_DATE) >= TRUNC (sysdate - 60);

                                 DBMS_OUTPUT.PUT_LINE(' Recupera el monto de primer Cargo '||VL_PRIM_PAGO ||'*'||VL_SEC_PAGO);    

                            EXCEPTION    
                                WHEN OTHERS THEN
                                    VL_PRIM_PAGO := 0;
                                    VL_SEC_PAGO :=0;
                                       -- DBMS_OUTPUT.PUT_LINE('   (Exc.) Descuento por promocion de inscripcion (M3)(VL_PROMOCION): '||TO_CHAR(VL_PROMOCION,'$999,999.00')||CHR(10)||CHR(10));
                            END;      

                        -- Si hay descuento por promoci n de inscripcion, entonces...                                 
                            IF VL_PRIM_PAGO > 0 THEN 
                                -- DBMS_OUTPUT.PUT_LINE('-> Si hay descuento por promoci n de inscripcion, entonces...'||CHR(10));
                                 -- Actualizaci n de promoci n consumida a 1.                        
                                BEGIN 
                                    -- DBMS_OUTPUT.PUT_LINE('Consume el registro de promoci n de inscripcion en los accesorios escalonados(TZFACCE)'||CHR(10));
                                    UPDATE TZFACCE FACE
                                       SET FACE.TZFACCE_FLAG = 1
                                     WHERE 1 = 1
                                       AND FACE.TZFACCE_PIDM     = X.pidm
                                       AND FACE.TZFACCE_SEC_PIDM = VL_SEC_PAGO
                                       AND FACE.TZFACCE_DETAIL_CODE = 'PRIM'
                                       AND FACE.TZFACCE_FLAG      = 0
                                       AND FACE.TZFACCE_STUDY     = X.sp;
                                    -- DBMS_OUTPUT.PUT_LINE('     (Qry.) Actualiza el registro de promoci n de inscripcion en los accesorios escalonados(TZFACCE) a consumido(1)'||CHR(10)||CHR(10));       
                                EXCEPTION   
                                    WHEN OTHERS THEN 
                                        NULL;
                                          --  DBMS_OUTPUT.PUT_LINE('     (Exc.) No se actualiza el registro de promoci n a consumido.'||CHR(10)||CHR(10));
                                END;
                            END IF; 
                    End if;

                -- Si hay parcialidad, entonces... 
                    IF VL_PARCIALIDAD IS NOT NULL THEN
                       VL_ERROR:='EXITO';
                       If VL_PRIM_PAGO > 0 then 
                           VL_PARCIALIDAD := VL_PRIM_PAGO;
                           DBMS_OUTPUT.PUT_LINE(' Entra en el IF para ajustar el costo '||VL_PRIM_PAGO ||'*'||VL_PARCIALIDAD);    
                       Else
                           VL_PARCIALIDAD := VL_PARCIALIDAD - VL_PROMOCION;
                           DBMS_OUTPUT.PUT_LINE(' Entra en el ELSE para ajustar el costo '||VL_PROMOCION ||'*'||VL_PARCIALIDAD);  
                       End if;

                        -- DBMS_OUTPUT.PUT_LINE('-> Si hay parcialidad, entonces... '||CHR(10));
                    -- Setea la variable del No. de reg. del Edo. de Cta. a 0.
                        -- DBMS_OUTPUT.PUT_LINE('   Setea la variable del No. de reg. del Edo. de Cta. a 0.'||CHR(10));
                           VL_SECUENCIA := 0;
                        -- DBMS_OUTPUT.PUT_LINE('   No. de reg. del Edo. de Cta. ->  (VL_SECUENCIA): '||VL_SECUENCIA||CHR(10)||CHR(10));
                        -- N mero siguiente de registro en el Edo. de Cta. (TBRACCD).                        
                        BEGIN
                            -- DBMS_OUTPUT.PUT_LINE('-> Consulta del No. m ximo de registro en el Edo. de Cta. del matriculado.'||CHR(10));
                            SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) + 1
                              INTO VL_SECUENCIA
                              FROM TBRACCD
                             WHERE 1 = 1
                               AND TBRACCD_PIDM = X.pidm;
                            -- DBMS_OUTPUT.PUT_LINE('   (Qry.)  No. m ximo de registro del Edo. de Cta. del matriculado (VL_SECUENCIA)?: '||VL_SECUENCIA||CHR(10)||CHR(10));
                        EXCEPTION
                            WHEN OTHERS THEN
                                VL_SECUENCIA := 1;
                                       DBMS_OUTPUT.PUT_LINE('   (Exc.)  No. m ximo de registro del Edo. de Cta. del matriculado (VL_SECUENCIA)?: '||VL_SECUENCIA||CHR(10)||CHR(10));
                        END;

                    -- Si el No. de folio / orden es nulo, entonces... 
                        IF p_VPDI_CODE IS NULL THEN
                            -- DBMS_OUTPUT.PUT_LINE('-> Si el No. de folio / orden(X.FOLIO) es Nulo o vac o, entonces...'||CHR(10));                            
                            BEGIN 
                                -- DBMS_OUTPUT.PUT_LINE('Se obtiene el nuevo No. de folio / orden para ser registrado la tabla de ordenes(TZTORDR).'||CHR(10));
                                DBMS_OUTPUT.PUT_LINE('OMS Linea 2,469 --> p_VPDI_CODE: ' || p_VPDI_CODE);
                                SELECT TZTORDR_CONTADOR
                                  INTO VL_SECUEN
                                  FROM TZTORDR
                                 WHERE 1 = 1
                                   AND TZTORDR_CAMPUS = X.campus
                                   AND TZTORDR_NIVEL  = X.nivel
                                   AND TZTORDR_PIDM   = X.pidm
                                   AND TRUNC (TZTORDR_FECHA_INICIO) = p_FECHA
                                   AND TZTORDR_ESTATUS = 'S'; 
                            -- DBMS_OUTPUT.PUT_LINE('   (Qry.)  No. de folio / orden nuevo(VL_SECUEN)?: '||VL_SECUEN||CHR(10)||CHR(10));       
                            EXCEPTION
                                WHEN OTHERS THEN 
                                    VL_SECUEN := NULL;
                                           DBMS_OUTPUT.PUT_LINE('   (Exc.)  No. de folio / orden nuevo(VL_SECUEN)?: '||VL_SECUEN||CHR(10)||CHR(10));
                            END;

                        -- Si el No. de folio / orden est  vac o o nulo, entonces...                                     
                            IF VL_SECUEN IS NULL THEN 
                                DBMS_OUTPUT.PUT_LINE('Si el No. de folio / orden est  vac o o nulo, entonces...'||CHR(10));
                                BEGIN
                                    -- DBMS_OUTPUT.PUT_LINE('Se obtiene el nuevo No. de folio / orden m s 1. '||CHR(10));
                                    SELECT MAX(TZTORDR_CONTADOR) + 1
                                      INTO VL_SECUEN
                                      FROM TZTORDR
                                     WHERE 1 = 1;
                                     DBMS_OUTPUT.PUT_LINE('  (Qry.) Nuevo No. de folio / orden: '||VL_SECUEN||CHR(10)||CHR(10));     
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        VL_SECUEN := NULL;
                                            -- DBMS_OUTPUT.PUT_LINE('  (Exc.) Nuevo No. de folio / orden: '||VL_SECUEN||CHR(10)||CHR(10));
                                END;

                            -- Inserta registro del nuevo No. de orden en la tabla de  folios / ordenes (TZTORDR).                                                    
                                BEGIN
                                    DBMS_OUTPUT.PUT_LINE('Inserta registro del nuevo No. de orden en la tabla de  folios / ordenes (TZTORDR). '||CHR(10));
                                    INSERT INTO TZTORDR(TZTORDR_CAMPUS
                                                       ,TZTORDR_NIVEL
                                                       ,TZTORDR_CONTADOR
                                                       ,TZTORDR_PROGRAMA
                                                       ,TZTORDR_PIDM
                                                       ,TZTORDR_ID
                                                       ,TZTORDR_ESTATUS
                                                       ,TZTORDR_ACTIVITY_DATE
                                                       ,TZTORDR_USER
                                                       ,TZTORDR_DATA_ORIGIN
                                                       ,TZTORDR_NO_REGLA
                                                       ,TZTORDR_FECHA_INICIO
                                                       ,TZTORDR_RATE
                                                       ,TZTORDR_JORNADA
                                                       ,TZTORDR_DSI
                                                       ,TZTORDR_TERM_CODE)
                                                 VALUES(X.campus
                                                       ,X.nivel
                                                       ,VL_SECUEN
                                                       ,X.programa
                                                       ,X.pidm
                                                       ,x.matricula
                                                       ,'S'
                                                       ,SYSDATE
                                                       ,USER
                                                       ,'TZTFEDCA'
                                                       ,NULL
                                                       ,p_FECHA
                                                       ,X.RATE
                                                       ,Vm_Jornada
                                                       ,VL_MONTO_DSI
                                                       ,p_PTRM_CODE);
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        VL_ERROR := 'Error al calcular el folio /No. de orden... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10);
                                        DBMS_OUTPUT.PUT_LINE(VL_ERROR||CHR(10)||CHR(10));
                                END;
                            END IF;
                        END IF;

                                DBMS_OUTPUT.PUT_LINE('OMS Linea 2,579 --> vl_Error: ' || VL_ERROR||CHR(10)||CHR(10));

                    -- Si no hay error, entonces... 
                        IF VL_ERROR  = 'EXITO' THEN
                            DBMS_OUTPUT.PUT_LINE('Si no hay error en el proceso, entonces... '||CHR(10));
                        -- Calcula el Cod. de Detalle, Descripci n del detalle y la moneda.
                            BEGIN
                                DBMS_OUTPUT.PUT_LINE('Calcula el Cod. de detalle, concepto y la moneda. '||CHR(10));
                                SELECT TBBDETC_DETAIL_CODE
                                      ,TBBDETC_DESC
                                      ,TVRDCTX_CURR_CODE
                                  INTO VL_CODIGO
                                      ,VL_DESCRIP
                                      ,VL_MONEDA
                                  FROM TBBDETC
                                      ,TVRDCTX
                                 WHERE 1 = 1
                                   AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE                              
                                   AND TBBDETC_DETAIL_CODE = SUBSTR(x.matricula,1,2)||CASE
                                                                                        WHEN SUBSTR(X.programa,4,2) = 'DI' THEN
                                                                                            'NR'
                                                                                        WHEN SUBSTR(X.programa,4,2) = 'CU' THEN
                                                                                            'NT' -- 'NQ'    --   OMS 15/OCT/2024
                                                                                      END;    
                                /*
                                DBMS_OUTPUT.PUT_LINE('Resultado del Cod. de detalle, concepto y moneda: '||CHR(10)
                                                   ||'Cod. de detalle   (VL_CODIGO)     : '||VL_CODIGO||CHR(10)
                                                   ||'Conceto           (VL_DESCRIP)    : '||VL_DESCRIP||CHR(10)
                                                   ||'Moneda            (VL_MONEDA)     : '||VL_MONEDA ||CHR(10)||CHR(10));
                                */
                            EXCEPTION
                                WHEN OTHERS THEN
                                    VL_ERROR := '-> (Exc.) Error al calcular el Cod. de Detalle, Descripci n del detalle y/o la moneda... Favor de revisar...'||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM;
                                    DBMS_OUTPUT.PUT_LINE(VL_ERROR||CHR(10));
                            END;

                        -- Concatenaci n de la descripci n: COL. + "Nombre del programa" para cargo en el Edo. de Cta.                             
                            BEGIN
                                -- DBMS_OUTPUT.PUT_LINE('Concatenaci n de la descripci n: COL. + Nombre del programa para cargo en el Edo. de Cta.'||CHR(10));
                                SELECT TBBDETC_DESC
                                    -- OMS 23/Nov/2023
                                    -- Se elimina el cambio de agregar el nombre del diplomado en la descripcion de la cartera
                                    -- SUBSTR(TBBDETC_DESC,1,3)||'. '||REGEXP_SUBSTR(TBBDETC_DESC, '[^ ]+', 1,2)||' '||X.SORL_PROGRAMA
                                  INTO VL_CARGO_DESC
                                  FROM TBBDETC
                                 WHERE 1 = 1
                                   AND TBBDETC_DETAIL_CODE = VL_CODIGO
                                   AND TBBDETC_DETAIL_CODE = SUBSTR(x.matricula,1,2)||CASE
                                                                                        WHEN SUBSTR(X.programa,4,2) = 'DI' THEN
                                                                                            'NR'
                                                                                        WHEN SUBSTR(X.programa,4,2) = 'CU' THEN
                                                                                            'NT' -- 'NQ'   --  OMS 15/OCT/2024
                                                                                      END;

                                DBMS_OUTPUT.PUT_LINE('  (Qry.) Nuevo nombre de cargo: '||VL_CARGO_DESC||CHR(10));                                        
                            EXCEPTION
                                WHEN OTHERS THEN
                                    VL_CARGO_DESC := 'Sin Descripcion el Codigo de Detalle';
                                    DBMS_OUTPUT.PUT_LINE('   (Exc.) Nuevo nombre del cargo: '||VL_CARGO_DESC||CHR(10)); 
                            END;                                                                                                                                                               

                        -- Seteo de variables para el periodo y la parte periodo a vac o / nulo. 
                            -- DBMS_OUTPUT.PUT_LINE('Seteo de variables para el periodo y la parte periodo a vac o / nulo. '||CHR(10));
                            VL_PERIODO := NULL;
                            -- DBMS_OUTPUT.PUT_LINE('Valor -> Variable periodo (VL_PERIODO): '||VL_PERIODO||CHR(10));
                            VL_PARTE   := NULL;   
                              -- DBMS_OUTPUT.PUT_LINE('Valor -> Variable parte periodo (VL_PARTE): '||VL_PARTE||CHR(10)||CHR(10));     
                              -- Obtenci n del peroido y parte periodo a partir de la fecha de inicio del alumno.                                                            
                            BEGIN 
                            -- DBMS_OUTPUT.PUT_LINE('Obtenci n del peroido y parte periodo a partir de la fecha de inicio del alumno. '||CHR(10));
                               -- Asigna valores a las variables Periodo y Parte de Periodo
                               Vl_Periodo := P_Periodo;
                               Vl_Parte   := p_PTRM_CODE;
                                -- DBMS_OUTPUT.PUT_LINE('  (Qry.) Periodo: '||VL_PERIODO||CHR(10)
                                --                   ||'         Parte periodo: '||VL_PARTE||CHR(10)||CHR(10));       
                            EXCEPTION        
                                WHEN OTHERS THEN                   
                                    VL_PERIODO := NULL; 
                                    VL_PARTE   := NULL;
                                        -- DBMS_OUTPUT.PUT_LINE('  (Exc.) Periodo: '||VL_PERIODO||CHR(10)
                                        --                    ||'         Parte periodo: '||VL_PARTE||CHR(10)||CHR(10)); 
                            END;                           

                            vl_pagos:=0;
                            If x.num_pagos = '01' then 
                                vl_pagos:=0;
                                Begin
                                    Select COUNT(1)
                                        Into vl_pagos 
                                   from tbraccd
                                   where 1=1
                                   and tbraccd_pidm = x.pidm 
                                   and tbraccd_detail_code = VL_CODIGO
                                   And TBRACCD_STSP_KEY_SEQUENCE = x.sp;
                                Exception
                                    When Others then
                                     vl_pagos:=0;
                                End;

                            End if;


                        -- Si hay periodo y parte periodo, entonces...                                                            
                            IF  VL_PERIODO IS NOT NULL AND  VL_PARTE IS NOT NULL And vl_pagos = 0 THEN    
                                --DBMS_OUTPUT.PUT_LINE('Si hay periodo y parte periodo, entonces... '||CHR(10));         
                                BEGIN
                                        DBMS_OUTPUT.PUT_LINE('Linea 2,686 VL_SECUEN:    ' || VL_SECUEN);
                                        DBMS_OUTPUT.PUT_LINE('Linea 2,687 x.STCR_ORDEN: ' || p_VPDI_CODE);    
                                    if p_VPDI_CODE is not null then 
                                        VL_SECUEN := p_VPDI_CODE; 
                                    end if;

                                EXCEPTION WHEN OTHERS THEN VL_SECUEN := NULL;
                                END;

                            -- Inserta el cargo del(los) programa(s) diplomado(s) en el Edo. de Cta. del alumno.                                                                 
                                BEGIN
                                    DBMS_OUTPUT.PUT_LINE('Inserta el cargo del(los) programa(s) diplomado(s) en el Edo. de Cta. del alumno. '||CHR(10));
                                    INSERT INTO TBRACCD 
                                         VALUES(X.pidm
                                               ,VL_SECUENCIA
                                               ,VL_PERIODO
                                               ,VL_CODIGO
                                               ,USER
                                               ,SYSDATE
                                               ,VL_PARCIALIDAD
                                               ,VL_PARCIALIDAD
                                               ,p_FECHA
                                               ,NULL
                                               ,NULL
                                               ,VL_CARGO_DESC --  || ' --> p_fecha = ' || p_fecha
                                               ,VL_SECUEN
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,'T'
                                               ,'Y'
                                               ,SYSDATE
                                               ,0
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,p_FECHA
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,VL_MONEDA
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,p_FECHA
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,'TZFEDCA (PARC)'
                                               ,'TZFEDCA (PARC)'
                                               ,NULL
                                               ,NULL
                                               ,X.sp
                                               ,VL_PARTE
                                               ,NULL
                                               ,NULL
                                               ,USER
                                               ,NULL);                                            

                                EXCEPTION
                                    WHEN OTHERS THEN
                                        VL_ERROR := '(Exc.) Error al insertar cargos en el Edo. de Cta... Favor de revisar...'||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10);                                         
                                        DBMS_OUTPUT.PUT_LINE(VL_ERROR||CHR(10));
                                END;                                         

                            -- Si no hay errores en el proceso, entonces...                                                    
                                IF VL_ERROR = 'EXITO' THEN 
                                    -- DBMS_OUTPUT.PUT_LINE('Si no hay errores en el proceso, entonces... '||CHR(10));
                                    VL_ERROR := 'EXITO' ;
                                    --COMMIT;
                                    -- DBMS_OUTPUT.PUT_LINE('Confirma las transacciones del proceso(VL_ERRROR):  '||VL_ERROR||CHR(10)||CHR(10));                                                              
                                ELSE
                                    DBMS_OUTPUT.PUT_LINE('Si hay errores en el proceso, entonces... '||CHR(10));
                                    null;
                                    -- DBMS_OUTPUT.PUT_LINE('Reversa(ROLLBACK) las operaciones / transacciones del proceso(VL_ERRROR):  '||VL_ERROR||CHR(10)||CHR(10));
                                END IF;

                            END IF;

                        END IF;
                    Else
                        VL_ERROR:='No Existe Regla de Cobro ';                    
                    END IF;
                    Vm_Contador := Vm_Contador + 1; -- Contador de Iteraciones en el LOOP OMS 10/Nov/2023

              END LOOP;

    RETURN(VL_ERROR);
    --DBMS_OUTPUT.PUT_LINE(VL_ERROR);

END F_DIPLOMADO_CARGO_TRG;




-- Nueva funcion para obtener la parcialidad (cuota de colegiatura) cuando sean DIPLOMADOS --> lLAMADA DESDE EL TRIGGER DE HORARIOS
-- OMS Junio/07
FUNCTION F_PARCIALIDAD_ECONTINUA_TGR (P_PIDM NUMBER, P_FECHA DATE, P_PROGRAMA IN VARCHAR2 DEFAULT NULL,
                                  P_STUDY_PATH IN NUMBER   DEFAULT NULL,
                                  P_JORNADA    IN VARCHAR2 DEFAULT NULL,

                                  P_SFRSTCR_TERM_CODE    IN VARCHAR2, 
                                  P_SFRSTCR_CRN          IN VARCHAR2, 
                                  P_SFRSTCR_PTRM_CODE    IN VARCHAR2, 
                                  P_SFRSTCR_RSTS_CODE    IN VARCHAR2, 
                                  P_SFRSTCR_RESERVED_KEY IN VARCHAR2, 
                                  P_SFRSTCR_DATA_ORIGIN  IN VARCHAR2, 
                                  P_SFRSTCR_USER_ID      IN VARCHAR2,
                                  P_SFRSTCR_VPDI_CODE    IN VARCHAR2
                                  ) RETURN NUMBER IS

-- Variables
   VL_PARCIALIDAD NUMBER;

BEGIN  

  DBMS_OUTPUT.PUT_LINE('PARCIALIDAD P_STUDY_PATH = ' || P_STUDY_PATH);
  DBMS_OUTPUT.PUT_LINE('PARCIALIDAD P_JORNADA    = ' || P_JORNADA);
  DBMS_OUTPUT.PUT_LINE('PARCIALIDAD P_PROGRAMA   = ' || P_PROGRAMA);
  DBMS_OUTPUT.PUT_LINE('PARCIALIDAD P_FECHA      = ' || P_FECHA);
  DBMS_OUTPUT.PUT_LINE('P_SFRSTCR_TERM_CODE      = ' || P_SFRSTCR_TERM_CODE); 
  DBMS_OUTPUT.PUT_LINE('P_SFRSTCR_CRN            = ' || P_SFRSTCR_CRN); 
  DBMS_OUTPUT.PUT_LINE('P_SFRSTCR_PTRM_CODE      = ' || P_SFRSTCR_PTRM_CODE); 
  DBMS_OUTPUT.PUT_LINE('P_SFRSTCR_RSTS_CODE      = ' || P_SFRSTCR_RSTS_CODE);
  DBMS_OUTPUT.PUT_LINE('P_SFRSTCR_RESERVED_KEY   = ' || P_SFRSTCR_RESERVED_KEY);
  DBMS_OUTPUT.PUT_LINE('P_SFRSTCR_DATA_ORIGIN    = ' || P_SFRSTCR_DATA_ORIGIN);
  DBMS_OUTPUT.PUT_LINE('P_SFRSTCR_USER_ID        = ' || P_SFRSTCR_USER_ID);
  DBMS_OUTPUT.PUT_LINE('P_SFRSTCR_VPDI_CODE      = ' || P_SFRSTCR_VPDI_CODE);

--   INSERT INTO TMP_BITACORA_PKG Values (sysdate, 'PARCIAL', '1=' || P_PIDM || ', 2=' || P_FECHA || ', 3=' || P_PROGRAMA || 
--                                        ', 4= ' || P_STUDY_PATH  || ', 5= ' || P_JORNADA || ', 6= '   || P_SFRSTCR_TERM_CODE || ', 7|= ' ||
--                                        P_SFRSTCR_CRN || ', 8= ' || P_SFRSTCR_PTRM_CODE  || ', 9= '   || P_SFRSTCR_RSTS_CODE || ', 10= ' ||
--                                        P_SFRSTCR_RESERVED_KEY   || ', 11= ' || P_SFRSTCR_DATA_ORIGIN || ', 12= ' || P_SFRSTCR_USER_ID   || ', 13= ' ||
--                                        P_SFRSTCR_VPDI_CODE);

  BEGIN
        SELECT DISTINCT
               ROUND(((SELECT  A.SFRRGFE_MAX_CHARGE
               FROM SFRRGFE A , TBBDETC
               WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
               AND  A.SFRRGFE_TERM_CODE= PERIODO
               AND A.SFRRGFE_TYPE = 'STUDENT'
               AND A.SFRRGFE_ENTRY_TYPE = 'R'
               AND A.SFRRGFE_LEVL_CODE = NIVEL
               AND A.SFRRGFE_CAMP_CODE = CAMPUS
               AND A.SFRRGFE_ATTS_CODE = P_JORNADA
               AND A.SFRRGFE_RATE_CODE = RATE
               AND NVL(A.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
               AND NVL(A.SFRRGFE_PROGRAM,'SIN') = PRO_SFR
               AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND NVL(A1.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
                                      AND NVL(A1.SFRRGFE_PROGRAM,'SIN') = PRO_SFR)) - NVL(MONTO_DSI,0) - NVL(((SELECT A.SFRRGFE_MAX_CHARGE
               FROM SFRRGFE A , TBBDETC
               WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
               AND  A.SFRRGFE_TERM_CODE= PERIODO
               AND A.SFRRGFE_TYPE = 'STUDENT'
               AND A.SFRRGFE_ENTRY_TYPE = 'R'
               AND A.SFRRGFE_LEVL_CODE = NIVEL
               AND A.SFRRGFE_CAMP_CODE = CAMPUS
               AND A.SFRRGFE_ATTS_CODE = P_JORNADA
               AND A.SFRRGFE_RATE_CODE = RATE
               AND NVL(A.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
               AND NVL(A.SFRRGFE_PROGRAM,'SIN') = PRO_SFR
               AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND NVL(A1.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
                                      AND NVL(A1.SFRRGFE_PROGRAM,'SIN') = PRO_SFR))*DESCUENTO/100),0))/NUM_PAG)PARCIALIDAD
        INTO VL_PARCIALIDAD
        FROM(SELECT DISTINCT
                SORLCUR_PIDM PIDM,
                SORLCUR_KEY_SEQNO STUDY,
                SORLCUR_PROGRAM PROGRAMA,
                SORLCUR_RATE_CODE RATE,
                SORLCUR_CAMP_CODE CAMPUS,
                SPRIDEN_ID,
                SORLCUR_START_DATE,
                SORLCUR_LEVL_CODE NIVEL,
                SFRSTCR_TERM_CODE PERIODO,
                SFRSTCR_PTRM_CODE PPARTE,
                SSBSECT_PTRM_START_DATE FECHA,
                NVL((SELECT NVL(SFRRGFE_PROGRAM,'SIN')
                FROM SFRRGFE A , TBBDETC
                WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
                AND  A.SFRRGFE_TERM_CODE= F.SFRSTCR_TERM_CODE
                AND A.SFRRGFE_TYPE = 'STUDENT'
                AND A.SFRRGFE_ENTRY_TYPE = 'R'
                AND A.SFRRGFE_LEVL_CODE = A.SORLCUR_LEVL_CODE
                AND A.SFRRGFE_CAMP_CODE = A.SORLCUR_CAMP_CODE
                AND A.SFRRGFE_ATTS_CODE = (SELECT MAX (T.SGRSATT_ATTS_CODE)
                                            FROM SGRSATT T
                                            WHERE T.SGRSATT_PIDM = A.SORLCUR_PIDM
                                            AND T.SGRSATT_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                            AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
                                            AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                            AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                                               FROM SGRSATT TT
                                                                               WHERE  TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                                               AND  TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                                               AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                                               AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]'))
                                            AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                                                           FROM SGRSATT T1
                                                                           WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                                                           AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                                           AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                                           AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                                           AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')))
                AND A.SFRRGFE_RATE_CODE = A.SORLCUR_RATE_CODE
                AND nvl(A.SFRRGFE_DEPT_CODE,0) = nvl((SELECT DISTINCT NVL(SORLCUR_SITE_CODE,0)
                                          FROM SORLCUR CUR
                                          WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                          AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                          ANd cur.sorlcur_program = P_PROGRAMA
                                          AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                                   FROM SORLCUR CUR2
                                                                   WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                                   And CUR2.sorlcur_program = CUR.sorlcur_program
                                                                   AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE)),'0')
                AND A.SFRRGFE_PROGRAM = A.SORLCUR_PROGRAM
                AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND nvl(A1.SFRRGFE_DEPT_CODE,0) = nvl((SELECT DISTINCT NVL(SORLCUR_SITE_CODE,'0')
                                                                  FROM SORLCUR CUR
                                                                  WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                  AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                                                  ANd cur.sorlcur_program = P_PROGRAMA
                                                                  AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                                                           FROM SORLCUR CUR2
                                                                                           WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                                                           And CUR2.sorlcur_program = CUR.sorlcur_program
                                                                                           AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE)),'0')
                                      AND A1.SFRRGFE_PROGRAM = A.SORLCUR_PROGRAM)),'SIN')PRO_SFR,
                (SELECT DISTINCT NVL(SORLCUR_SITE_CODE,0)
                              FROM SORLCUR CUR
                              WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                              AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                              ANd cur.sorlcur_program = P_PROGRAMA
                              AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                       FROM SORLCUR CUR2
                                                       WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                       And CUR2.sorlcur_program = CUR.sorlcur_program
                                                       AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO,

-- Version TZTDMTO (Descuento)
                (SELECT DISTINCT TZTDMTO_PORCENTAJE_ECONTINUA
                FROM TZTDMTO A
                WHERE A.TZTDMTO_PIDM   = A.SORLCUR_PIDM
                AND   A.TZTDMTO_CAMP_CODE = A.SORLCUR_CAMP_CODE
                AND  A.TZTDMTO_NIVEL  = A.SORLCUR_LEVL_CODE
                AND A.TZTDMTO_PROGRAMA =  A.SORLCUR_PROGRAM
                AND A.TZTDMTO_IND = 1
                AND A.TZTDMTO_STUDY_PATH = A.SORLCUR_KEY_SEQNO
                AND ( A.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                     OR A.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                               FROM TZTDMTO TZT
                                               WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                               AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                               AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                               AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                               AND TZT.TZTDMTO_IND = 1
                                               AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                               AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE))
                AND A.TZTDMTO_ACTIVITY_DATE = (SELECT MAX (A1.TZTDMTO_ACTIVITY_DATE)
                                                FROM TZTDMTO A1
                                                WHERE A1.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                AND   A1.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                AND  A1.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                AND A1.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                AND A1.TZTDMTO_IND = 1
                                                AND A1.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                AND ( A1.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                                                      OR A1.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                                 FROM TZTDMTO TZT
                                                                                 WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                                 AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                                 AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                                 AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                                 AND TZT.TZTDMTO_IND = 1
                                                                                 AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                                 AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE)))
                 AND A.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE
                 AND ROWNUM = 1)DESCUENTO,
                (SELECT DISTINCT TZTDMTO_MONTO
                FROM TZTDMTO A
                WHERE A.TZTDMTO_PIDM   = A.SORLCUR_PIDM
                AND   A.TZTDMTO_CAMP_CODE = A.SORLCUR_CAMP_CODE
                AND  A.TZTDMTO_NIVEL  = A.SORLCUR_LEVL_CODE
                AND A.TZTDMTO_PROGRAMA =  A.SORLCUR_PROGRAM
                AND A.TZTDMTO_IND = 1
                AND A.TZTDMTO_STUDY_PATH = A.SORLCUR_KEY_SEQNO
                AND ( A.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                     OR A.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                               FROM TZTDMTO TZT
                                               WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                               AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                               AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                               AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                               AND TZT.TZTDMTO_IND = 1
                                               AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                               AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE))
                AND A.TZTDMTO_ACTIVITY_DATE = (SELECT MAX (A1.TZTDMTO_ACTIVITY_DATE)
                                                FROM TZTDMTO A1
                                                WHERE A1.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                AND   A1.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                AND  A1.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                AND A1.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                AND A1.TZTDMTO_IND = 1
                                                AND A1.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                AND ( A1.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                                                      OR A1.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                                 FROM TZTDMTO TZT
                                                                                 WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                                 AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                                 AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                                 AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                                 AND TZT.TZTDMTO_IND = 1
                                                                                 AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                                 AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE)))
                 AND A.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE
                 AND ROWNUM = 1)MONTO_DSI,
                CASE
                SUBSTR (SORLCUR_RATE_CODE, 1, 1)
                WHEN  ('P') THEN SUBSTR (SORLCUR_RATE_CODE, 2, 2)
                WHEN  ('C') THEN SUBSTR (SORLCUR_RATE_CODE, 3, 1)-- Se agrega
                WHEN  ('J') THEN SUBSTR (SORLCUR_RATE_CODE, 3, 1)
                END NUM_PAG,
                SFRSTCR_VPDI_CODE FOLIO
        FROM SORLCUR A, SPRIDEN D, SSBSECT G, SZTDTEC E,
             (SELECT P_PIDM                 SFRSTCR_PIDM, 
                     P_STUDY_PATH           SFRSTCR_STSP_KEY_SEQUENCE,       
                     P_SFRSTCR_TERM_CODE    SFRSTCR_TERM_CODE, 
                     P_SFRSTCR_CRN          SFRSTCR_CRN, 
                     P_SFRSTCR_PTRM_CODE    SFRSTCR_PTRM_CODE, 
                     P_SFRSTCR_RSTS_CODE    SFRSTCR_RSTS_CODE, 
                     P_SFRSTCR_RESERVED_KEY SFRSTCR_RESERVED_KEY, 
                     P_SFRSTCR_DATA_ORIGIN  SFRSTCR_DATA_ORIGIN, 
                     P_SFRSTCR_USER_ID      SFRSTCR_USER_ID,
                     P_SFRSTCR_VPDI_CODE    SFRSTCR_VPDI_CODE
                FROM DUAL
             ) F
        WHERE A.SORLCUR_PIDM = D.SPRIDEN_PIDM
        AND A.SORLCUR_LMOD_CODE = 'LEARNER'
        AND A.SORLCUR_ROLL_IND  = 'Y'
        AND A.SORLCUR_CACT_CODE = 'ACTIVE'
        AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                               FROM SORLCUR A1
                               WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                               AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                               AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                               AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                               AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
        AND A.SORLCUR_TERM_CODE_CTLG = E.SZTDTEC_TERM_CODE
        AND D.SPRIDEN_CHANGE_IND IS NULL
        AND F.SFRSTCR_PIDM = A.SORLCUR_PIDM
        AND F.SFRSTCR_RSTS_CODE = 'RE'
        AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
        AND F.SFRSTCR_TERM_CODE = G.SSBSECT_TERM_CODE
        AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
        AND (SFRSTCR_RESERVED_KEY NOT IN ('M1HB401', 'CP001', 'CPB13001') OR SFRSTCR_RESERVED_KEY IS NULL )
        AND (F.SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL)
        AND (F.SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
        AND (F.SFRSTCR_USER_ID != 'MIGRA_D' OR F.SFRSTCR_USER_ID IS NULL)
        AND F.SFRSTCR_CRN = G.SSBSECT_CRN
        AND F.SFRSTCR_PTRM_CODE = G.SSBSECT_PTRM_CODE
        AND G.SSBSECT_PTRM_START_DATE = P_FECHA
        AND D.SPRIDEN_PIDM = P_PIDM 
        AND A.SORLCUR_PROGRAM = P_PROGRAMA);

        DBMS_OUTPUT.PUT_LINE('PARCIALIDAD (OK) = ' || VL_PARCIALIDAD);

  EXCEPTION
  WHEN OTHERS THEN
       VL_PARCIALIDAD:=0;
       DBMS_OUTPUT.PUT_LINE('PARCIALIDAD (EXECPTION) = ' || VL_PARCIALIDAD || ' --> ' || SQLERRM);
  END;
  RETURN(VL_PARCIALIDAD);
END F_PARCIALIDAD_ECONTINUA_TGR;


END PKG_FINANZAS_GGC;
/

DROP PUBLIC SYNONYM PKG_FINANZAS_GGC;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FINANZAS_GGC FOR BANINST1.PKG_FINANZAS_GGC;


GRANT EXECUTE ON BANINST1.PKG_FINANZAS_GGC TO SATURN;
