DROP PACKAGE BODY BANINST1.PKG_ALINEA_DEVENGO;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_ALINEA_DEVENGO AS
/******************************************************************************
   NAME:       PKG_ALINEA_DEVENGO
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27/05/2021      jrezaoli       1. Created this package.
******************************************************************************/

FUNCTION F_NIVELACION_DEVENGO (P_FECHA DATE) RETURN VARCHAR2 IS 

VL_ERROR  VARCHAR2(900);
VL_COUNT  NUMBER:=0;

 BEGIN
   BEGIN
    FOR X IN (
      
              SELECT DISTINCT
                     SSBSECT_PTRM_START_DATE FECHA_INICIO,
                     SSBSECT_TERM_CODE PERIODO,
                     SFRSTCR_TERM_CODE,
                     SFRSTCR_PIDM PIDM,
                     SPRIDEN_ID MATRICULA,
                     SFRSTCR_PTRM_CODE PPARTE,
                     SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB materia,
                     SFRSTCR_RSTS_CODE,
                     SFRSTCR_STSP_KEY_SEQUENCE SP,
                     SFRSTCR_CAMP_CODE || SFRSTCR_LEVL_CODE CAMPUS_NIVEL,
                     SFRSTCR_DATA_ORIGIN,
                     TRUNC (SFRSTCR_ACTIVITY_DATE) FECHA_CREACION,
                     SFRSTCR_VPDI_CODE ORDEN,
                     SFRSTCR_STRD_SEQNO NUM_NIVE,
                     (SELECT DISTINCT (TBRACCD_RECEIPT_NUMBER)
                        FROM TBRACCD D, TBBDETC
                       WHERE     D.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                             AND TBBDETC_TYPE_IND = 'C'
                             AND D.TBRACCD_PIDM = A.SFRSTCR_PIDM
                             AND D.TBRACCD_CROSSREF_NUMBER = A.SFRSTCR_STRD_SEQNO) ORDEN_NIVELA
                FROM SFRSTCR A
                JOIN SSBSECT
                  ON (SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE AND SSBSECT_CRN = SFRSTCR_CRN)
                JOIN SPRIDEN
                  ON (SPRIDEN_PIDM = SFRSTCR_PIDM AND SPRIDEN_CHANGE_IND IS NULL)
               WHERE     1 = 1
                     AND SFRSTCR_VPDI_CODE IS NULL
                     AND SUBSTR (SFRSTCR_TERM_CODE, 5, 1) = 8
                     AND SFRSTCR_RSTS_CODE = 'RE'
                     AND SSBSECT_PTRM_START_DATE >= P_FECHA-(TO_CHAR(P_FECHA,'DD')-1)
                     AND (SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB NOT IN ('M1HB401', 'M1HB402') OR SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB IS NULL)
                     AND (SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR SFRSTCR_DATA_ORIGIN IS NULL)
            ORDER BY 1, 4 DESC
            
     ) LOOP
    
       IF X.ORDEN_NIVELA IS NOT NULL THEN
         BEGIN
           UPDATE SFRSTCR
              SET SFRSTCR_VPDI_CODE = X.ORDEN_NIVELA
            WHERE     1=1    
                  AND SFRSTCR_PIDM = X.PIDM
                  AND SFRSTCR_STRD_SEQNO = X.NUM_NIVE
                  AND SFRSTCR_VPDI_CODE IS NULL
                  AND SFRSTCR_PTRM_CODE = X.PPARTE
                  AND SFRSTCR_TERM_CODE = X.SFRSTCR_TERM_CODE;
         END;  
                
         BEGIN
             UPDATE TBRACCD
                SET TBRACCD_TERM_CODE = X.PERIODO,
                    TBRACCD_PERIOD = X.PPARTE
              WHERE     TBRACCD_PIDM = X.PIDM
                    AND TBRACCD_CROSSREF_NUMBER = X.NUM_NIVE;
         END;
         
         BEGIN      
             UPDATE TVRACCD
                SET TVRACCD_TERM_CODE = X.PERIODO,
                    TVRACCD_PERIOD = X.PPARTE
              WHERE     TVRACCD_PIDM = X.PIDM
                    AND TVRACCD_CROSSREF_NUMBER = X.NUM_NIVE;
         END;    
         VL_COUNT:=VL_COUNT+1;
       END IF;
     END LOOP;
     VL_ERROR:='NIVELACIONES ACTUALIZADAS = '||VL_COUNT;
    COMMIT; 
    RETURN(VL_ERROR);
   END;
 END F_NIVELACION_DEVENGO;

