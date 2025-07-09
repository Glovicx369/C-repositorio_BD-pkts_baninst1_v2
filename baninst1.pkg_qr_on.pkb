DROP PACKAGE BODY BANINST1.PKG_QR_ON;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_QR_ON
IS
   VREG_INSERTA   NUMBER := 0;

   --proceso es una copia ajustada del proceso principal de QR este solo para este proceso DPLO glovicx 10.04.2024

      CURSOR c_universo_p (ppidm number)
      IS
           SELECT T.PIDM PIDM,
                  T.MATRICULA MATRICULA,
                     S.SPRIDEN_FIRST_NAME
                  || ' '
                  || REPLACE (S.SPRIDEN_LAST_NAME, '/', ' ')
                     NOMBRE,
                  T.PROGRAMA PROGRAMA,
                  V.SVRSVPR_PROTOCOL_SEQ_NO SEQNO,
                  V.SVRSVPR_SRVC_CODE CODE_ACC,
                  T.CAMPUS CAMPUS,
                  T.NIVEL NIVEL,
                  V.SVRSVPR_ACCD_TRAN_NUMBER
             FROM SVRSVPR v, tztprog t, SPRIDEN S
            WHERE     1 = 1
                  AND v.SVRSVPR_PIDM = t.pidm
                  AND V.SVRSVPR_PIDM = S.SPRIDEN_PIDM
                  AND S.SPRIDEN_CHANGE_IND IS NULL
                  AND TRUNC (V.SVRSVPR_RECEPTION_DATE) >= ('01/04/2024')
                  AND V.SVRSVPR_PIDM = NVL (ppidm, V.SVRSVPR_PIDM)
                  AND SVRSVPR_SRVS_CODE IN ('PA', 'CL') -- se agrega parametro para proyecto costo cero_QR
                  AND V.SVRSVPR_SRVC_CODE = 'DPLO'
                  AND T.PROGRAMA IN
                         (SELECT DISTINCT va.SVRSVAD_ADDL_DATA_CDE
                            FROM svrsvpr v2, SVRSVAD VA
                           WHERE     1 = 1
                                 AND v2.SVRSVPR_PIDM =    NVL (ppidm, v2.SVRSVPR_PIDM)
                                 AND V2.SVRSVPR_PROTOCOL_SEQ_NO =   VA.SVRSVAD_PROTOCOL_SEQ_NO
                                 AND V2.SVRSVPR_PROTOCOL_SEQ_NO =   v.SVRSVPR_PROTOCOL_SEQ_NO
                                 AND va.SVRSVAD_ADDL_DATA_SEQ = '1')
                  AND NOT EXISTS
                             (SELECT 1
                                FROM SZTQRON
                               WHERE     1 = 1
                                     AND SZTQRON_PIDM = v.SVRSVPR_PIDM
                                     AND SZTQRON_SEQNO_SIU =    V.SVRSVPR_PROTOCOL_SEQ_NO)
         ORDER BY V.SVRSVPR_SRVC_CODE;



  
      VSECUENCIA      VARCHAR2 (50);
      squery               VARCHAR2 (70);
      squery2              VARCHAR2 (50);
      VAVANCE            varchar2(8);
      VPROMEDIO           varchar2(8);
      VFOLIO_DOCTO         SZTQRDG.SZT_FOLIO_DOCTO%TYPE;
      VNO_MATERIAS_ACRED   SZTQRDG.SZT_NO_MATERIAS_ACRED%TYPE;
      VNO_MATERIAS_TOTAL   SZTQRDG.SZT_NO_MATERIAS_TOTAL%TYPE;
      VSEC_FOLIO         SZTQRDG.SZT_SEQ_FOLIO%TYPE;
      VSEC_FOLIO2        VARCHAR2 (10);
      VCICLO                SZTQRDG.SZT_CICLO_CURSA%TYPE;
      VCICLO_INI           SZTQRDG.SZT_FECHAS_CICLO_INI%TYPE;
      VCICLO_FIN           SZTQRDG.SZT_FECHAS_CICLO_FIN%TYPE;
      Vciclo_gtlg            VARCHAR2 (10);
      VERROR                VARCHAR2 (1000);
      vtalleres              NUMBER;
      vmateria              VARCHAR2 (19);
      VSEM_ACTUAL      VARCHAR2 (70);
      VNO_RVOE           VARCHAR2 (30);
      VFECHA_RVOE       VARCHAR2 (30);

      vperiodo_act         VARCHAR2 (20);
      vperiodo_sep         VARCHAR2 (3);
      vnom_prog            VARCHAR2 (120);
      val_prog             NUMBER;
      VSESO                NUMBER := 0;
      VFECHA_ENVIO_CAP     VARCHAR2 (30):= REPLACE (TO_CHAR (SYSDATE, 'DD-MONTH-yyyy') || '-'  || TO_CHAR (SYSDATE, 'HH24:MI:SS'), ' ', '');
      VSTATUS_ENVIO        NUMBER := 1;
      VPROM_ANTE           VARCHAR2 (20);
      VPERIODO_ANT         VARCHAR2 (12);
      vinicio2             VARCHAR2 (18);
      vfin2                VARCHAR2 (18);
      vvalida_eng          VARCHAR2 (1) := 'N';
      vcampus              VARCHAR2 (4);
      F_INI_ENG            SZTQRDG.SZT_FECHAS_CICLO_INI%TYPE;
      F_FIN_ENG            SZTQRDG.SZT_FECHAS_CICLO_FIN%TYPE;
      vcrn                 VARCHAR2 (8);
      ppidm                number;
      pprograma            varchar2(20);
      PCODE                VARCHAR2(10):= 'DPLO';
      vnivel               varchar2(6);
      VETIQUETA            varchar2(6):='NA';
      --VREG_INSERTA         number:= 0;
      vestatus              varchar2(1):='Y';
      vmateriasOK           varchar2(200);
      vdiplomaok            varchar2(300);
      vetiquetaok           varchar2(6);
      vsalida               varchar2(300);
      VMAIL                 varchar2(80);  
      VDESCRPT              VARCHAR2(90);
      
      
