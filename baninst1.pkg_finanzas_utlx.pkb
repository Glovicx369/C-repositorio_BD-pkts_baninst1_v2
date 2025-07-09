DROP PACKAGE BODY BANINST1.PKG_FINANZAS_UTLX;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_FINANZAS_UTLX" AS
/******************************************************************************
 NAME: BANINST1.PKG_FINANZAS_UTLX
 PURPOSE:

 REVISIONS:
 Ver Date Author Description
 --------- ---------- --------------- ------------------------------------
 1.0 22/12/2021 ggarcica 1. Created this package.
******************************************************************************/

FUNCTION F_INSERT_TZTUTLX ( P_CAMPUS VARCHAR2,
 P_NIVEL VARCHAR2,
 P_PIDM NUMBER,
 P_MATRICULA VARCHAR2,
 P_PROGRAMA VARCHAR2,
 P_PERIODO VARCHAR2,
 P_FECHA_INICIO DATE,
 P_DIVISA VARCHAR2,
 P_DESCUENTO NUMBER,
 P_MONTO_PARC NUMBER,
 P_MONTO_PRIMER_PAGO NUMBER,
 P_PAGOS_MAT NUMBER,
 P_PAGOS_REGLA NUMBER,
 P_RATE VARCHAR2,
 P_JORNADA VARCHAR2,
 P_ORIGEN VARCHAR2
 )RETURN VARCHAR2 IS
 /*INSERTA TABLA TZTUTLX*/

VL_ERROR VARCHAR2(500);

 BEGIN
 BEGIN
 INSERT
 INTO TZTUTLX
 (TZTUTLX_CAMP_CODE,
 TZTUTLX_LEVL_CODE,
 TZTUTLX_PIDM,
 TZTUTLX_ID,
 TZTUTLX_PROGRAM,
 TZTUTLX_TERM_CODE,
 TZTUTLX_START_DATE,
 TZTUTLX_CURR_CODE,
 TZTUTLX_DESCUENTO,
 TZTUTLX_AMOUNT,
 TZTUTLX_PRI_AMOUNT,
 TZTUTLX_NUM_TRAN,
 TZTUTLX_NUM_PAG,
 TZTUTLX_RATE_CODE,
 TZTUTLX_ATTS_CODE,
 TZTUTLX_ACTIVITY_DATE,
 TZTUTLX_ACTIVITY_UPDATE,
 TZTUTLX_USER,
 TZTUTLX_USER_UPDATE,
 TZTUTLX_DATA_ORIGIN,
 TZTUTLX_STATUS,
 TZTUTLX_FLAG
 )
 VALUES (P_CAMPUS,
 P_NIVEL,
 P_PIDM,
 P_MATRICULA,
 P_PROGRAMA,
 P_PERIODO,
 P_FECHA_INICIO,
 P_DIVISA,
 P_DESCUENTO,
 P_MONTO_PARC,
 P_MONTO_PRIMER_PAGO,
 P_PAGOS_MAT,
 P_PAGOS_REGLA,
 P_RATE,
 P_JORNADA,
 SYSDATE,
 SYSDATE,
 USER,
 USER,
 P_ORIGEN,
 'ACTIVO',
 0
 );
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'Error al insertar en TZTUTLX = '||SQLERRM;
 END;

 IF VL_ERROR IS NULL THEN
 VL_ERROR:= 'EXITO';
 COMMIT;
 ELSE
 ROLLBACK;
 END IF;

 RETURN(VL_ERROR);

 END F_INSERT_TZTUTLX;


 FUNCTION F_CART_UTLX (P_PIDM NUMBER,
 P_FECHA DATE,
 P_ALUMNO VARCHAR2,
 P_DETAIL_CODE VARCHAR2 )RETURN VARCHAR2 IS

 /*GENERA CARGO UTLX*/

