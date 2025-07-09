DROP PACKAGE BODY BANINST1.PKG_FINANZAS_BOOTCAMP;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_FINANZAS_BOOTCAMP" AS
/******************************************************************************
   NAME:       PKG_FINANZAS_BOOTCAMP
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        28/10/2020      jrezaoli       1. Created this package body.
******************************************************************************/

-- Nueva versión del proceso de CANCELACION de BOOTCAMP (Job que se debe ejecutar todos los días)
PROCEDURE P_CANCELA_BOOT_2023 IS
-- DESCRIPCION: Cancela los registros que no se pago el primer pago en el tiempo establecido (20 DÃas de Tolerancia - Tabla de Parametros)
-- AUTOR......: Omar L. Meza Sol
-- VERSION....: Version 2.0
-- FECHA......: 23-Septiembre-2023

-- Cursor para recorrer el universo de candidatos a CANCELAR
   CURSOR c_Principal IS
          SELECT DISTINCT tztboot_Id Matricula, tbraccd_pidm Pidm, Tbraccd_feed_date Fecha_Inicio, tztboot_start_date,
                          tbraccd_amount, tbraccd_balance, tbraccd_document_number, tbraccd_effective_date, NVL (c.zstPara_Param_Valor,0) No_Dias,
                          TRUNC (tbraccd_effective_date + NVL (c.zstPara_Param_Valor,0)) Limite, tbraccd_receipt_number, 
                          tztboot_program Programa, b.tbraccd_detail_code Codigo
            FROM tztboot a, tbraccd b, zstPara c
           WHERE a.tztboot_status          = 'GENERADA'         -- != 'CANCELADO'
-- and tztboot_id = '400583443'
             AND SUBSTR (a.tztboot_Id,1,2) = '40'               -- Solo Matricula del Campus 40 (UCamp)
             AND c.zstPara_Mapa_Id   = 'BOOT_VIG_PAGO'
             AND b.tbraccd_pidm      = a.tztboot_pidm
             AND b.tbraccd_feed_date = a.tztboot_start_date
             AND b.tbraccd_term_code LIKE '40%'
             AND SUBSTR (b.tbraccd_detail_code,3,2) = SUBSTR (tztboot_program,LENGTH (tztboot_program)-1,2)
             AND b.tbraccd_detail_code IN (SELECT tbbdetc_detail_code
                                             FROM TBBDETC
                                            WHERE TBBDETC_DCAT_CODE = 'COL'
                                              AND SUBSTR (TBBDETC_DETAIL_CODE,1,2) = SUBSTR (b.tbraccd_detail_code, 1, 2) -- ||'N'
                                          --  AND SUBSTR (TBBDETC_DETAIL_CODE,1,3) = SUBSTR (b.tbraccd_detail_code, 1, 2)    ||'N' -- Version Anterior
                                              AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                          )
             AND (tbraccd_receipt_number, b.tbraccd_tran_number) IN  (SELECT tbraccd_receipt_number, MIN (f.tbraccd_tran_number)
                                             FROM tbraccd f
                                            WHERE f.tbraccd_pidm      = b.tbraccd_pidm
                                              AND f.tbraccd_feed_date = b.tbraccd_feed_date
                                            GROUP BY tbraccd_receipt_number
                                          )             
             AND tbraccd_document_number like '%de%'
             AND NVL   (tbraccd_amount, 0)   + NVL (tbraccd_balance,0) != 0
             AND NVL   (tbraccd_balance,0)  > 0    -- != 0  -- >= 0 (Se intento hacer el UPDATE PAGADO)
             AND NVL   (tbraccd_amount, 0)   = NVL (tbraccd_balance,0)          -- 23/Oct/2023 (Solo IMPORTE TOTAL)
             AND TRUNC (tbraccd_feed_date)   = TRUNC (tztboot_start_date)
             AND TRUNC (tztboot_start_date) <= TRUNC (sysdate)
             AND TRUNC (tbraccd_effective_date + NVL (c.zstPara_Param_Valor,0)) <= TRUNC (sysdate)
          -- OMS 05/Oct/2023 --> Se incluyen los registros que quedan en el Limbo (Status = 'ACTIVO')
           UNION ALL
          SELECT DISTINCT tztboot_Id Matricula, tztboot_pidm Pidm, tztboot_start_date Fecha_Inicio, tztboot_start_date,
                          1 tbraccd_amount, 1 tbraccd_balance, '1 de 1' tbraccd_document_number, 
                          tztboot_start_date tbraccd_effective_date, NVL (c.zstPara_Param_Valor,0) No_Dias,
                          TRUNC (tztboot_start_date + NVL (c.zstPara_Param_Valor,0)) Limite,
                          NULL tbraccd_receipt_number, tztboot_program Programa, NULL Codigo
            FROM tztboot a, zstPara c
           WHERE 1 = 1
--           AND a.tztboot_pidm      = 551923
             AND a.tztboot_status    = 'ACTIVO'
             AND SUBSTR (a.tztboot_Id,1,2) = '40'                 -- Solo Matricula del Campus 40 (UCamp)
             AND c.zstPara_Mapa_Id   = 'BOOT_VIG_PAGO'
             AND TRUNC (tztboot_start_date) <= TRUNC (sysdate)
             AND TRUNC (tztboot_start_date + NVL (c.zstPara_Param_Valor,0)) <= TRUNC (sysdate);


   CURSOR c_Parcialidades (p_pidm NUMBER, p_Fecha_Inicio DATE, p_Recibo NUMBER, p_programa VARCHAR2) IS
          SELECT TBRACCD_PIDM,      TBRACCD_TRAN_NUMBER,       TBRACCD_TERM_CODE,     TBRACCD_DETAIL_CODE,    TBRACCD_AMOUNT,
                 TBRACCD_BALANCE,   TBRACCD_DESC,              TBRACCD_USER,          TBRACCD_ENTRY_DATE,     TBRACCD_EFFECTIVE_DATE,
                 TBRACCD_SRCE_CODE, TBRACCD_ACCT_FEED_IND,     TBRACCD_ACTIVITY_DATE, TBRACCD_SESSION_NUMBER, TBRACCD_SURROGATE_ID,
                 TBRACCD_VERSION,   TBRACCD_STSP_KEY_SEQUENCE, TBRACCD_PERIOD,        TBRACCD_FEED_DATE,      TBRACCD_RECEIPT_NUMBER,
                 TBRACCD_CURR_CODE
            FROM TBRACCD A
           WHERE A.TBRACCD_PIDM           = p_pidm
             AND A.TBRACCD_FEED_DATE      = p_Fecha_Inicio
             AND A.tbraccd_receipt_number = p_Recibo                           -- OMS 10/Octubre/2023
             AND SUBSTR (A.tbraccd_detail_code,3,2) = SUBSTR (p_programa, LENGTH (p_programa)-1,2)
             AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                             FROM TBBDETC
                                            WHERE TBBDETC_DCAT_CODE = 'COL'
                                              AND SUBSTR (TBBDETC_DETAIL_CODE,1,2) = SUBSTR (A.TBRACCD_DETAIL_CODE, 1, 2) -- || 'N'
                                            --AND SUBSTR (TBBDETC_DETAIL_CODE,1,3) = SUBSTR (A.TBRACCD_DETAIL_CODE, 1, 2)    || 'N'
                                              AND TBBDETC_DETC_ACTIVE_IND = 'Y')
          -- AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
               ;


-- Variables
   Vm_PAGO          NUMBER := 0;          -- Numero de Pagos CSH
   Vm_Indice        NUMBER := 1;          -- Cuenta el numero de registros que se estan procesando
   Vm_Tran_Max      NUMBER := 0;	      -- Numero de Transaccion
   Vm_Vigencia_COL  DATE   := Sysdate;    -- Fecha de Vigencia
   Vm_Parcialidades NUMBER := 0;          -- Contador de numero de parcialidades


BEGIN
  -- Recorre el universo de candidatos a CANCELAR el BOOTCAMP
  FOR i_Alumno_BOOT IN c_Principal LOOP

      DBMS_OUTPUT.PUT_LINE (CHR (10) || 'Procesando Registro: ' || Vm_Indice);

      -- Verifica que los pagos sean en CASH
      BEGIN
         /* Version Anterior: Localiza Pagos Realizados
         SELECT COUNT(*)
           INTO Vm_PAGO
           FROM TBRACCD,TBBDETC
          WHERE TBRACCD_DETAIL_CODE    = TBBDETC_DETAIL_CODE
            AND TBBDETC_DCAT_CODE      = 'CSH'
            AND TBRACCD_PIDM           = i_Alumno_BOOT.PIDM
            AND TBRACCD_FEED_DATE      = i_Alumno_BOOT.Fecha_Inicio                  -- OMS 05/Oct/2023 (Incluye la fecha de Inicio)
            AND TBRACCD_RECEIPT_NUMBER = i_Alumno_BOOT.tbraccd_receipt_number       -- OMS 10/Octubre/2023 (Diferenciar el RECIBO = StudyPath)     
            AND SUBSTR (tbraccd_detail_code,3,2) = SUBSTR (i_Alumno_BOOT.Programa,LENGTH (i_Alumno_BOOT.Programa)-1,2);
         */

         SELECT COUNT(*)
           INTO Vm_PAGO
           FROM TBRACCD A
          WHERE 1 = 1
            AND TBRACCD_PIDM           = i_Alumno_BOOT.PIDM
            AND TBRACCD_FEED_DATE      = i_Alumno_BOOT.Fecha_Inicio                 -- OMS 05/Oct/2023 (Incluye la fecha de Inicio)
            AND TBRACCD_RECEIPT_NUMBER = i_Alumno_BOOT.tbraccd_receipt_number       -- OMS 10/Octubre/2023 (Diferenciar el RECIBO = StudyPath)     
            AND SUBSTR (tbraccd_detail_code,3,2) = SUBSTR (i_Alumno_BOOT.Programa,LENGTH (i_Alumno_BOOT.Programa)-1,2)
     --     AND TBRACCD_BALANCE >= 0 AND TBRACCD_BALANCE < TBRACCD_AMOUNT           -- Se intento hacer el UPDATE
            AND TBRACCD_BALANCE  = 0            
            AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                             FROM TBBDETC
                                            WHERE TBBDETC_DCAT_CODE = 'COL'
                                              AND SUBSTR (TBBDETC_DETAIL_CODE,1,2) = SUBSTR (A.TBRACCD_DETAIL_CODE, 1, 2) -- || 'N'
                                            --AND SUBSTR (TBBDETC_DETAIL_CODE,1,3) = SUBSTR (A.TBRACCD_DETAIL_CODE, 1, 2)    || 'N'
                                              AND TBBDETC_DETC_ACTIVE_IND = 'Y');


      EXCEPTION WHEN OTHERS THEN Vm_PAGO := 0;
      END;

      IF Vm_Pago = 0 THEN

         DBMS_OUTPUT.PUT_LINE ('Matricula: ' || i_Alumno_BOOT.Matricula || ' / ' || i_Alumno_BOOT.pidm);

         -- Checa las Parcialidades
         Vm_Parcialidades := 1;
         FOR i_Parcialidades IN c_Parcialidades (i_Alumno_BOOT.pidm, i_Alumno_BOOT.Fecha_Inicio, i_Alumno_BOOT.tbraccd_receipt_number,
                                                 i_Alumno_BOOT.Programa) LOOP

             -- Actualiza la cartera
             BEGIN
                UPDATE TBRACCD
                   SET TBRACCD_TRAN_NUMBER_PAID = NULL
                 WHERE TBRACCD_PIDM             = i_Parcialidades.TBRACCD_PIDM
                   AND TBRACCD_TRAN_NUMBER_PAID = i_Parcialidades.TBRACCD_TRAN_NUMBER
                   AND TBRACCD_FEED_DATE        = i_Alumno_BOOT.Fecha_Inicio                     -- OMS 05/Oct/2023 (Incluye la fecha de Inicio)
                   AND TBRACCD_RECEIPT_NUMBER   = i_Alumno_BOOT.tbraccd_receipt_number           -- OMS 10/Octubre/2023 (Recibo = StudyPath)
                   AND SUBSTR (tbraccd_detail_code,3,2) = SUBSTR (i_Alumno_BOOT.Programa,LENGTH (i_Alumno_BOOT.Programa)-1,2);
             END;

             -- Obtiene el numero mÃ¡ximo de transacciones
             BEGIN
                SELECT MAX(TBRACCD_TRAN_NUMBER)+1
                  INTO Vm_Tran_Max
                  FROM TBRACCD
                 WHERE TBRACCD_PIDM = i_Parcialidades.TBRACCD_PIDM ;

             EXCEPTION WHEN OTHERS THEN Vm_Tran_Max := 1;
             END;

             -- Des-Aplica los pagos realizados
             PKG_FINANZAS.P_DESAPLICA_PAGOS (i_Parcialidades.TBRACCD_PIDM, i_Parcialidades.TBRACCD_TRAN_NUMBER);


             -- Re-asigna la fecha de vigencia
             IF i_Parcialidades.TBRACCD_EFFECTIVE_DATE <= TRUNC(SYSDATE) 
                THEN Vm_Vigencia_COL := TRUNC(SYSDATE);
                ELSE Vm_Vigencia_COL := i_Parcialidades.TBRACCD_EFFECTIVE_DATE;
             END IF;


             -- Inserta la cancelaciÃ³n de la cartera
             BEGIN
                INSERT INTO TBRACCD (TBRACCD_PIDM,
                                     TBRACCD_TRAN_NUMBER,
                                     TBRACCD_TERM_CODE,
                                     TBRACCD_DETAIL_CODE,
                                     TBRACCD_AMOUNT,
                                     TBRACCD_BALANCE,
                                     TBRACCD_DESC,
                                     TBRACCD_USER,
                                     TBRACCD_ENTRY_DATE,
                                     TBRACCD_EFFECTIVE_DATE,
                                     TBRACCD_TRANS_DATE,
                                     TBRACCD_SRCE_CODE,
                                     TBRACCD_ACCT_FEED_IND,
                                     TBRACCD_ACTIVITY_DATE,
                                     TBRACCD_SESSION_NUMBER,
                                     TBRACCD_SURROGATE_ID,
                                     TBRACCD_VERSION,
                                     TBRACCD_TRAN_NUMBER_PAID,
                                     TBRACCD_FEED_DATE,
                                     TBRACCD_STSP_KEY_SEQUENCE,
                                     TBRACCD_DATA_ORIGIN,
                                     TBRACCD_PERIOD,
                                     TBRACCD_RECEIPT_NUMBER,
                                     TBRACCD_CREATE_SOURCE,
                                     TBRACCD_USER_ID,
                                     TBRACCD_CURR_CODE)
                             VALUES (i_Parcialidades.TBRACCD_PIDM,
                                     Vm_Tran_Max,
                                     i_Parcialidades.TBRACCD_TERM_CODE ,
                                     SUBSTR(i_Parcialidades.TBRACCD_TERM_CODE,1,2)||'TL',
                                     i_Parcialidades.TBRACCD_AMOUNT,
                                     i_Parcialidades.TBRACCD_AMOUNT*-1 ,
                                     'CANCELACION PLAN BOOTCAMP VPN',
                                     USER,
                                     SYSDATE,
                                     Vm_Vigencia_COL,
                                     Vm_Vigencia_COL,
                                     i_Parcialidades.TBRACCD_SRCE_CODE,
                                     i_Parcialidades.TBRACCD_ACCT_FEED_IND,
                                     i_Parcialidades.TBRACCD_ACTIVITY_DATE,
                                     0,
                                     NULL,
                                     NULL,
                                     i_Parcialidades.TBRACCD_TRAN_NUMBER,
                                     i_Parcialidades.TBRACCD_FEED_DATE,
                                     i_Parcialidades.TBRACCD_STSP_KEY_SEQUENCE,
                                     'CAN_BOOT',
                                     i_Parcialidades.TBRACCD_PERIOD,
                                     i_Parcialidades.TBRACCD_RECEIPT_NUMBER,
                                     'CAN_BOOT',
                                     USER,
                                     i_Parcialidades.TBRACCD_Curr_Code);

             END; -- begin del insert

             -- Actualiza la cartera
             BEGIN
                UPDATE TBRACCD
                   SET TBRACCD_DOCUMENT_NUMBER = 'CAN_BOOT',
                       TBRACCD_ACTIVITY_DATE   =  SYSDATE
                 WHERE TBRACCD_PIDM            =  i_Parcialidades.TBRACCD_PIDM
                   AND TBRACCD_TRAN_NUMBER    IN (i_Parcialidades.TBRACCD_TRAN_NUMBER, Vm_Tran_Max)
                   AND TBRACCD_RECEIPT_NUMBER  =  i_Alumno_BOOT.tbraccd_receipt_number       -- OMS 10/Octubre/2023 (Recibo=StudyPpath)
                   AND SUBSTR (tbraccd_detail_code,3,2) = SUBSTR (i_Alumno_BOOT.Programa,LENGTH (i_Alumno_BOOT.Programa)-1,2);
             END;

             Vm_Parcialidades := Vm_Parcialidades + 1;
         END LOOP;  -- ciclo de parcialidades

         DBMS_OUTPUT.PUT_LINE ('Parcialidades: ' || Vm_Parcialidades);

         -- Cancela el BOOTCAMP
         BEGIN
            UPDATE TZTBOOT
               SET TZTBOOT_STATUS          = 'CANCELADO',
                   TZTBOOT_ACTIVITY_UPDATE = sysdate
             WHERE TZTBOOT_PIDM       = i_Alumno_BOOT.PIDM
               AND TZTBOOT_START_DATE = i_Alumno_BOOT.FECHA_INICIO
               AND TZTBOOT_PROGRAM    = i_Alumno_BOOT.Programa;                 -- OMS 10/Octubre/2023 (Solo para el Programa)
         END;

         -- Cuenta el numero de registros que se estan procesando
         Vm_Indice := Vm_Indice + 1;      

      ELSE
        -- OMS 05/Oct/2023 (Incluye la fecha de Inicio)
         DBMS_OUTPUT.PUT_LINE ('Se detectaron ' || Vm_Pago || ' pago(s) para la matricula: ' || i_Alumno_BOOT.Matricula);
         NULL;

         -- Cambia el status a PAGADO
         BEGIN
            UPDATE TZTBOOT
               SET TZTBOOT_STATUS          = 'PAGADO',
                   TZTBOOT_ACTIVITY_UPDATE = sysdate
             WHERE TZTBOOT_PIDM       = i_Alumno_BOOT.PIDM
               AND TZTBOOT_START_DATE = i_Alumno_BOOT.FECHA_INICIO
               AND TZTBOOT_PROGRAM    = i_Alumno_BOOT.Programa;                 -- OMS 10/Octubre/2023 (Solo para el Programa)
         END;

      END IF;	-- if Vm_Pago

  END LOOP;	-- Ciclo Principal


  -- Graba los cambios
  COMMIT;