FUNCTION F_MATERIA_DEVENGO (P_FECHA DATE) RETURN VARCHAR2 IS 

VL_ERROR  VARCHAR2(900);
VL_COUNT  NUMBER:=0;

 BEGIN
    BEGIN
    FOR X IN (
                SELECT DISTINCT
                       SFRSTCR_PIDM PIDM ,
                       SPRIDEN_ID MATRICULA, 
                       SSBSECT_PTRM_START_DATE FECHA_INICIO, 
                       SSBSECT_TERM_CODE PERIODO, 
                       SFRSTCR_TERM_CODE,
                       SORLCUR_RATE_CODE RATE,
                       SFRSTCR_PTRM_CODE PPARTE,
                       SFRSTCR_RSTS_CODE,
                       SFRSTCR_STSP_KEY_SEQUENCE SP,
                       SFRSTCR_CAMP_CODE||SFRSTCR_LEVL_CODE CAMPUS_NIVEL            ,
                       SFRSTCR_DATA_ORIGIN     , 
                       TRUNC (SFRSTCR_ACTIVITY_DATE) FECHA_CREACION    ,
                       SFRSTCR_VPDI_CODE ORDEN,
                       CASE SUBSTR (SOL.SORLCUR_RATE_CODE, 1, 1)  
                         WHEN ('J') THEN (SELECT TBRACCD_RECEIPT_NUMBER
                                            FROM TBRACCD D
                                           WHERE     D.TBRACCD_PIDM = A.SFRSTCR_PIDM
                                                 AND D.TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                                                                FROM TBRACCD
                                                                               WHERE     TBRACCD_PIDM = A.SFRSTCR_PIDM
                                                                                     AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                                                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                                                                     AND TBRACCD_STSP_KEY_SEQUENCE = A.SFRSTCR_STSP_KEY_SEQUENCE  
                                                                                     AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(SSBSECT_PTRM_START_DATE+12)))
                         WHEN ('P') THEN (SELECT TBRACCD_RECEIPT_NUMBER
                                            FROM TBRACCD D
                                           WHERE     D.TBRACCD_PIDM = A.SFRSTCR_PIDM
                                                 AND D.TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                                                                FROM TBRACCD,TBBDETC
                                                                               WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE    
                                                                                     AND TBRACCD_PIDM = A.SFRSTCR_PIDM
                                                                                     AND TBBDETC_DCAT_CODE = 'COL'
                                                                                     AND (    TBBDETC_DESC LIKE 'COLEGIATURA%'
                                                                                           OR TBBDETC_DESC = 'COLE LICENCIATURA PLAN NOTA'
                                                                                          AND TBRACCD_USER = 'MIGRA_D') 
                                                                                     AND TBBDETC_DESC != 'COLEGIATURA EXTRAORDINARIO'
                                                                                     AND (    TBBDETC_DESC NOT LIKE '%NOTA'
                                                                                           OR TBBDETC_DESC = 'COLE LICENCIATURA PLAN NOTA'
                                                                                          AND TBRACCD_USER = 'MIGRA_D') 
                                                                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL))
                       END FOLIO
                FROM SORLCUR SOL, SFRSTCR A
                JOIN SSBSECT 
                  ON (SSBSECT_TERM_CODE  = SFRSTCR_TERM_CODE AND SSBSECT_CRN = SFRSTCR_CRN)
                JOIN SPRIDEN 
                  ON (SPRIDEN_PIDM = SFRSTCR_PIDM AND SPRIDEN_CHANGE_IND IS NULL)
               WHERE    SOL.SORLCUR_PIDM = A.SFRSTCR_PIDM 
                    AND SOL.SORLCUR_KEY_SEQNO = A.SFRSTCR_STSP_KEY_SEQUENCE
                    AND SOL.SORLCUR_LMOD_CODE = 'LEARNER'
                    AND SOL.SORLCUR_ROLL_IND  = 'Y'
                    AND SOL.SORLCUR_CACT_CODE = 'ACTIVE'
                    AND SOL.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                FROM SORLCUR A1
                                               WHERE     A1.SORLCUR_PIDM = SOL.SORLCUR_PIDM
                                                     AND A1.SORLCUR_ROLL_IND  = SOL.SORLCUR_ROLL_IND
                                                     AND A1.SORLCUR_CACT_CODE = SOL.SORLCUR_CACT_CODE
                                                     AND A1.SORLCUR_PROGRAM = SOL.SORLCUR_PROGRAM
                                                     AND A1.SORLCUR_LMOD_CODE = SOL.SORLCUR_LMOD_CODE)
                     AND SFRSTCR_VPDI_CODE IS NULL
                     AND SUBSTR (SFRSTCR_TERM_CODE, 5,1) NOT IN (8,9)
                     AND SFRSTCR_RSTS_CODE = 'RE'
                     AND SSBSECT_PTRM_START_DATE > P_FECHA-(TO_CHAR(P_FECHA,'DD')-1)
                     AND SSBSECT_PTRM_START_DATE < LAST_DAY(P_FECHA)
                     AND (SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB NOT IN ('M1HB401', 'M1HB402') OR SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB IS NULL)
                     AND (SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR SFRSTCR_DATA_ORIGIN IS NULL)
                     --AND SPRIDEN_ID = '010020448'
               ORDER BY 1,4 DESC
     ) LOOP
    
        IF X.FOLIO IS NOT NULL THEN
        
            UPDATE SFRSTCR
               SET SFRSTCR_VPDI_CODE = X.FOLIO
             WHERE     1=1    
                   AND SFRSTCR_PIDM = X.PIDM
                   AND SFRSTCR_VPDI_CODE IS NULL
                   AND SFRSTCR_PTRM_CODE = X.PPARTE
                   AND SFRSTCR_TERM_CODE = X.SFRSTCR_TERM_CODE;

          VL_COUNT:=VL_COUNT+1;        
        END IF;
     
     END LOOP;
     VL_ERROR:='ORDENES DE MATERIAS ACTUALIZADAS = '||VL_COUNT;
    COMMIT; 
    RETURN(VL_ERROR);
   END;
 END F_MATERIA_DEVENGO;