VL_DESCRIPCION_PAR VARCHAR2(40);
VL_SECUENCIA NUMBER;
VL_ERROR VARCHAR2(500):= 'Error al generar cartera';
VL_ORDEN NUMBER;



 BEGIN

 IF P_ALUMNO = 'WUTLX' THEN

 FOR ALUMNO IN (

 SELECT TZTUTLX_CAMP_CODE CAMPUS,
 TZTUTLX_LEVL_CODE NIVEL,
 TZTUTLX_PIDM PIDM,
 TZTUTLX_ID MATRICULA,
 TZTUTLX_PROGRAM PROGRAMA,
 TZTUTLX_TERM_CODE PERIODO,
 TZTUTLX_START_DATE FECHA_INICIO,
 TZTUTLX_CURR_CODE DIVISA,
 NVL(TZTUTLX_DESCUENTO,0) DESCUENTO,
 TZTUTLX_AMOUNT MONTO,
 TZTUTLX_NUM_TRAN TRANSA,
 TZTUTLX_NUM_PAG PAGOS,
 TZTUTLX_RATE_CODE RATE,
 TZTUTLX_ATTS_CODE JORNADA,
 TZTUTLX_DATA_ORIGIN ORIGEN,
 TZTUTLX_STATUS ESTATUS,
 TZTUTLX_ORDEN ORDEN,
 SORLCUR_KEY_SEQNO STUDY_PATH,
 DECODE (A.SORLCUR_DEGC_CODE, 'DIPL', 'COLEGIATURA DIPLOMADO', 'CURS', 'COLEGIATURA CURSO')DEGC_CODE,
 (SELECT DISTINCT SORLCUR_SITE_CODE
 FROM SORLCUR CUR
 WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
 AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
 AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
 FROM SORLCUR CUR2
 WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
 AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO,
 TZTUTLX_OBSERVACIONES OBSERVACIONES
 FROM TZTUTLX LEFT JOIN
 SORLCUR A
 ON TZTUTLX_PIDM = A.SORLCUR_PIDM
 AND A.SORLCUR_LMOD_CODE = 'LEARNER'
 AND A.SORLCUR_ROLL_IND = 'Y'
 AND A.SORLCUR_CACT_CODE = 'ACTIVE'
 AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
 FROM SORLCUR A1
 WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
 AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND
 AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
 AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
 AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
 WHERE TZTUTLX_PIDM = P_PIDM
 AND TRUNC(TZTUTLX_START_DATE) = P_FECHA
 AND TZTUTLX_STATUS = 'ACTIVO'
 )LOOP

 BEGIN

 SELECT TBBDETC_DESC
 INTO VL_DESCRIPCION_PAR
 FROM TBBDETC
 WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CODE;
 END;

 DBMS_OUTPUT.PUT_LINE('Codigo ='||VL_DESCRIPCION_PAR);

 DBMS_OUTPUT.PUT_LINE(TO_CHAR(TO_DATE(SUBSTR(ALUMNO.FECHA_INICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY'));

 VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (ALUMNO.PIDM);


 VL_ERROR:= PKG_FINANZAS.F_INSERTA_TBRACCD(
 P_PIDM => ALUMNO.PIDM
 , P_SECUENCIA => VL_SECUENCIA
 , P_NUMBER_PAID => NULL
 , P_PERIODO => ALUMNO.PERIODO
 , P_PARTE_PERIODO => NULL
 , P_CODIGO => P_DETAIL_CODE
 , P_MONTO => ALUMNO.MONTO
 , P_BALANCE => ALUMNO.MONTO
 , P_FECHA_VENC => TRUNC(SYSDATE)
 , P_DESCRIP => VL_DESCRIPCION_PAR
 , P_STUDY_PATH => ALUMNO.STUDY_PATH
 , P_ORIGEN => 'TZFEDCA (PARC)'
-- , P_FECHA_INICIO => TRUNC(SYSDATE)
 , P_FECHA_INICIO => TO_DATE(SUBSTR(ALUMNO.FECHA_INICIO,1,10),'DD/MM/YYYY')
 );


 IF VL_ERROR IS NULL THEN

 BEGIN
 SELECT MAX(TZTORDR_CONTADOR)+1
 INTO VL_ORDEN
 FROM TZTORDR;
 EXCEPTION
 WHEN OTHERS THEN
 VL_ORDEN:= NULL;
 END;

 DBMS_OUTPUT.PUT_LINE('Orden ='||VL_ORDEN);

 IF VL_ORDEN IS NOT NULL THEN

 BEGIN

 INSERT INTO TZTORDR
 (
 TZTORDR_CAMPUS,
 TZTORDR_NIVEL,
 TZTORDR_CONTADOR,
 TZTORDR_PROGRAMA,
 TZTORDR_PIDM,
 TZTORDR_ID,
 TZTORDR_ESTATUS,
 TZTORDR_ACTIVITY_DATE,
 TZTORDR_USER,
 TZTORDR_DATA_ORIGIN,
 TZTORDR_NO_REGLA,
 TZTORDR_FECHA_INICIO,
 TZTORDR_RATE,
 TZTORDR_JORNADA,
 TZTORDR_DSI,
 TZTORDR_TERM_CODE
 )
 VALUES( ALUMNO.CAMPUS,
 ALUMNO.NIVEL,
 VL_ORDEN,
 ALUMNO.PROGRAMA,
 ALUMNO.PIDM,
 ALUMNO.MATRICULA,
 'S',
 SYSDATE,
 USER,
 'TZTFEDCA',
 NULL,
 TRUNC(ALUMNO.FECHA_INICIO),
 ALUMNO.RATE,
 ALUMNO.JORNADA,
 0,
 ALUMNO.PERIODO
 );
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'ERROR AL INSERTAR EN TZTORDR = '||SQLERRM;
 END;

 END IF;

 BEGIN
 UPDATE TBRACCD A1
 SET A1.TBRACCD_RECEIPT_NUMBER = VL_ORDEN
 WHERE A1.TBRACCD_PIDM = ALUMNO.PIDM
 AND A1.TBRACCD_TERM_CODE = ALUMNO.PERIODO
-- AND A1.TBRACCD_PERIOD = NULL
 AND A1.TBRACCD_RECEIPT_NUMBER IS NULL;

 UPDATE TVRACCD A1
 SET A1.TVRACCD_RECEIPT_NUMBER = VL_ORDEN
 WHERE A1.TVRACCD_PIDM = ALUMNO.PIDM
 AND A1.TVRACCD_TERM_CODE = ALUMNO.PERIODO
-- AND A1.TVRACCD_PERIOD = NULL
 AND A1.TVRACCD_RECEIPT_NUMBER IS NULL;
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'ERROR AL ACTUALIZAR TBRACCD = '||SQLERRM;
 END;

 BEGIN
 UPDATE TZTUTLX
 SET TZTUTLX_OBSERVACIONES = NULL,
 TZTUTLX_ORDEN = VL_ORDEN,
 TZTUTLX_STATUS = 'GENERADA',
 TZTUTLX_USER_UPDATE = USER,
 TZTUTLX_ACTIVITY_UPDATE = SYSDATE
 WHERE TZTUTLX_PIDM = ALUMNO.PIDM
 AND TRUNC(TZTUTLX_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);
 END;

 BEGIN
 INSERT
 INTO TZDOCTR
 (TZDOCTR_PIDM,
 TZDOCTR_PROGRAM,
 TZDOCTR_STST_CODE,
 TZDOCTR_STYP_CODE,
 TZDOCTR_CAMP_CODE,
 TZDOCTR_LEVL_CODE,
 TZDOCTR_TERM_CODE,
 TZDOCTR_START_DATE,
 TZDOCTR_PTRM_CODE,
 TZDOCTR_STUDY_PATH,
 TZDOCTR_NUM_PAGOS,
 TZDOCTR_RATE_CODE,
 TZDOCTR_COLEG,
 TZDOCTR_DESC,
 TZDOCTR_PPAGO,
 TZDOCTR_PARCI,
 FECHA_PROCESO,
 TZDOCTR_IND,
 TZDOCTR_OBSERVACIONES,
 TZDOCTR_VENCIMIENTO,
 TZDOCTR_ID,
 TZDOCTR_TIPO_PROC,
 TZDOCTR_DESCUENTO)
 VALUES (ALUMNO.PIDM,
 ALUMNO.PROGRAMA,
 'MA',
 'N',
 ALUMNO.CAMPUS,
 ALUMNO.NIVEL,
 ALUMNO.PERIODO,
 TRUNC(ALUMNO.FECHA_INICIO),
 NULL,
 0,
 ALUMNO.PAGOS,
 NULL,
 0,
 0,
 0,
 0,
 SYSDATE ,
 1 ,
 'Cartera creada con exito para UTELX',
 TO_CHAR(SYSDATE,'DD'),
 ALUMNO.MATRICULA,
 'UTX' ,
 1);
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR :='Error al insertar la bitacora de la cartera' ||SQLERRM;
 END;

 END IF;

 END LOOP;

 END IF;

 IF VL_ERROR IS NULL THEN
 VL_ERROR:='EXITO';
 COMMIT;
 ELSE
 ROLLBACK;
 END IF;

 RETURN(VL_ERROR);

END F_CART_UTLX;

 FUNCTION F_ELIMNINA_ETQ_UTLX (P_PIDM NUMBER,p_detail_code varchar2 )
 return varchar2
 IS
 l_retorna varchar2(500):='EXITO';
 l_contar number;
 begin

 begin

 select count(*)
 into l_contar
 from goradid
 where 1 = 1
 and goradid_pidm = p_pidm
 and goradid_adid_code = p_detail_code;
-- and exists(select null
-- from SZTPDMA
-- where 1 = 1
-- and GORADID_ADID_CODE = SZTPDMA_ALIANZA
-- and SZTPDMA_DETAIL_COODE = p_detail_code
-- );

 exception when others then
 null;
 end;

 if l_contar > 0 then

 begin

 delete
 from goradid
 where 1 = 1
 and goradid_pidm = p_pidm
 and goradid_adid_code = p_detail_code;
-- and exists(select null
-- from SZTPDMA
-- where 1 = 1
-- and GORADID_ADID_CODE = SZTPDMA_ALIANZA
-- and SZTPDMA_DETAIL_COODE = p_detail_code
-- );


 exception when others then
 l_retorna:='Error al eliminar etiqueta ='||p_pidm;
 end;


 else

 l_retorna:='No se encuentra etiqueta';


 end if;

 commit;
 return l_retorna;
 end;

FUNCTION F_REACTIVA_UTLX (P_PIDM NUMBER, P_SEQNO NUMBER DEFAULT NULL, P_FECHA DATE DEFAULT NULL, P_CODIGO VARCHAR2) RETURN VARCHAR2 IS

/*FUNCION QUE INSERTA PRIMER CARGO AL REACTIVAR UTLX Y CONECTA
AUTOR: GGARCICA
FECHA: 18/01/2022 AJUSTE DE P_SEQNO APLICADO POR VICTOR S Y EL PRIMER BLOQUE POR VICTOR R
CAMBIO GLOVICX AJUSTE AL MONTO 27.07.2023

*/

VL_ENTRA NUMBER;
VL_DESCRI_ACC VARCHAR2(35);
VL_DESCUENTO_ACC NUMBER;
VL_ERROR VARCHAR2(900);
VL_PORCE_DESC NUMBER;
VL_DESCUE_SW NUMBER;
VL_MONTO_ACC NUMBER;
VL_COD_DESCUENTO VARCHAR2(5);
VL_AJUSTE NUMBER;
VL_SECUENCIA NUMBER;
VL_DESCRI_DESCUENTO VARCHAR2(35);
VL_PERIODO VARCHAR2(10);
VL_INICIO VARCHAR2(20);
VL_STUDY NUMBER;
VL_ORDEN NUMBER;
VL_FECHA DATE;
VL_CARGOS NUMBER;
VL_TRAN_NUM NUMBER:=1;
VL_MONEDA VARCHAR2(10);
VL_TZFACCE_NUM NUMBER;
VL_TZFACCE_STUDY NUMBER;
VL_TRANSA VARCHAR2(20);
VL_EXISTE_CODIGO NUMBER;
VL_PARTE VARCHAR2(4);
P_PROGRAMA VARCHAR2(20);
VL_PARTE_1 VARCHAR2(4);


BEGIN

 Begin

 Select distinct max (SFRSTCR_PTRM_CODE)
 Into VL_PARTE_1
 from sfrstcr a
 where 1= 1
 And a.SFRSTCR_PIDM = P_PIDM
 And substr (a.SFRSTCR_TERM_CODE, 5,1) not in ('9','8')
 And a.SFRSTCR_TERM_CODE = (select max (a1.SFRSTCR_TERM_CODE)
 from SFRSTCR a1
 join ssbsect a2 on a2.SSBSECT_TERM_CODE = a1.SFRSTCR_TERM_CODE and a2.SSBSECT_CRN = a1.SFRSTCR_CRN
 Where a.SFRSTCR_PIDM = a1.SFRSTCR_PIDM
 );
 Exception
 When Others then
 VL_PARTE_1:= null;
 End;

 VL_FECHA:=P_FECHA;

 Begin

 IF VL_FECHA IS NULL

 THEN VL_FECHA:=TRUNC(SYSDATE);

 ELSE

 VL_FECHA:= P_FECHA;

 END IF;

 Select distinct a.programa, b.TZTORDR_TERM_CODE, b.TZTORDR_CONTADOR, a.sp, a.fecha_inicio,
 c.SORLCUR_VPDI_CODE
 Into P_PROGRAMA, VL_PERIODO, VL_ORDEN, VL_STUDY, VL_INICIO,VL_PARTE
 from tztprog a
 join TZTORDR b on b.TZTORDR_PIDM = a.pidm and TZTORDR_CAMPUS = a.campus and TZTORDR_NIVEL = a.nivel
 And b.TZTORDR_CONTADOR = (select max ( b1.TZTORDR_CONTADOR)
 from TZTORDR b1
 where b.TZTORDR_PIDM = b1.TZTORDR_PIDM
 )
 join sorlcur c on c.sorlcur_pidm = a.pidm and c.SORLCUR_PROGRAM = a.programa
 AND SORLCUR_LMOD_CODE = 'LEARNER'
 AND SORLCUR_ROLL_IND = 'Y'
 AND SORLCUR_CACT_CODE = 'ACTIVE'
 where 1= 1
 And a.sp = (select max (a1.sp)
 from tztprog a1
 Where a.campus = a1.campus
 And a.nivel = a1.nivel
 And a.pidm = a1.pidm)
 And a.pidm = P_PIDM;


 Exception
 When Others then
 P_PROGRAMA := null;
 VL_PERIODO:= null;
 VL_ORDEN:= null;
 VL_STUDY:= null;
 VL_INICIO:= null;
 VL_PARTE:= null;
 VL_ERROR:=SQLERRM;
 End;

 If VL_PARTE_1 is not null then
 VL_PARTE:= VL_PARTE_1;
 End if;


 IF SUBSTR (P_CODIGO,3,2) = 'NA' THEN

 BEGIN
 SELECT COUNT(SZTUTLX_DISABLE_IND)
 INTO VL_ENTRA
 FROM SZTUTLX X
 WHERE 1 = 1
 AND X.SZTUTLX_PIDM = P_PIDM
 AND X.SZTUTLX_DISABLE_IND = 'A'
 AND X.SZTUTLX_SEQ_NO = ( SELECT MAX (SZTUTLX_SEQ_NO)
 FROM SZTUTLX
 WHERE SZTUTLX_PIDM = X.SZTUTLX_PIDM
 AND SZTUTLX_DISABLE_IND = 'A');

 EXCEPTION WHEN
 OTHERS THEN
 VL_ENTRA:=0;
 END;

 ELSE

 BEGIN
 SELECT COUNT(TZTCOTA_STATUS)
 INTO VL_ENTRA
 FROM TZTCOTA X
 WHERE 1 = 1
 AND X.TZTCOTA_PIDM = P_PIDM
 AND X.TZTCOTA_STATUS = 'A'
 AND X.TZTCOTA_CODIGO = P_CODIGO
 AND X.TZTCOTA_SEQNO = ( SELECT MAX (TZTCOTA_SEQNO)
 FROM TZTCOTA
 WHERE TZTCOTA_PIDM = X.TZTCOTA_PIDM
 AND TZTCOTA_STATUS = 'A');

 EXCEPTION WHEN
 OTHERS THEN
 VL_ENTRA:=0;
 END;
 END IF;


 IF VL_ENTRA = 0 THEN VL_ERROR:= 'VALIDAR ESTATUS';


 ELSE

 BEGIN
 SELECT DISTINCT TBBDETC_DESC,TBBDETC_AMOUNT,TVRDCTX_CURR_CODE
 INTO VL_DESCRI_ACC,VL_MONTO_ACC,VL_MONEDA
 FROM TBBDETC,TVRDCTX
 WHERE TBBDETC_DETAIL_CODE = P_CODIGO
 AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE;

 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR EN CALCULAR CODIGO '||SQLERRM;
 END;


     IF SUBSTR (P_CODIGO,3,2) like ( '%NA' ) THEN   -- SE AGREGO ESTA  validación para tomar el monto de la pregunta 5 regla de fernado glovicx 12.07.2023 
       
         begin
            select distinct -- SVRSVPR_PROTOCOL_AMOUNT  AJUSTE GLOVICX 04.08.2023
                          substr (SVRSVAD_ADDL_DATA_DESC,instr(SVRSVAD_ADDL_DATA_DESC,'$',1)+1,7)
                INTO  VL_MONTO_ACC
                 from svrsvpr v,SVRSVAD VA, SZTCTSIU G
                 where 1=1
                    AND v.SVRSVPR_PROTOCOL_SEQ_NO = P_SEQNO
                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    AND  va.SVRSVAD_ADDL_DATA_SEQ = 5
                    AND  v.SVRSVPR_PIDM    = P_PIDM
                    and  substr(g.SZT_CODTLE,1,2) =  SUBSTR(F_GetSpridenID( P_PIDM),1,2)
                    and  v.SVRSVPR_SRVC_CODE  = g.SZT_CODE_SERV
                    and  TRIM(substr(VA.SVRSVAD_ADDL_DATA_DESC, instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)+1, 3)) = G.SZT_MESES;

         exception when others then
           VL_MONTO_ACC := 0;
         end;
  
      END IF;
 
 
 
 IF VL_ERROR IS NULL THEN


 BEGIN
 SELECT COUNT (*)
 INTO VL_CARGOS
 FROM TBRACCD
 WHERE TBRACCD_PIDM = P_PIDM
 AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
 AND TBRACCD_DOCUMENT_NUMBER IS NULL
 AND TBRACCD_TERM_CODE = VL_PERIODO
 AND TBRACCD_PERIOD = VL_PARTE
 AND LAST_DAY(TBRACCD_EFFECTIVE_DATE)>= LAST_DAY(VL_FECHA)
 AND TBRACCD_STSP_KEY_SEQUENCE = VL_STUDY;

 END;


 BEGIN
 SELECT COUNT(*)
 INTO VL_EXISTE_CODIGO
 FROM TBRACCD
 WHERE SUBSTR(TBRACCD_DETAIL_CODE,3,2) IN ('NA','B2','B3')
 AND to_char(TRUNC(TBRACCD_EFFECTIVE_DATE) , 'MM/RRRR') = to_char(TRUNC(VL_FECHA) , 'MM/RRRR')
 AND TBRACCD_PIDM = P_PIDM;
 END;


 IF VL_EXISTE_CODIGO > 0 THEN

 CASE
 WHEN SUBSTR(P_CODIGO,3,2)='B3' THEN VL_CARGOS:=0;
 WHEN VL_EXISTE_CODIGO > 1 THEN VL_CARGOS:= 0;
 WHEN VL_CARGOS = 2 THEN VL_CARGOS:=1;
 WHEN VL_CARGOS = 1 OR VL_EXISTE_CODIGO > 1 THEN VL_CARGOS:=0;
 ELSE
 VL_CARGOS:= VL_CARGOS;
 END CASE;

 ELSE

 CASE
 WHEN VL_CARGOS = 0 THEN VL_CARGOS:= 1;
 ELSE
 VL_CARGOS:= VL_CARGOS;
 END CASE;


 END IF;


 FOR I IN 1..VL_CARGOS LOOP

 BEGIN
 SELECT MAX(TBRACCD_TRAN_NUMBER)+1
 INTO VL_SECUENCIA
 FROM TBRACCD WHERE TBRACCD_PIDM = P_PIDM;
 EXCEPTION
 WHEN OTHERS THEN
 VL_SECUENCIA:= 0;
 END;


 IF VL_EXISTE_CODIGO > 0 THEN

 IF VL_TRAN_NUM = 1 AND VL_CARGOS = 1 THEN
 VL_FECHA:= ADD_MONTHS(VL_FECHA,1);
 ELSE
 VL_FECHA:=VL_FECHA;
 END IF;

 ELSE

 IF VL_TRAN_NUM = 1 THEN
 VL_FECHA:= VL_FECHA;
-- ELSE
-- VL_FECHA:= ADD_MONTHS(VL_FECHA,1);
 END IF;

 END IF;


 BEGIN

 INSERT
 INTO TBRACCD
 VALUES ( P_PIDM, -- TBRACCD_PIDM
 VL_SECUENCIA, -- TBRACCD_TRAN_NUMBER
 VL_PERIODO, -- TBRACCD_TERM_CODE
 P_CODIGO, -- TBRACCD_DETAIL_CODE
 USER, -- TBRACCD_USER
 SYSDATE, -- TBRACCD_ENTRY_DATE
 NVL(VL_MONTO_ACC,0), -- TBRACCD_AMOUNT
 NVL(VL_MONTO_ACC,0), -- TBRACCD_BALANCE
 TO_DATE(VL_FECHA,'DD/MM/RRRR'), -- TBRACCD_EFFECTIVE_DATE
 NULL, -- TBRACCD_BILL_DATE
 NULL, -- TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
 VL_DESCRI_ACC, -- TBRACCD_DESC
 VL_ORDEN, -- TBRACCD_RECEIPT_NUMBER
 NULL, -- TBRACCD_TRAN_NUMBER_PAID
 NULL, -- TBRACCD_CROSSREF_PIDM
 NULL, -- TBRACCD_CROSSREF_NUMBER
 NULL, -- TBRACCD_CROSSREF_DETAIL_CODE
 'T', -- TBRACCD_SRCE_CODE
 'Y', -- TBRACCD_ACCT_FEED_IND
 SYSDATE, -- TBRACCD_ACTIVITY_DATE
 0, -- TBRACCD_SESSION_NUMBER
 NULL, -- TBRACCD_CSHR_END_DATE
 NULL, -- TBRACCD_CRN
 NULL, -- TBRACCD_CROSSREF_SRCE_CODE
 NULL, -- TBRACCD_LOC_MDT
 NULL, -- TBRACCD_LOC_MDT_SEQ
 NULL, -- TBRACCD_RATE
 NULL, -- TBRACCD_UNITS
 NULL, -- TBRACCD_DOCUMENT_NUMBER
 TO_DATE(VL_FECHA,'DD/MM/RRRR'), -- TBRACCD_TRANS_DATE
 NULL, -- TBRACCD_PAYMENT_ID
 NULL, -- TBRACCD_INVOICE_NUMBER
 NULL, -- TBRACCD_STATEMENT_DATE
 NULL, -- TBRACCD_INV_NUMBER_PAID
 VL_MONEDA, -- TBRACCD_CURR_CODE
 NULL, -- TBRACCD_EXCHANGE_DIFF
 NULL, -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
 NULL, -- TBRACCD_LATE_DCAT_CODE
 VL_INICIO, -- TBRACCD_FEED_DATE
 NULL, -- TBRACCD_FEED_DOC_CODE
 NULL, -- TBRACCD_ATYP_CODE
 NULL, -- TBRACCD_ATYP_SEQNO
 NULL, -- TBRACCD_CARD_TYPE_VR
 NULL, -- TBRACCD_CARD_EXP_DATE_VR
 NULL, -- TBRACCD_CARD_AUTH_NUMBER_VR
 NULL, -- TBRACCD_CROSSREF_DCAT_CODE
 NULL, -- TBRACCD_ORIG_CHG_IND
 NULL, -- TBRACCD_CCRD_CODE
 NULL, -- TBRACCD_MERCHANT_ID
 NULL, -- TBRACCD_TAX_REPT_YEAR
 NULL, -- TBRACCD_TAX_REPT_BOX
 NULL, -- TBRACCD_TAX_AMOUNT
 NULL, -- TBRACCD_TAX_FUTURE_IND
 'TZFEDCA(ACC)', -- TBRACCD_DATA_ORIGIN
 'TZFEDCA(ACC)', -- TBRACCD_CREATE_SOURCE
 NULL, -- TBRACCD_CPDT_IND
 NULL, -- TBRACCD_AIDY_CODE
 VL_STUDY, -- TBRACCD_STSP_KEY_SEQUENCE
 VL_PARTE, -- TBRACCD_PERIOD
 NULL, -- TBRACCD_SURROGATE_ID
 NULL, -- TBRACCD_VERSION
 USER, -- TBRACCD_USER_ID
 NULL ); -- TBRACCD_VPDI_CODE
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR := 'ERROR AL INSERT EN TBRACCD '||SQLERRM;
 END;

 VL_TRAN_NUM:= VL_TRAN_NUM +1;

 END LOOP;


 IF SUBSTR(P_CODIGO,3,2) = 'NA' THEN

 BEGIN
 SELECT NVL(MAX (TZFACCE_SEC_PIDM),0)+1
 INTO VL_TZFACCE_NUM
 FROM TZFACCE
 WHERE TZFACCE_PIDM = P_PIDM;
 EXCEPTION
 WHEN OTHERS THEN
 VL_TRAN_NUM := 1;
 END;

 BEGIN
 SELECT NVL(MAX (TZFACCE_STUDY),1)
 INTO VL_TZFACCE_STUDY
 FROM TZFACCE
 WHERE TZFACCE_PIDM = P_PIDM;
 EXCEPTION
 WHEN OTHERS THEN
 VL_TZFACCE_STUDY := 1;
 END;


 BEGIN
 Insert INTO TZFACCE
 (TZFACCE_PIDM, TZFACCE_SEC_PIDM, TZFACCE_TERM_CODE, TZFACCE_DETAIL_CODE, TZFACCE_DESC,
 TZFACCE_AMOUNT, TZFACCE_EFFECTIVE_DATE, TZFACCE_USER, TZFACCE_ACTIVITY_DATE, TZFACCE_FLAG,
 TZFACCE_STUDY)
 Values
 (P_PIDM, VL_TZFACCE_NUM, VL_PERIODO, P_CODIGO, VL_DESCRI_ACC,
 VL_MONTO_ACC, TRUNC(SYSDATE), 'SV2A', SYSDATE, '0',
 VL_TZFACCE_STUDY);

 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'ERROR INSERTAR TZFACCE'||SQLERRM;
 END;

 END IF;

 ELSE
 DBMS_OUTPUT.PUT_LINE('SIN BENEFICIO');
 END IF;

 END IF;
 COMMIT;

 BEGIN
 SELECT LISTAGG(TBRACCD_TRAN_NUMBER,',')WITHIN GROUP (ORDER BY TBRACCD_TRAN_NUMBER)
 INTO VL_TRANSA
 FROM TBRACCD
 WHERE TBRACCD_DETAIL_CODE = P_CODIGO
 AND TBRACCD_PIDM = P_PIDM;
 END;

 IF VL_ERROR IS NULL THEN
 VL_ERROR:='EXITO';

-- DBMS_OUTPUT.PUT_LINE('SALIDA EXITO '||VL_ERROR||'|'||VL_TRANSA);

 ELSE
-- DBMS_OUTPUT.PUT_LINE('SALIDA ERROR '||VL_ERROR||'|'||VL_TRANSA);
 VL_ERROR:=VL_ERROR;

 END IF;

 RETURN (VL_ERROR);


END F_REACTIVA_UTLX;


 FUNCTION F_INS_CONECTA (P_PIDM NUMBER,
 P_PERIODO VARCHAR2 default null,
 P_CAMPUS VARCHAR2 default null,
 P_NIVEL VARCHAR2 default null,
 P_PROGRAMA VARCHAR2 default null,
 P_CODIGO VARCHAR2 default null,
 P_SERVICIO NUMBER default null,
 P_CARGOS NUMBER default null,
 P_MONTO NUMBER default 0,
 P_DESCUENTO NUMBER default null,
 P_FECHA_INI DATE default null,
 P_ACTIVITY DATE default null,
 P_ORIGEN VARCHAR2 default null,
 P_OBSERVACIONES VARCHAR2 default null,
 P_MESES NUMBER default null,
 P_ESTATUS VARCHAR2 default 'A',
 P_SINCRONIA VARCHAR2 default 0,
 P_MAIL VARCHAR2 DEFAULT NULL,
 P_FRECUENCIA_PAGOS VARCHAR2 DEFAULT NULL,
 P_MONTO_DESC   number DEFAULT NULL ,
 P_NUM_DESC      number DEFAULT NULL ,
 P_NUM_DESC_APLIC  number DEFAULT NULL
 )RETURN VARCHAR2 IS

/*FUNCION QUE INSERTAR ACCESORIO DE CONECTA
AUTOR: GGARCICA
FECHA: 08/02/2021
modificacion: glovicx
se acondiciona la función para que se pueda usar para nuevo flujo de utelx y altas. y bajas.
fecha 18.10.022
-- se agrega el parametro p_descuento al insert x que lo ocupa fernando para buen fin --glovicx 27.10.022
-- se agregan 3 columnas proyecto pantalla de promociones  glovicx 12032024 
*/

VL_ERROR VARCHAR2(900);
VL_CAMPUS VARCHAR2(5);
VL_NIVEL VARCHAR2(3);
VL_PROGRAMA VARCHAR2(15);
VL_PERIODO VARCHAR2(6);
VL_ORDEN NUMBER;
VL_STUDY NUMBER;
VL_INICIO DATE;
VL_PARTE VARCHAR2(4);
VL_CARGOS NUMBER;
VL_SEQNO NUMBER:=0;
VL_APLICADOS NUMBER;
VL_DESC VARCHAR2(50);
VL_ENTRA NUMBER;
VL_UNICO NUMBER;
vl_existe NUMBER:=0;

BEGIN


 Begin

 SELECT DISTINCT A.CAMPUS,
 A.NIVEL,
 A.PROGRAMA,
 B.TZTORDR_TERM_CODE,
 B.TZTORDR_CONTADOR,
 A.SP,
 A.FECHA_INICIO,
 C.SORLCUR_VPDI_CODE
 INTO VL_CAMPUS, VL_NIVEL, VL_PROGRAMA, VL_PERIODO, VL_ORDEN, VL_STUDY, VL_INICIO,VL_PARTE
 FROM TZTPROG A
 JOIN TZTORDR B ON B.TZTORDR_PIDM = A.PIDM AND TZTORDR_CAMPUS = A.CAMPUS AND TZTORDR_NIVEL = A.NIVEL
 AND B.TZTORDR_CONTADOR = (SELECT MAX ( B1.TZTORDR_CONTADOR)
 FROM TZTORDR B1
 WHERE B.TZTORDR_PIDM = B1.TZTORDR_PIDM
 )
 JOIN SORLCUR C ON C.SORLCUR_PIDM = A.PIDM AND C.SORLCUR_PROGRAM = A.PROGRAMA
 AND SORLCUR_LMOD_CODE = 'LEARNER'
 AND SORLCUR_ROLL_IND = 'Y'
 AND SORLCUR_CACT_CODE = 'ACTIVE'
 WHERE 1= 1
 AND A.SP = (SELECT MAX (A1.SP)
 FROM TZTPROG A1
 WHERE A.CAMPUS = A1.CAMPUS
 AND A.NIVEL = A1.NIVEL
 AND A.PIDM = A1.PIDM)
 AND A.PIDM = P_PIDM;


 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 VL_ERROR:='No existe/encuentra información en TZTCOTA para el Pidm '||P_PIDM||'... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM;
 End;


 BEGIN
 SELECT COUNT (1)
 INTO VL_SEQNO
 FROM TZTCOTA
 WHERE TZTCOTA_PIDM = P_PIDM;
 EXCEPTION
 WHEN OTHERS THEN
 VL_SEQNO:=0;
 END;

 VL_SEQNO := VL_SEQNO + 1;


 BEGIN
 SELECT COUNT(*)
 INTO VL_ENTRA
 FROM ZSTPARA
 WHERE ZSTPARA_PARAM_ID = P_CODIGO
 AND ZSTPARA_MAPA_ID = 'MEM_COD'
 AND ZSTPARA_PARAM_VALOR = P_CARGOS;
 EXCEPTION
 WHEN OTHERS THEN
 VL_ENTRA:=0;
 END;


 IF VL_ENTRA > 0 THEN

 BEGIN
 SELECT ZSTPARA_PARAM_VALOR,ZSTPARA_PARAM_DESC
 INTO VL_CARGOS,VL_DESC
 FROM ZSTPARA
 WHERE ZSTPARA_PARAM_ID = P_CODIGO
 AND ZSTPARA_MAPA_ID = 'MEM_COD'
 AND ZSTPARA_PARAM_VALOR = P_CARGOS;
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='No existe/encuentra el código de detalle '||P_CODIGO||' para el agrupador MEM_COD... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM;
 END;

 ELSE

 VL_CARGOS:= P_CARGOS;

 BEGIN
 SELECT COUNT (*)
 INTO VL_UNICO
 FROM TBBDETC
 WHERE TBBDETC_DETAIL_CODE = P_CODIGO
 AND TBBDETC_DESC LIKE '%UNICO%';
 END;

 END IF;


 IF VL_CARGOS >1 THEN VL_APLICADOS:= 1;

 ELSIF
 (VL_DESC = 'UNICO' OR VL_UNICO = 1) THEN VL_APLICADOS:= 1;

 ELSE
 VL_APLICADOS:= NULL;
 END IF;


 IF VL_ERROR IS NULL AND (VL_DESC = 'UNICO' OR VL_UNICO = 1) THEN
 VL_ERROR:= 'FINALIZADO CORRECTAMENTE';
 ELSE
 VL_ERROR:= VL_ERROR;

 END IF;


 BEGIN
 INSERT
 INTO TZTCOTA
 (TZTCOTA_PIDM,
 TZTCOTA_TERM_CODE,
 TZTCOTA_CAMPUS,
 TZTCOTA_NIVEL,
 TZTCOTA_PROGRAMA,
 TZTCOTA_CODIGO,
 TZTCOTA_SERVICIO,
 TZTCOTA_CARGOS,
 TZTCOTA_APLICADOS,
 TZTCOTA_DESCUENTO,
 TZTCOTA_SEQNO,
 TZTCOTA_FLAG,
 TZTCOTA_USER,
 TZTCOTA_ORIGEN,
 TZTCOTA_STATUS,
 TZTCOTA_FECHA_INI,
 TZTCOTA_ACTIVITY,
 TZTCOTA_OBSERVACIONES,
 TZTCOTA_MONTO,
 TZTCOTA_GRATIS,
 GRATIS_APLICADO,
 TZTCOTA_EMAIL,
 TZTCOTA_SINCRONIA,
 TZTCOTA_FREC_PAGO,
 TZTCOTA_MONTO_DESC,
 TZTCOTA_NUM_DESC,
 TZTCOTA_NUM_DESC_APLIC
 )
 VALUES(P_PIDM,
 VL_PERIODO,
 VL_CAMPUS,
 VL_NIVEL,
 VL_PROGRAMA,
 P_CODIGO,
 P_SERVICIO,
 P_CARGOS, --------CARGOS
 VL_APLICADOS, --------CARGOS APLICADOS
 P_DESCUENTO, --------DESCUENTO
 VL_SEQNO,
 0,
 substr(USER,1,10), --validacion se la puso glovicx 18.08.022 x que esta tronando ya que hay muchos user con mas de 10 caracteres
 P_ORIGEN,
 P_ESTATUS, --'A', se cambio x parametro glovicx 18.10.022
 VL_INICIO,
 sysdate,
 VL_ERROR||' - '||P_OBSERVACIONES,
 P_MONTO,
 P_MESES,
 null,
 P_MAIL,
 P_SINCRONIA,
 P_FRECUENCIA_PAGOS,
 P_MONTO_DESC,
 P_NUM_DESC,
 P_NUM_DESC_APLIC
 );

 VL_ERROR:='EXITO';

 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR AL INSERTAR = '||SQLERRM;
 END;

 IF VL_ERROR IS NULL THEN
 VL_ERROR:='EXITO';
 ELSE
 VL_ERROR:=VL_ERROR;
 END IF;


 Begin
 Select count(1)
 Into vl_existe
 from GENERAL.GORADID
 Where GORADID_PIDM = P_PIDM
 And GORADID_ADID_CODE = P_ORIGEN;

 Exception
 When Others then
 vl_existe :=0;
 End;

 -----esta seccion se agrego para manejar el flujo de las etiquetas de conecta glovicx 18.10.022
 IF VL_ERROR='EXITO' AND P_ESTATUS = 'I' THEN ---AQUI HAY UNA BAJA INACTIVO SE BORRA LA ETIQUETA

 If vl_existe >= 1 then

 begin
 DELETE
 FROM GORADID
 WHERE 1=1
 AND GORADID_PIDM = P_PIDM
 And GORADID_ADID_CODE = P_ORIGEN;

 Exception
 When others then
 VL_ERROR :='Error al borrar la Etiqueta'||sqlerrm;
 NULL;
 end;
 End if;
 ELSE
 NULL;

 END IF;





 RETURN(VL_ERROR);

-- DBMS_OUTPUT.PUT_LINE(VL_ERROR);
COMMIT;
END F_INS_CONECTA;
PROCEDURE P_CONECTA (P_pidm number DEFAULT NULL) IS
/*PROCEDIMIENTO GENERA CARGO DE CONECTA
AUTOR: GGARCICA
FECHA: 07/02/2022*/

VL_ERROR VARCHAR2(3237);
VL_SECUENCIA NUMBER;
VL_FECHA DATE;
VL_TRAN_NUM NUMBER:= 1;
VL_ORDEN NUMBER;
VL_MESES NUMBER;
VL_PROGRAMA VARCHAR2(15);
VL_PERIODO VARCHAR2(6);
VL_STUDY NUMBER;
VL_INICIO DATE;
VL_PARTE VARCHAR2(5);
VL_PARTE_1 VARCHAR2(5);
VL_EXISTE_CODIGO NUMBER;
VL_RATE VARCHAR2(6);
VL_DIA NUMBER;
VL_MES NUMBER;
VL_ANO NUMBER;
VL_OBSERVACIONES VARCHAR2(30);
VL_BITACORA VARCHAR2(20);
VL_NUM_CARG VARCHAR2(9);
VL_PROCESA VARCHAR2(15);
VL_CODIGO VARCHAR2(4);
VL_DESC VARCHAR2(100);
VL_DESC_NTCR VARCHAR2(100);
vl_gratis number:=0;
VL_SECUENCIA_ntcr number:=0;
vl_fecha_fut date;
vl_existe_salud number:=0;

BEGIN

 FOR X IN (

 
             SELECT DISTINCT matricula spriden_id , 
             TZTCOTA_PIDM MATRICULA,
             TZTCOTA_CODIGO CODIGO,
             TZTCOTA_SEQNO,
             nvl (TZTCOTA_APLICADOS,1) APLICADOS,
             nvl (TZTCOTA_CARGOS,0) CARGOS,
             TBBDETC_DESC DESCR,
             CASE 
             When TBBDETC_DESC like '%CONECTA%' then 
             TBBDETC_AMOUNT 
             When TBBDETC_DESC not like '%CONECTA%' then 
             FLOOR(TBBDETC_AMOUNT/TZTCOTA_CARGOS) 
             End MONTO,
             TVRDCTX_CURR_CODE MONEDA,
             TZTCOTA_OBSERVACIONES,
             TZTCOTA_ACTIVITY Registro,
             nvl (TZTCOTA_GRATIS,0) Gratis_Generado,
             TZTCOTA_ORIGEN Accesorio,
             nvl (GRATIS_APLICADO,0) gratis_apl,
             case
             when length (SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC) = 4 then 
             SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC
             when length (SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC) != 4 then
             null
             End Cdo_canc, 
             'X' uno,
             e.estatus,
              case 
                 when trim (a.TZTCOTA_FREC_PAGO) = 'SEMESTRAL RECURRENTE' then 
                      '6'
                 when trim (a.TZTCOTA_FREC_PAGO) = 'MES RECURRENTE' then   
                       '1'
                 when trim (a.TZTCOTA_FREC_PAGO) = 'ANUAL RECURRENTE' then   
                       '12'
                 when trim (a.TZTCOTA_FREC_PAGO) is null  then   
                       '1'
              End periodicidad             
             FROM TZTCOTA A
             Join TBBDETC on TBBDETC_DETAIL_CODE = A.TZTCOTA_CODIGO 
             Join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
             join tztprog e on e.pidm = a.TZTCOTA_PIDM and e.estatus = 'MA' and e.sp = (select max (e1.sp)
                                                                                         from tztprog e1
                                                                                         Where e.pidm = e1.pidm
                                                                                       )
            join SZVCAMP on SZVCAMP_CAMP_CODE = e.campus                                                                           
             left join ZSTPARA e on e.ZSTPARA_PARAM_VALOR = a.TZTCOTA_ORIGEN and e.ZSTPARA_MAPA_ID = 'COD_MESGRATIS' 
             WHERE 1=1
             AND A.TZTCOTA_STATUS = 'A'
             AND A.TZTCOTA_SEQNO = (SELECT MAX(a1.TZTCOTA_SEQNO)
                                     FROM TZTCOTA a1
                                     WHERE a1.TZTCOTA_PIDM = A.TZTCOTA_PIDM
                                     AND a1.TZTCOTA_CODIGO = A.TZTCOTA_CODIGO
                                     --AND a1.TZTCOTA_STATUS = 'A'
                                     )
             And a.TZTCOTA_CARGOS is not null
             and a.TZTCOTA_MONTO is null
              And a.TZTCOTA_PIDM not in (select goradid_pidm
                                                    from GORADID
                                                    Where 1=1
                                                    And GORADID_ADID_CODE ='SBTI' ----> Se excluyen a los alumnos que cuenten con la etiqueta de Retencion 
                                                    )                        
             And a.TZTCOTA_PIDM = nvl (P_pidm, a.TZTCOTA_PIDM)
             union
             SELECT DISTINCT e.matricula spriden_id , 
             TZTCOTA_PIDM MATRICULA,
             TZTCOTA_CODIGO CODIGO,
             TZTCOTA_SEQNO,
             nvl (TZTCOTA_APLICADOS,1) APLICADOS,
             nvl(TZTCOTA_CARGOS,0) CARGOS,
             TBBDETC_DESC DESCR,
             TZTCOTA_MONTO MONTO,
             TVRDCTX_CURR_CODE MONEDA,
             TZTCOTA_OBSERVACIONES,
             trunc (TZTCOTA_ACTIVITY) Registro,
             nvl (TZTCOTA_GRATIS,0) Gratis_Generado,
             TZTCOTA_ORIGEN Accesorio,
             nvl (GRATIS_APLICADO,0) gratis_apl,
             case
             when length (SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC) = 4 then 
             SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC
             when length (SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC) != 4 then
             null
             End Cdo_canc, 
             'Y' uno,
              e.estatus,
              case 
                 when trim (a.TZTCOTA_FREC_PAGO) = 'SEMESTRAL RECURRENTE' then 
                      '6'
                 when trim (a.TZTCOTA_FREC_PAGO) = 'MES RECURRENTE' then   
                       '1'
                 when trim (a.TZTCOTA_FREC_PAGO) = 'ANUAL RECURRENTE' then   
                       '12'
                 when trim (a.TZTCOTA_FREC_PAGO) is null  then   
                       '1'
              End periodicidad      
             FROM TZTCOTA A
             Join TBBDETC on TBBDETC_DETAIL_CODE = A.TZTCOTA_CODIGO 
             Join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
             join tztprog e on e.pidm = a.TZTCOTA_PIDM and e.estatus = 'MA' and e.sp = (select max (e1.sp)
                                                                                         from tztprog e1
                                                                                         Where e.pidm = e1.pidm
                                                                                       ) left join ZSTPARA e on e.ZSTPARA_PARAM_VALOR = a.TZTCOTA_ORIGEN and e.ZSTPARA_MAPA_ID = 'COD_MESGRATIS' 
            left join ZSTPARA e on e.ZSTPARA_PARAM_VALOR = a.TZTCOTA_ORIGEN and e.ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
            join SZVCAMP on SZVCAMP_CAMP_CODE = e.campus                                                                           
             WHERE 1=1
             AND A.TZTCOTA_STATUS = 'A'
             AND A.TZTCOTA_SEQNO = (SELECT MAX(a1.TZTCOTA_SEQNO)
                                     FROM TZTCOTA a1
                                     WHERE a1.TZTCOTA_PIDM = A.TZTCOTA_PIDM
                                     AND a1.TZTCOTA_CODIGO = A.TZTCOTA_CODIGO
                                     )
             And TZTCOTA_CARGOS is not null
             and TZTCOTA_MONTO is not null
              And a.TZTCOTA_PIDM not in (select goradid_pidm
                                                    from GORADID
                                                    Where 1=1
                                                    And GORADID_ADID_CODE ='SBTI' ----> Se excluyen a los alumnos que cuenten con la etiqueta de Retencion 
                                                    )               
             And a.TZTCOTA_PIDM = nvl (P_pidm, a.TZTCOTA_PIDM)
             -- And spriden_id ='010308550'
             union
             SELECT DISTINCT e.matricula spriden_id , 
             TZTCOTA_PIDM MATRICULA,
             TZTCOTA_CODIGO CODIGO,
             TZTCOTA_SEQNO,
             nvl (TZTCOTA_APLICADOS,1) APLICADOS,
             nvl(TZTCOTA_CARGOS,0) CARGOS,
             TBBDETC_DESC DESCR,
             TZTCOTA_MONTO MONTO,
             TVRDCTX_CURR_CODE MONEDA,
             TZTCOTA_OBSERVACIONES,
             trunc (TZTCOTA_ACTIVITY) Registro,
             nvl (TZTCOTA_GRATIS,0) Gratis_Generado,
             TZTCOTA_ORIGEN Accesorio,
             nvl (GRATIS_APLICADO,0) gratis_apl,
             case
             when length (SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC) = 4 then 
             SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC
             when length (SZVCAMP_CAMP_ALT_CODE||e.ZSTPARA_PARAM_DESC) != 4 then
             null
             End Cdo_canc, 
             'Y' uno,
              e.estatus,
              case 
                 when trim (a.TZTCOTA_FREC_PAGO) = 'SEMESTRAL RECURRENTE' then 
                      '6'
                 when trim (a.TZTCOTA_FREC_PAGO) = 'MES RECURRENTE' then   
                       '1'
                 when trim (a.TZTCOTA_FREC_PAGO) = 'ANUAL RECURRENTE' then   
                       '12'
                 when trim (a.TZTCOTA_FREC_PAGO) is null  then   
                       '1'
              End periodicidad      
             FROM TZTCOTA A
             Join TBBDETC on TBBDETC_DETAIL_CODE = A.TZTCOTA_CODIGO 
             Join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
             join tztprog e on e.pidm = a.TZTCOTA_PIDM and e.estatus = 'EG' and e.sp = (select max (e1.sp)
                                                                                         from tztprog e1
                                                                                         Where e.pidm = e1.pidm
                                                                                       ) left join ZSTPARA e on e.ZSTPARA_PARAM_VALOR = a.TZTCOTA_ORIGEN and e.ZSTPARA_MAPA_ID = 'COD_MESGRATIS' 
            left join ZSTPARA e on e.ZSTPARA_PARAM_VALOR = a.TZTCOTA_ORIGEN and e.ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
            join SZVCAMP on SZVCAMP_CAMP_CODE = e.campus                                                                           
             WHERE 1=1
             AND A.TZTCOTA_STATUS = 'A'
             AND A.TZTCOTA_SEQNO = (SELECT MAX(a1.TZTCOTA_SEQNO)
                                     FROM TZTCOTA a1
                                     WHERE a1.TZTCOTA_PIDM = A.TZTCOTA_PIDM
                                     AND a1.TZTCOTA_CODIGO = A.TZTCOTA_CODIGO
                                     )
             And TZTCOTA_CARGOS is not null
             and TZTCOTA_MONTO is not null
             And TZTCOTA_CODIGO in (select ZSTPARA_PARAM_ID from ZSTPARA where 1=1 and  ZSTPARA_MAPA_ID = 'RECU_EGRESADO')
              And a.TZTCOTA_PIDM not in (select goradid_pidm
                                                    from GORADID
                                                    Where 1=1
                                                    And GORADID_ADID_CODE ='SBTI' ----> Se excluyen a los alumnos que cuenten con la etiqueta de Retencion 
                                                    )               
             And a.TZTCOTA_PIDM = nvl (P_pidm, a.TZTCOTA_PIDM)
             --And matricula ='010006448'
             order by 3 


 )LOOP


         VL_ERROR := NULL;
         VL_SECUENCIA := NULL;
         VL_FECHA := NULL;
         VL_TRAN_NUM := NULL;
         VL_ORDEN := NULL;
         VL_MESES := NULL;
         VL_PROGRAMA := NULL;
         VL_PERIODO := NULL;
         VL_STUDY := NULL;
         VL_INICIO := NULL;
         VL_PARTE := NULL;
         VL_PARTE_1 := NULL;
         VL_EXISTE_CODIGO:= NULL;
         VL_RATE := NULL;
         VL_DIA := NULL;
         VL_MES := NULL;
         VL_ANO := NULL;
         VL_OBSERVACIONES:= NULL;
         VL_BITACORA := NULL;
         VL_NUM_CARG := NULL;
         VL_PROCESA := NULL;
         VL_CODIGO := NULL;
         VL_DESC := NULL;
         VL_DESC_NTCR := NULL;

            DBMS_OUTPUT.PUT_LINE('ENtra al PROCESO');

         BEGIN
             SELECT ZSTPARA_PARAM_VALOR,TBBDETC_DESC
                 INTO VL_CODIGO,VL_DESC
             FROM ZSTPARA,TBBDETC
             WHERE ZSTPARA_PARAM_VALOR = TBBDETC_DETAIL_CODE
             AND ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
             AND ZSTPARA_PARAM_ID = X.CODIGO;
         EXCEPTION
         WHEN OTHERS THEN
             VL_CODIGO:= null;
             VL_DESC:= null;
         END;

         If VL_CODIGO is null then 
             VL_CODIGO:=X.CODIGO;
             VL_DESC:=X.DESCR;
         end if;


       --------------- Se eliminan los decuentos que llegan desde paquete Fijo para los accesorios de este agrupador poque se suman al registrar en cota  
          vl_existe_salud:=0;
          Begin
                select count(*) 
                    Into vl_existe_salud
                from zstpara
                where ZSTPARA_MAPA_ID = 'COD_MEMB_SALUD'
                and ZSTPARA_PARAM_ID||ZSTPARA_PARAM_VALOR = VL_CODIGO;
          Exception
            When Others then 
              vl_existe_salud:=0;
          End;       

          
          If vl_existe_salud > 0 then 
          
                Begin 
                    delete SWTMDAC a
                    where a.SWTMDAC_PIDM =X.MATRICULA
                    And a.SWTMDAC_DETAIL_CODE_ACC = VL_CODIGO;
                Exception
                    When Others then
                     null;
                    DBMS_OUTPUT.PUT_LINE('Error al Borrar en SWTMDAC'||sqlerrm );    
                End;            
          End if;

         Begin

             Select distinct max (SFRSTCR_PTRM_CODE)
             Into VL_PARTE_1
             from sfrstcr a
             where 1= 1
             And a.SFRSTCR_PIDM = X.MATRICULA
             And substr (a.SFRSTCR_TERM_CODE, 5,1) not in ('9','8')
             And a.SFRSTCR_TERM_CODE = (select max (a1.SFRSTCR_TERM_CODE)
             from SFRSTCR a1
             join ssbsect a2 on a2.SSBSECT_TERM_CODE = a1.SFRSTCR_TERM_CODE and a2.SSBSECT_CRN = a1.SFRSTCR_CRN
             Where a.SFRSTCR_PIDM = a1.SFRSTCR_PIDM
             );
         DBMS_OUTPUT.PUT_LINE('Parte_Periodo: '||VL_PARTE_1);
         Exception
         When Others then
         VL_PARTE_1:= null;
         End;

            VL_FECHA:= TRUNC(SYSDATE);   ---Restar los 30 para el mes anterior -30  MACANA

         Begin
             Select distinct a.programa, b.TZTORDR_TERM_CODE, b. TZTORDR_CONTADOR, a.sp, 
                          case when substr (nvl (a.FECHA_PRIMERA, a.FECHA_INICIO), 1, 2) <20 then 
                  nvl (a.FECHA_PRIMERA, a.FECHA_INICIO)
                when substr (nvl (a.FECHA_PRIMERA, a.FECHA_INICIO), 1, 2) between 20 and 25 then                  
                    nvl (a.FECHA_PRIMERA, a.FECHA_INICIO)  +12
                when substr (nvl (a.FECHA_PRIMERA, a.FECHA_INICIO), 1, 2) between 26 and 31 then                  
                    nvl (a.FECHA_PRIMERA, a.FECHA_INICIO)  +9
             End case, ---> Se agrega el 12 para brincar de mes a las fechas posteriores del 20
             c.SORLCUR_VPDI_CODE,nvl (b.TZTORDR_RATE, sorlcur_rate_code) rate 
             Into VL_PROGRAMA, VL_PERIODO, VL_ORDEN, VL_STUDY, VL_INICIO,VL_PARTE,VL_RATE
             from tztprog a
             left join TZTORDR b on b.TZTORDR_PIDM = a.pidm and TZTORDR_CAMPUS = a.campus and TZTORDR_NIVEL = a.nivel
             And b.TZTORDR_CONTADOR = (select max ( b1.TZTORDR_CONTADOR)
             from TZTORDR b1
             where b.TZTORDR_PIDM = b1.TZTORDR_PIDM
             )
             join sorlcur c on c.sorlcur_pidm = a.pidm and c.SORLCUR_PROGRAM = a.programa
             AND SORLCUR_LMOD_CODE = 'LEARNER'
             AND SORLCUR_ROLL_IND = 'Y'
             AND SORLCUR_CACT_CODE = 'ACTIVE'
             where 1= 1
             And a.sp = (select max (a1.sp)
             from tztprog a1
             Where a.campus = a1.campus
             And a.pidm = a1.pidm)
             And a.pidm = X.MATRICULA;       
         Exception
         When Others then
             VL_PROGRAMA := null;
             VL_PERIODO:= null;
             VL_ORDEN:= null;
             VL_STUDY:= null;
             VL_INICIO:= null;
             VL_PARTE:= null;
             VL_RATE:=null;
             VL_ERROR:=SQLERRM;
         End;

        If VL_PERIODO is null and VL_ORDEN is null then 
        
            Begin
                Select distinct TBRACCD_TERM_CODE, TBRACCD_RECEIPT_NUMBER
                    Into VL_PERIODO, VL_ORDEN
                from tztprog a
                join tbraccd b on b.tbraccd_pidm = a.pidm and b.TBRACCD_STSP_KEY_SEQUENCE = a.sp and b.TBRACCD_TRAN_NUMBER = (select max (b1.TBRACCD_TRAN_NUMBER)
                                                                                                                                from tbraccd b1
                                                                                                                                where 1=1
                                                                                                                                and b1.tbraccd_pidm =  b.tbraccd_pidm 
                                                                                                                                And b1.TBRACCD_STSP_KEY_SEQUENCE = b.TBRACCD_STSP_KEY_SEQUENCE)
                where 1=1 
                and a.programa = VL_PROGRAMA
                And a.pidm = X.MATRICULA  
                And a.sp = VL_STUDY;
            Exception
                WHen Others then 
                 VL_PERIODO:= null;
                 VL_ORDEN:= null;                    
            End;
        
        
        End if;
        


         If VL_PARTE_1 is not null then
            VL_PARTE:= VL_PARTE_1;
         End if;

        If x.periodicidad = 1 then  ---> Macana
        
             Begin
                 Select count(*)  
                 Into VL_EXISTE_CODIGO
                 from tbraccd
                 where 1= 1
                 and tbraccd_pidm =  X.MATRICULA
                 And tbraccd_detail_code =VL_CODIGO
                 And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE));   --> Macana 30
             Exception
             When Others then 
             VL_EXISTE_CODIGO:=0; 
             End;   
 
         DBMS_OUTPUT.PUT_LINE('Periodicidad: '||x.periodicidad ||'*'||VL_EXISTE_CODIGO);
 
        ElsIf x.periodicidad != 1 then --> Macana
            Begin     
            
                Select ADD_MONTHS (trunc (TBRACCD_EFFECTIVE_DATE,'MM'), x.periodicidad) fecha
                 Into vl_fecha_fut
                from tbraccd a
                where a.tbraccd_pidm = X.MATRICULA
                And a.tbraccd_detail_code = VL_CODIGO
                And a.TBRACCD_TRAN_NUMBER = (select max (a1.TBRACCD_TRAN_NUMBER)
                                             from tbraccd a1
                                             Where a.tbraccd_pidm = a1.tbraccd_pidm
                                             And a.tbraccd_detail_code = a1.tbraccd_detail_code);        

            Exception 
                When Others then 
                    vl_fecha_fut:= null;
            End;

            DBMS_OUTPUT.PUT_LINE('Periodicidad: '||x.periodicidad ||'*'||vl_fecha_fut);


            If vl_fecha_fut is not null and vl_fecha_fut = TRUNC(SYSDATE, 'MM') then  --------> 30 Macana 
            
              DBMS_OUTPUT.PUT_LINE('Primer IF: '||vl_fecha_fut ||'*'||TRUNC(SYSDATE, 'MM'));
            
               VL_EXISTE_CODIGO:=0;
                 
                 Begin
                     Select count(*)
                     Into VL_EXISTE_CODIGO
                     from tbraccd
                     where 1= 1
                     and tbraccd_pidm = X.MATRICULA
                     And tbraccd_detail_code = VL_CODIGO 
                     And trunc (TBRACCD_EFFECTIVE_DATE) between vl_fecha_fut and TRUNC(LAST_DAY(vl_fecha_fut));
                 Exception
                 When Others then 
                 VL_EXISTE_CODIGO:=0; 
                 End;                 
               
               DBMS_OUTPUT.PUT_LINE('Valida IF : '||VL_EXISTE_CODIGO);
               
            Else
              VL_EXISTE_CODIGO := 1;
               DBMS_OUTPUT.PUT_LINE('ELSE IF : '||VL_EXISTE_CODIGO);
                
            End if; 

       
        End if;
       

 DBMS_OUTPUT.PUT_LINE('EXISTE CODIGO ='||VL_EXISTE_CODIGO);

     BEGIN
         SELECT TO_CHAR (TO_DATE(VL_FECHA),'MM')-TO_CHAR(TBRACCD_EFFECTIVE_DATE,'MM')+12 MES
            INTO VL_MESES
         FROM TBRACCD A
         WHERE A.TBRACCD_PIDM = X.MATRICULA
         AND A.TBRACCD_DETAIL_CODE = VL_CODIGO
         AND A.TBRACCD_TRAN_NUMBER = (SELECT MAX (TBRACCD_TRAN_NUMBER)
                                         FROM TBRACCD
                                         WHERE TBRACCD_PIDM = A.TBRACCD_PIDM
                                         AND TBRACCD_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
                                         AND (TBRACCD_CREATE_SOURCE IN ('TZFEDCA(ACC)','ACC_DIFER')
                                         OR TBRACCD_CREATE_SOURCE IS NULL));
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR AL CALCULAR MESES'||SQLERRM;
     END;
     
     VL_ERROR:= null;


     Begin 
        ------ Si meses esta vacio se toma el valor de Sysdate -------------
        Select to_char (sysdate, 'mm')   ---Restar los 30 para el mes anterior -30 MACANA
          Into VL_MESES
        from dual;
     Exception
        When Others then 
           VL_MESES:= null;
     End;

 DBMS_OUTPUT.PUT_LINE('EXISTE CODIGO ='||VL_EXISTE_CODIGO);

     IF VL_MESES >= 13 THEN
        VL_MESES := 1;
     ELSE
        VL_MESES:=VL_MESES;
     END IF;

DBMS_OUTPUT.PUT_LINE('Mesess: '||VL_MESES);

 IF (X.APLICADOS < X.CARGOS OR X.CARGOS = 1) THEN
  DBMS_OUTPUT.PUT_LINE('Detalle cargos: '||X.APLICADOS ||'*'||X.CARGOS);
     IF VL_MESES > 0 THEN
      DBMS_OUTPUT.PUT_LINE('Entra detalle meses: '||VL_MESES);
      DBMS_OUTPUT.PUT_LINE('Definicio : '||X.CARGOS ||'*'||X.APLICADOS||'# '||VL_EXISTE_CODIGO ||'$ '||VL_PROCESA||'%'||VL_CODIGO||'&'||SUBSTR(VL_PERIODO,1,2)||'**'||VL_MESES); 
           CASE
             WHEN X.CARGOS = X.APLICADOS THEN VL_PROCESA:= 'NO APLICA';
             DBMS_OUTPUT.PUT_LINE('no_aplica1'||X.CARGOS ||'*'||X.APLICADOS );
             WHEN VL_EXISTE_CODIGO >= 1 THEN VL_PROCESA:= ' NO APLICA';
             DBMS_OUTPUT.PUT_LINE('no_aplica2'||VL_EXISTE_CODIGO );
             WHEN VL_CODIGO = SUBSTR(VL_PERIODO,1,2)||'B3' AND VL_MESES
             IN (6,12,18,24,30,36,42,48,54,60,66,72,78,84,90,96) THEN VL_PROCESA:= 'APLICA';
             WHEN VL_CODIGO != SUBSTR(VL_PERIODO,1,2)||'B3' AND VL_MESES >0 THEN VL_PROCESA:= 'APLICA';
             DBMS_OUTPUT.PUT_LINE('Salida Case: '||VL_PROCESA);
           ELSE
            VL_MESES:=0;
            DBMS_OUTPUT.PUT_LINE('Entre Else Case: '||VL_PROCESA);
           END CASE;

             VL_DIA := CASE SUBSTR(VL_RATE,4,1) WHEN 'A' THEN 15 WHEN 'B' THEN 30 WHEN 'C' THEN 10 END;
             VL_MES :=SUBSTR (TO_CHAR(VL_FECHA, 'dd/mm/rrrr'), 4, 2);
             VL_ANO :=SUBSTR (TO_CHAR(VL_FECHA, 'dd/mm/rrrr'), 7, 4);

 DBMS_OUTPUT.PUT_LINE('rate: '||VL_RATE);
 DBMS_OUTPUT.PUT_LINE('Dia: '||VL_DIA);
 DBMS_OUTPUT.PUT_LINE('mes: '||VL_MES);
 DBMS_OUTPUT.PUT_LINE('año: '||VL_ANO);
 DBMS_OUTPUT.PUT_LINE('PROCESA: '||VL_PROCESA);

           IF VL_PROCESA = 'APLICA' AND VL_MESES != 0 and VL_RATE is not null THEN
 DBMS_OUTPUT.PUT_LINE('Entre Proceso aplica: '||VL_MESES);
             FOR I IN 1..X.CARGOS LOOP
                 DBMS_OUTPUT.PUT_LINE('vueltas '||I);
              EXIT WHEN I > 1;


                         BEGIN
                         SELECT MAX(TBRACCD_TRAN_NUMBER)+1
                             INTO VL_SECUENCIA
                         FROM TBRACCD WHERE TBRACCD_PIDM = X.MATRICULA;
                         EXCEPTION
                         WHEN OTHERS THEN
                             VL_SECUENCIA:= 0;
                         END;

             DBMS_OUTPUT.PUT_LINE('Secuencia '||VL_SECUENCIA);

                         IF VL_DIA = '30' THEN
                             VL_FECHA := TO_DATE((CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO),'DD/MM/YYYY');
                         ELSE
                             VL_FECHA := TO_DATE((VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO),'DD/MM/YYYY');
                         END IF;


                         CASE
                         WHEN X.CARGOS = 1 THEN 
                            VL_NUM_CARG:= 'RECURRE';
                         ELSE
                             VL_NUM_CARG:= (X.APLICADOS +1 ) ||' | '|| X.CARGOS ;
                             VL_BITACORA:= (X.APLICADOS + 1);
                         END CASE;

                       DBMS_OUTPUT.PUT_LINE('Valor de Fecha  '||VL_FECHA);
                       DBMS_OUTPUT.PUT_LINE('Valor de Fecha inicio  '||VL_INICIO);


--VL_INICIO := trunc(sysdate-1);--- pruebas
                   If VL_FECHA <= VL_INICIO then     ---Valida que la fecha del cargo sea mayor  a la fecha de inicio
                      null;
                          DBMS_OUTPUT.PUT_LINE('entre al null');
                   Else 
                            
                         BEGIN
                          DBMS_OUTPUT.PUT_LINE('entre a insertar el cargo del mes');

                             INSERT INTO TBRACCD
                             VALUES ( X.MATRICULA, -- TBRACCD_PIDM
                             VL_SECUENCIA, -- TBRACCD_TRAN_NUMBER
                             VL_PERIODO, -- TBRACCD_TERM_CODE
                             VL_CODIGO, -- TBRACCD_DETAIL_CODE
                             USER, -- TBRACCD_USER
                             SYSDATE, -- TBRACCD_ENTRY_DATE
                             NVL(X.MONTO,0), -- TBRACCD_AMOUNT
                             NVL(X.MONTO,0), -- TBRACCD_BALANCE
                             TO_DATE(VL_FECHA,'DD/MM/RRRR'), -- TBRACCD_EFFECTIVE_DATE
                             NULL, -- TBRACCD_BILL_DATE
                             NULL, -- TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                             VL_DESC, -- TBRACCD_DESC
                             VL_ORDEN, -- TBRACCD_RECEIPT_NUMBER
                             NULL, -- TBRACCD_TRAN_NUMBER_PAID
                             NULL, -- TBRACCD_CROSSREF_PIDM
                             NULL, -- TBRACCD_CROSSREF_NUMBER
                             NULL, -- TBRACCD_CROSSREF_DETAIL_CODE
                             'T', -- TBRACCD_SRCE_CODE
                             'Y', -- TBRACCD_ACCT_FEED_IND
                             SYSDATE, -- TBRACCD_ACTIVITY_DATE
                             0, -- TBRACCD_SESSION_NUMBER
                             NULL, -- TBRACCD_CSHR_END_DATE
                             NULL, -- TBRACCD_CRN
                             NULL, -- TBRACCD_CROSSREF_SRCE_CODE
                             NULL, -- TBRACCD_LOC_MDT
                             NULL, -- TBRACCD_LOC_MDT_SEQ
                             NULL, -- TBRACCD_RATE
                             NULL, -- TBRACCD_UNITS
                             NULL, -- TBRACCD_DOCUMENT_NUMBER
                             TO_DATE(VL_FECHA,'DD/MM/RRRR'), -- TBRACCD_TRANS_DATE
                             NULL, -- TBRACCD_PAYMENT_ID
                             NULL, -- TBRACCD_INVOICE_NUMBER
                             NULL, -- TBRACCD_STATEMENT_DATE
                             NULL, -- TBRACCD_INV_NUMBER_PAID
                             X.MONEDA, -- TBRACCD_CURR_CODE
                             NULL, -- TBRACCD_EXCHANGE_DIFF
                             NULL, -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                             NULL, -- TBRACCD_LATE_DCAT_CODE
                             VL_INICIO, -- TBRACCD_FEED_DATE
                             VL_NUM_CARG, --TBRACCD_FEED_DOC_CODE
                             NULL, -- TBRACCD_ATYP_CODE
                             NULL, -- TBRACCD_ATYP_SEQNO
                             NULL, -- TBRACCD_CARD_TYPE_VR
                             NULL, -- TBRACCD_CARD_EXP_DATE_VR
                             NULL, -- TBRACCD_CARD_AUTH_NUMBER_VR
                             NULL, -- TBRACCD_CROSSREF_DCAT_CODE
                             NULL, -- TBRACCD_ORIG_CHG_IND
                             NULL, -- TBRACCD_CCRD_CODE
                             NULL, -- TBRACCD_MERCHANT_ID
                             NULL, -- TBRACCD_TAX_REPT_YEAR
                             NULL, -- TBRACCD_TAX_REPT_BOX
                             NULL, -- TBRACCD_TAX_AMOUNT
                             NULL, -- TBRACCD_TAX_FUTURE_IND
                             'TZFEDCA(ACC)', -- TBRACCD_DATA_ORIGIN
                             'TZFEDCA(ACC)', -- TBRACCD_CREATE_SOURCE
                             NULL, -- TBRACCD_CPDT_IND
                             NULL, -- TBRACCD_AIDY_CODE
                             VL_STUDY, -- TBRACCD_STSP_KEY_SEQUENCE
                             VL_PARTE, -- TBRACCD_PERIOD
                             NULL, -- TBRACCD_SURROGATE_ID
                             NULL, -- TBRACCD_VERSION
                             USER, -- TBRACCD_USER_ID
                             NULL ); -- TBRACCD_VPDI_CODE
                             VL_ERROR:= null;
                         EXCEPTION
                         WHEN OTHERS THEN
                         VL_ERROR := 'Se presento ERROR INSERT TBRACCD '||SQLERRM;
                         END;

                        VL_TRAN_NUM:= VL_TRAN_NUM +1;
                
                   End if;

             END LOOP;


       If VL_FECHA <= VL_INICIO then     ---Valida que la fecha del cargo sea mayor  a la fecha de inicio
          null;
       Else  


            IF VL_ERROR IS NULL THEN
                 DBMS_OUTPUT.PUT_LINE('Entro a insertar Nota ' ||VL_ERROR);
                 ----------------- Se registran los meses gratis ---------------------
                  DBMS_OUTPUT.PUT_LINE('Gratis Generado' ||x.gratis_generado);
                 If x.gratis_generado >0 then 
                        DBMS_OUTPUT.PUT_LINE('Gratis X Generado' ||(x.gratis_apl) ||'*'|| (x.gratis_generado));
                     If (x.gratis_apl) < (x.gratis_generado) then  
                          --DBMS_OUTPUT.PUT_LINE('Entro a Generar NTCR');
                         Begin
                             Select distinct tbbdetc_Desc
                             Into VL_DESC_NTCR
                             from tbbdetc 
                             where tbbdetc_detail_code = x.cdo_canc;
                         Exception
                         When Others then 
                             VL_DESC_NTCR:= null; 
                         end;
 
                         VL_SECUENCIA_ntcr :=0;
                         BEGIN
                             SELECT MAX(TBRACCD_TRAN_NUMBER)+1
                                 INTO VL_SECUENCIA_ntcr
                             FROM TBRACCD WHERE TBRACCD_PIDM = X.MATRICULA;
                         EXCEPTION
                         WHEN OTHERS THEN
                             VL_SECUENCIA_ntcr:= 0;
                         END;
                         
                          DBMS_OUTPUT.PUT_LINE('Genero Secuencia ' ||VL_SECUENCIA_ntcr||'*'||VL_SECUENCIA);
                         ----------------------- GEnero la nota de credito para saldar el accesorio ----------------
                        
                         
                         BEGIN

                         INSERT INTO TBRACCD
                         VALUES ( X.MATRICULA, -- TBRACCD_PIDM
                                 VL_SECUENCIA_ntcr, -- TBRACCD_TRAN_NUMBER
                                 VL_PERIODO, -- TBRACCD_TERM_CODE
                                 x.cdo_canc, -- TBRACCD_DETAIL_CODE
                                 USER, -- TBRACCD_USER
                                 SYSDATE, -- TBRACCD_ENTRY_DATE
                                 NVL(X.MONTO,0), -- TBRACCD_AMOUNT
                                 NVL(X.MONTO,0)*-1, -- TBRACCD_BALANCE
                                 TO_DATE(sysdate,'DD/MM/RRRR'), -- TBRACCD_EFFECTIVE_DATE
                                 NULL, -- TBRACCD_BILL_DATE
                                 NULL, -- TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                 VL_DESC_NTCR, -- TBRACCD_DESC
                                 VL_ORDEN, -- TBRACCD_RECEIPT_NUMBER
                                 VL_SECUENCIA, -- TBRACCD_TRAN_NUMBER_PAID
                                 NULL, -- TBRACCD_CROSSREF_PIDM
                                 NULL, -- TBRACCD_CROSSREF_NUMBER
                                 NULL, -- TBRACCD_CROSSREF_DETAIL_CODE
                                 'T', -- TBRACCD_SRCE_CODE
                                 'Y', -- TBRACCD_ACCT_FEED_IND
                                 SYSDATE, -- TBRACCD_ACTIVITY_DATE
                                 0, -- TBRACCD_SESSION_NUMBER
                                 NULL, -- TBRACCD_CSHR_END_DATE
                                 NULL, -- TBRACCD_CRN
                                 NULL, -- TBRACCD_CROSSREF_SRCE_CODE
                                 NULL, -- TBRACCD_LOC_MDT
                                 NULL, -- TBRACCD_LOC_MDT_SEQ
                                 NULL, -- TBRACCD_RATE
                                 NULL, -- TBRACCD_UNITS
                                 NULL, -- TBRACCD_DOCUMENT_NUMBER
                                 TO_DATE(sysdate,'DD/MM/RRRR'), -- TBRACCD_TRANS_DATE
                                 NULL, -- TBRACCD_PAYMENT_ID
                                 NULL, -- TBRACCD_INVOICE_NUMBER
                                 NULL, -- TBRACCD_STATEMENT_DATE
                                 NULL, -- TBRACCD_INV_NUMBER_PAID
                                 X.MONEDA, -- TBRACCD_CURR_CODE
                                 NULL, -- TBRACCD_EXCHANGE_DIFF
                                 NULL, -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                 NULL, -- TBRACCD_LATE_DCAT_CODE
                                 VL_INICIO, -- TBRACCD_FEED_DATE
                                 VL_NUM_CARG, --TBRACCD_FEED_DOC_CODE
                                 NULL, -- TBRACCD_ATYP_CODE
                                 NULL, -- TBRACCD_ATYP_SEQNO
                                 NULL, -- TBRACCD_CARD_TYPE_VR
                                 NULL, -- TBRACCD_CARD_EXP_DATE_VR
                                 NULL, -- TBRACCD_CARD_AUTH_NUMBER_VR
                                 NULL, -- TBRACCD_CROSSREF_DCAT_CODE
                                 NULL, -- TBRACCD_ORIG_CHG_IND
                                 NULL, -- TBRACCD_CCRD_CODE
                                 NULL, -- TBRACCD_MERCHANT_ID
                                 NULL, -- TBRACCD_TAX_REPT_YEAR
                                 NULL, -- TBRACCD_TAX_REPT_BOX
                                 NULL, -- TBRACCD_TAX_AMOUNT
                                 NULL, -- TBRACCD_TAX_FUTURE_IND
                                 'TZFEDCA(ACC)', -- TBRACCD_DATA_ORIGIN
                                 'TZFEDCA(ACC)', -- TBRACCD_CREATE_SOURCE
                                 NULL, -- TBRACCD_CPDT_IND
                                 NULL, -- TBRACCD_AIDY_CODE
                                 VL_STUDY, -- TBRACCD_STSP_KEY_SEQUENCE
                                 VL_PARTE, -- TBRACCD_PERIOD
                                 NULL, -- TBRACCD_SURROGATE_ID
                                 NULL, -- TBRACCD_VERSION
                                 USER, -- TBRACCD_USER_ID
                                 NULL ); -- TBRACCD_VPDI_CODE 
                         EXCEPTION
                         WHEN OTHERS THEN
                             VL_ERROR := 'Se presento ERROR INSERT TBRACCD NTCR'||SQLERRM;
                          DBMS_OUTPUT.PUT_LINE('Error al Generar NTCR ' ||VL_ERROR);
                         END;
 
                             DBMS_OUTPUT.PUT_LINE('Se genero el cargo de NTCR ' ||VL_ERROR);
 
                         If VL_ERROR is null then 
                         
                             BEGIN
                                 UPDATE TZTCOTA
                                 SET GRATIS_APLICADO = nvl (GRATIS_APLICADO,0) +1
                                 WHERE 1=1
                                 AND TZTCOTA_PIDM = X.MATRICULA
                                 AND TZTCOTA_STATUS = 'A'
                                 AND TZTCOTA_CODIGO = X.CODIGO
                                 AND TZTCOTA_SEQNO = X.TZTCOTA_SEQNO;
                             EXCEPTION
                             WHEN OTHERS THEN
                                 VL_ERROR:='ERROR AL ACTUALIZAR NTCR = '||X.MATRICULA||'='||SQLERRM;
                              --DBMS_OUTPUT.PUT_LINE('Error al actualizar COTA NTCR ' ||VL_ERROR);
                             END; 
                         
                         
                         End if;

 
                     End if;
 
                 End if;

                 BEGIN
                     UPDATE TZTCOTA
                         SET TZTCOTA_APLICADOS = nvl (TZTCOTA_APLICADOS,0) +1
                     WHERE 1=1
                     AND TZTCOTA_PIDM = X.MATRICULA
                     AND TZTCOTA_STATUS = 'A'
                     AND TZTCOTA_CODIGO = X.CODIGO
                     AND TZTCOTA_SEQNO = X.TZTCOTA_SEQNO;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_ERROR:='ERROR AL ACTUALIZAR CARGO = '||X.MATRICULA||'='||SQLERRM;
                 END;

  DBMS_OUTPUT.PUT_LINE('ERROR AL ACTUALIZAR CARGO = '||VL_ERROR||'='||X.APLICADOS);

                BEGIN
                     CASE
                     WHEN X.APLICADOS + 1 = X.CARGOS AND X.CARGOS !=1 THEN VL_OBSERVACIONES:= 'FINALIZADO CORRECTAMENTE';
                     WHEN X.APLICADOS < X.CARGOS THEN VL_OBSERVACIONES:= 'GENERADO CORRECTAMENTE';
                     WHEN (X.CARGOS = X.APLICADOS OR X.APLICADOS IS NULL) THEN VL_OBSERVACIONES:= 'GENERADO CORRECTAMENTE';
                     ELSE
                         VL_OBSERVACIONES:= 'VALIDAR REGISTRO';
                     END CASE;


                     BEGIN
                         UPDATE TZTCOTA
                         SET TZTCOTA_OBSERVACIONES = VL_OBSERVACIONES,
                         TZTCOTA_ACTIVITY = sysdate
                         WHERE 1=1
                         AND TZTCOTA_PIDM = X.MATRICULA
                         AND TZTCOTA_STATUS = 'A'
                         AND TZTCOTA_CODIGO = X.CODIGO
                         AND TZTCOTA_SEQNO = X.TZTCOTA_SEQNO;
                     EXCEPTION
                     WHEN OTHERS THEN
                         VL_ERROR:='ERROR AL ACTUALIZAR OBSERVACIONES = '||X.MATRICULA||'='||SQLERRM;
                     END;
                END;

            END IF;
            
         End if;
            
       END IF;

     END IF;

 END IF;

  DBMS_OUTPUT.PUT_LINE('ERROR 5= '||VL_ERROR);

 IF VL_ERROR IS NOT NULL THEN
     ROLLBACK;
     BEGIN
         UPDATE TZTCOTA
         SET TZTCOTA_OBSERVACIONES = VL_ERROR
         WHERE TZTCOTA_PIDM = X.MATRICULA
         AND TZTCOTA_SEQNO = X.TZTCOTA_SEQNO;
     Exception
        When Others then 
            null;
     END;
    COMMIT;

 ELSE
    COMMIT;
 END IF;

  DBMS_OUTPUT.PUT_LINE('ERROR 5= '||VL_ERROR);

 END LOOP;

END P_CONECTA;

FUNCTION F_MENSUAL_DIFERIDO(P_PIDM NUMBER,
 P_CODIGO VARCHAR2,
 P_CARGOS NUMBER,
 P_PROGRAMA VARCHAR2,
 P_SERVICIO NUMBER,
 P_TIPO_SER VARCHAR2
 )RETURN VARCHAR2 IS

/*AUTOR:GGARCICA
 FECHA:17/03/2022
 GENERA CARGO DIFERIDO DE FORMA MENSUAL
 */



VL_ERROR VARCHAR2(900);
VL_MONTO NUMBER;
VL_SECUENCIA NUMBER;
VL_COD_DIFER VARCHAR2(5);
VL_DESC_DIFE VARCHAR2(50);
VL_FECHA_EFE DATE;
VL_PERIODO VARCHAR2(11);
VL_CAMPUS VARCHAR2(4);
VL_NIVEL VARCHAR2(4);
VL_STUDY NUMBER;
VL_MATRICULA VARCHAR2(11);
VL_FOLIO NUMBER;
VL_SECUENCIA_INICIAL NUMBER;
VL_MESES NUMBER;
VL_SALTO_FECHA NUMBER;
VL_DIA_SALTO NUMBER;
VL_MONEDA VARCHAR2(5);
VL_TZFACCE_NUM NUMBER;
VL_TZFACCE_STUDY NUMBER;

BEGIN

 BEGIN
 SELECT ZSTPARA_PARAM_ID,TBBDETC_DESC,TVRDCTX_CURR_CODE
 INTO VL_COD_DIFER,VL_DESC_DIFE,VL_MONEDA
 FROM ZSTPARA,TBBDETC,TVRDCTX
 WHERE ZSTPARA_PARAM_ID = P_CODIGO
 AND ZSTPARA_PARAM_ID = TBBDETC_DETAIL_CODE
 AND TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
 AND ZSTPARA_MAPA_ID = 'MEM_COD';
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR AL CALCULAR CODIGO = '||P_CODIGO||', '||SQLERRM;
 END;

 DBMS_OUTPUT.PUT_LINE('CODIGO = '||VL_COD_DIFER||' = '||'MONEDA = '||VL_MONEDA);


 BEGIN
 SELECT FLOOR(TBBDETC_AMOUNT/P_CARGOS)
 INTO VL_MONTO
 FROM TBBDETC
 WHERE TBBDETC_DETAIL_CODE = P_CODIGO;
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'ERROR AL CALCULAR MONTO '||SQLERRM;
 END;

 BEGIN
 SELECT SORLCUR_CAMP_CODE,SORLCUR_LEVL_CODE,SORLCUR_KEY_SEQNO
 INTO VL_CAMPUS,VL_NIVEL,VL_STUDY
 FROM SORLCUR A
 WHERE A.SORLCUR_PIDM = P_PIDM
 AND A.SORLCUR_LMOD_CODE = 'LEARNER'
 AND A.SORLCUR_ROLL_IND = 'Y'
 AND A.SORLCUR_CACT_CODE = 'ACTIVE'
 AND A.SORLCUR_PROGRAM = P_PROGRAMA
 AND A.SORLCUR_SEQNO = ( SELECT MAX(SORLCUR_SEQNO)
 FROM SORLCUR
 WHERE SORLCUR_PIDM = A.SORLCUR_PIDM
 AND SORLCUR_LMOD_CODE = 'LEARNER'
 AND SORLCUR_ROLL_IND = 'Y'
 AND SORLCUR_CACT_CODE = 'ACTIVE'
 AND SORLCUR_PROGRAM = P_PROGRAMA);
 EXCEPTION
 WHEN OTHERS THEN
 BEGIN
 SELECT SORLCUR_CAMP_CODE,SORLCUR_LEVL_CODE,SORLCUR_KEY_SEQNO
 INTO VL_CAMPUS,VL_NIVEL,VL_STUDY
 FROM SORLCUR A
 WHERE A.SORLCUR_PIDM = P_PIDM
 AND A.SORLCUR_LMOD_CODE = 'LEARNER'
 AND A.SORLCUR_PROGRAM = P_PROGRAMA
 AND A.SORLCUR_SEQNO = ( SELECT MAX(SORLCUR_SEQNO)
 FROM SORLCUR
 WHERE SORLCUR_PIDM = A.SORLCUR_PIDM
 AND SORLCUR_LMOD_CODE = 'LEARNER'
 AND SORLCUR_PROGRAM = P_PROGRAMA);

 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR AL CALCULAR STUDY = '||SQLERRM;
 END;

 END;

 BEGIN
 SELECT MAX(DISTINCT SOBPTRM_TERM_CODE)
 INTO VL_PERIODO
 FROM SOBPTRM
 WHERE SUBSTR(SOBPTRM_TERM_CODE,1,2) = SUBSTR(P_CODIGO,1,2)
 AND SUBSTR(SOBPTRM_TERM_CODE,5,1) NOT IN (8,9,0)
 AND SUBSTR(SOBPTRM_PTRM_CODE,1,1) =
 CASE VL_NIVEL
 WHEN 'MA' THEN 'M'
 WHEN 'LI' THEN 'L'
 WHEN 'DO' THEN 'O'
 WHEN 'EC' THEN 'D'
 WHEN 'MS' THEN 'A'
 END
 AND TO_DATE(SYSDATE) BETWEEN SOBPTRM_START_DATE AND SOBPTRM_END_DATE;
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR AL CALCULAR PERIODO = '||SQLERRM;
 END;

 BEGIN
 SELECT SPRIDEN_ID
 INTO VL_MATRICULA
 FROM SPRIDEN
 WHERE SPRIDEN_PIDM = P_PIDM
 AND SPRIDEN_CHANGE_IND IS NULL;
 END;

 DBMS_OUTPUT.PUT_LINE('ACC DIFERIDO 1 = '||VL_ERROR||' = '||VL_PERIODO);

 IF P_TIPO_SER IS NOT NULL THEN

 BEGIN -----------------recupera la parte de periodo que solicito el alumno
 SELECT SUBSTR(TO_CHAR(SUBSTR(RANGO,1, INSTR(RANGO,'-AL-',1 )-1)),4,2),
 SUBSTR(TO_CHAR(SUBSTR(RANGO,1, INSTR(RANGO,'-AL-',1 )-1)),1,2)
 INTO VL_SALTO_FECHA,VL_DIA_SALTO
 FROM ( SELECT SVRSVAD_ADDL_DATA_DESC RANGO
 FROM SVRSVPR V,SVRSVAD VA
 WHERE SVRSVPR_SRVC_CODE = P_TIPO_SER
 AND SVRSVPR_PROTOCOL_SEQ_NO = P_SERVICIO
 AND SVRSVPR_PIDM = P_PIDM
 AND V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
 AND VA.SVRSVAD_ADDL_DATA_SEQ = '7') ;
 EXCEPTION WHEN OTHERS THEN
 VL_ERROR:='ERROR REZA FECHA '||SQLERRM;
 END;

 END IF;


 IF P_TIPO_SER IS NULL THEN
 VL_FECHA_EFE:= (TRUNC(SYSDATE+1)-(TO_CHAR(TRUNC(SYSDATE),'DD')))+9 ;

 ELSE

 IF VL_DIA_SALTO >20 THEN
 VL_SALTO_FECHA:=VL_SALTO_FECHA+1;
 END IF;

 VL_MESES:=VL_SALTO_FECHA-(TO_CHAR(TRUNC(SYSDATE),'MM'));

 IF VL_MESES < 0 THEN
 VL_MESES:= VL_MESES+12;
 END IF;

 BEGIN
 VL_FECHA_EFE:= (TRUNC(SYSDATE+1)-(TO_CHAR(TRUNC(SYSDATE),'DD')))+9;
 END;

 BEGIN
 VL_FECHA_EFE:= ADD_MONTHS(VL_FECHA_EFE,VL_MESES);
 END;

 END IF;

 IF VL_ERROR IS NULL THEN

 BEGIN


 FOR DIF IN 1..P_CARGOS LOOP
 EXIT WHEN DIF > 1;

 IF VL_FECHA_EFE <= TRUNC(SYSDATE) THEN
 VL_FECHA_EFE:= ADD_MONTHS(VL_FECHA_EFE,1);
 END IF;

 BEGIN
 SELECT MAX(TBRACCD_TRAN_NUMBER)+1
 INTO VL_SECUENCIA
 FROM TBRACCD
 WHERE TBRACCD_PIDM = P_PIDM;
 END;


 BEGIN
 INSERT
 INTO TBRACCD ( TBRACCD_PIDM
 , TBRACCD_TRAN_NUMBER
 , TBRACCD_TRAN_NUMBER_PAID
 , TBRACCD_CROSSREF_NUMBER
 , TBRACCD_TERM_CODE
 , TBRACCD_DETAIL_CODE
 , TBRACCD_USER
 , TBRACCD_ENTRY_DATE
 , TBRACCD_AMOUNT
 , TBRACCD_BALANCE
 , TBRACCD_EFFECTIVE_DATE
 , TBRACCD_FEED_DATE
 , TBRACCD_FEED_DOC_CODE
 , TBRACCD_DESC --No SecPAdre
 , TBRACCD_SRCE_CODE
 , TBRACCD_ACCT_FEED_IND
 , TBRACCD_ACTIVITY_DATE
 , TBRACCD_SESSION_NUMBER
 , TBRACCD_TRANS_DATE
 , TBRACCD_CURR_CODE
 , TBRACCD_DATA_ORIGIN
 , TBRACCD_CREATE_SOURCE
 , TBRACCD_STSP_KEY_SEQUENCE
 , TBRACCD_PERIOD
 , TBRACCD_USER_ID
 , TBRACCD_RECEIPT_NUMBER)
 VALUES (P_PIDM, -- TBRACCD_PIDM
 VL_SECUENCIA, -- TBRACCD_TRAN_NUMBER
 NULL, -- TBRACCD_TRAN_NUMBER_PAID
 P_SERVICIO, -- TBRACCD_CROSSREF_NUMBER
 VL_PERIODO, -- TBRACCD_TERM_CODE
 VL_COD_DIFER, -- TBRACCD_DETAIL_CODE
 USER, -- TBRACCD_USER
 SYSDATE, -- TBRACCD_ENTRY_DATE
 VL_MONTO, -- TBRACCD_AMOUNT
 VL_MONTO, -- TBRACCD_BALANCE
 VL_FECHA_EFE, -- TBRACCD_EFFECTIVE_DATE
 NULL, -- TBRACCD_FEED_DATE
 1||' | '||P_CARGOS, ---TBRACCD_FEED_DOC_CODE
 VL_DESC_DIFE, -- TBRACCD_DESC
 'T', -- TBRACCD_SRCE_CODE
 'Y', -- TBRACCD_ACCT_FEED_IND
 SYSDATE, -- TBRACCD_ACTIVITY_DATE
 0, -- TBRACCD_SESSION_NUMBER
 VL_FECHA_EFE, -- TBRACCD_TRANS_DATE
 VL_MONEDA, -- TBRACCD_CURR_CODE
 'ACC_DIFER', -- TBRACCD_DATA_ORIGIN
 'ACC_DIFER', -- TBRACCD_CREATE_SOURCE
 VL_STUDY, -- TBRACCD_STSP_KEY_SEQUENCE
 NULL, -- TBRACCD_PERIOD
 USER, -- TBRACCD_USER_ID
 NULL);
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR :='Error al insertar cargo = '||SQLERRM;
 END;

 VL_FECHA_EFE:= ADD_MONTHS(VL_FECHA_EFE,1);


 END LOOP;


 BEGIN
 SELECT MIN(TBRACCD_TRAN_NUMBER)
 INTO VL_SECUENCIA_INICIAL
 FROM TBRACCD
 WHERE TBRACCD_PIDM=P_PIDM
 AND TBRACCD_CROSSREF_NUMBER=P_SERVICIO;
 END;


 IF VL_ERROR IS NULL THEN


 BEGIN
 SELECT MAX(TZTORDR_CONTADOR)+1
 INTO VL_FOLIO
 FROM TZTORDR;
 EXCEPTION
 WHEN OTHERS THEN
 VL_FOLIO:= NULL;
 END;

 BEGIN

 INSERT
 INTO TZTORDR ( TZTORDR_CAMPUS,
 TZTORDR_NIVEL,
 TZTORDR_CONTADOR,
 TZTORDR_PROGRAMA,
 TZTORDR_PIDM,
 TZTORDR_ID,
 TZTORDR_ESTATUS,
 TZTORDR_ACTIVITY_DATE,
 TZTORDR_USER,
 TZTORDR_DATA_ORIGIN,
 TZTORDR_NO_REGLA,
 TZTORDR_FECHA_INICIO,
 TZTORDR_RATE,
 TZTORDR_JORNADA,
 TZTORDR_DSI,
 TZTORDR_TERM_CODE)
 VALUES ( VL_CAMPUS,
 VL_NIVEL,
 VL_FOLIO,
 P_PROGRAMA,
 P_PIDM,
 VL_MATRICULA,
 'S',
 SYSDATE,
 USER,
 'ACC_DIFER',
 NULL,
 TRUNC(SYSDATE),
 NULL,
 NULL,
 NULL,
 VL_PERIODO);
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR AL GUARDAR ORDEN = '||SQLERRM;
 END;


 BEGIN
 UPDATE TBRACCD
 SET TBRACCD_RECEIPT_NUMBER = VL_FOLIO
 WHERE TBRACCD_PIDM = P_PIDM
 AND TBRACCD_DETAIL_CODE = VL_COD_DIFER
 AND TRUNC(TBRACCD_ENTRY_DATE) = TRUNC(SYSDATE);

 UPDATE TVRACCD
 SET TVRACCD_RECEIPT_NUMBER = VL_FOLIO
 WHERE TVRACCD_PIDM = P_PIDM
 AND TVRACCD_DETAIL_CODE = VL_COD_DIFER
 AND TRUNC(TVRACCD_ENTRY_DATE) = TRUNC(SYSDATE);
 END;


 BEGIN
 UPDATE TZTCOTA
 SET TZTCOTA_APLICADOS = TZTCOTA_APLICADOS + 1
 WHERE TZTCOTA_PIDM = P_PIDM
 AND TZTCOTA_STATUS = 'A'
 AND TZTCOTA_CODIGO = VL_COD_DIFER
 AND TZTCOTA_SEQNO = (SELECT MAX(A.TZTCOTA_SEQNO)
 FROM TZTCOTA A
 WHERE A.TZTCOTA_PIDM = TZTCOTA_PIDM
 AND A.TZTCOTA_CODIGO = TZTCOTA_CODIGO
 AND A.TZTCOTA_APLICADOS = TZTCOTA_APLICADOS
 AND A.TZTCOTA_STATUS = TZTCOTA_STATUS);
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR AL ACTUALIZAR CARGO APLICADO = '||P_PIDM||'='||SQLERRM;
 END;


 BEGIN
 UPDATE TZTCOTA
 SET TZTCOTA_OBSERVACIONES = 'GENERADO CORRECTAMENTE'
 WHERE TZTCOTA_PIDM = P_PIDM
 AND TZTCOTA_STATUS = 'A'
 AND TZTCOTA_CODIGO = VL_COD_DIFER;
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR AL ACTUALIZAR OBSERVACIONES = '||P_PIDM||'='||SQLERRM;
 END;

 END IF;

 END;

 END IF;

 IF VL_ERROR IS NULL THEN
 VL_ERROR:='EXITO|'||VL_SECUENCIA_INICIAL;
 COMMIT;
 ELSE
 ROLLBACK;
 END IF;

 RETURN(VL_ERROR);

END F_MENSUAL_DIFERIDO;
-----
-----
   FUNCTION F_REACTIVA_INACTIVA (P_PIDM        NUMBER,
                                 P_ESTATUS     VARCHAR2,
                                 P_USUARIO     VARCHAR2,
                                 P_ETIQUETA    VARCHAR2)
      RETURN VARCHAR2
   IS
      -- Variables del proceso.
      VL_EXISTE_GORA       NUMBER := 0;
      VL_MAX_SURROGATE     NUMBER := 0;
      VL_MAX_SURROGATE_1   NUMBER := 0;
      VL_MAX_SEQ_NO        NUMBER := 0;
      VL_MAX_PERIODO       VARCHAR2 (7) := NULL;
      VL_MAX_ADID_DESC     VARCHAR2 (50) := NULL;
      VL_ERROR             VARCHAR2 (1000) := 'EXITO';
      VL_COTA_APLICADOS    NUMBER := 0;
      VL_COTA_PIDM         NUMBER := 0;
      VL_COTA_ORIGEN       VARCHAR2 (4) := NULL;
      VL_COTA_SERVICIO     NUMBER := 0;
      VL_VALIDA_COTA       NUMBER := 0;
      VL_SEQ               NUMBER := 0;
      VL_PIDM_COTA         NUMBER := 0;
      VL_ORIGEN_COTA       VARCHAR2 (6) := NULL;
      VL_SYN_COTA          NUMBER := 0;
      VL_SZT_SYN_AV        NUMBER := 0;
      VL_CAN_SERV_ESP      VARCHAR2 (1000) := NULL;
      VL_CAN_ACC_RECU      VARCHAR2 (1000) := NULL;
      VL_SEQ_COTA          NUMBER := 0;
      VL_VALIDA_TZTCOTA    NUMBER := 0;

      -- OMS 23/Enero/2025
      Vm_Maximo_seqCOTA NUMBER := 0;


/*******************************************************************************
*           Bloque de obtención de datos para registro de movimientos.         *
*******************************************************************************/

BEGIN
-- Valida existencia de etiqueta para el matriculado.
    BEGIN
        SELECT COUNT (1)
          INTO VL_EXISTE_GORA
          FROM GORADID GORA
         WHERE 1 = 1
           AND GORA.GORADID_PIDM = P_PIDM
           AND GORA.GORADID_ADID_CODE = P_ETIQUETA;

    EXCEPTION
        WHEN OTHERS THEN
            VL_ERROR := '(Exc.) No hay registro de etiqueta '||P_ETIQUETA|| ' para el matriculado '|| GB_COMMON.F_GET_ID (P_PIDM)|| '... Favor de revisar...'|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM|| CHR (10)|| CHR (10);
      END;

-- Maximo registro del ID a sustituir(SURROGATE) en GORADID mas 1.
    BEGIN
        SELECT NVL (MAX (GORA.GORADID_SURROGATE_ID), 0) + 1
          INTO VL_MAX_SURROGATE
          FROM GORADID GORA
         WHERE 1 = 1;

    EXCEPTION
        WHEN OTHERS THEN
            VL_MAX_SURROGATE := 1;
    END;

-- Maximo registro del ID a sustituir(SURROGATE) en SGRSCMT mas 1.
    BEGIN
        SELECT NVL (MAX (SCMT.SGRSCMT_SURROGATE_ID), 0) + 1
          INTO VL_MAX_SURROGATE_1
          FROM SGRSCMT SCMT
         WHERE 1 = 1;

    EXCEPTION
         WHEN OTHERS
         THEN
            VL_MAX_SURROGATE_1 := 1;

    END;

-- Maximo registro de secuencia en SGRSCMT para el matriculado.
    BEGIN
        SELECT NVL (MAX (SCMT.SGRSCMT_SEQ_NO), 0) + 1
          INTO VL_MAX_SEQ_NO
          FROM SGRSCMT SCMT
         WHERE 1 = 1 AND SCMT.SGRSCMT_PIDM = P_PIDM;

    EXCEPTION
        WHEN OTHERS THEN
            VL_MAX_SEQ_NO := 1;
    END;

-- Maximo periodo en la tabla SGBSTDN del matriculado.
    BEGIN
        SELECT NVL (MAX (SGBSTDN_TERM_CODE_EFF), 'SIN PERIODO')
          INTO VL_MAX_PERIODO
          FROM SGBSTDN
         WHERE 1 = 1 AND SGBSTDN_PIDM = P_PIDM;

    EXCEPTION
        WHEN OTHERS THEN
            VL_MAX_PERIODO := NULL;

    END;

-- Maximo registro de descripcion de etiqueta en la tabla GTVADID.
    BEGIN
        SELECT NVL (MAX (ADID.GTVADID_DESC), 'SIN ETIQUETA')
          INTO VL_MAX_ADID_DESC
          FROM GTVADID ADID
         WHERE 1 = 1 AND ADID.GTVADID_CODE = P_ETIQUETA;

    EXCEPTION
       WHEN OTHERS  THEN
            VL_MAX_ADID_DESC := NULL;
    END;

/*******************************************************************************
*       Fin bloque de obtención de datos para registro de movimientos.         *
*******************************************************************************/

/*******************************************************************************
*     Bloque de inactivación(I) - activación(A) del accesorio - servicio.      *
*******************************************************************************/

-- Si existe la etiqueta(VL_EXISTE_GORA) y el estatus(P_ESTATUS) es INACTIVA, entonces...
    IF VL_EXISTE_GORA > 0 AND P_ESTATUS = 'INACTIVA' THEN

    -- Valida existencia de accesorio - servicio en Autoservicio(TZTCOTA).
        BEGIN
            SELECT COUNT (1)
              INTO VL_VALIDA_COTA
              FROM TZTCOTA COTA
             WHERE 1 = 1
               AND COTA.TZTCOTA_ORIGEN = P_ETIQUETA
               AND COTA.TZTCOTA_PIDM = P_PIDM
               AND COTA.TZTCOTA_SEQNO = (SELECT MAX(COTA1.TZTCOTA_SEQNO)
                                           FROM TZTCOTA COTA1
                                          WHERE 1 = 1
                                            AND COTA1.TZTCOTA_ORIGEN = COTA.TZTCOTA_ORIGEN
                                            AND COTA1.TZTCOTA_PIDM = COTA.TZTCOTA_PIDM);

        EXCEPTION
            WHEN OTHERS THEN
                VL_ERROR :=
                     '-->    (Exc.) No hay registro de accesorio - servicio con cargos aplicados para el matriculado '|| GB_COMMON.F_GET_ID (P_PIDM)|| '... Favor de revisar...'|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM|| CHR (10)|| CHR (10);
        END;

    -- Si existe accesorio - servicio en Autoservicio(TZTCOTA), entonces...
        IF VL_VALIDA_COTA >= 1 THEN

        -- Obtiene la cantidad de cargos aplicados del accesorio - servicio en Autoservicio(TZTCOTA).
            BEGIN
                SELECT COTA.TZTCOTA_APLICADOS
                  INTO VL_COTA_APLICADOS
                  FROM TZTCOTA COTA
                 WHERE 1 = 1
                   AND COTA.TZTCOTA_ORIGEN = P_ETIQUETA
                   AND COTA.TZTCOTA_PIDM = P_PIDM
                   AND COTA.TZTCOTA_SEQNO = (SELECT MAX (COTA1.TZTCOTA_SEQNO)
                                               FROM TZTCOTA COTA1
                                              WHERE 1 = 1
                                                AND COTA1.TZTCOTA_ORIGEN = COTA.TZTCOTA_ORIGEN
                                                AND COTA1.TZTCOTA_PIDM = COTA.TZTCOTA_PIDM);
            EXCEPTION
                WHEN OTHERS THEN
                    VL_COTA_APLICADOS := 0;
            END;

        -- Si el numero de aplicados es igual a 1 o 0 o nulo, entonces...
            IF VL_COTA_APLICADOS = 1
               OR VL_COTA_APLICADOS = 0
               OR VL_COTA_APLICADOS IS NULL THEN

               -- Obtención de datos para llamar a la función PKG_SERV_SIU.P_CAN_SERV_ESP
                BEGIN
                    SELECT COTA.TZTCOTA_PIDM
                          ,COTA.TZTCOTA_ORIGEN
                          ,COTA.TZTCOTA_SERVICIO
                      INTO VL_COTA_PIDM
                          ,VL_COTA_ORIGEN
                          ,VL_COTA_SERVICIO
                      FROM TZTCOTA COTA
                     WHERE 1 = 1
                       AND COTA.TZTCOTA_ORIGEN = P_ETIQUETA
                       AND COTA.TZTCOTA_PIDM = P_PIDM
                       AND (COTA.TZTCOTA_APLICADOS = 1
                            OR COTA.TZTCOTA_APLICADOS = 0
                            OR COTA.TZTCOTA_APLICADOS IS NULL)
                       AND COTA.TZTCOTA_SEQNO = (SELECT MAX(COTA1.TZTCOTA_SEQNO)
                                                   FROM TZTCOTA COTA1
                                                  WHERE 1 = 1
                                                    AND COTA1.TZTCOTA_ORIGEN = COTA.TZTCOTA_ORIGEN
                                                    AND COTA1.TZTCOTA_PIDM = COTA.TZTCOTA_PIDM
                                                    AND (COTA1.TZTCOTA_APLICADOS = 1
                                                         OR COTA1.TZTCOTA_APLICADOS = 0
                                                         OR COTA1.TZTCOTA_APLICADOS IS NULL));

                EXCEPTION
                    WHEN OTHERS THEN
                        VL_COTA_PIDM := 0;
                        VL_COTA_ORIGEN := NULL;
                        VL_COTA_SERVICIO := 0;
                END;

            -- Llama a la funcion PKG_SERV_SIU.P_CAN_SERV_ESP para su proceso de cancelación.
                VL_CAN_SERV_ESP := PKG_SERV_SIU.P_CAN_SERV_ESP (VL_COTA_ORIGEN
                                                               ,VL_COTA_PIDM
                                                               ,VL_COTA_SERVICIO
                                                               ,P_USUARIO
                                                               ,NULL);
            -- OMS 11/Febrero/2025
            -- Actualiza registro en la tabla de servicio a cancelado
                BEGIN
-- DBMS_OUTPUT.PUT_LINE('Actualiza el Servicio con estatus CA (Linea nueva)');
                    UPDATE SVRSVPR
                       SET SVRSVPR_SRVS_CODE = 'CA'
                     WHERE 1 = 1
                       AND SVRSVPR_PIDM            = VL_COTA_PIDM
                       AND SVRSVPR_PROTOCOL_SEQ_NO = VL_COTA_SERVICIO
--                       AND SVRSVPR_SRVC_CODE = VL_COTA_ORIGEN
                       ;
                END;

        -- Si no, si el numero de aplicados es mayor o igual a 2, entonces...
            ELSIF VL_COTA_APLICADOS >= 2 THEN

                BEGIN
                    SELECT COTA.TZTCOTA_PIDM
                          ,COTA.TZTCOTA_ORIGEN
                          ,COTA.TZTCOTA_SERVICIO
                      INTO VL_COTA_PIDM
                          ,VL_COTA_ORIGEN
                          ,VL_COTA_SERVICIO
                      FROM TZTCOTA COTA
                     WHERE 1 = 1
                       AND COTA.TZTCOTA_ORIGEN = P_ETIQUETA
                       AND COTA.TZTCOTA_PIDM = P_PIDM
                       AND COTA.TZTCOTA_STATUS = 'A'
                       AND COTA.TZTCOTA_SEQNO = (SELECT MAX(COTA1.TZTCOTA_SEQNO)
                                                   FROM TZTCOTA COTA1
                                                  WHERE     1 = 1
                                                    AND COTA1.TZTCOTA_ORIGEN = COTA.TZTCOTA_ORIGEN
                                                    AND COTA1.TZTCOTA_PIDM = COTA.TZTCOTA_PIDM
                                                    AND COTA1.TZTCOTA_STATUS = COTA.TZTCOTA_STATUS);

                EXCEPTION
                    WHEN OTHERS THEN
                        VL_COTA_PIDM := 0;
                        VL_COTA_ORIGEN := NULL;
                        VL_COTA_SERVICIO := 0;
                END;

            -- Actualiza registro en la tabla de servicio a cancelado
                BEGIN
                    UPDATE SVRSVPR
                       SET SVRSVPR_SRVS_CODE = 'CA'
                     WHERE 1 = 1
                       AND SVRSVPR_PIDM = VL_COTA_PIDM
                       AND SVRSVPR_PROTOCOL_SEQ_NO = VL_COTA_SERVICIO
--                       AND SVRSVPR_SRVC_CODE = VL_COTA_ORIGEN
                       ;
                END;

            -- Llama a la funcion PKG_FINANZAS_UTLX.F_CANC_ACC_RECU para su proceso de cancelación del acceosrio recurrente.
               VL_CAN_ACC_RECU := PKG_FINANZAS_UTLX.F_CANC_ACC_RECU (P_PIDM
                                                                    ,P_USUARIO
                                                                    ,P_ETIQUETA);
            END IF;

        -- Nuevo registro en Autoservicio para la inactivación - cancelación del accesorio - servicio.
            BEGIN
                 -- OMS 23/Enero/2023
                 BEGIN
                    SELECT MAX (TZTCOTA_SEQNO)
                      INTO Vm_Maximo_seqCOTA
                      FROM TZTCOTA
                     WHERE 1 = 1
                       AND TZTCOTA_PIDM   = P_PIDM
                    -- AND TZTCOTA_ORIGEN = P_ETIQUETA          -- OMS 21/Febrero/2025
                       ;
                   
                 EXCEPTION WHEN OTHERS THEN Vm_Maximo_seqCOTA := 1;
                 END;

                VL_SEQ_COTA := 0;
                FOR COTA IN (
                                SELECT *
                                  FROM TZTCOTA
                                 WHERE 1 = 1
                                   AND TZTCOTA_PIDM    = P_PIDM
                                   AND TZTCOTA_ORIGEN  = P_ETIQUETA
                                   AND TZTCOTA_STATUS  = 'A'
                            )LOOP

                                VL_SEQ_COTA := VL_SEQ_COTA + 1;

-- DBMS_OUTPUT.PUT_LINE('---- pidm-seqno-origen');
-- DBMS_OUTPUT.PUT_LINE(COTA.TZTCOTA_PIDM);
-- DBMS_OUTPUT.PUT_LINE(COTA.TZTCOTA_SEQNO + 1);
-- DBMS_OUTPUT.PUT_LINE(COTA.TZTCOTA_ORIGEN);

                            -- Insertar registro en Autoservicio.
                                BEGIN
                                    INSERT INTO TZTCOTA
                                         VALUES(COTA.TZTCOTA_PIDM,
                                                COTA.TZTCOTA_TERM_CODE,
                                                COTA.TZTCOTA_CAMPUS,
                                                COTA.TZTCOTA_NIVEL,
                                                COTA.TZTCOTA_PROGRAMA,
                                                COTA.TZTCOTA_CODIGO,
                                                COTA.TZTCOTA_SERVICIO,
                                                COTA.TZTCOTA_CARGOS,
                                                COTA.TZTCOTA_APLICADOS,
                                                COTA.TZTCOTA_DESCUENTO,
                                                Vm_Maximo_seqCOTA + VL_SEQ_COTA,   -- COTA.TZTCOTA_SEQNO + 1,
                                                1,
                                                P_USUARIO,
                                                COTA.TZTCOTA_ORIGEN,
                                                'I',
                                                COTA.TZTCOTA_FECHA_INI,
                                                SYSDATE,
                                                'CANCE SERVICIO',
                                                COTA.TZTCOTA_MONTO,
                                                COTA.TZTCOTA_GRATIS,
                                                COTA.GRATIS_APLICADO,
                                                COTA.TZTCOTA_EMAIL,
                                                COTA.TZTCOTA_SINCRONIA,
                                                null,
                                                null,
                                                null,
                                                null
                                                );
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        VL_ERROR := 'Error al registrar movimiento en Autoservicio... Favor de revisar...'|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
                                END;

                            END LOOP;

            END;

        END IF;

/*******************************************************************************
*     Fin bloque de inactivación - cancelación del accesorio - servicio.       *
*******************************************************************************/

    -- Borra etiqueta de la tabla GORADID por Pidm y Etiqueta
        BEGIN
            DELETE
              FROM GORADID
             WHERE 1 = 1
               AND GORADID_PIDM = P_PIDM
               AND GORADID_ADID_CODE = P_ETIQUETA;

        EXCEPTION
            WHEN OTHERS THEN
                VL_ERROR := 'No se puede eliminar la etiqueta en GORADID para el alumno(PIDM): '|| P_PIDM|| ', favor de revisarlo...'|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
        END;

    -- Inserta registro en la tabla SGRSCMT
        BEGIN
            INSERT INTO SGRSCMT(SGRSCMT_PIDM,
                                SGRSCMT_SEQ_NO,
                                SGRSCMT_TERM_CODE,
                                SGRSCMT_COMMENT_TEXT,
                                SGRSCMT_ACTIVITY_DATE,
                                SGRSCMT_SURROGATE_ID,
                                SGRSCMT_VERSION,
                                SGRSCMT_USER_ID,
                                SGRSCMT_DATA_ORIGIN,
                                SGRSCMT_VPDI_CODE)
                          VALUES(P_PIDM
                                ,VL_MAX_SEQ_NO
                                ,VL_MAX_PERIODO
                                ,'INACTIVA'|| VL_MAX_ADID_DESC|| '--'|| P_ETIQUETA|| ' Usuario '|| P_USUARIO|| ' Fecha: '|| SYSDATE
                                ,SYSDATE
                                ,VL_MAX_SURROGATE_1
                                ,1
                                ,P_USUARIO
                                ,'CONECTA AUT'
                                ,1);
        EXCEPTION
            WHEN OTHERS THEN
               VL_ERROR := 'Error al insertar en la tabla SGRSCMT para el alumno(Pidm) '|| P_PIDM|| ' para inactivar, favor de revisarlo...' || CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
        END;

-- Si no existe etiqueta(VL_EXISTE_GORA) y el estatus es REACTIVA.
    ELSIF VL_EXISTE_GORA = 0 AND P_ESTATUS = 'REACTIVA' THEN

    -- Inserta registro de etiqueta en la tabla GORADID.
         BEGIN
            INSERT INTO GORADID (GORADID_PIDM,
                                 GORADID_ADDITIONAL_ID,
                                 GORADID_ADID_CODE,
                                 GORADID_USER_ID,
                                 GORADID_ACTIVITY_DATE,
                                 GORADID_DATA_ORIGIN,
                                 GORADID_SURROGATE_ID,
                                 GORADID_VERSION,
                                 GORADID_VPDI_CODE)
                         VALUES (P_PIDM                                 --GORADID_PIDM
                               ,
                         VL_MAX_ADID_DESC              --GORADID_ADDITIONAL_ID
                                         ,
                         P_ETIQUETA                        --GORADID_ADID_CODE
                                   ,
                         P_USUARIO                           --GORADID_USER_ID
                                  ,
                         SYSDATE                       --GORADID_ACTIVITY_DATE
                                ,
                         'UTEL'                          --GORADID_DATA_ORIGIN
                               ,
                         VL_MAX_SURROGATE               --GORADID_SURROGATE_ID
                                         ,
                         0                                   --GORADID_VERSION
                          ,
                         NULL);                            --GORADID_VPDI_CODE
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_ERROR := 'Error al insertar en la tabla GORADID para el alumno(Pidm) '|| P_PIDM || ' para etiqueta, favor de revisarlo... '|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;

         END;

         -- Inserta registro de etiqueta en la tabla SGRSCMT.
         BEGIN
            INSERT INTO SGRSCMT (SGRSCMT_PIDM,
                                 SGRSCMT_SEQ_NO,
                                 SGRSCMT_TERM_CODE,
                                 SGRSCMT_COMMENT_TEXT,
                                 SGRSCMT_ACTIVITY_DATE,
                                 SGRSCMT_SURROGATE_ID,
                                 SGRSCMT_VERSION,
                                 SGRSCMT_USER_ID,
                                 SGRSCMT_DATA_ORIGIN,
                                 SGRSCMT_VPDI_CODE)
                    VALUES (
                              P_PIDM                            --SGRSCMT_PIDM
                                    ,
                              1                               --SGRSCMT_SEQ_NO
                               ,
                              VL_MAX_PERIODO               --SGRSCMT_TERM_CODE
                                            ,
                                 'REACTIVA'
                              || VL_MAX_ADID_DESC
                              || '--'
                              || P_ETIQUETA
                              || ' Usuario '
                              || P_USUARIO
                              || ' Fecha: '
                              || SYSDATE                --SGRSCMT_COMMENT_TEXT
                                        ,
                              SYSDATE                  --SGRSCMT_ACTIVITY_DATE
                                     ,
                              VL_MAX_SURROGATE_1        --SGRSCMT_SURROGATE_ID
                                                ,
                              1                              --SGRSCMT_VERSION
                               ,
                              P_USUARIO                      --SGRSCMT_USER_ID
                                       ,
                              'CONECTA AUT'              --SGRSCMT_DATA_ORIGIN
                                           ,
                              NULL);                       --SGRSCMT_VPDI_CODE
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_ERROR := 'Error al insertar en la tabla SGRSCMT para el alumno(Pidm) '|| P_PIDM || ' para reactivar, favor de revisarlo... '|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
         END;
      END IF;

      -- Validar existencia de registros en TZTCOTA ----
      BEGIN
         SELECT COUNT (1)
           INTO VL_VALIDA_TZTCOTA
           FROM TZTCOTA
          WHERE     1 = 1
                AND TZTCOTA_ORIGEN = P_ETIQUETA
                AND TZTCOTA_PIDM = P_PIDM;

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            VL_VALIDA_TZTCOTA := 0;
            VL_ERROR := 'No existe/encontró registros en TZTCOTA para el Pidm ' || P_PIDM || ', con la etiqueta '|| P_ETIQUETA || '.' || CHR (10);
      END;

      IF VL_VALIDA_TZTCOTA > 0
      THEN
         /*******************************************************************************
         *    Fin bloque de inactivación(I) - activación(A) del accesorio - servicio.   *
         *******************************************************************************/

         FOR C_GECE IN (SELECT *
                          FROM SZTGECE
                         WHERE 1 = 1 AND SZT_ETIQUETA = P_ETIQUETA)
         LOOP
            BEGIN
               UPDATE TZTCOTA
                  SET TZTCOTA_GRATIS =
                         (SELECT A1.TZTCOTA_GRATIS
                            FROM TZTCOTA A1
                           WHERE     1 = 1
                                 AND A1.TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                                 AND A1.TZTCOTA_PIDM = P_PIDM
                                 AND A1.TZTCOTA_SEQNO =
                                        (SELECT MIN (A3.TZTCOTA_SEQNO)
                                           FROM TZTCOTA A3
                                          WHERE     1 = 1
                                                AND A3.TZTCOTA_ORIGEN =
                                                       A1.TZTCOTA_ORIGEN
                                                AND A3.TZTCOTA_PIDM =
                                                       A1.TZTCOTA_PIDM)),
                      GRATIS_APLICADO =
                         (SELECT A2.GRATIS_APLICADO
                            FROM TZTCOTA A2
                           WHERE     1 = 1
                                 AND A2.TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                                 AND A2.TZTCOTA_PIDM = P_PIDM
                                 AND A2.TZTCOTA_SEQNO =
                                        (SELECT MIN (A4.TZTCOTA_SEQNO)
                                           FROM TZTCOTA A4
                                          WHERE     1 = 1
                                                AND A4.TZTCOTA_ORIGEN =
                                                       A2.TZTCOTA_ORIGEN
                                                AND A4.TZTCOTA_PIDM =
                                                       A2.TZTCOTA_PIDM))
                WHERE     1 = 1
                      AND TZTCOTA_STATUS = 'I'
                      AND TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                      AND (   TZTCOTA_SINCRONIA = C_GECE.SZT_SYN_AV
                           OR TZTCOTA_SINCRONIA IS NULL)
                      AND TZTCOTA_PIDM = P_PIDM;


            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_ERROR := 'Error al actualizar registro en TZTCOTA(Cambio Sincro a 5), favor de revisar... '|| CHR (10) || 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
            END;

            IF C_GECE.SZT_SYN_AV = 0
            THEN
               BEGIN
                  UPDATE TZTCOTA
                     SET TZTCOTA_SINCRONIA = 5
                   WHERE     1 = 1
                         AND TZTCOTA_STATUS = 'I'
                         AND TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                         AND (   TZTCOTA_SINCRONIA = C_GECE.SZT_SYN_AV
                              OR TZTCOTA_SINCRONIA IS NULL)
                         AND TZTCOTA_PIDM = P_PIDM;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VL_ERROR := 'Error al actualizar registro en TZTCOTA(Cambio Sincro a 5), favor de revisar... '|| CHR (10) || 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
               END;
            ELSIF C_GECE.SZT_SYN_AV = 1
            THEN
               BEGIN
                  UPDATE TZTCOTA
                     SET TZTCOTA_SINCRONIA = 0
                   WHERE     1 = 1
                         AND TZTCOTA_STATUS = 'I'
                         AND TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                         AND (   TZTCOTA_SINCRONIA = C_GECE.SZT_SYN_AV
                              OR TZTCOTA_SINCRONIA IS NULL)
                         AND TZTCOTA_PIDM = P_PIDM;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VL_ERROR := 'Error al actualizar registro en TZTCOTA(Cambio Sincro a 5), favor de revisar... '|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
               END;
            END IF;
         END LOOP;
      ---------------------------------------

      ELSE
         --------------------------------------------------------------------------------

         FOR C_GECE IN (SELECT *
                          FROM SZTGECE
                         WHERE 1 = 1 AND SZT_ETIQUETA = P_ETIQUETA)
         LOOP
            BEGIN
               UPDATE TZTCOTA
                  SET TZTCOTA_GRATIS =
                         (SELECT A1.TZTCOTA_GRATIS
                            FROM TZTCOTA A1
                           WHERE     1 = 1
                                 AND A1.TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                                 AND A1.TZTCOTA_PIDM = P_PIDM
                                 AND A1.TZTCOTA_SEQNO =
                                        (SELECT MIN (A3.TZTCOTA_SEQNO)
                                           FROM TZTCOTA A3
                                          WHERE     1 = 1
                                                AND A3.TZTCOTA_ORIGEN =
                                                       A1.TZTCOTA_ORIGEN
                                                AND A3.TZTCOTA_PIDM =
                                                       A1.TZTCOTA_PIDM)),
                      GRATIS_APLICADO =
                         (SELECT A2.GRATIS_APLICADO
                            FROM TZTCOTA A2
                           WHERE     1 = 1
                                 AND A2.TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                                 AND A2.TZTCOTA_PIDM = P_PIDM
                                 AND A2.TZTCOTA_SEQNO =
                                        (SELECT MIN (A4.TZTCOTA_SEQNO)
                                           FROM TZTCOTA A4
                                          WHERE     1 = 1
                                                AND A4.TZTCOTA_ORIGEN =
                                                       A2.TZTCOTA_ORIGEN
                                                AND A4.TZTCOTA_PIDM =
                                                       A2.TZTCOTA_PIDM))
                WHERE     1 = 1
                      AND TZTCOTA_STATUS = 'I'
                      AND TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                      AND (   TZTCOTA_SINCRONIA = C_GECE.SZT_SYN_AV
                           OR TZTCOTA_SINCRONIA IS NULL)
                      AND TZTCOTA_PIDM = P_PIDM;

            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_ERROR :='Error, no se puede actualizar en TZTCOTA, favor de revisar...'|| CHR (10)|| 'SQLCODE :'|| SQLCODE|| CHR (10)|| SQLERRM;
            END;

            IF C_GECE.SZT_SYN_AV = 0
            THEN
               BEGIN
                  UPDATE TZTCOTA
                     SET TZTCOTA_SINCRONIA = 5
                   WHERE     1 = 1
                         AND TZTCOTA_STATUS = 'I'
                         AND TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                         AND (   TZTCOTA_SINCRONIA = C_GECE.SZT_SYN_AV
                              OR TZTCOTA_SINCRONIA IS NULL)
                         AND TZTCOTA_PIDM = P_PIDM;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VL_ERROR := 'Error al actualizar registro en TZTCOTA(Cambio Sincro a 5), favor de revisar... '|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
               END;
            ELSIF C_GECE.SZT_SYN_AV = 1
            THEN
               BEGIN
                  UPDATE TZTCOTA
                     SET TZTCOTA_SINCRONIA = 0
                   WHERE     1 = 1
                         AND TZTCOTA_STATUS = 'I'
                         AND TZTCOTA_ORIGEN = C_GECE.SZT_ETIQUETA
                         AND (   TZTCOTA_SINCRONIA = C_GECE.SZT_SYN_AV
                              OR TZTCOTA_SINCRONIA IS NULL)
                         AND TZTCOTA_PIDM = P_PIDM;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VL_ERROR := 'Error al actualizar registro en TZTCOTA(Cambio Sincro a 5), favor de revisar... '|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
               END;
            END IF;
         END LOOP;
      ---------------------------------------

      END IF;


      -- Fin Validar existencia de registros en TZTCOTA ----

      IF VL_ERROR = 'EXITO'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN VL_ERROR;
   END F_REACTIVA_INACTIVA;
   

   --
   --

FUNCTION F_CURSOR_MEMBRESIA (P_PIDM IN NUMBER, P_ERROR OUT VARCHAR2) RETURN BANINST1.PKG_FINANZAS_UTLX.CURSOR_MEMBRESIA AS
MEMBRESIA BANINST1.PKG_FINANZAS_UTLX.CURSOR_MEMBRESIA;


VL_ENTRA NUMBER;
VL_ERROR VARCHAR2(900);

/*AUTOR PROCESO MEMBRESIAS
AUTOR GGARCICA
FECHA 03/03/2022
*/

BEGIN

 BEGIN
 SELECT COUNT (*)
 INTO VL_ENTRA
 FROM TZTCOTA X
 WHERE X.TZTCOTA_PIDM = P_PIDM
 AND X.TZTCOTA_SEQNO = ( SELECT MAX (TZTCOTA_SEQNO)
 FROM TZTCOTA
 WHERE TZTCOTA_PIDM = X.TZTCOTA_PIDM);
-- AND TZTCOTA_FLAG = 0);
 EXCEPTION
 WHEN
 OTHERS THEN
 VL_ENTRA:=0;
 END;

 IF VL_ENTRA > 0 THEN


 BEGIN
 OPEN MEMBRESIA
 FOR
 SELECT DISTINCT
 SPRIDEN_ID MATRICULA,
 (REPLACE (UPPER(SPRIDEN_LAST_NAME),'/',' '))||' '||
 (UPPER (SPRIDEN_FIRST_NAME)) NOMBRE,
 (SELECT STVSTST_DESC
 FROM SGBSTDN N,STVSTST
 WHERE N.SGBSTDN_PIDM = TZTCOTA_PIDM
 AND N.SGBSTDN_STST_CODE = STVSTST_CODE
 AND N.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
 FROM SGBSTDN
 WHERE SGBSTDN_PIDM = N.SGBSTDN_PIDM))ALUMNO,
 (SELECT MAX (UPPER(SZTDTEC_PROGRAMA_COMP))
 FROM SZTDTEC
 WHERE SZTDTEC_PROGRAM = X.TZTCOTA_PROGRAMA)PROGRAMA,
 (SELECT A.GOREMAL_EMAIL_ADDRESS
 FROM GOREMAL A
 WHERE GOREMAL_PIDM = TZTCOTA_PIDM
 AND A.GOREMAL_EMAL_CODE = NVL ('PRIN', A.GOREMAL_EMAL_CODE)
 AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
 FROM GOREMAL A1
 WHERE A1.GOREMAL_EMAIL_ADDRESS = A.GOREMAL_EMAIL_ADDRESS
 AND A1.GOREMAL_PIDM = A.GOREMAL_PIDM
 AND A1.GOREMAL_EMAL_CODE = A.GOREMAL_EMAL_CODE))CORREO,
 TZTCOTA_ORIGEN ETIQUETA,
 TZTCOTA_CODIGO CODIGO_ACTUAL,
 GTVADID_DESC MEMBRESIA,
 (SELECT ZSTPARA_PARAM_DESC
 FROM ZSTPARA
 WHERE ZSTPARA_MAPA_ID = 'MEM_COD'
 AND ZSTPARA_PARAM_ID = X.TZTCOTA_CODIGO)PAGO,
 CASE
 WHEN (SELECT COUNT (*)
 FROM TZTCOTA
 WHERE TZTCOTA_PIDM = X.TZTCOTA_PIDM
 AND TZTCOTA_ORIGEN = X.TZTCOTA_ORIGEN
 AND TZTCOTA_SEQNO = X.TZTCOTA_SEQNO
 AND TZTCOTA_ORIGEN = GTVADID_CODE
 AND TZTCOTA_ORIGEN IN (SELECT GORADID_ADID_CODE
 FROM GORADID
 WHERE GORADID_PIDM = TZTCOTA_PIDM
 AND TZTCOTA_ORIGEN = GORADID_ADID_CODE
 AND TZTCOTA_ORIGEN = X.TZTCOTA_ORIGEN
 AND TZTCOTA_ORIGEN = GTVADID_CODE
 ))>0 THEN 'CON'
 ELSE
 'SIN'
 END ETIA,
 CASE
 WHEN TZTCOTA_STATUS = 'A' THEN 'ACTIVO'
 ELSE
 'INACTIVO'
 END ESTATUS
 FROM SPRIDEN, TZTCOTA X LEFT JOIN GTVADID ON (X.TZTCOTA_ORIGEN = GTVADID_CODE)
 WHERE SPRIDEN_PIDM= TZTCOTA_PIDM
 AND X.TZTCOTA_PIDM = P_PIDM
 AND SPRIDEN_CHANGE_IND IS NULL