PROCEDURE p_universo_paralelo (ppidm NUMBER)
   IS
   
      
 BEGIN
      --DBMS_OUTPUT.put_line ('INICIA PROCESO ANTES LOOP'  );
  FOR jump IN c_universo_p(ppidm)
      LOOP
         NULL;
         ---LIMPIA VARIABLES--

         VAVANCE := NULL;
         VPROMEDIO := NULL;
         VFOLIO_DOCTO := NULL;
         VNO_MATERIAS_ACRED := NULL;
         VNO_MATERIAS_TOTAL := NULL;
         VSEC_FOLIO := NULL;
         VSEC_FOLIO2 := NULL;
         VCICLO := NULL;
         VCICLO_INI := NULL;
         VCICLO_FIN := NULL;
         vtalleres := NULL;
         vmateria := NULL;
         VSEM_ACTUAL := NULL;
         vperiodo_act := NULL;
         vperiodo_sep := NULL;
         VSESO := 0;
         VFECHA_ENVIO_CAP := NULL;
         VSTATUS_ENVIO := NULL;
         VPROM_ANTE := NULL;
         VPERIODO_ANT := NULL;
         vvalida_eng := 'N';
         vcampus := NULL;

         --
               -------- calculamos campus nivel  
                begin
                      select T1.campus, T1.nivel, T1.PROGRAMA
                       into vcampus , vnivel, PPROGRAMA
                        from tztprog T1
                          where 1=1
                           and T1.pidm = jump.pidm 
                           --and T1.ESTATUS = 'MA'
                           AND T1.SP = (SELECT MAX(T2.SP)  FROM  TZTPROG T2
                                                   WHERE 1=1 AND T1.PIDM=T2.PIDM  )
                           --and programa = pprograma
                           ;
                
                exception when others then
                null;
                VERROR := SQLERRM;
                vestatus := 'N';
                
                DBMS_OUTPUT.PUT_LINE('ERROR EN TZTPROGRAMA  '|| VERROR  );
                end;
         --
       /*  DBMS_OUTPUT.put_line (
               'INICIA PROCESO DENTRO LOOP ANTES DE CICLOS:  '
            || PPIDM
            || '-'
            || pprograma);
      */
       
    if  vestatus = 'Y' then  
    
         BEGIN
            SELECT t1.CTLG,
                   TO_CHAR (t1.fecha_inicio, 'DD-Month-yyyy'),
                   T1.CAMPUS
              INTO Vciclo_gtlg, VCICLO_INI, vcampus
              FROM tztprog t1
             WHERE     1 = 1
                   AND t1.pidm = jump.pidm
                   AND t1.programa = pprograma--and   t1.sp = ( select max(t2.sp)  from tztprog t2  where t1.pidm = t2.PIDM   )
            ;
         EXCEPTION
            WHEN OTHERS
            THEN
               Vciclo_gtlg := NULL;
               VCICLO_INI := NULL;
               VERROR := SQLERRM;
             DBMS_OUTPUT.PUT_LINE (  'SALIDA ERROR: CALCULAR CICLOS TZTPROG  ' || VERROR);
         END;



         -----OBTENER TOTAL DE MATERIAS-- Y PROMEDIO ACTUAL
      begin 
        VNO_MATERIAS_TOTAL :=  BANINST1.PKG_DATOS_ACADEMICOS.TOTAL_MATE2 (jump.pidm, pprograma);
         VPROMEDIO := BANINST1.PKG_DATOS_ACADEMICOS.promedio1 (jump.pidm, pprograma);
      exception when others then
      VNO_MATERIAS_TOTAL := 0; 
      VPROMEDIO    :=0;
      
      end;
         ----- nuevo metodo de sacar las rechas de unicio y fin-- glovicx 30.01.2023

         BEGIN
            SELECT datos.SSBSECT_TERM_CODE,
                TO_CHAR (datos.fecha_inicio, 'DD-Month-yyyy')
                 INTO VCICLO, vinicio2
                from (
                select distinct ss.SSBSECT_TERM_CODE,
                max(ss.SSBSECT_PTRM_START_DATE) fecha_inicio
              FROM SSBSECT ss
             WHERE     1 = 1
                   AND (ss.SSBSECT_TERM_CODE, SS.SSBSECT_CRN) IN
                  (SELECT DISTINCT  (SFRSTCR_TERM_CODE) periodo,  (F.SFRSTCR_CRN) crn
                             FROM sfrstcr f
                            WHERE     1 = 1
                                  AND f.SFRSTCR_PIDM = jump.pidm
                      AND SUBSTR (f.SFRSTCR_TERM_CODE, 5, 1) !=  '8'
                     AND f.SFRSTCR_TERM_CODE =  (SELECT MAX (f2.SFRSTCR_TERM_CODE)
                                            FROM sfrstcr f2
                                           WHERE     1 = 1
                                                                                 AND f2.SFRSTCR_PIDM =   f.SFRSTCR_PIDM
                                                                                 AND SUBSTR ( f2.SFRSTCR_TERM_CODE,5, 1) NOT IN ('8', '9'))
                )
                AND ss.SSBSECT_SUBJ_CODE || ss.SSBSECT_CRSE_NUMB NOT LIKE ('%H%')
                AND ss.SSBSECT_SUBJ_CODE || ss.SSBSECT_CRSE_NUMB NOT LIKE  ('%SESO%')
                group by ss.SSBSECT_TERM_CODE
                ) datos
                ;
         EXCEPTION
            WHEN OTHERS
            THEN
               VCICLO := NULL;
               vinicio2 := NULL;
           --  DBMS_OUTPUT.PUT_LINE ('ERROR1 EN FECHAS INICIO ' || PPIDM || '--' || SQLERRM);
         END;

          BEGIN
            SELECT datos.SSBSECT_TERM_CODE,
                TO_CHAR (datos.fecha_FIN, 'DD-Month-yyyy')
                 INTO VCICLO, vfin2
                from (
                select distinct ss.SSBSECT_TERM_CODE,
                max(ss.SSBSECT_PTRM_END_DATE) fecha_FIN
                FROM SSBSECT ss
                WHERE     1 = 1
                AND (ss.SSBSECT_TERM_CODE, SS.SSBSECT_CRN) IN
                  (SELECT DISTINCT  (SFRSTCR_TERM_CODE) periodo,  (F.SFRSTCR_CRN) crn
                             FROM sfrstcr f
                            WHERE     1 = 1
                                  AND f.SFRSTCR_PIDM = jump.pidm
                                  AND SUBSTR (f.SFRSTCR_TERM_CODE, 5, 1) !=  '8'
                                  AND f.SFRSTCR_TERM_CODE =  (SELECT MAX (f2.SFRSTCR_TERM_CODE)
                                                                                    FROM sfrstcr f2
                                                                                   WHERE     1 = 1
                                                                                         AND f2.SFRSTCR_PIDM =   f.SFRSTCR_PIDM
                                                                                         AND SUBSTR ( f2.SFRSTCR_TERM_CODE,5, 1) NOT IN ('8', '9'))
                )
                AND ss.SSBSECT_SUBJ_CODE || ss.SSBSECT_CRSE_NUMB NOT LIKE ('%H%')
                AND ss.SSBSECT_SUBJ_CODE || ss.SSBSECT_CRSE_NUMB NOT LIKE  ('%SESO%')
                group by ss.SSBSECT_TERM_CODE
                ) datos
                ;
          EXCEPTION
            WHEN OTHERS
            THEN
               VCICLO := NULL;
               vfin2 := NULL;
            -- DBMS_OUTPUT.PUT_LINE ('ERROR1 EN MATERIAS ' || PPIDM || '--' || SQLERRM);
         END;

       /*  DBMS_OUTPUT.PUT_LINE (
               'recupera las MATERIAS '
            || VCICLO
            || '-'
            || vinicio2
            || '--'
            || vfin2
            || '-'
            || vcrn);  
            */

            BEGIN
               SELECT DISTINCT TO_CHAR (STVTERM_END_DATE, 'DD-Month-yyyy')
                 -- to_char (STVTERM_START_DATE,'DD-Month-yyyy')
                 INTO VCICLO_FIN
                 FROM stvterm v
                WHERE 1 = 1 AND STVTERM_CODE = VCICLO;
            EXCEPTION
               WHEN OTHERS
               THEN
                  -- VCICLO_INI  := null;
                  VCICLO_FIN := NULL;
            END;
        

         ------OBTIENE EL AVANCE CURRICULAR ---nueva forma glovicx 25.01.23


           Begin
                  SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 (jump.pidm, pprograma)
                    INTO VAVANCE
                    FROM DUAL;
               --   DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
           EXCEPTION   WHEN OTHERS    THEN
                   VAVANCE := 0;
            END;

                 IF TO_NUMBER(VAVANCE) >= 100 THEN
                       VAVANCE := '100';
                  END IF;

               -------------   numero materias creditadas nuevo glovicx
         BEGIN
                  SELECT BANINST1.PKG_DATOS_ACADEMICOS.acreditadas1 (jump.pidm, pprograma)
                    INTO VNO_MATERIAS_ACRED
                    FROM DUAL;
               --   DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VNO_MATERIAS_ACRED := 0;
         END;


         ---SE OBTIENE LA SECUENCIA DEPENDIENDO DEL CODIGO

         BEGIN
            SELECT ZSTPARA_PARAM_VALOR
              INTO VSECUENCIA
              FROM ZSTPARA
             WHERE     1 = 1
                   AND ZSTPARA_MAPA_ID = 'CODIGOQR'
                   AND ZSTPARA_PARAM_ID = PCODE;
         EXCEPTION
            WHEN OTHERS
            THEN
               VSECUENCIA := NULL;
         END;

       
         squery := 'SELECT ' || VSECUENCIA;
         squery2 := squery || ' FROM DUAL';

        --  dbms_output.put_line('salida_SECUENCIA..>>>>'||squery2);



         EXECUTE IMMEDIATE (squery2) INTO VSEC_FOLIO;

        -- dbms_output.put_line('salida..SEQ.>>>>'||PCODE||'---'|| VSEC_FOLIO|| ' MATERIA '|| trim(VMATERIA));



         BEGIN
            IF LENGTH (VSEC_FOLIO) < 2
            THEN
               VSEC_FOLIO2 := LPAD (VSEC_FOLIO, 2, '0');
            --'uno'
            ELSE
               VSEC_FOLIO2 := VSEC_FOLIO;
            --'dos'
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;


        VFOLIO_DOCTO := SUBSTR (PCODE, 1, 3) || TO_CHAR (SYSDATE, 'YYYY')|| '/'|| VSEC_FOLIO2;

         --DBMS_OUTPUT.put_line (  'salida..FOLIO.>>>>' || VFOLIO_DOCTO || '--' || Vciclo_gtlg);

         --END IF;


         ------CALCULA NUM DE TALLERES--

         BEGIN
            SELECT DISTINCT SMBPGEN_MAX_COURSES_I_NONTRAD
              INTO vtalleres
              FROM SMBPGEN
             WHERE     1 = 1
                   AND SMBPGEN_PROGRAM = pprograma
                   AND SMBPGEN_ACTIVE_IND = 'Y'
                   AND SMBPGEN_TERM_CODE_EFF = Vciclo_gtlg;
         EXCEPTION
            WHEN OTHERS
            THEN
               vtalleres := 0;
         END;

         ---------VALIDA SI EL TALLER TIENE MATERIA DE SERVICIO SOCIAL SI TIENE HAY QUE RESTARLA A LA VARIABLE DE TALLERES
         -------- REGLA QUE DIO SUSY SAVEEDRA 10-03-021   GLOVICX

         BEGIN
            SELECT DISTINCT 1
              INTO VSESO
              FROM SMRPCMT
             WHERE     1 = 1
                   AND SMRPCMT_TEXT LIKE ('%SESO%')
                   AND SMRPCMT_PROGRAM = pprograma;
         EXCEPTION
            WHEN OTHERS
            THEN
               VSESO := 0;
         END;

         --  dbms_output.put_line('salida talleres y SESO '|| vtalleres ||'-'||VSESO );

         ------- CALCULA NO RVOE--
         BEGIN
            SELECT DISTINCT
                   NVL (zt.SZTDTEC_NUM_RVOE, '000000') AS numrvoe,
                   --TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'YYYY-MM-DD')   AS fech_rvoe
                   TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'DD-Month-yyyy'),
                   CASE
                      WHEN zt.SZTDTEC_PERIODICIDAD_SEP IS NULL
                      THEN
                         TO_CHAR (zt.SZTDTEC_PERIODICIDAD)
                      ELSE
                         --'dos'
                         TO_CHAR (zt.SZTDTEC_PERIODICIDAD_SEP)
                   END
                      periodo_sep,
                   ZT.SZTDTEC_PROGRAMA_COMP
              INTO VNO_RVOE,
                   VFECHA_RVOE,
                   vperiodo_sep,
                   vnom_prog
              FROM SZTDTEC zt
             WHERE     1 = 1
                   AND zt.SZTDTEC_CAMP_CODE = vcampus
                   AND zt.SZTDTEC_PROGRAM = pprograma
                   AND zt.SZTDTEC_TERM_CODE = Vciclo_gtlg;
         EXCEPTION
            WHEN OTHERS
            THEN
               VNO_RVOE := NULL;
               VFECHA_RVOE := NULL;
               VERROR := SQLERRM;
               vperiodo_sep := NULL;

         END;


       /*  DBMS_OUTPUT.put_line (
               'antes de enviar fcurso_act:  '
            || PPIDM
            || '-'
            || pprograma
            || '-'
            || vnivel
            || '-'
            || vcampus
            || '-'
            || vcampus); */


         ----se ejecuta la funcion para saber en que cuatrimestre se encuentra
         VSEM_ACTUAL := BANINST1.PKG_QR_DIG.F_curso_actual (jump.pidm,pprograma,vnivel,vcampus);


         --NUMERO DE TALLERES MENOS SERVICIOSOCIAL  REGLA SUSY 10/03/021
         IF vtalleres = 0
         THEN
            NULL;
         ELSE
            vtalleres := vtalleres - VSESO;
         END IF;



         ----valida que materias cursadas no se amayor que totales

         IF VNO_MATERIAS_TOTAL < VNO_MATERIAS_ACRED
         THEN
            VNO_MATERIAS_ACRED := VNO_MATERIAS_TOTAL;
         END IF;


         -----AQUI VALIDA SI ES CAP ENTONCES MANDA LA FECHA DE ENVIO Y EL ESTATUS DE ENVIO COMO PRENDIDOS-- REGLA DE SUSY POR MAIL 23/04/no_div021-- GLOVICX
            VSTATUS_ENVIO := NULL;
        
         ---------AQUI TOMA EL PROMEDIO ANTERIOR INMEDIATO POR SI EXISTE QUE SE BRINCO UN PERIODO ENTONCES BUSCA EL ÚLTIMO MENOR AL ACTUAL GLOVICX 12/07/021

         BEGIN
              SELECT TRIM (TO_CHAR (AVG (SFRSTCR_GRDE_CODE), '999.99'))
                        AS promedio
                INTO VPROM_ANTE
                FROM sfrstcr f1
               WHERE     1 = 1
                     AND f1.SFRSTCR_PIDM = jump.pidm
                     AND f1.SFRSTCR_GRDE_CODE NOT IN ('NA', 'NP')
                     AND f1.SFRSTCR_GRDE_CODE IS NOT NULL
                     AND f1.SFRSTCR_GRDE_CODE != '5.0'
                     AND f1.SFRSTCR_TERM_CODE < VCICLO          --perio actual
                     AND SUBSTR (f1.SFRSTCR_TERM_CODE, 5, 1) NOT IN (8, 9)
                     AND f1.SFRSTCR_TERM_CODE =   (SELECT MAX (f2.SFRSTCR_TERM_CODE)
                               FROM sfrstcr f2
                              WHERE     1 = 1
                                                                AND F2.SFRSTCR_GRDE_CODE NOT IN  ('NA', 'NP')
                                    AND F2.SFRSTCR_GRDE_CODE IS NOT NULL
                                    AND f1.SFRSTCR_PIDM = f2.SFRSTCR_PIDM
                                                                AND F2.SFRSTCR_GRDE_CODE IN  ('6.0', '7.0',  '8.0', '9.0', '10', '10.0')
                                                                AND SUBSTR (f2.SFRSTCR_TERM_CODE, 5, 1) NOT IN(8, 9)
                                    AND f2.SFRSTCR_TERM_CODE < VCICLO)
            ORDER BY 1 DESC;
         EXCEPTION
            WHEN OTHERS
            THEN
               VPROM_ANTE := 'en curso';
         END;


         IF vnivel IN ('MA', 'MS', 'DO')
         THEN
            ----aqui hace el calculo de promedio anterior sonre estos niveles que es x bimestre anterior
            BEGIN
               SELECT TRIM ( TO_CHAR (AVG (datos2.SFRSTCR_GRDE_CODE), '999.99')) AS promedio
                 INTO VPROM_ANTE
                 FROM (  SELECT MAX (datos.SFRSTCR_TERM_CODE),
                                datos.SFRSTCR_PTRM_CODE,
                                datos.SFRSTCR_GRDE_CODE --  TRIM(TO_CHAR(avg(datos.SFRSTCR_GRDE_CODE),'999.99')) as promedio
                           FROM (  SELECT f.SFRSTCR_TERM_CODE,
                                          f.SFRSTCR_PTRM_CODE,
                                          bb.SSBSECT_PTRM_START_DATE,
                                          bb.SSBSECT_PTRM_END_DATE,
                                          f.SFRSTCR_GRDE_CODE,
                                          F.SFRSTCR_RSTS_DATE
                                     FROM sfrstcr f, ssbsect bb
                                    WHERE     1 = 1
                                          AND F.SFRSTCR_CRN = BB.SSBSECT_CRN
                                          AND F.SFRSTCR_TERM_CODE =
                                                 BB.SSBSECT_TERM_CODE
                                          AND SFRSTCR_PIDM = jump.pidm
                                          AND f.SFRSTCR_GRDE_CODE NOT IN ('NA', 'NP', 'AC')
                                          AND f.SFRSTCR_GRDE_CODE IS NOT NULL
                                          AND f.SFRSTCR_GRDE_CODE != '5.0'
                                          AND SUBSTR (F.SFRSTCR_TERM_CODE, 5, 1) NOT IN (8, 9)
                                          AND (SFRSTCR_TERM_CODE,SFRSTCR_PTRM_CODE) NOT IN
                                                                                 (SELECT DISTINCT B2.SSBSECT_TERM_CODE,  B2.SSBSECT_PTRM_CODE
                                                    FROM ssbsect b2
                                                   WHERE     1 = 1
                                                                                         AND TRUNC (SYSDATE) BETWEEN TRUNC ( B2.SSBSECT_PTRM_START_DATE)
                                                                                                                 AND TRUNC ( B2.SSBSECT_PTRM_END_DATE)
                                                                                         AND BB.SSBSECT_CRN = B2.SSBSECT_CRN
                                                                                         AND BB.SSBSECT_TERM_CODE = B2.SSBSECT_TERM_CODE)
                                                                 ORDER BY F.SFRSTCR_RSTS_DATE DESC, SFRSTCR_PTRM_CODE DESC) datos
                          WHERE     1 = 1
                                                                AND TRUNC (SFRSTCR_RSTS_DATE) > TRUNC (SYSDATE) - 120
                                                       GROUP BY datos.SFRSTCR_PTRM_CODe,datos.SFRSTCR_GRDE_CODE) datos2;
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     SELECT TRIM ( TO_CHAR (AVG (datos2.SFRSTCR_GRDE_CODE),  '999.99')) AS promedio
                       INTO VPROM_ANTE
                       FROM (  SELECT *
                                 FROM (  SELECT MAX (f.SFRSTCR_TERM_CODE),
                                                f.SFRSTCR_PTRM_CODE,
                                                f.SFRSTCR_GRDE_CODE
                                           FROM sfrstcr f, ssbsect bb
                                          WHERE     1 = 1
                                                AND F.SFRSTCR_CRN = BB.SSBSECT_CRN
                                                AND F.SFRSTCR_TERM_CODE = BB.SSBSECT_TERM_CODE
                                                AND SFRSTCR_PIDM = jump.pidm
                                                AND f.SFRSTCR_GRDE_CODE NOT IN ('NA', 'NP', 'AC')
                                                AND f.SFRSTCR_GRDE_CODE IS NOT NULL
                                                AND f.SFRSTCR_GRDE_CODE != '5.0'
                                                AND SUBSTR (F.SFRSTCR_TERM_CODE, 5, 1) NOT IN (8, 9)
                                                AND (SFRSTCR_TERM_CODE,SFRSTCR_PTRM_CODE) IN
                                                       (  SELECT DISTINCT MAX ( f2.SFRSTCR_TERM_CODE),f2.SFRSTCR_PTRM_CODE
                                                            FROM SFRSTCR f2
                                                           WHERE     1 = 1
                                                                 AND f2.SFRSTCR_PIDM = jump.pidm
                                                                 AND f2.SFRSTCR_GRDE_CODE NOT IN ('NA', 'NP','AC')
                                                                 --and  f.SFRSTCR_GRDE_CODE is not null
                                                                 AND f2.SFRSTCR_GRDE_CODE != '5.0'
                                                                 AND SUBSTR ( F2.SFRSTCR_TERM_CODE, 5, 1) NOT IN (8, 9)
                                                        GROUP BY f2.SFRSTCR_PTRM_CODE)
                                       GROUP BY f.SFRSTCR_PTRM_CODE,
                                                bb.SSBSECT_PTRM_START_DATE,
                                                bb.SSBSECT_PTRM_END_DATE,
                                                f.SFRSTCR_GRDE_CODE,
                                                F.SFRSTCR_RSTS_DATE) datos
                                WHERE 1 = 1
                             ORDER BY 1 DESC, 2 DESC) datos2;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        VPROM_ANTE := 'en curso';
                  END;
            END;
         END IF;



         ---- esto es para cuando los documentos van en ingles. segun los campues en especial glovicx 07.09.022
         BEGIN
            SELECT DISTINCT 'Y'
              INTO vvalida_eng
              FROM zstpara
             WHERE     1 = 1
                   AND ZSTPARA_PARAM_ID = vcampus
                   AND ZSTPARA_MAPA_ID = 'COES_INGLES';
         EXCEPTION
            WHEN OTHERS
            THEN
               vvalida_eng := 'N';
         END;



         BEGIN
            SELECT TO_CHAR (vinicio2, 'dd/mm/yyyy') INTO vinicio2 FROM DUAL;

           -- DBMS_OUTPUT.PUT_LINE ('dentro feca ini -- ' || vinicio2);
         EXCEPTION
            WHEN OTHERS
            THEN
               vinicio2 := vinicio2;
         END;

         -- HACEMOS EL AJUSTE PARA INGLES O ESPAÑOL GLOVICX 07.10.022



       /*  DBMS_OUTPUT.PUT_LINE (
               'dentro fecha inglasXX00 -- '
            || vinicio2
            || '----'
            || vfin2
            || '-'
            || vvalida_eng); */

         --SI ES YES ENTONCES HAY QUE CAMBIAR ALGUNOS DATOS A INGLES SOLO PARA COES GLOVICX 07.09.022
                -----SON CAMPUS EN ESPAÑOL
            VCICLO_INI := REPLACE (TRIM (VCICLO_INI), ' ', '');
            VCICLO_FIN := REPLACE (TRIM (VCICLO_FIN), ' ', '');

            IF VPROM_ANTE IS NULL
            THEN
               VPROM_ANTE := 'en curso';
            END IF;


         -- -- TO_CHAR (BB.SSBSECT_PTRM_START_DATE ,'DD-Month-yyyy'),TO_CHAR(BB.SSBSECT_PTRM_END_DATE ,'DD-Month-yyyy')

       /*  DBMS_OUTPUT.PUT_LINE (
               'ANTES DE INSERTAR LA TABLA'
            || PPIDM
            || '-'
            || pprograma
            || '-'
            || 'seqno'
            || '-'
            || TO_CHAR (VPROMEDIO, 99.99)
            || '-'
            || VCICLO_INI
            || '-'
            || VCICLO_FIN
            || '-'
            ||VETIQUETA
            || '-'
           -- ||  JUMP.DIPLOMA
            || '-'
         --   || JUMP.MAIL
            
            ); 
         */
             BEGIN   ---sacamos la etiqueta del curso solicitado
                 
                SELECT  va.SVRSVAD_ADDL_DATA_CDE, va.SVRSVAD_ADDL_DATA_DESC
                  INTO vetiquetaok, vdiplomaok
                FROM SVRSVPR v, SVRSVAD va
                WHERE 1 = 1
                 AND SVRSVPR_SRVC_CODE IN ('DPLO')
                 AND SVRSVPR_SRVS_CODE IN ('CL', 'PA')
                 AND v.SVRSVPR_PROTOCOL_SEQ_NO =  VA.SVRSVAD_PROTOCOL_SEQ_NO
                 AND SVRSVAD_ADDL_DATA_SEQ = 10   --aqui esta la etiqueta del curso que solicito el alumno
                 AND V.SVRSVPR_PIDM = jump.pidm
                 AND V.SVRSVPR_PROTOCOL_SEQ_NO = jump.seqno;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vetiquetaok := NULL;
               END;
               --con la etiqueta y el RVOE podemos obtener las materias del curso y el nombre del diploma
               
              begin
              
               
                select  SZT_MATERIAS_REQ
                   INTO vmateriasok 
                     from  SZTDIGR g
                      where 1=1
                       and g.SZT_ETIQUETA = vetiquetaok
                       and g.SZT_RVOE   = VNO_RVOE
                       and G.SZT_DIPLOMA   = vdiplomaok  ;
              
              
              
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vsalida  := sqlerrm;
               END;
             
             
            -- dbms_output.put_line(' despuyes de materias y etiquetas:  '||ppidm||'-'|| jump.seqno||'-'|| VNO_RVOE||'-'||vetiquetaok||'-'||vdiplomaok||'-'|| vmateriasok   );
             
             BEGIN
                 SELECT   DISTINCT  GOREMAL_EMAIL_ADDRESS
                      INTO VMAIL
                       FROM GOREMAL
                         WHERE     GOREMAL_PIDM = jump.pidm
                           AND GOREMAL_STATUS_IND  = 'A'
                             AND GOREMAL_EMAL_CODE = 'PRIN';
             EXCEPTION  WHEN OTHERS  THEN
              vsalida  := sqlerrm;       
             
             END;
             
            
         BEGIN
            INSERT INTO SZTQRON (SZTQRON_PIDM,
                                    SZTQRON_PROGRAMA,
                                    SZTQRON_AVANCE,
                                    SZTQRON_PROMEDIO,
                                    SZTQRON_FOLIO_DOCTO,
                                    SZTQRON_SEQNO_SIU,
                                    SZTQRON_CODE_ACCESORIO,
                                    SZTQRON_ENVIO_ALUMNO,
                                    SZTQRON_FECHA_ENVIO,
                                    SZTQRON_ACTIVITY_DATE,
                                    SZTQRON_NO_MATERIAS_ACRED,
                                    SZTQRON_NO_MATERIAS_TOTAL,
                                    --SZTQRON_CODE_QR,
                                    SZTQRON_USER,
                                    SZTQRON_DATA_ORIGIN,
                                    SZTQRON_SEQ_FOLIO,
                                    SZTQRON_CICLO_CURSA,
                                    SZTQRON_FECHAS_CICLO_INI,
                                    SZTQRON_FECHAS_CICLO_FIN,
                                    SZTQRON_TALLERES,
                                    SZTQRON_PERIODO_ACT,
                                    SZTQRON_PROM_ANTERIOR,
                                    SZTQRON_ETIQUETA,
                                    SZTQRON_DIPLOMA,
                                    SZTQRON_MAIL,
                                    SZTQRON_MATERIAS_REQ
                                    )
                 VALUES (
                           jump.pidm,
                            pprograma,
                            VAVANCE,
                           REPLACE (TO_CHAR (TRIM (VPROMEDIO), 99.99),' ',''),
                           VFOLIO_DOCTO,
                           JUMP.SEQNO,
                           PCODE,
                           --VREP_AUTORIZA,
                           VSTATUS_ENVIO,                      --ENVIO_ALUMNO,
                           VFECHA_ENVIO_CAP,                --SZT_FECHA_ENVIO,
                           REPLACE ( TO_CHAR (SYSDATE, 'DD-MONTH-yyyy')|| '-'|| TO_CHAR (SYSDATE, 'HH24:MI:SS'),' ',''),
                           --VNO_RVOE,
                           --REPLACE (TRIM(VFECHA_RVOE),' ',''),
                           -- TRIM(to_char (VFECHA_RVOE,'DD')||to_char (VFECHA_RVOE,'Month')||to_char (VFECHA_RVOE,'YYYY')) ,
                           VNO_MATERIAS_ACRED,
                           VNO_MATERIAS_TOTAL,
                           USER,                                   --SZT_USER,
                           'QR_ON_JOB',                     --SZT_DATA_ORIGIN
                           VSEC_FOLIO,
                           VCICLO,
                           VCICLO_INI,
                           VCICLO_FIN,
                           --'luis.aguilar@utel.edu.mx', --v_email_alumno,   HAY QUE QUITAR EL MAIL DE LUIS Y DEJAR ALUMNO
                           --VNOM_PROGRAMA,
                           vtalleres,
                           VSEM_ACTUAL--upper(Vcorreponda),
                                      --upper(VCARGO),
                                      --upper(VINSTITUTO)
                           ,
                           VPROM_ANTE,
                           VETIQUETAOK,
                           VDIPLOMAOK,
                           VMAIL,
                           vmateriasok
                           );

            VREG_INSERTA := SQL%ROWCOUNT;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

           -- aqui se inserta la etiqueta del accesorio 
           
        BEGIN
           select ZSTPARA_PARAM_DESC
              INTO VDESCRPT
             From zstpara
               where 1=1
                and ZSTPARA_MAPA_ID = 'ETIQUETAS_DASHB'
                AND ZSTPARA_PARAM_ID  = VETIQUETAOK ;
           
        EXCEPTION  WHEN OTHERS   THEN
            NULL;
            
         END;
              
            
         
       --  dbms_output.put_line('antes de insertar goradid '||VDESCRPT ||'-'|| VETIQUETAOK );
       
         begin
                     
           INSERT INTO  GORADID 
             VALUES(jump.pidm, VETIQUETAOK, VETIQUETAOK, 'WWW_SIU', sysdate, 'QR_ON',null, 0,null);
         Exception When others then
         NULL;
         --vetiqueta:='Error al insertar Etiqueta'||sqlerrm;
         vsalida := 'Error al insertar Etiqueta'||sqlerrm;
                 
         end;
       
       
         COMMIT;
      end if;      
         
         
  END LOOP;
   --COMMIT;

  Exception When others then
         NULL;
         --vetiqueta:='Error al insertar Etiqueta'||sqlerrm;
         vsalida := 'Error general de universo paralelo'||sqlerrm;
                 
     dbms_output.put_line(vsalida );
     
   END p_universo_paralelo;