END P_CANCELA_BOOT_2023;




-- OMS 09/Agosto/2023 
-- Se agrega la funcionalidad de pagos escalonados; en la función: F_CART_BOOTCAMP_v2 para alumnos de UCamp
-- Start:

FUNCTION F_CART_BOOTCAMP_v2 (P_PIDM  NUMBER,
                             P_FECHA DATE,
                             P_ALUMNO VARCHAR2,
                             P_DETAIL_CODE VARCHAR2 )RETURN VARCHAR2 IS


VL_DIA                  NUMBER;
VL_MES                  NUMBER;
VL_ANO                  NUMBER;
VL_CODIGO_PAR           VARCHAR2(4);
VL_MONTO_COL            NUMBER;
VL_VENCIMIENTO          DATE;
VL_DESCRIPCION_PAR      VARCHAR2(40);
VL_ORDEN                NUMBER;
VL_SECUENCIA            NUMBER;
VL_ERROR                VARCHAR2(500):= 'Error al generar cartera';
VL_CODIGO               VARCHAR2(5);
VL_DESCRIPCION          VARCHAR2(50);
VL_MONTO                NUMBER;
VL_SFRRGFE_RATE_CODE    VARCHAR2(5);
VL_CODIGO_DESC          VARCHAR2(5);
VL_DESCRIPCION_DESC     VARCHAR2(50);
VL_MONTO_PERCENT        NUMBER;
VL_MONTO_AMOUNT         NUMBER;
VL_DESCUENTODSI         NUMBER;
VL_CODIGO_DSI           VARCHAR2(5);
VL_DESCRIPCION_DSI      VARCHAR2(50);
VL_CODIGO_PLP           VARCHAR2(5);
VL_DESCRIPCION_PLP      VARCHAR2(50);
VL_PLAN_PAGO            NUMBER;
VL_ULT_COL              NUMBER;
VL_DESCUENTO            NUMBER;
VL_SECUENCIACOL         NUMBER;
VL_DIFE                 NUMBER;
VL_NUMERO               NUMBER;
VL_PRIMER_FECHA         DATE;
VL_FLAG_PAGO            NUMBER;
VL_cargos               NUMBER;
Vm_Fecha_Vigencia       DATE;                   -- OMS 23/Sep/2023 (Fecha del Primer Pago)
Vm_Status_BootCamp      VARCHAR2 (10) := NULL;  -- OMS 23/Sep/2023 (GENERADA o PAGADO)