-- AND X.TZTCOTA_CODIGO IN (SELECT ZSTPARA_PARAM_ID
-- FROM ZSTPARA,TZTCOTA
-- WHERE ZSTPARA_MAPA_ID = 'MEM_COD'
-- AND X.TZTCOTA_CODIGO = ZSTPARA_PARAM_ID)
 AND TZTCOTA_SEQNO = (SELECT MAX (TZTCOTA_SEQNO)
 FROM TZTCOTA
 WHERE TZTCOTA_PIDM = X.TZTCOTA_PIDM
 AND TZTCOTA_CODIGO = X.TZTCOTA_CODIGO);
-- AND TZTCOTA_FLAG = 1);
 END;

 ELSE

 BEGIN

 VL_ERROR:='No presenta historial';
 P_ERROR:=VL_ERROR;

 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:=NULL;
 P_ERROR:=VL_ERROR;
 END;

 END IF;

 RETURN (MEMBRESIA);


 END F_CURSOR_MEMBRESIA;

FUNCTION F_MEMBRESIA_REINA (P_PIDM NUMBER
 ,P_CODIGO VARCHAR2
 ,P_PROCESO VARCHAR2
 ,P_FECHA DATE DEFAULT NULL) RETURN VARCHAR2 IS

/*FUNCION PARA REACTIVAR E INACTIVAR MEMBRESIA
AUTOR: GGARCICA
FECHA: 04/03/2022*/

