DROP PACKAGE BODY BANINST1.PKG_SINCRO_UTLX_SIU;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SINCRO_UTLX_SIU AS
/******************************************************************************
   NAME:       BANINST1.PKG_SINCRO_UTLX_SIU
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/04/2023      GOLVERA       1. Created this procedure.
******************************************************************************/

/*PROCEDURE PARA VALIDACION DE PIDM CON ALTAS Y BAJAS UTLX*/
PROCEDURE SP_SIU_UTLX AS

   ln_cnt_sincro   NUMBER (5);
   lv_programa     VARCHAR2(50);
   lv_desc_prog    VARCHAR2(2000);
   V_ERROR         VARCHAR2 (500);

BEGIN


FOR SINCRO_UTLX IN (
SELECT * FROM SZTUTELX
where estatus_sincro in (0,2)
AND FECHA_SINCRO IS NULL
AND INTENTOS =0)
LOOP
IF SINCRO_UTLX.PROGRAMA IS NULL THEN
     BEGIN
        select A.PROGRAMA, A.NOMBRE
        		INTO lv_programa, lv_desc_prog
        from MIGRA.TZTPROG A WHERE A.pidm = SINCRO_UTLX.PIDM
        AND  A.estatus NOT IN ('CF', 'CC', 'CP')
        AND A.SP IN (SELECT max(B.SP) FROM MIGRA.TZTPROG B where b.pidm = a.pidm);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_programa := null;
			lv_desc_prog := null;
      END;

    BEGIN
        UPDATE SZTUTELX SET PROGRAMA= lv_programa , DESC_PROGRAMA =lv_desc_prog, FECHA_JOB=SYSDATE
        WHERE PIDM = SINCRO_UTLX.PIDM;
        COMMIT;
        EXCEPTION WHEN OTHERS THEN
          V_ERROR    := SQLERRM ||'- Error en UPDATING PROGRAMA';
      END;
END IF;


IF SINCRO_UTLX.ESTATUS_SINCRO =2 AND SINCRO_UTLX.ESTATUS ='ALTA' AND SINCRO_UTLX.FECHA_SINCRO IS NULL THEN
--- Validaciones UTLX SIU
select COUNT(1)
INTO ln_cnt_sincro
from SZTUTLX where SZTUTLX_PIDM =SINCRO_UTLX.PIDM
and SZTUTLX_OBS  LIKE '%Sincroizado correctamente%'
and SZTUTLX_DISABLE_IND ='A';
    IF ln_cnt_sincro > 0 THEN
        BEGIN
        UPDATE SZTUTELX SET ESTATUS_SINCRO =0, FECHA_JOB =SYSDATE
        WHERE PIDM = SINCRO_UTLX.PIDM
        AND ESTATUS_SINCRO =2
        AND ESTATUS ='ALTA'
        ;
        COMMIT;
        EXCEPTION WHEN OTHERS THEN
          V_ERROR    := SQLERRM ||'- Error en UPDATING ESTATUS ALTA';
      END;

    END IF;
END IF;

END LOOP;


END SP_SIU_UTLX;

END PKG_SINCRO_UTLX_SIU;
/

DROP PUBLIC SYNONYM PKG_SINCRO_UTLX_SIU;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SINCRO_UTLX_SIU FOR BANINST1.PKG_SINCRO_UTLX_SIU;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_SINCRO_UTLX_SIU TO PUBLIC;