FUNCTION f_marca_envio (ppidm NUMBER, pprog VARCHAR2, pseqno NUMBER, pestatus number, pcomentario varchar2 )
      RETURN VARCHAR2
   IS
       VREGRESA   VARCHAR2 (12);
        vchecas    varchar2(1):='N';
      
      -- se agrego el nuevo parametro para saber si es liberado=1 y Rechazado = 2 glovicx 01.03.2023
      -- se agrego nuevo parametro comentarios para cuendo sea rechazado guardar el por que 16.03.2023 glovicx
 BEGIN
        begin ----- nueva modificacion para rechazar los boqueos glovicx 12.03.2024
                    --si existe el reg estonces No se actualiza         
              select 'Y'
              INTO vchecas
               from SZTQRON
                WHERE 1 = 1
                AND SZTQRON_PIDM = ppidm
                AND SZTQRON_PROGRAMA = pprog
                AND SZTQRON_SEQNO_SIU = pseqno
                and SZTQRON_ENVIO_ALUMNO in (select distinct z1.ZSTPARA_PARAM_ID
                                            FROM ZSTPARA z1
                                            WHERE 1 = 1
                                            AND z1.ZSTPARA_MAPA_ID = 'N_CONFIRMAR_QR'
                                            and  z1.ZSTPARA_PARAM_VALOR = pestatus) 
                ;
        EXCEPTION  WHEN OTHERS   THEN 
            NULL;
            vchecas := 'N';
            
      end;    
   
   
    IF vchecas = 'Y'  then
     --no hace nada no se puede rechazar
       null;
     
      ELSE
     
            BEGIN
                 UPDATE SZTQRON
                    SET SZTQRON_ENVIO_ALUMNO = pestatus,
                        SZTQRON_FECHA_ENVIO = REPLACE (TO_CHAR (SYSDATE, 'DD-MONTH-yyyy') || '-' || TO_CHAR (SYSDATE, 'HH24:MI:SS'), ' ', ''),
                         SZTQRON_COMENTARIOS   = pcomentario
                  WHERE     1 = 1
                        AND SZTQRON_PIDM = ppidm
                        AND SZTQRON_PROGRAMA = pprog
                        AND SZTQRON_SEQNO_SIU = pseqno;

                 VREG_INSERTA := SQL%ROWCOUNT;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    NULL;
            END;
              
    END IF;
   
   
      
      IF VREG_INSERTA > 0 THEN
             RETURN ('EXITO');
          ELSE
             RETURN ('FALSO');
      END IF;