FUNCTION F_DOBLE_PARTE (P_FECHA DATE)RETURN VARCHAR2 IS

VL_CONTA        NUMBER:=0;
VL_CADENA       VARCHAR2(900);
VL_ERROR        VARCHAR2(900);
VL_MATRICULA    VARCHAR2(900);

 BEGIN
   FOR X IN (
              SELECT SPRIDEN_ID,
                     SSBSECT_TERM_CODE,
                     SSBSECT_PTRM_START_DATE,
                     COUNT(DISTINCT SFRSTCR_PTRM_CODE)PARTES 
                FROM SFRSTCR A
                JOIN SSBSECT 
                  ON (SSBSECT_TERM_CODE  = SFRSTCR_TERM_CODE AND SSBSECT_CRN = SFRSTCR_CRN AND SSBSECT_PTRM_CODE = SFRSTCR_PTRM_CODE)
                JOIN SPRIDEN 
                  ON (SPRIDEN_PIDM = SFRSTCR_PIDM AND SPRIDEN_CHANGE_IND IS NULL)
            WHERE     SFRSTCR_RSTS_CODE = 'RE'
                  AND (SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB NOT IN ('M1HB401', 'M1HB402') OR SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB IS NULL)
                  AND (SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR SFRSTCR_DATA_ORIGIN IS NULL)
                  AND SUBSTR (SFRSTCR_TERM_CODE, 5,1) NOT IN (8,9)
                  AND SSBSECT_PTRM_START_DATE >= P_FECHA-(TO_CHAR(P_FECHA,'DD')-1)
            GROUP BY SPRIDEN_ID,
                     SSBSECT_TERM_CODE,
                     SSBSECT_PTRM_START_DATE
            HAVING COUNT(DISTINCT SFRSTCR_PTRM_CODE)>1
   )LOOP
     VL_MATRICULA:=X.SPRIDEN_ID;
     VL_CONTA:=VL_CONTA+1;
     VL_CADENA:=VL_CADENA||' = '||VL_MATRICULA;
   END LOOP;
   
   VL_ERROR:='VALIDAR PARTE DOBLE = '||VL_CONTA||', MATRICULAS '||VL_CADENA;
   
   COMMIT;
   RETURN(VL_ERROR);
 END F_DOBLE_PARTE;
 