VL_CODIGO VARCHAR2(5);
VL_DESC VARCHAR2(35);
VL_ERROR VARCHAR2(900);
VL_SECUENCIA NUMBER;
VL_FECHA DATE;
VL_CARGOS NUMBER;
VL_EXISTE_CODIGO NUMBER;
VL_PARTE VARCHAR2(4);
VL_PARTE_1 VARCHAR2(4);
VL_NUM_CARG VARCHAR2(8);
VL_APLICADOS NUMBER;


BEGIN


 IF P_PROCESO = 'REACTIVA' THEN


 BEGIN
 SELECT DISTINCT MAX (SFRSTCR_PTRM_CODE)
 INTO VL_PARTE_1
 FROM SFRSTCR A
 WHERE 1= 1
 AND A.SFRSTCR_PIDM = P_PIDM
 AND SUBSTR (A.SFRSTCR_TERM_CODE, 5,1) NOT IN ('9','8')
 AND A.SFRSTCR_TERM_CODE = (SELECT MAX (A1.SFRSTCR_TERM_CODE)
 FROM SFRSTCR A1
 JOIN SSBSECT A2 ON A2.SSBSECT_TERM_CODE = A1.SFRSTCR_TERM_CODE
 AND A2.SSBSECT_CRN = A1.SFRSTCR_CRN
 WHERE A.SFRSTCR_PIDM = A1.SFRSTCR_PIDM);
 EXCEPTION
 WHEN OTHERS THEN
 VL_PARTE_1:= NULL;
 END;


 BEGIN

 FOR X IN (
 SELECT DISTINCT A.CAMPUS
 ,A.NIVEL
 ,A.PROGRAMA
 ,B.TZTORDR_TERM_CODE PERIODO
 ,B.TZTORDR_CONTADOR ORDEN
 ,A.SP STUDY
 ,A.FECHA_INICIO INICIO
 ,C.SORLCUR_VPDI_CODE
 ,TZTCOTA_SERVICIO SERVICIO
 ,TZTCOTA_CODIGO CODIGO
 ,TZTCOTA_CARGOS CARGOS
 ,TZTCOTA_APLICADOS APLICADOS
 ,TZTCOTA_ORIGEN ORIGEN
 ,TZTCOTA_STATUS STATUS
 ,TZTCOTA_SEQNO SEQNO
 ,TBBDETC_DESC DESCR
 ,FLOOR(TBBDETC_AMOUNT/TZTCOTA_CARGOS) MONTO
 ,TVRDCTX_CURR_CODE MONEDA
 FROM TBBDETC
 ,TVRDCTX
 ,TZTPROG A JOIN TZTCOTA ON A.PIDM = TZTCOTA_PIDM
 AND TZTCOTA_CODIGO = P_CODIGO
 AND TZTCOTA_SEQNO = (SELECT MAX(X.TZTCOTA_SEQNO)
 FROM TZTCOTA X
 WHERE X.TZTCOTA_PIDM = TZTCOTA_PIDM
 AND X.TZTCOTA_PIDM = A.PIDM
 AND X.TZTCOTA_CODIGO = P_CODIGO)
 JOIN TZTORDR B ON B.TZTORDR_PIDM = A.PIDM
 AND TZTORDR_CAMPUS = A.CAMPUS
 AND TZTORDR_NIVEL = A.NIVEL
 AND B.TZTORDR_CONTADOR = (SELECT MAX(B1.TZTORDR_CONTADOR)
 FROM TZTORDR B1
 WHERE B.TZTORDR_PIDM = B1.TZTORDR_PIDM)
 JOIN SORLCUR C ON C.SORLCUR_PIDM = A.PIDM
 AND C.SORLCUR_PROGRAM = A.PROGRAMA
 AND SORLCUR_LMOD_CODE = 'LEARNER'
 AND SORLCUR_ROLL_IND = 'Y'
 AND SORLCUR_CACT_CODE = 'ACTIVE'
 WHERE 1 = 1
 AND A.SP = (SELECT MAX (A1.SP)
 FROM TZTPROG A1
 WHERE A.CAMPUS = A1.CAMPUS
 AND A.NIVEL = A1.NIVEL
 AND A.PIDM = A1.PIDM)
 AND A.PIDM = P_PIDM
 AND TZTCOTA_CODIGO = TBBDETC_DETAIL_CODE
 AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE
 )LOOP

 VL_PARTE := NULL;
 VL_ERROR := NULL;
 VL_FECHA := NULL;
 VL_CODIGO := NULL;
 VL_DESC := NULL;
 VL_EXISTE_CODIGO := NULL;
 VL_NUM_CARG := NULL;
 VL_APLICADOS := NULL;

 IF VL_PARTE_1 IS NOT NULL THEN

 VL_PARTE:= VL_PARTE_1;

 END IF;

 IF P_FECHA IS NULL THEN

 VL_FECHA:= TRUNC(SYSDATE);

 ELSE

 VL_FECHA:= P_FECHA;

 END IF;


 IF X.STATUS = 'A' THEN

 IF X.CARGOS > 1 THEN

 BEGIN
 SELECT ZSTPARA_PARAM_VALOR,TBBDETC_DESC
 INTO VL_CODIGO,VL_DESC
 FROM ZSTPARA,TBBDETC
 WHERE ZSTPARA_PARAM_VALOR = TBBDETC_DETAIL_CODE
 AND ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
 AND ZSTPARA_PARAM_ID = X.CODIGO;

 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'ERROR AL CALCULAR CODIGO'||SQLERRM;
 END;

 -- DBMS_OUTPUT.PUT_LINE('CODIGO = '||VL_CODIGO||','||'DESC = '||VL_DESC);
 ELSE

 VL_CODIGO := X.CODIGO;
 VL_DESC := X.DESCR;

 END IF;

 -- DBMS_OUTPUT.PUT_LINE('FECHA = '||VL_FECHA);
 BEGIN
 SELECT COUNT(*)
 INTO VL_EXISTE_CODIGO
 FROM TBRACCD
 WHERE TBRACCD_DETAIL_CODE = VL_CODIGO ----CREAR PARAMETRIZADOR
 AND TO_CHAR(TRUNC(TBRACCD_EFFECTIVE_DATE) , 'MM/RRRR') = TO_CHAR(TRUNC(VL_FECHA) , 'MM/RRRR')
 AND (TBRACCD_DOCUMENT_NUMBER != 'WCANCE'
 OR TBRACCD_DOCUMENT_NUMBER IS NULL)
 AND TBRACCD_PIDM = P_PIDM;
 END;

 -- DBMS_OUTPUT.PUT_LINE('Existe Codigo = '||VL_EXISTE_CODIGO);
 -- DBMS_OUTPUT.PUT_LINE('Existe PARTE = '||VL_PARTE);

 CASE
 WHEN VL_EXISTE_CODIGO >=1 THEN
 VL_CARGOS:= 0;
 ELSE
 VL_CARGOS:= 1;
 END CASE;


 CASE
 WHEN X.CARGOS = 1 AND VL_DESC != 'UNICO' THEN
 VL_NUM_CARG:= 'RECURRE';
 ELSE
 VL_NUM_CARG:= (X.APLICADOS + 1 ) ||' | '|| X.CARGOS ;
 END CASE;


 BEGIN
 SELECT MAX(TBRACCD_TRAN_NUMBER)+1
 INTO VL_SECUENCIA
 FROM TBRACCD
 WHERE TBRACCD_PIDM = P_PIDM;

 EXCEPTION
 WHEN OTHERS THEN
 VL_SECUENCIA:= 0;
 END;

 -- DBMS_OUTPUT.PUT_LINE('Existe codigo = '||VL_EXISTE_CODIGO||'Cargos = '||X.CARGOS||'Aplicados'||X.APLICADOS);
 IF VL_EXISTE_CODIGO = 0 AND (X.APLICADOS < X.CARGOS OR X.APLICADOS IS NULL) THEN
 -- DBMS_OUTPUT.PUT_LINE('Existe codigo = '||VL_EXISTE_CODIGO||'Cargos = '||X.CARGOS||'Aplicados'||X.APLICADOS);

 IF TO_CHAR(VL_FECHA,'DD') > 20 THEN

 VL_FECHA:= ADD_MONTHS(VL_FECHA,1);

 END IF;


 CASE
 WHEN X.APLICADOS < X.CARGOS AND P_PROCESO = 'REACTIVA' THEN
 VL_APLICADOS:= X.APLICADOS + 1;
 ELSE
 VL_APLICADOS:= X.APLICADOS;
 END CASE;
 -- DBMS_OUTPUT.PUT_LINE('APLICADOS = '||VL_APLICADOS);
 -- DBMS_OUTPUT.PUT_LINE('FECHA = '||VL_FECHA);
 BEGIN
 INSERT INTO TBRACCD
 VALUES(P_PIDM, -- TBRACCD_PIDM
 VL_SECUENCIA, -- TBRACCD_TRAN_NUMBER
 X.PERIODO, -- TBRACCD_TERM_CODE
 VL_CODIGO, -- TBRACCD_DETAIL_CODE
 USER, -- TBRACCD_USER
 SYSDATE, -- TBRACCD_ENTRY_DATE
 NVL(X.MONTO,0), -- TBRACCD_AMOUNT
 NVL(X.MONTO,0), -- TBRACCD_BALANCE
 VL_FECHA, -- TBRACCD_EFFECTIVE_DATE
 NULL, -- TBRACCD_BILL_DATE
 NULL, -- TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
 VL_DESC, -- TBRACCD_DESC
 X.ORDEN, -- TBRACCD_RECEIPT_NUMBER
 NULL, -- TBRACCD_TRAN_NUMBER_PAID
 NULL, -- TBRACCD_CROSSREF_PIDM
 NULL, -- TBRACCD_CROSSREF_NUMBER
 NULL, -- TBRACCD_CROSSREF_DETAIL_CODE
 'T', -- TBRACCD_SRCE_CODE
 'Y', -- TBRACCD_ACCT_FEED_IND
 SYSDATE, -- TBRACCD_ACTIVITY_DATE
 0, -- TBRACCD_SESSION_NUMBER
 NULL, -- TBRACCD_CSHR_END_DATE
 NULL, -- TBRACCD_CRN
 NULL, -- TBRACCD_CROSSREF_SRCE_CODE
 NULL, -- TBRACCD_LOC_MDT
 NULL, -- TBRACCD_LOC_MDT_SEQ
 NULL, -- TBRACCD_RATE
 NULL, -- TBRACCD_UNITS
 NULL, -- TBRACCD_DOCUMENT_NUMBER
 VL_FECHA, -- TBRACCD_TRANS_DATE
 NULL, -- TBRACCD_PAYMENT_ID
 NULL, -- TBRACCD_INVOICE_NUMBER
 NULL, -- TBRACCD_STATEMENT_DATE
 NULL, -- TBRACCD_INV_NUMBER_PAID
 X.MONEDA, -- TBRACCD_CURR_CODE
 NULL, -- TBRACCD_EXCHANGE_DIFF
 NULL, -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
 NULL, -- TBRACCD_LATE_DCAT_CODE
 X.INICIO, -- TBRACCD_FEED_DATE
 VL_NUM_CARG, -- TBRACCD_FEED_DOC_CODE
 NULL, -- TBRACCD_ATYP_CODE
 NULL, -- TBRACCD_ATYP_SEQNO
 NULL, -- TBRACCD_CARD_TYPE_VR
 NULL, -- TBRACCD_CARD_EXP_DATE_VR
 NULL, -- TBRACCD_CARD_AUTH_NUMBER_VR
 NULL, -- TBRACCD_CROSSREF_DCAT_CODE
 NULL, -- TBRACCD_ORIG_CHG_IND
 NULL, -- TBRACCD_CCRD_CODE
 NULL, -- TBRACCD_MERCHANT_ID
 NULL, -- TBRACCD_TAX_REPT_YEAR
 NULL, -- TBRACCD_TAX_REPT_BOX
 NULL, -- TBRACCD_TAX_AMOUNT
 NULL, -- TBRACCD_TAX_FUTURE_IND
 'REACTIVA', -- TBRACCD_DATA_ORIGIN
 'TZFEDCA(ACC)', -- TBRACCD_CREATE_SOURCE
 NULL, -- TBRACCD_CPDT_IND
 NULL, -- TBRACCD_AIDY_CODE
 X.STUDY, -- TBRACCD_STSP_KEY_SEQUENCE
 VL_PARTE, -- TBRACCD_PERIOD
 NULL, -- TBRACCD_SURROGATE_ID
 NULL, -- TBRACCD_VERSION
 USER, -- TBRACCD_USER_ID
 NULL ); -- TBRACCD_VPDI_CODE
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'ERROR AL INSERTAR EN TBRACCD';
 END;


 IF VL_ERROR IS NOT NULL THEN
 -- ROLLBACK;---SE COMENTA PARA QUE PERMITA GUARDAR EN LA BOTACORA EL ERROR-------

 BEGIN
 UPDATE TZTCOTA
 SET TZTCOTA_OBSERVACIONES = VL_ERROR
 WHERE TZTCOTA_PIDM = P_PIDM
 AND TZTCOTA_SEQNO = X.SEQNO;
 END;

 COMMIT;
 ELSE

 BEGIN
 UPDATE TZTCOTA
 SET TZTCOTA_APLICADOS = VL_APLICADOS
 WHERE 1=1
 AND TZTCOTA_PIDM = P_PIDM
 AND TZTCOTA_STATUS = 'A'
 AND TZTCOTA_CODIGO = X.CODIGO
 AND TZTCOTA_SEQNO = X.SEQNO;

 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:='ERROR AL ACTUALIZAR CARGO = '||P_PIDM||'='||SQLERRM;
 END;

 VL_ERROR:='EXITO';

 COMMIT;
 END IF;

 END IF;

 END IF;

 END LOOP;

 END;

 IF VL_ERROR IS NULL THEN

 VL_ERROR:= 'EXITO';

 END IF;

 RETURN VL_ERROR;
-- DBMS_OUTPUT.PUT_LINE('SALIDA = '||VL_ERROR);
 END IF;

END F_MEMBRESIA_REINA;

FUNCTION F_INS_REACTIVA (P_PIDM NUMBER
 ,P_CODIGO VARCHAR2
 ,P_PROCESO VARCHAR2
 ,P_USUARIO VARCHAR2
 ,P_ETIQUETA VARCHAR2) RETURN VARCHAR2 IS

/* Función: Reactiva/Inactiva membresia
 * Autor: GGC@Create -> FND@Update
 * Fecha: 07/11/2022
 */

VL_ERROR VARCHAR2(900) := NULL;
VL_SEQNO NUMBER := 0;
VL_DESC VARCHAR2(100) := NULL;
VL_ESTATUS VARCHAR2(1) := NULL;
VL_CARGOS NUMBER := 0;
VL_BITACORA VARCHAR2(900) := NULL;


BEGIN
 DBMS_OUTPUT.PUT_LINE('---Parámetros de entrada---'||CHR(10)
 ||'Pidm : '||P_PIDM||CHR(10)
 ||'Cod. Detalle : '||P_CODIGO||CHR(10)
 ||'Tipo Proceso (Reac/Inac) : '||P_PROCESO||CHR(10)
 ||'Etiqueta : '||P_ETIQUETA||CHR(10)
 ||'Usuario : '||P_USUARIO||CHR(10)||CHR(10));
 FOR X IN (

 SELECT DISTINCT A.CAMPUS
 ,A.NIVEL
 ,A.PROGRAMA
 ,B.TZTORDR_TERM_CODE PERIODO
 ,B.TZTORDR_CONTADOR
 ,A.SP
 ,A.FECHA_INICIO
 ,C.SORLCUR_VPDI_CODE
 ,TZTCOTA_SERVICIO SERVICIO
 ,TZTCOTA_CODIGO CODIGO
 ,TZTCOTA_CARGOS CARGOS
 ,TZTCOTA_APLICADOS APLICADOS
 ,TZTCOTA_MONTO MONTO
 ,TZTCOTA_ORIGEN ORIGEN
 FROM TZTPROG A
 JOIN TZTCOTA ON A.PIDM = TZTCOTA_PIDM
 AND TZTCOTA_CODIGO = P_CODIGO
 AND TZTCOTA_SEQNO = (SELECT MAX(X.TZTCOTA_SEQNO)
 FROM TZTCOTA X
 WHERE X.TZTCOTA_PIDM = TZTCOTA_PIDM
 AND X.TZTCOTA_PIDM = A.PIDM
 AND X.TZTCOTA_CODIGO = P_CODIGO)
 JOIN TZTORDR B ON B.TZTORDR_PIDM = A.PIDM
 AND TZTORDR_CAMPUS = A.CAMPUS
 AND TZTORDR_NIVEL = A.NIVEL
 AND B.TZTORDR_CONTADOR = (SELECT MAX(B1.TZTORDR_CONTADOR)
 FROM TZTORDR B1
 WHERE B.TZTORDR_PIDM = B1.TZTORDR_PIDM)
 JOIN SORLCUR C ON C.SORLCUR_PIDM = A.PIDM
 AND C.SORLCUR_PROGRAM = A.PROGRAMA
 AND SORLCUR_LMOD_CODE = 'LEARNER'
 AND SORLCUR_ROLL_IND = 'Y'
 AND SORLCUR_CACT_CODE = 'ACTIVE'
 WHERE 1= 1
 AND A.SP = (SELECT MAX(A1.SP)
 FROM TZTPROG A1
 WHERE A.CAMPUS = A1.CAMPUS
 AND A.NIVEL = A1.NIVEL
 AND A.PIDM = A1.PIDM)
 AND A.PIDM = P_PIDM


 ) LOOP


DBMS_OUTPUT.PUT_LINE('---Parámetros del cursor X para Pidm: '||P_PIDM||CHR(10)
 ||'Campus : '||X.CAMPUS||CHR(10)
 ||'Nivel : '||X.NIVEL||CHR(10)
 ||'Programa : '||X.PROGRAMA||CHR(10)
 ||'Periodo : '||X.PERIODO||CHR(10)
 ||'Contador : '||X.SERVICIO||CHR(10)
 ||'Study Path : '||X.SP||CHR(10)
 ||'Fecha de Inicio : '||X.FECHA_INICIO||CHR(10)
 ||'Parte Periodo : '||X.SORLCUR_VPDI_CODE||CHR(10)
 ||'Servicio : '||X.SERVICIO||CHR(10)
 ||'Código de Detalle : '||X.CODIGO||CHR(10)
 ||'Cargos : '||X.CARGOS||CHR(10)
 ||'Aplicados : '||X.APLICADOS||CHR(10)
 ||'Monto : '||X.MONTO||CHR(10)
 ||'Origen / Etiqueta : '||X.ORIGEN||CHR(10)||CHR(10));


-- VL_ERROR := NULL;
-- VL_SEQNO := NULL;
-- VL_DESC := NULL;
---- VL_APLICADOS := NULL;
-- VL_ESTATUS := NULL;
-- VL_CARGOS := NULL;
-- VL_BITACORA := NULL;

 BEGIN
 SELECT COUNT (1)
 INTO VL_SEQNO
 FROM TZTCOTA
 WHERE TZTCOTA_PIDM = P_PIDM;

 DBMS_OUTPUT.PUT_LINE('Secuencia: '||VL_SEQNO||CHR(10)||CHR(10));

 EXCEPTION
 WHEN OTHERS THEN
 VL_SEQNO:=0;
 DBMS_OUTPUT.PUT_LINE('Secuencia: '||VL_SEQNO||CHR(10)||CHR(10));
 END;

 VL_SEQNO := VL_SEQNO + 1;
 DBMS_OUTPUT.PUT_LINE('Secuencia: '||VL_SEQNO||CHR(10)||CHR(10));


 BEGIN
 SELECT ZSTPARA_PARAM_DESC,ZSTPARA_PARAM_VALOR
 INTO VL_DESC,VL_CARGOS
 FROM ZSTPARA
 WHERE ZSTPARA_PARAM_ID = P_CODIGO
 AND ZSTPARA_MAPA_ID = 'MEM_COD'
 AND ZSTPARA_PARAM_VALOR = X.CARGOS;

 DBMS_OUTPUT.PUT_LINE('---Valores del agrupador: MEM_COD---'||CHR(10)
 ||'Descripción : '||VL_DESC||CHR(10)
 ||'Valor -> Cargos : '||VL_CARGOS||CHR(10)||CHR(10));

 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 VL_ERROR := 'No existe/encuentra el código de detalle '||P_CODIGO||' en el agrupador MEM_COD... Favor de revisar...'||CHR(10)||'SQLCODE :' ||SQLCODE||CHR(10)||SQLERRM;
 END;

 IF P_PROCESO = 'REACTIVA' THEN
 VL_ESTATUS:= 'A';
 VL_BITACORA:= 'REACTIVA';
 DBMS_OUTPUT.PUT_LINE('Si P_PROCESO es : '||P_PROCESO||', entonces el estatus es: '||VL_ESTATUS||CHR(10)||CHR(10));
 ELSE
 VL_ESTATUS:= 'I';
 VL_BITACORA:= 'INACTIVA';
 DBMS_OUTPUT.PUT_LINE('Si P_PROCESO es : '||P_PROCESO||', entonces el estatus es: '||VL_ESTATUS||CHR(10)||CHR(10));
 END IF;


 BEGIN

 INSERT INTO TZTCOTA(TZTCOTA_PIDM
 ,TZTCOTA_TERM_CODE
 ,TZTCOTA_CAMPUS
 ,TZTCOTA_NIVEL
 ,TZTCOTA_PROGRAMA
 ,TZTCOTA_CODIGO
 ,TZTCOTA_SERVICIO
 ,TZTCOTA_CARGOS
 ,TZTCOTA_APLICADOS
 ,TZTCOTA_MONTO
 ,TZTCOTA_DESCUENTO
 ,TZTCOTA_SEQNO
 ,TZTCOTA_FLAG
 ,TZTCOTA_USER
 ,TZTCOTA_ORIGEN
 ,TZTCOTA_STATUS
 ,TZTCOTA_FECHA_INI
 ,TZTCOTA_ACTIVITY
 ,TZTCOTA_OBSERVACIONES)
 VALUES(P_PIDM -->TZTCOTA_PIDM
 ,X.PERIODO -->TZTCOTA_TERM_CODE
 ,X.CAMPUS -->TZTCOTA_CAMPUS
 ,X.NIVEL -->TZTCOTA_NIVEL
 ,X.PROGRAMA -->TZTCOTA_PROGRAMA
 ,X.CODIGO -->TZTCOTA_CODIGO
 ,X.SERVICIO -->TZTCOTA_SERVICIO
 ,X.CARGOS -->TZTCOTA_CARGOS
 ,X.APLICADOS -->TZTCOTA_APLICADOS
 ,X.MONTO -->TZTCOTA_MONTO
 ,NULL -->TZTCOTA_DESCUENTO
 ,VL_SEQNO -->TZTCOTA_SEQNO
 ,1 -->TZTCOTA_FLAG
 ,P_USUARIO -->TZTCOTA_USER
 ,X.ORIGEN -->TZTCOTA_ORIGEN
 ,VL_ESTATUS -->TZTCOTA_STATUS
 ,X.FECHA_INICIO -->TZTCOTA_FECHA_INI
 ,SYSDATE -->TZTCOTA_ACTIVITY
 ,VL_BITACORA); -->TZTCOTA_OBSERVACIONES