END f_marca_envio;

FUNCTION f_datos_complemento (pfolio       VARCHAR2,
                                 ppidm        NUMBER,
                                 pcode        VARCHAR2,
                                 PPROGRAMA    VARCHAR2)
      RETURN PKG_QR_ON.cur_datos_alumn
   IS
      lv_pidm          NUMBER := 0;

      --cur_alumnos BANINST1.PKG_QR_DIG.cur_datos_alumn;
      cur_alumnos      SYS_REFCURSOR;


      vl_error         VARCHAR2 (1000);

      ------
      --vpidm                    number;

      Vcorreponda      VARCHAR2 (70);
      VCARGO           VARCHAR2 (70);
      VINSTITUTO       VARCHAR2 (70);
      vnombre_alumn    VARCHAR2 (100);
      VREP_AUTORIZA    VARCHAR2 (80);
      VNO_RVOE         VARCHAR2 (30);
      VFECHA_RVOE      VARCHAR2 (30);
      v_email_alumno   VARCHAR2 (50);
      VNOM_PROGRAMA    VARCHAR2 (100);
      Vciclo_gtlg      VARCHAR2 (12);
      VCAMPUS          VARCHAR2 (4);
      vmatricula       VARCHAR2 (12);
      VPROM_ANTE       VARCHAR2 (6);
      VPERIODO_ANT     VARCHAR2 (10);
      VCICLO_ACTUAL    VARCHAR2 (8);
      VDIMA            VARCHAR2 (25);
      VSSN             VARCHAR2 (15);
      VPAIS            VARCHAR2 (25);
      vperiodo_act     VARCHAR2 (25);
      vclave_escuela   VARCHAR2 (25);
      vclave_periodo   VARCHAR2 (20);
      vmodalidad       VARCHAR2 (80);
      vvalida_eng      VARCHAR2 (1) := 'N';
      vsexo            VARCHAR2 (2);
      vnum_horas    number:=0;
      vfecha_inicio2  varchar2(20);
      vnivel             varchar2(4);


   BEGIN
      Vcorreponda := NULL;
      VCARGO := NULL;
      VINSTITUTO := NULL;
      VREP_AUTORIZA := NULL;
      VNO_RVOE := NULL;
      VFECHA_RVOE := NULL;
      VNOM_PROGRAMA := NULL;
      v_email_alumno := NULL;
      Vciclo_gtlg := NULL;
      VCAMPUS := NULL;
      vmatricula := NULL;
      VPROM_ANTE := NULL;
      VPERIODO_ANT := NULL;
      VCICLO_ACTUAL := NULL;
      VSSN := NULL;
      VPAIS := NULL;
      vperiodo_act := NULL;
      vclave_escuela := NULL;
      vclave_periodo := NULL;
      vmodalidad := NULL;
      vsexo := NULL;
      vnum_horas := NULL;
       vfecha_inicio2  :='No lleva' ;

      ---calcula el pidm y el nomnbre del alumno, y se agrega el sexo del alumno glovicx 22.11.2022
      BEGIN
         SELECT ss.spriden_id matricula,
                   Ss.SPRIDEN_FIRST_NAME
                || ' '
                || REPLACE (Ss.SPRIDEN_LAST_NAME, '/', ' '),
                P.SPBPERS_SEX
           INTO Vmatricula, vnombre_alumn, vsexo
           FROM spriden ss, spbpers p
          WHERE     1 = 1
                AND ss.spriden_pidm = p.SPBPERS_PIDM
                AND SPRIDEN_CHANGE_IND IS NULL
                AND ss.SPRIDEN_PIDm = ppidm;
      EXCEPTION
         WHEN OTHERS
         THEN
            Vmatricula := NULL;
            vnombre_alumn := NULL;
           -- DBMS_OUTPUT.put_line ('error en sexo ' || SQLERRM);
      END;

     -- DBMS_OUTPUT.put_line ('calcula  en sexo ' || vsexo);

      ----calcula las fechas de matriculacion y la fechas de ctgl

      BEGIN
         SELECT t1.CTLG, T1.CAMPUS, T1.NIVEL
           INTO Vciclo_gtlg, VCAMPUS,vnivel
           FROM tztprog t1
          WHERE 1 = 1
            AND t1.pidm = pPIDM
            AND t1.programa = Pprograma  ;--and   t1.sp = ( select max(t2.sp)  from tztprog t2  where t1.pidm = t2.PIDM   ) -- se le quito esta opcion por que ya esta entrando x nombre de programa hay alum que tiene mas de 2 progamas glovicx 08/032022
      EXCEPTION
         WHEN OTHERS   THEN
            Vciclo_gtlg := NULL;
            VCAMPUS := NULL;
            --VERROR := SQLERRM;
           -- DBMS_OUTPUT.PUT_LINE (  'SALIDA ERROR: CALCULAR CICLOS F_DATOS_COMPLEMENTO  ');
      END;

      ------CALCULA EL PAIS DE PROCEDENCIA---Y SU RESPECTIVO NUMERO DE SSN


      BEGIN
         SELECT DISTINCT S.SPBPERS_SSN, N.SZTNACP_NAC
           INTO VSSN, vpais
           FROM spbpers S, SZTNACP N
          WHERE     1 = 1
                AND S.SPBPERS_PIDM = N.SZTNACP_PIDM
                AND S.SPBPERS_PIDM = pPIDM;
      EXCEPTION
         WHEN OTHERS
         THEN
            VSSN := NULL;
      END;


      -------AQUI SE CALCULAN LAS PREGUNTAS EXTRAS DE COES Y --
      /*   4    Persona a quien va dirigido el documento
      5    Cargo de la persona a quien va dirigido el documento
      6    Nombre de la institución a que va dirigido el documento
      */

      BEGIN
           SELECT DISTINCT NVL (SVRSVAD_ADDL_DATA_DESC, 'A quien corresponda')
             INTO Vcorreponda
             FROM svrsvpr v, SVRSVAD VA
            WHERE     1 = 1
                  --SVRSVPR_SRVC_CODE IN ('COES')
                  AND SVRSVPR_PROTOCOL_SEQ_NO IN (pfolio)
                  AND SVRSVPR_PIDM = ppidm
                  AND V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  AND va.SVRSVAD_ADDL_DATA_SEQ = '4' --VER CUAL NUMERO SE QUEDARON
         ORDER BY 1 DESC;
      EXCEPTION
         WHEN OTHERS
         THEN
            Vcorreponda := 'A quien corresponda:';
      END;

      IF Vcorreponda IS NULL OR Vcorreponda = ' '
      THEN
         Vcorreponda := 'A quien corresponda:';
      END IF;


      BEGIN
           SELECT DISTINCT SVRSVAD_ADDL_DATA_DESC
             INTO VCARGO
             FROM svrsvpr v, SVRSVAD VA
            WHERE     1 = 1
                  --SVRSVPR_SRVC_CODE IN ('COES')
                  AND SVRSVPR_PROTOCOL_SEQ_NO IN (pfolio)
                  AND SVRSVPR_PIDM = ppidm
                  AND V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  AND va.SVRSVAD_ADDL_DATA_SEQ = '5' --VER CUAL NUMERO SE QUEDARON
         ORDER BY 1 DESC;
      EXCEPTION
         WHEN OTHERS
         THEN
            VCARGO := NULL;
      END;

      BEGIN
           SELECT DISTINCT SVRSVAD_ADDL_DATA_DESC
             INTO VINSTITUTO
             FROM svrsvpr v, SVRSVAD VA
            WHERE     1 = 1
                  --SVRSVPR_SRVC_CODE IN ('COES')
                  AND SVRSVPR_PROTOCOL_SEQ_NO IN (pfolio)
                  AND SVRSVPR_PIDM = ppidm
                  AND V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  AND va.SVRSVAD_ADDL_DATA_SEQ = '6' --VER CUAL NUMERO SE QUEDARON
         ORDER BY 1 DESC;
      EXCEPTION
         WHEN OTHERS
         THEN
            VINSTITUTO := NULL;
      END;


      ------- CALCULA NO RVOE--
      BEGIN
         SELECT DISTINCT NVL (zt.SZTDTEC_NUM_RVOE, '000000') AS numrvoe,
                         --TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'YYYY-MM-DD')   AS fech_rvoe
                         TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'DD-Month-yyyy'),
                         --  to_char( to_date ( ZT.SZTDTEC_FECHA_RVOE,'DD-Month-YYYY'),'DD-Month-YYYY' ) as fecha_revoe,
                         (ZT.SZTDTEC_PROGRAMA_COMP),
                         SZTDTEC_CLVE_ESC,
                         SZTDTEC_MODALIDAD
           INTO VNO_RVOE,
                VFECHA_RVOE,
                VNOM_PROGRAMA,
                vclave_escuela,
                vmodalidad
           FROM SZTDTEC zt
          WHERE     1 = 1
                AND zt.SZTDTEC_CAMP_CODE = VCAMPUS
                AND zt.SZTDTEC_PROGRAM = PPROGRAMA
                AND zt.SZTDTEC_TERM_CODE = Vciclo_gtlg;
      --   DBMS_OUTPUT.put_line ('DATOS DE   RVOE:  '||VNO_RVOE ||'-<<'|| VFECHA_RVOE ||'>>-'|| Vciclo_gtlg  );


      EXCEPTION
         WHEN OTHERS
         THEN
            VNO_RVOE := NULL;
            VFECHA_RVOE := NULL;
            vmodalidad := NULL;
            --VERROR := SQLERRM;
            --  vperiodo_sep  := null;
           -- DBMS_OUTPUT.put_line (  'EROOR AL CALCULAR  RVOE:  ' || Vciclo_gtlg);
      END;



      ------REPRESENTANTE LEGAL AUTORIZA---
      BEGIN
         SELECT    SZTREDC_NOMBRE
                || ' '
                || SZTREDC_PATERNO
                || ' '
                || SZTREDC_MATERNO
           INTO VREP_AUTORIZA
           FROM SZTREDC CE
          WHERE 1 = 1
             AND CE.SZTREDC_IDCARGO = 1
             AND CE.SZTREDC_ESTATUS = 1    ;
      EXCEPTION
         WHEN OTHERS
         THEN
            VREP_AUTORIZA := NULL;
      END;


      -----------SE CALCULA EL EMAIL
      -- BEGIN
      BEGIN
         SELECT DISTINCT GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES
           INTO v_email_alumno
           FROM GOREMAL
          WHERE     GOREMAL_PIDM = ppidm
                AND GOREMAL_EMAL_CODE = ('PRIN')
                AND ROWNUM < 2;
      EXCEPTION
         WHEN OTHERS
         THEN
            --v_email_alumno:= 'ERROR';
            BEGIN
               SELECT DISTINCT GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES
                 INTO v_email_alumno
                 FROM GOREMAL
                WHERE     GOREMAL_PIDM = ppidm
                      AND GOREMAL_EMAL_CODE = ('ALTE')
                      AND ROWNUM < 2;
            EXCEPTION
               WHEN OTHERS
               THEN
                  SELECT DISTINCT GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES
                    INTO v_email_alumno
                    FROM GOREMAL
                   WHERE     GOREMAL_PIDM = ppidm
                         AND GOREMAL_EMAL_CODE = ('INST')
                         AND ROWNUM < 2;
            END;
      END;

      --   AQUI VAMOS A CALCULAR EL PERIODO ANTERIOR PARA SABER QUE PROMEDIO ANTERIOR TUVO
      BEGIN
         SELECT Zo.SZTQRON_CICLO_CURSA, zo.SZTQRON_PERIODO_ACT
           INTO VCICLO_ACTUAL, vperiodo_act
           FROM SZTQRON Zo
          WHERE 1 = 1 
            AND Zo.SZTQRON_PIDM = ppidm 
            AND Zo.SZTQRON_SEQNO_SIU = pfolio;
      EXCEPTION
         WHEN OTHERS
         THEN
            VCICLO_ACTUAL := '000';
      END;



      VPERIODO_ANT := BANINST1.PKG_QR_DIG.F_PERIODO_ANTERIOR (VCICLO_ACTUAL);


    /*   esto no aplica para DPLO
      IF PCODE = 'DIMA'
      THEN
         VDIMA := PKG_QR_DIG.F_DIMA (VCAMPUS, pprograma, Vciclo_gtlg);
         vnombre_alumn := INITCAP (vnombre_alumn);
      ELSE
         VDIMA := 'NO_MOSTRAR';
      END IF;

      IF PCODE = 'TIPR'
      THEN
         vnombre_alumn := INITCAP (vnombre_alumn);
      END IF;
    */

      -- aqui se van a calcular las otras para todos los accesorios que sean de educación continua EC glovicx 03.07.2023
      IF vnivel    = 'EC' then

         IF PCODE in ( 'DIPD', 'COES')  THEN
                 BEGIN
                    SELECT DISTINCT SZTDTEC_NUM_HORAS
                      INTO vnum_horas
                    FROM SZTDTEC
                    WHERE 1=1
                    AND SZTDTEC_PROGRAM   = pprograma;

                 EXCEPTION WHEN OTHERS THEN
                   vnum_horas  := 0;
                 END;
           --dbms_output.put_line('calcula el número de horas sztdtec'||vnum_horas  );
           --- calculamos la calificación  del modulo anterior regla dictada x betzy 11.05.023
          begin
                select max(SFRSTCR_GRDE_CODE)
                  INTO VPROM_ANTE
                    from sfrstcr f1
                    where 1=1
                    and f1.SFRSTCR_PIDM = ppidm
                    and f1.SFRSTCR_ADD_DATE  = (select max (f2.SFRSTCR_ADD_DATE )
                                                                     from sfrstcr f2
                                                                        where 1=1
                                                                          and f1.SFRSTCR_PIDM =  f2.SFRSTCR_PIDM );


          exception when others then
             VPROM_ANTE := 'NA';
           end;


         END IF;
      end if;

 --dbms_output.put_line('calcula el número de horas sztdtec'||vnum_horas  );

      -----esta parte es para cuando es un campues en ingles
      ---- esto es para cuando los documentos van en ingles. segun los campues en especial glovicx 27.09.022
      BEGIN
         SELECT DISTINCT 'Y'
           INTO vvalida_eng
           FROM zstpara
          WHERE     1 = 1
                AND ZSTPARA_PARAM_ID = vcampus
                AND ZSTPARA_MAPA_ID = 'COES_INGLES';
      EXCEPTION
         WHEN OTHERS
         THEN
            vvalida_eng := 'N';
      END;



          IF PCODE = 'COIN'  THEN  --- esta fecha va en ingles segun requerimento
         --  DBMS_OUTPUT.PUT_LINE ('dentro COIN  -- ' || pprograma||'-'|| ppidm);
         BEGIN
            SELECT DISTINCT TO_CHAR(MAX(SORLCUR_START_DATE), 'DD/MM/YYYY')
              INTO vfecha_inicio2
            FROM sorlcur c
            WHERE 1=1
            AND C.SORLCUR_PROGRAM  = pprograma
            and  C.SORLCUR_PIDM    =   ppidm ;

           -- DBMS_OUTPUT.PUT_LINE ('dentro fecha INIcio2 -- ' || vfecha_inicio2);


         EXCEPTION WHEN OTHERS THEN
           vfecha_inicio2  :='No lleva' ;
            DBMS_OUTPUT.PUT_LINE ('errorr en  fecha INIcio2 ingles -- ' || vfecha_inicio2);
         END;


      END IF;

        -- DBMS_OUTPUT.PUT_LINE ('antes de  fecha inglasXX00 -- ' || vvalida_eng);

      --SI ES YES ENTONCES HAY QUE CAMBIAR ALGUNOS DATOS A INGLES SOLO PARA COES GLOVICX 07.09.022
      IF vvalida_eng = 'Y'
      THEN
         vFECHA_RVOE := REPLACE (vFECHA_RVOE, ' ', '');

         --DBMS_OUTPUT.PUT_LINE ('dentro fecha inglasXX1 -- ' || vFECHA_RVOE);

            begin
         SELECT TO_CHAR (TO_DATE (vFECHA_RVOE, 'dd/mm/yyyy'),
                         'fmMonth dd, yyyy',
                         'NLS_DATE_LANGUAGE = English')
           INTO vFECHA_RVOE
           FROM DUAL;                                                    ---OK
            exception when others then
             vfecha_inicio2 := null;

             end;
           --- fecha de COin aqui se convierte a ingles siempre y cuando sea del campus ingles glovicx 28.06.2023
             begin

                SELECT TO_CHAR (TO_DATE (vfecha_inicio2, 'dd/mm/yyyy'),
                             'fmMonth dd, yyyy',
                             'NLS_DATE_LANGUAGE = English')
               INTO vfecha_inicio2
               FROM DUAL;

             exception when others then
             vfecha_inicio2 := null;

             end;

        -- DBMS_OUTPUT.PUT_LINE ('dentro fecha inglasXX22 -- ' || vFECHA_RVOE);
      ELSE
         vFECHA_RVOE := REPLACE (vFECHA_RVOE, ' ', '');
         vfecha_inicio2 := REPLACE (vfecha_inicio2, ' ', '');
      END IF;





    /*  DBMS_OUTPUT.put_line (
            'inicio calcula periodos '
         || ppidm
         || '--'
         || VCICLO_ACTUAL
         || '-'
         || VPERIODO_ANT
         || '-'
         || pfolio);

      DBMS_OUTPUT.put_line (
            'inicio calcula promedio '
         || ppidm
         || '--'
         || VPERIODO_ANT
         || '-'
         || VPROM_ANTE
         || '->'
         || vmodalidad);*/

      OPEN cur_alumnos FOR
         SELECT vmatricula "MATRICULA",
                Vcorreponda "CORRESPONDA",
                VCARGO "CARGO",
                VINSTITUTO "INSTITUTO",
                vnombre_alumn "NOMBRE_ALUMNO",
                VREP_AUTORIZA "AUTORIZA",
                vNO_RVOE "RVOE",
                vFECHA_RVOE "FECHA_RVOE",
                v_email_alumno "EMAIL_ALUMNO",
                VNOM_PROGRAMA "PROGRAMA",
                VPROM_ANTE "PROMEDIO_ANTERIOR",
                VDIMA "DURACIÓN",
                VSSN "SSNO",
                VPAIS "PAIS",
                vperiodo_act "PERIODO_ACT",
                vclave_escuela "CLAVE ESCUELA",
                SUBSTR (vperiodo_act, INSTR (vperiodo_act, '.', 1) + 1)  "cve_periodo",
                vmodalidad "Modalidad",
                vsexo "sexo",
                vnum_horas "num_horas",
                vfecha_inicio2  "fecha_ini"
           FROM DUAL;


      --dbms_output.put_line('fin de proceso ' );
      RETURN cur_alumnos;
   --  return (resultar);