FUNCTION F_ALINEA_TODO (P_FECHA_TOTAL DATE)RETURN VARCHAR2 IS

VL_MATERIA      VARCHAR(900);        
VL_DOBLE_PARTE  VARCHAR(900);
VL_NIVELACION   VARCHAR(900);
VL_ERROR        VARCHAR(900);

BEGIN
  BEGIN
   FOR X IN (
             SELECT TZTPAGO_CAMP,TZTPAGO_LEVL,TZTPAGO_ID,TZTPAGO_PROGRAMA,TZTORDR_CONTADOR
               FROM TZTORDR,TZTPAGO A
              WHERE     TZTORDR_CAMPUS||TZTORDR_NIVEL IS NULL
                    AND A.TZTPAGO_ID = TZTORDR_ID
                    AND A.TZTPAGO_STAT_INSCR != 'CANCELADA'
                    AND A.TZTPAGO_FECHA_DOCTO = (SELECT MAX(TZTPAGO_FECHA_DOCTO)
                                                 FROM TZTPAGO
                                                 WHERE TZTPAGO_ID = A.TZTPAGO_ID
                                                 AND TZTPAGO_STAT_INSCR != 'CANCELADA')
                    AND A.TZTPAGO_TERM_CODE = (SELECT MAX (TZTPAGO_TERM_CODE)
                                                 FROM TZTPAGO A1
                                                WHERE     A1.TZTPAGO_ID = A.TZTPAGO_ID
                                                      AND A1.TZTPAGO_STAT_INSCR != 'CANCELADA'
                                                      AND A1.TZTPAGO_FECHA_DOCTO = (SELECT MAX(TZTPAGO_FECHA_DOCTO)
                                                                                      FROM TZTPAGO
                                                                                     WHERE TZTPAGO_ID = A.TZTPAGO_ID
                                                                                           AND TZTPAGO_STAT_INSCR != 'CANCELADA'))                               
    )LOOP
      BEGIN
        UPDATE TZTORDR
           SET TZTORDR_NIVEL = X.TZTPAGO_LEVL,
               TZTORDR_CAMPUS = X.TZTPAGO_CAMP,
               TZTORDR_PROGRAMA = X.TZTPAGO_PROGRAMA
         WHERE     TZTORDR_ID = X.TZTPAGO_ID
               AND TZTORDR_CONTADOR = X.TZTORDR_CONTADOR
               AND TZTORDR_CAMPUS||TZTORDR_NIVEL IS NULL;
      END;
    END LOOP;
  END;

  BEGIN
  
    BEGIN
    VL_MATERIA:=PKG_ALINEA_DEVENGO.F_MATERIA_DEVENGO (P_FECHA_TOTAL);
    END;
    
    BEGIN
    VL_DOBLE_PARTE := PKG_ALINEA_DEVENGO.F_DOBLE_PARTE (P_FECHA_TOTAL);
    END;
    
    BEGIN
    VL_NIVELACION:= PKG_ALINEA_DEVENGO.F_NIVELACION_DEVENGO (P_FECHA_TOTAL);
    END;
    
    VL_ERROR:=SUBSTR(VL_NIVELACION||', '||VL_MATERIA||', '||VL_DOBLE_PARTE,1,899);
  
  END;
  COMMIT;
 RETURN(VL_ERROR);
END F_ALINEA_TODO;
 
END PKG_ALINEA_DEVENGO;
/

DROP PUBLIC SYNONYM PKG_ALINEA_DEVENGO;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ALINEA_DEVENGO FOR BANINST1.PKG_ALINEA_DEVENGO;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_ALINEA_DEVENGO TO PUBLIC;