DBMS_OUTPUT.PUT_LINE('---Valores para insertar en TZTCOTA: '||P_PIDM||CHR(10)
 ||'Campus : '||X.CAMPUS||CHR(10)
 ||'Nivel : '||X.NIVEL||CHR(10)
 ||'Programa : '||X.PROGRAMA||CHR(10)
 ||'Periodo : '||X.PERIODO||CHR(10)
 ||'Contador : '||X.SERVICIO||CHR(10)
 ||'Study Path : '||X.SP||CHR(10)
 ||'Fecha de Inicio : '||X.FECHA_INICIO||CHR(10)
 ||'Parte Periodo : '||X.SORLCUR_VPDI_CODE||CHR(10)
 ||'Servicio : '||X.SERVICIO||CHR(10)
 ||'Código de Detalle : '||X.CODIGO||CHR(10)
 ||'Cargos : '||X.CARGOS||CHR(10)
 ||'Aplicados : '||X.APLICADOS||CHR(10)
 ||'Monto : '||X.MONTO||CHR(10)
 ||'Secuencia : '||VL_SEQNO||CHR(10)
 ||'Estatus : '||VL_ESTATUS||CHR(10)
 ||'Observaciones : '||VL_BITACORA||CHR(10)
 ||'Origen / Etiqueta : '||X.ORIGEN||CHR(10)||CHR(10));


 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'ERROR AL INSERTAR EN TZTCOTA '||CHR(10)||'SQLCODE :'||CHR(10)||SQLERRM;
 DBMS_OUTPUT.PUT_LINE(VL_ERROR||CHR(10)||'SQLCODE :'||CHR(10)||SQLERRM);
 END;


 IF VL_ERROR IS NOT NULL THEN
 ROLLBACK;

 BEGIN
 UPDATE TZTCOTA
 SET TZTCOTA_OBSERVACIONES = VL_ERROR
 WHERE TZTCOTA_PIDM = P_PIDM
 AND TZTCOTA_SEQNO = VL_SEQNO;

 END;
 COMMIT;

 ELSE
 VL_ERROR:= 'EXITO';
 COMMIT;
 END IF;

 END LOOP;

-- DBMS_OUTPUT.PUT_LINE ('SALIDA = '||VL_ERROR);

RETURN VL_ERROR;

END F_INS_REACTIVA;

FUNCTION F_CURSOR_DATOS_ALUMNO (P_PIDM IN NUMBER ) RETURN PKG_FINANZAS_UTLX.CURSOR_DATOS_ALUMNO AS
DATOS_ALUMNO PKG_FINANZAS_UTLX.CURSOR_DATOS_ALUMNO;


VL_ID NUMBER;



 BEGIN

 BEGIN

 SELECT COUNT(SPRIDEN_ID)
 INTO VL_ID
 FROM SPRIDEN
 WHERE SPRIDEN_PIDM = P_PIDM
 AND SPRIDEN_CHANGE_IND IS NULL;
 EXCEPTION
 WHEN OTHERS THEN
 VL_ID:= 0;
 END;


 IF VL_ID > 0 THEN

 BEGIN
 OPEN DATOS_ALUMNO
 FOR
 SELECT DISTINCT
 SPRIDEN_ID MATRICULA,
 (REPLACE (UPPER(SPRIDEN_LAST_NAME),'/',' '))||' '||
 (UPPER (SPRIDEN_FIRST_NAME)) NOMBRE,
 ESTATUS_D ESTATUS,
-- (SELECT STVSTST_DESC
-- FROM SGBSTDN N,STVSTST
-- WHERE N.SGBSTDN_PIDM = SPRIDEN_PIDM
-- AND N.SGBSTDN_STST_CODE = STVSTST_CODE
-- AND N.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
-- FROM SGBSTDN
-- WHERE SGBSTDN_PIDM = N.SGBSTDN_PIDM))ALUMNO
 (SELECT MAX (UPPER(SZTDTEC_PROGRAMA_COMP))
 FROM SZTDTEC
 WHERE SZTDTEC_PROGRAM = PROGRAMA)PROGRAMA,
 (SELECT A.GOREMAL_EMAIL_ADDRESS
 FROM GOREMAL A
 WHERE GOREMAL_PIDM = PIDM
 And a.GOREMAL_STATUS_IND = 'A'
 And a.GOREMAL_PREFERRED_IND ='Y'
 AND A.GOREMAL_EMAL_CODE = NVL ('PRIN', A.GOREMAL_EMAL_CODE)
 AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
 FROM GOREMAL A1
 WHERE A1.GOREMAL_EMAIL_ADDRESS = A.GOREMAL_EMAIL_ADDRESS
 AND A1.GOREMAL_PIDM = A.GOREMAL_PIDM
 AND A1.GOREMAL_EMAL_CODE = A.GOREMAL_EMAL_CODE))CORREO
 FROM SPRIDEN LEFT JOIN TZTPROG ON (SPRIDEN_PIDM = PIDM)
 WHERE 1=1
 AND SPRIDEN_CHANGE_IND IS NULL
 AND PIDM = P_PIDM;


 RETURN(DATOS_ALUMNO);

 END;

 ELSE

 OPEN DATOS_ALUMNO
 FOR
 SELECT 'Sin registro en SPRIDEN.',NULL,NULL,NULL,NULL
 FROM DUAL;
 RETURN(DATOS_ALUMNO);

 END IF;

 END F_CURSOR_DATOS_ALUMNO;

 FUNCTION CANCE_PACCESORIOS (P_PIDM NUMBER, P_SERVICIO VARCHAR2) RETURN VARCHAR2 IS

VL_ERROR VARCHAR2(900);
VL_DESCRI_ACC VARCHAR2(30);
VL_MONEDA VARCHAR2(3);
VL_COD_CANCE VARCHAR2(4);
VL_SECUENCIA NUMBER;
VL_BALANCE NUMBER;
VL_TRAN NUMBER;



 BEGIN

 FOR CAN IN (

 SELECT TBRACCD_PIDM,
 TBRACCD_TRAN_NUMBER,
 TBRACCD_DESC,
 TBRACCD_AMOUNT,
 TBRACCD_TERM_CODE,
 TBRACCD_PERIOD,
 TBRACCD_EFFECTIVE_DATE,
 TBRACCD_STSP_KEY_SEQUENCE,
 TBRACCD_FEED_DATE,
 TBRACCD_RECEIPT_NUMBER,
 TBBDETC_TYPE_IND,
 SPRIDEN_ID
 FROM SPRIDEN,TBRACCD,TBBDETC
 WHERE SPRIDEN_PIDM = TBRACCD_PIDM
 AND SPRIDEN_CHANGE_IND IS NULL
 AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
 AND TBRACCD_PIDM = P_PIDM
 AND TBRACCD_CROSSREF_NUMBER = P_SERVICIO
-- AND TRUNC(TBRACCD_EFFECTIVE_DATE) > TRUNC(SYSDATE)
 AND (TBRACCD_DOCUMENT_NUMBER != 'WCANCE'
 OR TBRACCD_DOCUMENT_NUMBER IS NULL)
-- AND TBRACCD_AMOUNT > 0
 ORDER BY TBBDETC_TYPE_IND

 )LOOP

 VL_ERROR:= NULL;
 VL_DESCRI_ACC:= NULL;
 VL_MONEDA:= NULL;
 VL_SECUENCIA:= NULL;
 VL_BALANCE:= NULL;
 VL_TRAN:= NULL;
 VL_COD_CANCE:= NULL;

 IF CAN.TBBDETC_TYPE_IND = 'C' THEN
 VL_BALANCE := CAN.TBRACCD_AMOUNT*-1;
 VL_COD_CANCE := SUBSTR(CAN.SPRIDEN_ID,1,2)||'WM';
 VL_TRAN:= NULL;
 ELSIF CAN.TBBDETC_TYPE_IND = 'P' THEN
 VL_BALANCE:= CAN.TBRACCD_AMOUNT;
 VL_COD_CANCE := SUBSTR(CAN.SPRIDEN_ID,1,2)||'BU';
 VL_TRAN:= CAN.TBRACCD_TRAN_NUMBER;
 END IF;


 IF CAN.TBBDETC_TYPE_IND = 'P' THEN

 PKG_FINANZAS.P_DESAPLICA_PAGOS(CAN.TBRACCD_PIDM,CAN.TBRACCD_TRAN_NUMBER);

 END IF;


 BEGIN
 SELECT MAX(TBRACCD_TRAN_NUMBER)+1
 INTO VL_SECUENCIA
 FROM TBRACCD WHERE TBRACCD_PIDM = CAN.TBRACCD_PIDM;
 EXCEPTION
 WHEN OTHERS THEN
 VL_SECUENCIA:= 0;
 END;


 BEGIN
 SELECT TBBDETC_DESC,TVRDCTX_CURR_CODE
 INTO VL_DESCRI_ACC,VL_MONEDA
 FROM TBBDETC,TVRDCTX
 WHERE TBBDETC_DETAIL_CODE = VL_COD_CANCE
 AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE;
 EXCEPTION
 WHEN OTHERS THEN
 VL_DESCRI_ACC:=NULL;
 END;


 BEGIN
 INSERT
 INTO TBRACCD
 VALUES ( CAN.TBRACCD_PIDM, -- TBRACCD_PIDM
 VL_SECUENCIA, -- TBRACCD_TRAN_NUMBER
 CAN.TBRACCD_TERM_CODE, -- TBRACCD_TERM_CODE
 VL_COD_CANCE, -- TBRACCD_DETAIL_CODE
 USER, -- TBRACCD_USER
 SYSDATE, -- TBRACCD_ENTRY_DATE
 NVL(CAN.TBRACCD_AMOUNT,0), -- TBRACCD_AMOUNT
 NVL(VL_BALANCE,0), -- TBRACCD_BALANCE
 SYSDATE, -- TBRACCD_EFFECTIVE_DATE
 NULL, -- TBRACCD_BILL_DATE
 NULL, -- TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
 VL_DESCRI_ACC, -- TBRACCD_DESC
 CAN.TBRACCD_RECEIPT_NUMBER, -- TBRACCD_RECEIPT_NUMBER
 VL_TRAN , -- TBRACCD_TRAN_NUMBER_PAID
 NULL, -- TBRACCD_CROSSREF_PIDM
 NULL, -- TBRACCD_CROSSREF_NUMBER
 NULL, -- TBRACCD_CROSSREF_DETAIL_CODE
 'T', -- TBRACCD_SRCE_CODE
 'Y', -- TBRACCD_ACCT_FEED_IND
 SYSDATE, -- TBRACCD_ACTIVITY_DATE
 0, -- TBRACCD_SESSION_NUMBER
 NULL, -- TBRACCD_CSHR_END_DATE
 NULL, -- TBRACCD_CRN
 NULL, -- TBRACCD_CROSSREF_SRCE_CODE
 NULL, -- TBRACCD_LOC_MDT
 NULL, -- TBRACCD_LOC_MDT_SEQ
 NULL, -- TBRACCD_RATE
 NULL, -- TBRACCD_UNITS
 NULL, -- TBRACCD_DOCUMENT_NUMBER
 SYSDATE, -- TBRACCD_TRANS_DATE
 NULL, -- TBRACCD_PAYMENT_ID
 NULL, -- TBRACCD_INVOICE_NUMBER
 NULL, -- TBRACCD_STATEMENT_DATE
 NULL, -- TBRACCD_INV_NUMBER_PAID
 VL_MONEDA, -- TBRACCD_CURR_CODE
 NULL, -- TBRACCD_EXCHANGE_DIFF
 NULL, -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
 NULL, -- TBRACCD_LATE_DCAT_CODE
 CAN.TBRACCD_FEED_DATE, -- TBRACCD_FEED_DATE
 NULL, -- TBRACCD_FEED_DOC_CODE
 NULL, -- TBRACCD_ATYP_CODE
 NULL, -- TBRACCD_ATYP_SEQNO
 NULL, -- TBRACCD_CARD_TYPE_VR
 NULL, -- TBRACCD_CARD_EXP_DATE_VR
 NULL, -- TBRACCD_CARD_AUTH_NUMBER_VR
 NULL, -- TBRACCD_CROSSREF_DCAT_CODE
 NULL, -- TBRACCD_ORIG_CHG_IND
 NULL, -- TBRACCD_CCRD_CODE
 NULL, -- TBRACCD_MERCHANT_ID
 NULL, -- TBRACCD_TAX_REPT_YEAR
 NULL, -- TBRACCD_TAX_REPT_BOX
 NULL, -- TBRACCD_TAX_AMOUNT
 NULL, -- TBRACCD_TAX_FUTURE_IND
 'WCANCE', -- TBRACCD_DATA_ORIGIN
 'WCANCE', -- TBRACCD_CREATE_SOURCE
 NULL, -- TBRACCD_CPDT_IND
 NULL, -- TBRACCD_AIDY_CODE
 CAN.TBRACCD_STSP_KEY_SEQUENCE, -- TBRACCD_STSP_KEY_SEQUENCE
 CAN.TBRACCD_PERIOD, -- TBRACCD_PERIOD
 NULL, -- TBRACCD_SURROGATE_ID
 NULL, -- TBRACCD_VERSION
 USER, -- TBRACCD_USER_ID
 NULL ); -- TBRACCD_VPDI_CODE
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR := 'Se presento ERROR INSERT TBRACCD '||SQLERRM;
 END;


 BEGIN
 UPDATE TBRACCD
 SET TBRACCD_DOCUMENT_NUMBER = 'WCANCE',
 TBRACCD_TRAN_NUMBER_PAID = NULL
 WHERE TBRACCD_PIDM = CAN.TBRACCD_PIDM
 AND TBRACCD_TRAN_NUMBER = CAN.TBRACCD_TRAN_NUMBER;

 UPDATE TVRACCD
 SET TVRACCD_DOCUMENT_NUMBER = 'WCANCE',
 TVRACCD_TRAN_NUMBER_PAID = NULL
 WHERE TVRACCD_PIDM = CAN.TBRACCD_PIDM
 AND TVRACCD_ACCD_TRAN_NUMBER = CAN.TBRACCD_TRAN_NUMBER;
 END;

 IF VL_ERROR IS NULL THEN
 VL_ERROR:= 'EXITO';
 ELSE
 VL_ERROR:=VL_ERROR;
 END IF;

 END LOOP;
 COMMIT;
 RETURN (VL_ERROR);


 END CANCE_PACCESORIOS;

PROCEDURE P_MEMBRESIA_UTELX IS

vl_existe_cargo number:=0;
VL_DIA VARCHAR2(2);
VL_MES VARCHAR2(2);
VL_ANO VARCHAR2(4);
VL_VENCIMIENTO VARCHAR2(15);
VL_SECUENCIA Number:=0;
VL_SEC_CARGO Number:=0;
vl_codigo_cargo varchar2(4):= null;
vl_costo_cargo Number:=0;
vl_codigo_Descrip varchar2(250):= null;
vl_moneda varchar2(6):= null;
vl_orden number:=0;
VL_ERROR varchar2(500):= null;
vl_desc_venta number:=0;

 Begin

 For cx in (

 select distinct A.pidm,
 a.matricula,
 a.campus,
 a.nivel,
 fget_periodo_general (substr (a.matricula,1,2), trunc (sysdate)) Periodo,
 a.programa,
 a.sp,
 c.TZFACCE_EFFECTIVE_DATE,
 c.TZFACCE_DETAIL_CODE Codigo,
 nvl (c.TZFACCE_AMOUNT,0) Monto_Cargo,
 c.TZFACCE_FLAG,
 a.estatus,
 a.fecha_inicio,
 a.FECHA_PRIMERA,
 b.SZTUTLX_SEQ_NO Seq,
 b.SZTUTLX_DISABLE_IND,
 b.SZTUTLX_OBS,
 nvl (b.SZTUTLX_GRATIS,0) Mes_Gratis_SSB,
 nvl (b.SZTUTLX_GRATIS_APLI,0) Aplicados_SSB,
 nvl (b.SZTUTLX_ROW2,0) MES_GRATIS_Ret,
 nvl (b.SZTUTLX_ROW3,0) Descuento_Venta,
 pkg_utilerias.f_etiqueta(a.pidm, 'UTLX') etiqueta,
 d.sgbstdn_rate_code Rate,
 (DECODE (SUBSTR (d.SGBSTDN_RATE_CODE, 4, 1), 'A', 15, 'B', '30', 'C', '10')) VENCIMIENTO
 from tztprog a
 join SZTUTLX b on b.SZTUTLX_PIDM = a.pidm and b.SZTUTLX_STAT_IND in ('1','2') and b.SZTUTLX_SEQ_NO = (select max (b1.SZTUTLX_SEQ_NO)
 from SZTUTLX b1
 Where 1= 1
 And b.SZTUTLX_PIDM = b1.SZTUTLX_PIDM
 And b1.SZTUTLX_STAT_IND = b.SZTUTLX_STAT_IND
 )
 left join TZFACCE c on c.TZFACCE_PIDM = a.pidm and substr (TZFACCE_DETAIL_CODE, 3,2) in ( 'QI', 'QG') --and TZFACCE_AMOUNT > 0
 join SGBSTDN d on d.sgbstdn_pidm = a.pidm and d.SGBSTDN_PROGRAM_1 = a.programa And d.SGBSTDN_TERM_CODE_EFF IN (SELECT MAX (d1.SGBSTDN_TERM_CODE_EFF)
 FROM SGBSTDN d1
 WHERE d.SGBSTDN_PIDM = d1.SGBSTDN_PIDM
 AND d.SGBSTDN_PROGRAM_1 = d1.SGBSTDN_PROGRAM_1
 )
 where 1= 1
 and a.sp = (select max (a1.sp)
 from tztprog a1
 where a.pidm = a1.pidm)
 and a.estatus in ('MA')
 and b.SZTUTLX_DISABLE_IND = 'A'
 And SZTUTLX_USER_BLOQUEO is null
 And trunc (a.fecha_inicio) <= trunc (sysdate)
-- And a.matricula in ( '010010780')


 ) loop


 ------------- Valido que no tenga el cargo en el mes

 vl_existe_cargo :=0;
 VL_DIA := NULL;
 VL_MES := NULL;
 VL_ANO := NULL;
 VL_VENCIMIENTO := NULL;
 VL_SECUENCIA :=0;
 VL_SEC_CARGO :=0;
 vl_codigo_cargo := null;
 vl_codigo_Descrip := null;
 vl_costo_cargo :=0;
 vl_moneda := null;
 vl_orden := null;


 If cx.codigo is not null then
 vl_codigo_cargo:= cx.codigo;
 vl_costo_cargo := cx.monto_cargo;
 --DBMS_OUTPUT.PUT_LINE('Codigo_Venta = '||vl_codigo_cargo||'*'||vl_costo_cargo );

 else
 Begin
 Select ZSTPARA_PARAM_DESC Monto, ZSTPARA_PARAM_VALOR Codigo
 Into vl_costo_cargo, vl_codigo_cargo
 from ZSTPARA
 Where ZSTPARA_MAPA_ID = 'COSTO_UTELX'
 And ZSTPARA_PARAM_ID = cx.campus;
 --DBMS_OUTPUT.PUT_LINE('Codigo_SSB = '||vl_codigo_cargo||'*'||vl_costo_cargo );
 Exception
 When Others then
 vl_costo_cargo:= null;
 vl_codigo_cargo:= null;
 End;

 End if;


 --------------------------- Este codigo se tiene que quitar al momento de integrar al paquete

-- Begin
-- Update tbraccd
-- set TBRACCD_EFFECTIVE_DATE = trunc (TBRACCD_EFFECTIVE_DATE) -30
-- where tbraccd_pidm = cx.pidm
-- and tbraccd_detail_code =vl_codigo_cargo ;
-- commit;
-- Exception
-- When OThers then
-- null;
-- End;




 Begin

 Select count(*)
 Into vl_existe_cargo
 from tbraccd
 where 1= 1
 and tbraccd_pidm = cx.pidm
 And substr (tbraccd_detail_code,3,2) in ('QI', 'NA')--= vl_codigo_cargo
 And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE));

 Exception
 When Others then
 vl_existe_cargo:=0;
 End;


 If vl_existe_cargo = 0 and vl_costo_cargo>0 then
 --DBMS_OUTPUT.PUT_LINE('Entra a Generar Cargo' );


 BEGIN

 VL_DIA := cx.VENCIMIENTO;
 VL_MES := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 4, 2);
 VL_ANO := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 7, 4);

 IF VL_DIA = '30' THEN
 VL_VENCIMIENTO := CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
 ELSE
 VL_VENCIMIENTO := VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
 END IF;

 END;

 --DBMS_OUTPUT.PUT_LINE('Vencimiento = '||VL_VENCIMIENTO );

 VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);
 VL_SEC_CARGO:= VL_SECUENCIA;

 BEGIN

 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
 Into vl_codigo_Descrip, vl_moneda
 FROM TBBDETC
 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
 WHERE TBBDETC_DETAIL_CODE = vl_codigo_cargo;
 --DBMS_OUTPUT.PUT_LINE('Recupera Codigos = '||vl_codigo_Descrip ||'*'|| vl_moneda);

 Exception
 When Others then
 vl_codigo_Descrip:= null;
 --DBMS_OUTPUT.PUT_LINE('Error Recupera Codigos = '||sqlerrm );
 END;

 Begin
 Select TZTORDR_CONTADOR
 Into vl_orden
 from TZTORDR
 where TZTORDR_PIDM = cx.pidm
 And TZTORDR_CAMPUS = cx.campus
 And TZTORDR_NIVEL = cx.nivel
 And TZTORDR_ESTATUS = 'S'
 And trunc (TZTORDR_FECHA_INICIO) = cx.fecha_inicio;
 Exception
 When Others then
 vl_orden:= null;
 End;

 If vl_orden is null then

 BEGIN
 SELECT MAX(TZTORDR_CONTADOR)+1
 INTO vl_orden
 FROM TZTORDR;
 EXCEPTION
 WHEN OTHERS THEN
 vl_orden:= NULL;
 END;

 IF vl_orden IS NOT NULL THEN

 BEGIN

 INSERT INTO TZTORDR
 (
 TZTORDR_CAMPUS,
 TZTORDR_NIVEL,
 TZTORDR_CONTADOR,
 TZTORDR_PROGRAMA,
 TZTORDR_PIDM,
 TZTORDR_ID,
 TZTORDR_ESTATUS,
 TZTORDR_ACTIVITY_DATE,
 TZTORDR_USER,
 TZTORDR_DATA_ORIGIN,
 TZTORDR_NO_REGLA,
 TZTORDR_FECHA_INICIO,
 TZTORDR_RATE,
 TZTORDR_JORNADA,
 TZTORDR_DSI,
 TZTORDR_TERM_CODE
 )
 VALUES( cx.CAMPUS,
 cx.NIVEL,
 vl_orden,
 cx.PROGRAMA,
 cx.PIDM,
 cx.MATRICULA,
 'S',
 SYSDATE,
 USER,
 'AUTO_UTELX',
 NULL,
 TRUNC(SYSDATE),
 NULL,
 NULL,
 NULL,
 cx.PERIODO
 );
 VL_ERROR:='EXITO';
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR:= 'ERROR AL INSERTAR EN TZTORDR = '||sqlerrm;
 --DBMS_OUTPUT.PUT_LINE('Error al inserta Orden = '||VL_ERROR );
 END;

 END IF;


 end if;

 --DBMS_OUTPUT.PUT_LINE('Recupera Orden = '||vl_orden );

 BEGIN
 INSERT INTO TBRACCD VALUES (
 cx.PIDM, --TBRACCD_PIDM
 VL_SEC_CARGO, --TBRACCD_TRAN_NUMBER
 cx.PERIODO, --TBRACCD_TERM_CODE
 vl_codigo_cargo, --TBRACCD_DETAIL_CODE
 USER, --TBRACCD_USER
 SYSDATE, --TBRACCD_ENTRY_DATE
 vl_costo_cargo, --TBRACCD_AMOUNT
 vl_costo_cargo, --TBRACCD_BALANCE
 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
 NULL, --TBRACCD_BILL_DATE
 NULL, --TBRACCD_DUE_DATE
 vl_codigo_Descrip, --TBRACCD_DESC
 vl_orden, --TBRACCD_RECEIPT_NUMBER
 null, --TBRACCD_TRAN_NUMBER_PAID
 NULL, --TBRACCD_CROSSREF_PIDM
 NULL, --TBRACCD_CROSSREF_NUMBER
 NULL, --TBRACCD_CROSSREF_DETAIL_CODE
 'T', --TBRACCD_SRCE_CODE
 'Y', --TBRACCD_ACCT_FEED_IND
 SYSDATE, --TBRACCD_ACTIVITY_DATE
 0, --TBRACCD_SESSION_NUMBER
 NULL, --TBRACCD_CSHR_END_DATE
 NULL, --TBRACCD_CRN
 NULL, --TBRACCD_CROSSREF_SRCE_CODE
 NULL, --TBRACCD_LOC_MDT
 NULL, --TBRACCD_LOC_MDT_SEQ
 NULL, --TBRACCD_RATE
 NULL, --TBRACCD_UNITS
 NULL, --TBRACCD_DOCUMENT_NUMBER
 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
 NULL, --TBRACCD_PAYMENT_ID
 NULL, --TBRACCD_INVOICE_NUMBER
 NULL, --TBRACCD_STATEMENT_DATE
 NULL, --TBRACCD_INV_NUMBER_PAID
 vl_moneda, --TBRACCD_CURR_CODE
 NULL, --TBRACCD_EXCHANGE_DIFF
 NULL, --TBRACCD_FOREIGN_AMOUNT
 NULL, --TBRACCD_LATE_DCAT_CODE
 cx.FECHA_INICIO, --TBRACCD_FEED_DATE
 NULL, --TBRACCD_FEED_DOC_CODE
 NULL, --TBRACCD_ATYP_CODE
 NULL, --TBRACCD_ATYP_SEQNO
 NULL, --TBRACCD_CARD_TYPE_VR
 NULL, --TBRACCD_CARD_EXP_DATE_VR
 NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
 NULL, --TBRACCD_CROSSREF_DCAT_CODE
 NULL, --TBRACCD_ORIG_CHG_IND
 NULL, --TBRACCD_CCRD_CODE
 NULL, --TBRACCD_MERCHANT_ID
 NULL, --TBRACCD_TAX_REPT_YEAR
 NULL, --TBRACCD_TAX_REPT_BOX
 NULL, --TBRACCD_TAX_AMOUNT
 NULL, --TBRACCD_TAX_FUTURE_IND
 'UTEL X', --TBRACCD_DATA_ORIGIN
 'UTEL X', --TBRACCD_CREATE_SOURCE
 NULL, --TBRACCD_CPDT_IND
 NULL, --TBRACCD_AIDY_CODE
 cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
 null, --TBRACCD_PERIOD
 NULL, --TBRACCD_SURROGATE_ID
 NULL, --TBRACCD_VERSION
 USER, --TBRACCD_USER_ID
 NULL ); --TBRACCD_VPDI_CODE
 VL_ERROR:='EXITO';
 --DBMS_OUTPUT.PUT_LINE('Termina de Generar cargo ' ||VL_ERROR);
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR := 'Se presento ERROR INSERT TBRACCD Cargo '||SQLERRM;
 --DBMS_OUTPUT.PUT_LINE(VL_ERROR);
 END;

 VL_SECUENCIA:= null;

 ---------------- Se busca tenga el descuentos -------------
  If cx.descuento_venta = 0 then

     Begin

            Select a.tbraccd_amount
                Into vl_desc_venta
             from tbraccd a
            where 1 = 1
            And a.tbraccd_pidm = cx.pidm
            And substr (a.tbraccd_detail_code,3,2) = 'QK'
            And a.TBRACCD_STSP_KEY_SEQUENCE = cx.sp
            And trunc (a.TBRACCD_EFFECTIVE_DATE) = (select max (trunc(a1.TBRACCD_EFFECTIVE_DATE))
                                                     from tbraccd a1
                                                     Where a.tbraccd_pidm = a1.tbraccd_pidm
                                                     And a.tbraccd_detail_code = a1.tbraccd_detail_code);
     Exception
        When Others then
            vl_desc_venta:=0;
     End;

     If vl_desc_venta > 0 then
        Begin
            Update SZTUTLX
                set SZTUTLX_ROW3 = vl_desc_venta
            Where SZTUTLX_PIDM = cx.pidm
            And SZTUTLX_SEQ_NO = cx.seq;
        Exception
            When Others then
                null;
        End;

     End if;

 ElsIf cx.descuento_venta > 0 then
   vl_desc_venta:= cx.descuento_venta;
 --------------------- Se genera el descuento desde la Venta ---------
 --DBMS_OUTPUT.PUT_LINE('Entra a Generar Descuento de la Venta ' ||VL_ERROR);
 VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);

 vl_codigo_cargo:= substr (cx.matricula,1,2) ||'QK';
 --DBMS_OUTPUT.PUT_LINE('Recupera Codigos Clave= '||vl_codigo_cargo);

 vl_codigo_Descrip:= null;
 vl_moneda:= null;
 Begin
 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
 Into vl_codigo_Descrip, vl_moneda
 FROM TBBDETC
 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
 WHERE TBBDETC_DETAIL_CODE = vl_codigo_cargo;
 --DBMS_OUTPUT.PUT_LINE('Recupera Codigos Desc= '||vl_codigo_Descrip ||'*'|| vl_moneda);

 Exception
 When Others then
 vl_codigo_Descrip:= null;
 vl_moneda:= null;
 --DBMS_OUTPUT.PUT_LINE('Error Recupera Codigos desc= '||sqlerrm );
 END;

 BEGIN
 INSERT INTO TBRACCD VALUES (
 cx.PIDM, --TBRACCD_PIDM
 VL_SECUENCIA, --TBRACCD_TRAN_NUMBER
 cx.PERIODO, --TBRACCD_TERM_CODE
 vl_codigo_cargo, --TBRACCD_DETAIL_CODE
 USER, --TBRACCD_USER
 SYSDATE, --TBRACCD_ENTRY_DATE
 vl_desc_venta, --TBRACCD_AMOUNT
 vl_desc_venta*-1, --TBRACCD_BALANCE
 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
 NULL, --TBRACCD_BILL_DATE
 NULL, --TBRACCD_DUE_DATE
 vl_codigo_Descrip, --TBRACCD_DESC
 vl_orden, --TBRACCD_RECEIPT_NUMBER
 VL_SEC_CARGO, --TBRACCD_TRAN_NUMBER_PAID
 NULL, --TBRACCD_CROSSREF_PIDM
 NULL, --TBRACCD_CROSSREF_NUMBER
 NULL, --TBRACCD_CROSSREF_DETAIL_CODE
 'T', --TBRACCD_SRCE_CODE
 'Y', --TBRACCD_ACCT_FEED_IND
 SYSDATE, --TBRACCD_ACTIVITY_DATE
 0, --TBRACCD_SESSION_NUMBER
 NULL, --TBRACCD_CSHR_END_DATE
 NULL, --TBRACCD_CRN
 NULL, --TBRACCD_CROSSREF_SRCE_CODE
 NULL, --TBRACCD_LOC_MDT
 NULL, --TBRACCD_LOC_MDT_SEQ
 NULL, --TBRACCD_RATE
 NULL, --TBRACCD_UNITS
 NULL, --TBRACCD_DOCUMENT_NUMBER
 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
 NULL, --TBRACCD_PAYMENT_ID
 NULL, --TBRACCD_INVOICE_NUMBER
 NULL, --TBRACCD_STATEMENT_DATE
 NULL, --TBRACCD_INV_NUMBER_PAID
 vl_moneda, --TBRACCD_CURR_CODE
 NULL, --TBRACCD_EXCHANGE_DIFF
 NULL, --TBRACCD_FOREIGN_AMOUNT
 NULL, --TBRACCD_LATE_DCAT_CODE
 cx.FECHA_INICIO, --TBRACCD_FEED_DATE
 NULL, --TBRACCD_FEED_DOC_CODE
 NULL, --TBRACCD_ATYP_CODE
 NULL, --TBRACCD_ATYP_SEQNO
 NULL, --TBRACCD_CARD_TYPE_VR
 NULL, --TBRACCD_CARD_EXP_DATE_VR
 NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
 NULL, --TBRACCD_CROSSREF_DCAT_CODE
 NULL, --TBRACCD_ORIG_CHG_IND
 NULL, --TBRACCD_CCRD_CODE
 NULL, --TBRACCD_MERCHANT_ID
 NULL, --TBRACCD_TAX_REPT_YEAR
 NULL, --TBRACCD_TAX_REPT_BOX
 NULL, --TBRACCD_TAX_AMOUNT
 NULL, --TBRACCD_TAX_FUTURE_IND
 'UTEL X', --TBRACCD_DATA_ORIGIN
 'UTEL X', --TBRACCD_CREATE_SOURCE
 NULL, --TBRACCD_CPDT_IND
 NULL, --TBRACCD_AIDY_CODE
 cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
 null, --TBRACCD_PERIOD
 NULL, --TBRACCD_SURROGATE_ID
 NULL, --TBRACCD_VERSION
 USER, --TBRACCD_USER_ID
 NULL ); --TBRACCD_VPDI_CODE
 VL_ERROR:='EXITO';
 --DBMS_OUTPUT.PUT_LINE('GEnera Cargo del Descuento de la Venta ' ||VL_ERROR);
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR := 'Se presento ERROR INSERT TBRACCD Descuento '||SQLERRM;
 --DBMS_OUTPUT.PUT_LINE(VL_ERROR);
 END;

 ElsIf vl_desc_venta = 0 and cx.MES_GRATIS_SSB >= 1 then -----------> Genera el mes gratis por Autoservicio
 VL_SECUENCIA:= null;
 If cx.APLICADOS_SSB < cx.MES_GRATIS_SSB then
 --DBMS_OUTPUT.PUT_LINE('GEnera Cargo del Descuento del SSB ' ||VL_ERROR);

 VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);

 Begin
 Select substr (cx.matricula,1,2) ||trim (ZSTPARA_PARAM_DESC)
 Into vl_codigo_cargo
 from ZSTPARA
 where 1=1
 and ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
 AND ZSTPARA_PARAM_ID = 'UTLX';
 Exception
 When Others then
 vl_codigo_cargo:=null;
 End;
 --DBMS_OUTPUT.PUT_LINE('Recupera Codigos Clave= '||vl_codigo_cargo);

 vl_codigo_Descrip:= null;
 vl_moneda:= null;
 Begin
 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
 Into vl_codigo_Descrip, vl_moneda
 FROM TBBDETC
 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
 WHERE TBBDETC_DETAIL_CODE = vl_codigo_cargo;
 --DBMS_OUTPUT.PUT_LINE('Recupera Codigos Desc= '||vl_codigo_Descrip ||'*'|| vl_moneda);

 Exception
 When Others then
 vl_codigo_Descrip:= null;
 vl_moneda:= null;
 --DBMS_OUTPUT.PUT_LINE('Error Recupera Codigos desc= '||sqlerrm );
 END;


 BEGIN
 INSERT INTO TBRACCD VALUES (
 cx.PIDM, --TBRACCD_PIDM
 VL_SECUENCIA, --TBRACCD_TRAN_NUMBER
 cx.PERIODO, --TBRACCD_TERM_CODE
 vl_codigo_cargo, --TBRACCD_DETAIL_CODE
 USER, --TBRACCD_USER
 SYSDATE, --TBRACCD_ENTRY_DATE
 vl_costo_cargo, --TBRACCD_AMOUNT
 vl_costo_cargo*-1, --TBRACCD_BALANCE
 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
 NULL, --TBRACCD_BILL_DATE
 NULL, --TBRACCD_DUE_DATE
 vl_codigo_Descrip, --TBRACCD_DESC
 vl_orden, --TBRACCD_RECEIPT_NUMBER
 VL_SEC_CARGO, --TBRACCD_TRAN_NUMBER_PAID
 NULL, --TBRACCD_CROSSREF_PIDM
 NULL, --TBRACCD_CROSSREF_NUMBER
 NULL, --TBRACCD_CROSSREF_DETAIL_CODE
 'T', --TBRACCD_SRCE_CODE
 'Y', --TBRACCD_ACCT_FEED_IND
 SYSDATE, --TBRACCD_ACTIVITY_DATE
 0, --TBRACCD_SESSION_NUMBER
 NULL, --TBRACCD_CSHR_END_DATE
 NULL, --TBRACCD_CRN
 NULL, --TBRACCD_CROSSREF_SRCE_CODE
 NULL, --TBRACCD_LOC_MDT
 NULL, --TBRACCD_LOC_MDT_SEQ
 NULL, --TBRACCD_RATE
 NULL, --TBRACCD_UNITS
 NULL, --TBRACCD_DOCUMENT_NUMBER
 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
 NULL, --TBRACCD_PAYMENT_ID
 NULL, --TBRACCD_INVOICE_NUMBER
 NULL, --TBRACCD_STATEMENT_DATE
 NULL, --TBRACCD_INV_NUMBER_PAID
 vl_moneda, --TBRACCD_CURR_CODE
 NULL, --TBRACCD_EXCHANGE_DIFF
 NULL, --TBRACCD_FOREIGN_AMOUNT
 NULL, --TBRACCD_LATE_DCAT_CODE
 cx.FECHA_INICIO, --TBRACCD_FEED_DATE
 NULL, --TBRACCD_FEED_DOC_CODE
 NULL, --TBRACCD_ATYP_CODE
 NULL, --TBRACCD_ATYP_SEQNO
 NULL, --TBRACCD_CARD_TYPE_VR
 NULL, --TBRACCD_CARD_EXP_DATE_VR
 NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
 NULL, --TBRACCD_CROSSREF_DCAT_CODE
 NULL, --TBRACCD_ORIG_CHG_IND
 NULL, --TBRACCD_CCRD_CODE
 NULL, --TBRACCD_MERCHANT_ID
 NULL, --TBRACCD_TAX_REPT_YEAR
 NULL, --TBRACCD_TAX_REPT_BOX
 NULL, --TBRACCD_TAX_AMOUNT
 NULL, --TBRACCD_TAX_FUTURE_IND
 'UTEL X', --TBRACCD_DATA_ORIGIN
 'UTEL X', --TBRACCD_CREATE_SOURCE
 NULL, --TBRACCD_CPDT_IND
 NULL, --TBRACCD_AIDY_CODE
 cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
 null, --TBRACCD_PERIOD
 NULL, --TBRACCD_SURROGATE_ID
 NULL, --TBRACCD_VERSION
 USER, --TBRACCD_USER_ID
 NULL ); --TBRACCD_VPDI_CODE
 VL_ERROR:='EXITO';
 --DBMS_OUTPUT.PUT_LINE('Inserta el Descuento SSB ' ||VL_ERROR);
 EXCEPTION
 WHEN OTHERS THEN
 VL_ERROR := 'Se presento ERROR INSERT TBRACCD Descuento '||SQLERRM;
 --DBMS_OUTPUT.PUT_LINE(VL_ERROR);
 END;

 --DBMS_OUTPUT.PUT_LINE('Entra a Actualizar el UTELX los meses gratis ');
 Begin
 Update SZTUTLX
 set SZTUTLX_GRATIS_APLI = nvl (SZTUTLX_GRATIS_APLI,0) + 1
 Where SZTUTLX_PIDM = cx.pidm
 And SZTUTLX_SEQ_NO = cx.seq
 And SZTUTLX_DISABLE_IND = cx.SZTUTLX_DISABLE_IND;
 VL_ERROR:='EXITO';
 --DBMS_OUTPUT.PUT_LINE('Actualiza mes gratis SSB ' ||VL_ERROR);
 Exception
 When Others then
 VL_ERROR := 'Se presento ERROR al actualizar el mes gratis '||SQLERRM;
 --DBMS_OUTPUT.PUT_LINE(VL_ERROR);
 End;


 End if;

 End if;

 Else

 VL_ERROR := 'No Entra a Generar Cargo';

 End if;
 If VL_ERROR='EXITO' then
 Commit;
 Else
 Rollback;
 End if;

 End loop;