EXCEPTION
      WHEN OTHERS
      THEN
         vl_error := 'PKG_QR_DIG.cur_alumnos: ' || SQLERRM;
         --DBMS_OUTPUT.put_line ('error general' || vl_error);
END f_datos_complemento;


FUNCTION f_xml_envio (pfolio        VARCHAR2,
                         pmatricula    VARCHAR2,
                         pcode         VARCHAR2)
      RETURN PKG_QR_ON.cur_datos_serv
   IS
      lv_pidm          NUMBER := 0;

      cur_alumnos      BANINST1.PKG_QR_ON.cur_datos_serv;


      vl_error         VARCHAR2 (1000);


      vpidm            NUMBER;
      vprograma        VARCHAR2 (12);
      vprograma_nom    VARCHAR2 (12);
      verror           VARCHAR2 (1000);

      --ALUMNOS_DATOS   SYS_REFCURSOR;
      ALUMNOS_DATOS    PKG_QR_ON.cur_datos_alumn;

      Vcorreponda      VARCHAR2 (120);
      VCARGO           VARCHAR2 (120);
      VINSTITUTO       VARCHAR2 (120);
      vnombre_alumn    VARCHAR2 (120);
      VREP_AUTORIZA    VARCHAR2 (120);
      VNO_RVOE         VARCHAR2 (12);
      VFECHA_RVOE      VARCHAR2 (20);
      v_email_alumno   VARCHAR2 (60);
      VNOM_PROGRAMA    VARCHAR2 (80);
      Vciclo_gtlg      VARCHAR2 (12);
      VCAMPUS          VARCHAR2 (4);
      vmatricula       VARCHAR2 (12);
      vbimestre        VARCHAR2 (50);
      VFECHA_EMI       VARCHAR2 (12);
      vno_mostrar      VARCHAR2 (12) := 'NO_MOSTRAR';
      vtalleres        VARCHAR2 (14);
      VSESO            NUMBER := 0;
      VCICLO_ACTUAL    VARCHAR2 (8);
      VPERIODO_ANT     VARCHAR2 (8);
      VPROM_ANTE       VARCHAR2 (12);
      VDIMA            VARCHAR2 (25);
      VTIPR            VARCHAR2 (250);
      vpuesto          VARCHAR2 (250);
      vvigencia     varchar2(20);
      vseqno        number:=0;

   BEGIN
      Vcorreponda := NULL;
      VCARGO := NULL;
      VINSTITUTO := NULL;
      VREP_AUTORIZA := NULL;
      VNO_RVOE := NULL;
      VFECHA_RVOE := NULL;
      VNOM_PROGRAMA := NULL;
      v_email_alumno := NULL;
      Vciclo_gtlg := NULL;
      VCAMPUS := NULL;
      vmatricula := NULL;
      vbimestre := NULL;
      VCICLO_ACTUAL := NULL;
      VTIPR := NULL;
      vseqno  := 0;


      vpidm := fget_pidm (pmatricula);

      BEGIN
         SELECT DISTINCT Q.SZTQRON_PROGRAMA, q.SZTQRON_CICLO_CURSA, q.SZTQRON_PROM_ANTERIOR,  Q.SZTQRON_SEQNO_SIU seqno
           INTO vprograma, VCICLO_ACTUAL, VPROM_ANTE, vseqno
           FROM SZTQRON q
          WHERE 1 = 1 
          AND q.SZTQRON_PIDM = vpidm 
          AND Q.SZTQRON_FOLIO_DOCTO = pfolio;
      EXCEPTION
         WHEN OTHERS
         THEN
            vprograma := NULL;
            VCICLO_ACTUAL := NULL;
            VPROM_ANTE := NULL;
           --  DBMS_OUTPUT.put_line ('salida 00:  ' || sqlerrm);
      END;



     -- DBMS_OUTPUT.PUT_LINE('iNICIA DE PROCESO xml---ANTES DE DATOS COMPLEM: '|| pfolio||'-'||vpidm||'-'||pcode||'-'||vprograma );
      -- ALUMNOS_DATOS := BANINST1.PKG_QR_DIG.f_datos_complemento  (pfolio, vpidm, pcode, vprograma );

      ---calcula el pidm y el nomnbre del alumno
      BEGIN
         SELECT DISTINCT ss.spriden_id matricula, p.SPBPERS_LEGAL_NAME
           INTO Vmatricula, vnombre_alumn
           FROM spriden ss, spbpers p
          WHERE 1 = 1
                AND ss.spriden_pidm = p.SPBPERS_PIDM
                AND SPRIDEN_CHANGE_IND IS NULL
                AND ss.SPRIDEN_PIDm = vpidm;
      EXCEPTION
         WHEN OTHERS
         THEN
            Vmatricula := NULL;
            vnombre_alumn := NULL;
            vl_error := SQLERRM;
          -- DBMS_OUTPUT.put_line ('salida 1:  ' || vl_error);
      END;



      ----calcula las fechas de matriculacion y la fechas de ctgl

      BEGIN
         SELECT DISTINCT t1.CTLG, T1.CAMPUS
           INTO Vciclo_gtlg, VCAMPUS
           FROM tztprog t1
          WHERE 1 = 1 AND t1.pidm = vpidm AND t1.programa = vprograma--and   t1.sp = ( select max(t2.sp)  from tztprog t2
                                                                     --                where t1.pidm = t2.PIDM   )
         ;
      EXCEPTION
         WHEN OTHERS
         THEN
            Vciclo_gtlg := '';
            VCAMPUS := '';
            --VERROR := SQLERRM;
          --  DBMS_OUTPUT.PUT_LINE (   'SALIDA ERROR: CALCULAR CICLOS f_XML_ENVIO  ');
            vl_error := SQLERRM;
          --  DBMS_OUTPUT.put_line ('salida 2:  ' || vl_error);
      END;

     -- DBMS_OUTPUT.PUT_LINE('SALIDA CALCULAR CICLOS TZTPROG  ' ||Vciclo_gtlg||'-'||  VCAMPUS   );

      -------AQUI SE CALCULAN LAS PREGUNTAS EXTRAS DE COES Y --
      /*   4    Persona a quien va dirigido el documento
      5    Cargo de la persona a quien va dirigido el documento
      6    Nombre de la institución a que va dirigido el documento
      */

      BEGIN
           SELECT DISTINCT NVL (SVRSVAD_ADDL_DATA_DESC, 'A quien corresponda')
             INTO Vcorreponda
             FROM svrsvpr v, SVRSVAD VA
            WHERE     1 = 1
                  --SVRSVPR_SRVC_CODE IN ('COES')
                  AND SVRSVPR_PROTOCOL_SEQ_NO IN (vseqno)
                  AND SVRSVPR_PIDM = vpidm
                  AND V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  AND va.SVRSVAD_ADDL_DATA_SEQ = '4' --VER CUAL NUMERO SE QUEDARON
         ORDER BY 1 DESC;
      EXCEPTION
         WHEN OTHERS
         THEN
            Vcorreponda := 'A quien corresponda:';
            vl_error := SQLERRM;
          --  DBMS_OUTPUT.put_line ('salida 3:  ' || vl_error);
      END;

      IF Vcorreponda IS NULL OR Vcorreponda = ' '
      THEN
         Vcorreponda := 'A quien corresponda:';
      END IF;


      BEGIN
           SELECT DISTINCT SVRSVAD_ADDL_DATA_DESC
             INTO VCARGO
             FROM svrsvpr v, SVRSVAD VA
            WHERE     1 = 1
                  --SVRSVPR_SRVC_CODE IN ('COES')
                  AND SVRSVPR_PROTOCOL_SEQ_NO IN (vseqno)
                  AND SVRSVPR_PIDM = vpidm
                  AND V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  AND va.SVRSVAD_ADDL_DATA_SEQ = '5' --VER CUAL NUMERO SE QUEDARON
         ORDER BY 1 DESC;
      EXCEPTION
         WHEN OTHERS
         THEN
            VCARGO := NULL;
            vl_error := SQLERRM;
          --  DBMS_OUTPUT.put_line ('salida 4:  ' || vl_error);
      END;



      BEGIN
           SELECT DISTINCT SVRSVAD_ADDL_DATA_DESC
             INTO VINSTITUTO
             FROM svrsvpr v, SVRSVAD VA
            WHERE     1 = 1
                  --SVRSVPR_SRVC_CODE IN ('COES')
                  AND SVRSVPR_PROTOCOL_SEQ_NO IN (vseqno)
                  AND SVRSVPR_PIDM = vpidm
                  AND V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  AND va.SVRSVAD_ADDL_DATA_SEQ = '6' --VER CUAL NUMERO SE QUEDARON
         ORDER BY 1 DESC;
      EXCEPTION
         WHEN OTHERS
         THEN
            VINSTITUTO := NULL;
            vl_error := SQLERRM;
           -- DBMS_OUTPUT.put_line ('salida 5:  ' || vl_error);
      END;

      --DBMS_OUTPUT.PUT_LINE('SALIDA coresponda y cargos e intituto ' ||Vcorreponda||'-'||  VCARGO ||'-'||VINSTITUTO  );


      ------REPRESENTANTE LEGAL AUTORIZA---
      BEGIN
         SELECT DISTINCT ZSTPARA_PARAM_VALOR nombre, ZSTPARA_PARAM_DESC descx
           INTO VREP_AUTORIZA, vpuesto
           FROM ZSTPARA
          WHERE     1 = 1
                AND ZSTPARA_MAPA_ID = 'FIRMA_DOCS_QR'
                AND ZSTPARA_PARAM_ID = 'FIRMA';
      EXCEPTION
         WHEN OTHERS
         THEN
            VREP_AUTORIZA := NULL;
            vl_error := SQLERRM;
           -- DBMS_OUTPUT.put_line ('salida 7:  ' || vl_error);
      END;

       -- DBMS_OUTPUT.put_line ('salida 7:  ' || VREP_AUTORIZA||'-'||vpuesto||'-'||vpidm);
      -----------SE CALCULA EL EMAIL
      -- BEGIN
      BEGIN
         SELECT DISTINCT GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES
           INTO v_email_alumno
           FROM GOREMAL
          WHERE     GOREMAL_PIDM = vpidm
                AND GOREMAL_EMAL_CODE = ('PRIN')
                AND ROWNUM < 2;
                
          -- DBMS_OUTPUT.put_line ('salida 9:  ' || v_email_alumno);  
           
      EXCEPTION
         WHEN OTHERS
         THEN
            --v_email_alumno:= 'ERROR';
            -- DBMS_OUTPUT.put_line ('error salida 9:  ' || sqlerrm);  
            BEGIN
               SELECT DISTINCT GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES
                 INTO v_email_alumno
                 FROM GOREMAL
                WHERE     GOREMAL_PIDM = vpidm
                      AND GOREMAL_EMAL_CODE = ('ALTE')
                      AND ROWNUM < 2;
            EXCEPTION
               WHEN OTHERS
               THEN
                  SELECT DISTINCT GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES
                    INTO v_email_alumno
                    FROM GOREMAL
                   WHERE     GOREMAL_PIDM = vpidm
                         AND GOREMAL_EMAL_CODE = ('INST')
                         AND ROWNUM < 2;
                      --   DBMS_OUTPUT.put_line ('salida 8a:  ' || sqlerrm);
            END;
      END;



      --dbms_output.put_line('inicio de procesoxx '||pfolio||'--'||vmatricula||'-'||Vcorreponda||'-'||VCARGO||'-'||VINSTITUTO
       --                ||'-'||VREP_AUTORIZA||'-'|| vNO_RVOE||'-'||vFECHA_RVOE||'-'||VNOM_PROGRAMA );



      ----CALCULA NUM DE TALLERES--

      BEGIN
         SELECT DISTINCT SMBPGEN_MAX_COURSES_I_NONTRAD
           INTO vtalleres
           FROM SMBPGEN
          WHERE     1 = 1
                AND SMBPGEN_PROGRAM = vprograma
                AND SMBPGEN_ACTIVE_IND = 'Y'
                AND SMBPGEN_TERM_CODE_EFF = Vciclo_gtlg;
      EXCEPTION
         WHEN OTHERS
         THEN
            vtalleres := 0;
      END;

      ---------VALIDA SI EL TALLER TIENE MATERIA DE SERVICIO SOCIAL SI TIENE HAY QUE RESTARLA A LA VARIABLE DE TALLERES
      -------- REGLA QUE DIO SUSY SAVEEDRA 10-03-021   GLOVICX

      BEGIN
         SELECT DISTINCT 1
           INTO VSESO
           FROM SMRPCMT
          WHERE     1 = 1
                AND SMRPCMT_TEXT LIKE ('%SESO%')
                AND SMRPCMT_PROGRAM = vprograma;
      EXCEPTION
         WHEN OTHERS
         THEN
            VSESO := 0;
      END;


      --NUMERO DE TALLERES MENOS SERVICIOSOCIAL  REGLA SUSY 10/03/021
      IF vtalleres = 0
      THEN
         NULL;
      ELSE
         vtalleres := vtalleres - VSESO;
      END IF;


      VPERIODO_ANT := PKG_QR_DIG.F_PERIODO_ANTERIOR (VCICLO_ACTUAL);

      

      IF pcode = 'COES'
      THEN
         VPROM_ANTE := VPROM_ANTE;
      ELSE
         VPROM_ANTE := 'NO_MOSTRAR';
      END IF;


      IF PCODE = 'DIMA'
      THEN
         VDIMA := PKG_QR_DIG.F_DIMA (VCAMPUS, vprograma, Vciclo_gtlg);
      -- se pidio oculatar estos campos para DIMA por orden susy 19/04/2021

      --CUATRIMESTRE EN CURSO
      --CICLO EN CURSO
      --CICLO INICIO
      --CICLO FIN
      --RVOE
      --FECHA RVOE


      ELSE
         VDIMA := 'NO_MOSTRAR';
      END IF;

      -----exception para titulo intermedio-- regla susy 23/04/021

      IF PCODE = 'TIPR'
      THEN
         VTIPR := PKG_QR_DIG.F_TI_INTERMEDIO (vpidm, vprograma);

         --en esta parte le quita lo de las materias y solo manda la cadena
         --VTIPR := substr(VTIPR,4);
         SELECT SUBSTR (VTIPR, INSTR (VTIPR, '|') + 1) INTO VTIPR FROM DUAL;
      ELSE
         VTIPR := 'NO_MOSTRAR';
      END IF;
    ------ nuevo ajuste para las credenciales CRED y CREX  glovicx 27.06.2023
    /* reglas malu:
    CRED:    Nombre del Alumno, Matrícula, Programa, Vigencia, Fecha de emisión de documento y Nombre y cargo del Director de Servicios Escolares y Regulación
   CREX:   Nombre del alumno, Matrícula, Programa, Fecha de emisión y Nombre y cargo del Director de Servicios Escolares y Regulación
    */
      IF PCODE in ('CRED','CREX')
      THEN
      -- SE MANDA PARA OCULTAR EN SIR
      VTIPR :=  'NO_MOSTRAR';
      VPROM_ANTE :=  'NO_MOSTRAR';
      VDIMA :=  'NO_MOSTRAR';
      --vvigencia :=  F_VIGENCIA_CRED  (DATOS.FECHA_EMISION );

      ELSE
      VPUESTO :=  'NO_MOSTRAR';

      end IF;



  /*    DBMS_OUTPUT.PUT_LINE (
            'DATOS EN LOOP: '
         || vmatricula
         || '-'
         || Vcorreponda
         || '-'
         || VCARGO
         || '-'
         || vNO_RVOE
         || '-'
         || vtalleres
         || '-'
         || Vciclo_gtlg
         || VPROM_ANTE); 
*/

      OPEN cur_alumnos FOR
         SELECT DISTINCT
                datos.NOM_ACC "TIPO DE DOCUMENTO",
                datos.no_solicitud "NO SOLICITUD",
                datos.folio_doct "FOLIO DEL DOCUMENTO",
                vmatricula "MATRÍCULA",
                vnombre_alumn "NOMBRE",
                VTIPR "TÍTULO INTERMEDIO",
                CASE
                   WHEN PCODE IN ('COTE', 'DIMA', 'DIPD', 'CRED','CREX') THEN vno_mostrar
                   ELSE DATOS.BIM_ACTUAL
                END
                   "BIMESTRE/CUATRIMESTRE EN CURSO",
                datos.NOM_PROG "PROGRAMA INSCRITO",
                CASE
                   WHEN PCODE IN ('COTE', 'DIMA',  'CRED','CREX') THEN vno_mostrar
                   ELSE datos.ciclo_cursa
                END
                   "CICLO EN CURSO",
                CASE
                   WHEN PCODE IN ('COTE', 'DIMA',  'CRED','CREX') THEN vno_mostrar
                   ELSE datos.ciclo_inicio
                END    "CICLO INICIO",
                CASE
                   WHEN PCODE IN ('COTE', 'DIMA',  'CRED','CREX') THEN vno_mostrar
                   ELSE datos.ciclo_fin
                END
                   "CICLO FIN",
                 CASE
                   WHEN PCODE IN ('CRED','CREX') THEN 999 --vno_mostrar
                   ELSE datos.materías_ac
                END   "MATERIAS ACREDITADAS",
                 CASE
                   WHEN PCODE IN ('CRED','CREX') THEN 999 --vno_mostrar
                   ELSE datos.materías_total
                 END  "MATERIAS TOTAL",
                 CASE
                   WHEN PCODE IN ('CRED','CREX') THEN vno_mostrar
                   ELSE datos.avance || '%'
                 END  "AVANCE",
                 CASE
                   WHEN PCODE IN ('CRED','CREX') THEN vno_mostrar
                   ELSE  datos.promedio
                 END    "PROMEDIO GENERAL",
                VPROM_ANTE "PROMEDIO CUATRIMESTRE ANTERIOR",
                CASE
                   WHEN PCODE IN ('DIMA','CRED','CREX' ) THEN vno_mostrar
                   ELSE DATOS.RVOE
                END  "RVOE",
                CASE
                   WHEN PCODE IN ('DIMA', 'CRED','CREX') THEN vno_mostrar
                   ELSE TO_CHAR (DATOS.FECHA_RVOE)
                END    "FECHA RVOE",
                VREP_AUTORIZA "AUTORIZA",
                VPUESTO "PUESTO",
                NVL (DATOS.FECHA_EMISION, 'Sin envío') "FECHA DE EMISIÓN",
                VDIMA "DURACIÓN",
                CASE WHEN PCODE IN ('CRED') THEN
                   --   datos.vigencia
                     -- TO_CHAR (ADD_MONTHS(DATOS.FECHA_EMISION, 36), 'DD/MM/YYYY')
                  PKG_QR_DIG.F_VIGENCIA_CRED(SYSDATE)
                  ELSE
                       'NO_MOSTRAR'
                END "VIGENCIA"
           FROM (  SELECT DISTINCT
                          Q.SZTQRON_PIDM pidm,
                          Q.SZTQRON_AVANCE avance,
                          Q.SZTQRON_PROMEDIO promedio,
                          Q.SZTQRON_FOLIO_DOCTO folio_doct,
                          Q.SZTQRON_SEQNO_SIU no_solicitud,
                          (SELECT DISTINCT SVVSRVC_DESC
                             FROM SVVSRVC
                            WHERE SVVSRVC_CODE = Q.SZTQRON_CODE_ACCESORIO) NOM_ACC,
                          Q.SZTQRON_NO_MATERIAS_ACRED materías_ac,
                          Q.SZTQRON_NO_MATERIAS_TOTAL + vtalleres materías_total, --SE LE SUMAN LOS TALLERES AL TOTAL REGLA SUSY 10/03/021
                          Q.SZTQRON_CICLO_CURSA ciclo_cursa,
                          Q.SZTQRON_FECHAS_CICLO_INI ciclo_inicio,
                          Q.SZTQRON_FECHAS_CICLO_FIN ciclo_fin,
                          Q.SZTQRON_FECHA_ENVIO FECHA_EMISION,
                          Q.SZTQRON_PERIODO_ACT BIM_ACTUAL,
                          QR.RVOE RVOE,
                          QR.FECHA_RVOE FECHA_RVOE,
                          QR.NOMBRE_PROGRAMA NOM_PROG
                          ,TO_CHAR (ADD_MONTHS(SYSDATE, 36), 'DD/MM/YYYY') vigencia
                     FROM SZTQRON Q, DATOS_QR QR
                    WHERE     1 = 1
                          AND Q.SZTQRON_FOLIO_DOCTO = pfolio
                          AND Q.SZTQRON_PIDM = vpidm     -- fget_pidm( pmatricula)
                          AND QR.CVE_PROG = vprograma
                          AND Q.SZTQRON_FECHA_ENVIO IS NOT NULL
                 ORDER BY 1) datos;

      --dbms_output.put_line('fin del proceso ');
      RETURN cur_alumnos;
   --  return (resultar);

 EXCEPTION
      WHEN OTHERS
      THEN
         vl_error := 'PKG_QR_ON.cur_alumnos: ' || SQLERRM;
         RETURN cur_alumnos;

         DBMS_OUTPUT.put_line ('eror general proceso ' || vl_error);
END f_xml_envio;



END PKG_QR_ON;
/

DROP PUBLIC SYNONYM PKG_QR_ON;

CREATE OR REPLACE PUBLIC SYNONYM PKG_QR_ON FOR BANINST1.PKG_QR_ON;


GRANT EXECUTE ON BANINST1.PKG_QR_ON TO PUBLIC WITH GRANT OPTION;