-- Variables PAGOS Escalonados		--> OMS 09/Agosto/2023
VL_Escalonados	    	NUMBER :=  0;
VL_Numero_Cargos 	    NUMBER :=  0;
VL_Cad_Inicio           NUMBER := 13;	--> Inicio de los MONTOS en el campo Observaciones, contiene la leyenda 'ESCALONADO: ' (Posición 13)
VL_Cad_Fin              NUMBER :=  0;
-- Variables PAGOS Escalonados		--> OMS 09/Agosto/2023

 BEGIN

   IF P_ALUMNO = 'BOOTCAMP' THEN

   -- DBMS_OUTPUT.PUT_LINE ('Entra a procesar BOOTCAMP...');

     BEGIN

         FOR ALUMNO IN (

                      SELECT TZTBOOT_CAMP_CODE CAMPUS,
                             TZTBOOT_LEVL_CODE NIVEL,
                             TZTBOOT_PIDM PIDM,
                             TZTBOOT_ID MATRICULA,
                             TZTBOOT_PROGRAM PROGRAMA,
                             TZTBOOT_TERM_CODE PERIODO,
                             TZTBOOT_START_DATE  FECHA_INICIO,
                             TZTBOOT_CURR_CODE DIVISA,
                             NVL(TZTBOOT_DESCUENTO,0) DESCUENTO,
                             TZTBOOT_AMOUNT MONTO,
                             TZTBOOT_NUM_TRAN TRANSA,
                             TZTBOOT_NUM_PAG PAGOS,
                             TZTBOOT_RATE_CODE RATE,
                             TZTBOOT_ATTS_CODE JORNADA,
                             TZTBOOT_DATA_ORIGIN ORIGEN,
                             TZTBOOT_STATUS ESTATUS,
                             TZTBOOT_ORDEN ORDEN,
                             TZTBOOT_NUM_PAG FLAG_PAGO,
                             SORLCUR_KEY_SEQNO STUDY_PATH,
                             DECODE (A.SORLCUR_DEGC_CODE, 'DIPL', 'COLEGIATURA DIPLOMADO', 'CURS', 'COLEGIATURA CURSO')DEGC_CODE,
                             (SELECT DISTINCT SORLCUR_SITE_CODE
                                FROM SORLCUR CUR
                               WHERE    CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                    AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                    AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                             FROM SORLCUR CUR2
                                                             WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                             AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO,
                             TZTBOOT_OBSERVACIONES OBSERVACIONES,
                             TZTBOOT_CUPON_DESC, 
                             TZTBOOT_CUPON, 
                             TZTBOOT_CODIGO                             
                        FROM    TZTBOOT LEFT JOIN
                                SORLCUR A
                             ON     TZTBOOT_PIDM = A.SORLCUR_PIDM
                                AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                                AND A.SORLCUR_ROLL_IND = 'Y'
                                AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                                AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                          FROM SORLCUR A1
                                                         WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                               AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND
                                                               AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                                               AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                               AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
                           WHERE TZTBOOT_PIDM = P_PIDM
                             AND TRUNC(TZTBOOT_START_DATE) = TRUNC (P_FECHA)    -- OMS 09/Agostp/2023 (TRUNC)
                          -- AND TZTBOOT_STATUS = 'ACTIVO'                      -- OMS 23/Sep/2023
                             AND (  TZTBOOT_STATUS = 'ACTIVO' OR
                                   (TZTBOOT_STATUS = 'PAGADO' AND TZTBOOT_CUPON      = 100) OR
                                   (TZTBOOT_STATUS = 'PAGADO' AND TZTBOOT_PRI_AMOUNT = 0)           -- 27/OCT/2023
                                   )

       )LOOP

          VL_DIA                  :=NULL;
          VL_MES                  :=NULL;
          VL_ANO                  :=NULL;
          VL_CODIGO_PAR           :=NULL;
          VL_MONTO_COL            :=NULL;
          VL_VENCIMIENTO          :=NULL;
          VL_DESCRIPCION_PAR      :=NULL;
          VL_ORDEN                :=NULL;
          VL_SECUENCIA            :=NULL;
          VL_ERROR                :=NULL;
          VL_CODIGO               :=NULL;
          VL_DESCRIPCION          :=NULL;
          VL_MONTO                :=NULL;
          VL_SFRRGFE_RATE_CODE    :=NULL;
          VL_CODIGO_DESC          :=NULL;
          VL_DESCRIPCION_DESC     :=NULL;
          VL_MONTO_PERCENT        :=NULL;
          VL_MONTO_AMOUNT         :=NULL;
          VL_DESCUENTODSI         :=NULL;
          VL_CODIGO_DSI           :=NULL;
          VL_DESCRIPCION_DSI      :=NULL;
          VL_NUMERO               :=NULL;
          VL_PRIMER_FECHA         :=NULL;
          VL_FLAG_PAGO            :=NULL;

         -- DBMS_OUTPUT.PUT_LINE('RECHA = '||P_FECHA);

         VL_DIA := CASE WHEN TO_CHAR(ALUMNO.FECHA_INICIO,'DD') BETWEEN 1 AND 15 THEN 15
                        WHEN TO_CHAR(ALUMNO.FECHA_INICIO,'DD') BETWEEN 16 AND 31 THEN 30 END;
         VL_MES := SUBSTR (TO_CHAR(TRUNC(ALUMNO.FECHA_INICIO),'dd/mm/rrrr'), 4, 2);
         VL_ANO := SUBSTR (TO_CHAR(TRUNC(ALUMNO.FECHA_INICIO),'dd/mm/rrrr'), 7, 4);

--       VL_MONTO_COL:= ALUMNO.MONTO-(ALUMNO.MONTO*(ALUMNO.DESCUENTO/100));         -- OMS 09/Agosto/2023


         BEGIN
           SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
             INTO VL_CODIGO_PAR,VL_DESCRIPCION_PAR
             FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CODE
              AND TBBDETC_DCAT_CODE = 'COL';
         EXCEPTION
         WHEN OTHERS THEN
         VL_CODIGO_PAR:=NULL;
         VL_DESCRIPCION_PAR:=NULL;
         VL_ERROR:= 'Error al calcular concepto = '||SQLERRM;
         END;

         IF VL_ERROR IS NULL THEN
            VL_NUMERO        := 1;
            VL_cargos        := 0;
            VL_Escalonados   := 0;       			-- OMS 09/Agosto/2023
            VL_Numero_Cargos := 0;	 			-- OMS 09/Agosto/2023

            -- Verifica si se trata de PAGOS ESCALONADOS	-- OMS 09/Agosto/2023            
            BEGIN
               SELECT REGEXP_COUNT (Alumno.Observaciones, ';') Resultado
                 INTO VL_Escalonados
                 FROM dual
                WHERE Alumno.Observaciones LIKE 'ESCALONADO:%';


               VL_Cad_Inicio := INSTR  (Alumno.Observaciones, ' ', 1, 1)+1;	-- Inicio de montos en ESCALONADOS; posicion 13 (Osbservaciones)

               IF  VL_Escalonados > 0 
                   THEN VL_Numero_Cargos := VL_Escalonados;
                   ELSE VL_Numero_Cargos := Alumno.Transa;
               END IF;

            EXCEPTION WHEN OTHERS THEN VL_Numero_Cargos := Alumno.Transa;
            END;   
            -- End: Verifica si se trata de PAGOS ESCALONADOS	-- OMS 09/Agosto/2023    


            -- DBMS_OUTPUT.PUT_LINE('VL_Escalonados   = '|| VL_Escalonados);
            -- DBMS_OUTPUT.PUT_LINE('VL_Numero_Cargos = '|| VL_Numero_Cargos);
            -- DBMS_OUTPUT.PUT_LINE('VL_Cad_Inicio    = '|| VL_Cad_Inicio);

            BEGIN

             FOR I IN 1..VL_Numero_Cargos			-- OMS 09/Agosto/2023
              LOOP

                -- DBMS_OUTPUT.PUT_LINE('Iteraci n No = ' || i);
                -- DBMS_OUTPUT.PUT_LINE('VL_MES = ' || VL_MES);
                -- DBMS_OUTPUT.PUT_LINE('VL_DIA = ' || VL_DIA);
                -- DBMS_OUTPUT.PUT_LINE('VL_ANO = ' || VL_ANO);


                IF VL_DIA = '30' THEN
                  VL_VENCIMIENTO := TO_DATE(CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO,'DD/MM/YYYY');
                ELSE
                  VL_VENCIMIENTO := TO_DATE(VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO,'DD/MM/YYYY');
                END IF;


                 VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (ALUMNO.PIDM);

                IF VL_NUMERO = 1 THEN
                   VL_PRIMER_FECHA := VL_VENCIMIENTO;
                   VL_VENCIMIENTO  := ALUMNO.FECHA_INICIO;
                END IF;

                IF VL_Escalonados  > 0 AND i = 1 THEN
                   VL_VENCIMIENTO  :=  VL_PRIMER_FECHA;                 -- OMS 09/Agosto/2023
                ELSIF VL_Escalonados > 0 AND i > 1 THEN
                   VL_VENCIMIENTO  :=  VL_VENCIMIENTO;    -- OMS 09/Agosto/2023

                ELSIF ALUMNO.FLAG_PAGO = 1 THEN 
                   VL_VENCIMIENTO  := ADD_MONTHS(VL_VENCIMIENTO,1);                
                ELSIF VL_NUMERO     = 1 THEN
                   VL_VENCIMIENTO  := VL_VENCIMIENTO;
                END IF;

                -- DBMS_OUTPUT.PUT_LINE('VL_PRIMER_FECHA = '|| VL_PRIMER_FECHA);
                -- DBMS_OUTPUT.PUT_LINE('VL_VENCIMIENTO  = '|| VL_VENCIMIENTO);

                BEGIN


 		   -- Calcula el Monto; dependiento el TIPO: Pago Unico, Fijo, Escalonado		--> OMS 09/Agosto/2023
                   VL_Cad_Fin := INSTR (Alumno.Observaciones, ';', 1, i)-1;				--> OMS Fin de la Cadena para extraer MONTO
                   IF  VL_Escalonados > 0
                       THEN VL_MONTO_COL := TO_NUMBER (SUBSTR (Alumno.Observaciones, VL_Cad_Inicio, VL_Cad_Fin - VL_Cad_Inicio + 1));
                            VL_MONTO_COL := VL_MONTO_COL - (VL_MONTO_COL * (ALUMNO.DESCUENTO/100));	-- OMS 09/Agosto/2023
                       ELSE VL_MONTO_COL := ALUMNO.MONTO - (ALUMNO.MONTO * (ALUMNO.DESCUENTO/100));	-- OMS 09/Agosto/2023
                   END IF;
                   -- End: Calcula el Monto; dependiento el TIPO: Pago Unico, Fijo, Escalonado

                 -- DBMS_OUTPUT.PUT_LINE('VL_Cad_Fin   = ' || VL_Cad_Fin);
                 -- DBMS_OUTPUT.PUT_LINE('VL_MONTO_COL = ' || VL_MONTO_COL);
                 -- DBMS_OUTPUT.PUT_LINE('Extracci n   = ' || SUBSTR (Alumno.Observaciones, VL_Cad_Inicio, VL_Cad_Fin - VL_Cad_Inicio + 1));

                 -- DBMS_OUTPUT.PUT_LINE('-------------------------------------');
                 -- DBMS_OUTPUT.PUT_LINE('ALUMNO.PIDM        = ' || ALUMNO.PIDM);
                 -- DBMS_OUTPUT.PUT_LINE('VL_SECUENCIA       = ' || VL_SECUENCIA);
                 -- DBMS_OUTPUT.PUT_LINE('ALUMNO.PERIODO     = ' || ALUMNO.PERIODO);
                 -- DBMS_OUTPUT.PUT_LINE('VL_CODIGO_PAR      = ' || VL_CODIGO_PAR);
                 -- DBMS_OUTPUT.PUT_LINE('VL_MONTO_COL       = ' || VL_MONTO_COL);
                 -- DBMS_OUTPUT.PUT_LINE('P_FECHA_VENC       = ' || TO_CHAR(VL_VENCIMIENTO,'DD/MM/YYYY'));
                 -- DBMS_OUTPUT.PUT_LINE('VL_DESCRIPCION_PAR = ' || VL_DESCRIPCION_PAR);
                 -- DBMS_OUTPUT.PUT_LINE('P_FECHA_INICIO     = ' || TO_CHAR(ALUMNO.FECHA_INICIO,'DD/MM/YYYY'));
                 -- DBMS_OUTPUT.PUT_LINE('-------------------------------------');


                 -- OMS 23/Sep/2023 --> En caso de ser el primer pago; debe ser la fecha del dia de HOY (sysdate)
                 IF i = 1
                    THEN Vm_Fecha_Vigencia := SYSDATE;           -- OMS 23/Sep/2023 (Fecha del Primer Pago)
                    ELSE Vm_Fecha_Vigencia := VL_VENCIMIENTO;    -- Se conserva la fecha calculada
                 END IF;

                 IF VL_Escalonados > 0 THEN
                   VL_ERROR:= PKG_FINANZAS.F_INSERTA_TBRACCD(
                                                             P_PIDM            => ALUMNO.PIDM
                                                           , P_SECUENCIA       => VL_SECUENCIA
                                                           , P_NUMBER_PAID     => NULL
                                                           , P_PERIODO         => ALUMNO.PERIODO
                                                           , P_PARTE_PERIODO   => NULL
                                                           , P_CODIGO          => VL_CODIGO_PAR
                                                           , P_MONTO           => VL_MONTO_COL
                                                           , P_BALANCE         => VL_MONTO_COL
                                                           , P_FECHA_VENC      => TO_CHAR(Vm_Fecha_Vigencia,'DD/MM/YYYY')
                                                           , P_DESCRIP         => VL_DESCRIPCION_PAR
                                                           , P_STUDY_PATH      => 0
                                                           , P_ORIGEN          => 'TZFEDCA (PARC)'
                                                           , P_FECHA_INICIO     => TO_CHAR(ALUMNO.FECHA_INICIO,'DD/MM/YYYY')
                                                           );

                 ELSE
                   -- Version de Pagos Fijos y Pago Unico
                   VL_ERROR:= PKG_FINANZAS.F_INSERTA_TBRACCD(
                                                             P_PIDM            => ALUMNO.PIDM
                                                           , P_SECUENCIA       => VL_SECUENCIA
                                                           , P_NUMBER_PAID     => NULL
                                                           , P_PERIODO         => ALUMNO.PERIODO
                                                           , P_PARTE_PERIODO   => NULL
                                                           , P_CODIGO          => VL_CODIGO_PAR
                                                           , P_MONTO           => VL_MONTO_COL
                                                           , P_BALANCE         => VL_MONTO_COL
                                                           , P_FECHA_VENC      => TO_CHAR(TO_DATE(SUBSTR(Vm_Fecha_Vigencia,1,10),'YYYY/MM/DD'),'DD/MM/YYYY')
                                                           , P_DESCRIP         => VL_DESCRIPCION_PAR
                                                           , P_STUDY_PATH      => 0
                                                           , P_ORIGEN          => 'TZFEDCA (PARC)'
                                                           , P_FECHA_INICIO     => TO_CHAR(TO_DATE(SUBSTR(ALUMNO.FECHA_INICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY')
                                                           );
                   END IF;


                   IF VL_NUMERO = 1 AND VL_Escalonados = 0 THEN                 -- OMS 09/Agosto/2023
                      VL_VENCIMIENTO:= VL_PRIMER_FECHA;
                   END IF;

                   VL_NUMERO := VL_NUMERO+1;
                   VL_cargos := VL_cargos+1;

                -- VL_MONTO_COL:= ALUMNO.MONTO-(ALUMNO.MONTO*(ALUMNO.DESCUENTO/100));		-- OMS 09/Agosto/2023
                   -- DBMS_OUTPUT.PUT_LINE('VL_MONTO_COL (segunda) = ' || VL_MONTO_COL);


                    VL_MES := VL_MES +1;

                   IF VL_MES = '13' THEN
                      VL_MES := '01';
                      VL_ANO := VL_ANO +1;
                   END IF;

                  ----------------- Pone el numero de Cargos --------------------

                  Begin
                        Update tbraccd
                        -- set TBRACCD_DOCUMENT_NUMBER = VL_cargos || ' de '||alumno.TRANSA
                           set TBRACCD_DOCUMENT_NUMBER = i ||' de '|| VL_Numero_Cargos          -- OMS 09/Agosto/2023
                        Where 1=1
                        and tbraccd_pidm = ALUMNO.PIDM
                        And TBRACCD_TRAN_NUMBER = VL_SECUENCIA;
                  Exception
                    When Others then  
                     null;
                  End;

                END;

                -- Siguiente Iteraci n; Aplica para PAGOS ESCALONADOS
                -- DBMS_OUTPUT.PUT_LINE('Siguiente Iteraci n...');
                IF VL_Escalonados > 0 THEN VL_Cad_Inicio := VL_Cad_Fin+2 ; END IF;	--> OMS 09/Agosto/2023

              END LOOP;				-- Ciclo para el numero de pagos 	--> OMS 09/Agosto/2023

           END;

           BEGIN
           /*   SE GENERA ORDEN PARA TENER EL RASTRO DE LA CARTERA  */
             BEGIN
               SELECT MAX(TZTORDR_CONTADOR)+1
                 INTO VL_ORDEN
                 FROM TZTORDR;
             EXCEPTION
             WHEN OTHERS THEN
             VL_ORDEN:= NULL;
             END;

             IF VL_ORDEN IS NOT NULL THEN

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
                       'TZTBOOT',
                       NULL,
                       TRUNC(ALUMNO.FECHA_INICIO),
                       ALUMNO.RATE,
                       ALUMNO.JORNADA,
                       NULL,
                       ALUMNO.PERIODO);

             END IF;

             BEGIN
               UPDATE TBRACCD A1
                  SET A1.TBRACCD_RECEIPT_NUMBER = VL_ORDEN,
                      A1.TBRACCD_CURR_CODE = ALUMNO.DIVISA
                WHERE     A1.TBRACCD_PIDM = ALUMNO.PIDM
                      AND A1.TBRACCD_TERM_CODE = ALUMNO.PERIODO
                      AND A1.TBRACCD_RECEIPT_NUMBER IS NULL;
             EXCEPTION
             WHEN OTHERS THEN
             NULL;
             END;

             BEGIN
               UPDATE TVRACCD A1
                  SET A1.TVRACCD_RECEIPT_NUMBER = VL_ORDEN,
                      A1.TVRACCD_CURR_CODE = ALUMNO.DIVISA
                WHERE     A1.TVRACCD_PIDM = ALUMNO.PIDM
                      AND A1.TVRACCD_TERM_CODE = ALUMNO.PERIODO
                      AND A1.TVRACCD_RECEIPT_NUMBER IS NULL;
             EXCEPTION
             WHEN OTHERS THEN
             NULL;
             END;

           END ;

           BEGIN
             -- Obtiene el status original de TZTBOOT
             BEGIN 
                SELECT tztboot_status
                  INTO Vm_Status_BootCamp        -- OMS 23/Sep/2023 (GENERADA o PAGADO)
                  FROM tztboot a
                 WHERE TZTBOOT_PIDM = P_PIDM
                   AND TRUNC(TZTBOOT_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);

             EXCEPTION WHEN OTHERS THEN Vm_Status_BootCamp := 'ACTIVO';
             END;

             IF Vm_Status_BootCamp = 'ACTIVO' THEN Vm_Status_BootCamp := 'GENERADA'; END IF;

             UPDATE TZTBOOT
                SET -- TZTBOOT_OBSERVACIONES = NULL,			-- OMS 09/Agosto/2023 (Borraba las observaciones)
                    TZTBOOT_ORDEN  = VL_ORDEN,
                    TZTBOOT_STATUS = Vm_Status_BootCamp,        -- 'GENERADA',  -- OMS 23/Sep/2023 (Se queda con el status original)
                    TZTBOOT_USER_UPDATE = USER,
                    TZTBOOT_ACTIVITY_UPDATE = SYSDATE
              WHERE TZTBOOT_PIDM = P_PIDM
                AND TRUNC(TZTBOOT_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);
           END;

           BEGIN
               INSERT
                 INTO  TZDOCTR
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
                       ALUMNO.TRANSA,
                       NULL,
                       0,
                       0,
                       0,
                       VL_MONTO_COL,
                       SYSDATE        ,
                       1              ,
                       'Cartera creada con exito para BOOTCAMP',
                       VL_DIA,
                       ALUMNO.MATRICULA,
                       'BOOT'         ,
                       1);
           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR :='Error al insertar la bitacora de la cartera' ||SQLERRM;
           END;

         ELSE
           /* SE GUARDA ERROR EN BITACORA PARA EJECUTAR POSTERIORMENTE */
           UPDATE TZTBOOT
              SET TZTBOOT_OBSERVACIONES = TZTBOOT_OBSERVACIONES || ' - ' || VL_ERROR 			-- OMS 09/Agosto/2023

            WHERE     TZTBOOT_PIDM = P_PIDM
                  AND TRUNC(TZTBOOT_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);

         END IF;

       END LOOP;				-- Cursor Registros de TZTBOOT   --> OMS 09/Agosto/2023
     END;					-- BEGIN Principal de 'BOOTCAMP' --> OMS 09/Agosto/2023

     -- P_ALUMNO = 'BOOTCAMP'			-- OMS 09/Agosto/2023

   ELSIF P_ALUMNO = 'SENIOR' THEN

      -------------------------------------------
      -------------------------------------------
      -------------------------------------------
      -------------------------------------------
     BEGIN

       FOR ALUMNO IN (
                      SELECT TZTSNOR_PIDM PIDM,
                             GB_COMMON.F_GET_ID (TZTSNOR_PIDM) MATRICULA,
                             TZTSNOR_PROGRAM PROGRAMA,
                             TZTSNOR_TERM_CODE PERIODO,
                             TZTSNOR_START_DATE  FECHA_INICIO,
                             TZTSNOR_PTRM_CODE PPARTE,
                             NVL(TZTSNOR_DESCUENTO,0) DESCUENTO,
                             TZTSNOR_AMOUNT MONTO,
                             TZTSNOR_NUM_PAG PAGOS,
                             TZTSNOR_RATE_CODE RATE,
                             TZTSNOR_ATTS_CODE JORNADA,
                             TZTSNOR_STATUS ESTATUS,
                             TZTSNOR_ORDEN ORDEN,
                             SORLCUR_KEY_SEQNO STUDY_PATH,
                             DECODE (A.SORLCUR_DEGC_CODE, 'DIPL', 'COLEGIATURA DIPLOMADO', 'CURS', 'COLEGIATURA CURSO')DEGC_CODE,
                             (SELECT DISTINCT SORLCUR_SITE_CODE
                                FROM SORLCUR CUR
                               WHERE    CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                    AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                    AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                             FROM SORLCUR CUR2
                                                             WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                             AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO,
                             TZTSNOR_OBSERVACIONES OBSERVACIONES
                        FROM TZTSNOR, SORLCUR A
                       WHERE      TZTSNOR_PIDM = A.SORLCUR_PIDM
--                             AND A.SORLCUR_START_DATE = TZTSNOR_START_DATE
                             AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                             AND A.SORLCUR_ROLL_IND = 'Y'
                             AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                             AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                       FROM SORLCUR A1
                                                      WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                            AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND
                                                            AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                                            AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                            AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
                             AND TZTSNOR_PIDM = P_PIDM
                             AND TZTSNOR_START_DATE = P_FECHA

       )LOOP

            BEGIN

             SELECT TBBDETC_DESC
               INTO VL_DESCRIPCION_PAR
               FROM TBBDETC
              WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CODE;
            END;


           -- DBMS_OUTPUT.PUT_LINE(TO_CHAR(TO_DATE(SUBSTR(ALUMNO.FECHA_INICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY'));

                    VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (ALUMNO.PIDM);


                      VL_ERROR:= PKG_FINANZAS.F_INSERTA_TBRACCD(
                                                    P_PIDM            => ALUMNO.PIDM
                                                  , P_SECUENCIA       => VL_SECUENCIA
                                                  , P_NUMBER_PAID     => NULL
                                                  , P_PERIODO         => ALUMNO.PERIODO
                                                  , P_PARTE_PERIODO   => ALUMNO.PPARTE
                                                  , P_CODIGO          => P_DETAIL_CODE
                                                  , P_MONTO           => ALUMNO.MONTO
                                                  , P_BALANCE         => ALUMNO.MONTO
                                                  , P_FECHA_VENC      => TRUNC(SYSDATE)
                                                  , P_DESCRIP         => VL_DESCRIPCION_PAR
                                                  , P_STUDY_PATH      => ALUMNO.STUDY_PATH
                                                  , P_ORIGEN          => 'TZFEDCA (PARC)'
                                                  , P_FECHA_INICIO    => TO_DATE(SUBSTR(ALUMNO.FECHA_INICIO,1,10),'DD/MM/YYYY')
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
                 VALUES( 'SEN',
                         'LI',
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
                WHERE     A1.TBRACCD_PIDM = ALUMNO.PIDM
                      AND A1.TBRACCD_TERM_CODE = ALUMNO.PERIODO
                      AND A1.TBRACCD_PERIOD = ALUMNO.PPARTE
                      AND A1.TBRACCD_RECEIPT_NUMBER IS NULL;

               UPDATE TVRACCD A1
                  SET A1.TVRACCD_RECEIPT_NUMBER = VL_ORDEN
                WHERE     A1.TVRACCD_PIDM = ALUMNO.PIDM
                      AND A1.TVRACCD_TERM_CODE = ALUMNO.PERIODO
                      AND A1.TVRACCD_PERIOD = ALUMNO.PPARTE
                      AND A1.TVRACCD_RECEIPT_NUMBER IS NULL;
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR:= 'ERROR AL ACTUALIZAR TBRACCD = '||SQLERRM;
             END;

             BEGIN
                -- Obtiene el status original de TZTBOOT
                BEGIN 
                   SELECT tztboot_status
                     INTO Vm_Status_BootCamp        -- OMS 23/Sep/2023 (GENERADA o PAGADO)
                     FROM tztboot a
                    WHERE TZTBOOT_PIDM = P_PIDM
                      AND TRUNC(TZTBOOT_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);

                EXCEPTION WHEN OTHERS THEN Vm_Status_BootCamp := 'ACTIVO';
                END;

                IF Vm_Status_BootCamp = 'ACTIVO' THEN Vm_Status_BootCamp := 'GENERADA'; END IF;

               UPDATE TZTSNOR
                  SET -- TZTSNOR_OBSERVACIONES = NULL,			-- OMS 09/Agosto/2023 (Borraba las observaciones)
                      TZTSNOR_ORDEN  = VL_ORDEN,
                      TZTSNOR_STATUS = Vm_Status_BootCamp,      -- 'GENERADA',  -- OMS 23/Sep/2023 (Se queda con el status original)
                      TZTSNOR_USER_UPDATE = USER,
                      TZTSNOR_ACTIVITY_UPDATE = SYSDATE
                WHERE     TZTSNOR_PIDM = ALUMNO.PIDM
                      AND TRUNC(TZTSNOR_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);
             END;

             BEGIN
                 INSERT
                   INTO  TZDOCTR
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
                         'SEN',
                         'LI',
                         ALUMNO.PERIODO,
                         TRUNC(ALUMNO.FECHA_INICIO),
                         ALUMNO.PPARTE,
                         0,
                         ALUMNO.PAGOS,
                         NULL,
                         0,
                         0,
                         0,
                         0,
                         SYSDATE        ,
                         1              ,
                         'Cartera creada con exito para SENIOR',
                         TO_CHAR(SYSDATE,'DD'),
                         ALUMNO.MATRICULA,
                         'SENI'         ,
                         1);
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR :='Error al insertar la bitacora de la cartera' ||SQLERRM;
             END;

           END IF;
       END LOOP;

     END;

   END IF;


   IF VL_ERROR IS NULL THEN
     VL_ERROR:='EXITO';
     COMMIT;
   ELSE
    -- DBMS_OUTPUT.PUT_LINE ('VL_ERROR (EXCEPTION) = ' || VL_ERROR || ' --> ' || SQLERRM);
    ROLLBACK;
   END IF;

  RETURN(VL_ERROR);

 END F_CART_BOOTCAMP_v2;

-- OMS 09/Agosto/2023 
-- Se agrega la funcionalidad de pagos escalonados; en la función: F_CART_BOOTCAMP_v2 para alumnos de UCamp
-- End:



FUNCTION F_CART_BOOTCAMP (P_PIDM  NUMBER,
                          P_FECHA DATE,
                          P_ALUMNO VARCHAR2,
                          P_DETAIL_CODE VARCHAR2 )RETURN VARCHAR2 IS


VL_DIA                  NUMBER;
VL_MES                  NUMBER;
VL_ANO                  NUMBER;
VL_CODIGO_PAR           VARCHAR2(4);
VL_MONTO_COL            NUMBER;
VL_VENCIMIENTO          DATE;
VL_DESCRIPCION_PAR      VARCHAR2(40);
VL_ORDEN                NUMBER;
VL_SECUENCIA            NUMBER;
VL_ERROR                VARCHAR2(500):= 'Error al generar cartera';
VL_CODIGO               VARCHAR2(5);
VL_DESCRIPCION          VARCHAR2(50);
VL_MONTO                NUMBER;
VL_SFRRGFE_RATE_CODE    VARCHAR2(5);
VL_CODIGO_DESC          VARCHAR2(5);
VL_DESCRIPCION_DESC     VARCHAR2(50);
VL_MONTO_PERCENT        NUMBER;
VL_MONTO_AMOUNT         NUMBER;
VL_DESCUENTODSI         NUMBER;
VL_CODIGO_DSI           VARCHAR2(5);
VL_DESCRIPCION_DSI      VARCHAR2(50);
VL_CODIGO_PLP           VARCHAR2(5);
VL_DESCRIPCION_PLP      VARCHAR2(50);
VL_PLAN_PAGO            NUMBER;
VL_ULT_COL              NUMBER;
VL_DESCUENTO            NUMBER;
VL_SECUENCIACOL         NUMBER;
VL_DIFE                 NUMBER;
VL_NUMERO               NUMBER;
VL_PRIMER_FECHA         DATE;
VL_FLAG_PAGO            NUMBER;
VL_cargos               NUMBER;
Vm_Fecha_Vigencia       DATE;                  -- OMS 23/Sep/2023 (Fecha del Primer Pago)
Vm_Status_BootCamp      VARCHAR2 (10) := NULL; -- OMS 23/Sep/2023     -- Status = GENERADA o PAGADO

 BEGIN

   IF P_ALUMNO = 'BOOTCAMP' THEN

     BEGIN

         FOR ALUMNO IN (

                      SELECT TZTBOOT_CAMP_CODE CAMPUS,
                             TZTBOOT_LEVL_CODE NIVEL,
                             TZTBOOT_PIDM PIDM,
                             TZTBOOT_ID MATRICULA,
                             TZTBOOT_PROGRAM PROGRAMA,
                             TZTBOOT_TERM_CODE PERIODO,
                             TZTBOOT_START_DATE  FECHA_INICIO,
                             TZTBOOT_CURR_CODE DIVISA,
                             NVL(TZTBOOT_DESCUENTO,0) DESCUENTO,
                             TZTBOOT_AMOUNT MONTO,
                             TZTBOOT_NUM_TRAN TRANSA,
                             TZTBOOT_NUM_PAG PAGOS,
                             TZTBOOT_RATE_CODE RATE,
                             TZTBOOT_ATTS_CODE JORNADA,
                             TZTBOOT_DATA_ORIGIN ORIGEN,
                             TZTBOOT_STATUS ESTATUS,
                             TZTBOOT_ORDEN ORDEN,
                             TZTBOOT_NUM_PAG FLAG_PAGO,
                             SORLCUR_KEY_SEQNO STUDY_PATH,
                             DECODE (A.SORLCUR_DEGC_CODE, 'DIPL', 'COLEGIATURA DIPLOMADO', 'CURS', 'COLEGIATURA CURSO')DEGC_CODE,
                             (SELECT DISTINCT SORLCUR_SITE_CODE
                                FROM SORLCUR CUR
                               WHERE    CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                    AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                    AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                             FROM SORLCUR CUR2
                                                             WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                             AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO,
                             TZTBOOT_OBSERVACIONES OBSERVACIONES
                        FROM    TZTBOOT LEFT JOIN
                                SORLCUR A
                             ON     TZTBOOT_PIDM = A.SORLCUR_PIDM
                                AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                                AND A.SORLCUR_ROLL_IND = 'Y'
                                AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                                AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                          FROM SORLCUR A1
                                                         WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                               AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND
                                                               AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                                               AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                               AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)

                       WHERE     TZTBOOT_PIDM = P_PIDM
                             AND TRUNC(TZTBOOT_START_DATE) = TRUNC (P_FECHA)    -- OMS 09/Agostp/2023 (TRUNC)
                          -- AND TZTBOOT_STATUS = 'ACTIVO'                      -- OMS 23/Sep/2023
                             AND (  TZTBOOT_STATUS = 'ACTIVO' OR
                                   (TZTBOOT_STATUS = 'PAGADO' AND TZTBOOT_CUPON = 100))

       )LOOP

          VL_DIA                  :=NULL;
          VL_MES                  :=NULL;
          VL_ANO                  :=NULL;
          VL_CODIGO_PAR           :=NULL;
          VL_MONTO_COL            :=NULL;
          VL_VENCIMIENTO          :=NULL;
          VL_DESCRIPCION_PAR      :=NULL;
          VL_ORDEN                :=NULL;
          VL_SECUENCIA            :=NULL;
          VL_ERROR                :=NULL;
          VL_CODIGO               :=NULL;
          VL_DESCRIPCION          :=NULL;
          VL_MONTO                :=NULL;
          VL_SFRRGFE_RATE_CODE    :=NULL;
          VL_CODIGO_DESC          :=NULL;
          VL_DESCRIPCION_DESC     :=NULL;
          VL_MONTO_PERCENT        :=NULL;
          VL_MONTO_AMOUNT         :=NULL;
          VL_DESCUENTODSI         :=NULL;
          VL_CODIGO_DSI           :=NULL;
          VL_DESCRIPCION_DSI      :=NULL;
          VL_NUMERO               :=NULL;
          VL_PRIMER_FECHA         :=NULL;
          VL_FLAG_PAGO            :=NULL;


         DBMS_OUTPUT.PUT_LINE('RECHA = '||P_FECHA);

         VL_DIA := CASE WHEN TO_CHAR(ALUMNO.FECHA_INICIO,'DD') BETWEEN 1 AND 15 THEN 15
                        WHEN TO_CHAR(ALUMNO.FECHA_INICIO,'DD') BETWEEN 16 AND 31 THEN 30 END;
         VL_MES := SUBSTR (TO_CHAR(TRUNC(ALUMNO.FECHA_INICIO),'dd/mm/rrrr'), 4, 2);
         VL_ANO := SUBSTR (TO_CHAR(TRUNC(ALUMNO.FECHA_INICIO),'dd/mm/rrrr'), 7, 4);

         VL_MONTO_COL:= ALUMNO.MONTO-(ALUMNO.MONTO*(ALUMNO.DESCUENTO/100));


         BEGIN
           SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
             INTO VL_CODIGO_PAR,VL_DESCRIPCION_PAR
             FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CODE
              AND TBBDETC_DCAT_CODE = 'COL';
         EXCEPTION
         WHEN OTHERS THEN
         VL_CODIGO_PAR:=NULL;
         VL_DESCRIPCION_PAR:=NULL;
         VL_ERROR:= 'Error al calcular concepto = '||SQLERRM;
         END;


         IF VL_ERROR IS NULL THEN
           VL_NUMERO:=1;
           VL_cargos:=0;
            BEGIN

             FOR I IN 1..ALUMNO.TRANSA

              LOOP

                IF VL_DIA = '30' THEN
                  VL_VENCIMIENTO := TO_DATE(CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO,'DD/MM/YYYY');
                ELSE
                  VL_VENCIMIENTO := TO_DATE(VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO,'DD/MM/YYYY');
                END IF;

                 VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (ALUMNO.PIDM);

                IF VL_NUMERO = 1 THEN
                   VL_PRIMER_FECHA:= VL_VENCIMIENTO;
                   VL_VENCIMIENTO:= ALUMNO.FECHA_INICIO;
                END IF;


                IF ALUMNO.FLAG_PAGO = 1 THEN
                   VL_VENCIMIENTO:= ADD_MONTHS(VL_VENCIMIENTO,1);
                ELSIF VL_NUMERO = 1 THEN
                   VL_VENCIMIENTO:= VL_VENCIMIENTO;
                END IF;


                BEGIN

                 -- OMS 23/Sep/2023 --> En caso de ser el primer pago; debe ser la fecha del dia de HOY (sysdate)
                 IF i = 1
                    THEN Vm_Fecha_Vigencia := SYSDATE;           -- OMS 23/Sep/2023 (Fecha del Primer Pago)
                    ELSE Vm_Fecha_Vigencia := VL_VENCIMIENTO;    -- Se conserva la fecha calculada
                 END IF;


                   VL_ERROR:= PKG_FINANZAS.F_INSERTA_TBRACCD(
                                                             P_PIDM            => ALUMNO.PIDM
                                                           , P_SECUENCIA       => VL_SECUENCIA
                                                           , P_NUMBER_PAID     => NULL
                                                           , P_PERIODO         => ALUMNO.PERIODO
                                                           , P_PARTE_PERIODO   => NULL
                                                           , P_CODIGO          => VL_CODIGO_PAR
                                                           , P_MONTO           => VL_MONTO_COL
                                                           , P_BALANCE         => VL_MONTO_COL
                                                           , P_FECHA_VENC      => TO_CHAR(TO_DATE(SUBSTR(Vm_Fecha_Vigencia,1,10),'YYYY/MM/DD'),'DD/MM/YYYY')
                                      --                   , P_FECHA_VENC      => TO_CHAR(TO_DATE(SUBSTR(VL_VENCIMIENTO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY')
                                                           , P_DESCRIP         => VL_DESCRIPCION_PAR
                                                           , P_STUDY_PATH      => 0
                                                           , P_ORIGEN          => 'TZFEDCA (PARC)'
                                                           ,P_FECHA_INICIO     => TO_CHAR(TO_DATE(SUBSTR(ALUMNO.FECHA_INICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY')
                                                           );



                   IF VL_NUMERO = 1 THEN
                      VL_VENCIMIENTO:= VL_PRIMER_FECHA;
                   END IF;

                   VL_NUMERO:=VL_NUMERO+1;
                   VL_cargos:= VL_cargos+1;

                   VL_MONTO_COL:=ALUMNO.MONTO-(ALUMNO.MONTO*(ALUMNO.DESCUENTO/100));

                    VL_MES := VL_MES +1;

                   IF VL_MES = '13' THEN
                      VL_MES := '01';
                      VL_ANO := VL_ANO +1;
                   END IF;

                  ----------------- Pone el numero de Cargos --------------------
                  Begin
                        Update tbraccd
                        set TBRACCD_DOCUMENT_NUMBER = VL_cargos ||' de '||alumno.TRANSA
                        Where 1=1
                        and tbraccd_pidm = ALUMNO.PIDM
                        And TBRACCD_TRAN_NUMBER = VL_SECUENCIA;
                  Exception
                    When Others then
                     null;
                  End;



                END;

              END LOOP;

           END;

           BEGIN
           /*   SE GENERA ORDEN PARA TENER EL RASTRO DE LA CARTERA  */
             BEGIN
               SELECT MAX(TZTORDR_CONTADOR)+1
                 INTO VL_ORDEN
                 FROM TZTORDR;
             EXCEPTION
             WHEN OTHERS THEN
             VL_ORDEN:= NULL;
             END;

             IF VL_ORDEN IS NOT NULL THEN

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
                       'TZTBOOT',
                       NULL,
                       TRUNC(ALUMNO.FECHA_INICIO),
                       ALUMNO.RATE,
                       ALUMNO.JORNADA,
                       NULL,
                       ALUMNO.PERIODO);

             END IF;

             BEGIN
               UPDATE TBRACCD A1
                  SET A1.TBRACCD_RECEIPT_NUMBER = VL_ORDEN,
                      A1.TBRACCD_CURR_CODE = ALUMNO.DIVISA
                WHERE     A1.TBRACCD_PIDM = ALUMNO.PIDM
                      AND A1.TBRACCD_TERM_CODE = ALUMNO.PERIODO
                      AND A1.TBRACCD_RECEIPT_NUMBER IS NULL;
             EXCEPTION
             WHEN OTHERS THEN
             NULL;
             END;

             BEGIN
               UPDATE TVRACCD A1
                  SET A1.TVRACCD_RECEIPT_NUMBER = VL_ORDEN,
                      A1.TVRACCD_CURR_CODE = ALUMNO.DIVISA
                WHERE     A1.TVRACCD_PIDM = ALUMNO.PIDM
                      AND A1.TVRACCD_TERM_CODE = ALUMNO.PERIODO
                      AND A1.TVRACCD_RECEIPT_NUMBER IS NULL;
             EXCEPTION
             WHEN OTHERS THEN
             NULL;
             END;

           END ;

           BEGIN
             -- Obtiene el status original de TZTBOOT
             BEGIN 
                SELECT tztboot_status
                  INTO Vm_Status_BootCamp        -- OMS 23/Sep/2023 (GENERADA o PAGADO)
                  FROM tztboot a
                 WHERE TZTBOOT_PIDM = P_PIDM
                   AND TRUNC(TZTBOOT_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);

             EXCEPTION WHEN OTHERS THEN Vm_Status_BootCamp := 'ACTIVO';
             END;

             IF Vm_Status_BootCamp = 'ACTIVO' THEN Vm_Status_BootCamp := 'GENERADA'; END IF;

             UPDATE TZTBOOT
                SET -- TZTBOOT_OBSERVACIONES = NULL,        -- OMS 29/Agosto/2023 (Versión Escalonados)
                    TZTBOOT_ORDEN  = VL_ORDEN,
                    TZTBOOT_STATUS = Vm_Status_BootCamp,    -- 'GENERADA',      -- OMS 23/Sep/2023 (Se queda con el status original)
                    TZTBOOT_USER_UPDATE = USER,
                    TZTBOOT_ACTIVITY_UPDATE = SYSDATE
              WHERE     TZTBOOT_PIDM = P_PIDM
                    AND TRUNC(TZTBOOT_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);
           END;

           BEGIN
               INSERT
                 INTO  TZDOCTR
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
                       ALUMNO.TRANSA,
                       NULL,
                       0,
                       0,
                       0,
                       VL_MONTO_COL,
                       SYSDATE        ,
                       1              ,
                       'Cartera creada con exito para BOOTCAMP',
                       VL_DIA,
                       ALUMNO.MATRICULA,
                       'BOOT'         ,
                       1);
           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR :='Error al insertar la bitacora de la cartera' ||SQLERRM;
           END;

         ELSE
           /* SE GUARDA ERROR EN BITACORA PARA EJECUTAR POSTERIORMENTE */
           UPDATE TZTBOOT
              SET TZTBOOT_OBSERVACIONES = VL_ERROR
            WHERE     TZTBOOT_PIDM = P_PIDM
                  AND TRUNC(TZTBOOT_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);

         END IF;

       END LOOP;
     END;

   ELSIF P_ALUMNO = 'SENIOR' THEN

      -------------------------------------------
      -------------------------------------------
      -------------------------------------------
      -------------------------------------------
     BEGIN

       FOR ALUMNO IN (
                      SELECT TZTSNOR_PIDM PIDM,
                             GB_COMMON.F_GET_ID (TZTSNOR_PIDM) MATRICULA,
                             TZTSNOR_PROGRAM PROGRAMA,
                             TZTSNOR_TERM_CODE PERIODO,
                             TZTSNOR_START_DATE  FECHA_INICIO,
                             TZTSNOR_PTRM_CODE PPARTE,
                             NVL(TZTSNOR_DESCUENTO,0) DESCUENTO,
                             TZTSNOR_AMOUNT MONTO,
                             TZTSNOR_NUM_PAG PAGOS,
                             TZTSNOR_RATE_CODE RATE,
                             TZTSNOR_ATTS_CODE JORNADA,
                             TZTSNOR_STATUS ESTATUS,
                             TZTSNOR_ORDEN ORDEN,
                             SORLCUR_KEY_SEQNO STUDY_PATH,
                             DECODE (A.SORLCUR_DEGC_CODE, 'DIPL', 'COLEGIATURA DIPLOMADO', 'CURS', 'COLEGIATURA CURSO')DEGC_CODE,
                             (SELECT DISTINCT SORLCUR_SITE_CODE
                                FROM SORLCUR CUR
                               WHERE    CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                    AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                    AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                             FROM SORLCUR CUR2
                                                             WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                             AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO,
                             TZTSNOR_OBSERVACIONES OBSERVACIONES
                        FROM TZTSNOR, SORLCUR A
                       WHERE      TZTSNOR_PIDM = A.SORLCUR_PIDM
--                             AND A.SORLCUR_START_DATE = TZTSNOR_START_DATE
                             AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                             AND A.SORLCUR_ROLL_IND = 'Y'
                             AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                             AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                       FROM SORLCUR A1
                                                      WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                            AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND
                                                            AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                                            AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                            AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
                             AND TZTSNOR_PIDM = P_PIDM
                             AND TZTSNOR_START_DATE = P_FECHA

       )LOOP

            BEGIN

             SELECT TBBDETC_DESC
               INTO VL_DESCRIPCION_PAR
               FROM TBBDETC
              WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CODE;
            END;


           DBMS_OUTPUT.PUT_LINE(TO_CHAR(TO_DATE(SUBSTR(ALUMNO.FECHA_INICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY'));

                    VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (ALUMNO.PIDM);


                      VL_ERROR:= PKG_FINANZAS.F_INSERTA_TBRACCD(
                                                    P_PIDM            => ALUMNO.PIDM
                                                  , P_SECUENCIA       => VL_SECUENCIA
                                                  , P_NUMBER_PAID     => NULL
                                                  , P_PERIODO         => ALUMNO.PERIODO
                                                  , P_PARTE_PERIODO   => ALUMNO.PPARTE
                                                  , P_CODIGO          => P_DETAIL_CODE
                                                  , P_MONTO           => ALUMNO.MONTO
                                                  , P_BALANCE         => ALUMNO.MONTO
                                                  , P_FECHA_VENC      => TRUNC(SYSDATE)
                                                  , P_DESCRIP         => VL_DESCRIPCION_PAR
                                                  , P_STUDY_PATH      => ALUMNO.STUDY_PATH
                                                  , P_ORIGEN          => 'TZFEDCA (PARC)'
                                                  , P_FECHA_INICIO    => TO_DATE(SUBSTR(ALUMNO.FECHA_INICIO,1,10),'DD/MM/YYYY')
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
                 VALUES( 'SEN',
                         'LI',
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
                WHERE     A1.TBRACCD_PIDM = ALUMNO.PIDM
                      AND A1.TBRACCD_TERM_CODE = ALUMNO.PERIODO
                      AND A1.TBRACCD_PERIOD = ALUMNO.PPARTE
                      AND A1.TBRACCD_RECEIPT_NUMBER IS NULL;

               UPDATE TVRACCD A1
                  SET A1.TVRACCD_RECEIPT_NUMBER = VL_ORDEN
                WHERE     A1.TVRACCD_PIDM = ALUMNO.PIDM
                      AND A1.TVRACCD_TERM_CODE = ALUMNO.PERIODO
                      AND A1.TVRACCD_PERIOD = ALUMNO.PPARTE
                      AND A1.TVRACCD_RECEIPT_NUMBER IS NULL;
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR:= 'ERROR AL ACTUALIZAR TBRACCD = '||SQLERRM;
             END;

             BEGIN
                -- Obtiene el status original de TZTBOOT
                BEGIN 
                   SELECT tztboot_status
                     INTO Vm_Status_BootCamp        -- OMS 23/Sep/2023 (GENERADA o PAGADO)
                     FROM tztboot a
                    WHERE TZTBOOT_PIDM = P_PIDM
                      AND TRUNC(TZTBOOT_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);

                EXCEPTION WHEN OTHERS THEN Vm_Status_BootCamp := 'ACTIVO';
                END;

                IF Vm_Status_BootCamp = 'ACTIVO' THEN Vm_Status_BootCamp := 'GENERADA'; END IF;

               UPDATE TZTSNOR
                  SET -- TZTSNOR_OBSERVACIONES = NULL,        -- OMS 29/Agosto/2023 ... Pagos Escalonados
                      TZTSNOR_ORDEN  = VL_ORDEN,
                      TZTSNOR_STATUS = Vm_Status_BootCamp,    -- 'GENERADA',    -- OMS 23/Sep/2023 (Generada o PAGADO)
                      TZTSNOR_USER_UPDATE = USER,
                      TZTSNOR_ACTIVITY_UPDATE = SYSDATE
                WHERE     TZTSNOR_PIDM = ALUMNO.PIDM
                      AND TRUNC(TZTSNOR_START_DATE) = TRUNC(ALUMNO.FECHA_INICIO);
             END;

             BEGIN
                 INSERT
                   INTO  TZDOCTR
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
                         'SEN',
                         'LI',
                         ALUMNO.PERIODO,
                         TRUNC(ALUMNO.FECHA_INICIO),
                         ALUMNO.PPARTE,
                         0,
                         ALUMNO.PAGOS,
                         NULL,
                         0,
                         0,
                         0,
                         0,
                         SYSDATE        ,
                         1              ,
                         'Cartera creada con exito para SENIOR',
                         TO_CHAR(SYSDATE,'DD'),
                         ALUMNO.MATRICULA,
                         'SENI'         ,
                         1);
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR :='Error al insertar la bitacora de la cartera' ||SQLERRM;
             END;

           END IF;
       END LOOP;

     END;

   END IF;


   IF VL_ERROR IS NULL THEN
     VL_ERROR:='EXITO';
    COMMIT;
   ELSE
    ROLLBACK;
   END IF;

  RETURN(VL_ERROR);

 END F_CART_BOOTCAMP;

FUNCTION F_INSERT_TZTBOOT ( P_CAMPUS                VARCHAR2,
                            P_NIVEL                 VARCHAR2,
                            P_PIDM                  NUMBER,
                            P_MATRICULA             VARCHAR2,
                            P_PROGRAMA              VARCHAR2,
                            P_PERIODO               VARCHAR2,
                            P_FECHA_INICIO          DATE,
                            P_DIVISA                VARCHAR2,
                            P_DESCUENTO             NUMBER,
                            P_MONTO_PARC            NUMBER,
                            P_MONTO_PRIMER_PAGO     NUMBER,
                            P_PAGOS_MAT             NUMBER,
                            P_PAGOS_REGLA           NUMBER,
                            P_RATE                  VARCHAR2,
                            P_JORNADA               VARCHAR2,
                            P_ORIGEN                VARCHAR2,
                            P_CUPON_DESC            VARCHAR2,
                            P_CUPON_MONTO           NUMBER,
                            P_CODIGO                VARCHAR2,
                            P_DURACION              NUMBER   DEFAULT NULL,
                            P_PREGUNTA              VARCHAR2 DEFAULT NULL,
                            P_MEDIO                 VARCHAR2 DEFAULT NULL,
                            P_OBSERVACIONES         VARCHAR2 DEFAULT NULL,
                            
                            p_pais_lada             VARCHAR2 DEFAULT NULL,       -- OMS 23/Abril/2024
                            p_telefono              VARCHAR2 DEFAULT NULL        -- OMS 23/Abril/2024
                           )RETURN VARCHAR2 IS

VL_ERROR             VARCHAR2(500);
Vm_Monto_Primer_Pago NUMBER;                        -- Monto del Primer Pago 26/Oct/2023

 BEGIN
   BEGIN
     -- Obtiene el primer pago: 26/Oct/2023
     Vm_Monto_Primer_Pago := P_MONTO_PRIMER_PAGO;
     IF p_observaciones IS NOT NULL THEN
        -- Se refiere a un pago escalonado
        Vm_Monto_Primer_Pago := TO_NUMBER (SUBSTR (p_Observaciones, 1, INSTR(p_Observaciones, ';')-1));
     END IF;

     INSERT
       INTO TZTBOOT
            (TZTBOOT_CAMP_CODE,
             TZTBOOT_LEVL_CODE,
             TZTBOOT_PIDM,
             TZTBOOT_ID,
             TZTBOOT_PROGRAM,
             TZTBOOT_TERM_CODE,
             TZTBOOT_START_DATE,
             TZTBOOT_CURR_CODE,
             TZTBOOT_DESCUENTO,
             TZTBOOT_AMOUNT,
             TZTBOOT_PRI_AMOUNT,
             TZTBOOT_NUM_TRAN,
             TZTBOOT_NUM_PAG,
             TZTBOOT_RATE_CODE,
             TZTBOOT_ATTS_CODE,
             TZTBOOT_ACTIVITY_DATE,
             TZTBOOT_ACTIVITY_UPDATE,
             TZTBOOT_USER,
             TZTBOOT_USER_UPDATE,
             TZTBOOT_DATA_ORIGIN,
             TZTBOOT_STATUS,
             TZTBOOT_FLAG,
             TZTBOOT_CUPON_DESC,
             TZTBOOT_CUPON,
             TZTBOOT_CODIGO,
             TZTBOOT_DURACION,
             TZTBOOT_PREGUNTA,
             TZTBOOT_MEDIO,
             TZTBOOT_OBSERVACIONES,

             TZTBOOT_pais_lada,       -- OMS 23/Abril/2024
             TZTBOOT_telefono         -- OMS 23/Abril/2024
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
             Vm_Monto_Primer_Pago,          --  P_MONTO_PRIMER_PAGO,  26/Oct/2023
             P_PAGOS_MAT,
             P_PAGOS_REGLA,
             P_RATE,
             P_JORNADA,
             SYSDATE,
             SYSDATE,
             USER,
             USER,
             P_ORIGEN,
             DECODE (P_CUPON_MONTO, 100, 'PAGADO', DECODE (Vm_Monto_Primer_Pago, 0, 'PAGADO', 'ACTIVO')),   -- OMS 23/Sep/2023 100% de Descuento
             0,
             P_CUPON_DESC,
             P_CUPON_MONTO,
             P_CODIGO,
             P_DURACION,
             P_PREGUNTA,
             P_MEDIO,
             DECODE (P_OBSERVACIONES, NULL, NULL, 'ESCALONADO: ' || P_OBSERVACIONES || ';'),
             
             p_pais_lada,       -- OMS 23/Abril/2024
             p_telefono         -- OMS 23/Abril/2024             
             );
   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:= 'Error al insertar en TZTBOOT = '||SQLERRM;
   END;

   IF VL_ERROR IS NULL THEN
    VL_ERROR:= 'EXITO';
    COMMIT;
   ELSE
    ROLLBACK;
   END IF;

   RETURN(VL_ERROR);

 END F_INSERT_TZTBOOT;



FUNCTION F_PAGOS_BOOTCAMP RETURN PKG_FINANZAS_BOOTCAMP.BOOTCAMP
AS
PAGOS_BOOT PKG_FINANZAS_BOOTCAMP.BOOTCAMP;

 BEGIN
   BEGIN
    OPEN PAGOS_BOOT
     FOR
             SELECT MATRICULA,
                    PERIODO,
                    FECHA_INICIO,
                    FECHA_INSCRIP,
                    FECHA_VIGENCIA,
                    PARCIALIDAD,
                    BALANCE,
                    ALUMNO,
                    CASE
                      WHEN BALANCE = 0 THEN 'PAGADO'
                      WHEN BALANCE > 0 AND FECHA_VIGENCIA < TRUNC(SYSDATE) AND PARCIALIDAD = BALANCE THEN 'VENCIDO'
                      WHEN BALANCE > 0 AND FECHA_VIGENCIA < TRUNC(SYSDATE) AND PARCIALIDAD != BALANCE THEN 'PAGO PARCIAL VENCIDO'
                      WHEN BALANCE > 0 AND FECHA_VIGENCIA >= TRUNC(SYSDATE) AND PARCIALIDAD = BALANCE THEN 'PENDIENTE DE PAGO'
                      WHEN BALANCE > 0 AND FECHA_VIGENCIA >= TRUNC(SYSDATE) AND PARCIALIDAD != BALANCE THEN 'PAGO PARCIAL'
                    END ESTADO
               FROM ( SELECT TZTBOOT_ID MATRICULA,
                             TZTBOOT_PIDM PIDM,
                             TZTBOOT_TERM_CODE PERIODO,
                             TRUNC(TZTBOOT_START_DATE)FECHA_INICIO,
                             TRUNC(TZTBOOT_ACTIVITY_DATE)FECHA_INSCRIP,
                             TRUNC(TZTBOOT_START_DATE)FECHA_VIGENCIA,
                             TZTBOOT_PRI_AMOUNT PARCIALIDAD,
                             0 BALANCE,
                             TZTBOOT_STATUS STATUS,
                             TZTBOOT_FLAG,
                             'NUEVO INGRESO' ALUMNO
                        FROM TZTBOOT
                       WHERE     TZTBOOT_STATUS = 'PAGADO'
                             AND TZTBOOT_FLAG = 0
                       UNION
                      SELECT TZTBOOT_ID MATRICULA,
                             TZTBOOT_PIDM PIDM,
                             TZTBOOT_TERM_CODE PERIODO,
                             TRUNC(TZTBOOT_START_DATE)FECHA_INICIO,
                             TRUNC(TZTBOOT_ACTIVITY_DATE)FECHA_INSCRIP,
                             TBRACCD_EFFECTIVE_DATE FECHA_VIGENCIA,
                             TZTBOOT_PRI_AMOUNT PARCIALIDAD,
                             TBRACCD_BALANCE BALANCE,
                             'PENDIENTE DE PAGO' STATUS,
                             TZTBOOT_FLAG,
                             'CONTINUO' ALUMNO
                        FROM TZTBOOT A,TBRACCD B
                       WHERE     A.TZTBOOT_PIDM = B.TBRACCD_PIDM
                             AND LAST_DAY(TRUNC(B.TBRACCD_EFFECTIVE_DATE)) <= LAST_DAY(TRUNC(SYSDATE))
                             AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                             FROM TBBDETC
                                                            WHERE TBBDETC_DCAT_CODE = 'COL')
                             AND A.TZTBOOT_STATUS = 'PAGADO'
                             AND A.TZTBOOT_FLAG = 1
                             AND (    B.TBRACCD_CROSSREF_PIDM = 1
                                  AND B.TBRACCD_BALANCE = 0
                                   OR B.TBRACCD_CROSSREF_PIDM IS NULL
                                  )
                             AND (SELECT SUM(TBRACCD_BALANCE)
                                    FROM TBRACCD
                                   WHERE TBRACCD_PIDM = A.TZTBOOT_PIDM
                                   AND LAST_DAY(TRUNC(TBRACCD_EFFECTIVE_DATE)) <= LAST_DAY(TRUNC(SYSDATE)))>0)BOOT
              WHERE 1=1;

     BEGIN
       FOR X IN (
                  SELECT TZTBOOT_ID MATRICULA,
                         TZTBOOT_PIDM PIDM,
                         0 NUM,
                         TZTBOOT_TERM_CODE PERIODO,
                         TRUNC(TZTBOOT_START_DATE)FECHA_INICIO,
                         TRUNC(TZTBOOT_ACTIVITY_DATE)FECHA_INSCRIP,
                         TRUNC(TZTBOOT_START_DATE)FECHA_VIGENCIA,
                         TZTBOOT_PRI_AMOUNT PARCIALIDAD,
                         0 BALANCE,
                         TZTBOOT_STATUS STATUS,
                         TZTBOOT_FLAG,
                         'NUEVO INGRESO' ALUMNO
                    FROM TZTBOOT
                   WHERE     TZTBOOT_STATUS = 'PAGADO'
                         AND TZTBOOT_FLAG = 0
                   UNION
                  SELECT TZTBOOT_ID MATRICULA,
                         TZTBOOT_PIDM PIDM,
                         TBRACCD_TRAN_NUMBER NUM,
                         TZTBOOT_TERM_CODE PERIODO,
                         TRUNC(TZTBOOT_START_DATE)FECHA_INICIO,
                         TRUNC(TZTBOOT_ACTIVITY_DATE)FECHA_INSCRIP,
                         TBRACCD_EFFECTIVE_DATE FECHA_VIGENCIA,
                         TZTBOOT_PRI_AMOUNT PARCIALIDAD,
                         TBRACCD_BALANCE BALANCE,
                         'PENDIENTE DE PAGO' STATUS,
                         TZTBOOT_FLAG,
                         'CONTINUO' ALUMNO
                    FROM TZTBOOT A,TBRACCD B
                   WHERE     A.TZTBOOT_PIDM = B.TBRACCD_PIDM
                         AND LAST_DAY(TRUNC(B.TBRACCD_EFFECTIVE_DATE)) <= LAST_DAY(TRUNC(SYSDATE))
                         AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                         FROM TBBDETC
                                                        WHERE TBBDETC_DCAT_CODE = 'COL')
                         AND A.TZTBOOT_STATUS = 'PAGADO'
                         AND A.TZTBOOT_FLAG = 1
                         AND (    B.TBRACCD_CROSSREF_PIDM = 1
                              AND B.TBRACCD_BALANCE = 0
                               OR B.TBRACCD_CROSSREF_PIDM IS NULL
                              )
                         AND (SELECT SUM(TBRACCD_BALANCE)
                                FROM TBRACCD
                               WHERE TBRACCD_PIDM = A.TZTBOOT_PIDM
                               AND LAST_DAY(TRUNC(TBRACCD_EFFECTIVE_DATE)) <= LAST_DAY(TRUNC(SYSDATE)))>0
       )LOOP

         IF X.ALUMNO = 'NUEVO INGRESO' THEN
           BEGIN
             UPDATE TZTBOOT
                SET TZTBOOT_FLAG = 1
              WHERE     TZTBOOT_STATUS = 'PAGADO'
                    AND TZTBOOT_FLAG = 0
                    AND TZTBOOT_PIDM = X.PIDM
                    AND TRUNC(TZTBOOT_START_DATE) = X.FECHA_INICIO;
           END;
         END IF;

         IF X.BALANCE = 0 AND X.NUM != 0 THEN
           BEGIN
             UPDATE TBRACCD
                SET TBRACCD_CROSSREF_PIDM = 2
              WHERE     TBRACCD_PIDM = X.PIDM
                    AND TBRACCD_TRAN_NUMBER = X.NUM;
           END;

         ELSIF X.BALANCE !=0 THEN
           BEGIN
             UPDATE TBRACCD
                SET TBRACCD_CROSSREF_PIDM = 1
              WHERE     TBRACCD_PIDM = X.PIDM
                    AND TBRACCD_TRAN_NUMBER = X.NUM;
           END;
         END IF;

       END LOOP;
      COMMIT;
     END;

    RETURN (PAGOS_BOOT);
   END;

 END F_PAGOS_BOOTCAMP;

PROCEDURE P_CANCELA_BOOT IS
---------------- JOB para cancelar cartera en TVAAREV
---------------- para matriculas de BOOTCAMP al no realizar pago
---------------- AUTOR: JREZAOLI
---------------- ACTUALIZACION : 20/02/2019

VTRAN_MAX       NUMBER;
VL_PAGO         NUMBER;
VL_ERROR        VARCHAR2(500):= NULL;
VL_VIG          NUMBER;
VL_VIGENCIA_COL DATE;

 BEGIN

   BEGIN
     SELECT ZSTPARA_PARAM_VALOR
       INTO VL_VIG
       FROM ZSTPARA
      WHERE ZSTPARA_MAPA_ID = 'BOOT_VIG_PAGO';
   EXCEPTION
   WHEN OTHERS THEN
   VL_VIG:=0;
   END;

   BEGIN
     FOR BOOT IN (
                    SELECT DISTINCT
                           TZTBOOT_ID MATRICULA,
                           TBRACCD_PIDM PIDM,
                           TBRACCD_FEED_DATE FECHA_INICIO,
                           TZTBOOT_START_DATE
                      FROM TBRACCD A LEFT JOIN TZTBOOT ON A.TBRACCD_PIDM = TZTBOOT_PIDM
                                                      AND A.TBRACCD_FEED_DATE = TZTBOOT_START_DATE
                     WHERE     TZTBOOT_STATUS != 'CANCELADO'
                           AND A.TBRACCD_TERM_CODE LIKE '40%'
                           AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                           FROM TBBDETC
                                                          WHERE     TBBDETC_DCAT_CODE = 'COL'
                                                                AND SUBSTR (TBBDETC_DETAIL_CODE,1,3) = SUBSTR (A.TBRACCD_DETAIL_CODE, 1, 2)||'N'
                                                                AND TBBDETC_DETC_ACTIVE_IND = 'Y')
                           AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
--                           AND A.TBRACCD_PIDM IN (324152,322452,317498,318694,318873,319003,319050)
                           AND A.TBRACCD_PIDM NOT IN (SELECT B.TBRACCD_PIDM
                                                        FROM TBRACCD B
                                                       WHERE     B.TBRACCD_PIDM = A.TBRACCD_PIDM
                                                             AND B.TBRACCD_BALANCE != TBRACCD_AMOUNT
                                                             AND B.TBRACCD_TRAN_NUMBER = (SELECT MIN(TBRACCD_TRAN_NUMBER)
                                                                                            FROM TBRACCD
                                                                                          WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                                                                                AND TBRACCD_FEED_DATE =A.TBRACCD_FEED_DATE))
                     ORDER BY 3

     )LOOP

       BEGIN
         SELECT COUNT(*)
           INTO VL_PAGO
           FROM TBRACCD,TBBDETC
          WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                AND TBBDETC_DCAT_CODE = 'CSH'
                AND TBRACCD_PIDM = BOOT.PIDM;
       END;

       IF VL_PAGO = 0 THEN

         IF (BOOT.FECHA_INICIO+VL_VIG) < TRUNC(SYSDATE) THEN

           BEGIN
             FOR PARCIALIDADES  IN (

                               SELECT  TBRACCD_PIDM,
                                       TBRACCD_TRAN_NUMBER,
                                       TBRACCD_TERM_CODE,
                                       TBRACCD_DETAIL_CODE,
                                       TBRACCD_AMOUNT,
                                       TBRACCD_BALANCE,
                                       TBRACCD_DESC,
                                       TBRACCD_USER,
                                       TBRACCD_ENTRY_DATE,
                                       TBRACCD_EFFECTIVE_DATE,
                                       TBRACCD_SRCE_CODE,
                                       TBRACCD_ACCT_FEED_IND,
                                       TBRACCD_ACTIVITY_DATE,
                                       TBRACCD_SESSION_NUMBER,
                                       TBRACCD_SURROGATE_ID,
                                       TBRACCD_VERSION,
                                       TBRACCD_STSP_KEY_SEQUENCE,
                                       TBRACCD_PERIOD,
                                       TBRACCD_FEED_DATE,
                                       TBRACCD_RECEIPT_NUMBER
                              FROM TBRACCD A
                              WHERE A.TBRACCD_PIDM = BOOT.PIDM
                              AND A.TBRACCD_FEED_DATE = BOOT.FECHA_INICIO
                              AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                          FROM TBBDETC
                                                          WHERE TBBDETC_DCAT_CODE = 'COL'
                                                          AND SUBSTR (TBBDETC_DETAIL_CODE,1,3) = SUBSTR (A.TBRACCD_DETAIL_CODE, 1, 2)||'N'
                                                          AND TBBDETC_DETC_ACTIVE_IND = 'Y')
                              AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
              )LOOP

                DBMS_OUTPUT.PUT_LINE('1');

                VL_ERROR:= NULL;
                VL_VIGENCIA_COL:= NULL;

                BEGIN
                  UPDATE TBRACCD
                     SET TBRACCD_TRAN_NUMBER_PAID = NULL
                  WHERE     TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                        AND TBRACCD_TRAN_NUMBER_PAID = PARCIALIDADES.TBRACCD_TRAN_NUMBER;
                END;

                BEGIN

                  SELECT MAX(TBRACCD_TRAN_NUMBER)+1
                  INTO  VTRAN_MAX
                  FROM TBRACCD
                  WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM ;

                END;

                DBMS_OUTPUT.PUT_LINE('2');
                  -------------------este es la desaplicacion de pagos--------

               PKG_FINANZAS.P_DESAPLICA_PAGOS (PARCIALIDADES.TBRACCD_PIDM, PARCIALIDADES.TBRACCD_TRAN_NUMBER);

               IF PARCIALIDADES.TBRACCD_EFFECTIVE_DATE <= TRUNC(SYSDATE) THEN
                   VL_VIGENCIA_COL:= TRUNC(SYSDATE);
               ELSE
                   VL_VIGENCIA_COL:= PARCIALIDADES.TBRACCD_EFFECTIVE_DATE;
               END IF;

                BEGIN

                      INSERT
                      INTO TBRACCD
                           (TBRACCD_PIDM,
                            TBRACCD_TRAN_NUMBER,
                            TBRACCD_TERM_CODE,
                            TBRACCD_DETAIL_CODE,
                            TBRACCD_AMOUNT,
                            TBRACCD_BALANCE,
                            TBRACCD_DESC,
                            TBRACCD_USER,
                            TBRACCD_ENTRY_DATE,
                            TBRACCD_EFFECTIVE_DATE,
                            TBRACCD_TRANS_DATE,
                            TBRACCD_SRCE_CODE,
                            TBRACCD_ACCT_FEED_IND,
                            TBRACCD_ACTIVITY_DATE,
                            TBRACCD_SESSION_NUMBER,
                            TBRACCD_SURROGATE_ID,
                            TBRACCD_VERSION,
                            TBRACCD_TRAN_NUMBER_PAID,
                            TBRACCD_FEED_DATE,
                            TBRACCD_STSP_KEY_SEQUENCE,
                            TBRACCD_DATA_ORIGIN,
                            TBRACCD_PERIOD,
                            TBRACCD_RECEIPT_NUMBER  )
                       VALUES(PARCIALIDADES.TBRACCD_PIDM,
                              VTRAN_MAX,
                              PARCIALIDADES.TBRACCD_TERM_CODE ,
                              SUBSTR(PARCIALIDADES.TBRACCD_TERM_CODE,1,2)||'TL',
                              PARCIALIDADES.TBRACCD_AMOUNT,
                              PARCIALIDADES.TBRACCD_AMOUNT*-1 ,
                              'CANCELACION PLAN BOOTCAMP VPN',
                              USER,
                              SYSDATE,
                              VL_VIGENCIA_COL,
                              VL_VIGENCIA_COL,
                              PARCIALIDADES.TBRACCD_SRCE_CODE,
                              PARCIALIDADES.TBRACCD_ACCT_FEED_IND,
                              PARCIALIDADES.TBRACCD_ACTIVITY_DATE,
                              0,
                              NULL,
                              NULL,
                              PARCIALIDADES.TBRACCD_TRAN_NUMBER,
                              PARCIALIDADES.TBRACCD_FEED_DATE,
                              PARCIALIDADES.TBRACCD_STSP_KEY_SEQUENCE,
                              'CAN_BOOT',
                              PARCIALIDADES.TBRACCD_PERIOD,
                              PARCIALIDADES.TBRACCD_RECEIPT_NUMBER  );

                              DBMS_OUTPUT.PUT_LINE('3');

                END;

                BEGIN
                  UPDATE TBRACCD
                     SET TBRACCD_DOCUMENT_NUMBER = 'CAN_BOOT',
                         TBRACCD_ACTIVITY_DATE  = SYSDATE
                   WHERE     TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                         AND TBRACCD_TRAN_NUMBER IN (PARCIALIDADES.TBRACCD_TRAN_NUMBER,VTRAN_MAX);
                END;

              END LOOP;

           END;

           BEGIN
             UPDATE TZTBOOT
                SET TZTBOOT_STATUS = 'CANCELADO'
              WHERE     TZTBOOT_PIDM = BOOT.PIDM
                    AND TZTBOOT_START_DATE = BOOT.FECHA_INICIO;
           END;

         END IF;

       END IF;

     END LOOP;

   END;

  COMMIT;

 END P_CANCELA_BOOT;

FUNCTION F_BITA_PAGOS (P_TIPO_ALUMNO VARCHAR2,
                       P_BALANCE     NUMBER,
                       P_MATRICULA   VARCHAR2,
                       P_VIGENCIA    DATE,
                       P_ERROR       VARCHAR2
                       ) RETURN VARCHAR2 IS

VL_ERROR        VARCHAR2(500):= 'EXITO';

  BEGIN

    IF P_TIPO_ALUMNO = 'NUEVO INGRESO' THEN
      BEGIN
        UPDATE TZTBOOT
           SET TZTBOOT_FLAG = 1
         WHERE     TZTBOOT_STATUS = 'PAGADO'
               AND TZTBOOT_FLAG = 0
               AND TZTBOOT_PIDM = FGET_PIDM(P_MATRICULA)
               AND TRUNC(TZTBOOT_START_DATE) = P_VIGENCIA;

      EXCEPTION
      WHEN OTHERS THEN
      VL_ERROR:='ERROR 1 = '||SQLERRM;
      END;

    ELSIF P_ERROR IS NOT NULL THEN

      BEGIN
        UPDATE TZTBOOT
           SET TZTBOOT_OBSERVACIONES = P_ERROR
         WHERE     TZTBOOT_STATUS = 'PAGADO'
               AND TZTBOOT_PIDM = FGET_PIDM(P_MATRICULA);
      EXCEPTION
      WHEN OTHERS THEN
      VL_ERROR:='ERROR 2 = '||SQLERRM;
      END;

    END IF;

    IF P_BALANCE = 0 THEN

      BEGIN
        UPDATE TBRACCD
           SET TBRACCD_CROSSREF_PIDM = 2
         WHERE     TBRACCD_PIDM = FGET_PIDM(P_MATRICULA)
               AND TBRACCD_EFFECTIVE_DATE = P_VIGENCIA;
      EXCEPTION
      WHEN OTHERS THEN
      VL_ERROR:='ERROR 3 = '||SQLERRM;
      END;

      BEGIN
        UPDATE TZTBOOT
           SET TZTBOOT_OBSERVACIONES = NULL
         WHERE     TZTBOOT_STATUS = 'PAGADO'
               AND TZTBOOT_PIDM = FGET_PIDM(P_MATRICULA);
      EXCEPTION
      WHEN OTHERS THEN
      VL_ERROR:='ERROR 4 = '||SQLERRM;
      END;

    ELSIF P_BALANCE !=0 THEN

      BEGIN
        UPDATE TBRACCD
           SET TBRACCD_CROSSREF_PIDM = 1
         WHERE     TBRACCD_PIDM = FGET_PIDM(P_MATRICULA)
               AND TBRACCD_EFFECTIVE_DATE = P_VIGENCIA;
      EXCEPTION
      WHEN OTHERS THEN
      VL_ERROR:='ERROR 5 = '||SQLERRM;
      END;

      BEGIN
        UPDATE TZTBOOT
           SET TZTBOOT_OBSERVACIONES = NULL
         WHERE     TZTBOOT_STATUS = 'PAGADO'
               AND TZTBOOT_PIDM = FGET_PIDM(P_MATRICULA);
      EXCEPTION
      WHEN OTHERS THEN
      VL_ERROR:='ERROR 6 = '||SQLERRM;
      END;
    END IF;

    IF SQL%ROWCOUNT = 0 THEN
      VL_ERROR:= 'NO ACTUALIZO';
    END IF;

    COMMIT;

    RETURN(VL_ERROR);
  END F_BITA_PAGOS;

FUNCTION F_VALIDA_UPSELLING (P_PIDM NUMBER, pseqno number )RETURN VARCHAR2 IS

VL_ERROR        VARCHAR2(900);
VL_ENTRA        NUMBER;
VL_SECUENCIA    NUMBER:=0;
VL_CODIGO       VARCHAR2(5);
VL_DESCRI       VARCHAR2(40);
VL_MONTO        NUMBER;
-- se grega nuevo parametro es el numero de seqno para insertar en tbraccd y tener la trza completa cambio glovicx 29/11/2021---se modifica la salida RETURN


 BEGIN

   BEGIN
     SELECT COUNT(*)
       INTO VL_ENTRA
       FROM TBRACCD
      WHERE TBRACCD_PIDM = P_PIDM
      AND TBRACCD_FEED_DATE IN (SELECT DISTINCT TRUNC(SZTALOL_FECHA_INICIO)
                                    FROM SZTALOL M
                                    WHERE M.SZTALOL_PIDM = P_PIDM
                                    AND M.SZTALOL_ESTATUS = 'A'
                                    AND M.SZTALOL_FECHA_INICIO = (SELECT MAX(SZTALOL_FECHA_INICIO)
                                                                    FROM SZTALOL
                                                                   WHERE     SZTALOL_PIDM = M.SZTALOL_PIDM
                                                                         AND SZTALOL_ESTATUS = 'A'))
      AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)';
   END;
DBMS_OUTPUT.PUT_LINE('ANTES ='||VL_ENTRA);
   IF VL_ENTRA = 0 THEN
     VL_ERROR:= 'EXITO';
   ELSE

     VL_ERROR:= 'EXITO';

     BEGIN
       FOR UPSE IN (
                       SELECT *
                         FROM TBRACCD
                        WHERE     TBRACCD_PIDM = P_PIDM
                              AND TBRACCD_FEED_DATE =  (SELECT TRUNC(SZTALOL_FECHA_INICIO)
                                                            FROM SZTALOL M
                                                            WHERE M.SZTALOL_PIDM = P_PIDM
                                                            AND M.SZTALOL_ESTATUS = 'A'
                                                            AND M.SZTALOL_FECHA_INICIO = (SELECT MAX(SZTALOL_FECHA_INICIO)
                                                                                            FROM SZTALOL
                                                                                           WHERE     SZTALOL_PIDM = M.SZTALOL_PIDM
                                                                                                 AND SZTALOL_ESTATUS = 'A'))
                              AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                              AND TBRACCD_DOCUMENT_NUMBER IS NULL
       )LOOP

       DBMS_OUTPUT.PUT_LINE('ECURSOR ='||UPSE.TBRACCD_TRAN_NUMBER);

         BEGIN
           SELECT MAX(TBRACCD_TRAN_NUMBER)+1
             INTO VL_SECUENCIA
             FROM TBRACCD WHERE TBRACCD_PIDM = P_PIDM;
         END;

         IF SUBSTR(UPSE.TBRACCD_PERIOD,1,1) = 'L' THEN
           VL_CODIGO:= SUBSTR(UPSE.TBRACCD_TERM_CODE,1,2)||'SY';
         ELSIF SUBSTR(UPSE.TBRACCD_PERIOD,1,1) = 'M' THEN
           VL_CODIGO:= SUBSTR(UPSE.TBRACCD_TERM_CODE,1,2)||'TJ';
         END IF;

         BEGIN
           SELECT TBBDETC_DESC,TBBDETC_AMOUNT
             INTO VL_DESCRI,VL_MONTO
             FROM TBBDETC
            WHERE TBBDETC_DETAIL_CODE = VL_CODIGO;
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR:='ERROR AL RECUPERAR CODIGO DETALLE = '||SQLERRM;
         END;

         BEGIN
           INSERT
             INTO TBRACCD (  TBRACCD_PIDM
                           , TBRACCD_TRAN_NUMBER
                           , TBRACCD_TRAN_NUMBER_PAID
                           , TBRACCD_TERM_CODE
                           , TBRACCD_DETAIL_CODE
                           , TBRACCD_USER
                           , TBRACCD_ENTRY_DATE
                           , TBRACCD_AMOUNT
                           , TBRACCD_BALANCE
                           , TBRACCD_EFFECTIVE_DATE
                           , TBRACCD_FEED_DATE
                           , TBRACCD_DESC
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
                           , TBRACCD_RECEIPT_NUMBER
                           , TBRACCD_CROSSREF_NUMBER)
           VALUES(P_PIDM,                                   -- TBRACCD_PIDM
                  VL_SECUENCIA,                             -- TBRACCD_TRAN_NUMBER
                  NULL,                                     -- TBRACCD_TRAN_NUMBER_PAID
                  UPSE.TBRACCD_TERM_CODE,                   -- TBRACCD_TERM_CODE
                  VL_CODIGO,                                -- TBRACCD_DETAIL_CODE
                  USER,                                     -- TBRACCD_USER
                  SYSDATE,                                  -- TBRACCD_ENTRY_DATE
                  NVL(ROUND(VL_MONTO),0),                   -- TBRACCD_AMOUNT
                  NVL(ROUND(VL_MONTO),0),                   -- TBRACCD_BALANCE
                  UPSE.TBRACCD_EFFECTIVE_DATE,              -- TBRACCD_EFFECTIVE_DATE
                  UPSE.TBRACCD_FEED_DATE,                   -- TBRACCD_FEED_DATE
                  VL_DESCRI,                                -- TBRACCD_DESC
                  'T',                                      -- TBRACCD_SRCE_CODE
                  'Y',                                      -- TBRACCD_ACCT_FEED_IND
                  SYSDATE,                                  -- TBRACCD_ACTIVITY_DATE
                  0,                                        -- TBRACCD_SESSION_NUMBER
                  UPSE.TBRACCD_EFFECTIVE_DATE,              -- TBRACCD_TRANS_DATE
                  'MXN',                                    -- TBRACCD_CURR_CODE
                  'TZFEDCA (ACC)',                          -- TBRACCD_DATA_ORIGIN
                  'TZFEDCA (ACC)',                          -- TBRACCD_CREATE_SOURCE
                  UPSE.TBRACCD_STSP_KEY_SEQUENCE,           -- TBRACCD_STSP_KEY_SEQUENCE
                  UPSE.TBRACCD_PERIOD,                      -- TBRACCD_PERIOD
                  USER,                                     -- TBRACCD_USER_ID
                  UPSE.TBRACCD_RECEIPT_NUMBER               -- TBRACCD_RECEIPT_NUMBER
                  ,pseqno                                   --TBRACCD_CROSSREF_NUMBER
                   );
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR :='Error al insertar en TBRACCD'||SQLERRM;
         END;

       END LOOP;

     END;

   END IF;

   COMMIT;

   RETURN(VL_ERROR||'|'||VL_SECUENCIA);

 END F_VALIDA_UPSELLING;

FUNCTION F_STATUS_UPSELLING(P_PIDM NUMBER,P_USER VARCHAR2)RETURN VARCHAR2 IS

VL_ERROR VARCHAR2 (200);


BEGIN

     BEGIN
        UPDATE SZTALOL
           SET SZTALOL_ESTATUS = 'I',
               SZTALOL_FECHA_INSERTO=SYSDATE,
               SZTALOL_USUARIO = P_USER
         WHERE     SZTALOL_PIDM=P_PIDM
         AND   SZTALOL_ESTATUS = 'A';

     END;

     IF SQL%ROWCOUNT=0THEN
     VL_ERROR:='SIN ACTUALIZAR';
     ELSE
     VL_ERROR:='EXITO';
     END IF;
         COMMIT; RETURN (VL_ERROR);
END F_STATUS_UPSELLING;

FUNCTION F_DECISION_AUTOM (P_PIDM NUMBER, P_SOLICITUD NUMBER)RETURN VARCHAR2 IS

VL_ERROR            VARCHAR2(900);
LV_MSG_TYPE         VARCHAR2(900);
LV_MSG              VARCHAR2(900);
LV_BATCH_MSG        VARCHAR2(900);



 BEGIN
  FOR X IN (
            SELECT SARADAP_PIDM,
                   SARADAP_TERM_CODE_ENTRY,
                   SARADAP_APPL_NO
              FROM SARADAP
             WHERE     SARADAP_PIDM = P_PIDM
                   AND SARADAP_APPL_NO = P_SOLICITUD
   )LOOP

     BEGIN
       SAKDCSN.P_PROCESS_DECSN(
                               P_PIDM              => X.SARADAP_PIDM,
                               P_TERM_CODE         => X.SARADAP_TERM_CODE_ENTRY,
                               P_APPL_NO           => X.SARADAP_APPL_NO,
                               P_APDC_CODE         => 35,
                               P_SELF_SERVICE      => 'N',
                               P_FATAL_ALLOWED     => 'Y',  --Since called from a form
                               P_COMMPLAN_IND      => 'N',  --Do not create comm plan recs
                               P_MSG_TYPE_OUT      => LV_MSG_TYPE,
                               P_MSG_OUT           => LV_MSG,
                               P_BATCH_MSG_OUT     => LV_BATCH_MSG,
                               P_MAINT_IND         => 'U',
                               P_APDC_DATE         => SYSDATE,
                               P_SCPC_CODE         => NULL);
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR P_PROCESS_DECSN = '||SQLERRM;
     END;

     BEGIN
       UPDATE TZTSNOR
          SET TZTSNOR_FLAG = 1
         WHERE TZTSNOR_PIDM = P_PIDM
         AND TZTSNOR_SOLICITUD = P_SOLICITUD;
     END;

   END LOOP;

   DBMS_OUTPUT.PUT_LINE('FINAL AUTOM DECISION 35 = '||VL_ERROR);

   IF VL_ERROR IS NULL THEN
     VL_ERROR:='EXITO';
     COMMIT;
   ELSE
     ROLLBACK;
   END IF;
  RETURN (VL_ERROR);
 END F_DECISION_AUTOM;

 FUNCTION F_INS_SENIOR (P_PIDM       NUMBER,
                        P_PROGRAMA   VARCHAR2,
                        P_PERIODO    VARCHAR2,
                        P_FECHA_INI  DATE,
                        P_PARTE_PER  VARCHAR2,
                        P_SOLICITUD  NUMBER,
                        P_MONTO      NUMBER,
                        P_NUM_PARC   NUMBER,
                        P_JORNADA    VARCHAR2)RETURN VARCHAR2 IS

VL_ERROR    VARCHAR2(900);
VL_CONTADOR NUMBER:=0;

 BEGIN

          BEGIN
                    Select count(1)
                    Into VL_CONTADOR
                    from TZTSNOR
                    where  TZTSNOR_PIDM =  P_PIDM;
          Exception
          When others then
            VL_CONTADOR:=0;
         End;

  VL_CONTADOR := VL_CONTADOR + 1;

   BEGIN
     INSERT
       INTO TZTSNOR
           (TZTSNOR_PIDM,
            TZTSNOR_PROGRAM,
            TZTSNOR_TERM_CODE,
            TZTSNOR_START_DATE,
            TZTSNOR_PTRM_CODE,
            TZTSNOR_SOLICITUD,
            TZTSNOR_AMOUNT,
            TZTSNOR_NUM_PAG,
            TZTSNOR_ATTS_CODE,
            TZTSNOR_ACTIVITY_DATE,
            TZTSNOR_ACTIVITY_UPDATE,
            TZTSNOR_USER,
            TZTSNOR_USER_UPDATE,
            TZTSNOR_DATA_ORIGIN)
     VALUES(P_PIDM,
            P_PROGRAMA,
            P_PERIODO,
            P_FECHA_INI,
            P_PARTE_PER,
            VL_CONTADOR,
            P_MONTO,
            P_NUM_PARC,
            P_JORNADA,
            SYSDATE,
            SYSDATE,
            USER,
            USER,
            'SENIOR');

     VL_ERROR:='EXITO';

   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:='ERROR AL INSERTAR = '||SQLERRM;
   END;
  COMMIT;
  RETURN(VL_ERROR);
 END F_INS_SENIOR;

FUNCTION CANCE_BOOT_CAMP (P_PIDM NUMBER, P_CODIGO VARCHAR2, P_INICIO DATE, P_USUARIO VARCHAR2) RETURN VARCHAR2 IS

VL_TRAN_NUM      NUMBER:= 1;
VL_APLICA        VARCHAR2(10);
VL_ERROR         VARCHAR2(900);
VL_SECUENCIA     NUMBER;
VL_CODE_CANCE    VARCHAR2(10);
VL_DESC          VARCHAR2(50);
VL_MONEDA        VARCHAR2(3);

  BEGIN

        FOR X IN (

            SELECT A.*,
            (SELECT COUNT(*)
                      FROM TBRACCD A1
              WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                    AND A1.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                    AND SUBSTR(A1.TBRACCD_DETAIL_CODE,3,2)= P_CODIGO
                    AND A1.TBRACCD_FEED_DATE = P_INICIO
                    AND A1.TBRACCD_EFFECTIVE_DATE = A.TBRACCD_EFFECTIVE_DATE
                    AND A1.TBRACCD_BALANCE = A1.TBRACCD_AMOUNT) CARGOS
       FROM TBRACCD A
        WHERE     TBRACCD_PIDM = P_PIDM
              AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_BALANCE = TBRACCD_AMOUNT
              AND SUBSTR(TBRACCD_DETAIL_CODE,3,2)= P_CODIGO
              AND TBRACCD_EFFECTIVE_DATE >= TRUNC(SYSDATE)
              AND TBRACCD_FEED_DATE = P_INICIO

    )LOOP

    VL_TRAN_NUM   := NULL;
    VL_APLICA     := NULL;
    VL_ERROR      := NULL;
    VL_SECUENCIA  := NULL;
    VL_CODE_CANCE := NULL;
    VL_DESC       := NULL;
    VL_MONEDA     := NULL;

      BEGIN
         SELECT ZSTPARA_PARAM_VALOR,TBBDETC_DESC,TVRDCTX_CURR_CODE
             INTO VL_CODE_CANCE,VL_DESC,VL_MONEDA
             FROM ZSTPARA,TBBDETC,TVRDCTX
            WHERE     ZSTPARA_PARAM_ID = X.TBRACCD_CURR_CODE
                  AND ZSTPARA_PARAM_VALOR = TBBDETC_DETAIL_CODE
                  AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE
                  AND ZSTPARA_MAPA_ID = 'CANC_DIV_BOOT';
      EXCEPTION
      WHEN OTHERS THEN
      VL_ERROR:= 'ERROR AL CALCULAR CODIGO';
      END;


      FOR I IN 1..X.CARGOS LOOP


        IF VL_TRAN_NUM = 1 AND TO_CHAR(TRUNC(SYSDATE),'DD') < 20 THEN VL_APLICA:= 'APLICA';

         ELSE VL_APLICA:= 'APLICA';

        END IF;

        VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (P_PIDM);

        IF VL_APLICA = 'APLICA' THEN


          BEGIN

            INSERT
              INTO TBRACCD
            VALUES ( X.TBRACCD_PIDM,                 -- TBRACCD_PIDM
                     VL_SECUENCIA,                   -- TBRACCD_TRAN_NUMBER
                     X.TBRACCD_TERM_CODE,            -- TBRACCD_TERM_CODE
                     VL_CODE_CANCE,                   -- TBRACCD_DETAIL_CODE
                     P_USUARIO,                           -- TBRACCD_USER
                     SYSDATE,                        -- TBRACCD_ENTRY_DATE
                     NVL(X.TBRACCD_AMOUNT,0),        -- TBRACCD_AMOUNT
                     NVL(X.TBRACCD_AMOUNT,0)* -1,   -- TBRACCD_BALANCE
                     TO_DATE(TRUNC(SYSDATE),'DD/MM/RRRR'),  -- TBRACCD_EFFECTIVE_DATE
                     NULL,                           -- TBRACCD_BILL_DATE
                     NULL,                           -- TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                     VL_DESC,                        -- TBRACCD_DESC
                     X.TBRACCD_RECEIPT_NUMBER,       -- TBRACCD_RECEIPT_NUMBER
                     X.TBRACCD_TRAN_NUMBER,          -- TBRACCD_TRAN_NUMBER_PAID
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
                     X.TBRACCD_FEED_DATE,            -- TBRACCD_FEED_DATE
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
                     X.TBRACCD_STSP_KEY_SEQUENCE,    -- TBRACCD_STSP_KEY_SEQUENCE
                     X.TBRACCD_PERIOD,               -- TBRACCD_PERIOD
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
           WHERE TBRACCD_PIDM = X.TBRACCD_PIDM
                 AND TBRACCD_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER;

           UPDATE TVRACCD
              SET TVRACCD_DOCUMENT_NUMBER = 'CANCE'
           WHERE TVRACCD_PIDM = X.TBRACCD_PIDM
                 AND TVRACCD_ACCD_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER;

           UPDATE TZTBOOT
              SET TZTBOOT_STATUS = 'CANCELADO'
            WHERE TZTBOOT_PIDM = X.TBRACCD_PIDM
                  AND TZTBOOT_START_DATE  = X.TBRACCD_FEED_DATE;
        END IF;

      END LOOP;

    END LOOP;

    IF VL_ERROR IS NULL THEN
          VL_ERROR:= 'EXITO';
    END IF;

   COMMIT;
--     DBMS_OUTPUT.PUT_LINE('SALIDA ='||VL_ERROR);
   RETURN(VL_ERROR);

  END CANCE_BOOT_CAMP;

FUNCTION F_CURSOR_DATOS_BOOTCAMP (P_PIDM IN NUMBER ) RETURN PKG_FINANZAS_BOOTCAMP.CURSOR_DATOS_BOOTCAMP AS
DATOS_BOOTCAMP PKG_FINANZAS_BOOTCAMP.CURSOR_DATOS_BOOTCAMP;

/*CURSOR RETORNA DATOS DE ALUMNO CON LA CONDICION DE EXISTIR EN TBRACCD SIN CANCELACION*/
VL_ID     VARCHAR2(12);


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
      OPEN DATOS_BOOTCAMP
       FOR
          SELECT TZTBOOT_PIDM       PIDM,
                 TZTBOOT_PROGRAM    PROGRAMA,
                 TZTBOOT_START_DATE INICIO,
                 TZTBOOT_STATUS     STATUS
          FROM TZTBOOT
         WHERE   TZTBOOT_STATUS NOT IN ('CANCELADO','ACTIVO')
                 AND SUBSTR(TZTBOOT_PROGRAM,9,2) IN (SELECT SUBSTR(TBRACCD_DETAIL_CODE,3,2)
                                                           FROM TBRACCD
                                                          WHERE  TBRACCD_PIDM = TZTBOOT_PIDM
                                                                 AND TZTBOOT_START_DATE = TBRACCD_FEED_DATE
                                                                 AND TZTBOOT_TERM_CODE = TBRACCD_TERM_CODE
                                                                 AND TZTBOOT_ORDEN = TBRACCD_RECEIPT_NUMBER)
                 AND TZTBOOT_PIDM = P_PIDM;

    RETURN (DATOS_BOOTCAMP);
    END;


  ELSE
     OPEN DATOS_BOOTCAMP
          FOR
            SELECT 'Sin registro en SPRIDEN.',NULL,NULL,NULL
              FROM DUAL;
     RETURN(DATOS_BOOTCAMP);
  END IF;


END F_CURSOR_DATOS_BOOTCAMP;


-- OMS 22/Febrero/2024
-- Obtiene cursor de registros con el status correspondiente de cada uno de ellos.
FUNCTION f_Obt_Etiqueta_TZTBOOT (p_pidm IN NUMBER) RETURN pkg_finanzas_bootcamp.CURSOR_DATOS_BOOTCAMP_v2 AS
-- Etiquetas:	MA=Matricula
--		        EG=Egresado
--		        BD=Baja Definitiva
--		        CV=Cancelación de Venta
--		        XX-Otros 

   CURSOR_Etiquetado_TZTBOOT pkg_finanzas_bootcamp.CURSOR_DATOS_BOOTCAMP_v2;

BEGIN
   BEGIN
     OPEN CURSOR_Etiquetado_TZTBOOT FOR
          SELECT a.tztboot_pidm PIDM, a.tztboot_program PROGRAMA, a.tztboot_start_date INICIO, a.tztboot_status,
                 NVL (a.tztboot_atts_code, 'XX') Etiqueta
            FROM tztboot a
           WHERE 1 = 1
             AND a.tztboot_pidm = p_pidm;

     RETURN (CURSOR_Etiquetado_TZTBOOT);
   END;

END f_Obt_Etiqueta_TZTBOOT;


-- Actualiza la etiqueta en TZTBOOT en procesos por lotes
FUNCTION f_Upd_Etiqueta_TZTBOOT (p_pidm IN NUMBER, p_fecha_inicio IN DATE, p_programa IN VARCHAR2, p_etiqueta IN VARCHAR2) RETURN VARCHAR2 AS
-- Etiquetas:	MA=Matricula
--		        EG=Egresado
--		        BD=Baja Definitiva
--		        CV=Cancelación de Venta
--		        XX-Otros 

   -- Variables Locales
   Vm_Periodo    TZTBOOT.tztboot_term_code%TYPE;
   Vm_Study_Path TBRACCD.tbraccd_stsp_key_sequence%TYPE;
   Vm_exito      VARCHAR2(1000) := 'EXITO';

BEGIN
    -- Actualiza la etiqueta en TZTBOOT
    IF p_etiqueta IN ('EG','CV','MA') THEN
       UPDATE tztboot
          SET tztboot_atts_code     = p_etiqueta,
              tztboot_activity_date = sysdate
        WHERE tztboot_pidm          = p_pidm
          AND tztboot_start_date    = p_fecha_inicio
          AND tztboot_program       = p_programa;
          
    -- Baja Definitiva
    ELSIF p_etiqueta IN ('BD') THEN
          UPDATE tztboot
             SET tztboot_atts_code     = p_etiqueta,
                 tztboot_status        = 'CANCELADO',
                 tztboot_activity_date = sysdate
           WHERE tztboot_pidm          = p_pidm
             AND tztboot_start_date    = p_fecha_inicio
             AND tztboot_program       = p_programa;
             
          -- Version aplicando la funcion de baja definitica del paquete PKG_FINANZAS
          BEGIN
             SELECT DISTINCT tztboot_term_code, b.tbraccd_stsp_key_sequence
               INTO Vm_Periodo, Vm_Study_Path
               FROM tztboot a,tbraccd b
              WHERE a.tztboot_pidm    = p_pidm
                AND a.tztboot_program = p_programa
                AND TRUNC (a.tztboot_start_date) = TRUNC (p_fecha_inicio)
                AND a.tztboot_status != 'CANCELADO'
                AND b.tbraccd_pidm = a.tztboot_pidm
                AND SUBSTR (b.tbraccd_detail_code,3,2) = SUBSTR (a.tztboot_program, LENGTH (a.tztboot_program)-1, 2)
                AND TRUNC (b.tbraccd_feed_date) = TRUNC (a.tztboot_start_date)
                AND Rownum <= 1;
          
          EXCEPTION
              WHEN OTHERS THEN 
                   Vm_Periodo    := NULL;
                   Vm_Study_Path := NULL;
          END;
          
          -- Verifica que se recuperen bien los valos de PERIODO and Study-Path
          IF Vm_Periodo IS NOT NULL AND Vm_Study_Path IS NOT NULL THEN
             NULL;
             -- Vm_Exito := pkg_finanzas.F_BAJA_ECONOMICA (p_pidm, 'BOT', 'EC', 'BD', p_programa, Vm_Periodo, sysdate, p_fecha_inicio, sysdate, Vm_Study_Path);
          END IF;
          
    END IF;
    
    
    -- Graba la transacción
    IF Vm_Exito = 'EXITO' THEN
       COMMIT;
    END IF;
    
    RETURN Vm_Exito;
    
    -- Control de errores
    EXCEPTION WHEN OTHERS THEN RETURN 'ERROR: ' || sqlerrm;
END f_Upd_Etiqueta_TZTBOOT;
-- OMS 22/Febrero/2024


END PKG_FINANZAS_BOOTCAMP;
/

DROP PUBLIC SYNONYM PKG_FINANZAS_BOOTCAMP;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FINANZAS_BOOTCAMP FOR BANINST1.PKG_FINANZAS_BOOTCAMP;