End P_MEMBRESIA_UTELX;


FUNCTION F_UPDATE_CONECTA (p_pidm NUMBER, p_status_Sincro NUMBER,  p_fecha_sincro DATE,p_obervacion VARCHAR2, p_user VARCHAR2)RETURN VARCHAR2 IS
 -- ESTA funcion se hizo para ACTUALIZAR los estatus de CONECTA al momento de ser sincronizado x el aula
 -- esta funcion la consume Python directamente;  proyecto conecta sincriniza AV. glovicx 17.10.00
vsalida varchar2(500):= 'EXITO';

BEGIN
--  DBMS_OUTPUT.PUT_LINE('inicio  PKG_FINANZAS_UTL.F_UPDATE_CONECTA  '||P_PIDM||'-'|| P_ORIGEN||'-'|| vsalida  );

        begin
           update sztcone A
                set
                a.ESTATUS_SINCRO = p_status_Sincro,
                a.FECHA_SINCRO = p_fecha_sincro,
                a.OBSERVACIONES = p_obervacion,
                a.FECHA_ACTU = sysdate,
                a.USUARIO = p_user
                where 1=1
                and a.pidm = p_pidm
                and a.secuencia = (SELECT MAX (a1.secuencia)
                                             FROM sztcone A1
                                             WHERE 1=1
                                             AND A1.PIDM = A.PIDM );

        exception when others then
            vsalida := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR AL ACTUALIZAR PKG_FINANZAS_UTL.F_UPDATE_CONECTA  '||vsalida
             );


        end;

--DBMS_OUTPUT.PUT_LINE('inicio  PKG_FINANZAS_UTL.F_UPDATE_CONECTA  '||P_PIDM||'-'|| P_ORIGEN||'-'|| vsalida  );
commit;

RETURN(vsalida);

exception when others then
vsalida := SQLERRM;
DBMS_OUTPUT.PUT_LINE('ERROR GRAL PKG_FINANZAS_UTL.F_UPDATE_CONECTA  '||vsalida  );

RETURN(vsalida);

END F_UPDATE_CONECTA;

PROCEDURE P_MEMBRESIA_UTELX_v2 (P_pidm number DEFAULT NULL) IS

-------- SSB ------
vl_monto number:=0; 
vl_porcentaje number:=0; 
vl_monto_Descuento number:=0;
vl_Fecha varchar2(12):= null;
-------- PAquete Fijo ------
vl_codigo_Desc varchar2(4):= null; 
vl_porc_desc number := 0;
vl_monto_Desc number:=0; 

vl_codigo_Descrip varchar2(50):= null; 
vl_moneda varchar2(10):= null;
vl_cod_desc_Descrip varchar2(50):= null;
----------- Generacion de cargos ----------
vl_existe_cargo number:=0;
VL_DIA VARCHAR2(2);
VL_MES VARCHAR2(2);
VL_ANO VARCHAR2(4);
vl_orden NUMBER:= null;
vl_codigo_cargo varchar2(4):= null;
VL_VENCIMIENTO VARCHAR2(15);
VL_SECUENCIA number:=0;
VL_SEC_CARGO number:=0;
VL_VENCIMIENTO_ssb VARCHAR2(15);
vl_secuencia_ssb number:=0;
vl_existe_cartera number:=0;
vl_salida varchar2(250):= null;
vl_fecha_ret date;
vl_fecha_fut date;



Begin 


     delete UTELX_CARGO;
     commit;

    ------------------------------- Actualiza el codigo de descuento para paqueteria FIJA 

    Begin

            For cx in (

                        Select distinct *--SWTMDAC_DETAIL_CODE_ACC, SWTMDAC_DETAIL_CODE_DESC
                        from SWTMDAC a
                        where 1=1
                        And substr (a.SWTMDAC_DETAIL_CODE_ACC, 3,2) in ('QI', 'QG')
                        And substr (a.SWTMDAC_DETAIL_CODE_DESC, 3,2) in ('QJ')
                     --   And  SWTMDAC_PIDM = 655581
                
                
              ) loop
              
                    Begin 
                            Update SWTMDAC
                            set SWTMDAC_DETAIL_CODE_DESC = substr (SWTMDAC_DETAIL_CODE_DESC, 1,2)||'QK'
                            Where 1=1
                            And SWTMDAC_PIDM = cx.SWTMDAC_PIDM
                            And SWTMDAC_SEC_PIDM = cx.SWTMDAC_SEC_PIDM
                            And SWTMDAC_DETAIL_CODE_ACC = cx.SWTMDAC_DETAIL_CODE_ACC;
                    Exception
                        When Others then 
                            null;
                    End;      
                  
                    Commit;
              
              End loop;
              
              Commit;
    End;          



    ------------------------------------ Se generan los registros en la tabla de Utelx y se agrega la etiqueta para paquetes Dinamicos 

    Begin

            For cx in (
                                            
                        Select distinct  b.pidm, b.matricula, b.campus, b.nivel, c.GOZTPAC_PIN password, a.TZTPADI_AMOUNT Monto, a.TZTPADI_TERM_CODE Periodo, b.FECHA_MOV Fecha_Registro
                        from tztpadi a
                        join tztprog b on b.pidm = a.TZTPADI_PIDM and b.sp = (select max (b1.sp)
                                                                             from tztprog b1
                                                                             Where b.pidm = b1.pidm
                                                                             )
                        join GOZTPAC c on GOZTPAC_PIDM = a.TZTPADI_PIDM                                                                 
                        where 1= 1
                        and a.TZTPADI_PIDM = nvl (p_pidm, a.TZTPADI_PIDM)  
                        and substr (a.TZTPADI_DETAIL_CODE, 3,2) in ('QI','QG')
                        And a.TZTPADI_FLAG = 0
                        And a.TZTPADI_SEQNO = (select max (a1.TZTPADI_SEQNO)
                                                from TZTPADI a1
                                                Where a.TZTPADI_PIDM = a1.TZTPADI_PIDM
                                                And a.TZTPADI_DETAIL_CODE = a1.TZTPADI_DETAIL_CODE
                                                And a.TZTPADI_FLAG = a1.TZTPADI_FLAG
                                                )
                       And a.TZTPADI_PIDM not in (select b.SZTUTLX_PIDM
                                                    from SZTUTLX  b
                                                  )                                                                      
                                        

                ) loop     
                
                        Begin 

                                           
                            INSERT INTO SZTUTLX VALUES(cx.pidm,--SZTUTLX_PIDM
                                                       cx.matricula, --SZTUTLX_ID
                                                       cx.periodo,--SZTUTLX_TERM_CODE
                                                       cx.campus,--SZTUTLX_CAMP_CODE
                                                       cx.nivel,--SZTUTLX_LEVL_CODE
                                                       1,--SZTUTLX_SEQ_NO
                                                       0,--SZTUTLX_STAT_IND
                                                       Null,--SZTUTLX_OBS
                                                       'A',--SZTUTLX_DISABLE_IND
                                                       cx.password,--SZTUTLX_PWD
                                                       Null,--SZTUTLX_MDL_ID
                                                       USER,--SZTUTLX_USER_INSERT
                                                       cx.fecha_registro,--SZTUTLX_ACTIVITY_DATE
                                                       Null,--SZTUTLX_DATE_UPDATE
                                                       Null,--SZTUTLX_USER_UPDATE
                                                       cx.fecha_registro,--SZTUTLX_ROW1
                                                       null,--SZTUTLX_ROW2
                                                       cx.monto,--SZTUTLX_ROW3
                                                       Null,--SZTUTLX_ROW4
                                                       Null,--SZTUTLX_ROW5
                                                       null,
                                                       null,
                                                       null,
                                                       null,
                                                       null,--- colm nuevas glovicx proy, retencion utls 27.07.2023
                                                       null,
                                                       null,
                                                       null
                                                       );  
                            Commit;  
                        Exception
                            When Others then 
                                null;
                        End;            
                
                
                        Begin
                                vl_salida:=pkg_utilerias.F_Genera_Etiqueta(cx.pidm, 'UTLX', 'UTEL-X', 'MASIVO');
                                Commit;
                        Exception
                            When Others then 
                                null;    
                        End;
                
                        Commit;
                
                End loop;
                
                
                
    End;              







    Begin 


        ------------------ Este bloque actualiza el mes gratis paara la venta de Autoservcio --------------------------

        For cx in (


                    Select SVRSVPR_PROTOCOL_SEQ_NO, SVRSVAD_ADDL_DATA_CDE, SVRSVPR_PIDM, SVRSVPR_ACCD_TRAN_NUMBER, tbraccd_detail_code , 
                            trunc (TBRACCD_EFFECTIVE_DATE), SZTUTLX_SEQ_NO, SZTUTLX_GRATIS_APLI, SZTUTLX_GRATIS      
                    from SVRSVPR
                    join SVRSVAD on SVRSVAD_PROTOCOL_SEQ_NO = SVRSVPR_PROTOCOL_SEQ_NO
                    join SZTUTLX b ON     b.SZTUTLX_PIDM = SVRSVPR_PIDM
                       AND b.SZTUTLX_STAT_IND IN ('1', '2')
                       AND b.SZTUTLX_SEQ_NO = (SELECT MAX (b1.SZTUTLX_SEQ_NO)
                                                FROM SZTUTLX b1
                                                WHERE     1 = 1
                                                AND b.SZTUTLX_PIDM = b1.SZTUTLX_PIDM
                                                AND b1.SZTUTLX_STAT_IND = b.SZTUTLX_STAT_IND)
                   left join tbraccd on tbraccd_pidm = SVRSVPR_PIDM  And substr (tbraccd_detail_code, 3,2) = '17' 
                    --     And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                    where 1=1
                     And SVRSVPR_PIDM = nvl (P_pidm, SVRSVPR_PIDM)
                    and SVRSVPR_SRVC_CODE = 'UTLX'
                    and SVRSVPR_SRVS_CODE= 'CL'
                    and SVRSVAD_ADDL_DATA_SEQ in (9)
                        
               
        ) loop
          
           if cx.SVRSVAD_ADDL_DATA_CDE = '1' and cx.TBRACCD_DETAIL_CODE is null then 
           
                Begin 
                    Update SZTUTLX
                    set SZTUTLX_GRATIS_APLI = 0,
                        SZTUTLX_GRATIS = 1
                    Where SZTUTLX_PIDM = cx.SVRSVPR_PIDM
                    and SZTUTLX_SEQ_NO = cx.SZTUTLX_SEQ_NO;
                Exception
                    When Others then 
                        null;
                End;

           Elsif cx.SVRSVAD_ADDL_DATA_CDE = '0' then 
                Begin 
                    Update SZTUTLX
                    set SZTUTLX_GRATIS_APLI = null,
                        SZTUTLX_GRATIS = null
                    Where SZTUTLX_PIDM = cx.SVRSVPR_PIDM
                    and SZTUTLX_SEQ_NO = cx.SZTUTLX_SEQ_NO;
                Exception
                    When Others then 
                        null;
                End;       
           Elsif cx.SVRSVAD_ADDL_DATA_CDE = '1' and cx.TBRACCD_DETAIL_CODE is not null then 
               
                Begin 
                    Update SZTUTLX
                    set SZTUTLX_GRATIS_APLI = 1,
                        SZTUTLX_GRATIS = 1
                    Where SZTUTLX_PIDM = cx.SVRSVPR_PIDM
                    and SZTUTLX_SEQ_NO = cx.SZTUTLX_SEQ_NO;
                Exception
                    When Others then 
                        null;
                End;       
           End if;



        End loop;
        Commit;


    End;


----------------------- Proceso masivo para la creacion de los cargos de UTelx para Paquete Fijo y SSB ------------------------

    For cx in ( 


                  SELECT DISTINCT
                                 A.pidm,
                                 a.matricula,
                                 a.campus,
                                 a.nivel,
                                 fget_periodo_general (SUBSTR (a.matricula, 1, 2),TRUNC (SYSDATE))Periodo,
                                 a.programa,
                                 a.sp,
                                 a.estatus,
                                 a.fecha_inicio,
                                 a.FECHA_PRIMERA,
                                 b.SZTUTLX_SEQ_NO Seq,
                                 b.SZTUTLX_DISABLE_IND,
                                 b.SZTUTLX_OBS,
                                 NVL (b.SZTUTLX_GRATIS, 0) Mes_Gratis_SSB,
                                 NVL (b.SZTUTLX_GRATIS_APLI, 0) Aplicados_SSB,
                                 NVL (b.SZTUTLX_ROW2, 0) MES_GRATIS_Ret,
                                 NVL (b.SZTUTLX_ROW3, 0) Descuento_Venta,
                                 pkg_utilerias.f_etiqueta (a.pidm, 'UTLX') etiqueta,
                                 pkg_utilerias.f_calcula_rate(a.pidm,a.programa)Rate,
                                 (decode (substr (pkg_utilerias.f_calcula_rate(a.pidm,a.programa), 4, 1),'A', 15,'B','30','C','10'))VENCIMIENTO,
                                 case 
                                 when trim (b.SZTUTLX_FREC_PAGO) = 'SEMESTRAL RECURRENTE' then 
                                      '6'
                                 when trim (b.SZTUTLX_FREC_PAGO) = 'MES RECURRENTE' then   
                                       '1'
                                 when trim (b.SZTUTLX_FREC_PAGO) = 'ANUAL RECURRENTE' then   
                                       '12'
                                 when trim (b.SZTUTLX_FREC_PAGO) is null  then   
                                       '1'
                                End periodicidad
                            FROM tztprog a
                                 JOIN SZTUTLX b ON     b.SZTUTLX_PIDM = a.pidm
                                       AND b.SZTUTLX_STAT_IND IN ('1', '2') --> Quitar el valor de 0 solo para el desarrollo
                                       AND b.SZTUTLX_SEQ_NO = (SELECT MAX (b1.SZTUTLX_SEQ_NO)
                                                                FROM SZTUTLX b1
                                                                WHERE     1 = 1
                                                                AND b.SZTUTLX_PIDM = b1.SZTUTLX_PIDM
                                                                AND b1.SZTUTLX_STAT_IND = b.SZTUTLX_STAT_IND)
                           WHERE     1 = 1
                           AND a.sp = (SELECT MAX (a1.sp)
                                        FROM tztprog a1
                                        WHERE a.pidm = a1.pidm)
                           AND a.estatus IN ('MA', 'EG')
                           AND b.SZTUTLX_DISABLE_IND = 'A'
                           AND SZTUTLX_USER_BLOQUEO IS NULL
                           AND TRUNC (a.fecha_inicio+12) <= TRUNC (SYSDATE)
                           And a.pidm not in (select goradid_pidm
                                                                                from GORADID
                                                                                Where 1=1
                                                                                And GORADID_ADID_CODE ='SBTI' ----> Se excluyen a los alumnos que cuenten con la etiqueta de Retencion 
                                                                                )                                     
                            --And b.SZTUTLX_FREC_PAGO is not null  --> Quitar esta linea solo es para el desarrollo
                            
                         And a.pidm = nvl (P_pidm, a.pidm)
           
      ) loop

            --------------- Busco los valores para el AutoServicio ----------------
        Begin 
            select a.monto, a.PORCENTAJE, a.MONTODESCUENTO, a.FECHA_STATUS
                Into vl_monto, vl_porcentaje, vl_monto_Descuento, vl_Fecha
            from SZRVSSB a
            where 1= 1
            And a.ESTATUS_SOLC = 'CONCLUIDO' 
            And a.COD_SERVICIO = 'UTLX'
            And a.Matricula = cx.matricula 
            And a.Campus = cx.campus
            And a.nivel  = cx.nivel
            And to_number(a.SEQ_NO) = (select maX(to_number(a1.SEQ_NO))
                               from SZRVSSB a1
                               Where a.Matricula = a1.Matricula
                               And a.COD_SERVICIO = a1.COD_SERVICIO
                               );
        Exception
            When Others then 
                vl_monto:=null; 
                vl_porcentaje:=null; 
                vl_monto_Descuento:=null;
        End;
               
        If vl_monto >=0 then --------- Registro por SSB
           vl_codigo_Descrip:= null;
           vl_moneda := null;  
        
           Begin 
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'NA';
           Exception
            When Others then 
              vl_codigo_Descrip:= null;  
              vl_moneda:= null;
           End;        
        
           If cx.MES_GRATIS_SSB = 1  then 
            
             vl_codigo_cargo:= null;
            
             Begin 
                 Select substr (cx.matricula,1,2) ||trim (ZSTPARA_PARAM_DESC)
                     Into vl_codigo_cargo
                 from ZSTPARA
                 where 1=1
                 and ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
                 AND ZSTPARA_PARAM_ID = 'UTLX';
             Exception
             When Others then 
              vl_codigo_cargo:=null;
             End;        
           
           End if;
        
           Begin 
                Insert into UTELX_CARGO values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.sp,
                                                cx.rate,
                                                cx.vencimiento,
                                                substr (cx.matricula,1,2) ||'NA', ---> SSB
                                                vl_monto,
                                                vl_codigo_cargo,
                                                0,
                                                null,
                                                'SSB', 
                                                NULL,
                                                cx.MES_GRATIS_SSB,
                                                cx.APLICADOS_SSB,
                                                1,
                                                vl_codigo_Descrip, 
                                                vl_moneda,
                                                NULL,
                                                cx.fecha_inicio,
                                                cx.periodo,
                                                CX.SEQ,
                                                CX.ESTATUS,
                                                CX.periodicidad,
                                                null,
                                                null
                                              
                                                );
           Exception
            When Others then 
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );                                                
           End;
        
        
        End if;
         
        ---------------------------- Se buscan los registros de paquete fijo ------------------
        
        vl_monto:=0; 
        vl_porcentaje:=0; 
        vl_monto_Descuento:=0;  
        vl_codigo_Desc:= null; 
        vl_porc_desc:=0; 
        vl_monto_Desc:=0;       
        
        Begin 
        
            Select TZFACCE_AMOUNT 
                Into vl_monto
            from TZFACCE a 
            Where 1=1
            and a.TZFACCE_PIDM = cx.pidm
             and substr (a.TZFACCE_DETAIL_CODE, 3,2) in ('QI', 'QG')
--             And a.TZFACCE_DESC = 'MEMBRESIA UTEL X'
             And a.TZFACCE_SEC_PIDM = (select max (a1.TZFACCE_SEC_PIDM)
                                        from TZFACCE a1
                                        Where a.TZFACCE_pidm  = a1.TZFACCE_pidm
                                        And a.TZFACCE_DETAIL_CODE = a1.TZFACCE_DETAIL_CODE
                                        --And a.TZFACCE_DESC = a1.TZFACCE_DESC
                                        );
        Exception
            When Others then 
               vl_monto:=null;      
        
        End; 
        
        Begin 
        
        select SWTMDAC_DETAIL_CODE_DESC , SWTMDAC_PERCENT_DESC, (nvl (vl_monto,0)*SWTMDAC_PERCENT_DESC/100) monto_desc
            into vl_codigo_Desc, vl_porc_desc, vl_monto_Desc 
        from SWTMDAC a
        where 1= 1
        And a.SWTMDAC_PIDM = cx.pidm
        and substr (a.SWTMDAC_DETAIL_CODE_ACC, 3,2) in ('QI', 'QG')
        And a.SWTMDAC_SEC_PIDM = (select max (a1.SWTMDAC_SEC_PIDM)
                                  from SWTMDAC a1
                                  Where 1 = 1
                                  And a.SWTMDAC_PIDM = a1.SWTMDAC_PIDM
                                  And a.SWTMDAC_DETAIL_CODE_ACC = a1.SWTMDAC_DETAIL_CODE_ACC);
        Exception
            When Others then 
              vl_codigo_Desc := null; 
              vl_porc_desc := 0;
              vl_monto_Desc :=0;   
        End; 
        
        If vl_monto_Desc = 0 then 
        
            Begin 
                select SWTMDAC_AMOUNT_DESC
                    into vl_monto_Desc 
                from SWTMDAC a
                where 1= 1
                And a.SWTMDAC_PIDM = cx.pidm
                and substr (a.SWTMDAC_DETAIL_CODE_ACC, 3,2) in ('QI', 'QG')
                And a.SWTMDAC_SEC_PIDM = (select max (a1.SWTMDAC_SEC_PIDM)
                                          from SWTMDAC a1
                                          Where 1 = 1
                                          And a.SWTMDAC_PIDM = a1.SWTMDAC_PIDM
                                          And a.SWTMDAC_DETAIL_CODE_ACC = a1.SWTMDAC_DETAIL_CODE_ACC);
            Exception
                When Others then 
                  vl_codigo_Desc := null; 
                  vl_porc_desc := 0;
                  vl_monto_Desc :=0;   
            End;           
        End if;
        
        
        If vl_monto >=0 then --------- Registro por Fijo
           vl_codigo_Descrip:= null; 
           vl_moneda:= null;
           vl_cod_desc_Descrip:= null;

           Begin 
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'QI';
           Exception
            When Others then 
              vl_codigo_Descrip:= null;  
              vl_moneda:= null;
           End;       
           
           Begin 
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_cod_desc_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = vl_codigo_Desc;
           Exception
            When Others then 
              vl_cod_desc_Descrip:= null;  
              vl_moneda:= null;
           End;                  
        
           Begin 
                Insert into UTELX_CARGO values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.sp,
                                                cx.rate,
                                                cx.vencimiento,
                                                substr (cx.matricula,1,2) ||'QI', ----Paquete Fijo
                                                vl_monto,
                                                vl_codigo_Desc,
                                                vl_monto_Desc,
                                                null,
                                                'FIJO', 
                                                NULL,
                                                cx.MES_GRATIS_SSB,
                                                cx.APLICADOS_SSB,
                                                2,
                                                vl_codigo_Descrip, 
                                                vl_moneda,
                                                vl_cod_desc_Descrip,
                                                cx.fecha_inicio,
                                                cx.periodo,
                                                CX.SEQ,
                                                CX.ESTATUS,
                                                CX.periodicidad,
                                                null,
                                                null                                            
                                                );
           Exception
            When Others then 
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );                                                
           End;
        
        
        End if;        
        
        
        ---------------------------- Se buscan los registros de paquete Dinamico ------------------
        vl_monto:=0;
        vl_codigo_Desc:= null;
        vl_monto_Desc:=null;
            
        
        Begin         
            Select distinct  TZTPADI_AMOUNT
                Into vl_monto
            from tztpadi a
            where 1= 1
            and a.TZTPADI_PIDM = cx.pidm
            and substr (a.TZTPADI_DETAIL_CODE, 3,2) in ('QI','QG')
            And a.TZTPADI_FLAG = 0
            And a.TZTPADI_SEQNO = (select max (a1.TZTPADI_SEQNO)
                                    from TZTPADI a1
                                    Where a.TZTPADI_PIDM = a1.TZTPADI_PIDM
                                    And a.TZTPADI_DETAIL_CODE = a1.TZTPADI_DETAIL_CODE
                                    And a.TZTPADI_FLAG = a1.TZTPADI_FLAG
                                    ) ;       
        Exception
            When Others then 
             vl_monto:=null;
        End;
            
        If vl_monto >=0 then --------- Registro por Dinamico
           vl_codigo_Descrip:= null; 
           vl_moneda:= null;
           vl_cod_desc_Descrip:= null;

           Begin 
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'QI';
           Exception
            When Others then 
              vl_codigo_Descrip:= null;  
              vl_moneda:= null;
           End;       
         
        
           Begin 
                Insert into UTELX_CARGO values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.sp,
                                                cx.rate,
                                                cx.vencimiento,
                                                substr (cx.matricula,1,2) ||'QI', ----Paquete Fijo
                                                vl_monto,
                                                vl_codigo_Desc,
                                                vl_monto_Desc,
                                                null,
                                                'Dinamico', 
                                                NULL,
                                                cx.MES_GRATIS_SSB,
                                                cx.APLICADOS_SSB,
                                                3,
                                                vl_codigo_Descrip, 
                                                vl_moneda,
                                                null,
                                                cx.fecha_inicio,
                                                cx.periodo,   
                                                CX.SEQ,
                                                CX.ESTATUS,
                                                CX.periodicidad,
                                                null,
                                                null                                          
                                                );
           Exception
            When Others then 
                    null;
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );                                                
           End;
        
        
        End if;            
        
        Commit;
        
                
      End loop;
      Commit;
        
      ----------------- Se eliminan los registros duplicados para registros mayores -------------------
      Begin 
                                    
              For cx in (
              
                            select count(*), matricula
                            from UTELX_CARGO
                            group by matricula
                            having count(*) > 1
              
              ) loop


                    For cx2 in (
                               
                            select *
                            from UTELX_CARGO a
                            Where 1=1
                            And a.matricula = cx.matricula
                            And a.ORDEN_APLICACION = (select min (a1.ORDEN_APLICACION)
                                                       from UTELX_CARGO a1
                                                       Where a.matricula = a1.matricula
                                                     )    
                    
                    ) loop        
                    

                            Begin 
                                delete UTELX_CARGO
                                Where 1= 1
                                And matricula = cx2.matricula
                                And ORDEN_APLICACION = cx2.ORDEN_APLICACION
                                And origen not in ('SSB');
                            Exception
                                When Others then 
                                 null; 
                            End;
                            Commit;
                            
                  End loop;          

              End loop;     
                
      End;  
      
      Begin 
        For cx in (

                    select count(*), matricula 
                    from UTELX_CARGO
                    --where matricula ='010024052'
                    group by matricula
                    having count(*) > 1

        ) loop


                Begin 
                        Delete UTELX_CARGO
                        where matricula = cx.matricula 
                        and origen not in ('SSB');
                Exception
                    When Others then 
                        null;
                End;


        End Loop;
        Commit;
    
      End;  
      
      
      -------------------------- Se actualiza el monto de la tabla Eje con base a los cargos generados para la tabla de TZFACCE  -------------------
      
      
      Begin 
      
            For cx in (

                        Select distinct a.pidm, a.matricula, b.TZFACCE_AMOUNT Monto_nuevo, a.MONTO_CARGO Monto_Anterior, a.sp, a.programa, a.origen, a.campus, a.nivel, b.TZFACCE_FLAG Bandera
                        from UTELX_CARGO a
                        join TZFACCE b on b.TZFACCE_PIDM = a.pidm and b.TZFACCE_DETAIL_CODE = a.CODIGO_CARGO And b.TZFACCE_FLAG = 0
                        where a.origen = 'SSB'
                        And b.TZFACCE_SEC_PIDM = (select max (b1.TZFACCE_SEC_PIDM)
                                                    from TZFACCE b1
                                                  Where b.TZFACCE_PIDM = b1.TZFACCE_PIDM
                                                  And b.TZFACCE_DETAIL_CODE = b1.TZFACCE_DETAIL_CODE
                                                  And b.TZFACCE_FLAG = b1.TZFACCE_FLAG
                                                  )
                        and a.MES_GRATIS_SSB = a.MES_GRATIS_SSB_APLICADO
                        And b.TZFACCE_AMOUNT != a.MONTO_CARGO
                        --and matricula ='010369652'
            
            ) loop
      
                        Begin 
                            Update UTELX_CARGO
                            set MONTO_CARGO = cx.monto_nuevo
                            Where 1=1
                            And campus = cx.campus
                            And nivel = cx.nivel
                            And programa = cx.programa
                            And pidm = cx.pidm
                            And origen = cx.origen;
                        Exception
                            When others then 
                                null;
                        End;
                        Commit;
      
      
            End loop; 
      Exception
        When Others then 
            null;
      End;
      
      
      
      -------- Se ponen las descripciones de las descuentos que no estan registradas 
      Begin 
            Update UTELX_CARGO a
            set a.DESC_DESCR = (select TBBDETC_DESC 
                                from TBBDETC
                                Where TBBDETC_DETAIL_CODE = a.CODIGO_DESC)
            Where CODIGO_DESC is not null;                                        
      Exception
        When Others then 
            null;
      End;                        
                      

    ----------- Se eliminan las membresias con estatus de Egresados para todo lo que no sea SSB 
    
      Begin
            delete  UTELX_CARGO
            where origen not in ('SSB')
            And estatus ='EG';    
      Exception
            When Others then 
             null;
      End;


      ----------------------------- Se inicia el proceso de registro en la cartera ------------------------
      
      For cx in (
      
                    select *
                    from UTELX_CARGO
                    where 1 = 1
                    -- And ORIGEN in ('SSB')
                    And ORIGEN in ('FIJO', 'SSB')
                   --  AND matricula IN ('010230513') ------ Aqui pones las matriculas AGEDA
                    order by ORDEN_APLICACION                     
      
      ) loop
      
        If cx.periodicidad = 1 then 
         DBMS_OUTPUT.PUT_LINE('Periodicidad '||cx.periodicidad );
      
             Begin
                 Select count(*)
                 Into vl_existe_cargo
                 from tbraccd
                 where 1= 1
                 and tbraccd_pidm = cx.pidm 
                 And tbraccd_detail_code = cx.codigo_cargo 
                 And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE));
             Exception
             When Others then 
             vl_existe_cargo:=0; 
             End;     
       
            DBMS_OUTPUT.PUT_LINE('Periodicidad '||cx.periodicidad ||'*'||vl_existe_cargo);
      
        ElsIf cx.periodicidad != 1 then --> Macana
          DBMS_OUTPUT.PUT_LINE('Periodicidad '||cx.periodicidad );
            Begin     
            
                Select ADD_MONTHS (trunc (TBRACCD_EFFECTIVE_DATE,'MM'), cx.periodicidad) fecha
                 Into vl_fecha_fut
                from tbraccd a
                where a.tbraccd_pidm = cx.pidm 
                And a.tbraccd_detail_code = cx.codigo_cargo
                And a.TBRACCD_TRAN_NUMBER = (select max (a1.TBRACCD_TRAN_NUMBER)
                                             from tbraccd a1
                                             Where a.tbraccd_pidm = a1.tbraccd_pidm
                                             And a.tbraccd_detail_code = a1.tbraccd_detail_code);        

            Exception 
                When Others then 
                    vl_fecha_fut:= null;
            End;
            
            DBMS_OUTPUT.PUT_LINE('Periodicidad '||cx.periodicidad ||'*'||vl_fecha_fut);

            If vl_fecha_fut is not null and vl_fecha_fut = TRUNC(SYSDATE, 'MM') then
               vl_existe_cargo:=0;
               DBMS_OUTPUT.PUT_LINE('Primer IF '||vl_fecha_fut ||'*'||TRUNC(SYSDATE, 'MM'));
                 
                 Begin
                     Select count(*)
                     Into vl_existe_cargo
                     from tbraccd
                     where 1= 1
                     and tbraccd_pidm = cx.pidm 
                     And tbraccd_detail_code = cx.codigo_cargo 
                     And trunc (TBRACCD_EFFECTIVE_DATE) between vl_fecha_fut and TRUNC(LAST_DAY(vl_fecha_fut));
                 Exception
                 When Others then 
                 vl_existe_cargo:=0; 
                 End;                 
               
                DBMS_OUTPUT.PUT_LINE('Valida IF '||vl_existe_cargo );
               
            Else
              vl_existe_cargo := 1;
              DBMS_OUTPUT.PUT_LINE('ELSE IF '||vl_existe_cargo );
                
            End if; 

       
        End if;
       
       --   DBMS_OUTPUT.PUT_LINE('Sin SSB= '||cx.pidm ||'*'||cx.codigo_cargo||'*'||vl_existe_cargo );
         
         
         If vl_existe_cargo = 0 and trim (cx.origen) = 'SSB' then
         
             Begin
                 Select count(*)
                 Into vl_existe_cargo
                 from tbraccd
                 where 1= 1
                 and tbraccd_pidm = cx.pidm 
                 And tbraccd_detail_code = cx.codigo_desc
                 And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE));
             Exception
             When Others then 
             vl_existe_cargo:=0; 
             End;          
         End if;
        -- DBMS_OUTPUT.PUT_LINE('Sin CON= '||cx.pidm ||'*'||cx.codigo_desc||'*'||vl_existe_cargo );
      
         If vl_existe_cargo = 0  then
             VL_DIA := NULL;
             VL_MES := NULL;
             VL_ANO := NULL;   
             VL_VENCIMIENTO := null;      
             BEGIN
                 VL_DIA := cx.VENCIMIENTO;
                 VL_MES := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 4, 2);
                 VL_ANO := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 7, 4);

                 IF VL_DIA = '30' THEN
                     VL_VENCIMIENTO := CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
                 ELSE
                     VL_VENCIMIENTO := VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
                 END IF;
             Exception
                When Others then 
                    null;
             END;          
         
             VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);
             VL_SEC_CARGO:= VL_SECUENCIA; 
             vl_orden:= null;
         
             Begin
                 Select TZTORDR_CONTADOR
                     Into vl_orden 
                 from TZTORDR
                 where TZTORDR_PIDM = cx.pidm
                 And TZTORDR_CAMPUS = cx.campus
                 And TZTORDR_NIVEL = cx.nivel
                 And TZTORDR_ESTATUS = 'S'
                 And trunc (TZTORDR_FECHA_INICIO) = cx.fecha_inicio;
             Exception
             When Others then 
                 vl_orden:= null;
             End;         
         
             If vl_orden is null then             
                 BEGIN
                     SELECT MAX(TZTORDR_CONTADOR)+1
                         INTO vl_orden
                     FROM TZTORDR;
                 EXCEPTION
                 WHEN OTHERS THEN
                  vl_orden:= NULL;
                 END;         
             End if; 
             
             If vl_orden is not null then 
                 BEGIN
                     INSERT INTO TZTORDR (
                                         TZTORDR_CAMPUS,
                                         TZTORDR_NIVEL,
                                         TZTORDR_CONTADOR,
                                         TZTORDR_PROGRAMA,
                                         TZTORDR_PIDM,
                                         TZTORDR_ID,
                                         TZTORDR_ESTATUS,
                                         TZTORDR_ACTIVITY_DATE,
                                         TZTORDR_USER,
                                         TZTORDR_DATA_ORIGIN,
                                         TZTORDR_NO_REGLA,
                                         TZTORDR_FECHA_INICIO,
                                         TZTORDR_RATE,
                                         TZTORDR_JORNADA,
                                         TZTORDR_DSI,
                                         TZTORDR_TERM_CODE
                                         )
                                     VALUES( cx.CAMPUS,
                                             cx.NIVEL,
                                             vl_orden,
                                             cx.PROGRAMA,
                                             cx.PIDM,
                                             cx.MATRICULA,
                                             'S',
                                             SYSDATE,
                                             USER,
                                             'AUTO_UTELX',
                                             NULL,
                                             TRUNC(SYSDATE),
                                             NULL,
                                             NULL,
                                             NULL,
                                             cx.PERIODO
                                     );
                 EXCEPTION
                 WHEN OTHERS THEN
                    null;
                 END;             
             End if;
             

                 ------------------ valida que para el servicio de SSB sea el primer pago y si es el primer pago pones la fecha de vencimiento
                 ------------------ como la fecha de compra del serviio 
                 -------- Busca que no existan cargos con el codigo de detalle -----------
                                    
                If cx.ORIGEN in ('SSB') then 
                     vl_existe_cargo:=0;
                     VL_VENCIMIENTO_SSB:= null;
                     Begin
                         Select count(*)
                            Into vl_existe_cargo
                         from tbraccd
                         where 1= 1
                         and tbraccd_pidm = cx.pidm 
                         And tbraccd_detail_code = cx.codigo_cargo; 
                     Exception
                     When Others then 
                     vl_existe_cargo:=0; 
                     End;                      
                    
                     If vl_existe_cargo = 0 then 
                
                         Begin 

                            Select trunc(SVRSVPR_STATUS_DATE) Fecha_Servicio, SVRSVPR_PROTOCOL_SEQ_NO
                                Into VL_VENCIMIENTO_SSB, vl_secuencia_ssb
                            from SVRSVPR
                            join SZTUTLX b ON     b.SZTUTLX_PIDM = SVRSVPR_PIDM
                               AND b.SZTUTLX_STAT_IND IN ('1', '2')
                               AND b.SZTUTLX_SEQ_NO = (SELECT MAX (b1.SZTUTLX_SEQ_NO)
                                                        FROM SZTUTLX b1
                                                        WHERE     1 = 1
                                                        AND b.SZTUTLX_PIDM = b1.SZTUTLX_PIDM
                                                        AND b1.SZTUTLX_STAT_IND = b.SZTUTLX_STAT_IND)
                            where 1=1
                            And SVRSVPR_PIDM = cx.pidm 
                            and SVRSVPR_SRVC_CODE = 'UTLX'
                            and SVRSVPR_SRVS_CODE= 'CL';
                         Exception
                            When Others then 
                             VL_VENCIMIENTO_SSB := null;
                         End;
                
                     End if;
                
                
                End if;             
                              
               
                If VL_VENCIMIENTO_SSB is not null then 
                    VL_VENCIMIENTO:= VL_VENCIMIENTO_SSB;
                End if;
             

                ------------------------ Realiza el registro del cargo ------------------------
                 BEGIN
                     INSERT INTO TBRACCD VALUES (cx.PIDM, --TBRACCD_PIDM
                                                 VL_SEC_CARGO, --TBRACCD_TRAN_NUMBER
                                                 cx.PERIODO, --TBRACCD_TERM_CODE
                                                 cx.codigo_cargo, --TBRACCD_DETAIL_CODE
                                                 USER, --TBRACCD_USER
                                                 VL_VENCIMIENTO, --TBRACCD_ENTRY_DATE
                                                 cx.monto_cargo, --TBRACCD_AMOUNT
                                                 cx.monto_cargo, --TBRACCD_BALANCE
                                                 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
                                                 NULL, --TBRACCD_BILL_DATE
                                                 NULL, --TBRACCD_DUE_DATE
                                                 cx.cargo_Descr, --TBRACCD_DESC
                                                 vl_orden, --TBRACCD_RECEIPT_NUMBER
                                                 null, --TBRACCD_TRAN_NUMBER_PAID
                                                 NULL, --TBRACCD_CROSSREF_PIDM
                                                 NULL, --TBRACCD_CROSSREF_NUMBER
                                                 NULL, --TBRACCD_CROSSREF_DETAIL_CODE
                                                 'T', --TBRACCD_SRCE_CODE
                                                 'Y', --TBRACCD_ACCT_FEED_IND
                                                 VL_VENCIMIENTO, --TBRACCD_ACTIVITY_DATE
                                                 0, --TBRACCD_SESSION_NUMBER
                                                 NULL, --TBRACCD_CSHR_END_DATE
                                                 NULL, --TBRACCD_CRN
                                                 NULL, --TBRACCD_CROSSREF_SRCE_CODE
                                                 NULL, --TBRACCD_LOC_MDT
                                                 NULL, --TBRACCD_LOC_MDT_SEQ
                                                 NULL, --TBRACCD_RATE
                                                 NULL, --TBRACCD_UNITS
                                                 NULL, --TBRACCD_DOCUMENT_NUMBER
                                                 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
                                                 NULL, --TBRACCD_PAYMENT_ID
                                                 NULL, --TBRACCD_INVOICE_NUMBER
                                                 NULL, --TBRACCD_STATEMENT_DATE
                                                 NULL, --TBRACCD_INV_NUMBER_PAID
                                                 cx.cargo_moneda, --TBRACCD_CURR_CODE
                                                 NULL, --TBRACCD_EXCHANGE_DIFF
                                                 NULL, --TBRACCD_FOREIGN_AMOUNT
                                                 NULL, --TBRACCD_LATE_DCAT_CODE
                                                 cx.FECHA_INICIO, --TBRACCD_FEED_DATE
                                                 NULL, --TBRACCD_FEED_DOC_CODE
                                                 NULL, --TBRACCD_ATYP_CODE
                                                 NULL, --TBRACCD_ATYP_SEQNO
                                                 NULL, --TBRACCD_CARD_TYPE_VR
                                                 NULL, --TBRACCD_CARD_EXP_DATE_VR
                                                 NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
                                                 NULL, --TBRACCD_CROSSREF_DCAT_CODE
                                                 NULL, --TBRACCD_ORIG_CHG_IND
                                                 NULL, --TBRACCD_CCRD_CODE
                                                 NULL, --TBRACCD_MERCHANT_ID
                                                 NULL, --TBRACCD_TAX_REPT_YEAR
                                                 NULL, --TBRACCD_TAX_REPT_BOX
                                                 NULL, --TBRACCD_TAX_AMOUNT
                                                 NULL, --TBRACCD_TAX_FUTURE_IND
                                                 'UTEL X', --TBRACCD_DATA_ORIGIN
                                                 'UTEL X', --TBRACCD_CREATE_SOURCE
                                                 NULL, --TBRACCD_CPDT_IND
                                                 NULL, --TBRACCD_AIDY_CODE
                                                 cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
                                                 null, --TBRACCD_PERIOD
                                                 NULL, --TBRACCD_SURROGATE_ID
                                                 NULL, --TBRACCD_VERSION
                                                 USER, --TBRACCD_USER_ID
                                                 NULL ); --TBRACCD_VPDI_CODE

                 EXCEPTION
                 WHEN OTHERS THEN
                  null;
                 --DBMS_OUTPUT.PUT_LINE(VL_ERROR); 
                 END;             
 
                 If cx.ORIGEN in ('SSB') and vl_existe_cargo =0  then   
                 
                 
                    Begin
                        Update SVRSVPR
                        Set SVRSVPR_ACCD_TRAN_NUMBER = VL_SEC_CARGO
                        where SVRSVPR_PIDM = cx.pidm
                        And SVRSVPR_PROTOCOL_SEQ_NO = vl_secuencia_ssb;
                    Exception
                        When Others then 
                            null;
                    End;

                 End if;
             
              VL_SECUENCIA:= null;

 ---------------- Se busca tenga el descuentos -------------
              If cx.codigo_desc is not null    then
                VL_SECUENCIA:= null;
              
                    Begin 
                        Update SZTUTLX
                            set SZTUTLX_ROW3 = cx.monto_Desc
                        Where SZTUTLX_PIDM = cx.pidm 
                        And SZTUTLX_SEQ_NO = cx.seq_utelx;
                    Exception
                        When Others then 
                            null;
                    End;              

                    If (cx.mes_gratis_ssb = cx.mes_gratis_ssb_aplicado ) or (cx.mes_gratis_ssb = 0) or (cx.mes_gratis_ssb is null) then ---> Lo aplica si el mes de
                     --  dbms_output.put_line ( ' Descuento ' ||'bloque 1');               
                        --------------------- Se genera el descuento desde la Venta ---------
                        If cx.MONTO_DESC > 0 then 
                     --   dbms_output.put_line ( ' Descuento ' ||'bloque 2');
                            VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);              

                             BEGIN
                                 INSERT INTO TBRACCD VALUES (
                                                             cx.PIDM, --TBRACCD_PIDM
                                                             VL_SECUENCIA, --TBRACCD_TRAN_NUMBER
                                                             cx.PERIODO, --TBRACCD_TERM_CODE
                                                             cx.codigo_desc, --TBRACCD_DETAIL_CODE
                                                             USER, --TBRACCD_USER
                                                             SYSDATE, --TBRACCD_ENTRY_DATE
                                                             cx.monto_desc, --TBRACCD_AMOUNT
                                                             cx.monto_desc*-1, --TBRACCD_BALANCE
                                                             TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
                                                             NULL, --TBRACCD_BILL_DATE
                                                             NULL, --TBRACCD_DUE_DATE
                                                             cx.desc_descr, --TBRACCD_DESC
                                                             vl_orden, --TBRACCD_RECEIPT_NUMBER
                                                             VL_SEC_CARGO, --TBRACCD_TRAN_NUMBER_PAID
                                                             NULL, --TBRACCD_CROSSREF_PIDM
                                                             NULL, --TBRACCD_CROSSREF_NUMBER
                                                             NULL, --TBRACCD_CROSSREF_DETAIL_CODE
                                                             'T', --TBRACCD_SRCE_CODE
                                                             'Y', --TBRACCD_ACCT_FEED_IND
                                                             SYSDATE, --TBRACCD_ACTIVITY_DATE
                                                             0, --TBRACCD_SESSION_NUMBER
                                                             NULL, --TBRACCD_CSHR_END_DATE
                                                             NULL, --TBRACCD_CRN
                                                             NULL, --TBRACCD_CROSSREF_SRCE_CODE
                                                             NULL, --TBRACCD_LOC_MDT
                                                             NULL, --TBRACCD_LOC_MDT_SEQ
                                                             NULL, --TBRACCD_RATE
                                                             NULL, --TBRACCD_UNITS
                                                             NULL, --TBRACCD_DOCUMENT_NUMBER
                                                             TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
                                                             NULL, --TBRACCD_PAYMENT_ID
                                                             NULL, --TBRACCD_INVOICE_NUMBER
                                                             NULL, --TBRACCD_STATEMENT_DATE
                                                             NULL, --TBRACCD_INV_NUMBER_PAID
                                                             cx.cargo_moneda, --TBRACCD_CURR_CODE
                                                             NULL, --TBRACCD_EXCHANGE_DIFF
                                                             NULL, --TBRACCD_FOREIGN_AMOUNT
                                                             NULL, --TBRACCD_LATE_DCAT_CODE
                                                             cx.FECHA_INICIO, --TBRACCD_FEED_DATE
                                                             NULL, --TBRACCD_FEED_DOC_CODE
                                                             NULL, --TBRACCD_ATYP_CODE
                                                             NULL, --TBRACCD_ATYP_SEQNO
                                                             NULL, --TBRACCD_CARD_TYPE_VR
                                                             NULL, --TBRACCD_CARD_EXP_DATE_VR
                                                             NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
                                                             NULL, --TBRACCD_CROSSREF_DCAT_CODE
                                                             NULL, --TBRACCD_ORIG_CHG_IND
                                                             NULL, --TBRACCD_CCRD_CODE
                                                             NULL, --TBRACCD_MERCHANT_ID
                                                             NULL, --TBRACCD_TAX_REPT_YEAR
                                                             NULL, --TBRACCD_TAX_REPT_BOX
                                                             NULL, --TBRACCD_TAX_AMOUNT
                                                             NULL, --TBRACCD_TAX_FUTURE_IND
                                                             'UTEL X', --TBRACCD_DATA_ORIGIN
                                                             'UTEL X', --TBRACCD_CREATE_SOURCE
                                                             NULL, --TBRACCD_CPDT_IND
                                                             NULL, --TBRACCD_AIDY_CODE
                                                             cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
                                                             null, --TBRACCD_PERIOD
                                                             NULL, --TBRACCD_SURROGATE_ID
                                                             NULL, --TBRACCD_VERSION
                                                             USER, --TBRACCD_USER_ID
                                                             NULL ); --TBRACCD_VPDI_CODE
                             EXCEPTION
                             WHEN OTHERS THEN
                                null;
                             END;                     
                        End if;
              
                    Elsif cx.mes_gratis_ssb > cx.mes_gratis_ssb_aplicado  and vl_existe_cargo >=1   then -------------Victor
                        -- dbms_output.put_line ( ' Descuento ' ||'bloque 3');
                         VL_SECUENCIA:=null;
                         VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);
                         vl_codigo_cargo:= null;
                         
                         Begin 
                         Select substr (cx.matricula,1,2) ||trim (ZSTPARA_PARAM_DESC)
                             Into vl_codigo_cargo
                         from ZSTPARA
                         where 1=1
                         and ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
                         AND ZSTPARA_PARAM_ID = 'UTLX';
                         Exception
                         When Others then 
                          vl_codigo_cargo:=null;
                         End; 


                         Begin
                             Select count(*)
                                Into vl_existe_cargo
                             from tbraccd
                             where 1= 1
                             and tbraccd_pidm = cx.pidm 
                             And tbraccd_detail_code = vl_codigo_cargo; 
                         Exception
                         When Others then 
                         vl_existe_cargo:=0; 
                         End;   


                         vl_codigo_Descrip:= null;
                         vl_moneda:= null;
                         Begin 
                             SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                                  Into vl_codigo_Descrip, vl_moneda
                             FROM TBBDETC
                             join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                             WHERE TBBDETC_DETAIL_CODE = vl_codigo_cargo;
                         Exception
                         When Others then 
                         vl_codigo_Descrip:= null;
                         vl_moneda:= null;
                         --DBMS_OUTPUT.PUT_LINE('Error Recupera Codigos desc= '||sqlerrm );
                         END; 
                      
                        If cx.monto_Cargo > 0 and vl_existe_cargo = 0 then
                       -- dbms_output.put_line ( ' Descuento ' ||'bloque 4'); 
 
                             BEGIN
                                 INSERT INTO TBRACCD VALUES ( cx.PIDM, --TBRACCD_PIDM
                                                             VL_SECUENCIA, --TBRACCD_TRAN_NUMBER
                                                             cx.PERIODO, --TBRACCD_TERM_CODE
                                                             vl_codigo_cargo, --TBRACCD_DETAIL_CODE
                                                             USER, --TBRACCD_USER
                                                             SYSDATE, --TBRACCD_ENTRY_DATE
                                                             cx.monto_Cargo, --TBRACCD_AMOUNT
                                                             cx.monto_Cargo*-1, --TBRACCD_BALANCE
                                                             TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
                                                             NULL, --TBRACCD_BILL_DATE
                                                             NULL, --TBRACCD_DUE_DATE
                                                             vl_codigo_Descrip, --TBRACCD_DESC
                                                             vl_orden, --TBRACCD_RECEIPT_NUMBER
                                                             VL_SEC_CARGO, --TBRACCD_TRAN_NUMBER_PAID
                                                             NULL, --TBRACCD_CROSSREF_PIDM
                                                             NULL, --TBRACCD_CROSSREF_NUMBER
                                                             NULL, --TBRACCD_CROSSREF_DETAIL_CODE
                                                             'T', --TBRACCD_SRCE_CODE
                                                             'Y', --TBRACCD_ACCT_FEED_IND
                                                             SYSDATE, --TBRACCD_ACTIVITY_DATE
                                                             0, --TBRACCD_SESSION_NUMBER
                                                             NULL, --TBRACCD_CSHR_END_DATE
                                                             NULL, --TBRACCD_CRN
                                                             NULL, --TBRACCD_CROSSREF_SRCE_CODE
                                                             NULL, --TBRACCD_LOC_MDT
                                                             NULL, --TBRACCD_LOC_MDT_SEQ
                                                             NULL, --TBRACCD_RATE
                                                             NULL, --TBRACCD_UNITS
                                                             NULL, --TBRACCD_DOCUMENT_NUMBER
                                                             TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
                                                             NULL, --TBRACCD_PAYMENT_ID
                                                             NULL, --TBRACCD_INVOICE_NUMBER
                                                             NULL, --TBRACCD_STATEMENT_DATE
                                                             NULL, --TBRACCD_INV_NUMBER_PAID
                                                             vl_moneda, --TBRACCD_CURR_CODE
                                                             NULL, --TBRACCD_EXCHANGE_DIFF
                                                             NULL, --TBRACCD_FOREIGN_AMOUNT
                                                             NULL, --TBRACCD_LATE_DCAT_CODE
                                                             cx.FECHA_INICIO, --TBRACCD_FEED_DATE
                                                             NULL, --TBRACCD_FEED_DOC_CODE
                                                             NULL, --TBRACCD_ATYP_CODE
                                                             NULL, --TBRACCD_ATYP_SEQNO
                                                             NULL, --TBRACCD_CARD_TYPE_VR
                                                             NULL, --TBRACCD_CARD_EXP_DATE_VR
                                                             NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
                                                             NULL, --TBRACCD_CROSSREF_DCAT_CODE
                                                             NULL, --TBRACCD_ORIG_CHG_IND
                                                             NULL, --TBRACCD_CCRD_CODE
                                                             NULL, --TBRACCD_MERCHANT_ID
                                                             NULL, --TBRACCD_TAX_REPT_YEAR
                                                             NULL, --TBRACCD_TAX_REPT_BOX
                                                             NULL, --TBRACCD_TAX_AMOUNT
                                                             NULL, --TBRACCD_TAX_FUTURE_IND
                                                             'UTEL X', --TBRACCD_DATA_ORIGIN
                                                             'UTEL X', --TBRACCD_CREATE_SOURCE
                                                             NULL, --TBRACCD_CPDT_IND
                                                             NULL, --TBRACCD_AIDY_CODE
                                                             cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
                                                             null, --TBRACCD_PERIOD
                                                             NULL, --TBRACCD_SURROGATE_ID
                                                             NULL, --TBRACCD_VERSION
                                                             USER, --TBRACCD_USER_ID
                                                             NULL ); --TBRACCD_VPDI_CODE
                             EXCEPTION
                             WHEN OTHERS THEN
                                null;
                             --DBMS_OUTPUT.PUT_LINE(VL_ERROR); 
                             END; 

                             Begin
                                 Update SZTUTLX
                                 set SZTUTLX_GRATIS_APLI = nvl (SZTUTLX_GRATIS_APLI,0) + 1
                                 Where SZTUTLX_PIDM = cx.pidm
                                 And SZTUTLX_SEQ_NO = cx.seq_utelx;
                             Exception
                             When Others then 
                                null;
                             --DBMS_OUTPUT.PUT_LINE(VL_ERROR); 
                             End;
                        Elsif  cx.monto_Cargo > 0 and vl_existe_cargo > 0 then 
                             Begin
                                 Update SZTUTLX
                                 set SZTUTLX_GRATIS_APLI = nvl (SZTUTLX_GRATIS_APLI,0) + 1
                                 Where SZTUTLX_PIDM = cx.pidm
                                 And SZTUTLX_SEQ_NO = cx.seq_utelx;
                                 commit;
                             Exception
                             When Others then 
                                null;
                             --DBMS_OUTPUT.PUT_LINE(VL_ERROR); 
                             End;                        
                        End if;
                    
                    
                    End if;              

              End if; 
              
         End if;


      End Loop;  
      Commit;    
      
      
----------------------------- Se inicia el proceso de registro en la cartera para paquete Dinamico en 0 ------------------------

      vl_existe_cargo:=0;
      vl_existe_cartera:=0;
      
      For cx in (
      
                    select *
                    from UTELX_CARGO
                    where 1 = 1
                     And ORIGEN in ('Dinamico')
                     And PIDM  = nvl (P_pidm, pidm)
               --      AND matricula IN ('010459935') ------ Aqui pones las matriculas AGEDA
                    order by ORDEN_APLICACION                     
      
      ) loop
      
      
        If cx.periodicidad = 1 then 
      
             Begin
                 Select count(*)
                 Into vl_existe_cargo
                 from tbraccd
                 where 1= 1
                 and tbraccd_pidm = cx.pidm 
                 And tbraccd_detail_code = cx.codigo_cargo 
                 And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE));
             Exception
             When Others then 
             vl_existe_cargo:=0; 
             End;     
       
        ElsIf cx.periodicidad != 1 then --> Macana
            Begin     
            
                Select ADD_MONTHS (trunc (TBRACCD_EFFECTIVE_DATE,'MM'), cx.periodicidad) fecha
                 Into vl_fecha_fut
                from tbraccd a
                where a.tbraccd_pidm = cx.pidm 
                And a.tbraccd_detail_code = cx.codigo_cargo
                And a.TBRACCD_TRAN_NUMBER = (select max (a1.TBRACCD_TRAN_NUMBER)
                                             from tbraccd a1
                                             Where a.tbraccd_pidm = a1.tbraccd_pidm
                                             And a.tbraccd_detail_code = a1.tbraccd_detail_code);        

            Exception 
                When Others then 
                    vl_fecha_fut:= null;
            End;

            If vl_fecha_fut is not null and vl_fecha_fut = TRUNC(SYSDATE, 'MM') then
               vl_existe_cargo:=0;
                 
                 Begin
                     Select count(*)
                     Into vl_existe_cargo
                     from tbraccd
                     where 1= 1
                     and tbraccd_pidm = cx.pidm 
                     And tbraccd_detail_code = cx.codigo_cargo 
                     And trunc (TBRACCD_EFFECTIVE_DATE) between vl_fecha_fut and TRUNC(LAST_DAY(vl_fecha_fut));
                 Exception
                 When Others then 
                 vl_existe_cargo:=0; 
                 End;                 
               
               
            Else
              vl_existe_cargo := 1;
                
            End if; 

       
        End if;
      

         Begin
             Select count(*)
             Into vl_existe_cartera
             from tbraccd, TZTNCD
             where 1= 1
             and tbraccd_pidm = cx.pidm 
             And tbraccd_detail_code = TZTNCD_CODE
             And TZTNCD_CONCEPTO ='Venta'
             And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE));
         Exception
         When Others then 
         vl_existe_cartera:=0; 
         End;  


         
         
         If vl_existe_cargo = 0 and vl_existe_cartera >= 1 and trim (cx.origen) = 'Dinamico' then
         
             VL_DIA := NULL;
             VL_MES := NULL;
             VL_ANO := NULL;   
             VL_VENCIMIENTO := null;      

             BEGIN
                 VL_DIA := cx.VENCIMIENTO;
                 VL_MES := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 4, 2);
                 VL_ANO := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 7, 4);

                 IF VL_DIA = '30' THEN
                     VL_VENCIMIENTO := CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
                 ELSE
                     VL_VENCIMIENTO := VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
                 END IF;
             Exception
                When Others then 
                    null;
             END;          
         
             VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);
             VL_SEC_CARGO:= VL_SECUENCIA; 
             vl_orden:= null;
         
             Begin
                 Select TZTORDR_CONTADOR
                     Into vl_orden 
                 from TZTORDR
                 where TZTORDR_PIDM = cx.pidm
                 And TZTORDR_CAMPUS = cx.campus
                 And TZTORDR_NIVEL = cx.nivel
                 And TZTORDR_ESTATUS = 'S'
                 And trunc (TZTORDR_FECHA_INICIO) = cx.fecha_inicio;
             Exception
             When Others then 
                 vl_orden:= null;
             End;         
         
             If vl_orden is null then             
                 BEGIN
                     SELECT MAX(TZTORDR_CONTADOR)+1
                         INTO vl_orden
                     FROM TZTORDR;
                 EXCEPTION
                 WHEN OTHERS THEN
                  vl_orden:= NULL;
                 END;         
             End if; 
             
             If vl_orden is not null then 
                 BEGIN
                     INSERT INTO TZTORDR (
                                         TZTORDR_CAMPUS,
                                         TZTORDR_NIVEL,
                                         TZTORDR_CONTADOR,
                                         TZTORDR_PROGRAMA,
                                         TZTORDR_PIDM,
                                         TZTORDR_ID,
                                         TZTORDR_ESTATUS,
                                         TZTORDR_ACTIVITY_DATE,
                                         TZTORDR_USER,
                                         TZTORDR_DATA_ORIGIN,
                                         TZTORDR_NO_REGLA,
                                         TZTORDR_FECHA_INICIO,
                                         TZTORDR_RATE,
                                         TZTORDR_JORNADA,
                                         TZTORDR_DSI,
                                         TZTORDR_TERM_CODE
                                         )
                                     VALUES( cx.CAMPUS,
                                             cx.NIVEL,
                                             vl_orden,
                                             cx.PROGRAMA,
                                             cx.PIDM,
                                             cx.MATRICULA,
                                             'S',
                                             SYSDATE,
                                             USER,
                                             'AUTO_UTELX',
                                             NULL,
                                             TRUNC(SYSDATE),
                                             NULL,
                                             NULL,
                                             NULL,
                                             cx.PERIODO
                                     );
                 EXCEPTION
                 WHEN OTHERS THEN
                    null;
                 END;             
             End if;
             

                ------------------------ Realiza el registro del cargo ------------------------
                 BEGIN
                     INSERT INTO TBRACCD VALUES (cx.PIDM, --TBRACCD_PIDM
                                                 VL_SEC_CARGO, --TBRACCD_TRAN_NUMBER
                                                 cx.PERIODO, --TBRACCD_TERM_CODE
                                                 cx.codigo_cargo, --TBRACCD_DETAIL_CODE
                                                 USER, --TBRACCD_USER
                                                 VL_VENCIMIENTO, --TBRACCD_ENTRY_DATE
                                                 0, --TBRACCD_AMOUNT
                                                 0, --TBRACCD_BALANCE
                                                 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
                                                 NULL, --TBRACCD_BILL_DATE
                                                 NULL, --TBRACCD_DUE_DATE
                                                 cx.cargo_Descr, --TBRACCD_DESC
                                                 vl_orden, --TBRACCD_RECEIPT_NUMBER
                                                 null, --TBRACCD_TRAN_NUMBER_PAID
                                                 NULL, --TBRACCD_CROSSREF_PIDM
                                                 NULL, --TBRACCD_CROSSREF_NUMBER
                                                 NULL, --TBRACCD_CROSSREF_DETAIL_CODE
                                                 'T', --TBRACCD_SRCE_CODE
                                                 'Y', --TBRACCD_ACCT_FEED_IND
                                                 VL_VENCIMIENTO, --TBRACCD_ACTIVITY_DATE
                                                 0, --TBRACCD_SESSION_NUMBER
                                                 NULL, --TBRACCD_CSHR_END_DATE
                                                 NULL, --TBRACCD_CRN
                                                 NULL, --TBRACCD_CROSSREF_SRCE_CODE
                                                 NULL, --TBRACCD_LOC_MDT
                                                 NULL, --TBRACCD_LOC_MDT_SEQ
                                                 NULL, --TBRACCD_RATE
                                                 NULL, --TBRACCD_UNITS
                                                 NULL, --TBRACCD_DOCUMENT_NUMBER
                                                 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
                                                 NULL, --TBRACCD_PAYMENT_ID
                                                 NULL, --TBRACCD_INVOICE_NUMBER
                                                 NULL, --TBRACCD_STATEMENT_DATE
                                                 NULL, --TBRACCD_INV_NUMBER_PAID
                                                 cx.cargo_moneda, --TBRACCD_CURR_CODE
                                                 NULL, --TBRACCD_EXCHANGE_DIFF
                                                 NULL, --TBRACCD_FOREIGN_AMOUNT
                                                 NULL, --TBRACCD_LATE_DCAT_CODE
                                                 cx.FECHA_INICIO, --TBRACCD_FEED_DATE
                                                 NULL, --TBRACCD_FEED_DOC_CODE
                                                 NULL, --TBRACCD_ATYP_CODE
                                                 NULL, --TBRACCD_ATYP_SEQNO
                                                 NULL, --TBRACCD_CARD_TYPE_VR
                                                 NULL, --TBRACCD_CARD_EXP_DATE_VR
                                                 NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
                                                 NULL, --TBRACCD_CROSSREF_DCAT_CODE
                                                 NULL, --TBRACCD_ORIG_CHG_IND
                                                 NULL, --TBRACCD_CCRD_CODE
                                                 NULL, --TBRACCD_MERCHANT_ID
                                                 NULL, --TBRACCD_TAX_REPT_YEAR
                                                 NULL, --TBRACCD_TAX_REPT_BOX
                                                 NULL, --TBRACCD_TAX_AMOUNT
                                                 NULL, --TBRACCD_TAX_FUTURE_IND
                                                 'UTEL X', --TBRACCD_DATA_ORIGIN
                                                 'UTEL X', --TBRACCD_CREATE_SOURCE
                                                 NULL, --TBRACCD_CPDT_IND
                                                 NULL, --TBRACCD_AIDY_CODE
                                                 cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
                                                 null, --TBRACCD_PERIOD
                                                 NULL, --TBRACCD_SURROGATE_ID
                                                 NULL, --TBRACCD_VERSION
                                                 USER, --TBRACCD_USER_ID
                                                 NULL ); --TBRACCD_VPDI_CODE

                 EXCEPTION
                 WHEN OTHERS THEN
                  null;
                 --DBMS_OUTPUT.PUT_LINE(VL_ERROR); 
                 END;             
 
              
         End if;


      End Loop;  
      Commit;          
             
      
       ------------------------------------ Proceso que etiqueta a los alumnos de UtelX---------------------------
       
      For cx in (
                    
                    Select pidm, matricula, campus, nivel
                    from UTELX_CARGO
                    where 1= 1
                    And PIDM  = nvl (P_pidm, pidm)
                
      ) loop
      
      
            Begin
                    vl_salida:=pkg_utilerias.F_Genera_Etiqueta(cx.pidm, 'UTLX', 'UTEL-X', 'MASIVO');
                    Commit;
            Exception
                When Others then 
                    null;    
            End;
      
      
      
      End loop;
      
      
      --------------------------------- Se inicia el proceso para crear descuentos para  Dinamicos -----------------------------
      
      For cx in (
      
                Select *
                from UTELX_CARGO   
                where origen in ('Dinamico')    
                And MES_GRATIS_SSB > 0
                And MES_GRATIS_SSB_APLICADO < MES_GRATIS_SSB
                And PIDM  = nvl (P_pidm, pidm)
                
                
      ) loop
            
                         vl_codigo_cargo:= null;
                         VL_SECUENCIA:=null;
                         VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);
                         
                         Begin 
                             Select substr (cx.matricula,1,2) ||trim (ZSTPARA_PARAM_DESC)
                                 Into vl_codigo_cargo
                             from ZSTPARA
                             where 1=1
                             and ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
                             AND ZSTPARA_PARAM_ID = 'UTLX';
                         Exception
                         When Others then 
                          vl_codigo_cargo:=null;
                         End;             
            
                         vl_existe_cargo:=0;
                         
                         Begin
                             Select count(*)
                               Into vl_existe_cargo
                             from tbraccd
                             where 1= 1
                             and tbraccd_pidm = cx.pidm 
                             And tbraccd_detail_code = vl_codigo_cargo 
                             And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                             And TBRACCD_CREATE_SOURCE = 'RETE_UTELX' ;  --Con este origen sabemos los que llegan por retencion al estado de cuenta
                         Exception
                         When Others then 
                         vl_existe_cargo:=0; 
                         End;             
            
                         If vl_existe_cargo = 0 and cx.monto_Cargo > 0  then 
                         
                             vl_codigo_Descrip:= null;
                             vl_moneda:= null;
                             Begin 
                                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                                      Into vl_codigo_Descrip, vl_moneda
                                 FROM TBBDETC
                                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                                 WHERE TBBDETC_DETAIL_CODE = vl_codigo_cargo;
                             Exception
                             When Others then 
                                 vl_codigo_Descrip:= null;
                                 vl_moneda:= null;
                             END;                          
                         

                             VL_DIA := NULL;
                             VL_MES := NULL;
                             VL_ANO := NULL;   
                             VL_VENCIMIENTO := null;      
                             BEGIN
                                 VL_DIA := cx.VENCIMIENTO;
                                 VL_MES := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 4, 2);
                                 VL_ANO := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 7, 4);

                                 IF VL_DIA = '30' THEN
                                     VL_VENCIMIENTO := CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
                                 ELSE
                                     VL_VENCIMIENTO := VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
                                 END IF;
                             Exception
                                When Others then 
                                    null;
                             END;  


                             --------------------------------- Se recupera la fecha en que se otorgo el beneficio de retencion --------------------------
                                 vl_fecha_ret:= null;
                             
                                 Begin 
                                    Select trunc (GORADID_ACTIVITY_DATE)Creacion
                                        Into vl_fecha_ret 
                                    from goradid
                                    Where 1=1
                                    And goradid_pidm = cx.pidm
                                    And GORADID_ADID_CODE = 'RUTX';
                                 Exception
                                    When Others then 
                                       vl_fecha_ret:= To_DATE(VL_VENCIMIENTO,'DD,MM,YYYY');
                                 End;                              
                             
                              
                                 If  vl_fecha_ret <=  To_DATE(VL_VENCIMIENTO,'DD,MM,YYYY') then 
                             

                                     vl_orden:= null;
                                 
                                     Begin
                                         Select TZTORDR_CONTADOR
                                             Into vl_orden 
                                         from TZTORDR
                                         where TZTORDR_PIDM = cx.pidm
                                         And TZTORDR_CAMPUS = cx.campus
                                         And TZTORDR_NIVEL = cx.nivel
                                         And TZTORDR_ESTATUS = 'S'
                                         And trunc (TZTORDR_FECHA_INICIO) = cx.fecha_inicio;
                                     Exception
                                     When Others then 
                                         vl_orden:= null;
                                     End;         
                                 
                                     If vl_orden is null then             
                                         BEGIN
                                             SELECT MAX(TZTORDR_CONTADOR)+1
                                                 INTO vl_orden
                                             FROM TZTORDR;
                                         EXCEPTION
                                         WHEN OTHERS THEN
                                          vl_orden:= NULL;
                                         END;         
                                     End if; 
                                     
                                     If vl_orden is not null then 
                                         BEGIN
                                             INSERT INTO TZTORDR (
                                                                 TZTORDR_CAMPUS,
                                                                 TZTORDR_NIVEL,
                                                                 TZTORDR_CONTADOR,
                                                                 TZTORDR_PROGRAMA,
                                                                 TZTORDR_PIDM,
                                                                 TZTORDR_ID,
                                                                 TZTORDR_ESTATUS,
                                                                 TZTORDR_ACTIVITY_DATE,
                                                                 TZTORDR_USER,
                                                                 TZTORDR_DATA_ORIGIN,
                                                                 TZTORDR_NO_REGLA,
                                                                 TZTORDR_FECHA_INICIO,
                                                                 TZTORDR_RATE,
                                                                 TZTORDR_JORNADA,
                                                                 TZTORDR_DSI,
                                                                 TZTORDR_TERM_CODE
                                                                 )
                                                             VALUES( cx.CAMPUS,
                                                                     cx.NIVEL,
                                                                     vl_orden,
                                                                     cx.PROGRAMA,
                                                                     cx.PIDM,
                                                                     cx.MATRICULA,
                                                                     'S',
                                                                     SYSDATE,
                                                                     USER,
                                                                     'AUTO_UTELX',
                                                                     NULL,
                                                                     TRUNC(SYSDATE),
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     cx.PERIODO
                                                             );
                                         EXCEPTION
                                         WHEN OTHERS THEN
                                            null;
                                         END;             
                                     End if;
                     
                                     BEGIN
                                         INSERT INTO TBRACCD VALUES ( cx.PIDM, --TBRACCD_PIDM
                                                                     VL_SECUENCIA, --TBRACCD_TRAN_NUMBER
                                                                     cx.PERIODO, --TBRACCD_TERM_CODE
                                                                     vl_codigo_cargo, --TBRACCD_DETAIL_CODE
                                                                     USER, --TBRACCD_USER
                                                                     SYSDATE, --TBRACCD_ENTRY_DATE
                                                                     cx.monto_Cargo, --TBRACCD_AMOUNT
                                                                     cx.monto_Cargo*-1, --TBRACCD_BALANCE
                                                                     TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
                                                                     NULL, --TBRACCD_BILL_DATE
                                                                     NULL, --TBRACCD_DUE_DATE
                                                                     vl_codigo_Descrip, --TBRACCD_DESC
                                                                     vl_orden, --TBRACCD_RECEIPT_NUMBER
                                                                     null, --TBRACCD_TRAN_NUMBER_PAID
                                                                     NULL, --TBRACCD_CROSSREF_PIDM
                                                                     NULL, --TBRACCD_CROSSREF_NUMBER
                                                                     NULL, --TBRACCD_CROSSREF_DETAIL_CODE
                                                                     'T', --TBRACCD_SRCE_CODE
                                                                     'Y', --TBRACCD_ACCT_FEED_IND
                                                                     SYSDATE, --TBRACCD_ACTIVITY_DATE
                                                                     0, --TBRACCD_SESSION_NUMBER
                                                                     NULL, --TBRACCD_CSHR_END_DATE
                                                                     NULL, --TBRACCD_CRN
                                                                     NULL, --TBRACCD_CROSSREF_SRCE_CODE
                                                                     NULL, --TBRACCD_LOC_MDT
                                                                     NULL, --TBRACCD_LOC_MDT_SEQ
                                                                     NULL, --TBRACCD_RATE
                                                                     NULL, --TBRACCD_UNITS
                                                                     NULL, --TBRACCD_DOCUMENT_NUMBER
                                                                     TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
                                                                     NULL, --TBRACCD_PAYMENT_ID
                                                                     NULL, --TBRACCD_INVOICE_NUMBER
                                                                     NULL, --TBRACCD_STATEMENT_DATE
                                                                     NULL, --TBRACCD_INV_NUMBER_PAID
                                                                     vl_moneda, --TBRACCD_CURR_CODE
                                                                     NULL, --TBRACCD_EXCHANGE_DIFF
                                                                     NULL, --TBRACCD_FOREIGN_AMOUNT
                                                                     NULL, --TBRACCD_LATE_DCAT_CODE
                                                                     cx.FECHA_INICIO, --TBRACCD_FEED_DATE
                                                                     NULL, --TBRACCD_FEED_DOC_CODE
                                                                     NULL, --TBRACCD_ATYP_CODE
                                                                     NULL, --TBRACCD_ATYP_SEQNO
                                                                     NULL, --TBRACCD_CARD_TYPE_VR
                                                                     NULL, --TBRACCD_CARD_EXP_DATE_VR
                                                                     NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
                                                                     NULL, --TBRACCD_CROSSREF_DCAT_CODE
                                                                     NULL, --TBRACCD_ORIG_CHG_IND
                                                                     NULL, --TBRACCD_CCRD_CODE
                                                                     NULL, --TBRACCD_MERCHANT_ID
                                                                     NULL, --TBRACCD_TAX_REPT_YEAR
                                                                     NULL, --TBRACCD_TAX_REPT_BOX
                                                                     NULL, --TBRACCD_TAX_AMOUNT
                                                                     NULL, --TBRACCD_TAX_FUTURE_IND
                                                                     'RETE_UTELX', --TBRACCD_DATA_ORIGIN
                                                                     'RETE_UTELX', --TBRACCD_CREATE_SOURCE
                                                                     NULL, --TBRACCD_CPDT_IND
                                                                     NULL, --TBRACCD_AIDY_CODE
                                                                     cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
                                                                     null, --TBRACCD_PERIOD
                                                                     NULL, --TBRACCD_SURROGATE_ID
                                                                     NULL, --TBRACCD_VERSION
                                                                     USER, --TBRACCD_USER_ID
                                                                     NULL ); --TBRACCD_VPDI_CODE
                                     EXCEPTION
                                     WHEN OTHERS THEN
                                        null;
                                     --DBMS_OUTPUT.PUT_LINE(VL_ERROR); 
                                     END; 

                                     Begin
                                         Update SZTUTLX
                                         set SZTUTLX_GRATIS_APLI = nvl (SZTUTLX_GRATIS_APLI,0) + 1
                                         Where SZTUTLX_PIDM = cx.pidm
                                         And SZTUTLX_SEQ_NO = cx.seq_utelx;
                                     Exception
                                     When Others then 
                                        null;
                                     --DBMS_OUTPUT.PUT_LINE(VL_ERROR); 
                                     End;

                      
                                 End if;
      
               
                         End if; 
                         Commit;
            
            
      End loop;         
      
      

      --------------------------------- Se inicia el proceso para crear descuentos para  Fijos -----------------------------
      
      For cx in (
      
                Select *
                from UTELX_CARGO   
                where origen in ('FIJO')    
                And MES_GRATIS_SSB > 0
                And MES_GRATIS_SSB_APLICADO < MES_GRATIS_SSB
                And PIDM  = nvl (P_pidm, pidm)
                
                
      ) loop
            
        --  DBMS_OUTPUT.PUT_LINE('Entra aplicar descuento FIJO'); 
      
      
                         vl_codigo_cargo:= null;
                         VL_SECUENCIA:=null;
                         VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (cx.pidm);
                         
                      --   DBMS_OUTPUT.PUT_LINE('Valor de la secuencia del descuento '||VL_SECUENCIA); 
                        
                             Begin 
                                 Select substr (cx.matricula,1,2) ||trim (ZSTPARA_PARAM_DESC)
                                     Into vl_codigo_cargo
                                 from ZSTPARA
                                 where 1=1
                                 and ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
                                 AND ZSTPARA_PARAM_ID = 'UTLX';
                             Exception
                             When Others then 
                              vl_codigo_cargo:=null;
                             End; 
          
            
                          --  DBMS_OUTPUT.PUT_LINE('Recupera clave del descuento '||vl_codigo_cargo); 

                         vl_existe_cargo:=0;
                         
                         Begin
                             Select count(*)
                               Into vl_existe_cargo
                             from tbraccd
                             where 1= 1
                             and tbraccd_pidm = cx.pidm 
                             And tbraccd_detail_code = vl_codigo_cargo 
                             And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                             And TBRACCD_CREATE_SOURCE = 'RETE_UTELX' ;  --Con este origen sabemos los que llegan por retencion al estado de cuenta
                         Exception
                         When Others then 
                         vl_existe_cargo:=0; 
                         End;             
            
                           --  DBMS_OUTPUT.PUT_LINE('Valida que exista el descuento en el mes '||vl_existe_cargo); 

                         If vl_existe_cargo = 0 and cx.monto_desc > 0  then 
                         
                            --  DBMS_OUTPUT.PUT_LINE('Entra a Valida que aplique el descuento en el mes '||vl_existe_cargo ||'*'||cx.monto_desc); 
                         
                             vl_codigo_Descrip:= null;
                             vl_moneda:= null;
                             Begin 
                                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                                      Into vl_codigo_Descrip, vl_moneda
                                 FROM TBBDETC
                                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                                 WHERE TBBDETC_DETAIL_CODE = vl_codigo_cargo;
                             Exception
                             When Others then 
                                 vl_codigo_Descrip:= null;
                                 vl_moneda:= null;
                             END;                          
                         

                             VL_DIA := NULL;
                             VL_MES := NULL;
                             VL_ANO := NULL;   
                             VL_VENCIMIENTO := null;      
                             BEGIN
                                 VL_DIA := cx.VENCIMIENTO;
                                 VL_MES := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 4, 2);
                                 VL_ANO := SUBSTR (TO_CHAR(TRUNC(SYSDATE),'dd/mm/rrrr'), 7, 4);

                                 IF VL_DIA = '30' THEN
                                     VL_VENCIMIENTO := CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
                                 ELSE
                                     VL_VENCIMIENTO := VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO;
                                 END IF;
                             Exception
                                When Others then 
                                    null;
                             END;  

                             vl_orden:= null;
                         
                             --------------------------------- Se recupera la fecha en que se otorgo el beneficio de retencion --------------------------
                             vl_fecha_ret:= null;
                             
                             Begin 
                                Select trunc (GORADID_ACTIVITY_DATE)Creacion
                                    Into vl_fecha_ret 
                                from goradid
                                Where 1=1
                                And goradid_pidm = cx.pidm
                                And GORADID_ADID_CODE = 'RUTX';
                             Exception
                                When Others then 
                                   vl_fecha_ret:= To_DATE(VL_VENCIMIENTO,'DD,MM,YYYY');
                             End;                              
                             
                  --  DBMS_OUTPUT.PUT_LINE('Valida que la fecha de retencion sea menor al cargo '||vl_fecha_ret ||'*'||VL_VENCIMIENTO); 
                              
                             If  vl_fecha_ret <=  To_DATE(VL_VENCIMIENTO,'DD,MM,YYYY') then                          
                            
                          --  DBMS_OUTPUT.PUT_LINE('Entra Valida que la fecha de retencion sea menor al cargo '||vl_fecha_ret ||'*'||VL_VENCIMIENTO); 
                                 
                                 Begin
                                     Select TZTORDR_CONTADOR
                                         Into vl_orden 
                                     from TZTORDR
                                     where TZTORDR_PIDM = cx.pidm
                                     And TZTORDR_CAMPUS = cx.campus
                                     And TZTORDR_NIVEL = cx.nivel
                                     And TZTORDR_ESTATUS = 'S'
                                     And trunc (TZTORDR_FECHA_INICIO) = cx.fecha_inicio;
                                 Exception
                                 When Others then 
                                     vl_orden:= null;
                                 End;         
                                 
                                 If vl_orden is null then             
                                     BEGIN
                                         SELECT MAX(TZTORDR_CONTADOR)+1
                                             INTO vl_orden
                                         FROM TZTORDR;
                                     EXCEPTION
                                     WHEN OTHERS THEN
                                      vl_orden:= NULL;
                                     END;         
                                 End if; 
                                     
                                 If vl_orden is not null then 
                                     BEGIN
                                         INSERT INTO TZTORDR (
                                                             TZTORDR_CAMPUS,
                                                             TZTORDR_NIVEL,
                                                             TZTORDR_CONTADOR,
                                                             TZTORDR_PROGRAMA,
                                                             TZTORDR_PIDM,
                                                             TZTORDR_ID,
                                                             TZTORDR_ESTATUS,
                                                             TZTORDR_ACTIVITY_DATE,
                                                             TZTORDR_USER,
                                                             TZTORDR_DATA_ORIGIN,
                                                             TZTORDR_NO_REGLA,
                                                             TZTORDR_FECHA_INICIO,
                                                             TZTORDR_RATE,
                                                             TZTORDR_JORNADA,
                                                             TZTORDR_DSI,
                                                             TZTORDR_TERM_CODE
                                                             )
                                                         VALUES( cx.CAMPUS,
                                                                 cx.NIVEL,
                                                                 vl_orden,
                                                                 cx.PROGRAMA,
                                                                 cx.PIDM,
                                                                 cx.MATRICULA,
                                                                 'S',
                                                                 SYSDATE,
                                                                 USER,
                                                                 'AUTO_UTELX',
                                                                 NULL,
                                                                 TRUNC(SYSDATE),
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 cx.PERIODO
                                                         );
                                     EXCEPTION
                                     WHEN OTHERS THEN
                                        null;
                                     END;             
                                 End if;
                     
                                  --  DBMS_OUTPUT.PUT_LINE('Monto del Descuento '||cx.monto_Cargo); 

                                 BEGIN
                                     INSERT INTO TBRACCD VALUES ( cx.PIDM, --TBRACCD_PIDM
                                                                 VL_SECUENCIA, --TBRACCD_TRAN_NUMBER
                                                                 cx.PERIODO, --TBRACCD_TERM_CODE
                                                                 vl_codigo_cargo, --TBRACCD_DETAIL_CODE
                                                                 USER, --TBRACCD_USER
                                                                 SYSDATE, --TBRACCD_ENTRY_DATE
                                                                 nvl (cx.monto_Cargo,0) , --TBRACCD_AMOUNT
                                                                 nvl (cx.monto_Cargo,0) *-1, --TBRACCD_BALANCE
                                                                 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_EFFECTIVE_DATE
                                                                 NULL, --TBRACCD_BILL_DATE
                                                                 NULL, --TBRACCD_DUE_DATE
                                                                 vl_codigo_Descrip, --TBRACCD_DESC
                                                                 vl_orden, --TBRACCD_RECEIPT_NUMBER
                                                                 null, --TBRACCD_TRAN_NUMBER_PAID
                                                                 NULL, --TBRACCD_CROSSREF_PIDM
                                                                 NULL, --TBRACCD_CROSSREF_NUMBER
                                                                 NULL, --TBRACCD_CROSSREF_DETAIL_CODE
                                                                 'T', --TBRACCD_SRCE_CODE
                                                                 'Y', --TBRACCD_ACCT_FEED_IND
                                                                 SYSDATE, --TBRACCD_ACTIVITY_DATE
                                                                 0, --TBRACCD_SESSION_NUMBER
                                                                 NULL, --TBRACCD_CSHR_END_DATE
                                                                 NULL, --TBRACCD_CRN
                                                                 NULL, --TBRACCD_CROSSREF_SRCE_CODE
                                                                 NULL, --TBRACCD_LOC_MDT
                                                                 NULL, --TBRACCD_LOC_MDT_SEQ
                                                                 NULL, --TBRACCD_RATE
                                                                 NULL, --TBRACCD_UNITS
                                                                 NULL, --TBRACCD_DOCUMENT_NUMBER
                                                                 TO_DATE(VL_VENCIMIENTO,'DD,MM,YYYY'), --TBRACCD_TRANS_DATE
                                                                 NULL, --TBRACCD_PAYMENT_ID
                                                                 NULL, --TBRACCD_INVOICE_NUMBER
                                                                 NULL, --TBRACCD_STATEMENT_DATE
                                                                 NULL, --TBRACCD_INV_NUMBER_PAID
                                                                 vl_moneda, --TBRACCD_CURR_CODE
                                                                 NULL, --TBRACCD_EXCHANGE_DIFF
                                                                 NULL, --TBRACCD_FOREIGN_AMOUNT
                                                                 NULL, --TBRACCD_LATE_DCAT_CODE
                                                                 cx.FECHA_INICIO, --TBRACCD_FEED_DATE
                                                                 NULL, --TBRACCD_FEED_DOC_CODE
                                                                 NULL, --TBRACCD_ATYP_CODE
                                                                 NULL, --TBRACCD_ATYP_SEQNO
                                                                 NULL, --TBRACCD_CARD_TYPE_VR
                                                                 NULL, --TBRACCD_CARD_EXP_DATE_VR
                                                                 NULL, --TBRACCD_CARD_AUTH_NUMBER_VR
                                                                 NULL, --TBRACCD_CROSSREF_DCAT_CODE
                                                                 NULL, --TBRACCD_ORIG_CHG_IND
                                                                 NULL, --TBRACCD_CCRD_CODE
                                                                 NULL, --TBRACCD_MERCHANT_ID
                                                                 NULL, --TBRACCD_TAX_REPT_YEAR
                                                                 NULL, --TBRACCD_TAX_REPT_BOX
                                                                 NULL, --TBRACCD_TAX_AMOUNT
                                                                 NULL, --TBRACCD_TAX_FUTURE_IND
                                                                 'RETE_UTELX', --TBRACCD_DATA_ORIGIN
                                                                 'RETE_UTELX', --TBRACCD_CREATE_SOURCE
                                                                 NULL, --TBRACCD_CPDT_IND
                                                                 NULL, --TBRACCD_AIDY_CODE
                                                                 cx.sp, --TBRACCD_STSP_KEY_SEQUENCE
                                                                 null, --TBRACCD_PERIOD
                                                                 NULL, --TBRACCD_SURROGATE_ID
                                                                 NULL, --TBRACCD_VERSION
                                                                 USER, --TBRACCD_USER_ID
                                                                 NULL ); --TBRACCD_VPDI_CODE
                                        --  DBMS_OUTPUT.PUT_LINE('Inserta en tbraccd '||cx.monto_Cargo); 
                                 EXCEPTION
                                 WHEN OTHERS THEN
                                    null;
                                -- DBMS_OUTPUT.PUT_LINE('Error al Inserta en trabra '||sqlerrm ); 
                                 END; 

                                 Begin
                                     Update SZTUTLX
                                     set SZTUTLX_GRATIS_APLI = nvl (SZTUTLX_GRATIS_APLI,0) + 1
                                     Where SZTUTLX_PIDM = cx.pidm
                                     And SZTUTLX_SEQ_NO = cx.seq_utelx;
                                 Exception
                                 When Others then 
                                    null;
                                 --DBMS_OUTPUT.PUT_LINE(VL_ERROR); 
                                 End;

                             End if;
                       
                         End if; 
                         Commit;
            
            
      End loop;         
      
      
      
      
      

End P_MEMBRESIA_UTELX_v2; 





PROCEDURE P_CANCELA_MEMBRESIA_ESTATUS Is --- Proceso que cancelas las membresias para alumnos con los diferentes tipos de bajas

Begin

    ---------------------------- Cancela las membresias de UTELX ------------------------------

        For cx in (


                  SELECT DISTINCT
                                 A.pidm,
                                 a.matricula,
                                 a.campus,
                                 a.nivel,
                                 a.FECHA_MOV Fecha_Mov,
                                 fget_periodo_general (SUBSTR (a.matricula, 1, 2),TRUNC (SYSDATE))Periodo,
                                 a.programa,
                                 a.sp,
                                 a.estatus,
                                 a.fecha_inicio,
                                 a.FECHA_PRIMERA,
                                 b.SZTUTLX_SEQ_NO Seq,
                                 b.SZTUTLX_DISABLE_IND,
                                 b.SZTUTLX_OBS,
                                 NVL (b.SZTUTLX_GRATIS, 0) Mes_Gratis_SSB,
                                 NVL (b.SZTUTLX_GRATIS_APLI, 0) Aplicados_SSB,
                                 NVL (b.SZTUTLX_ROW2, 0) MES_GRATIS_Ret,
                                 NVL (b.SZTUTLX_ROW3, 0) Descuento_Venta,
                                 pkg_utilerias.f_etiqueta (a.pidm, 'UTLX') etiqueta,
                                 pkg_utilerias.f_calcula_rate(a.pidm,a.programa)Rate,
                                 (decode (substr (pkg_utilerias.f_calcula_rate(a.pidm,a.programa), 4, 1),'A', 15,'B', '30','C', '10'))VENCIMIENTO
                            FROM tztprog a
                                 JOIN SZTUTLX b ON     b.SZTUTLX_PIDM = a.pidm
                                       AND b.SZTUTLX_STAT_IND IN ('1', '2')
                                       AND b.SZTUTLX_SEQ_NO = (SELECT MAX (b1.SZTUTLX_SEQ_NO)
                                                                FROM SZTUTLX b1
                                                                WHERE     1 = 1
                                                                AND b.SZTUTLX_PIDM = b1.SZTUTLX_PIDM
                                                                --AND b1.SZTUTLX_STAT_IND = b.SZTUTLX_STAT_IND
                                                                )
                           WHERE     1 = 1
                           AND a.sp = (SELECT MAX (a1.sp)
                                        FROM tztprog a1
                                        WHERE a.pidm = a1.pidm)
                           AND a.estatus not IN ('MA', 'TR','AS' ,'EG')
                           AND b.SZTUTLX_DISABLE_IND = 'A'
                           AND SZTUTLX_USER_BLOQUEO IS NULL
                           AND TRUNC (a.fecha_inicio) <= TRUNC (SYSDATE)
                         --  AND a.matricula IN ('010191944')


        ) loop

                Begin
                      Insert into SZTUTLX
                      Select a.SZTUTLX_PIDM, a.SZTUTLX_ID, a.SZTUTLX_TERM_CODE, a.SZTUTLX_CAMP_CODE, a.SZTUTLX_LEVL_CODE, a.SZTUTLX_SEQ_NO+1 SZTUTLX_SEQ_NO,
                             0 SZTUTLX_STAT_IND, null SZTUTLX_OBS, 'I' SZTUTLX_DISABLE_IND, a.SZTUTLX_PWD, a.SZTUTLX_MDL_ID, user SZTUTLX_USER_INSERT,
                             cx.fecha_mov SZTUTLX_ACTIVITY_DATE, null SZTUTLX_USER_UPDATE, null SZTUTLX_DATE_UPDATE, a.SZTUTLX_ROW1, a.SZTUTLX_ROW2, a.SZTUTLX_ROW3,
                             a.SZTUTLX_ROW4, a.SZTUTLX_ROW5 , user SZTUTLX_USER_BLOQUEO,  cx.fecha_mov SZTUTLX_ACTIVITY_BLOQUEO, a.SZTUTLX_GRATIS, a.SZTUTLX_GRATIS_APLI
                            , A.SZTUTLX_FREC_PAGO, A.SZTUTLX_MONTO_DESC,A.SZTUTLX_NUM_DESC, A.SZTUTLX_NUM_DESC_APLIC     
                 from SZTUTLX a
                            Where 1=1
                            And a.SZTUTLX_PIDM = cx.pidm
                            And a.SZTUTLX_SEQ_NO = cx.seq;
                Exception
                When Others then
                    null;
                End;



                begin
                    Delete goradid
                    Where 1= 1
                    And goradid_pidm = cx.pidm
                    And GORADID_ADID_CODE in ('UTLX');
                Exception
                    When Others then
                     null;
                end;

                Commit;

        End loop;



        ------------- Se realizan las cancelaciones de la tabla de COTA --------------------



       Begin

          For cx in (



                         SELECT DISTINCT  a.TZTCOTA_PIDM PIDM,
                          a.TZTCOTA_PROGRAMA Programa,
                          a.TZTCOTA_CODIGO Codigo,
                          a.TZTCOTA_SEQNO Seq,
                          a.TZTCOTA_FLAG Flag,
                         'X' uno,
                         e.estatus,
                         f.SZT_CODE_SERV
                         FROM TZTCOTA A
                         Join TBBDETC on TBBDETC_DETAIL_CODE = A.TZTCOTA_CODIGO
                         Join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                         join SZVCAMP on SZVCAMP_CAMP_CODE = a.TZTCOTA_CAMPUS
                         join tztprog e on e.pidm = a.TZTCOTA_PIDM and e.estatus not in ('MA', 'EG') and e.sp = (select max (e1.sp)
                                                                                                     from tztprog e1
                                                                                                     Where e.pidm = e1.pidm
                                                                                                   )
                         left join ZSTPARA e on e.ZSTPARA_PARAM_VALOR = a.TZTCOTA_ORIGEN and e.ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
                         left join SZTCTSIU f on f.SZT_CODTLE = a.TZTCOTA_CODIGO
                         WHERE 1=1
                         AND A.TZTCOTA_STATUS = 'A'
                         AND A.TZTCOTA_SEQNO = (SELECT MAX(a1.TZTCOTA_SEQNO)
                                                 FROM TZTCOTA a1
                                                 WHERE a1.TZTCOTA_PIDM = A.TZTCOTA_PIDM
                                                 AND a1.TZTCOTA_CODIGO = A.TZTCOTA_CODIGO
                                                 --AND a1.TZTCOTA_STATUS = 'A'
                                                 )
                         And a.TZTCOTA_CARGOS is not null
                         and a.TZTCOTA_MONTO is null
                         union
                         SELECT DISTINCT a.TZTCOTA_PIDM PIDM,
                          a.TZTCOTA_PROGRAMA Programa,
                          a.TZTCOTA_CODIGO Codigo,
                          a.TZTCOTA_SEQNO Seq,
                          a.TZTCOTA_FLAG Flag,
                         'Y' UNO,
                          e.estatus,
                           f.SZT_CODE_SERV
                         FROM TZTCOTA A
                         Join TBBDETC on TBBDETC_DETAIL_CODE = A.TZTCOTA_CODIGO
                         Join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                         join SZVCAMP on SZVCAMP_CAMP_CODE = a.TZTCOTA_CAMPUS
                         join tztprog e on e.pidm = a.TZTCOTA_PIDM and e.estatus not in ('MA', 'EG') and e.sp = (select max (e1.sp)
                                                                                                     from tztprog e1
                                                                                                     Where e.pidm = e1.pidm
                                                                                                   ) left join ZSTPARA e on e.ZSTPARA_PARAM_VALOR = a.TZTCOTA_ORIGEN and e.ZSTPARA_MAPA_ID = 'COD_MESGRATIS'
                         left join SZTCTSIU f on f.SZT_CODTLE = a.TZTCOTA_CODIGO
                         WHERE 1=1
                         AND A.TZTCOTA_STATUS = 'A'
                         AND A.TZTCOTA_SEQNO = (SELECT MAX(a1.TZTCOTA_SEQNO)
                                                 FROM TZTCOTA a1
                                                 WHERE a1.TZTCOTA_PIDM = A.TZTCOTA_PIDM
                                                 AND a1.TZTCOTA_CODIGO = A.TZTCOTA_CODIGO
                                                 )
                         And TZTCOTA_CARGOS is not null
                         and TZTCOTA_MONTO is not null
                         -- And spriden_id ='010308550'
                         order by 3


                ) loop

                    ------------- Elimina la etiqueta del servicio -----------------

                    If cx.SZT_CODE_SERV is not null then

                        Begin
                                Delete goradid
                                where 1= 1
                                And GORADID_PIDM = cx.pidm
                                And  GORADID_ADID_CODE = cx.SZT_CODE_SERV;
                        Exception
                            When Others then
                                null;
                        End;

                        ------------- Inserta el registro para cancelar el servicio en la tabla  ------------------
                        Begin

                            Insert into TZTCOTA
                            Select a.TZTCOTA_PIDM,a.TZTCOTA_TERM_CODE,a.TZTCOTA_CAMPUS,a.TZTCOTA_NIVEL,a.TZTCOTA_PROGRAMA,a.TZTCOTA_CODIGO,a.TZTCOTA_SERVICIO
                            ,a.TZTCOTA_CARGOS,a.TZTCOTA_APLICADOS,a.TZTCOTA_DESCUENTO,a.TZTCOTA_SEQNO +1 TZTCOTA_SEQNO,1,'CAN-MASIVO','CAN-MASIVO'
                            ,'I',a.TZTCOTA_FECHA_INI,SYSDATE,'CAN-MASIVO',a.TZTCOTA_MONTO,a.TZTCOTA_GRATIS,a.GRATIS_APLICADO,a.TZTCOTA_EMAIL,null,null, null,null,null
                            from TZTCOTA a
                            Where 1=1
                            And TZTCOTA_PIDM = cx.pidm
                            And TZTCOTA_PROGRAMA = cx.programa
                            And TZTCOTA_SEQNO = cx.seq;
                        Exception
                            When Others then
                                null;
                        End;
                        Commit;
                    End if;

             End Loop;

       End;




End P_CANCELA_MEMBRESIA_ESTATUS;

FUNCTION F_CANC_ACC_RECU (P_PIDM NUMBER
                            ,P_USUARIO VARCHAR2
                            ,P_ETIQUETA VARCHAR2)
      RETURN VARCHAR2
   IS
      -- Variables del proceso.
      VL_ERROR                VARCHAR2 (1000) := 'EXITO';
      VL_VALIDA_COTA          NUMBER := 0;
      VL_PIDM                 NUMBER := 0;
      VL_ETIQUETA             VARCHAR2 (4) := NULL;
      VL_SECUENCIA            NUMBER := 0;
      VL_PERIODO              VARCHAR2 (6) := NULL;
      VL_COD_DETALLE          VARCHAR2 (4) := NULL;
      VL_NO_SERVICIO          NUMBER := 0;
      VL_APLICADOS            NUMBER := 0;
      VL_VALIDA_PARA          NUMBER := 0;
      VL_VALIDA_EXISTE_TBRA   NUMBER := 0;
      VL_CAN_ACC              VARCHAR2 (10) := 0;
      VL_BALANCE              NUMBER := 0;
      VL_COD_CANCE            VARCHAR2 (4) := 0;
      VL_TRAN                 NUMBER := 0;
      VL_DESCRI_ACC           VARCHAR2 (40) := NULL;
      VL_MONEDA               VARCHAR2 (5) := NULL;
      VL_CARGOS               NUMBER := 0;
      VL_ESTATUS              VARCHAR2 (2) := NULL;
      VL_SALDO                NUMBER := 0;
   BEGIN
      -- Existencia de etiqueta a inactivar -> cancelar
      BEGIN
         SELECT COUNT (1)
           INTO VL_VALIDA_COTA
           FROM TZTCOTA COTA
          WHERE     1 = 1
                AND COTA.TZTCOTA_ORIGEN = P_ETIQUETA
                AND COTA.TZTCOTA_PIDM = P_PIDM
                AND COTA.TZTCOTA_STATUS = 'A'
                AND COTA.TZTCOTA_SEQNO =
                       (SELECT MAX (COTA1.TZTCOTA_SEQNO)
                          FROM TZTCOTA COTA1
                         WHERE     1 = 1
                               AND COTA1.TZTCOTA_ORIGEN = P_ETIQUETA
                               AND COTA1.TZTCOTA_PIDM = P_PIDM
                               AND COTA1.TZTCOTA_STATUS = 'A');
      EXCEPTION
         WHEN OTHERS
         THEN
            VL_ERROR :=
                  '(Exc.) No existe registro en Autoservicio(TZTCOTA) para la matrícula '
               || GB_COMMON.F_GET_ID (P_PIDM)
               || ' con etiqueta '
               || P_ETIQUETA
               || ' activo... Favor de revisar... '
               || CHR (10)
               || 'SQLCODE: '
               || SQLCODE
               || CHR (10)
               || SQLERRM;

            DBMS_OUTPUT.PUT_LINE (VL_ERROR || CHR (10) || CHR (10));
      END;

      -- Si existe etiqueta a inactivar -> cancelar, entonces...
      IF VL_VALIDA_COTA > 0
      THEN
         -- Detalle del accesorio.
         BEGIN
            SELECT COTA.TZTCOTA_PIDM,
                   COTA.TZTCOTA_ORIGEN,
                   COTA.TZTCOTA_SEQNO,
                   COTA.TZTCOTA_TERM_CODE,
                   COTA.TZTCOTA_CODIGO,
                   COTA.TZTCOTA_SERVICIO,
                   COTA.TZTCOTA_CARGOS,
                   COTA.TZTCOTA_APLICADOS,
                   COTA.TZTCOTA_STATUS
              INTO VL_PIDM,
                   VL_ETIQUETA,
                   VL_SECUENCIA,
                   VL_PERIODO,
                   VL_COD_DETALLE,
                   VL_NO_SERVICIO,
                   VL_CARGOS,
                   VL_APLICADOS,
                   VL_ESTATUS
              FROM TZTCOTA COTA
             WHERE     1 = 1
                   AND COTA.TZTCOTA_ORIGEN = P_ETIQUETA
                   AND COTA.TZTCOTA_PIDM = P_PIDM
                   AND COTA.TZTCOTA_STATUS = 'A'
                   AND COTA.TZTCOTA_SEQNO =
                          (SELECT MAX (COTA1.TZTCOTA_SEQNO)
                             FROM TZTCOTA COTA1
                            WHERE     1 = 1
                                  AND COTA1.TZTCOTA_ORIGEN = P_ETIQUETA
                                  AND COTA1.TZTCOTA_PIDM = P_PIDM
                                  AND COTA1.TZTCOTA_STATUS = 'A');
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_ERROR :=
                     '(Exc.) No existe registro en Autoservicio(TZTCOTA) para la matrícula '
                  || GB_COMMON.F_GET_ID (P_PIDM)
                  || ' con etiqueta '
                  || P_ETIQUETA
                  || ' activo para cancelar... Favor de revisar... '
                  || CHR (10)
                  || 'SQLCODE: '
                  || SQLCODE
                  || CHR (10)
                  || SQLERRM;

               DBMS_OUTPUT.PUT_LINE (VL_ERROR || CHR (10) || CHR (10));
         END;

         -- Validación del accesorio como diferido.
         BEGIN
            SELECT COUNT (1)
              INTO VL_VALIDA_PARA
              FROM ZSTPARA PARA
             WHERE     1 = 1
                   AND PARA.ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
                   AND PARA.ZSTPARA_PARAM_VALOR = VL_COD_DETALLE;
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_ERROR :=
                     '(Exc.) El código de detalle '
                  || VL_COD_DETALLE
                  || ' no está clasificado o no se encuentra como accesorio diferido(ZSTPARA -> ACC_DIFERIDO)... Favor de revisar... '
                  || CHR (10)
                  || 'SQLCODE: '
                  || SQLCODE
                  || CHR (10)
                  || SQLERRM;

               DBMS_OUTPUT.PUT_LINE (VL_ERROR || CHR (10) || CHR (10));
         END;

         -- Si el accesorio es diferido, entonces...
         IF VL_VALIDA_PARA > 0
         THEN
            -- Validación de Cod. detalle en el Edo. de Cta.
            BEGIN
               SELECT COUNT (1) TOTAL_EXISTE_COD_TBRA
                 INTO VL_VALIDA_EXISTE_TBRA
                 FROM TBRACCD TBRA
                WHERE     1 = 1
                      AND TBRA.TBRACCD_PIDM = VL_PIDM
                      AND TBRA.TBRACCD_DETAIL_CODE = VL_COD_DETALLE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  VL_ERROR :=
                        '(Exc.) No existen cargos diferidos para el cod. de detalle '
                     || VL_COD_DETALLE
                     || ' en el Edo. de Cta. del matriculado '
                     || GB_COMMON.F_GET_ID (P_PIDM)
                     || '... Favor de revisar... '
                     || CHR (10)
                     || 'SQLCODE: '
                     || SQLCODE
                     || CHR (10)
                     || SQLERRM;
            END;

            -- Si existe el cod. de detalle en el Edo. de Cta., entonces...
            IF VL_VALIDA_EXISTE_TBRA > 0 THEN
               -- Cursor
               FOR CAN IN (SELECT TBRA.TBRACCD_PIDM,
                             TBRA.TBRACCD_TRAN_NUMBER,
                             TBRA.TBRACCD_DESC,
                             TBRA.TBRACCD_DETAIL_CODE,
                             TBRA.TBRACCD_AMOUNT,
                             TBRA.TBRACCD_TERM_CODE,
                             TBRA.TBRACCD_PERIOD,
                             TBRA.TBRACCD_EFFECTIVE_DATE,
                             TBRA.TBRACCD_TRANS_DATE,
                             TBRA.TBRACCD_STSP_KEY_SEQUENCE,
                             TBRA.TBRACCD_FEED_DATE,
                             TBRA.TBRACCD_RECEIPT_NUMBER,
                             DETC.TBBDETC_TYPE_IND,
                             SPRI.SPRIDEN_ID
                        FROM TBRACCD TBRA
                             JOIN TBBDETC DETC
                                ON DETC.TBBDETC_DETAIL_CODE =
                                      TBRA.TBRACCD_DETAIL_CODE
                             JOIN SPRIDEN SPRI
                                ON     SPRI.SPRIDEN_PIDM = TBRA.TBRACCD_PIDM
                                   AND SPRI.SPRIDEN_CHANGE_IND IS NULL
                       WHERE     1 = 1
                             AND TBRA.TBRACCD_PIDM = VL_PIDM
                             AND TBRA.TBRACCD_DETAIL_CODE = VL_COD_DETALLE
                             AND SUBSTR (TBRA.TBRACCD_FEED_DOC_CODE, 1, 1) =
                                    VL_APLICADOS
                             --AND TBRA.TBRACCD_BALANCE <= 0
                             AND TBRA.TBRACCD_EFFECTIVE_DATE =
                                    (SELECT MAX (
                                               TBRA1.TBRACCD_EFFECTIVE_DATE)
                                       FROM TBRACCD TBRA1
                                      WHERE     1 = 1
                                            AND TBRA1.TBRACCD_PIDM = P_PIDM
                                            AND TBRA1.TBRACCD_DETAIL_CODE =
                                                   VL_COD_DETALLE
                                            AND SUBSTR (
                                                   TBRA1.TBRACCD_FEED_DOC_CODE,
                                                   1,
                                                   1) = VL_APLICADOS-- AND TBRA1.TBRACCD_BALANCE <= 0
                                    )--                             AND TBRA1.TBRACCD_BALANCE <= 0
               )LOOP
--------------------------------------------------------------------------------

                    IF CAN.TBRACCD_TRANS_DATE >= SYSDATE THEN

--------------------------------------------------------------------------------
                                            BEGIN
                                                SELECT SUM(TBRACCD_BALANCE)
                                                  INTO VL_SALDO
                                                  FROM TBRACCD
                                                 WHERE 1 = 1
                                                   AND TBRACCD_PIDM = CAN.TBRACCD_PIDM
                                                   AND TBRACCD_DETAIL_CODE = CAN.TBRACCD_DETAIL_CODE
                                                   AND TBRACCD_EFFECTIVE_DATE > SYSDATE;
                                            END;

                                            IF VL_SALDO != 0 THEN


                        --------------------------------------------------------------------------------
                                                          IF CAN.TBBDETC_TYPE_IND = 'C'
                                                          THEN
                                                             VL_BALANCE := CAN.TBRACCD_AMOUNT * -1;
                                                             VL_COD_CANCE := SUBSTR (CAN.SPRIDEN_ID, 1, 2) || 'WM';
                                                             VL_TRAN := CAN.TBRACCD_TRAN_NUMBER;
                                                          ELSIF CAN.TBBDETC_TYPE_IND = 'P'
                                                          THEN
                                                             VL_BALANCE := CAN.TBRACCD_AMOUNT;
                                                             VL_COD_CANCE := SUBSTR (CAN.SPRIDEN_ID, 1, 2) || 'BU';
                                                             VL_TRAN := CAN.TBRACCD_TRAN_NUMBER;
                                                          END IF;

                                                          IF CAN.TBBDETC_TYPE_IND = 'P'
                                                          THEN
                                                             PKG_FINANZAS.P_DESAPLICA_PAGOS (CAN.TBRACCD_PIDM,
                                                                                             CAN.TBRACCD_TRAN_NUMBER);
                                                          END IF;

                                                          BEGIN
                                                             SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                                                               INTO VL_SECUENCIA
                                                               FROM TBRACCD
                                                              WHERE 1 = 1 AND TBRACCD_PIDM = CAN.TBRACCD_PIDM;
                                                          EXCEPTION
                                                             WHEN OTHERS
                                                             THEN
                                                                VL_SECUENCIA := 0;
                                                          END;

                                                          BEGIN
                                                             SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                                                               INTO VL_DESCRI_ACC, VL_MONEDA
                                                               FROM TBBDETC, TVRDCTX
                                                              WHERE     1 = 1
                                                                    AND TBBDETC_DETAIL_CODE = VL_COD_CANCE
                                                                    AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE;
                                                          EXCEPTION
                                                             WHEN OTHERS
                                                             THEN
                                                                VL_DESCRI_ACC := NULL;
                                                          END;

                                                          BEGIN
                                                             INSERT INTO TBRACCD
                                                                  VALUES (CAN.TBRACCD_PIDM,            -- TBRACCD_PIDM
                                                                          VL_SECUENCIA,         -- TBRACCD_TRAN_NUMBER
                                                                          CAN.TBRACCD_TERM_CODE,  -- TBRACCD_TERM_CODE
                                                                          VL_COD_CANCE,         -- TBRACCD_DETAIL_CODE
                                                                          USER,                        -- TBRACCD_USER
                                                                          SYSDATE,               -- TBRACCD_ENTRY_DATE
                                                                          NVL (CAN.TBRACCD_AMOUNT, 0), -- TBRACCD_AMOUNT
                                                                          NVL (VL_BALANCE, 0),      -- TBRACCD_BALANCE
                                                                          SYSDATE,           -- TBRACCD_EFFECTIVE_DATE
                                                                          NULL,                   -- TBRACCD_BILL_DATE
                                                                          NULL, -- TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                                                          VL_DESCRI_ACC,               -- TBRACCD_DESC
                                                                          CAN.TBRACCD_RECEIPT_NUMBER, -- TBRACCD_RECEIPT_NUMBER
                                                                          VL_TRAN,         -- TBRACCD_TRAN_NUMBER_PAID
                                                                          NULL,               -- TBRACCD_CROSSREF_PIDM
                                                                          NULL,             -- TBRACCD_CROSSREF_NUMBER
                                                                          NULL,        -- TBRACCD_CROSSREF_DETAIL_CODE
                                                                          'T',                    -- TBRACCD_SRCE_CODE
                                                                          'Y',                -- TBRACCD_ACCT_FEED_IND
                                                                          SYSDATE,            -- TBRACCD_ACTIVITY_DATE
                                                                          0,                 -- TBRACCD_SESSION_NUMBER
                                                                          NULL,               -- TBRACCD_CSHR_END_DATE
                                                                          NULL,                         -- TBRACCD_CRN
                                                                          NULL,          -- TBRACCD_CROSSREF_SRCE_CODE
                                                                          NULL,                     -- TBRACCD_LOC_MDT
                                                                          NULL,                 -- TBRACCD_LOC_MDT_SEQ
                                                                          NULL,                        -- TBRACCD_RATE
                                                                          NULL,                       -- TBRACCD_UNITS
                                                                          NULL,             -- TBRACCD_DOCUMENT_NUMBER
                                                                          SYSDATE,               -- TBRACCD_TRANS_DATE
                                                                          NULL,                  -- TBRACCD_PAYMENT_ID
                                                                          NULL,              -- TBRACCD_INVOICE_NUMBER
                                                                          NULL,              -- TBRACCD_STATEMENT_DATE
                                                                          NULL,             -- TBRACCD_INV_NUMBER_PAID
                                                                          VL_MONEDA,              -- TBRACCD_CURR_CODE
                                                                          NULL,               -- TBRACCD_EXCHANGE_DIFF
                                                                          NULL, -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                                                          NULL,              -- TBRACCD_LATE_DCAT_CODE
                                                                          CAN.TBRACCD_FEED_DATE,  -- TBRACCD_FEED_DATE
                                                                          NULL,               -- TBRACCD_FEED_DOC_CODE
                                                                          NULL,                   -- TBRACCD_ATYP_CODE
                                                                          NULL,                  -- TBRACCD_ATYP_SEQNO
                                                                          NULL,                -- TBRACCD_CARD_TYPE_VR
                                                                          NULL,            -- TBRACCD_CARD_EXP_DATE_VR
                                                                          NULL,         -- TBRACCD_CARD_AUTH_NUMBER_VR
                                                                          NULL,          -- TBRACCD_CROSSREF_DCAT_CODE
                                                                          NULL,                -- TBRACCD_ORIG_CHG_IND
                                                                          NULL,                   -- TBRACCD_CCRD_CODE
                                                                          NULL,                 -- TBRACCD_MERCHANT_ID
                                                                          NULL,               -- TBRACCD_TAX_REPT_YEAR
                                                                          NULL,                -- TBRACCD_TAX_REPT_BOX
                                                                          NULL,                  -- TBRACCD_TAX_AMOUNT
                                                                          NULL,              -- TBRACCD_TAX_FUTURE_IND
                                                                          'WCANCE',             -- TBRACCD_DATA_ORIGIN
                                                                          'WCANCE',           -- TBRACCD_CREATE_SOURCE
                                                                          NULL,                    -- TBRACCD_CPDT_IND
                                                                          NULL,                   -- TBRACCD_AIDY_CODE
                                                                          CAN.TBRACCD_STSP_KEY_SEQUENCE, -- TBRACCD_STSP_KEY_SEQUENCE
                                                                          CAN.TBRACCD_PERIOD,        -- TBRACCD_PERIOD
                                                                          NULL,                -- TBRACCD_SURROGATE_ID
                                                                          NULL,                     -- TBRACCD_VERSION
                                                                          USER,                     -- TBRACCD_USER_ID
                                                                          NULL);                  -- TBRACCD_VPDI_CODE
                                                          EXCEPTION
                                                             WHEN OTHERS
                                                             THEN
                                                                VL_ERROR :=
                                                                   'Se presento ERROR INSERT TBRACCD ' || SQLERRM;
                                                          END;

                                                          BEGIN
                                                             UPDATE TBRACCD
                                                                SET TBRACCD_DOCUMENT_NUMBER = 'WCANCE',
                                                                    TBRACCD_TRAN_NUMBER_PAID = NULL
                                                              WHERE     1 = 1
                                                                    AND TBRACCD_PIDM = CAN.TBRACCD_PIDM
                                                                    AND TBRACCD_TRAN_NUMBER = CAN.TBRACCD_TRAN_NUMBER;

                                                             UPDATE TVRACCD
                                                                SET TVRACCD_DOCUMENT_NUMBER = 'WCANCE',
                                                                    TVRACCD_TRAN_NUMBER_PAID = NULL
                                                              WHERE     1 = 1
                                                                    AND TVRACCD_PIDM = CAN.TBRACCD_PIDM
                                                                    AND TVRACCD_ACCD_TRAN_NUMBER =
                                                                           CAN.TBRACCD_TRAN_NUMBER;
                                                          END;
                                            END IF;
                    END IF;

               END LOOP;

            END IF;

         END IF;

      END IF;

      RETURN (VL_ERROR);
   END F_CANC_ACC_RECU;

END PKG_FINANZAS_UTLX;
/

DROP PUBLIC SYNONYM PKG_FINANZAS_UTLX;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FINANZAS_UTLX FOR BANINST1.PKG_FINANZAS_UTLX;


GRANT EXECUTE ON BANINST1.PKG_FINANZAS_UTLX TO SATURN;
