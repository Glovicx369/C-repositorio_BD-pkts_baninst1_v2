DROP PACKAGE BODY BANINST1.PKG_QR_DIG;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_QR_DIG
IS
   VREG_INSERTA   NUMBER := 0;

   ---procedimiento que se va ejecutar cada hora o cada dia recupera el universo de las solicitudes digitales y las
   -- guarda en la nueva tabla de donde despues SIR tiene que leer y mandar los regs que tenga marca de envio= 0
   -- se modifica cursol principal para proyecto costo cero QR; glovicx 10.08.022

   PROCEDURE p_universo (ppidm NUMBER)
   IS
      CURSOR c_universo
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
                  AND TRUNC (V.SVRSVPR_RECEPTION_DATE) >= ('17/07/2020')
                  AND V.SVRSVPR_PIDM = NVL (ppidm, V.SVRSVPR_PIDM)
                  AND SVRSVPR_SRVS_CODE IN ('PA', 'CL') -- se agrega parametro para proyecto costo cero_QR
                  AND V.SVRSVPR_SRVC_CODE IN
                         (SELECT ZSTPARA_PARAM_ID
                            FROM ZSTPARA
                           WHERE 1 = 1 AND ZSTPARA_MAPA_ID = 'CODIGOQR') --parametrizador hay que hacer uno
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
                                FROM SZTQRDG
                               WHERE     1 = 1
                                     AND szt_pidm = v.SVRSVPR_PIDM
                                     AND szt_seqno_siu =    V.SVRSVPR_PROTOCOL_SEQ_NO)
                  AND NOT EXISTS
                             (SELECT 1
                                   from SVRSVPR vv
                                     where 1=1
                                      and VV.SVRSVPR_PIDM = v.SVRSVPR_PIDM
                                      and VV.SVRSVPR_PROTOCOL_SEQ_NO =    V.SVRSVPR_PROTOCOL_SEQ_NO
                                      and  VV.SVRSVPR_SRVC_CODE  in ('CRED','CREX')
                                       AND TRUNC (V.SVRSVPR_RECEPTION_DATE) <= ('17/07/2023')
                                      )
         --AND 'PAGADO'  = UPPER((  SELECT F_VALIDA_PAGO_ACCESORIO (  v.SVRSVPR_PIDM, V.SVRSVPR_ACCD_TRAN_NUMBER)   FROM DUAL    ) )

         -- and v.SVRSVPR_SRVS_CODE = 'PA'
         ORDER BY V.SVRSVPR_SRVC_CODE;



      VSECUENCIA           VARCHAR2 (50);
      squery               VARCHAR2 (70);
      squery2              VARCHAR2 (50);
      VAVANCE              varchar2(8);
      VPROMEDIO            SZTQRDG.SZT_PROMEDIO%TYPE;
      VFOLIO_DOCTO         SZTQRDG.SZT_FOLIO_DOCTO%TYPE;
      VNO_MATERIAS_ACRED   SZTQRDG.SZT_NO_MATERIAS_ACRED%TYPE;
      VNO_MATERIAS_TOTAL   SZTQRDG.SZT_NO_MATERIAS_TOTAL%TYPE;
      VSEC_FOLIO           SZTQRDG.SZT_SEQ_FOLIO%TYPE;
      VSEC_FOLIO2          VARCHAR2 (10);
      VCICLO               SZTQRDG.SZT_CICLO_CURSA%TYPE;
      VCICLO_INI           SZTQRDG.SZT_FECHAS_CICLO_INI%TYPE;
      VCICLO_FIN           SZTQRDG.SZT_FECHAS_CICLO_FIN%TYPE;
      Vciclo_gtlg          VARCHAR2 (10);
      VERROR               VARCHAR2 (1000);
      vtalleres            NUMBER;
      vmateria             VARCHAR2 (19);
      VSEM_ACTUAL          VARCHAR2 (70);
      VNO_RVOE             VARCHAR2 (30);
      VFECHA_RVOE          VARCHAR2 (30);

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
   BEGIN
      --DBMS_OUTPUT.put_line ('INICIA PROCESO ANTES LOOP'  );
      FOR jump IN c_universo
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
        /* DBMS_OUTPUT.put_line (
               'INICIA PROCESO DENTRO LOOP ANTES DE CICLOS:  '
            || JUMP.PIDM
            || '-'
            || JUMP.PROGRAMA);
      */
         ----calcula las fechas de inicio de clases  y la fechas de ctgl Son para todos menos COES

         BEGIN
            SELECT t1.CTLG,
                   TO_CHAR (t1.fecha_inicio, 'DD-Month-yyyy'),
                   T1.CAMPUS
              INTO Vciclo_gtlg, VCICLO_INI, vcampus
              FROM tztprog t1
             WHERE     1 = 1
                   AND t1.pidm = JUMP.PIDM
                   AND t1.programa = jump.programa--and   t1.sp = ( select max(t2.sp)  from tztprog t2  where t1.pidm = t2.PIDM   )
            ;
         EXCEPTION
            WHEN OTHERS
            THEN
               Vciclo_gtlg := NULL;
               VCICLO_INI := NULL;
               VERROR := SQLERRM;
             --  DBMS_OUTPUT.PUT_LINE (  'SALIDA ERROR: CALCULAR CICLOS TZTPROG  ' || VERROR);
         END;



         -----OBTENER TOTAL DE MATERIAS-- Y PROMEDIO ACTUAL
         begin
         VNO_MATERIAS_TOTAL :=  BANINST1.PKG_DATOS_ACADEMICOS.TOTAL_MATE2 (JUMP.PIDM, JUMP.PROGRAMA);

         exception  when others then
          verror := sqlerrm;
          dbms_output.put_line('error en total mate :: '||verror ||'--'|| JUMP.PIDM||'--'|| JUMP.PROGRAMA);

         end;

        begin
         VPROMEDIO := BANINST1.PKG_DATOS_ACADEMICOS.promedio1 (JUMP.PIDM, JUMP.PROGRAMA);
        exception  when others then
          verror := sqlerrm;
          dbms_output.put_line('error en total promedio1 :: '||verror ||'--'|| JUMP.PIDM||'--'|| JUMP.PROGRAMA);

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
                                  AND f.SFRSTCR_PIDM = JUMP.PIDM
                      AND SUBSTR (f.SFRSTCR_TERM_CODE, 5, 1) !=  '8'
                     AND f.SFRSTCR_TERM_CODE =  (SELECT MAX (f2.SFRSTCR_TERM_CODE)
                                            FROM sfrstcr f2
                                           WHERE     1 = 1
                                                                                 AND f2.SFRSTCR_PIDM =   f.SFRSTCR_PIDM
                                                                                 AND SUBSTR ( f2.SFRSTCR_TERM_CODE,5, 1) NOT IN ('8', '9'))
                )
              --  AND ss.SSBSECT_SUBJ_CODE || ss.SSBSECT_CRSE_NUMB NOT LIKE ('%H%')
                AND ss.SSBSECT_SUBJ_CODE || ss.SSBSECT_CRSE_NUMB NOT LIKE  ('%SESO%')
                group by ss.SSBSECT_TERM_CODE
                ) datos
                ;
         EXCEPTION
            WHEN OTHERS
            THEN
               VCICLO := NULL;
               vinicio2 := NULL;
           --  DBMS_OUTPUT.PUT_LINE ('ERROR1 EN FECHAS INICIO ' || jump.pidm || '--' || SQLERRM);
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
                                  AND f.SFRSTCR_PIDM = JUMP.PIDM
                                  AND SUBSTR (f.SFRSTCR_TERM_CODE, 5, 1) !=  '8'
                                  AND f.SFRSTCR_TERM_CODE =  (SELECT MAX (f2.SFRSTCR_TERM_CODE)
                                                                                    FROM sfrstcr f2
                                                                                   WHERE     1 = 1
                                                                                         AND f2.SFRSTCR_PIDM =   f.SFRSTCR_PIDM
                                                                                         AND SUBSTR ( f2.SFRSTCR_TERM_CODE,5, 1) NOT IN ('8', '9'))
                )
              -- AND ss.SSBSECT_SUBJ_CODE || ss.SSBSECT_CRSE_NUMB NOT LIKE ('%H%')
                AND ss.SSBSECT_SUBJ_CODE || ss.SSBSECT_CRSE_NUMB NOT LIKE  ('%SESO%')
                group by ss.SSBSECT_TERM_CODE
                ) datos
                ;
          EXCEPTION
            WHEN OTHERS
            THEN
               VCICLO := NULL;
               vfin2 := NULL;
            -- DBMS_OUTPUT.PUT_LINE ('ERROR1 EN MATERIAS ' || jump.pidm || '--' || SQLERRM);
         END;

      /*   DBMS_OUTPUT.PUT_LINE (
               'recupera las MATERIAS '
            || VCICLO
            || '-'
            || vinicio2
            || '--'
            || vfin2
            || '-'
            || vcrn);  */


         ---------obtiene las fechas de inicio y fin del ciclo en curso--hay que validar si es solo para COES o para todos
         IF JUMP.CODE_ACC = 'COES' AND jump.nivel IN ('MA', 'MS', 'DO')
         THEN
            VCICLO_INI := vinicio2; --- segun regla se susi vienen de la parte de periodo que cursa ACTUALMENTE
            VCICLO_FIN := vfin2;                                --  mismo caso
         ELSIF JUMP.CODE_ACC = 'COES'
         THEN
            BEGIN
               SELECT TO_CHAR (SOBPTRM_END_DATE, 'DD-Month-yyyy')
                 INTO VCICLO_FIN
                 FROM sobptrm
                WHERE     1 = 1
                      AND SOBPTRM_PTRM_CODE = '1'
                      AND SOBPTRM_TERM_CODE = VCICLO;
            EXCEPTION
               WHEN OTHERS
               THEN
                  -- VCICLO_INI  := null;
                  VCICLO_FIN := NULL;
            END;

            -- con  base al ultimo mail se susy para LIC tambien debe quedar asi glovicx 25/11/021
            VCICLO_INI := vinicio2; --- segun regla se susi vienen de la parte de periodo que cursa ACTUALMENTE
         ELSE -------si no es coes solo busca la fecha final por que la fecha Inicial ya    la calculo glovicx 12/07/021

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
         END IF;

         ------OBTIENE EL AVANCE CURRICULAR ---nueva forma glovicx 25.01.23


           Begin
                  SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 (JUMP.PIDM, JUMP.PROGRAMA)
                    INTO VAVANCE
                    FROM DUAL;
               --   DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
         EXCEPTION
            WHEN OTHERS
            THEN
               VAVANCE := 0;
               END;

                 IF TO_NUMBER(VAVANCE) >= 100 THEN
                       VAVANCE := '100';
                  END IF;

               -------------   numero materias creditadas nuevo glovicx
            BEGIN
                  SELECT BANINST1.PKG_DATOS_ACADEMICOS.acreditadas1 (JUMP.PIDM, JUMP.PROGRAMA)
                    INTO VNO_MATERIAS_ACRED
                    FROM DUAL;
               --   DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VNO_MATERIAS_ACRED := 0;
         END;




         ----------COSNTRUYE EL FOLIO OFICIAL DEL DOCUMENTO SEGUN RGLAS
         /*
         Ejemplo:
         COES20/0720
         COES =  código de autoservicio definido para el documento.
         20 = Año de emisión.
         / = es un identificador de separación.
         0720 = consecutivo de número de constancias emitidas (el número con el vamos a dar inicio con el conteo es 700 en adelante).
         */

         ---SE OBTIENE LA SECUENCIA DEPENDIENDO DEL CODIGO

         BEGIN
            SELECT ZSTPARA_PARAM_VALOR
              INTO VSECUENCIA
              FROM ZSTPARA
             WHERE     1 = 1
                   AND ZSTPARA_MAPA_ID = 'CODIGOQR'
                   AND ZSTPARA_PARAM_ID = JUMP.CODE_ACC;
         EXCEPTION
            WHEN OTHERS
            THEN
               VSECUENCIA := NULL;
         END;

         --IF  JUMP.CODE_ACC = 'COES' THEN
         ----PRIMERO CALCULAMOS EL CONSECUTIVO-- PARA ESTE TIPO

         squery := 'SELECT ' || VSECUENCIA;
         squery2 := squery || ' FROM DUAL';

         -- dbms_output.put_line('salida_SECUENCIA..>>>>'||squery2);



         EXECUTE IMMEDIATE (squery2) INTO VSEC_FOLIO;

         --dbms_output.put_line('salida..SEQ.>>>>'||JUMP.CODE_ACC||'---'|| VSEC_FOLIO|| ' MATERIA '|| trim(VMATERIA));



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


         VFOLIO_DOCTO := SUBSTR (JUMP.CODE_ACC, 1, 3) || TO_CHAR (SYSDATE, 'YYYY')|| '/'|| VSEC_FOLIO2;

         --DBMS_OUTPUT.put_line (  'salida..FOLIO.>>>>' || VFOLIO_DOCTO || '--' || Vciclo_gtlg);

         --END IF;


         ------CALCULA NUM DE TALLERES--

         BEGIN
            SELECT DISTINCT SMBPGEN_MAX_COURSES_I_NONTRAD
              INTO vtalleres
              FROM SMBPGEN
             WHERE     1 = 1
                   AND SMBPGEN_PROGRAM = JUMP.PROGRAMA
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
                   AND SMRPCMT_PROGRAM = JUMP.PROGRAMA;
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
                   AND zt.SZTDTEC_CAMP_CODE = JUMP.CAMPUS
                   AND zt.SZTDTEC_PROGRAM = JUMP.PROGRAMA
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
            || JUMP.PIDM
            || '-'
            || JUMP.PROGRAMA
            || '-'
            || jump.nivel
            || '-'
            || jump.CAMPUS
            || '-'
            || jump.CAMPUS); */


         ----se ejecuta la funcion para saber en que cuatrimestre se encuentra
         VSEM_ACTUAL := BANINST1.PKG_QR_DIG.F_curso_actual (JUMP.PIDM,JUMP.PROGRAMA,jump.nivel,jump.CAMPUS);


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
         IF   -- JUMP.CODE_ACC = 'CAPS'   se quito nueva regla MALU 11.10.2023 glovicx
           -- OR JUMP.CODE_ACC = 'TIPR'    --- SE QUITO ESTA OPCION NUEVO REQUERIMIENTO VER SI TODAS SE QUITAN O SOLO ESA GLOVICX 1.03.2023
            JUMP.CODE_ACC = 'CEAP'
         THEN
            VFECHA_ENVIO_CAP :=  REPLACE ( TO_CHAR (SYSDATE, 'DD-MONTH-yyyy')|| '-' || TO_CHAR (SYSDATE, 'HH24:MI:SS'), ' ','');
            VSTATUS_ENVIO := 1;
         ELSE
            VFECHA_ENVIO_CAP := NULL;
            VSTATUS_ENVIO := NULL;
         END IF;


         --VPERIODO_ANT := BANINST1.PKG_QR_DIG.F_PERIODO_ANTERIOR ( VCICLO ); ya no se usa

         --DBMS_OUTPUT.put_line ('despues de calcula f_periodo_anterior:  '||VCICLO ||'-'|| VPERIODO_ANT   );

         ------busca las materias del periodo anterior y ssaca promedio

         ---------AQUI TOMA EL PROMEDIO ANTERIOR INMEDIATO POR SI EXISTE QUE SE BRINCO UN PERIODO ENTONCES BUSCA EL ÚLTIMO MENOR AL ACTUAL GLOVICX 12/07/021

         BEGIN
              SELECT TRIM (TO_CHAR (AVG (SFRSTCR_GRDE_CODE), '999.99'))
                        AS promedio
                INTO VPROM_ANTE
                FROM sfrstcr f1
               WHERE     1 = 1
                     AND f1.SFRSTCR_PIDM = JUMP.PIDM
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


         IF jump.nivel IN ('MA', 'MS', 'DO')
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
                                          AND SFRSTCR_PIDM = JUMP.PIDM
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
                                                AND SFRSTCR_PIDM = JUMP.PIDM
                                                AND f.SFRSTCR_GRDE_CODE NOT IN ('NA', 'NP', 'AC')
                                                AND f.SFRSTCR_GRDE_CODE IS NOT NULL
                                                AND f.SFRSTCR_GRDE_CODE != '5.0'
                                                AND SUBSTR (F.SFRSTCR_TERM_CODE, 5, 1) NOT IN (8, 9)
                                                AND (SFRSTCR_TERM_CODE,SFRSTCR_PTRM_CODE) IN
                                                       (  SELECT DISTINCT MAX ( f2.SFRSTCR_TERM_CODE),f2.SFRSTCR_PTRM_CODE
                                                            FROM SFRSTCR f2
                                                           WHERE     1 = 1
                                                                 AND f2.SFRSTCR_PIDM = JUMP.PIDM
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
         IF vvalida_eng = 'Y'                   /*AND JUMP.CODE_ACC = 'COES'*/
         THEN


            SELECT TO_CHAR (TO_DATE (vinicio2, 'dd/mm/yyyy'),
                            'fmMonth dd, yyyy',
                            'NLS_DATE_LANGUAGE = English')
              INTO F_INI_ENG
              FROM DUAL;                                                 ---OK

          /*  DBMS_OUTPUT.PUT_LINE (
                  'dentro fecha inglasXX22 -- '
               || F_INI_ENG
               || '----'
               || vinicio2);*/

            SELECT TO_CHAR (TO_DATE (vfin2, 'dd/mm/yyyy'), 'fmMonth dd, yyyy', 'NLS_DATE_LANGUAGE = English')
              INTO F_FIN_ENG
              FROM DUAL;                                                 ---OK

           -- DBMS_OUTPUT.PUT_LINE ( 'dentro fecha inglasXX33 -- ' || F_FIN_ENG || '----' || vfin2);

            VCICLO_INI := F_INI_ENG;   --- AQUI LOS SOBRE ESCRIBE LAS VARIABLE
            VCICLO_FIN := F_FIN_ENG;

            IF VPROM_ANTE IS NULL
            THEN
               VPROM_ANTE := 'in progress';
            END IF;


         ELSIF JUMP.CODE_ACC = 'DIPD' THEN  -- para los diplomados o cursos se toma de otro lado la fecha de inicio regla fernando 24.04.2023

                begin
                      select distinct TO_CHAR (FECHA_PRIMERA, 'DD-Month-yyyy')
                      into   VCICLO_INI
                        from tztprog
                        where 1=1
                                and pidm = JUMP.PIDM
                                and programa = JUMP.PROGRAMA   ;


                exception when others then
                VCICLO_INI  := null;

                end;

                    VCICLO_INI := REPLACE (TRIM (VCICLO_INI), ' ', '');

         ELSE                                      -----SON CAMPUS EN ESPAÑOL
            VCICLO_INI := REPLACE (TRIM (VCICLO_INI), ' ', '');
            VCICLO_FIN := REPLACE (TRIM (VCICLO_FIN), ' ', '');

            IF VPROM_ANTE IS NULL
            THEN
               VPROM_ANTE := 'en curso';
            END IF;


           -- DBMS_OUTPUT.PUT_LINE ('dentro fecha inglas  x44  ' || VCICLO_INI);
         END IF;

         -- -- TO_CHAR (BB.SSBSECT_PTRM_START_DATE ,'DD-Month-yyyy'),TO_CHAR(BB.SSBSECT_PTRM_END_DATE ,'DD-Month-yyyy')

        /* DBMS_OUTPUT.PUT_LINE (
               'ANTES DE INSERTAR LA TABLA'
            || JUMP.PIDM
            || '-'
            || JUMP.PROGRAMA
            || '-'
            || JUMP.SEQNO
            || '-'
            || TO_CHAR (VPROMEDIO, 99.99)
            || '-'
            || VCICLO_INI
            || '-'
            || VCICLO_FIN); */

         --------------------------------HAY AUQ AGREGARA A LA TABLA LA COLUMNA DE EMAIL Y OBTENER EL NOMBRE
         ------DEL PROGRAMA NO EL CODIGO ..  Y EL NOMBRE QUITARLE LA DIAGONAL Y EL GUION ---
        IF  JUMP.CODE_ACC = 'DPLO' THEN     
        --- SE AGREGO ESTA OPCION PARA QUE NO INSERTE DPLO EN LA TABLA YA QUE ESTE ACCESORIOSE INSERTA EN QR_ON GLOVICX 25.11/2024
       
         null;
       
        else
       
             BEGIN
                INSERT INTO SZTQRDG (SZT_PIDM,
                                     --SZT_MATRICULA,
                                     SZT_PROGRAMA,
                                     --SZT_NOMBRE,
                                     SZT_AVANCE,
                                     SZT_PROMEDIO,
                                     SZT_FOLIO_DOCTO,
                                     SZT_SEQNO_SIU,
                                     SZT_CODE_ACCESORIO,
                                     --SZT_REP_AUTORIZA,
                                     SZT_ENVIO_ALUMNO,
                                     SZT_FECHA_ENVIO,
                                     SZT_ACTIVITY_DATE,
                                     --SZT_NO_RVOE,
                                     --SZT_FECHA_RVOE,
                                     SZT_NO_MATERIAS_ACRED,
                                     SZT_NO_MATERIAS_TOTAL,
                                     SZT_CODE_QR,
                                     SZT_USER,
                                     SZT_DATA_ORIGIN,
                                     SZT_SEQ_FOLIO,
                                     SZT_CICLO_CURSA,
                                     SZT_FECHAS_CICLO_INI,
                                     SZT_FECHAS_CICLO_FIN,
                                     --SZT_EMAIL,
                                     --SZT_NOMBRE_PROG,
                                     SZT_TALLERES,
                                     SZT_PERIODO_ACT--SZT_CORRESPONDA,
                                                    --SZT_CARGO,
                                                    --SZT_INSTITUCIÓN
                                     ,
                                     SZT_prom_anterior)
                     VALUES (
                               JUMP.PIDM,
                               --JUMP.MATRICULA,
                               JUMP.PROGRAMA,
                               --JUMP.NOMBRE,
                               VAVANCE,
                               REPLACE (TO_CHAR (TRIM (VPROMEDIO), 99.99),' ',''),
                               VFOLIO_DOCTO,
                               JUMP.SEQNO,
                               JUMP.CODE_ACC,
                               --VREP_AUTORIZA,
                               VSTATUS_ENVIO,                      --ENVIO_ALUMNO,
                               VFECHA_ENVIO_CAP,                --SZT_FECHA_ENVIO,
                               REPLACE ( TO_CHAR (SYSDATE, 'DD-MONTH-yyyy')|| '-'|| TO_CHAR (SYSDATE, 'HH24:MI:SS'),' ',''),
                               --VNO_RVOE,
                               --REPLACE (TRIM(VFECHA_RVOE),' ',''),
                               -- TRIM(to_char (VFECHA_RVOE,'DD')||to_char (VFECHA_RVOE,'Month')||to_char (VFECHA_RVOE,'YYYY')) ,
                               VNO_MATERIAS_ACRED,
                               VNO_MATERIAS_TOTAL,
                               NULL,                                --SZT_CODE_QR,
                               USER,                                   --SZT_USER,
                               'QR_DIGITAL',                     --SZT_DATA_ORIGIN
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
                               VPROM_ANTE);

                VREG_INSERTA := SQL%ROWCOUNT;
             EXCEPTION
                WHEN OTHERS
                THEN
                   NULL;
             END;

             BEGIN
                SELECT 1
                  INTO val_prog
                  FROM datos_qr QR
                 WHERE 1 = 1 AND QR.CVE_PROG = JUMP.PROGRAMA;
             EXCEPTION
                WHEN OTHERS
                THEN
                   val_prog := 0;
             END;

             BEGIN
                IF val_prog = 0
                THEN
                   INSERT INTO datos_qr
                        VALUES (JUMP.PROGRAMA,VNO_RVOE,REPLACE (VFECHA_RVOE, ' ', ''),vnom_prog);
                END IF;
             EXCEPTION
                WHEN OTHERS
                THEN
                   NULL;
             END;

       END IF;
       



         COMMIT;
      END LOOP;
   --COMMIT;



   END p_universo;


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
               from SZTQRDG
                WHERE 1 = 1
                AND SZT_PIDM = ppidm
                AND SZT_PROGRAMA = pprog
                AND SZT_SEQNO_SIU = pseqno
                and SZT_ENVIO_ALUMNO in (select distinct z1.ZSTPARA_PARAM_ID
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
                 UPDATE SZTQRDG
                    SET SZT_ENVIO_ALUMNO = pestatus,
                        SZT_FECHA_ENVIO = REPLACE (TO_CHAR (SYSDATE, 'DD-MONTH-yyyy') || '-' || TO_CHAR (SYSDATE, 'HH24:MI:SS'), ' ', ''),
                         SZT_COMENTARIOS   = pcomentario
                  WHERE     1 = 1
                        AND SZT_PIDM = ppidm
                        AND SZT_PROGRAMA = pprog
                        AND SZT_SEQNO_SIU = pseqno;

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


Commit;

END f_marca_envio;



   FUNCTION f_xml_envio (pfolio        VARCHAR2,
                         pmatricula    VARCHAR2,
                         pcode         VARCHAR2)
      RETURN PKG_QR_DIG.cur_datos_serv
   IS
      lv_pidm          NUMBER := 0;

      cur_alumnos      BANINST1.PKG_QR_DIG.cur_datos_serv;


      vl_error         VARCHAR2 (1000);


      vpidm            NUMBER;
      vprograma        VARCHAR2 (14);
      vprograma_nom    VARCHAR2 (12);
      verror           VARCHAR2 (1000);

      --ALUMNOS_DATOS   SYS_REFCURSOR;
      ALUMNOS_DATOS    PKG_QR_DIG.cur_datos_alumn;

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
      VCICLO_ACTUAL    VARCHAR2 (10);
      VPERIODO_ANT     VARCHAR2 (8);
      VPROM_ANTE       VARCHAR2 (16);
      VDIMA            VARCHAR2 (25);
      VTIPR            VARCHAR2 (250);
      vpuesto          VARCHAR2 (250);
      vvigencia       varchar2(20);
      vseqno          number:=0;

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
         SELECT DISTINCT Q.SZT_PROGRAMA, q.SZT_CICLO_CURSA, q.SZT_prom_anterior,  Q.SZT_SEQNO_SIU seqno
           INTO vprograma, VCICLO_ACTUAL, VPROM_ANTE, vseqno
           FROM SZTQRDG q
          WHERE 1 = 1 
            AND q.szt_pidm = vpidm 
            AND Q.SZT_FOLIO_DOCTO = pfolio;
      EXCEPTION  WHEN OTHERS    THEN
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

      begin
      VPERIODO_ANT := PKG_QR_DIG.F_PERIODO_ANTERIOR (VCICLO_ACTUAL);
      exception when others then
      
        dbms_output.put_line('Error en PKG_QR_DIG.F_PERIODO_ANTERIOR ' ||  VPERIODO_ANT );
       end;
      


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
                END  "BIMESTRE/CUATRIMESTRE EN CURSO",
                datos.NOM_PROG "PROGRAMA INSCRITO",
                CASE
                   WHEN PCODE IN ('COTE', 'DIMA',  'CRED','CREX') THEN vno_mostrar
                   ELSE datos.ciclo_cursa
                END  "CICLO EN CURSO",
                CASE
                   WHEN PCODE IN ('COTE', 'DIMA',  'CRED','CREX') THEN vno_mostrar
                   ELSE datos.ciclo_inicio
                END    "CICLO INICIO",
                CASE
                   WHEN PCODE IN ('COTE', 'DIMA',  'CRED','CREX') THEN vno_mostrar
                   ELSE datos.ciclo_fin
                END     "CICLO FIN",
                 CASE
                   WHEN PCODE IN ('CRED','CREX') THEN 999 --vno_mostrar
                   ELSE datos.materías_ac
                END    "MATERIAS ACREDITADAS",
                 CASE
                   WHEN PCODE IN ('CRED','CREX') THEN 999 --vno_mostrar
                   ELSE datos.materías_total
                 END   "MATERIAS TOTAL",
                 CASE
                   WHEN PCODE IN ('CRED','CREX') THEN vno_mostrar
                   ELSE datos.avance || '%'
                 END    "AVANCE",
                 CASE
                   WHEN PCODE IN ('CRED','CREX') THEN vno_mostrar
                   ELSE  datos.promedio
                 END    "PROMEDIO GENERAL",
                VPROM_ANTE "PROMEDIO CUATRIMESTRE ANTERIOR",
                CASE
                   WHEN PCODE IN ('DIMA','CRED','CREX' ) THEN vno_mostrar
                   ELSE DATOS.RVOE
                END     "RVOE",
                CASE
                   WHEN PCODE IN ('DIMA', 'CRED','CREX') THEN vno_mostrar
                   ELSE TO_CHAR (DATOS.FECHA_RVOE)
                END     "FECHA RVOE",
                VREP_AUTORIZA "AUTORIZA",
                VPUESTO  "PUESTO",
                NVL (DATOS.FECHA_EMISION, 'Sin envío') "FECHA DE EMISIÓN",
                VDIMA "DURACIÓN",
                CASE WHEN PCODE IN ('CRED') THEN
                   --   datos.vigencia
                     -- TO_CHAR (ADD_MONTHS(DATOS.FECHA_EMISION, 36), 'DD/MM/YYYY')
                  PKG_QR_DIG.F_VIGENCIA_CRED(SYSDATE)
                ELSE
                       'NO_MOSTRAR'
                END   "VIGENCIA"
           FROM (  SELECT DISTINCT
                          Q.SZT_PIDM pidm,
                          Q.SZT_AVANCE avance,
                          Q.SZT_PROMEDIO promedio,
                          Q.SZT_FOLIO_DOCTO folio_doct,
                          Q.SZT_SEQNO_SIU no_solicitud,
                          (SELECT DISTINCT SVVSRVC_DESC
                             FROM SVVSRVC
                            WHERE SVVSRVC_CODE = Q.SZT_CODE_ACCESORIO)
                             NOM_ACC,
                          Q.SZT_NO_MATERIAS_ACRED materías_ac,
                          Q.SZT_NO_MATERIAS_TOTAL + vtalleres materías_total, --SE LE SUMAN LOS TALLERES AL TOTAL REGLA SUSY 10/03/021
                          Q.SZT_CICLO_CURSA ciclo_cursa,
                          Q.SZT_FECHAS_CICLO_INI ciclo_inicio,
                          Q.SZT_FECHAS_CICLO_FIN ciclo_fin,
                          Q.SZT_FECHA_ENVIO FECHA_EMISION,
                          Q.SZT_PERIODO_ACT BIM_ACTUAL,
                          QR.RVOE RVOE,
                          QR.FECHA_RVOE FECHA_RVOE,
                          QR.NOMBRE_PROGRAMA NOM_PROG
                          ,TO_CHAR (ADD_MONTHS(SYSDATE, 36), 'DD/MM/YYYY') vigencia
                     FROM SZTQRDG Q, DATOS_QR QR
                    WHERE     1 = 1
                          AND Q.SZT_FOLIO_DOCTO = pfolio
                          AND Q.SZT_pidm = vpidm     -- fget_pidm( pmatricula)
                          AND QR.CVE_PROG = vprograma
                          AND Q.SZT_FECHA_ENVIO IS NOT NULL
                 ORDER BY 1) datos;

      --dbms_output.put_line('fin del proceso ');
      RETURN cur_alumnos;
   --  return (resultar);

   EXCEPTION
      WHEN OTHERS
      THEN
         vl_error := 'PKG_QR_DIG.cur_alumnos: ' || SQLERRM;
        -- RETURN cur_alumnos;

         DBMS_OUTPUT.put_line ('eror general proceso ' || vl_error);
   END f_xml_envio;

   FUNCTION f_datos_complemento (pfolio       VARCHAR2,
                                 ppidm        NUMBER,
                                 pcode        VARCHAR2,
                                 PPROGRAMA    VARCHAR2)
      RETURN PKG_QR_DIG.cur_datos_alumn
   IS
      lv_pidm          NUMBER := 0;
      cur_alumnos      SYS_REFCURSOR;
      vl_error         VARCHAR2 (1000);
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
      vfecha_inicio2  varchar2(30);
      vnivel             varchar2(4);
      vcartass           varchar2(15);
       vsalidac1        varchar2(1000);
      vsalidac2        varchar2(1000);
      vsalida_larga    varchar2(1000);
      v_palabra        varchar2(50);
      vfecha_fin       varchar2(30);


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
       vcartass    := 'NO_MOSTRAR';
      vsalidac1   := NULL;  
      vsalidac2   := NULL;
      vfecha_fin  := NULL;
       

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
              
      EXCEPTION  WHEN OTHERS  THEN
      
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
      EXCEPTION  WHEN OTHERS  THEN
            Vcorreponda := 'A quien corresponda:';
      END;

      IF Vcorreponda IS NULL OR Vcorreponda = ' '  THEN
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
      EXCEPTION  WHEN OTHERS THEN
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
      EXCEPTION  WHEN OTHERS THEN
            VINSTITUTO := NULL;
      END;

     ------ nueva pregunta la los accesorios de SS  glovicx 26.11.24
      BEGIN
           SELECT DISTINCT SVRSVAD_ADDL_DATA_DESC 
             INTO Vcartass
             FROM svrsvpr v, SVRSVAD VA
            WHERE     1 = 1
                  AND SVRSVPR_PROTOCOL_SEQ_NO IN (pfolio)
                  AND SVRSVPR_PIDM = ppidm
                  AND V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  AND va.SVRSVAD_ADDL_DATA_SEQ = '24' --VER CUAL NUMERO SE QUEDARON
         ORDER BY 1 DESC;
      EXCEPTION WHEN OTHERS THEN
            Vcartass := 'NA';
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


      EXCEPTION   WHEN OTHERS    THEN
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
         SELECT Z.SZT_CICLO_CURSA, SZT_PERIODO_ACT
           INTO VCICLO_ACTUAL, vperiodo_act
           FROM SZTQRDG Z
          WHERE 1 = 1 AND Z.SZT_PIDM = ppidm AND Z.SZT_SEQNO_SIU = pfolio;
      EXCEPTION
         WHEN OTHERS
         THEN
            VCICLO_ACTUAL := '000';
      END;



      VPERIODO_ANT := BANINST1.PKG_QR_DIG.F_PERIODO_ANTERIOR (VCICLO_ACTUAL);



      IF PCODE = 'DIMA' THEN
         VDIMA := PKG_QR_DIG.F_DIMA (VCAMPUS, pprograma, Vciclo_gtlg);
         vnombre_alumn := INITCAP (vnombre_alumn);
      ELSE
         VDIMA := 'NO_MOSTRAR';
      END IF;

      IF PCODE = 'TIPR'
      THEN
         vnombre_alumn := INITCAP (vnombre_alumn);
      END IF;

      IF PCODE NOT IN ('CLRE','CPRE') THEN  ---esto es para que solo se muestr para los accesorios de SS
      Vcartass := 'NO_MOSTRAR';
      end if;
      

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
       
           --DBMS_OUTPUT.PUT_LINE ('dentro COIN  -- ' || pprograma||'-'|| ppidm);
         BEGIN
            SELECT DISTINCT TO_CHAR(MAX(SORLCUR_START_DATE), 'DD/MM/YYYY')
              INTO vfecha_inicio2
            FROM sorlcur c
            WHERE 1=1
            AND C.SORLCUR_PROGRAM  = pprograma
            and c.SORLCUR_CACT_CODE  = 'ACTIVE'-- se agrego esta opción 20.05.2024
            and  C.SORLCUR_PIDM    =   ppidm ;

            DBMS_OUTPUT.PUT_LINE ('dentro fecha INIcio2 -- ' || vfecha_inicio2);


         EXCEPTION WHEN OTHERS THEN
           vfecha_inicio2  :='No lleva' ;
            DBMS_OUTPUT.PUT_LINE ('errorr en  fecha INIcio2 ingles -- ' || vfecha_inicio2);
         END;


      END IF;

         --DBMS_OUTPUT.PUT_LINE ('antes de  fecha inglasXX00 -- ' || vvalida_eng ||'-'|| vfecha_inicio2  );

      --SI ES YES ENTONCES HAY QUE CAMBIAR ALGUNOS DATOS A INGLES SOLO PARA COES GLOVICX 07.09.022
      IF vvalida_eng = 'Y' THEN
      
         vFECHA_RVOE := REPLACE (vFECHA_RVOE, ' ', '');

         --DBMS_OUTPUT.PUT_LINE ('dentro fecha inglasXX1 -- ' || vFECHA_RVOE);

            begin
         SELECT TO_CHAR (TO_DATE (vFECHA_RVOE, 'dd/mm/yyyy'),
                         'fmMonth dd, yyyy',
                         'NLS_DATE_LANGUAGE = English')
           INTO vFECHA_RVOE
              FROM DUAL;   
                                                            ---OK
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

        ------aqui  obtenemos la fecha cuando se comviertio en egresado osea su fecha fin, para COTE glovicx 26.03.25
      BEGIN
         SELECT TO_CHAR (FECHA_MOV, 'DD-Month-RRRR') , TO_CHAR (fecha_primera, 'DD-Month-RRRR') 
           INTO Vfecha_fin, vfecha_inicio2
           FROM tztprog t1
          WHERE 1 = 1
            AND t1.pidm = pPIDM
            AND t1.programa = Pprograma  ;
      EXCEPTION
         WHEN OTHERS   THEN
           Vfecha_fin := NULL;
           vfecha_inicio2  := null;
          
          DBMS_OUTPUT.PUT_LINE (  'SALIDA ERROR: CALCULAR CICLOS F_DATOS_COMPLEMENTO  ');
      END;
      
     DBMS_OUTPUT.PUT_LINE (  'SALIDA de fechas ini y fin  '||vfecha_inicio2 ||'-'|| Vfecha_fin  );
     
     
      IF  PCODE in ('COTE', 'CAPS')   THEN  
       ---- aqui hay que sacar la fecha de INicio de tztprog  
       
        
        Vfecha_fin := REPLACE (Vfecha_fin, ' ', '');
        vfecha_inicio2 := REPLACE (vfecha_inicio2, ' ', '');
        
        BEGIN
          select substr(vfecha_inicio2, 1, instr(vfecha_inicio2,'-',1)-1)  || ' de '||
          SUBSTR(vfecha_inicio2, 
                 INSTR(vfecha_inicio2, '-') + 1, 
                 INSTR(vfecha_inicio2, '-', -1) - INSTR(vfecha_inicio2, '-') - 1)  || ' del '||
          SUBSTR(vfecha_inicio2, INSTR(vfecha_inicio2, '-', 1, 2) + 1)
          INTO vfecha_inicio2
           from dual;

            
         select substr(Vfecha_fin, 1, instr(Vfecha_fin,'-',1)-1)  || ' de '||
         SUBSTR(Vfecha_fin, 
                 INSTR(Vfecha_fin, '-') + 1, 
                 INSTR(Vfecha_fin, '-', -1) - INSTR(Vfecha_fin, '-') - 1)  || ' del '||
          SUBSTR(Vfecha_fin, INSTR(Vfecha_fin, '-', 1, 2) + 1)
          INTO Vfecha_fin
           from dual;
           
        EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE (  ' ERROR  EN FECHAS CONVERSION   '|| SQLERRM  );
        END;    
            
      END IF;
      

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
                vfecha_inicio2  "fecha_ini",
                vcartass     "carta_ss",
                Vfecha_fin "fecha_fin"
           FROM DUAL;


      --dbms_output.put_line('fin de proceso ' );
      RETURN cur_alumnos;
   --  return (resultar);

   EXCEPTION WHEN OTHERS  THEN
         vl_error := 'PKG_QR_DIG.cur_alumnos: ' || SQLERRM;
         --DBMS_OUTPUT.put_line ('error general' || vl_error);
   END f_datos_complemento;


   FUNCTION F_NOMBRE_ACC (PCODE VARCHAR2)
      RETURN VARCHAR2
   IS
      VDESCRP   VARCHAR2 (100);
   BEGIN
      SELECT DISTINCT SVVSRVC_DESC
        INTO VDESCRP
        FROM SVVSRVC
       WHERE 1 = 1 AND SVVSRVC_CODE = PCODE;


      RETURN VDESCRP;
   EXCEPTION
      WHEN OTHERS
      THEN
         VDESCRP := 'sin descripción';
         RETURN VDESCRP;
   END F_NOMBRE_ACC;


   FUNCTION F_curso_actual (PPIDM        NUMBER, PPROGRAMA    VARCHAR2, PNIVEL  VARCHAR2, PCAMPUS   VARCHAR2) RETURN VARCHAR2
   IS
      VSALIDA         VARCHAR2 (100) := 'EXITO';
      VSEM_ACTUAL     VARCHAR2 (100);
      vperiodo_act    VARCHAR2 (20);
      vperiodo_sep    VARCHAR2 (10);
      Vciclo_gtlg     VARCHAR2 (14);
      vcalificacion   VARCHAR2 (100);
      vstudy          NUMBER := 0;
      no_div          NUMBER := 0;
      vvalida_eng     VARCHAR2 (1) := 'N';
      vnum_mate       NUMBER := 0;
      vnumacc1          NUMBER := 0;
      vnumacc           NUMBER := 0;

   BEGIN
      ------calcula ciclo---
      BEGIN
         SELECT t1.CTLG, sp
           INTO Vciclo_gtlg, vstudy
           FROM tztprog t1
          WHERE 1 = 1 AND t1.pidm = PPIDM AND t1.programa = Pprograma--and   t1.sp = ( select max(t2.sp)  from tztprog t2  where t1.pidm = t2.PIDM   )
         ;
      EXCEPTION
         WHEN OTHERS
         THEN
            VSALIDA := SQLERRM;
            --DBMS_OUTPUT.PUT_LINE ( 'SALIDA ERROR: CALCULAR CICLOS F_CURSO ACTUAL  ' || VSALIDA);
      END;



      ------- CALCULA NO RVOE--
      BEGIN
         SELECT DISTINCT SZTDTEC_PERIODICIDAD_SEP
           INTO vperiodo_sep
           FROM SZTDTEC zt
          WHERE     1 = 1
                AND zt.SZTDTEC_CAMP_CODE = PCAMPUS
                AND zt.SZTDTEC_PROGRAM = PPROGRAMA
                AND zt.SZTDTEC_TERM_CODE = Vciclo_gtlg;
      -- DBMS_OUTPUT.put_line ('DATOS DE   RVOE:  ' ||Vciclo_gtlg ||'--'|| vperiodo_sep );

      EXCEPTION
         WHEN OTHERS
         THEN
            --VSALIDA := SQLERRM;

            IF SUBSTR (PPROGRAMA, 4, 2) IN ('LI', 'DO')
            THEN
               vperiodo_sep := 'cuatrimestre';
            ELSE
               vperiodo_sep := 'bimestre';
            END IF;
      END;


      --DBMS_OUTPUT.put_line ('AL CALCULAR  bimetrs y cuatri:  '||Vciclo_gtlg ||'-'|| vperiodo_sep ||'-'||substr(VSALIDA,1,100)   );

      IF (vperiodo_sep = '1' OR vperiodo_sep IS NULL)
      THEN
         IF SUBSTR (PPROGRAMA, 4, 2) IN ('LI', 'DO')
         THEN
            vperiodo_sep := 'cuatrimestre';
         ELSE
            vperiodo_sep := 'bimestre';
         END IF;
      --DBMS_OUTPUT.put_line ('LA VARIABLE ES NULA :  '||vperiodo_sep );

      ELSE
         BEGIN
            SELECT DISTINCT LOWER (ZSTPARA_PARAM_DESC)
              INTO vperiodo_act
              FROM ZSTPARA p
             WHERE     p.ZSTPARA_MAPA_ID LIKE '%CERT_DIGITAL%'
                   AND p.ZSTPARA_PARAM_VALOR = 'CATALOGO_TIPO_PERIODO'
                   AND p.ZSTPARA_PARAM_ID = vperiodo_sep;
         EXCEPTION
            WHEN OTHERS
            THEN
               vperiodo_act := NULL;

               VSALIDA := SQLERRM;
         --DBMS_OUTPUT.put_line ('EROOR AL CALCULAR PERIODO ACTUAL:  '||Vciclo_gtlg ||'-'|| VSALIDA   );
         END;
      END IF;


      -- DBMS_OUTPUT.put_line ('YA TIENE TODAS LAS VARIABLES VA CALCULAR EL PERIODO:  '||PPIDM||'-'||PPROGRAMA||'-'||PCAMPUS||'-'||PNIVEL||'-'||Vciclo_gtlg
      --                           ||'-'||vperiodo_sep||'-'|| vperiodo_act );
      -- NUEVA FUNCIONALIDAD PARA CAMPUS CON DATOS EN INGLES GLOVICX 07.09.022
      ---- esto es para cuando los documentos van en ingles. segun los campues en especial glovicx 07.09.022
      BEGIN
         SELECT DISTINCT 'Y'
           INTO vvalida_eng
           FROM zstpara
          WHERE     1 = 1
                AND ZSTPARA_PARAM_ID = PCAMPUS
                AND ZSTPARA_MAPA_ID = 'COES_INGLES';
      EXCEPTION
         WHEN OTHERS
         THEN
            vvalida_eng := 'N';
      END;



      IF vvalida_eng = 'Y'
      THEN                                   ---SETRATA DE UN CAMPUES DE INGLE
         NULL;

         IF pnivel = 'LI'
         THEN
            vperiodo_act := 'Term,';
            --vcalificacion  := ( '6.0,7.0,8.0,9.0,10.0'  );
            no_div := 4;

            --dbms_output.put_line(' estoy  en nivel '|| pnivel ||' - '||vcalificacion||' - '||  no_div  );

            BEGIN
               SELECT CASE
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN ('01') THEN 'Firts ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN ('02')  THEN  'Second ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN  ('03')  THEN  'Third ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN  ('04')  THEN  'Fourth ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN ('05') THEN 'Fifth ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / No_div, 0) IN ('06') THEN  'Sixth ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN  ('07')  THEN  'Seventh ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN ('08') THEN 'Eighth ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN  ('09') THEN   'Nineth ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN ('10') THEN  'Tenth ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN  ('11')  THEN  'Eleventh ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN ('12') THEN  'Twelfth ' || vperiodo_act
                         WHEN ROUND (SUM (DATOS.MATERIA) / no_div, 0) IN  ('13') THEN  'Thirteenth ' || vperiodo_act
                      END   periodos
                 INTO VSEM_ACTUAL
                 FROM (SELECT DISTINCT  COUNT (   BB.SSBSECT_SUBJ_CODE || BB.SSBSECT_CRSE_NUMB)  MATERIA
                         FROM sfrstcr f, ssbsect bb
                        WHERE     1 = 1
                              AND F.SFRSTCR_CRN = BB.SSBSECT_CRN
                              AND F.SFRSTCR_TERM_CODE = BB.SSBSECT_TERM_CODE
                              AND f.SFRSTCR_PIDM = ppidm
                              AND F.SFRSTCR_RSTS_CODE = 'RE'
                              AND SUBSTR (F.SFRSTCR_TERM_CODE, 5, 1) NOT IN  (8, 9)
                              AND F.SFRSTCR_GRDE_CODE IN  ('6.0', '7.0', '8.0', '9.0', '10.0')
                              AND F.SFRSTCR_GRDE_CODE NOT IN ('NP', 'NA')
                              AND f.SFRSTCR_STSP_KEY_SEQUENCE = vstudy
                              AND    BB.SSBSECT_SUBJ_CODE|| BB.SSBSECT_CRSE_NUMB NOT LIKE  ('%H%')
                              AND    BB.SSBSECT_SUBJ_CODE || BB.SSBSECT_CRSE_NUMB NOT LIKE  ('%SESO%')
                       UNION
                       SELECT DISTINCT COUNT ( BB.SSBSECT_SUBJ_CODE || BB.SSBSECT_CRSE_NUMB)  MATERIA
                         FROM sfrstcr f, ssbsect bb
                        WHERE     1 = 1
                              AND F.SFRSTCR_CRN = BB.SSBSECT_CRN
                              AND F.SFRSTCR_TERM_CODE = BB.SSBSECT_TERM_CODE
                              AND f.SFRSTCR_PIDM = ppidm
                              AND F.SFRSTCR_RSTS_CODE = 'RE'
                              AND SUBSTR (F.SFRSTCR_TERM_CODE, 5, 1) NOT IN   (8, 9)
                              AND F.SFRSTCR_GRDE_CODE IS NULL
                              AND f.SFRSTCR_STSP_KEY_SEQUENCE = vstudy
                              AND    BB.SSBSECT_SUBJ_CODE || BB.SSBSECT_CRSE_NUMB NOT LIKE  ('%H%')
                              AND    BB.SSBSECT_SUBJ_CODE|| BB.SSBSECT_CRSE_NUMB NOT LIKE   ('%SESO%')) DATOS;
            EXCEPTION
               WHEN OTHERS
               THEN
                  VSEM_ACTUAL := NULL;
                  VSALIDA := SQLERRM;

            END;
         ELSIF pnivel IN ('MA', 'DO')
         THEN
            vperiodo_act := 'Term,';
            -- vcalificacion  :=  '   and F.SFRSTCR_GRDE_CODE  IN '|| '(''7.0'''||',''8.0'''||',''9.0'''||',''10.0'')';
            no_div := 2;



            BEGIN
                 SELECT MAX (datos.NOMBRE_AREa)
                   INTO VSEM_ACTUAL
                   FROM (SELECT CASE
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('01')
                                   THEN
                                      '1ts ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('02')
                                   THEN
                                      '2nd ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('03')
                                   THEN
                                      '3rd ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('04')
                                   THEN
                                      '4th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('05')
                                   THEN
                                      '5th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('06')
                                   THEN
                                      '6th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('07')
                                   THEN
                                      '7th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('08')
                                   THEN
                                      '8th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('09')
                                   THEN
                                      '9th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('10')
                                   THEN
                                      '10th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('11')
                                   THEN
                                      '11th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('12')
                                   THEN
                                      '12th ' || vperiodo_act
                                   WHEN SUBSTR (smrpaap_area, 9, 2) IN ('13')
                                   THEN
                                      '13th ' || vperiodo_act
                                   --When substr(smrpaap_area,9,2) in ('12') then substr(smrpaap_area,9,2)||'avo. '||vperiodo_act
                                   ELSE
                                      vperiodo_act
                                END
                                   nombre_area
                           FROM SMBAGEN ge,
                                smrpaap ma,
                                smrarul ru,
                                ZSTPARA,
                                smralib li
                          WHERE     1 = 1
                                AND ge.SMBAGEN_ACTIVE_IND = 'Y'
                                AND GE.SMBAGEN_AREA = ma.SMRPAAP_AREA --'UTLTSS0310'
                                AND ma.SMRPAAP_TERM_CODE_EFF =
                                       ge.SMBAGEN_TERM_CODE_EFF
                                AND ru.SMRARUL_AREA = ma.SMRPAAP_AREA
                                AND LI.SMRALIB_AREA = ma.SMRPAAP_AREA
                                AND ma.SMRPAAP_PROGRAM = PPROGRAMA --'UTELIAAFED'
                                AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW IN
                                       (SELECT           -- SFRSTCR_TERM_CODE,
                                              BB  .SSBSECT_SUBJ_CODE
                                               || BB.SSBSECT_CRSE_NUMB
                                                  MATERIA
                                          FROM sfrstcr f, ssbsect bb
                                         WHERE     1 = 1
                                               AND F.SFRSTCR_CRN =
                                                      BB.SSBSECT_CRN
                                               AND F.SFRSTCR_TERM_CODE =
                                                      BB.SSBSECT_TERM_CODE
                                               AND f.SFRSTCR_PIDM = PPIDM
                                               AND SUBSTR (F.SFRSTCR_TERM_CODE,
                                                           5,
                                                           1) NOT IN
                                                      (8, 9)
                                               AND f.SFRSTCR_TERM_CODE =
                                                      (SELECT MAX (
                                                                 f2.SFRSTCR_TERM_CODE)
                                                         FROM SFRSTCR F2,
                                                              ssbsect bb2
                                                        WHERE     1 = 1
                                                              AND F.SFRSTCR_PIDM =
                                                                     F2.SFRSTCR_PIDM
                                                              AND F2.SFRSTCR_CRN =
                                                                     BB2.SSBSECT_CRN
                                                              AND SUBSTR (
                                                                     F.SFRSTCR_TERM_CODE,
                                                                     5,
                                                                     1) NOT IN
                                                                     (8, 9)
                                                              AND F2.SFRSTCR_TERM_CODE =
                                                                     BB2.SSBSECT_TERM_CODE
                                                              AND    BB2.SSBSECT_SUBJ_CODE
                                                                  || BB2.SSBSECT_CRSE_NUMB NOT LIKE
                                                                     ('%H%')
                                                              AND    BB2.SSBSECT_SUBJ_CODE
                                                                  || BB2.SSBSECT_CRSE_NUMB NOT LIKE
                                                                     ('%SESO%'))
                                               AND    BB.SSBSECT_SUBJ_CODE
                                                   || BB.SSBSECT_CRSE_NUMB NOT LIKE
                                                      ('%H%')
                                               AND    BB.SSBSECT_SUBJ_CODE
                                                   || BB.SSBSECT_CRSE_NUMB NOT LIKE
                                                      ('%SESO%'))
                                AND ZSTPARA_MAPA_ID = 'ORDEN_CUATRIMES'
                                AND SMRALIB_LEVL_CODE = Pnivel          --'LI'
                                                              --and  SUBSTR(ZSTPARA_PARAM_ID,1,3) = PCAMPUS --'UTL'
                        ) datos
               ORDER BY datos.NOMBRE_AREA DESC;
            EXCEPTION
               WHEN OTHERS
               THEN
                  VSEM_ACTUAL := NULL;

            END;
         END IF;
      ELSE
         ----  AQUI EMPIEZA EL PROCESO NORMAL ES ESPAÑOL


         IF pnivel = 'LI'
         THEN
            --vcalificacion  := ( '6.0,7.0,8.0,9.0,10.0'  );
            no_div := 4;

            --dbms_output.put_line(' estoy  en nivel '|| pnivel ||' - '||vcalificacion||' - '||  no_div  );

            ------inici NUEVO FLUJO  PRIMERO SACAMOS NUM ME MATERIAS
            --  materias aprobadas + materias en curso
            -------- se cambia esta parte para sacar el dato
            BEGIN
              /* SELECT (h.SZTHITA_APROB + h.SZTHITA_E_CURSO) num_mate
                 INTO vnum_mate
                 FROM szthita h
                WHERE     1 = 1
                      AND H.SZTHITA_LEVL = pnivel
                      AND H.SZTHITA_PIDM = ppidm;*/

              select count(1)
                 INTO vnumacc1
                   from sfrstcr f
                    where 1=1
                    and SFRSTCR_PIDM = ppidm
                    and F.SFRSTCR_RSTS_CODE  = 'RE'
                    and F.SFRSTCR_GRDE_CODE  is null
                    and substr(F.SFRSTCR_TERM_CODE,5,1)  not in ( '8','9');


            EXCEPTION
               WHEN OTHERS
               THEN
                  vnumacc1 := 0;
            END;

             begin
                   SELECT BANINST1.PKG_DATOS_ACADEMICOS.acreditadas1 (ppidm, PPROGRAMA)
                      into vnumacc
                            FROM DUAL;
                EXCEPTION
               WHEN OTHERS
               THEN
                  vnumacc := 0;
            END;
            -- HACEMOS la suma de las materias  glovicx 26.01.2023

            vnum_mate := vnumacc + vnumacc1;


            ----- buscamos en los rangos de los parametrizadores

            BEGIN
               SELECT DISTINCT datos.cuatri
                 INTO VSEM_ACTUAL
                 FROM (  SELECT ZSTPARA_PARAM_VALOR cuatri,
                                TO_NUMBER ( SUBSTR ( ZSTPARA_PARAM_ID,  1,   INSTR (ZSTPARA_PARAM_ID, '-', 1) - 1))  MIN,
                                TO_NUMBER ( SUBSTR ( ZSTPARA_PARAM_ID, INSTR (ZSTPARA_PARAM_ID, '-', 1) + 1))   MAX
                           --INTO vaccesorio
                           FROM zstpara
                          WHERE 1 = 1 AND ZSTPARA_MAPA_ID = 'CALCULO_CUATRI'
                       ORDER BY MIN) datos
                WHERE 1 = 1 AND vnum_mate >= MIN AND vnum_mate <= MAX;
            EXCEPTION
               WHEN OTHERS
               THEN
                  VSEM_ACTUAL := 'Fuera rango';
            END;
         ELSIF pnivel IN ('MA', 'DO')
         THEN
            -- vcalificacion  :=  '   and F.SFRSTCR_GRDE_CODE  IN '|| '(''7.0'''||',''8.0'''||',''9.0'''||',''10.0'')';
            no_div := 2;



            BEGIN
                 SELECT MAX (datos.NOMBRE_AREa)
                   INTO VSEM_ACTUAL
                   FROM (SELECT DISTINCT
                                CASE
                                   WHEN smrpaap_area NOT IN
                                           (SELECT ZSTPARA_PARAM_VALOR
                                              FROM ZSTPARA
                                             WHERE ZSTPARA_MAPA_ID =   'ORDEN_CUATRIMES')
                                   THEN
                                      CASE
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('01', '03')  THEN  SUBSTR (smrpaap_area, 10, 1)  || 'er. '   || vperiodo_act
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('02') THEN  SUBSTR (smrpaap_area, 10, 1) || 'do. ' || vperiodo_act
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('04', '05', '06') THEN  SUBSTR (smrpaap_area, 10, 1)  || 'to. '  || vperiodo_act
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('07')  THEN   SUBSTR (smrpaap_area, 10, 1)  || 'mo. '   || vperiodo_act
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('08') THEN  SUBSTR (smrpaap_area, 10, 1)  || 'vo. '  || vperiodo_act
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('09') THEN  SUBSTR (smrpaap_area, 10, 1)  || 'no. '  || vperiodo_act
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('10') THEN  SUBSTR (smrpaap_area, 9, 2) || 'mo. '  || vperiodo_act
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('11') THEN  SUBSTR (smrpaap_area, 9, 2) || 'avo. '  || vperiodo_act
                                         WHEN SUBSTR (smrpaap_area, 9, 2) IN  ('12') THEN  SUBSTR (smrpaap_area, 9, 2)  || 'avo. '  || vperiodo_act
                                         ELSE
                                            vperiodo_act
                                      END
                                   ELSE
                                      vperiodo_act
                                END  nombre_area
                           FROM SMBAGEN ge,
                                smrpaap ma,
                                smrarul ru,
                                ZSTPARA,
                                smralib li
                          WHERE     1 = 1
                                AND ge.SMBAGEN_ACTIVE_IND = 'Y'
                                AND GE.SMBAGEN_AREA = ma.SMRPAAP_AREA --'UTLTSS0310'
                                AND ma.SMRPAAP_TERM_CODE_EFF =
                                       ge.SMBAGEN_TERM_CODE_EFF
                                AND ru.SMRARUL_AREA = ma.SMRPAAP_AREA
                                AND LI.SMRALIB_AREA = ma.SMRPAAP_AREA
                                AND ma.SMRPAAP_PROGRAM = PPROGRAMA --'UTELIAAFED'
                                AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW IN
                                       (SELECT           -- SFRSTCR_TERM_CODE,
                                              BB  .SSBSECT_SUBJ_CODE|| BB.SSBSECT_CRSE_NUMB  MATERIA
                                          FROM sfrstcr f, ssbsect bb
                                         WHERE     1 = 1
                                               AND F.SFRSTCR_CRN =   BB.SSBSECT_CRN
                                               AND F.SFRSTCR_TERM_CODE =  BB.SSBSECT_TERM_CODE
                                               AND f.SFRSTCR_PIDM = PPIDM
                                               AND SUBSTR (F.SFRSTCR_TERM_CODE,  5,  1) NOT IN   (8, 9)
                                               AND f.SFRSTCR_TERM_CODE =
                                                      (SELECT MAX (  f2.SFRSTCR_TERM_CODE)
                                                         FROM SFRSTCR F2,
                                                              ssbsect bb2
                                                        WHERE     1 = 1
                                                              AND F.SFRSTCR_PIDM =  F2.SFRSTCR_PIDM
                                                              AND F2.SFRSTCR_CRN = BB2.SSBSECT_CRN
                                                              AND SUBSTR (   F.SFRSTCR_TERM_CODE,  5,  1) NOT IN  (8, 9)
                                                              AND F2.SFRSTCR_TERM_CODE = BB2.SSBSECT_TERM_CODE
                                                              AND    BB2.SSBSECT_SUBJ_CODE || BB2.SSBSECT_CRSE_NUMB NOT LIKE  ('%H%')
                                                              AND    BB2.SSBSECT_SUBJ_CODE|| BB2.SSBSECT_CRSE_NUMB NOT LIKE   ('%SESO%'))
                                            --   AND    BB.SSBSECT_SUBJ_CODE || BB.SSBSECT_CRSE_NUMB NOT LIKE ('%H%')
                                               AND    BB.SSBSECT_SUBJ_CODE || BB.SSBSECT_CRSE_NUMB NOT LIKE   ('%SESO%'))
                                AND ZSTPARA_MAPA_ID = 'ORDEN_CUATRIMES'
                                AND SMRALIB_LEVL_CODE = Pnivel          --'LI'
                                AND SUBSTR (ZSTPARA_PARAM_ID, 1, 3) = PCAMPUS --'UTL'
                                                                             ) datos
               ORDER BY datos.NOMBRE_AREA DESC;
            EXCEPTION
               WHEN OTHERS
               THEN
                  VSEM_ACTUAL := NULL;

            END;
         END IF;
      END IF;                                          -- DE TRADUCCION INGLES

      --DBMS_OUTPUT.PUT_LINE('al final de FCURSO ACTUAL:  '|| PPROGRAMA||'-'||ppidm||'-'||pnivel||'-'||pCAMPUS||'-'|| VSALIDA );

      IF VSALIDA = 'EXITO'
      THEN
         RETURN VSEM_ACTUAL;
      ELSE
         RETURN VSALIDA;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN

         RETURN VSALIDA;
   END F_curso_actual;



   FUNCTION F_PERIODO_ANTERIOR (PPERIODO VARCHAR2)
      RETURN VARCHAR2
   IS
      --FUNCION QUE SE ENCARGA DE RECUPERAR EL PERIODO INMEDIATO ANTERIOR DE LOS ALUMNOS, ESTO ES PARA PODER CALCULAR EL PROMEDIO
      -- DEL CUATRIMESTRE ANTERIOR, PARA LAS CONSTANCIAS QR  glovicx 24/03/21
      --
      --ppidm       number:= 342242;
      --pprograma   varchar2(12):= 'UTLLINIFED';
      pciclo_actual   VARCHAR2 (10);
      vperi_atras     VARCHAR2 (12) := '000000';
      vanio           NUMBER;
   BEGIN
      pciclo_actual := PPERIODO;

      -----primero le quitamos o le restamos un perio al actual
      -- solo hay 41,42,43
      IF SUBSTR (pciclo_actual, 5, 2) = '43'
      THEN                                                     -- ES EL ULTIMO
         vperi_atras := SUBSTR (pciclo_actual, 1, 4) || '42'; --SI SIGUIENTE ANTERIOR DEL 43 ES EL 42

        -- DBMS_OUTPUT.put_line ('entrada43 salida>> ' || vperi_atras);
      ELSIF SUBSTR (pciclo_actual, 5, 2) = '42'
      THEN                                                 -- ES EL INTERMEDIO
         vperi_atras := SUBSTR (pciclo_actual, 1, 4) || '41'; --SI SIGUIENTE ANTERIOR DEL 42 ES EL 41

         --DBMS_OUTPUT.put_line ('entrada 42 salida>> ' || vperi_atras);
      ELSIF SUBSTR (pciclo_actual, 5, 2) = '41'
      THEN                                                    -- ES EL PRIMERO
         --sacamos el año del periodo que son 3 y 4 caracters
         vanio := SUBSTR (pciclo_actual, 3, 2) - 1;

         vperi_atras := SUBSTR (pciclo_actual, 1, 2) || vanio || '43'; --SI SIGUIENTE ANTERIOR DEL 41 ES EL 43; POR QUE INICIA CAMBIO AÑO

        -- DBMS_OUTPUT.put_line ('entrada41, salida>> ' || vperi_atras);
      END IF;

      RETURN vperi_atras;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   --DBMS_OUTPUT.PUT_LINE('ERROR EN F_PERIODO_ANTERIOR:  '|| vperi_atras||'<->'||PPERIODO );

   --insert into twpasow( VALOR1,VALOR2,VALOR3, valor4, valor5 )
   --values( 'error_ QR_PERIODO_ANTERIOR',PPERIODO,vperi_atras ,vanio,pciclo_actual );
   --COMMIT;

   END F_PERIODO_ANTERIOR;


   FUNCTION F_DIMA (PCAMPUS VARCHAR2, PPROGRAMA VARCHAR2, PCTGL VARCHAR2)
      RETURN VARCHAR2
   IS
      vperiodo_sep   VARCHAR2 (45);
      vperiodo_act   VARCHAR2 (15);
      VSALIDA        VARCHAR2 (250);
      vdima          VARCHAR2 (30);
   BEGIN
      BEGIN
         SELECT DISTINCT SZTDTEC_NUM || ' ' || SZTDTEC_TIP_NUM AS cuatros
           INTO vperiodo_sep
           FROM SZTDTEC zt
          WHERE     1 = 1
                AND zt.SZTDTEC_CAMP_CODE = PCAMPUS
                AND zt.SZTDTEC_PROGRAM = PPROGRAMA
                AND zt.SZTDTEC_TERM_CODE = PCTGL;
      EXCEPTION
         WHEN OTHERS
         THEN
            vperiodo_sep := NULL;
            VSALIDA := SQLERRM;

      END;

     /* DBMS_OUTPUT.PUT_LINE (
            'salida  EN F_DIMA_PERIODO:  '
         || vperiodo_sep
         || '<->'
         || vperiodo_sep);*/
    


      RETURN (vperiodo_sep);
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   --DBMS_OUTPUT.PUT_LINE('ERROR EN F_DIMA_GRAL:  '|| vperiodo_sep ||'<->'||PPROGRAMA );

   --insert into twpasow( VALOR1,VALOR2,VALOR3, valor4, valor5 )
   --values( 'error_ QR_DIMA_PERIODO',PPROGRAMA,vperiodo_sep ,vperiodo_act,PCTGL );
   END F_DIMA;

   FUNCTION F_TI_INTERMEDIO (PPIDM NUMBER, PPROGRAMA VARCHAR2)
      RETURN VARCHAR2
   IS
      vcve_rvoe     VARCHAR2 (20);
      v23mate       VARCHAR2 (100);
      v24mate       VARCHAR2 (200);
      vaprobadas    NUMBER := 0;
      vsalida       VARCHAR2 (100);
      Vciclo_gtlg   VARCHAR2 (8);
   BEGIN
      ---calcula las fechas de matriculacion y la fechas de ctgl

      BEGIN
         SELECT DISTINCT t1.CTLG                                 --, T1.CAMPUS
           INTO Vciclo_gtlg                                        --, VCAMPUS
           FROM tztprog t1
          WHERE 1 = 1 AND t1.pidm = PPIDM AND t1.programa = PPROGRAMA--and   t1.sp = ( select max(t2.sp)  from tztprog t2
                                                                     --                where t1.pidm = t2.PIDM   )
         ;
      EXCEPTION
         WHEN OTHERS
         THEN
            Vciclo_gtlg := '';

            --VERROR := SQLERRM;
            --DBMS_OUTPUT.PUT_LINE (  'SALIDA ERROR: CALCULAR CICLOS TI_INTEMEDIO  ');
      --vl_error    := sqlerrm;
      -- dbms_output.put_line('salida 2:  '||vl_error  );
      END;



      --BUSCAMOS PRIMERO EL NUMERO DE RVOE DEL PROGRAMA
      BEGIN
         SELECT DISTINCT z.SZTDTEC_NUM_RVOE
           INTO vcve_rvoe
           FROM SZTDTEC z
          WHERE     1 = 1
                AND z.SZTDTEC_PROGRAM = PPROGRAMA
                AND Z.SZTDTEC_TERM_CODE = Vciclo_gtlg;
      EXCEPTION
         WHEN OTHERS
         THEN
            vcve_rvoe := NULL;
      END;


      BEGIN
        /* SELECT SZTHITA_APROB
           INTO vaprobadas
           FROM SZTHITA ZT
          WHERE     1 = 1
                AND SZTHITA_PIDM = PPIDM
                AND ZT.SZTHITA_PROG = PPROGRAMA;*/

               vaprobadas :=  PKG_DATOS_ACADEMICOS.acreditadas1 (PPIDM, PPROGRAMA);



      EXCEPTION
         WHEN OTHERS
         THEN
            vaprobadas := 0;
      END;


      IF vaprobadas < 12 AND SUBSTR (PPROGRAMA, 4, 2) = 'LI'
      THEN
         --aqui esta la regla para cuando sea menor  a 12
         BEGIN
            SELECT DISTINCT ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_valor
              INTO v23mate, v24mate
              FROM zstpara
             WHERE     1 = 1
                   AND zstpara_mapa_id = 'TIT_INTERMEDIO'
                   AND ZSTPARA_PARAM_ID = 'MENOR A 12';
         EXCEPTION
            WHEN OTHERS
            THEN
               v23mate := NULL;
               v24mate := NULL;
         END;
      ELSIF vaprobadas >= 12 AND SUBSTR (PPROGRAMA, 4, 2) = 'LI'
      THEN
         --aqui esta la regla para cuando sea mayor igual a 12

         BEGIN
            SELECT DISTINCT ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_valor
              INTO v23mate, v24mate
              FROM zstpara
             WHERE     1 = 1
                   AND zstpara_mapa_id = 'TIT_INTERMEDIO'
                   AND ZSTPARA_PARAM_ID = vcve_rvoe;
         EXCEPTION
            WHEN OTHERS
            THEN
               v23mate := NULL;
               v24mate := NULL;
         END;



         IF vaprobadas < 12
         THEN
            vsalida := vaprobadas || '|' || v24mate;
         ELSIF vaprobadas BETWEEN 12 AND 23
         THEN
            vsalida := '12|' || v23mate;
         ELSIF vaprobadas >= 24
         THEN
            vsalida := '24|' || v24mate;
         END IF;
      END IF;

      ----- aqui va la configuración para maestrias
      IF SUBSTR (PPROGRAMA, 4, 2) = 'MA'
      THEN
         BEGIN
            SELECT DISTINCT ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_valor
              INTO v23mate, v24mate
              FROM zstpara
             WHERE     1 = 1
                   AND zstpara_mapa_id = 'TIT_INTERMEDIO'
                   AND ZSTPARA_PARAM_ID = vcve_rvoe;
         EXCEPTION
            WHEN OTHERS
            THEN
               v23mate := NULL;
               v24mate := NULL;
         END;

         IF vaprobadas BETWEEN 6 AND 11
         THEN
            vsalida := 'Diplomado en ' || '|' || v23mate;
         ELSIF vaprobadas >= 12
         THEN
            vsalida := 'Diplomado en estudios avanzados en |' || v24mate;
         END IF;
      END IF;

      RETURN (vsalida);
   EXCEPTION
      WHEN OTHERS
      THEN
         vsalida := SQLERRM;


   END F_TI_INTERMEDIO;



   FUNCTION F_BTN_REINICIA (PPIDM NUMBER, PSEQNO NUMBER)
      RETURN VARCHAR2
   IS
      vqr       VARCHAR2 (1) := 'N';
      vsalida   VARCHAR2 (1000) := 'EXITO';
   BEGIN
      BEGIN
         SELECT 'Y'
           INTO vqr
           FROM SZTQRDG q
          WHERE     1 = 1
                AND q.SZT_PIDM = PPIDM
                AND q.SZT_SEQNO_SIU = PSEQNO
                AND NOT EXISTS
                           (SELECT 1
                              FROM SZTREPRO r
                             WHERE     1 = 1
                                   AND q.SZT_PIDM = r.SZT_PIDM
                                   AND q.SZT_SEQNO_SIU = R.SZT_SEQNO_SIU);
      EXCEPTION
         WHEN OTHERS
         THEN
            vqr := 'N';
      END;

      IF vqr = 'Y'
      THEN
         ---primero se borra el reg actial que existe
         BEGIN
            DELETE FROM SZTQRDG
                  WHERE 1 = 1 AND SZT_PIDM = PPIDM AND SZT_SEQNO_SIU = PSEQNO;
         EXCEPTION
            WHEN OTHERS
            THEN
               vsalida := SQLERRM;

         END;

         -- se vuelve a cargar mediante el proceso natural--

         BEGIN
            BANINST1.PKG_QR_DIG.p_universo (PPIDM);
         END;

         --ultimo paso se inserta el reg en la nueva tbla SZTREPRO


         BEGIN
            INSERT INTO SZTREPRO (SZT_PIDM, SZT_SEQNO_SIU, SZT_REPROCESA)
                 VALUES (PPIDM, PSEQNO, 1);
         EXCEPTION
            WHEN OTHERS
            THEN
               vsalida := SQLERRM;
         END;


         COMMIT;
      END IF;



      RETURN vsalida;
   END F_BTN_REINICIA;


 FUNCTION F_HIAC_ESP_INGL (Ppidm IN NUMBER, Pprog VARCHAR2)
      RETURN PKG_QR_DIG.hiac_out
   AS
      histac_out   PKG_QR_DIG.hiac_out;
      vnivel        VARCHAR2 (2);
      vsalida      VARCHAR2 (200);
   BEGIN
      BEGIN
         SELECT smrprle_levl_code
           INTO vnivel
           FROM smrprle
          WHERE smrprle_program = Pprog;
      EXCEPTION
         WHEN OTHERS
         THEN
            vnivel := NULL;
      END;


      IF vnivel = 'LI' then ---- aqui es licenciatura recupera datos de alumnos LI*****
      
         OPEN histac_out FOR
            SELECT DISTINCT
                      spriden_first_name
                   || ' '
                   || REPLACE (spriden_last_name, '/', ' ')
                      "Estudiante",
                   spriden_id "Matricula",
                   sztdtec_programa_comp "Programa",
                   TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) "per",
                   CASE
                      WHEN shrtckn_subj_code IS NULL OR SUBSTR (stvterm_code, 1, 2) = '08'
                      THEN ' '
                      ELSE
                         CASE
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('01')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1)|| 'st. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('02')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1) || 'nd. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('03')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1) || 'rd. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN
                                    ('04', '05','06', '07','08','09','10','11','12')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1) || 'th.  '|| 'Term'
                            ELSE
                               smralib_area_desc
                         END
                   END  as  "nombre_area",
                   smrarul_subj_code || smrarul_crse_numb_low "materia",
                   (SELECT ZSTPARA_PARAM_DESC
                      FROM ZSTPARA
                     WHERE     1 = 1
                           AND ZSTPARA_MAPA_ID = 'MAT_TRADUC'
                           AND ZSTPARA_PARAM_ID =
                                  smrarul_subj_code || smrarul_crse_numb_low) "NOMBRE_MAT",
                   --scrsyln_long_course_title "nombre_mat",
                   CASE
                      WHEN SUBSTR (stvterm_code, 1, 2) = '08'
                      THEN
                         SUBSTR (stvterm_desc, 7, 4)
                      ELSE
                         SUBSTR (stvterm_desc, 1, 6)
                   END as "periodo",
                   shrtckg_grde_code_final "calif",
                   shrgrde_abbrev "letra",
                   0 "Avance",
                   0 "Promedio",
                   shrgrde_passed_ind "aprobatoria",
                   scbcrse_credit_hr_low "creditos",
                   CASE
                      WHEN SUBSTR (shrtckn_term_code, 5, 1) = '8' THEN 'EXT'
                      ELSE 'ORD'
                   END
                      "evaluacion",
                 (select   REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '') ||' - '||
                         REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '')
                        from sfrstcr f, ssbsect bb
                        where 1=1
                        and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                        and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                         and f.SFRSTCR_GRDE_CODE is not null
                        and SFRSTCR_PIDM = ppidm
                        and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                        and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16
              FROM spriden
                   JOIN sgbstdn a
                      ON     sgbstdn_pidm = spriden_pidm
                         AND sgbstdn_term_code_eff IN
                                (SELECT MAX (sgbstdn_term_code_eff)
                                   FROM sgbstdn b
                                  WHERE     a.sgbstdn_pidm = b.sgbstdn_pidm
                                        AND b.SGBSTDN_PROGRAM_1 = Pprog)
                   JOIN sorlcur s
                      ON     sorlcur_pidm = spriden_pidm
                         AND sorlcur_program = Pprog
                         AND sorlcur_lmod_code = 'LEARNER'
                         AND SORLCUR_CACT_CODE != 'CHANGE'
                         AND sorlcur_seqno IN
                                (SELECT MAX (sorlcur_seqno)
                                   FROM sorlcur ss
                                  WHERE     s.sorlcur_pidm = ss.sorlcur_pidm
                                        AND s.sorlcur_program = ss.sorlcur_program
                                        AND s.sorlcur_lmod_code =  ss.sorlcur_lmod_code)
                   JOIN smrprle
                      ON sorlcur_program = smrprle_program
                   JOIN sztdtec
                      ON     sorlcur_program = sztdtec_program
                         AND SORLCUR_CAMP_CODE = sztdtec_camp_code
                         AND sztdtec_status = 'ACTIVO'
                         AND SZTDTEC_TERM_CODE = SORLCUR_TERM_CODE_CTLG
                   JOIN smrpaap s
                      ON     smrpaap_program = sorlcur_program
                         AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
                   JOIN smrarul
                      ON     smrpaap_area = smrarul_area
                         AND smrarul_area NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE ZSTPARA_MAPA_ID = 'ORDEN_CUATRIMES')
                         AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE     ZSTPARA_MAPA_ID = 'NOVER_MAT_DASHB'
                                        AND spriden_pidm IN
                                               (SELECT spriden_pidm
                                                  FROM spriden
                                                 WHERE spriden_id = ZSTPARA_PARAM_ID))
                         AND (  ( smrarul_area NOT IN
                                         (SELECT smriecc_area FROM smriecc)
                         AND smrarul_area NOT IN
                                         (SELECT smriemj_area FROM smriemj))
                              OR ( smrarul_area IN
                                         (SELECT smriemj_area
                                            FROM smriemj
                                           WHERE smriemj_majr_code =
                                                    (SELECT DISTINCT
                                                            SORLFOS_MAJR_CODE
                                                       FROM sorlcur cu,
                                                            sorlfos ss
                                                      WHERE     cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                            AND cu.SORLCUR_SEQNO = ss.SORLFOS_LCUR_SEQNO
                                                            AND cu.sorlcur_pidm = Ppidm
                                                            AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                            AND SORLFOS_LFST_CODE = 'MAJOR'
                                                            AND SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                            AND sorlcur_program =   pprog))
                                  AND smrarul_area NOT IN
                                         (SELECT smriecc_area FROM smriecc))
                              OR (smrarul_area IN
                                     (SELECT smriecc_area
                                        FROM smriecc
                                       WHERE smriecc_majr_code_conc IN
                                                (SELECT DISTINCT
                                                        SORLFOS_MAJR_CODE
                                                   FROM sorlcur cu,
                                                        sorlfos ss
                                                  WHERE     cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                        AND cu.SORLCUR_SEQNO = ss.SORLFOS_LCUR_SEQNO
                                                        AND cu.sorlcur_pidm = Ppidm
                                                        AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                        AND SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                        AND SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                        AND sorlcur_program =  pprog))))
                   JOIN smbpgen
                      ON     sorlcur_program = smbpgen_program
                         AND smbpgen_term_code_eff = smrpaap_term_code_eff
                   JOIN smbagen
                      ON     smbagen_area = smrpaap_area
                         AND smbagen_active_ind = 'Y'
                         AND smbagen_term_code_eff = smrpaap_term_code_eff
                   JOIN smralib
                      ON     smrpaap_area = smralib_area
                         AND SMRALIB_LEVL_CODE = SORLCUR_LEVL_CODE
                   JOIN smracaa
                      ON     smracaa_area = smrarul_area
                         AND smracaa_rule = smrarul_key_rule
                   JOIN shrtckn w
                      ON     shrtckn_pidm = spriden_pidm
                         AND shrtckn_subj_code = smrarul_subj_code
                         AND shrtckn_crse_numb = smrarul_crse_numb_low
                         AND shrtckn_stsp_key_sequence = sorlcur_key_seqno
                   JOIN shrtckg z
                      ON     shrtckg_pidm = shrtckn_pidm
                         AND shrtckg_term_code = shrtckn_term_code
                         AND shrtckg_tckn_seq_no = shrtckn_seq_no
                         AND shrtckg_term_code = shrtckn_term_code
                         AND DECODE (shrtckg_grde_code_final,'NA', 4,'NP', 4,'AC', 6, TO_NUMBER (shrtckg_grde_code_final)) IN
                                (SELECT MAX ( DECODE ( shrtckg_grde_code_final,'NA', 4,'NP', 4, 'AC', 6, TO_NUMBER ( shrtckg_grde_code_final)))
                                   FROM shrtckn ww, shrtckg zz
                                  WHERE     w.shrtckn_pidm = ww.shrtckn_pidm
                                        AND w.shrtckn_subj_code = ww.shrtckn_subj_code
                                        AND w.shrtckn_crse_numb = ww.shrtckn_crse_numb
                                        AND ww.shrtckn_pidm = zz.shrtckg_pidm
                                        AND ww.shrtckn_seq_no = zz.shrtckg_tckn_seq_no
                                        AND ww.shrtckn_term_code = zz.shrtckg_term_code)
                   JOIN scrsyln
                      ON     scrsyln_subj_code = shrtckn_subj_code
                       AND scrsyln_crse_numb = shrtckn_crse_numb
                   JOIN shrgrde
                      ON     shrgrde_code = shrtckg_grde_code_final
                         AND shrgrde_levl_code = sgbstdn_levl_code
                         /* cambio escalas para prod */
                         AND shrgrde_term_code_effective =
                                (SELECT zstpara_param_desc
                                   FROM zstpara
                                  WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                        AND SUBSTR ( (SELECT f_getspridenid (ppidm)
                                                  FROM DUAL),1,2) = zstpara_param_id
                                        AND zstpara_param_valor = sgbstdn_levl_code)
                   JOIN stvterm
                      ON stvterm_code = shrtckn_term_code
                   JOIN scbcrse
                      ON     scbcrse_subj_code = shrtckn_subj_code
                         AND scbcrse_crse_numb = shrtckn_crse_numb
                   LEFT OUTER JOIN zstpara
                      ON     zstpara_mapa_id = 'MAESTRIAS_BIM'
                         AND zstpara_param_id = sorlcur_program
                         AND zstpara_param_desc = SORLCUR_TERM_CODE_CTLG
             WHERE 1=1
              and spriden_pidm = Ppidm 
              AND spriden_change_ind IS NULL
       UNION
            SELECT DISTINCT
                      spriden_first_name|| ' ' || REPLACE (spriden_last_name, '/', ' ') "Estudiante",
                   spriden_id "Matricula",
                   sztdtec_programa_comp "Programa",
                   TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) "per",
                   CASE
                      WHEN    shrtrce_subj_code IS NULL
                           OR SUBSTR (spriden_id, 1, 2) = '08'
                      THEN
                         ' '
                      ELSE
                         CASE
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('01')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1)|| 'st. '|| 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('02')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1)|| 'nd. '|| 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('03')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1)|| 'rd. '|| 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN
                                    ('04','05','06','07','08','09', '10','11','12')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1)|| 'th.  ' || 'Term'
                            ELSE
                               smralib_area_desc
                         END
                   END as "nombre_area",
                   smrarul_subj_code || smrarul_crse_numb_low "materia",
                   (SELECT ZSTPARA_PARAM_DESC
                      FROM ZSTPARA
                     WHERE     1 = 1
                           AND ZSTPARA_MAPA_ID = 'MAT_TRADUC'
                           AND ZSTPARA_PARAM_ID =
                                  smrarul_subj_code || smrarul_crse_numb_low) as "NOMBRE_MAT",
                   --scrsyln_long_course_title "nombre_mat",
                   ' ' "periodo",
                   shrtrce_grde_code "calif",
                   shrgrde_abbrev "letra",
                   0 "Avance",
                   0 "Promedio",
                   shrgrde_passed_ind "aprobatoria",
                   scbcrse_credit_hr_low "creditos",
                   'EQ' "evaluacion",
                    (select   REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '') ||' - '||
                         REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '')
                        from sfrstcr f, ssbsect bb
                        where 1=1
                        and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                        and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                         and f.SFRSTCR_GRDE_CODE is not null
                        and SFRSTCR_PIDM = ppidm
                        and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                        and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16
              FROM spriden
                   JOIN sgbstdn a
                      ON     sgbstdn_pidm = spriden_pidm
                         AND sgbstdn_term_code_eff IN
                                (SELECT MAX (sgbstdn_term_code_eff)
                                   FROM sgbstdn b
                                  WHERE     a.sgbstdn_pidm = b.sgbstdn_pidm
                                        AND b.SGBSTDN_PROGRAM_1 = pprog)
                   JOIN sorlcur
                      ON     sorlcur_pidm = spriden_pidm
                         AND sorlcur_program = Pprog
                         AND sorlcur_lmod_code = 'LEARNER'
                         AND SORLCUR_CACT_CODE != 'CHANGE'
                   JOIN smrprle
                      ON sorlcur_program = smrprle_program
                   JOIN sztdtec
                      ON     sorlcur_program = sztdtec_program
                         AND SORLCUR_CAMP_CODE = sztdtec_camp_code
                         AND sztdtec_status = 'ACTIVO'
                         AND SZTDTEC_TERM_CODE = SORLCUR_TERM_CODE_CTLG
                   JOIN smrpaap s
                      ON     smrpaap_program = sorlcur_program
                         AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
                   JOIN smrarul
                      ON     smrpaap_area = smrarul_area
                         AND smrarul_area NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE     ZSTPARA_MAPA_ID = 'ORDEN_CUATRIMES'
                                     AND SUBSTR (ZSTPARA_PARAM_VALOR, 5, 2) <> 'TT')
                         AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE     ZSTPARA_MAPA_ID = 'NOVER_MAT_DASHB'
                                        AND spriden_pidm IN
                                               (SELECT spriden_pidm
                                                  FROM spriden
                                                 WHERE spriden_id = ZSTPARA_PARAM_ID))
                         AND (   (    smrarul_area NOT IN
                                         (SELECT smriecc_area FROM smriecc)
                                  AND smrarul_area NOT IN
                                         (SELECT smriemj_area FROM smriemj))
                              OR (    smrarul_area IN
                                         (SELECT smriemj_area
                                            FROM smriemj
                                           WHERE smriemj_majr_code =
                                                    (SELECT DISTINCT
                                                            SORLFOS_MAJR_CODE
                                                       FROM sorlcur cu,
                                                            sorlfos ss
                                                      WHERE     cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                            AND cu.SORLCUR_SEQNO = ss.SORLFOS_LCUR_SEQNO
                                                            AND cu.sorlcur_pidm = Ppidm
                                                            AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                            AND SORLFOS_LFST_CODE = 'MAJOR'
                                                            AND SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                            AND sorlcur_program =  Pprog))
                                  AND smrarul_area NOT IN
                                         (SELECT smriecc_area FROM smriecc))
                              OR (smrarul_area IN
                                     (SELECT smriecc_area
                                        FROM smriecc
                                       WHERE smriecc_majr_code_conc IN
                                                (SELECT DISTINCT
                                                        SORLFOS_MAJR_CODE
                                                   FROM sorlcur cu,
                                                        sorlfos ss
                                                  WHERE     cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                        AND cu.SORLCUR_SEQNO = ss.SORLFOS_LCUR_SEQNO
                                                        AND cu.sorlcur_pidm =  Ppidm
                                                        AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                        AND SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                        AND SORLCUR_CACT_CODE =  SORLFOS_CACT_CODE
                                                        AND sorlcur_program = Pprog))))
                   JOIN smbpgen
                      ON     sorlcur_program = smbpgen_program
                         AND smbpgen_term_code_eff = smrpaap_term_code_eff
                   JOIN smbagen
                      ON     smbagen_area = smrpaap_area
                         AND smbagen_active_ind = 'Y'
                         AND smbagen_term_code_eff = smrpaap_term_code_eff
                   JOIN smralib
                      ON     smrpaap_area = smralib_area
                         AND SMRALIB_LEVL_CODE = SORLCUR_LEVL_CODE
                   JOIN smracaa
                      ON     smracaa_area = smrarul_area
                         AND smracaa_rule = smrarul_key_rule
                   JOIN shrtrcr
                      ON     shrtrcr_pidm = spriden_pidm
                         AND shrtrcr_program = Pprog
                   JOIN shrtrce
                      ON     shrtrce_pidm = spriden_pidm
                         AND shrtrce_subj_code = smrarul_subj_code
                         AND shrtrce_crse_numb = smrarul_crse_numb_low
                         AND shrtrce_trit_seq_no = shrtrcr_trit_seq_no
                         AND shrtrce_tram_seq_no = shrtrcr_tram_seq_no
                   JOIN scrsyln
                      ON     scrsyln_subj_code = shrtrce_subj_code
                         AND scrsyln_crse_numb = shrtrce_crse_numb
                   JOIN shrgrde
                      ON     shrgrde_code = shrtrce_grde_code
                         AND shrgrde_levl_code = SORLCUR_LEVL_CODE
                         /* cambio escalas para prod */
                         AND SHRGRDE_TERM_CODE_EFFECTIVE =
                                (SELECT zstpara_param_desc
                                   FROM zstpara
                                  WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                        AND SUBSTR ( (SELECT f_getspridenid (Ppidm)
                                                  FROM DUAL), 1, 2) = zstpara_param_id
                                        AND zstpara_param_valor = sgbstdn_levl_code)
                   JOIN scbcrse
                      ON     scbcrse_subj_code = shrtrce_subj_code
                         AND scbcrse_crse_numb = shrtrce_crse_numb
                   LEFT OUTER JOIN zstpara
                      ON     zstpara_mapa_id = 'MAESTRIAS_BIM'
                         AND zstpara_param_id = sorlcur_program
                         AND zstpara_param_desc = SORLCUR_TERM_CODE_CTLG
             WHERE spriden_pidm = ppidm 
             AND spriden_change_ind IS NULL
       UNION
            SELECT DISTINCT
                      spriden_first_name || ' ' || REPLACE (spriden_last_name, '/', ' ') "Estudiante",
                   spriden_id "Matricula",
                   sztdtec_programa_comp "Programa",
                   20 "per",
                   'TALLERES' "nombre_area",
                   smrarul_subj_code || smrarul_crse_numb_low "materia",
                   (SELECT ZSTPARA_PARAM_DESC
                      FROM ZSTPARA
                     WHERE     1 = 1
                           AND ZSTPARA_MAPA_ID = 'MAT_TRADUC'
                           AND ZSTPARA_PARAM_ID = smrarul_subj_code || smrarul_crse_numb_low) "NOMBRE_MAT",
                   --scrsyln_long_course_title "nombre_mat",
                   CASE
                      WHEN SUBSTR (stvterm_code, 1, 2) = '08'
                      THEN
                         SUBSTR (stvterm_desc, 7, 4)
                      ELSE
                         SUBSTR (stvterm_desc, 1, 6)
                   END
                      "periodo",
                   shrtckg_grde_code_final "calif",
                   shrgrde_abbrev "letra",
                   0 "Avance",
                   0 "Promedio",
                   shrgrde_passed_ind "aprobatoria",
                   scbcrse_credit_hr_low "creditos",
                   CASE
                      WHEN SUBSTR (shrtckn_term_code, 5, 1) = '8' THEN 'EXT'
                      ELSE 'ORD'
                   END
                      "evaluacion",
               (select   REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '') ||' - '||
                         REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '')
                        from sfrstcr f, ssbsect bb
                        where 1=1
                        and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                        and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                         and f.SFRSTCR_GRDE_CODE is not null
                        and SFRSTCR_PIDM = ppidm
                        and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                        and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16
              FROM spriden
                   JOIN sgbstdn a
                      ON     sgbstdn_pidm = spriden_pidm
                         AND sgbstdn_term_code_eff IN
                                (SELECT MAX (sgbstdn_term_code_eff)
                                   FROM sgbstdn b
                                  WHERE     a.sgbstdn_pidm = b.sgbstdn_pidm
                                        AND b.SGBSTDN_PROGRAM_1 = pprog)
                   JOIN sorlcur
                      ON     sorlcur_pidm = sgbstdn_pidm
                         AND sorlcur_program = Pprog
                         AND sorlcur_lmod_code = 'LEARNER'
                   JOIN smrprle
                      ON sorlcur_program = smrprle_program
                   JOIN sztdtec
                      ON     sorlcur_program = sztdtec_program
                         AND SORLCUR_CAMP_CODE = sztdtec_camp_code
                         AND sztdtec_status = 'ACTIVO'
                         AND SZTDTEC_TERM_CODE = SORLCUR_TERM_CODE_CTLG
                   JOIN smrpaap s
                      ON     smrpaap_program = sorlcur_program
                         AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
                   JOIN smrarul
                      ON     smrpaap_area = smrarul_area
                         AND smrarul_area IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE ZSTPARA_MAPA_ID = 'ORDEN_CUATRIMES')
                         AND (   (    smrarul_area NOT IN
                                         (SELECT smriecc_area FROM smriecc)
                                  AND smrarul_area NOT IN
                                         (SELECT smriemj_area FROM smriemj))
                              OR (    smrarul_area IN
                                         (SELECT smriemj_area
                                            FROM smriemj
                                           WHERE smriemj_majr_code =
                                                    (SELECT DISTINCT
                                                            SORLFOS_MAJR_CODE
                                                       FROM sorlcur cu,
                                                            sorlfos ss
                                                      WHERE     cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                            AND cu.SORLCUR_SEQNO = ss.SORLFOS_LCUR_SEQNO
                                                            AND cu.sorlcur_pidm = Ppidm
                                                            AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                            AND SORLFOS_LFST_CODE = 'MAJOR'
                                                            AND SORLCUR_CACT_CODE =  SORLFOS_CACT_CODE
                                                            AND sorlcur_program = Pprog))
                                  AND smrarul_area NOT IN
                                         (SELECT smriecc_area FROM smriecc))
                              OR (smrarul_area IN
                                     (SELECT smriecc_area
                                        FROM smriecc
                                       WHERE smriecc_majr_code_conc IN
                                                (SELECT DISTINCT
                                                        SORLFOS_MAJR_CODE
                                                   FROM sorlcur cu,
                                                        sorlfos ss
                                                  WHERE     cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                        AND cu.SORLCUR_SEQNO = ss.SORLFOS_LCUR_SEQNO
                                                        AND cu.sorlcur_pidm = Ppidm
                                                        AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                        AND SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                        AND SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                        AND sorlcur_program = Pprog))))
                   JOIN smbpgen
                      ON     sorlcur_program = smbpgen_program
                         AND smbpgen_term_code_eff = smrpaap_term_code_eff
                   JOIN smbagen
                      ON     smbagen_area = smrpaap_area
                         AND smbagen_active_ind = 'Y'
                         AND smbagen_term_code_eff = smrpaap_term_code_eff
                   JOIN smralib
                      ON     smrpaap_area = smralib_area
                         AND SMRALIB_LEVL_CODE = SORLCUR_LEVL_CODE
                   JOIN smracaa
                      ON     smracaa_area = smrarul_area
                         AND smracaa_rule = smrarul_key_rule
                   JOIN shrtckn w
                      ON     shrtckn_pidm = spriden_pidm
                         AND shrtckn_subj_code = smrarul_subj_code
                         AND shrtckn_crse_numb = smrarul_crse_numb_low
                         AND shrtckn_stsp_key_sequence = sorlcur_key_seqno
                         AND SHRTCKN_TERM_CODE IN
                                (SELECT MAX (SHRTCKN_TERM_CODE)
                                   FROM shrtckn ww
                                  WHERE     w.shrtckn_pidm = ww.shrtckn_pidm
                                        AND w.shrtckn_subj_code =  ww.shrtckn_subj_code
                                        AND w.shrtckn_crse_numb = ww.shrtckn_crse_numb)
                   JOIN shrtckg
                      ON     shrtckg_pidm = shrtckn_pidm
                         AND shrtckg_term_code = shrtckn_term_code
                         AND shrtckg_tckn_seq_no = shrtckn_seq_no
                         AND shrtckg_term_code = shrtckn_term_code
                   JOIN scrsyln
                      ON     scrsyln_subj_code = shrtckn_subj_code
                         AND scrsyln_crse_numb = shrtckn_crse_numb
                   JOIN shrgrde
                      ON     shrgrde_code = shrtckg_grde_code_final
                         AND shrgrde_levl_code = SORLCUR_LEVL_CODE
                         /* cambio escalas para prod */
                         AND SHRGRDE_TERM_CODE_EFFECTIVE =
                                (SELECT zstpara_param_desc
                                   FROM zstpara
                                  WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                        AND SUBSTR (
                                               (SELECT f_getspridenid (Ppidm)
                                                  FROM DUAL), 1, 2) = zstpara_param_id
                                        AND zstpara_param_valor =  sgbstdn_levl_code)
                   JOIN stvterm
                      ON stvterm_code = shrtckn_term_code
                   JOIN scbcrse
                      ON     scbcrse_subj_code = shrtckn_subj_code
                         AND scbcrse_crse_numb = shrtckn_crse_numb
                   LEFT OUTER JOIN zstpara
                      ON     zstpara_mapa_id = 'MAESTRIAS_BIM'
                         AND zstpara_param_id = sorlcur_program
                         AND zstpara_param_desc = SORLCUR_TERM_CODE_CTLG
             WHERE spriden_pidm = ppidm 
             AND spriden_change_ind IS NULL
            ORDER BY "Matricula",
                     "per",
                     "nombre_area",
                     "materia";
      ELSE
        
          OPEN histac_out FOR
            SELECT DISTINCT
                      spriden_first_name || ' ' || REPLACE (spriden_last_name, '/', ' ') "Estudiante",
                   spriden_id "Matricula",
                   sztdtec_programa_comp "Programa",
                   TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) "per",
                   CASE
                      WHEN    shrtckn_subj_code IS NULL
                           OR SUBSTR (stvterm_code, 1, 2) = '08' THEN ' '
                      ELSE
                         CASE
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('01')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1) || 'st. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('02')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1) || 'nd. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('03')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1) || 'rd. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN
                                    ('04','05','06','07','08','09','10','11','12')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1)|| 'th.  '|| 'Term'
                            ELSE
                               smralib_area_desc
                         END
                   END as  "nombre_area",
                   smrarul_subj_code || smrarul_crse_numb_low "materia",
                   (SELECT ZSTPARA_PARAM_DESC
                      FROM ZSTPARA
                     WHERE     1 = 1
                           AND ZSTPARA_MAPA_ID = 'MAT_TRADUC'
                           AND ZSTPARA_PARAM_ID = smrarul_subj_code || smrarul_crse_numb_low) as "NOMBRE_MAT",
                   --scrsyln_long_course_title "nombre_mat",
                   CASE
                      WHEN SUBSTR (stvterm_code, 1, 2) = '08'
                      THEN
                         SUBSTR (stvterm_desc, 7, 4)
                      ELSE
                         SUBSTR (stvterm_desc, 1, 6)
                   END as "periodo",
                   shrtckg_grde_code_final "calif",
                   shrgrde_abbrev "letra",
                   0 "Avance",
                   0 "Promedio",
                   shrgrde_passed_ind "aprobatoria",
                   scbcrse_credit_hr_low "creditos",
                   CASE
                      WHEN SUBSTR (shrtckn_term_code, 5, 1) = '8' THEN 'ORD' --olc   cambio de EXT por ORD para maestria, master
                      ELSE 'ORD'
                   END  "evaluacion",
                    (select   REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '') ||' - '||
                         REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '')
                        from sfrstcr f, ssbsect bb
                        where 1=1
                        and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                        and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                         and f.SFRSTCR_GRDE_CODE is not null
                        and SFRSTCR_PIDM = ppidm
                        and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                        and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16
              FROM spriden
                   JOIN sgbstdn a
                      ON     sgbstdn_pidm = spriden_pidm
                         AND sgbstdn_term_code_eff IN
                                (SELECT MAX (sgbstdn_term_code_eff)
                                   FROM sgbstdn b
                                  WHERE     a.sgbstdn_pidm = b.sgbstdn_pidm
                                        AND b.SGBSTDN_PROGRAM_1 = Pprog)
                   JOIN sorlcur s
                      ON     sorlcur_pidm = spriden_pidm
                         AND sorlcur_program = Pprog
                         AND sorlcur_lmod_code = 'LEARNER'
                         AND sorlcur_seqno IN
                                (SELECT MAX (sorlcur_seqno)
                                   FROM sorlcur ss
                                  WHERE     s.sorlcur_pidm = ss.sorlcur_pidm
                                        AND s.sorlcur_program = ss.sorlcur_program
                                        AND s.sorlcur_lmod_code =  ss.sorlcur_lmod_code)
                   JOIN smrprle
                      ON sorlcur_program = smrprle_program
                   JOIN sztdtec
                      ON     sorlcur_program = sztdtec_program
                         AND SORLCUR_CAMP_CODE = sztdtec_camp_code
                         AND sztdtec_status = 'ACTIVO'
                         AND SZTDTEC_TERM_CODE = SORLCUR_TERM_CODE_CTLG
                   JOIN smrpaap s
                      ON     smrpaap_program = sorlcur_program
                         AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
                   JOIN smrarul
                      ON     smrpaap_area = smrarul_area
                         AND SMRARUL_TERM_CODE_EFF = smrpaap_term_code_eff
                         AND smrarul_area NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE ZSTPARA_MAPA_ID = 'ORDEN_CUATRIMES')
                         AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE     ZSTPARA_MAPA_ID = 'NOVER_MAT_DASHB'
                                        AND spriden_pidm IN
                                               (SELECT spriden_pidm
                                                  FROM spriden
                                                 WHERE spriden_id = ZSTPARA_PARAM_ID))
                   JOIN smbpgen
                      ON     sorlcur_program = smbpgen_program
                         AND smbpgen_term_code_eff = smrpaap_term_code_eff
                   JOIN smbagen
                      ON     smbagen_area = smrpaap_area
                         AND smbagen_active_ind = 'Y'
                         AND smbagen_term_code_eff = smrpaap_term_code_eff
                   JOIN smralib
                      ON     smrpaap_area = smralib_area
                         AND SMRALIB_LEVL_CODE = SORLCUR_LEVL_CODE
                   JOIN smracaa
                      ON     smracaa_area = smrarul_area
                         AND smracaa_rule = smrarul_key_rule
                   JOIN shrtckn w
                      ON     shrtckn_pidm = spriden_pidm
                         AND shrtckn_subj_code = smrarul_subj_code
                         AND shrtckn_crse_numb = smrarul_crse_numb_low
                         AND shrtckn_stsp_key_sequence = sorlcur_key_seqno
                   JOIN shrtckg z
                      ON     shrtckg_pidm = shrtckn_pidm
                         AND shrtckg_term_code = shrtckn_term_code
                         AND shrtckg_tckn_seq_no = shrtckn_seq_no
                         AND shrtckg_term_code = shrtckn_term_code
                         AND DECODE (shrtckg_grde_code_final,'NA', 4,'NP', 4,'AC', 6,
                                     TO_NUMBER (shrtckg_grde_code_final)) IN
                                (SELECT MAX ( DECODE (shrtckg_grde_code_final,'NA', 4,'NP', 4,'AC', 6,TO_NUMBER (shrtckg_grde_code_final)))
                                   FROM shrtckn ww, shrtckg zz
                                  WHERE     w.shrtckn_pidm = ww.shrtckn_pidm
                                        AND w.shrtckn_subj_code =ww.shrtckn_subj_code
                                        AND w.shrtckn_crse_numb =ww.shrtckn_crse_numb
                                        AND ww.shrtckn_pidm = zz.shrtckg_pidm
                                        AND ww.shrtckn_seq_no = zz.shrtckg_tckn_seq_no
                                        AND ww.shrtckn_term_code = zz.shrtckg_term_code)
                   JOIN scrsyln
                      ON     scrsyln_subj_code = shrtckn_subj_code
                         AND scrsyln_crse_numb = shrtckn_crse_numb
                   JOIN shrgrde
                      ON     shrgrde_code = shrtckg_grde_code_final
                         AND shrgrde_levl_code = SORLCUR_LEVL_CODE
                         AND shrgrde_passed_ind = 'Y'
                         /* cambio escalas para prod */
                         AND SHRGRDE_TERM_CODE_EFFECTIVE =
                                (SELECT zstpara_param_desc
                                   FROM zstpara
                                  WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                        AND SUBSTR ( (SELECT f_getspridenid (ppidm)
                                                  FROM DUAL), 1, 2) = zstpara_param_id
                                        AND zstpara_param_valor =  sgbstdn_levl_code)
                   JOIN stvterm
                      ON stvterm_code = shrtckn_term_code
                   JOIN scbcrse
                      ON     scbcrse_subj_code = shrtckn_subj_code
                         AND scbcrse_crse_numb = shrtckn_crse_numb
                   LEFT OUTER JOIN zstpara
                      ON     zstpara_mapa_id = 'MAESTRIAS_BIM'
                         AND zstpara_param_id = sorlcur_program
                         AND zstpara_param_desc = SORLCUR_TERM_CODE_CTLG
             WHERE spriden_pidm = ppidm 
             AND spriden_change_ind IS NULL
       UNION
            SELECT DISTINCT
                      spriden_first_name|| ' ' || REPLACE (spriden_last_name, '/', ' ') "Estudiante",
                   spriden_id "Matricula",
                   sztdtec_programa_comp "Programa",
                   TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) "per",
                   CASE
                      WHEN    shrtrce_subj_code IS NULL
                           OR SUBSTR (spriden_id, 1, 2) = '08'
                      THEN  ' '
                      ELSE
                         CASE
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('01')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1)|| 'st. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('02')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1) || 'nd. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN ('03')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1) || 'rd. ' || 'Term'
                            WHEN SUBSTR (smrarul_area, 9, 2) IN
                                    ('04', '05','06','07','08','09','10','11','12')
                            THEN
                                  SUBSTR (smrarul_area, 10, 1)|| 'th.  ' || 'Term'
                            ELSE
                               smralib_area_desc
                         END
                   END as  "nombre_area",
                   smrarul_subj_code || smrarul_crse_numb_low "materia",
                   (SELECT ZSTPARA_PARAM_DESC
                      FROM ZSTPARA
                     WHERE     1 = 1
                           AND ZSTPARA_MAPA_ID = 'MAT_TRADUC'
                           AND ZSTPARA_PARAM_ID =
                                  smrarul_subj_code || smrarul_crse_numb_low)
                      "NOMBRE_MAT",
                   --scrsyln_long_course_title "nombre_mat",
                   ' ' "periodo",
                   shrtrce_grde_code "calif",
                   shrgrde_abbrev "letra",
                   0 "Avance",
                   0 "Promedio",
                   shrgrde_passed_ind "aprobatoria",
                   scbcrse_credit_hr_low "creditos",
                   'EQ' "evaluacion",
                   (select   REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '') ||' - '||
                         REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '')
                        from sfrstcr f, ssbsect bb
                        where 1=1
                        and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                        and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                         and f.SFRSTCR_GRDE_CODE is not null
                        and SFRSTCR_PIDM = ppidm
                        and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                        and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16
              FROM spriden
                   JOIN sgbstdn a
                      ON     sgbstdn_pidm = spriden_pidm
                         AND sgbstdn_term_code_eff IN
                                (SELECT MAX (sgbstdn_term_code_eff)
                                   FROM sgbstdn b
                                  WHERE     a.sgbstdn_pidm = b.sgbstdn_pidm
                                        AND b.SGBSTDN_PROGRAM_1 = pprog)
                   JOIN sorlcur s
                      ON     sorlcur_pidm = spriden_pidm
                         AND sorlcur_program = pprog
                         AND sorlcur_lmod_code = 'LEARNER'
                         AND sorlcur_seqno IN
                                (SELECT MAX (sorlcur_seqno)
                                   FROM sorlcur ss
                                  WHERE     s.sorlcur_pidm = ss.sorlcur_pidm
                                        AND s.sorlcur_program = ss.sorlcur_program
                                        AND s.sorlcur_lmod_code =  ss.sorlcur_lmod_code)
                   JOIN smrprle
                      ON sorlcur_program = smrprle_program
                   JOIN sztdtec
                      ON     sorlcur_program = sztdtec_program
                         AND SORLCUR_CAMP_CODE = sztdtec_camp_code
                         AND sztdtec_status = 'ACTIVO'
                         AND SZTDTEC_TERM_CODE = SORLCUR_TERM_CODE_CTLG
                   JOIN smrpaap s
                      ON     smrpaap_program = sorlcur_program
                         AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
                   JOIN smrarul
                      ON     smrpaap_area = smrarul_area
                         AND SMRARUL_TERM_CODE_EFF = smrpaap_term_code_eff
                         AND smrarul_area NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE     ZSTPARA_MAPA_ID =  'ORDEN_CUATRIMES'
                                        AND SUBSTR (ZSTPARA_PARAM_VALOR, 5, 2) <> 'TT')
                         AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE     ZSTPARA_MAPA_ID = 'NOVER_MAT_DASHB'
                                        AND spriden_pidm IN
                                               (SELECT spriden_pidm
                                                  FROM spriden
                                                 WHERE spriden_id =  ZSTPARA_PARAM_ID))
                   JOIN smbpgen
                      ON     sorlcur_program = smbpgen_program
                         AND smbpgen_term_code_eff = smrpaap_term_code_eff
                   JOIN smbagen
                      ON     smbagen_area = smrpaap_area
                         AND smbagen_active_ind = 'Y'
                         AND smbagen_term_code_eff = smrpaap_term_code_eff
                   JOIN smralib
                      ON     smrpaap_area = smralib_area
                         AND SMRALIB_LEVL_CODE = SORLCUR_LEVL_CODE
                   JOIN smracaa
                      ON     smracaa_area = smrarul_area
                         AND smracaa_rule = smrarul_key_rule
                   JOIN shrtrcr
                      ON     shrtrcr_pidm = spriden_pidm
                         AND shrtrcr_program = Pprog
                   JOIN shrtrce
                      ON     shrtrce_pidm = spriden_pidm
                         AND shrtrce_subj_code = smrarul_subj_code
                         AND shrtrce_crse_numb = smrarul_crse_numb_low
                         AND shrtrce_trit_seq_no = shrtrcr_trit_seq_no
                         AND shrtrce_tram_seq_no = shrtrcr_tram_seq_no
                   JOIN scrsyln
                      ON     scrsyln_subj_code = shrtrce_subj_code
                         AND scrsyln_crse_numb = shrtrce_crse_numb
                   JOIN shrgrde
                      ON     shrgrde_code = shrtrce_grde_code
                         AND shrgrde_levl_code = SORLCUR_LEVL_CODE
                         AND shrgrde_passed_ind = 'Y'
                         /* cambio escalas para prod */
                         AND shrgrde_term_code_effective =
                                (SELECT zstpara_param_desc
                                   FROM zstpara
                                  WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                        AND SUBSTR (
                                               (SELECT f_getspridenid (ppidm)
                                                  FROM DUAL), 1, 2) = zstpara_param_id
                                        AND zstpara_param_valor =  sgbstdn_levl_code)
                   JOIN scbcrse
                      ON     scbcrse_subj_code = shrtrce_subj_code
                         AND scbcrse_crse_numb = shrtrce_crse_numb
                   LEFT OUTER JOIN zstpara
                      ON     zstpara_mapa_id = 'MAESTRIAS_BIM'
                         AND zstpara_param_id = sorlcur_program
                         AND zstpara_param_desc = SORLCUR_TERM_CODE_CTLG
             WHERE spriden_pidm = ppidm 
             AND spriden_change_ind IS NULL
       UNION
            SELECT DISTINCT
                spriden_first_name || ' ' || REPLACE (spriden_last_name, '/', ' ') "Estudiante",
                   spriden_id "Matricula",
                   sztdtec_programa_comp "Programa",
                   20 "per",
                   'TALLERES' "nombre_area",
                   smrarul_subj_code || smrarul_crse_numb_low "materia",
                   (SELECT ZSTPARA_PARAM_DESC
                      FROM ZSTPARA
                     WHERE     1 = 1
                           AND ZSTPARA_MAPA_ID = 'MAT_TRADUC'
                           AND ZSTPARA_PARAM_ID =
                                  smrarul_subj_code || smrarul_crse_numb_low) "NOMBRE_MAT",
                   --scrsyln_long_course_title "nombre_mat",
                   CASE
                      WHEN SUBSTR (stvterm_code, 1, 2) = '08'
                      THEN
                         SUBSTR (stvterm_desc, 7, 4)
                      ELSE
                         SUBSTR (stvterm_desc, 1, 6)
                   END
                      "periodo",
                   shrtckg_grde_code_final "calif",
                   shrgrde_abbrev "letra",
                   0 "Avance",
                   0 "Promedio",
                   shrgrde_passed_ind "aprobatoria",
                   scbcrse_credit_hr_low "creditos",
                   CASE
                      WHEN SUBSTR (shrtckn_term_code, 5, 1) = '8' THEN 'ORD' --olc   cambio de EXT por ORD para maestria, master
                      ELSE 'ORD'
                   END  "evaluacion",
                (select   REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '') ||' - '||
                         REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy', 'NLS_DATE_LANGUAGE = English')), ' ', '')
                        from sfrstcr f, ssbsect bb
                        where 1=1
                        and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                        and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                         and f.SFRSTCR_GRDE_CODE is not null
                        and SFRSTCR_PIDM = ppidm
                        and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                        and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16
                  FROM spriden
                   JOIN sgbstdn a
                      ON     sgbstdn_pidm = spriden_pidm
                         AND sgbstdn_term_code_eff IN
                                (SELECT MAX (sgbstdn_term_code_eff)
                                   FROM sgbstdn b
                                  WHERE     a.sgbstdn_pidm = b.sgbstdn_pidm
                                        AND b.SGBSTDN_PROGRAM_1 = Pprog)
                   JOIN sorlcur s
                      ON     sorlcur_pidm = sgbstdn_pidm
                         AND sorlcur_program = Pprog
                         AND sorlcur_lmod_code = 'LEARNER'
                         AND sorlcur_seqno IN
                                (SELECT MAX (sorlcur_seqno)
                                   FROM sorlcur ss
                                  WHERE     s.sorlcur_pidm = ss.sorlcur_pidm
                                        AND s.sorlcur_program =  ss.sorlcur_program
                                        AND s.sorlcur_lmod_code =  ss.sorlcur_lmod_code)
                   JOIN smrprle
                      ON sorlcur_program = smrprle_program
                   JOIN sztdtec
                      ON     sorlcur_program = sztdtec_program
                         AND SORLCUR_CAMP_CODE = sztdtec_camp_code
                         AND sztdtec_status = 'ACTIVO'
                         AND SZTDTEC_TERM_CODE = SORLCUR_TERM_CODE_CTLG
                   JOIN smrpaap s
                      ON     smrpaap_program = sorlcur_program
                         AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
                   JOIN smrarul
                      ON     smrpaap_area = smrarul_area
                         AND SMRARUL_TERM_CODE_EFF = smrpaap_term_code_eff
                         AND smrarul_area IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE ZSTPARA_MAPA_ID = 'ORDEN_CUATRIMES')
                         AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW NOT IN
                                (SELECT ZSTPARA_PARAM_VALOR
                                   FROM ZSTPARA
                                  WHERE     ZSTPARA_MAPA_ID = 'NOVER_MAT_DASHB'
                                        AND spriden_pidm IN
                                               (SELECT spriden_pidm
                                                  FROM spriden
                                                 WHERE spriden_id =   ZSTPARA_PARAM_ID))
                   JOIN smbpgen
                      ON     sorlcur_program = smbpgen_program
                         AND smbpgen_term_code_eff = smrpaap_term_code_eff
                   JOIN smbagen
                      ON     smbagen_area = smrpaap_area
                         AND smbagen_active_ind = 'Y'
                         AND smbagen_term_code_eff = smrpaap_term_code_eff
                   JOIN smralib
                      ON     smrpaap_area = smralib_area
                         AND SMRALIB_LEVL_CODE = SORLCUR_LEVL_CODE
                   JOIN smracaa
                      ON     smracaa_area = smrarul_area
                         AND smracaa_rule = smrarul_key_rule
                   JOIN shrtckn w
                      ON     shrtckn_pidm = spriden_pidm
                         AND shrtckn_subj_code = smrarul_subj_code
                         AND shrtckn_crse_numb = smrarul_crse_numb_low
                         AND shrtckn_seq_no IN
                                (SELECT MAX (shrtckn_seq_no)
                                   FROM shrtckn ww
                                  WHERE     w.shrtckn_pidm = ww.shrtckn_pidm
                                        AND w.shrtckn_subj_code =
                                               ww.shrtckn_subj_code
                                        AND w.shrtckn_crse_numb =
                                               ww.shrtckn_crse_numb)
                   JOIN shrtckg
                      ON     shrtckg_pidm = shrtckn_pidm
                         AND shrtckg_term_code = shrtckn_term_code
                         AND shrtckg_tckn_seq_no = shrtckn_seq_no
                         AND shrtckg_term_code = shrtckn_term_code
                   JOIN scrsyln
                      ON     scrsyln_subj_code = shrtckn_subj_code
                         AND scrsyln_crse_numb = shrtckn_crse_numb
                   JOIN shrgrde
                      ON     shrgrde_code = shrtckg_grde_code_final
                         AND shrgrde_levl_code = SORLCUR_LEVL_CODE
                         AND shrgrde_passed_ind = 'Y'
                         /* cambio escalas para prod */
                         AND shrgrde_term_code_effective =
                                (SELECT zstpara_param_desc
                                   FROM zstpara
                                  WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                        AND SUBSTR (
                                               (SELECT f_getspridenid (ppidm)
                                                  FROM DUAL),
                                               1,
                                               2) = zstpara_param_id
                                        AND zstpara_param_valor = sgbstdn_levl_code)
                   JOIN stvterm
                      ON stvterm_code = shrtckn_term_code
                   JOIN scbcrse
                      ON     scbcrse_subj_code = shrtckn_subj_code
                         AND scbcrse_crse_numb = shrtckn_crse_numb
                   LEFT OUTER JOIN zstpara
                      ON     zstpara_mapa_id = 'MAESTRIAS_BIM'
                         AND zstpara_param_id = sorlcur_program
                         AND zstpara_param_desc = SORLCUR_TERM_CODE_CTLG
             WHERE spriden_pidm = ppidm 
             AND spriden_change_ind IS NULL
            ORDER BY "Matricula", "per", "materia";
      END IF;

      RETURN (histac_out);
   EXCEPTION
      WHEN OTHERS
      THEN
         vsalida := 'PKG_QR_DIG.F_HIAC_ESP_INGL: ' || SQLERRM;
         ---    return vsalida;


   END F_HIAC_ESP_INGL;

   FUNCTION F_AVCU_INGL (ppidm IN NUMBER, pprog VARCHAR2)
      RETURN PKG_QR_DIG.avcu_out
   AS
      vcursor    SYS_REFCURSOR;
      avcu_out   PKG_QR_DIG.avcu_out;
      nivel      VARCHAR2 (2);
      vsalida    VARCHAR2 (200);

      pidm       NUMBER := ppidm;
      prog       VARCHAR2 (20) := pprog;
      -- se va a ejecutar el proceso normal del AVCU y solo le vamos a sustituir algunos valores al final
      usu_siu    VARCHAR2 (20) := 'user_qr';
      Pusu_siu   VARCHAR2 (20) := 'user_qr';
     
   BEGIN
         BEGIN
              DELETE FROM avance_n
                    WHERE     1 = 1
                          AND protocolo = 8889
                          AND pidm = ppidm
                          AND USUARIO_SIU = usu_siu;

              COMMIT;
           exception when others then
           null;
           
           end;
   
       BEGIN
          INSERT INTO avance_n
               SELECT datos1.noid,
                      datos1.per,
                      datos1.area,
                  DECODE (UPPER (datos1.nombre_area),
                          'SERVICIO SOCIAL', 'SOCIAL SERVICE',
                          'TALLERES DE TITULACION', 'DEGREE WORKSHOPS',
                          datos1.nombre_area),
                  datos1.materia,
                  datos1.nombre_mat,
                  NVL (datos1.calif, 0),
                  datos1.APR,
                  datos1.REGLA,
                  datos1.origen,
                  datos1.fecha,
                  datos1.pidm,
                  usu_siu
         FROM (SELECT DISTINCT /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                          8889 AS noid,
                          CASE  WHEN smralib_area_desc LIKE 'Servicio%'    THEN  TO_NUMBER (SUBSTR (smralib_area, 9, 2)) + 1
                             WHEN (   smralib_area_desc LIKE ('Taller%')
                                   OR smralib_area_desc LIKE ('CERTIFICATION%')) THEN  TO_NUMBER (SUBSTR (smralib_area, 9, 2)) + 1
                             ELSE
                                TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                          END  per,
                          smrpaap_area area,                              ----
                          CASE
                             WHEN smralib_area_desc LIKE 'Servicio%'   THEN 'Social service'
                             WHEN smralib_area_desc LIKE 'Taller%'     THEN 'Degree workshops'
                             ELSE
                                CASE
                                   WHEN smrpaap_area NOT IN
                                           (SELECT ZSTPARA_PARAM_VALOR
                                              FROM ZSTPARA
                                             WHERE ZSTPARA_MAPA_ID =  'ORDEN_CUATRIMES')
                                   THEN
                                      CASE
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN ('01') THEN
                                               SUBSTR (smrarul_area, 10, 1) || 'st.' || 'Term'
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN ('02')  THEN
                                               SUBSTR (smrarul_area, 10, 1) || 'nd.' || 'Term'
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN  ('03') THEN
                                               SUBSTR (smrarul_area, 10, 1) || 'rd.' || 'Term'
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN  ('04','05','06','07','08','09')  THEN
                                               SUBSTR (smrarul_area, 10, 1) || 'th.' || 'Term'
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN ('10', '11', '12') THEN
                                               SUBSTR (smrarul_area, 9, 2)  || 'th.' || 'Term'
                                      END
                                   ELSE
                                      'Degree workshops'
                                END
                          END   nombre_area,
                          smrarul_subj_code || smrarul_crse_numb_low AS materia,
                          --scrsyln_long_course_title nombre_mat,
                          (SELECT ZSTPARA_PARAM_DESC
                             FROM ZSTPARA
                            WHERE     1 = 1
                                  AND ZSTPARA_MAPA_ID = 'MAT_TRADUC'
                                  AND ZSTPARA_PARAM_ID = smrarul_subj_code || smrarul_crse_numb_low) AS nombre_mat,
                          CASE
                             WHEN k.calif IN ('NA', 'NP', 'AC') THEN '1'
                             WHEN k.st_mat = 'EC' THEN '101'
                             ELSE k.calif
                          END
                             calif,                                        ---
                          NVL (k.st_mat, 'PC') AS APR,                     ---
                          smracaa_rule AS regla,                           ---
                          CASE WHEN k.st_mat = 'EC' THEN NULL ELSE k.calif END  AS origen,
                          k.fecha AS fecha,                                ---
                          pidm AS pidm,
                          usu_siu AS usu_siu
                  FROM smrpaap s,
                          smrarul,
                          sgbstdn y,
                          sorlcur so,
                          spriden,
                          sztdtec,
                          stvstst,
                          smralib,
                          smracaa,
                          scrsyln,
                          zstpara,
                          smbagen,
                    (SELECT /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                 w.shrtckn_subj_code subj,
                                  w.shrtckn_crse_numb code,
                                  shrtckg_grde_code_final CALIF,
                                  DECODE (shrgrde_passed_ind,
                                          'Y', 'AP',
                                          'N', 'NA')
                                     ST_MAT,
                                  shrtckg_final_grde_chg_date fecha
                             FROM shrtckn w,
                                  shrtckg,
                                  shrgrde,
                                  smrprle
                            WHERE     shrtckn_pidm = pidm
                                  AND shrtckg_pidm = w.shrtckn_pidm
                                  AND SHRTCKN_SUBJ_CODE || SHRTCKN_CRSE_NUMB NOT IN
                                         ('L1HB401', 'L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001','M1HB401')
                                  AND shrtckg_tckn_seq_no = w.shrtckn_seq_no
                                  AND shrtckg_term_code = w.shrtckn_term_code
                                  AND smrprle_program = prog
                                  AND shrgrde_levl_code = smrprle_levl_code -------------------
                                  /* cambio escalas para prod */
                                  AND shrgrde_term_code_effective =
                                         (SELECT zstpara_param_desc
                                            FROM zstpara
                                           WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                                 AND SUBSTR ( (SELECT f_getspridenid (pidm) FROM DUAL),1, 2) = zstpara_param_id
                                                 AND zstpara_param_valor = smrprle_levl_code)
                                  AND shrgrde_code = shrtckg_grde_code_final
                                  AND DECODE ( shrtckg_grde_code_final,'NA', 4, 'NP', 4,'AC', 6, TO_NUMBER (shrtckg_grde_code_final)) -- anadido para sacar la calificacion mayor  OLC
                                      IN (SELECT MAX (DECODE ( shrtckg_grde_code_final, 'NA', 4, 'NP', 4,'AC', 6, TO_NUMBER ( shrtckg_grde_code_final)))
                                            FROM shrtckn ww, shrtckg zz
                                           WHERE     w.shrtckn_pidm =  ww.shrtckn_pidm
                                                 AND w.shrtckn_subj_code = ww.shrtckn_subj_code
                                                 AND w.shrtckn_crse_numb = ww.shrtckn_crse_numb
                                                 AND ww.shrtckn_pidm = zz.shrtckg_pidm
                                                 AND ww.shrtckn_seq_no = zz.shrtckg_tckn_seq_no
                                                 AND ww.shrtckn_term_code = zz.shrtckg_term_code)
                                  AND SHRTCKN_SUBJ_CODE || SHRTCKN_CRSE_NUMB NOT IN
                                         (SELECT ZSTPARA_PARAM_VALOR
                                            FROM ZSTPARA
                                           WHERE     ZSTPARA_MAPA_ID =
                                                        'NOVER_MAT_DASHB'
                                                 AND shrtckn_pidm IN
                                                        (SELECT spriden_pidm
                                                           FROM spriden
                                                          WHERE spriden_id =
                                                                   ZSTPARA_PARAM_ID))
                   UNION
                           SELECT shrtrce_subj_code subj,
                                  shrtrce_crse_numb code,
                                  shrtrce_grde_code CALIF,
                                  'EQ' ST_MAT,
                                  TRUNC (shrtrce_activity_date) fecha
                             FROM shrtrce
                            WHERE     shrtrce_pidm = pidm
                                  AND SHRTRCE_SUBJ_CODE || SHRTRCE_CRSE_NUMB NOT IN
                                         ('L1HB401',
                                          'L1HB402',
                                          'L1HB403',
                                          'L1HB404',
                                          'L1HB405',
                                          'L1HP401',
                                          'UTEL001',
                                          'M1HB401')
                  UNION
                           SELECT SHRTRTK_SUBJ_CODE_INST subj,
                                  SHRTRTK_CRSE_NUMB_INST code,
                                  /*nvl(SHRTRTK_GRDE_CODE_INST,0)*/
                                  '0' CALIF,
                                  'EQ' ST_MAT,
                                  TRUNC (SHRTRTK_ACTIVITY_DATE) fecha
                             FROM SHRTRTK
                            WHERE SHRTRTK_PIDM = pidm
                  UNION
                           SELECT ssbsect_subj_code subj,
                                  ssbsect_crse_numb code,
                                  '101' CALIF,
                                  'EC' ST_MAT,
                                  TRUNC (sfrstcr_rsts_date) + 120 fecha
                             FROM sfrstcr,
                                  smrprle,
                                  ssbsect,
                                  spriden
                            WHERE     smrprle_program = prog
                                  AND sfrstcr_pidm = pidm
                                  AND sfrstcr_grde_code IS NULL
                                  AND sfrstcr_rsts_code = 'RE'
                                  AND SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB NOT IN
                                         ('L1HB401',
                                          'L1HB402',
                                          'L1HB403',
                                          'L1HB404',
                                          'L1HB405',
                                          'L1HP401',
                                          'UTEL001',
                                          'M1HB401')
                                  AND spriden_pidm = sfrstcr_pidm
                                  AND spriden_change_ind IS NULL
                                  --                                              and    sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                  AND ssbsect_term_code = sfrstcr_term_code
                                  AND ssbsect_crn = sfrstcr_crn
                  UNION
                           SELECT /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                 ssbsect_subj_code subj,
                                  ssbsect_crse_numb code,
                                  sfrstcr_grde_code CALIF,
                                  DECODE (shrgrde_passed_ind,
                                          'Y', 'AP',
                                          'N', 'NA')
                                     ST_MAT,
                                  TRUNC (sfrstcr_rsts_date) /*+120*/
                                                           fecha
                             FROM sfrstcr,
                                  smrprle,
                                  ssbsect,
                                  spriden,
                                  shrgrde
                            WHERE     smrprle_program = prog
                                  AND sfrstcr_pidm = pidm
                                  AND sfrstcr_grde_code IS NOT NULL
                                  AND sfrstcr_pidm NOT IN
                                         (SELECT shrtckn_pidm
                                            FROM shrtckn
                                           WHERE     sfrstcr_term_code =
                                                        shrtckn_term_code
                                                 AND shrtckn_crn = sfrstcr_crn)
                                  AND SFRSTCR_RSTS_CODE != 'DD'   --- agregado
                                  AND spriden_pidm = sfrstcr_pidm
                                  AND spriden_change_ind IS NULL
                                  --                                             and   sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                  AND SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB NOT IN
                                         ('L1HB401',
                                          'L1HB402',
                                          'L1HB403',
                                          'L1HB404',
                                          'L1HB405',
                                          'L1HP401',
                                          'UTEL001',
                                          'M1HB401')
                                  AND SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB NOT IN
                                         (SELECT ZSTPARA_PARAM_VALOR
                                            FROM ZSTPARA
                                           WHERE     ZSTPARA_MAPA_ID =
                                                        'NOVER_MAT_DASHB'
                                                 AND sfrstcr_pidm IN
                                                        (SELECT spriden_pidm
                                                           FROM spriden
                                                          WHERE spriden_id =
                                                                   ZSTPARA_PARAM_ID))
                                  AND ssbsect_term_code = sfrstcr_term_code
                                  AND ssbsect_crn = sfrstcr_crn
                                  AND shrgrde_levl_code = smrprle_levl_code -------------------
                                  /* cambio escalas para prod */
                                  AND shrgrde_term_code_effective =
                                         (SELECT zstpara_param_desc
                                            FROM zstpara
                                           WHERE     zstpara_mapa_id =
                                                        'ESC_SHAGRD'
                                                 AND SUBSTR (
                                                        (SELECT f_getspridenid (
                                                                   pidm)
                                                           FROM DUAL),
                                                        1,
                                                        2) = zstpara_param_id
                                                 AND zstpara_param_valor =
                                                        smrprle_levl_code)
                                                 AND shrgrde_code = sfrstcr_grde_code) k
                    WHERE     spriden_pidm = pidm
                          AND spriden_change_ind IS NULL
                          AND sorlcur_pidm = spriden_pidm
                          AND SORLCUR_LMOD_CODE = 'LEARNER'
                          AND SORLCUR_SEQNO IN
                                 (SELECT MAX (SORLCUR_SEQNO)
                                    FROM sorlcur ss
                                   WHERE     so.SORLCUR_PIDM = ss.sorlcur_pidm
                                         AND so.sorlcur_lmod_code =
                                                ss.sorlcur_lmod_code
                                         AND ss.sorlcur_program = prog)
                          AND smrpaap_program = prog
                          AND smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                          AND smrpaap_area = SMBAGEN_AREA --solo areas activas  OLC
                          AND SMBAGEN_ACTIVE_IND = 'Y' --solo areas activas  OLC
                          AND SMRPAAP_TERM_CODE_EFF = SMBAGEN_TERM_CODE_EFF --solo areas activas  OLC
                          AND smrpaap_area = smrarul_area
                          AND sgbstdn_pidm = spriden_pidm
                          AND sgbstdn_program_1 = smrpaap_program
                          AND sgbstdn_term_code_eff IN
                                 (SELECT MAX (sgbstdn_term_code_eff)
                                    FROM sgbstdn x
                                   WHERE     x.sgbstdn_pidm = y.sgbstdn_pidm
                                         AND x.sgbstdn_program_1 =
                                                y.sgbstdn_program_1)
                          AND sztdtec_program = sgbstdn_program_1
                          AND sztdtec_status = 'ACTIVO'
                          AND SZTDTEC_CAMP_CODE = SORLCUR_CAMP_CODE --- **** nuevo CAPP ****
                          AND SZTDTEC_TERM_CODE = SORLCUR_TERM_CODE_CTLG
                          AND SMRARUL_TERM_CODE_EFF = SMRACAA_TERM_CODE_EFF
                          AND stvstst_code = sgbstdn_stst_code
                          AND smralib_area = smrpaap_area
                          AND smracaa_area = smrarul_area
                          AND smracaa_rule = smrarul_key_rule
                          AND SMRACAA_TERM_CODE_EFF = SORLCUR_TERM_CODE_CTLG
                          AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW NOT IN
                                 ('L1HB401',
                                  'L1HB402',
                                  'L1HB403',
                                  'L1HB404',
                                  'L1HB405',
                                  'L1HP401',
                                  'UTEL001',
                                  'M1HB401')
                          AND (   (    smrarul_area NOT IN
                                          (SELECT smriecc_area FROM smriecc)
                                   AND smrarul_area NOT IN
                                          (SELECT smriemj_area FROM smriemj))
                               OR (    smrarul_area IN
                                          (SELECT smriemj_area
                                             FROM smriemj
                                            WHERE smriemj_majr_code =
                                                     (SELECT DISTINCT
                                                             SORLFOS_MAJR_CODE
                                                        FROM sorlcur cu,
                                                             sorlfos ss
                                                       WHERE     cu.sorlcur_pidm =
                                                                    Ss.SORLfos_PIDM
                                                             AND cu.SORLCUR_SEQNO =
                                                                    ss.SORLFOS_LCUR_SEQNO
                                                             AND cu.sorlcur_pidm =
                                                                    pidm
                                                             AND SORLCUR_LMOD_CODE =
                                                                    'LEARNER'
                                                             AND SORLFOS_LFST_CODE =
                                                                    'MAJOR'
                                                             AND cu.SORLCUR_SEQNO IN
                                                                    (SELECT MAX (
                                                                               SORLCUR_SEQNO)
                                                                       FROM sorlcur ss
                                                                      WHERE     cu.SORLCUR_PIDM =
                                                                                   ss.sorlcur_pidm
                                                                            AND cu.sorlcur_lmod_code =
                                                                                   ss.sorlcur_lmod_code
                                                                            AND ss.sorlcur_program =
                                                                                   prog)
                                                             AND cu.SORLCUR_TERM_CODE IN
                                                                    (SELECT MAX (
                                                                               SORLCUR_TERM_CODE)
                                                                       FROM sorlcur ss
                                                                      WHERE     cu.SORLCUR_PIDM =
                                                                                   ss.sorlcur_pidm
                                                                            AND cu.sorlcur_lmod_code =
                                                                                   ss.sorlcur_lmod_code
                                                                            AND ss.sorlcur_program =
                                                                                   prog)
                                                             AND SORLCUR_CACT_CODE =
                                                                    SORLFOS_CACT_CODE
                                                             AND sorlcur_program =
                                                                    prog))
                                   AND smrarul_area NOT IN
                                          (SELECT smriecc_area FROM smriecc))
                               OR (smrarul_area IN
                                      (SELECT smriecc_area
                                         FROM smriecc
                                        WHERE smriecc_majr_code_conc IN
                                                 (SELECT DISTINCT
                                                         SORLFOS_MAJR_CODE
                                                    FROM sorlcur cu, sorlfos ss
                                                   WHERE     cu.sorlcur_pidm =
                                                                Ss.SORLfos_PIDM
                                                         AND cu.SORLCUR_SEQNO =
                                                                ss.SORLFOS_LCUR_SEQNO
                                                         AND cu.SORLCUR_SEQNO IN
                                                                (SELECT MAX (
                                                                           SORLCUR_SEQNO)
                                                                   FROM sorlcur ss
                                                                  WHERE     cu.SORLCUR_PIDM =
                                                                               ss.sorlcur_pidm
                                                                        AND cu.sorlcur_lmod_code =
                                                                               ss.sorlcur_lmod_code
                                                                        AND ss.sorlcur_program =
                                                                               prog)
                                                         AND cu.sorlcur_pidm =
                                                                pidm
                                                         AND SORLCUR_LMOD_CODE =
                                                                'LEARNER'
                                                         AND SORLFOS_LFST_CODE =
                                                                'CONCENTRATION'
                                                         AND SORLCUR_CACT_CODE =
                                                                SORLFOS_CACT_CODE
                                                         AND sorlcur_program =
                                                                prog))))
                          AND k.subj = smrarul_subj_code
                          AND k.code = smrarul_crse_numb_low
                          AND scrsyln_subj_code = smrarul_subj_code
                          AND scrsyln_crse_numb = smrarul_crse_numb_low
                          AND zstpara_mapa_id(+) = 'MAESTRIAS_BIM'
                          AND zstpara_param_id(+) = sgbstdn_program_1
                          AND zstpara_param_desc(+) = SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                 UNION
                      SELECT DISTINCT /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                          8889,
                          CASE
                             WHEN smralib_area_desc LIKE 'Servicio%'
                             THEN
                                TO_NUMBER (SUBSTR (smralib_area, 9, 2)) + 1
                             WHEN (   smralib_area_desc LIKE ('Taller%')
                                   OR smralib_area_desc LIKE ('CERTIFICATION%'))
                             THEN
                                TO_NUMBER (SUBSTR (smralib_area, 9, 2)) + 1
                             ELSE
                                TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                          END
                             per,                                          ---
                          smrpaap_area area,                               ---
                          CASE
                             WHEN smralib_area_desc LIKE 'Servicio%'
                             THEN
                                'Social service'
                             WHEN smralib_area_desc LIKE 'Taller%'
                             THEN
                                'Degree workshops'
                             ELSE
                                CASE
                                   WHEN smrpaap_area NOT IN
                                           (SELECT ZSTPARA_PARAM_VALOR
                                              FROM ZSTPARA
                                             WHERE ZSTPARA_MAPA_ID =
                                                      'ORDEN_CUATRIMES')
                                   THEN
                                      CASE
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN
                                                 ('01')
                                         THEN
                                               SUBSTR (smrarul_area, 10, 1)
                                            || 'st.'
                                            || 'Term'
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN
                                                 ('02')
                                         THEN
                                               SUBSTR (smrarul_area, 10, 1)
                                            || 'nd.'
                                            || 'Term'
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN
                                                 ('03')
                                         THEN
                                               SUBSTR (smrarul_area, 10, 1)
                                            || 'rd.'
                                            || 'Term'
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN
                                                 ('04',
                                                  '05',
                                                  '06',
                                                  '07',
                                                  '08',
                                                  '09')
                                         THEN
                                               SUBSTR (smrarul_area, 10, 1)
                                            || 'th.'
                                            || 'Term'
                                         WHEN SUBSTR (smrarul_area, 9, 2) IN
                                                 ('10', '11', '12')
                                         THEN
                                               SUBSTR (smrarul_area, 9, 2)
                                            || 'th.'
                                            || 'Term'
                                      END
                                   ELSE
                                      'Degree workshops'
                                END
                          END
                             nombre_area,
                          smrarul_subj_code || smrarul_crse_numb_low materia, ---
                          (SELECT ZSTPARA_PARAM_DESC
                             FROM ZSTPARA
                            WHERE     1 = 1
                                  AND ZSTPARA_MAPA_ID = 'MAT_TRADUC'
                                  AND ZSTPARA_PARAM_ID =
                                            smrarul_subj_code
                                         || smrarul_crse_numb_low)
                             AS nombre_mat,
                          ---scrsyln_long_course_title nombre_mat,            ---
                          NULL calif,                                      ---
                          'PC',                                            ---
                          smracaa_rule regla,                              ---
                          NULL origen,                                     ---
                          NULL fecha,                                       --
                          pidm,
                          usu_siu
                    FROM spriden,
                          smrpaap,
                          sgbstdn y,
                          sorlcur so,
                          SZTDTEC,
                          smrarul,
                          smracaa,
                          smralib,
                          stvstst,
                          scrsyln,
                          zstpara,
                          smbagen
                    WHERE     spriden_pidm = pidm
                          AND spriden_change_ind IS NULL
                          AND sorlcur_pidm = spriden_pidm
                          AND SORLCUR_LMOD_CODE = 'LEARNER'
                          AND SORLCUR_SEQNO IN
                                 (SELECT MAX (SORLCUR_SEQNO)
                                    FROM sorlcur ss
                                   WHERE     so.SORLCUR_PIDM = ss.sorlcur_pidm
                                         AND so.sorlcur_lmod_code =
                                                ss.sorlcur_lmod_code
                                         AND ss.sorlcur_program = prog)
                          AND smrpaap_program = prog
                          AND smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                          AND smrpaap_area = SMBAGEN_AREA
                          AND SMBAGEN_ACTIVE_IND = 'Y'
                          AND SMRPAAP_TERM_CODE_EFF = SMBAGEN_TERM_CODE_EFF
                          AND smrpaap_area = smrarul_area
                          AND sgbstdn_pidm = spriden_pidm
                          AND sgbstdn_program_1 = smrpaap_program
                          AND sgbstdn_term_code_eff IN
                                 (SELECT MAX (sgbstdn_term_code_eff)
                                    FROM sgbstdn x
                                   WHERE     x.sgbstdn_pidm = y.sgbstdn_pidm
                                         AND x.sgbstdn_program_1 =
                                                y.sgbstdn_program_1)
                          AND sztdtec_program = sgbstdn_program_1
                          AND sztdtec_status = 'ACTIVO'
                          AND SZTDTEC_CAMP_CODE = SORLCUR_CAMP_CODE --- **** nuevo CAPP ****
                          AND SZTDTEC_TERM_CODE = SORLCUR_TERM_CODE_CTLG
                          AND stvstst_code = sgbstdn_stst_code
                          AND smralib_area = smrpaap_area
                          AND smracaa_area = smrarul_area
                          AND smracaa_rule = smrarul_key_rule
                          AND SMRARUL_TERM_CODE_EFF = SORLCUR_TERM_CODE_CTLG
                          AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW NOT IN
                                 ('L1HB401',
                                  'L1HB402',
                                  'L1HB403',
                                  'L1HB404',
                                  'L1HB405',
                                  'L1HP401',
                                  'UTEL001')
                          AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW NOT IN
                                 (SELECT ZSTPARA_PARAM_VALOR
                                    FROM ZSTPARA
                                   WHERE     ZSTPARA_MAPA_ID =
                                                'NOVER_MAT_DASHB'
                                         AND spriden_pidm IN
                                                (SELECT spriden_pidm
                                                   FROM spriden
                                                  WHERE spriden_id =
                                                           ZSTPARA_PARAM_ID))
                          AND (   (    smrarul_area NOT IN
                                          (SELECT smriecc_area FROM smriecc)
                                   AND smrarul_area NOT IN
                                          (SELECT smriemj_area FROM smriemj))
                               OR (    smrarul_area IN
                                          (SELECT smriemj_area
                                             FROM smriemj
                                            WHERE smriemj_majr_code =
                                                     (SELECT DISTINCT
                                                             SORLFOS_MAJR_CODE
                                                        FROM sorlcur cu,
                                                             sorlfos ss
                                                       WHERE     cu.sorlcur_pidm =
                                                                    Ss.SORLfos_PIDM
                                                             AND cu.SORLCUR_SEQNO =
                                                                    ss.SORLFOS_LCUR_SEQNO
                                                             AND cu.sorlcur_pidm =
                                                                    pidm
                                                             AND SORLCUR_LMOD_CODE =
                                                                    'LEARNER'
                                                             AND SORLFOS_LFST_CODE =
                                                                    'MAJOR'
                                                             AND cu.SORLCUR_SEQNO IN
                                                                    (SELECT MAX (
                                                                               SORLCUR_SEQNO)
                                                                       FROM sorlcur ss
                                                                      WHERE     cu.SORLCUR_PIDM =
                                                                                   ss.sorlcur_pidm
                                                                            AND cu.sorlcur_lmod_code =
                                                                                   ss.sorlcur_lmod_code
                                                                            AND ss.sorlcur_program =
                                                                                   prog)
                                                             AND cu.SORLCUR_TERM_CODE IN
                                                                    (SELECT MAX (
                                                                               SORLCUR_TERM_CODE)
                                                                       FROM sorlcur ss
                                                                      WHERE     cu.SORLCUR_PIDM =
                                                                                   ss.sorlcur_pidm
                                                                            AND cu.sorlcur_lmod_code =
                                                                                   ss.sorlcur_lmod_code
                                                                            AND ss.sorlcur_program =
                                                                                   prog)
                                                             AND SORLCUR_CACT_CODE =
                                                                    SORLFOS_CACT_CODE
                                                             AND sorlcur_program =
                                                                    prog))
                                   AND smrarul_area NOT IN
                                          (SELECT smriecc_area FROM smriecc))
                               OR (smrarul_area IN
                                      (SELECT smriecc_area
                                         FROM smriecc
                                        WHERE smriecc_majr_code_conc IN
                                                 (SELECT DISTINCT
                                                         SORLFOS_MAJR_CODE
                                                    FROM sorlcur cu, sorlfos ss
                                                   WHERE     cu.sorlcur_pidm =
                                                                Ss.SORLfos_PIDM
                                                         AND cu.SORLCUR_SEQNO =
                                                                ss.SORLFOS_LCUR_SEQNO
                                                         AND cu.SORLCUR_SEQNO IN
                                                                (SELECT MAX (
                                                                           SORLCUR_SEQNO)
                                                                   FROM sorlcur ss
                                                                  WHERE     cu.SORLCUR_PIDM =
                                                                               ss.sorlcur_pidm
                                                                        AND cu.sorlcur_lmod_code =
                                                                               ss.sorlcur_lmod_code
                                                                        AND ss.sorlcur_program =
                                                                               prog)
                                                         AND cu.sorlcur_pidm =
                                                                pidm
                                                         AND SORLCUR_LMOD_CODE =
                                                                'LEARNER'
                                                         AND SORLFOS_LFST_CODE =
                                                                'CONCENTRATION'
                                                         AND SORLCUR_CACT_CODE =
                                                                SORLFOS_CACT_CODE
                                                         AND sorlcur_program =
                                                                prog))))
                          AND scrsyln_subj_code = smrarul_subj_code
                          AND scrsyln_crse_numb = smrarul_crse_numb_low
                          AND (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) NOT IN
                                 (SELECT SHRTCKN_SUBJ_CODE, SHRTCKN_CRSE_NUMB
                                    FROM shrtckn
                                   WHERE shrtckn_pidm = pidm)
                          AND (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) NOT IN
                                 (SELECT SHRTRCE_SUBJ_CODE, SHRTRCE_CRSE_NUMB
                                    FROM SHRTRCE
                                   WHERE SHRTRCE_pidm = pidm)       --agregado
                          AND (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) NOT IN
                                 (SELECT SHRTRTK_SUBJ_CODE_INST,
                                         SHRTRTK_CRSE_NUMB_INST
                                    FROM SHRTRTK
                                   WHERE SHRTRTK_pidm = pidm)       --agregado
                          AND (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) NOT IN
                                 (SELECT ssbsect_subj_code subj,
                                         ssbsect_crse_numb code
                                    FROM sfrstcr,
                                         smrprle,
                                         ssbsect,
                                         spriden --agregado para materias EC y aprobadas sin rolar
                                   WHERE     smrprle_program = prog
                                         AND sfrstcr_pidm = pidm
                                         AND (   sfrstcr_grde_code IS NULL
                                              OR sfrstcr_grde_code IS NOT NULL)
                                         AND sfrstcr_rsts_code = 'RE'
                                         AND spriden_pidm = sfrstcr_pidm
                                         AND spriden_change_ind IS NULL
                                         AND ssbsect_term_code =
                                                sfrstcr_term_code
                                         AND ssbsect_crn = sfrstcr_crn)
                          AND zstpara_mapa_id(+) = 'MAESTRIAS_BIM'
                          AND zstpara_param_id(+) = sgbstdn_program_1
                          AND zstpara_param_desc(+) = SORLCUR_TERM_CODE_CTLG) datos1
            WHERE 1 = 1
         ORDER BY 1;

    exception when others then
     null;
    end;  
    
    
    
    

      ------- aqui arma el curso de salida
    open avcu_out
      FOR
        select distinct avance1.materia as materia, 
          avance1.nombre_mat as nombre_mat,
          avance1.calif as calif,
          avance1.per as per, 
          avance1.area as area,
          case when substr(spriden_id,1,2)='08' then ' '
          else
              case when substr(avance1.materia,1,4)='L1HB' then 'MATERIAS INTRODUCTORIAS'
                    when substr(avance1.materia,1,4)='M1HB' then 'MATERIAS INTRODUCTORIAS'
              else upper(avance1.nombre_area)
              end
          end as nombre_area,
          avance1.ord as ord,
          CASE WHEN avance1.apr = 'AP' THEN 
          NULL 
          ELSE apr 
          END as tipo,
         ----------------------------------------
         case when
              round (( select count(unique materia) 
                    from avance_n x
                 where  apr in ('AP','EQ')
                 and    protocolo = 8889
                 and    pidm_alu = Ppidm
                 and    usuario_siu = Pusu_siu
                 and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                 and    calif not in ('NP','AC')
                 and    ( to_number(calif)  in (select max(to_number(calif)) 
                                                 from avance_n xx
                                                    where x.materia=xx.materia
                                                    and   x.protocolo=xx.protocolo
                                                    and   x.pidm_alu=xx.pidm_alu
                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) 
                     or calif is null)
                 and  ( ( area not in (select smriecc_area from smriecc) 
                 and  area not in (select smriemj_area from smriemj))
                   or   -- VALIDA LA EXITENCIA EN SMAALIB
                      ( area in (select smriemj_area 
                                  from smriemj
                                     where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                        and   cu.sorlcur_pidm = Ppidm
                                                                        and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                        and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                       -- and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                        and   cu.SORLCUR_SEQNO in ( select max(SORLCUR_SEQNO) 
                                                                                                      from sorlcur ss
                                                                                                        where cu.SORLCUR_PIDM = ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code = ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog)
                                                                       and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program =Pprog)
                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                        and   sorlcur_program   =Pprog
                                                                                           )    )
                     and area not in (select smriecc_area from smriecc)) 
                     or     -- VALIDA LA EXITENCIA EN SMAALIB
                         ( area in (select smriecc_area 
                                      from smriecc 
                                        where smriecc_majr_code_conc in  ( select distinct SORLFOS_MAJR_CODE
                                                                             from  sorlcur cu, sorlfos ss
                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                             where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                               and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                               and ss.sorlcur_program =Pprog )
                                                                                and   cu.sorlcur_pidm=Ppidm
                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                and   sorlcur_program   = Pprog ) 
                                      ) ) )
                      ) *100 /
                      ( select  distinct SMBPGEN_REQ_COURSES_I_TRAD  
                          from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                            where SMBPGEN_program=Pprog
                                and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG 
                                                                from sorlcur
                                                                   where  sorlcur_pidm = Ppidm
                                                                      and sorlcur_program = Pprog 
                                                                      and sorlcur_lmod_code='LEARNER'
                                                                      and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) 
                                                                                             from sorlcur ss
                                                                                               where ss.sorlcur_pidm = Ppidm
                                                                                                 and ss.sorlcur_program = Pprog 
                                                                                                 and ss.sorlcur_lmod_code='LEARNER')))
                  )>100  then 100
             else
                round ( ( select count(unique materia) 
                          from avance_n x
                            where  apr in ('AP','EQ')
                             and    protocolo=8889
                             and    pidm_alu = Ppidm
                             and    usuario_siu = Pusu_siu
                             and    area not in ( select ZSTPARA_PARAM_VALOR 
                                                   from ZSTPARA 
                                                    where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' 
                                                     and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                             and    calif not in ('NP','AC')
                             and    (to_number(calif)  in (select max(to_number(calif)) 
                                                           from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu and CALIF!=0) 
                              Or calif is null)
                         and (  (area not in (select smriecc_area from smriecc) 
                          and area not in (select smriemj_area from smriemj)) 
                         or   -- VALIDA LA EXITENCIA EN SMAALIB
                            ( area in (select smriemj_area 
                                       from smriemj
                                        where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                        and   cu.sorlcur_pidm = Ppidm
                                                                        and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                        and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                       -- and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                        and   cu.SORLCUR_SEQNO in ( select max(SORLCUR_SEQNO) 
                                                                                                     from sorlcur ss
                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog )
                                                                        and   cu.SORLCUR_TERM_CODE in ( select max(SORLCUR_TERM_CODE) 
                                                                                                       from sorlcur ss
                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog )
                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                        and   sorlcur_program   = Pprog )    )
                          and area not in (select smriecc_area from smriecc)) 
                            or -- VALIDA LA EXITENCIA EN SMAALIB
                               ( area in (select smriecc_area 
                                           from smriecc 
                                            where smriecc_majr_code_conc in ( select distinct SORLFOS_MAJR_CODE
                                                                               from  sorlcur cu, sorlfos ss
                                                                               where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                             where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                               and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                               and ss.sorlcur_program = Pprog )
                                                                                and  cu.sorlcur_pidm = Ppidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and   SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   = Pprog
                                                                                                 ) ) ) )
                          ) *100 /
                (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  
                  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                    where SMBPGEN_program=Pprog
                     and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG 
                                                   from sorlcur
                                                        where  sorlcur_pidm = Ppidm
                                                           and sorlcur_program = Pprog 
                                                           and sorlcur_lmod_code='LEARNER'
                                                           and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) 
                                                                                from sorlcur ss
                                                                                     where ss.sorlcur_pidm = Ppidm
                                                                                     and ss.sorlcur_program = Pprog 
                                                                                     and ss.sorlcur_lmod_code='LEARNER'))))
           end as avance_curr,
          (SELECT DISTINCT SCBCRSE_CREDIT_HR_LOW
                FROM scbcrse bs
                WHERE (SCBCRSE_SUBJ_CODE || SCBCRSE_CRSE_NUMB) = avance1.materia  ) as creditos
   FROM  spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
       ( SELECT 8889, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
           FROM  ( select 8889, per, area, nombre_area, materia, nombre_mat,
                   case when calif='1' then cal_origen
                            when apr='EC' then null
                    else calif
                    end as calif, 
                    apr, 
                    regla, 
                    null as n_area,
                   case when substr(materia,1,2)='L3' then 5
                    else 1
                   end as ord,
                   fecha
                   from  sgbstdn y, avance_n x
                      where  x.protocolo=8889
                        and    sgbstdn_pidm = Ppidm
                        and    sgbstdn_program_1 = Pprog
                        and    x.pidm_alu = Ppidm
                        and    x.usuario_siu = Pusu_siu
                        and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) 
                                                          from sgbstdn x
                                                          where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                            and x.sgbstdn_program_1=y.sgbstdn_program_1)
                        and   area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                        and  ( to_number(calif) in ( select max(to_number(calif)) 
                                                     from avance_n xx
                                                      where x.materia=xx.materia
                                                      and  x.protocolo=xx.protocolo   ----cambio
                                                      and  x.pidm_alu=sgbstdn_pidm  ----cambio
                                                      and  x.pidm_alu=xx.pidm_alu   ---- cambio
                                                      and  x.usuario_siu=xx.usuario_siu) or calif is null)
                      union
                          select distinct 8889, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                            case when calif='1' then cal_origen
                                 when apr='EC' then null
                            else calif
                            end as calif, 
                            apr, 
                            regla, 
                            null n_area,
                            case when substr(materia,1,2)='L3' then 5
                            else 1
                            end as ord, 
                            fecha
                            from  sgbstdn y, avance_n x
                           where   x.protocolo=8889
                            and     sgbstdn_pidm = Ppidm
                            and    x.pidm_alu=sgbstdn_pidm
                            and     x.usuario_siu = Pusu_siu
                            and     apr='EC'
                            and     sgbstdn_program_1 = Pprog
                            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) 
                                                              from sgbstdn x
                                                               where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                 and x.sgbstdn_program_1=y.sgbstdn_program_1)
                           and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                  union
                          select protocolo, per, area, nombre_area, materia, nombre_mat,
                                case when calif='1' then cal_origen
                                     when apr='EC' then null
                                else calif
                                end as calif, 
                                apr, 
                                regla, 
                                stvmajr_desc n_area, 
                                2 ord, 
                                fecha
                             from  sgbstdn y, avance_n x, smriemj, stvmajr
                               where   x.protocolo=8889
                                and     sgbstdn_pidm = Ppidm
                                and     x.pidm_alu=sgbstdn_pidm
                                and     x.usuario_siu = Pusu_siu
                                and     sgbstdn_program_1 = Pprog
                                and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) 
                                                                    from sgbstdn x
                                                                   where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                     and x.sgbstdn_program_1=y.sgbstdn_program_1)
                               and    area=smriemj_area
                                -- and smriemj_majr_code=sgbstdn_majr_code_1   --vic
                                and smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                from  sorlcur cu, sorlfos ss
                                                                where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                and   cu.sorlcur_pidm = Ppidm
                                                                and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                --and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                                                                           from sorlcur ss
                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                              and ss.sorlcur_program = Pprog)
                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) 
                                                                                                from sorlcur ss
                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                  and ss.sorlcur_program = Pprog)
                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                and   sorlcur_program   = Pprog
              )
               and    area not in (select smriecc_area from smriecc)
               and    smriemj_majr_code=stvmajr_code
               and    (to_number(calif) in ( select max(to_number(calif)) 
                                             from avance_n xx
                                              where x.materia=xx.materia
                                              and   x.protocolo=xx.protocolo
                                              and   x.pidm_alu=xx.pidm_alu
                                              and   x.usuario_siu=xx.usuario_siu) or calif is null)
            union
                select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                    case when calif='1' then cal_origen
                         when apr='EC' then null
                     else calif
                    end  as calif, 
                    apr, 
                    regla, 
                    smralib_area_desc n_area, 
                    3 ord, 
                    fecha
                    from sgbstdn y, avance_n x ,smralib, smriecc a
                      where  x.protocolo=8889
                        and   sgbstdn_pidm = Ppidm
                        and   x.pidm_alu=sgbstdn_pidm
                        and   x.usuario_siu = Pusu_siu
                        and   sgbstdn_program_1 = Pprog
                        and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) 
                                                         from sgbstdn x
                                                         where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                           and x.sgbstdn_program_1=y.sgbstdn_program_1)
                       and    area=smralib_area
                       and    area=smriecc_area
                       --    and    smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)---modifico vic   18.04.2018
                       and   smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                         from  sorlcur cu, sorlfos ss
                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                            --  and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                            --  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                            --  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                            --  and ss.sorlcur_program =Pprog )
                                                            and   cu.sorlcur_pidm = Ppidm
                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                            and  SORLCUR_CACT_CODE =SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                            and   sorlcur_program   = Pprog
                                                             )
                       and  ( to_number(calif) in (select max(to_number(calif)) from avance_n xx
                              where x.materia=xx.materia
                              and   x.protocolo=xx.protocolo
                              and   x.pidm_alu=xx.pidm_alu
                              and   x.usuario_siu=xx.usuario_siu) or calif is null)
                               and    (fecha in (select distinct fecha from avance_n xx
                              where x.materia=xx.materia
                              and   x.protocolo=xx.protocolo
                              and   x.pidm_alu=xx.pidm_alu
                              and   x.usuario_siu=xx.usuario_siu) or fecha is null)
                             order by  n_area desc, per, nombre_area,regla
                           )
        GROUP BY 8889, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
        )  avance1
   where 1=1 
       and spriden_pidm = Ppidm
        and   sorlcur_pidm= spriden_pidm
        and   SORLCUR_LMOD_CODE = 'LEARNER'
        and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                  from sorlcur ss 
                                   where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                   and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                   and ss.sorlcur_program = Pprog)
        and     spriden_change_ind is null
        and     sgbstdn_pidm=spriden_pidm
        and     sgbstdn_program_1 = Pprog
        and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                           where a.sgbstdn_pidm=b.sgbstdn_pidm
                                             and a.sgbstdn_program_1=b.sgbstdn_program_1)
        and     sztdtec_program=sgbstdn_program_1
        and     sztdtec_status='ACTIVO'
        and     SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE
        and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
        and     sgbstdn_stst_code=stvstst_code
         order by  avance1.per;

      COMMIT;
      RETURN (avcu_out);
    exception when others then
    null;
      
   END F_AVCU_INGL;

 FUNCTION F_VIGENCIA_CRED  (VFECHA_INI  DATE )
      RETURN VARCHAR2
   IS
    vfech_vigencia varchar2(16);


 begin
       -- LA FORMULA  ala fecha de inicio se le suman 36 meses = 3 años.
     vfech_vigencia :=  TO_CHAR (ADD_MONTHS(VFECHA_INI, 36), 'DD/MM/YYYY');


   RETURN (vfech_vigencia);

 end F_VIGENCIA_CRED  ;


procedure p_diploma_pago is
/*
este proceso es de Victor Ramirez lo hizo para la segunda parte del proceso que es la generación de Diploma y las recurrecias
30/08/2023.
*/


vl_exito varchar2(500):= null;
vl_descripcion varchar2(500):= null;


Begin

        For cx in (

                    select distinct SZTQRDI_PIDM, SZTQRDI_PROGRAMA, SZTQRDI_FOLIO_DOCTO, SZTQRDI_SEQ_FOLIO, SZTQRDI_SEQNO_SIU,
                    (select sum (TBRAPPL_AMOUNT) monto
                            from tbrappl
                            where 1= 1
                            And tbrappl_pidm = SZTQRDI_PIDM
                            and TBRAPPL_CHG_TRAN_NUMBER = SZTQRDI_TRANS_CARGO
                            and (tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER ) in (select tbraccd_pidm, TBRACCD_TRAN_NUMBER
                                                                             from tbraccd, TZTNCD
                                                                             where tbraccd_detail_code = TZTNCD_CODE
                                                                             And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion', 'Financieras'))
                            and TBRAPPL_REAPPL_IND is null
                    ) Pago,
                    (select tbraccd_amount
                        from tbraccd
                        where tbraccd_pidm = SZTQRDI_PIDM
                        And TBRACCD_TRAN_NUMBER  = SZTQRDI_TRANS_CARGO
                        ) Monto
                    from SZTQRDI
                    where 1=1
                    and SZTQRDI_TRANS_CARGO is not null
                    and SZTQRDI_DATE_CARGO is not null
                    And SZTQRDI_ENVIADO_QR is null
                    And SZTQRDI_DATE_ENVIADO_QR is null


        ) loop


            If cx.pago = cx.monto then

           -- DBMS_OUTPUT.PUT_LINE('Entra cuado esta pagado');

                   For cx2 in (

                                Select *
                                from SZTQRDI
                                Where 1=1
                                and SZTQRDI_PIDM = cx.SZTQRDI_PIDM
                                And SZTQRDI_PROGRAMA = cx.SZTQRDI_PROGRAMA
                                And SZTQRDI_FOLIO_DOCTO = cx.SZTQRDI_FOLIO_DOCTO
                                And SZTQRDI_SEQ_FOLIO = cx.SZTQRDI_SEQ_FOLIO

                    ) loop

                        -- DBMS_OUTPUT.PUT_LINE('Recupera Pidm '||cx2.SZTQRDI_PIDM);
                        vl_exito:= null;
                        Begin
                              Insert into SZTQRDG(SZT_PIDM
                                                  ,SZT_PROGRAMA
                                                  ,SZT_AVANCE
                                                  ,SZT_PROMEDIO
                                                  ,SZT_FOLIO_DOCTO
                                                  ,SZT_SEQNO_SIU
                                                  ,SZT_CODE_ACCESORIO
                                                  ,SZT_ENVIO_ALUMNO
                                                  ,SZT_FECHA_ENVIO
                                                  ,SZT_ACTIVITY_DATE
                                                  ,SZT_NO_MATERIAS_ACRED
                                                  ,SZT_NO_MATERIAS_TOTAL
                                                  ,SZT_CODE_QR
                                                  ,SZT_USER
                                                  ,SZT_DATA_ORIGIN
                                                  ,SZT_SEQ_FOLIO
                                                  ,SZT_CICLO_CURSA
                                                  ,SZT_FECHAS_CICLO_INI
                                                  ,SZT_FECHAS_CICLO_FIN
                                                  ,SZT_TALLERES
                                                  ,SZT_PERIODO_ACT
                                                  ,SZT_PROM_ANTERIOR
                                                  ,SZT_COMENTARIOS)
                                            values ( cx2.SZTQRDI_PIDM,
                                                   cx2.SZTQRDI_PROGRAMA,
                                                   cx2.SZTQRDI_AVANCE,
                                                   cx2.SZTQRDI_PROMEDIO,
                                                   cx2.SZTQRDI_FOLIO_DOCTO,
                                                   nvl (cx2.SZTQRDI_SEQNO_SIU,999999999),
                                                   cx2.SZTQRDI_CODE_ACCESORIO,
                                                   cx2.SZTQRDI_ENVIO_ALUMNO,
                                                   cx2.SZTQRDI_FECHA_ENVIO,
                                                   cx2.SZTQRDI_ACTIVITY_DATE,
                                                   cx2.SZTQRDI_NO_MATERIAS_ACRED,
                                                   cx2.SZTQRDI_NO_MATERIAS_TOTAL,
                                                   null,
                                                   cx2.SZTQRDI_USER,
                                                   'QR_MASIVO',
                                                   cx2.SZTQRDI_SEQ_FOLIO,
                                                   cx2.SZTQRDI_CICLO_CURSA,
                                                   cx2.SZTQRDI_FECHAS_CICLO_INI,
                                                   cx2.SZTQRDI_FECHAS_CICLO_FIN,
                                                   cx2.SZTQRDI_TALLERES,
                                                   cx2.SZTQRDI_PERIODO_ACT,
                                                   cx2.SZTQRDI_PROM_ANTERIOR,
                                                   cx2.SZTQRDI_COMENTARIOS);
                                    vl_exito:='EXITO';

                        Exception
                            When Others then
                                vl_exito:= 'Error al insertar SZTQRDG '||sqlerrm;
                                 --DBMS_OUTPUT.PUT_LINE(vl_exito);
                        End;

                        If vl_exito ='EXITO' then

                             Begin
                                    Update SZTQRDI
                                      set SZTQRDI_ENVIADO_QR ='Y',
                                          SZTQRDI_DATE_ENVIADO_QR = sysdate
                                    Where 1=1
                                    and SZTQRDI_PIDM = cx2.SZTQRDI_PIDM
                                    And SZTQRDI_PROGRAMA = cx2.SZTQRDI_PROGRAMA
                                    And SZTQRDI_FOLIO_DOCTO = cx2.SZTQRDI_FOLIO_DOCTO
                                    And SZTQRDI_SEQ_FOLIO = cx2.SZTQRDI_SEQ_FOLIO;
                                    vl_exito:='EXITO';
                             Exception
                                When Others then
                                 vl_exito:= 'Error al insertar SZTQRDI '||sqlerrm;
                               --  DBMS_OUTPUT.PUT_LINE(vl_exito);
                             End;

                              If vl_exito ='EXITO' then

                                    Begin
                                         Select distinct GTVADID_DESC
                                            Into vl_descripcion
                                         from  gtvadid
                                         where GTVADID_CODE = cx2.SZTQRDI_ETIQUETA;
                                     Exception
                                        When Others then
                                            vl_descripcion:= null;
                                    End;

                                    vl_exito:= null;
                                    Begin
                                        vl_exito:=pkg_utilerias.F_Genera_Etiqueta (cx2.SZTQRDI_PIDM, cx2.SZTQRDI_ETIQUETA, vl_descripcion, user);
                                    Exception
                                        When OThers then
                                         null;

                                    End;

                              End if;


                        End if;

                    End Loop;

            End if;

        End loop;

        Commit;

End p_diploma_pago;

 
FUNCTION F_HIAC_OUT (ppidm in number, pprog varchar2) RETURN PKG_QR_DIG.hiac_out
           AS
 histac_out PKG_QR_DIG.hiac_out;
 vnivel   varchar2(2);

 BEGIN
  begin
  select smrprle_levl_code
  into vnivel
  from smrprle
  where smrprle_program = pprog;
  exception when others then
    vnivel := null;
  end;


    if vnivel = 'LI' then ---- aqui es licenciatura recupera datos de alumnos LI*****
    open histac_out
    FOR
    select distinct
          spriden_first_name||' '||replace(spriden_last_name,'/',' ') "Estudiante", --col1
          spriden_id "Matricula",   --col2
          sztdtec_programa_comp "Programa",   --col3
           to_number(substr(smrarul_area,9,2)) "per",  --col4
          case when  shrtckn_subj_code is null or substr(stvterm_code,1,2)='08' then ' '
          else case when substr(smrarul_area,9,2) in ('01','03') then substr(smrarul_area,10,1)||'er. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('02') then substr(smrarul_area,10,1)||'do. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('04','05','06') then substr(smrarul_area,10,1)||'to.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('07') then substr(smrarul_area,10,1)||'mo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('08') then substr(smrarul_area,10,1)||'vo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('09') then substr(smrarul_area,10,1)||'no.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('10') then substr(smrarul_area,9,2)||'mo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          else smralib_area_desc
          end
          end   "nombre_area", ----col5
          smrarul_subj_code||smrarul_crse_numb_low "materia",  --col6
          scrsyln_long_course_title "nombre_mat",  ---col7
          case when substr(stvterm_code,1,2)='08' then substr(stvterm_desc,7,4)
          else substr(stvterm_desc,1,6)
          end  "periodo",  ---col8
          shrtckg_grde_code_final "calif",  --col9
          shrgrde_abbrev "letra",   ----col10
          0 "Avance",    -----col11
          0 "Promedio",   ---col12
          shrgrde_passed_ind "aprobatoria", ---col13
          scbcrse_credit_hr_low "creditos", ---col14
          case when substr(shrtckn_term_code,5,1)='8' then 'EXT'
             else 'ORD'
          end   "evaluacion",  ---col15
         -- s.SORLCUR_APPL_KEY_SEQNO,
          (select  distinct  REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy')), ' ', '') ||' - '||
                 REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy')), ' ', '')
                from sfrstcr f, ssbsect bb
                where 1=1
                and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                and SFRSTCR_PIDM = Ppidm
                and f.SFRSTCR_GRDE_CODE is not null
                and f.SFRSTCR_RSTS_CODE = 'RE'
                and f.SFRSTCR_STSP_KEY_SEQUENCE  = s.SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_RSTS_CODE = 'RE'
                                and f2.SFRSTCR_STSP_KEY_SEQUENCE  = s.SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16
        from spriden
        join sgbstdn a on sgbstdn_pidm=spriden_pidm
           and  sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff)
                                               from sgbstdn b
                                                  where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                    and b.SGBSTDN_PROGRAM_1= Pprog)
        join sorlcur s on sorlcur_pidm=spriden_pidm
          and sorlcur_program= Pprog
          and sorlcur_lmod_code='LEARNER'
          and SORLCUR_CACT_CODE!='CHANGE'
          and sorlcur_seqno in (select max(sorlcur_seqno)
                                 from sorlcur ss
                                     where s.sorlcur_pidm=ss.sorlcur_pidm
                                     and s.sorlcur_program=ss.sorlcur_program
                                     and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
        join smrprle on sorlcur_program=smrprle_program
        join sztdtec on sorlcur_program=sztdtec_program
             and  SORLCUR_CAMP_CODE=sztdtec_camp_code
             and sztdtec_status='ACTIVO'
             and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
        join smrpaap s on smrpaap_program=sorlcur_program
              AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
        join smrarul on smrpaap_area=smrarul_area
             and smrarul_area not in (select ZSTPARA_PARAM_VALOR
                                       from ZSTPARA
                                       where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
        and SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR
                                                                from ZSTPARA
                                                                  where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                   and spriden_pidm in ( select spriden_pidm
                                                                                           from spriden
                                                                                             where spriden_id=ZSTPARA_PARAM_ID))
          and ( (smrarul_area not in (select smriecc_area
                                         from smriecc)
          and smrarul_area not in (select smriemj_area from smriemj))
          or (smrarul_area in (select smriemj_area from smriemj
                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                 from  sorlcur cu, sorlfos ss
                                                                  where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                    and   cu.sorlcur_pidm = Ppidm
                                                                    and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                    and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                    and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                    and   cu.SORLCUR_CACT_CODE  = ss.SORLFOS_CACT_CODE
                                                                    and   cu.sorlcur_program   = Pprog
                                                               )    )
          and smrarul_area not in (select smriecc_area from smriecc))
          or (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                 from  sorlcur cu, sorlfos ss
                                                                where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                  and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                  and   cu.sorlcur_pidm  = Ppidm
                                                                  and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                  and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                  and  SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                                  and   sorlcur_program   = Pprog
                                                               ) )))
        join smbpgen on sorlcur_program=smbpgen_program and smbpgen_term_code_eff=smrpaap_term_code_eff
        join smbagen on smbagen_area=smrpaap_area and  smbagen_active_ind='Y' and  smbagen_term_code_eff=smrpaap_term_code_eff
        join smralib on smrpaap_area=smralib_area  and SMRALIB_LEVL_CODE=SORLCUR_LEVL_CODE
        join smracaa on  smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
        join shrtckn w on shrtckn_pidm=spriden_pidm and    shrtckn_subj_code=smrarul_subj_code and    shrtckn_crse_numb=smrarul_crse_numb_low and shrtckn_stsp_key_sequence=sorlcur_key_seqno
        join shrtckg z on shrtckg_pidm=shrtckn_pidm and  shrtckg_term_code=shrtckn_term_code and    shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
        and  decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))
                       in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final)))
                             from shrtckn ww, shrtckg zz
                               where w.shrtckn_pidm=ww.shrtckn_pidm
                               and   w.shrtckn_subj_code=ww.shrtckn_subj_code
                               and  w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                               and  ww.shrtckn_pidm=zz.shrtckg_pidm
                               and  ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no
                               and ww.shrtckn_term_code=zz.shrtckg_term_code)
        join scrsyln on scrsyln_subj_code=shrtckn_subj_code and    scrsyln_crse_numb=shrtckn_crse_numb
        join shrgrde on shrgrde_code=shrtckg_grde_code_final and    shrgrde_levl_code=sgbstdn_levl_code
        /* cambio escalas para prod */
        and shrgrde_term_code_effective = (select zstpara_param_desc
                                            from zstpara
                                            where zstpara_mapa_id='ESC_SHAGRD'
                                            and substr((select f_getspridenid(Ppidm)
                                                             from dual),1,2)=zstpara_param_id
                                            and zstpara_param_valor=sgbstdn_levl_code)
        join stvterm on stvterm_code=shrtckn_term_code
        join scbcrse on scbcrse_subj_code=shrtckn_subj_code and scbcrse_crse_numb=shrtckn_crse_numb
        left outer join zstpara on zstpara_mapa_id='MAESTRIAS_BIM' and zstpara_param_id=sorlcur_program and zstpara_param_desc=SORLCUR_TERM_CODE_CTLG
        where 1=1
        and spriden_pidm = Ppidm
        and spriden_change_ind is null
        and shrtckg_grde_code_final not in ('NP','NA','5.0')
    union
        select distinct
          spriden_first_name||' '||replace(spriden_last_name,'/',' ') "Estudiante",
          spriden_id "Matricula",
          sztdtec_programa_comp "Programa",
          to_number(substr(smrarul_area,9,2)) "per",
          case when  shrtrce_subj_code is null or substr(spriden_id,1,2)='08' then ' '
          else case when substr(smrarul_area,9,2) in ('01','03') then substr(smrarul_area,10,1)||'er.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('02') then substr(smrarul_area,10,1)||'do.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('04','05','06') then substr(smrarul_area,10,1)||'to.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('07') then substr(smrarul_area,10,1)||'mo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('08') then substr(smrarul_area,10,1)||'vo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('09') then substr(smrarul_area,10,1)||'no.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('10') then substr(smrarul_area,9,2)||'mo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          else smralib_area_desc
          end
          end   "nombre_area",
          smrarul_subj_code||smrarul_crse_numb_low "materia",
          scrsyln_long_course_title "nombre_mat",
          ' ' "periodo",
          shrtrce_grde_code "calif",
          shrgrde_abbrev "letra",
          0 "Avance",
          0 "Promedio",
          shrgrde_passed_ind "aprobatoria",
          scbcrse_credit_hr_low "creditos",
          'EQ' "evaluacion",
         --   SORLCUR_APPL_KEY_SEQNO,
           (select  distinct  REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy')), ' ', '') ||' - '||
                 REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy')), ' ', '')
                from sfrstcr f, ssbsect bb
                where 1=1
                and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                and SFRSTCR_PIDM = Ppidm
                and f.SFRSTCR_GRDE_CODE is not null
                and f.SFRSTCR_RSTS_CODE = 'RE'
                and f.SFRSTCR_STSP_KEY_SEQUENCE  = SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                 and f2.SFRSTCR_RSTS_CODE = 'RE'
                                 and f2.SFRSTCR_STSP_KEY_SEQUENCE  = SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16 --- col16
        from spriden
        join sgbstdn a on sgbstdn_pidm=spriden_pidm
             and sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff)
                                                from sgbstdn b
                                                  where a.sgbstdn_pidm = b.sgbstdn_pidm
                                                    and b.SGBSTDN_PROGRAM_1 = Pprog)
        join sorlcur on sorlcur_pidm=spriden_pidm
             and sorlcur_program = Pprog
             and sorlcur_lmod_code='LEARNER'
             and SORLCUR_CACT_CODE!='CHANGE'
        join smrprle on sorlcur_program=smrprle_program
        join sztdtec on sorlcur_program=sztdtec_program
             and SORLCUR_CAMP_CODE=sztdtec_camp_code
             and sztdtec_status='ACTIVO'
             and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
        join smrpaap s on smrpaap_program=sorlcur_program  AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
        join smrarul on smrpaap_area=smrarul_area
             and smrarul_area not in (select ZSTPARA_PARAM_VALOR
                                        from ZSTPARA
                                         where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES'
                                          and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
          and SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR
                                                                 from ZSTPARA
                                                                   where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                    and spriden_pidm in (select spriden_pidm
                                                                                            from spriden
                                                                                              where spriden_id=ZSTPARA_PARAM_ID))
         and ( (smrarul_area not in (select smriecc_area from smriecc)
               and smrarul_area not in (select smriemj_area from smriemj))
         or (smrarul_area in (select smriemj_area
                                from smriemj
                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                 from  sorlcur cu, sorlfos ss
                                                                  where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                    and   cu.sorlcur_pidm = Ppidm
                                                                    and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                    and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                    and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                    and   cu.SORLCUR_CACT_CODE= ss.SORLFOS_CACT_CODE
                                                                    and   cu.sorlcur_program   = Pprog
                                                               )    )
         and smrarul_area not in (select smriecc_area from smriecc))
         or (smrarul_area in (select smriecc_area
                                 from smriecc
                                   where smriecc_majr_code_conc in (select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                      where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                        and   cu.sorlcur_pidm = Ppidm
                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                        and  SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                                        and   sorlcur_program   = Pprog
                                                                         ) )) )
        join smbpgen on sorlcur_program=smbpgen_program and smbpgen_term_code_eff=smrpaap_term_code_eff
        join smbagen on smbagen_area=smrpaap_area and  smbagen_active_ind='Y' and  smbagen_term_code_eff=smrpaap_term_code_eff
        join smralib on smrpaap_area=smralib_area   and SMRALIB_LEVL_CODE=SORLCUR_LEVL_CODE
        join smracaa on  smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
        join shrtrcr on shrtrcr_pidm=spriden_pidm and  shrtrcr_program=Pprog
        join shrtrce on shrtrce_pidm=spriden_pidm and  shrtrce_subj_code=smrarul_subj_code
             and shrtrce_crse_numb=smrarul_crse_numb_low and shrtrce_trit_seq_no=shrtrcr_trit_seq_no
             and    shrtrce_tram_seq_no=shrtrcr_tram_seq_no
        join scrsyln on scrsyln_subj_code=shrtrce_subj_code and    scrsyln_crse_numb=shrtrce_crse_numb
        join shrgrde on shrgrde_code=shrtrce_grde_code and    shrgrde_levl_code=SORLCUR_LEVL_CODE
         /* cambio escalas para prod */
        and SHRGRDE_TERM_CODE_EFFECTIVE = (select zstpara_param_desc
                                             from zstpara
                                               where zstpara_mapa_id='ESC_SHAGRD'
                                                 and substr((select f_getspridenid(Ppidm) from dual),1,2) = zstpara_param_id
                                                 and zstpara_param_valor=sgbstdn_levl_code)
        join scbcrse on scbcrse_subj_code=shrtrce_subj_code and scbcrse_crse_numb=shrtrce_crse_numb
        left outer join zstpara on zstpara_mapa_id='MAESTRIAS_BIM'
             and zstpara_param_id=sorlcur_program
             and zstpara_param_desc=SORLCUR_TERM_CODE_CTLG
        where 1=1
        and spriden_pidm = Ppidm
        and spriden_change_ind is null
        and shrtrce_grde_code not in ('NP','NA','5.0')
    union
        select distinct
          spriden_first_name||' '||replace(spriden_last_name,'/',' ') "Estudiante",
          spriden_id "Matricula",
          sztdtec_programa_comp "Programa",
          20 "per",
          'TALLERES' "nombre_area",
          smrarul_subj_code||smrarul_crse_numb_low "materia",
          scrsyln_long_course_title "nombre_mat",
          case when substr(stvterm_code,1,2)='08' then substr(stvterm_desc,7,4)
          else substr(stvterm_desc,1,6)
          end  "periodo",
          shrtckg_grde_code_final "calif",
          shrgrde_abbrev "letra",
          0 "Avance",
          0 "Promedio",
          shrgrde_passed_ind "aprobatoria",
          scbcrse_credit_hr_low "creditos",
            case when substr(shrtckn_term_code,5,1)='8' then 'EXT'
             else 'ORD'
          end   "evaluacion",
        --    SORLCUR_APPL_KEY_SEQNO,
          (select  distinct  REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy')), ' ', '') ||' - '||
                 REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy')), ' ', '')
                from sfrstcr f, ssbsect bb
                where 1=1
                and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                and f.SFRSTCR_PIDM = Ppidm
                and f.SFRSTCR_RSTS_CODE = 'RE'
                and f.SFRSTCR_STSP_KEY_SEQUENCE  = SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                and f.SFRSTCR_GRDE_CODE is not null
                and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_RSTS_CODE = 'RE'
                                and f2.SFRSTCR_STSP_KEY_SEQUENCE  = SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16--- col16
        from spriden
        join sgbstdn a on sgbstdn_pidm=spriden_pidm
             and sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff)
                                            from sgbstdn b
                                               where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                 and b.SGBSTDN_PROGRAM_1 = Pprog)
        join sorlcur on sorlcur_pidm=sgbstdn_pidm
                and sorlcur_program = Pprog
                and sorlcur_lmod_code='LEARNER'
        join smrprle on sorlcur_program=smrprle_program
        join sztdtec on sorlcur_program=sztdtec_program
               and  SORLCUR_CAMP_CODE=sztdtec_camp_code
               and sztdtec_status='ACTIVO'
               and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
        join smrpaap s on smrpaap_program=sorlcur_program  AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
        join smrarul on smrpaap_area=smrarul_area
             and smrarul_area in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
             and (  (smrarul_area not in (select smriecc_area from smriecc)
                          and smrarul_area not in (select smriemj_area from smriemj))
             or (smrarul_area in (select smriemj_area from smriemj
                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                 from  sorlcur cu, sorlfos ss
                                                                  where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                    and   cu.sorlcur_pidm   = Ppidm
                                                                    and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                    and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                    and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                    and   cu.SORLCUR_CACT_CODE  = ss.SORLFOS_CACT_CODE
                                                                    and   cu.sorlcur_program   = Pprog
                                                               )    )
         and smrarul_area not in (select smriecc_area from smriecc))
         or  (smrarul_area in (select smriecc_area
                                 from smriecc
                                   where smriecc_majr_code_conc in
                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                 from  sorlcur cu, sorlfos ss
                                                                  where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                    and   cu.sorlcur_pidm = Ppidm
                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                    and  SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                                    and   sorlcur_program   = Pprog
                                                                     ) )) )
        join smbpgen on sorlcur_program=smbpgen_program and smbpgen_term_code_eff=smrpaap_term_code_eff
        join smbagen on smbagen_area=smrpaap_area and  smbagen_active_ind='Y' and  smbagen_term_code_eff=smrpaap_term_code_eff
        join smralib on smrpaap_area=smralib_area   and SMRALIB_LEVL_CODE=SORLCUR_LEVL_CODE
        join smracaa on  smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
        join shrtckn w on shrtckn_pidm=spriden_pidm
            and shrtckn_subj_code=smrarul_subj_code
            and shrtckn_crse_numb=smrarul_crse_numb_low
            and shrtckn_stsp_key_sequence=sorlcur_key_seqno
            and SHRTCKN_TERM_CODE in  (select max(SHRTCKN_TERM_CODE)
                                         from shrtckn ww
                                           where w.shrtckn_pidm=ww.shrtckn_pidm
                                            and w.shrtckn_subj_code=ww.shrtckn_subj_code
                                            and w.shrtckn_crse_numb=ww.shrtckn_crse_numb)
        join shrtckg on shrtckg_pidm=shrtckn_pidm and  shrtckg_term_code=shrtckn_term_code
              and shrtckg_tckn_seq_no=shrtckn_seq_no
              and shrtckg_term_code=shrtckn_term_code
        join scrsyln on scrsyln_subj_code=shrtckn_subj_code and scrsyln_crse_numb=shrtckn_crse_numb
        join shrgrde on shrgrde_code=shrtckg_grde_code_final
             and shrgrde_levl_code=SORLCUR_LEVL_CODE
         /* cambio escalas para prod */
        and  SHRGRDE_TERM_CODE_EFFECTIVE = ( select zstpara_param_desc
                                             from zstpara
                                              where zstpara_mapa_id='ESC_SHAGRD'
                                                and substr((select f_getspridenid(Ppidm) from dual),1,2) = zstpara_param_id
                                                and zstpara_param_valor=sgbstdn_levl_code)
        join stvterm on stvterm_code=shrtckn_term_code
        join scbcrse on scbcrse_subj_code=shrtckn_subj_code and scbcrse_crse_numb=shrtckn_crse_numb
        left outer join zstpara on zstpara_mapa_id='MAESTRIAS_BIM'
             and zstpara_param_id=sorlcur_program
             and zstpara_param_desc=SORLCUR_TERM_CODE_CTLG
        where 1=1
         and spriden_pidm = Ppidm
         and spriden_change_ind is null
         and shrtckg_grde_code_final not in ('NP','NA','5.0')
        order by  "Matricula",  "per","nombre_area","materia";

    else   -- IN ('MA','MS','DO')
        open histac_out
        FOR
        select distinct
              spriden_first_name||' '||replace(spriden_last_name,'/',' ') "Estudiante",
          spriden_id "Matricula",
          sztdtec_programa_comp "Programa",
          to_number(substr(smrarul_area,9,2)) "per",
          case when  shrtckn_subj_code is null or substr(stvterm_code,1,2)='08' then ' '
          else case when substr(smrarul_area,9,2) in ('01','03') then substr(smrarul_area,10,1)||'er. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('02') then substr(smrarul_area,10,1)||'do. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('04','05','06') then substr(smrarul_area,10,1)||'to.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('07') then substr(smrarul_area,10,1)||'mo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('08') then substr(smrarul_area,10,1)||'vo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('09') then substr(smrarul_area,10,1)||'no.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('10') then substr(smrarul_area,9,2)||'mo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          else smralib_area_desc
          end
          end   "nombre_area",
          smrarul_subj_code||smrarul_crse_numb_low "materia",
          scrsyln_long_course_title "nombre_mat",
          case when substr(stvterm_code,1,2)='08' then substr(stvterm_desc,7,4)
          else substr(stvterm_desc,1,6)
          end  "periodo",
          shrtckg_grde_code_final "calif",
          shrgrde_abbrev "letra",
          0 "Avance",
          0 "Promedio",
          shrgrde_passed_ind "aprobatoria",
          scbcrse_credit_hr_low "creditos",
          case when substr(shrtckn_term_code,5,1)='8' then 'ORD'   --olc   cambio de EXT por ORD para maestria, master
             else 'ORD'
          end  "evaluacion",
          --  s.SORLCUR_APPL_KEY_SEQNO,
           (select  distinct  REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy')), ' ', '') ||' - '||
                 REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy')), ' ', '')
                from sfrstcr f, ssbsect bb
                where 1=1
                and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                and f.SFRSTCR_PIDM = Ppidm
                and f.SFRSTCR_GRDE_CODE is not null
                and f.SFRSTCR_RSTS_CODE = 'RE'
                and f.SFRSTCR_STSP_KEY_SEQUENCE  = s.SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and f2.SFRSTCR_RSTS_CODE = 'RE'
                                and f2.SFRSTCR_STSP_KEY_SEQUENCE  = s.SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16 --- col16
        from spriden
        join sgbstdn a on sgbstdn_pidm=spriden_pidm
               and sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff)
                                              from sgbstdn b
                                               where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                and b.SGBSTDN_PROGRAM_1 = Pprog)
        join sorlcur s on sorlcur_pidm=spriden_pidm and sorlcur_program=Pprog  and sorlcur_lmod_code='LEARNER'
        and sorlcur_seqno in (select max(sorlcur_seqno)
                                from sorlcur ss
                                   where s.sorlcur_pidm=ss.sorlcur_pidm
                                     and s.sorlcur_program=ss.sorlcur_program
                                     and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
        join smrprle on sorlcur_program=smrprle_program
        join sztdtec on sorlcur_program=sztdtec_program
            and SORLCUR_CAMP_CODE=sztdtec_camp_code
            and sztdtec_status='ACTIVO'
            and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
        join smrpaap s on smrpaap_program=sorlcur_program  AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
        join smrarul on smrpaap_area=smrarul_area
              and SMRARUL_TERM_CODE_EFF=smrpaap_term_code_eff
              and smrarul_area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
        and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR
                                                                 from ZSTPARA
                                                                   where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                   and spriden_pidm in (select spriden_pidm
                                                                                           from spriden
                                                                                             where spriden_id=ZSTPARA_PARAM_ID))
        join smbpgen on sorlcur_program=smbpgen_program and smbpgen_term_code_eff=smrpaap_term_code_eff
        join smbagen on smbagen_area=smrpaap_area and  smbagen_active_ind='Y'
              and  smbagen_term_code_eff=smrpaap_term_code_eff
        join smralib on smrpaap_area=smralib_area  and SMRALIB_LEVL_CODE=SORLCUR_LEVL_CODE
        join smracaa on  smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
        join shrtckn w on shrtckn_pidm=spriden_pidm
             and shrtckn_subj_code=smrarul_subj_code
             and shrtckn_crse_numb=smrarul_crse_numb_low
             and shrtckn_stsp_key_sequence=sorlcur_key_seqno
        join shrtckg z on shrtckg_pidm=shrtckn_pidm
             and shrtckg_term_code=shrtckn_term_code
             and shrtckg_tckn_seq_no=shrtckn_seq_no
             and shrtckg_term_code=shrtckn_term_code
        and  decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))
                       in ( select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final)))
                              from shrtckn ww, shrtckg zz
                                where w.shrtckn_pidm=ww.shrtckn_pidm
                                and   w.shrtckn_subj_code=ww.shrtckn_subj_code
                                and   w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                and   ww.shrtckn_pidm=zz.shrtckg_pidm
                                and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no
                                and ww.shrtckn_term_code=zz.shrtckg_term_code)
        join scrsyln on scrsyln_subj_code=shrtckn_subj_code and    scrsyln_crse_numb=shrtckn_crse_numb
        join shrgrde on shrgrde_code=shrtckg_grde_code_final
           and shrgrde_levl_code=SORLCUR_LEVL_CODE
           and shrgrde_passed_ind='Y'
       /* cambio escalas para prod */
        and SHRGRDE_TERM_CODE_EFFECTIVE = ( select zstpara_param_desc
                                             from zstpara
                                               where zstpara_mapa_id='ESC_SHAGRD'
                                                and substr((select f_getspridenid(Ppidm) from dual),1,2)=zstpara_param_id
                                                and zstpara_param_valor=sgbstdn_levl_code)
        join stvterm on stvterm_code=shrtckn_term_code
        join scbcrse on scbcrse_subj_code=shrtckn_subj_code and scbcrse_crse_numb=shrtckn_crse_numb
        left outer join zstpara on zstpara_mapa_id='MAESTRIAS_BIM'
             and zstpara_param_id=sorlcur_program
             and zstpara_param_desc=SORLCUR_TERM_CODE_CTLG
        where 1=1
        and spriden_pidm = Ppidm
         and spriden_change_ind is null
         and shrtckg_grde_code_final not in ('NP','NA','5.0','6.0')
    union
        select distinct
          spriden_first_name||' '||replace(spriden_last_name,'/',' ') "Estudiante",
          spriden_id "Matricula",
          sztdtec_programa_comp "Programa",
          to_number(substr(smrarul_area,9,2)) "per",
          case when  shrtrce_subj_code is null or substr(spriden_id,1,2)='08' then ' '
          else case when substr(smrarul_area,9,2) in ('01','03') then substr(smrarul_area,10,1)||'er.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('02') then substr(smrarul_area,10,1)||'do.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('04','05','06') then substr(smrarul_area,10,1)||'to.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('07') then substr(smrarul_area,10,1)||'mo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('08') then substr(smrarul_area,10,1)||'vo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('09') then substr(smrarul_area,10,1)||'no.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          when substr(smrarul_area,9,2) in ('10') then substr(smrarul_area,9,2)||'mo.  '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
          else smralib_area_desc
          end
          end   "nombre_area",
          smrarul_subj_code||smrarul_crse_numb_low "materia",
          scrsyln_long_course_title "nombre_mat",
          ' ' "periodo",
          shrtrce_grde_code "calif",
          shrgrde_abbrev "letra",
          0 "Avance",
          0 "Promedio",
          shrgrde_passed_ind "aprobatoria",
          scbcrse_credit_hr_low "creditos",
          'EQ' "evaluacion",
          --  s.SORLCUR_APPL_KEY_SEQNO,
            (select  distinct  REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy')), ' ', '') ||' - '||
                 REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy')), ' ', '')
                from sfrstcr f, ssbsect bb
                where 1=1
                and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                and f.SFRSTCR_PIDM = Ppidm
                and f.SFRSTCR_GRDE_CODE is not null
                and f.SFRSTCR_RSTS_CODE = 'RE'
                and f.SFRSTCR_STSP_KEY_SEQUENCE  = s.SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_RSTS_CODE = 'RE'
                                and f2.SFRSTCR_STSP_KEY_SEQUENCE  = s.SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin --- col16 --- col16
        from spriden
        join sgbstdn a on sgbstdn_pidm=spriden_pidm
                  and sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff)
                                                    from sgbstdn b
                                                          where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                            and b.SGBSTDN_PROGRAM_1= Pprog)
        join sorlcur s on sorlcur_pidm=spriden_pidm and sorlcur_program=Pprog   and sorlcur_lmod_code='LEARNER'
        and sorlcur_seqno in (select max(sorlcur_seqno)
                               from sorlcur ss
                                 where s.sorlcur_pidm=ss.sorlcur_pidm
                                  and s.sorlcur_program=ss.sorlcur_program
                                  and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
        join smrprle on sorlcur_program=smrprle_program
        join sztdtec on sorlcur_program=sztdtec_program and SORLCUR_CAMP_CODE=sztdtec_camp_code
               and sztdtec_status='ACTIVO'
               and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
        join smrpaap s on smrpaap_program=sorlcur_program  AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
        join smrarul on smrpaap_area=smrarul_area
               and SMRARUL_TERM_CODE_EFF=smrpaap_term_code_eff
               and smrarul_area not in  (select ZSTPARA_PARAM_VALOR
                                            from ZSTPARA
                                              where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES'
                                               and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
        and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in
                         (select ZSTPARA_PARAM_VALOR
                            from ZSTPARA
                              where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                 and spriden_pidm in (select spriden_pidm
                                                        from spriden where spriden_id=ZSTPARA_PARAM_ID))
        join smbpgen on sorlcur_program=smbpgen_program and smbpgen_term_code_eff=smrpaap_term_code_eff
        join smbagen on smbagen_area=smrpaap_area
             and smbagen_active_ind='Y'
             and smbagen_term_code_eff=smrpaap_term_code_eff
        join smralib on smrpaap_area=smralib_area  and SMRALIB_LEVL_CODE=SORLCUR_LEVL_CODE
        join smracaa on  smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
        join shrtrcr on shrtrcr_pidm=spriden_pidm and  shrtrcr_program=Pprog
        join shrtrce on shrtrce_pidm=spriden_pidm
              and shrtrce_subj_code=smrarul_subj_code
              and shrtrce_crse_numb=smrarul_crse_numb_low
              and shrtrce_trit_seq_no=shrtrcr_trit_seq_no
              and    shrtrce_tram_seq_no=shrtrcr_tram_seq_no
        join scrsyln on scrsyln_subj_code=shrtrce_subj_code and    scrsyln_crse_numb=shrtrce_crse_numb
        join shrgrde on shrgrde_code=shrtrce_grde_code
             and shrgrde_levl_code=SORLCUR_LEVL_CODE
             and shrgrde_passed_ind='Y'
             /* cambio escalas para prod */
             and shrgrde_term_code_effective = (select zstpara_param_desc
                                                  from zstpara
                                                    where zstpara_mapa_id='ESC_SHAGRD'
                                                        and substr((select f_getspridenid(Ppidm) from dual),1,2)=zstpara_param_id
                                                        and zstpara_param_valor=sgbstdn_levl_code)
        join scbcrse on scbcrse_subj_code=shrtrce_subj_code and scbcrse_crse_numb=shrtrce_crse_numb
         left outer join zstpara on zstpara_mapa_id='MAESTRIAS_BIM'
               and zstpara_param_id=sorlcur_program
               and zstpara_param_desc=SORLCUR_TERM_CODE_CTLG
        where 1=1
            and spriden_pidm = Ppidm
            and spriden_change_ind is null
            and shrtrce_grde_code not in ('NP','NA','5.0','6.0')
     union
        select distinct
          spriden_first_name||' '||replace(spriden_last_name,'/',' ') "Estudiante",
          spriden_id "Matricula",
          sztdtec_programa_comp "Programa",
          20 "per",
          'TALLERES' "nombre_area",
          smrarul_subj_code||smrarul_crse_numb_low "materia",
          scrsyln_long_course_title "nombre_mat",
          case when substr(stvterm_code,1,2)='08' then substr(stvterm_desc,7,4)
          else substr(stvterm_desc,1,6)
          end  "periodo",
          shrtckg_grde_code_final "calif",
          shrgrde_abbrev "letra",
          0 "Avance",
          0 "Promedio",
          shrgrde_passed_ind "aprobatoria",
          scbcrse_credit_hr_low "creditos",
            case when substr(shrtckn_term_code,5,1)='8' then  'ORD'   --olc   cambio de EXT por ORD para maestria, master
             else 'ORD'
          end   "evaluacion",
          --  s.SORLCUR_APPL_KEY_SEQNO,
          (select  distinct  REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_START_DATE, 'DD/Mon/yy')), ' ', '') ||' - '||
                 REPLACE (TRIM (TO_CHAR (SSBSECT_PTRM_END_DATE, 'DD/Mon/yy')), ' ', '')
                from sfrstcr f, ssbsect bb
                where 1=1
                and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                and f.SFRSTCR_PIDM = Ppidm
                and f.SFRSTCR_GRDE_CODE is not null
                and f.SFRSTCR_RSTS_CODE = 'RE'
                and f.SFRSTCR_STSP_KEY_SEQUENCE  = s.SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low 
                and BB.SSBSECT_TERM_CODE = (select distinct max (B2.SSBSECT_TERM_CODE)
                            from sfrstcr f2, ssbsect b2
                                where 1=1
                                and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                and F2.SFRSTCR_PIDM = ppidm
                                and f2.SFRSTCR_GRDE_CODE is not null
                                and f2.SFRSTCR_RSTS_CODE = 'RE'
                                and f2.SFRSTCR_STSP_KEY_SEQUENCE  = s.SORLCUR_APPL_KEY_SEQNO --nuevo filtro x SP
                                and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB = smrarul_subj_code||smrarul_crse_numb_low )) as fini_fin  --- col16
        from spriden
        join sgbstdn a on sgbstdn_pidm=spriden_pidm
             and sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff)
                                             from sgbstdn b
                                               where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                 and b.SGBSTDN_PROGRAM_1 = Pprog)
        join sorlcur s on sorlcur_pidm=sgbstdn_pidm
         and sorlcur_program = Pprog
         and sorlcur_lmod_code='LEARNER'
        and sorlcur_seqno in (select max(sorlcur_seqno)
                                from sorlcur ss
                                  where s.sorlcur_pidm=ss.sorlcur_pidm
                                    and s.sorlcur_program=ss.sorlcur_program
                                    and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
        join smrprle on sorlcur_program=smrprle_program
        join sztdtec on sorlcur_program=sztdtec_program
            and SORLCUR_CAMP_CODE=sztdtec_camp_code
            and sztdtec_status='ACTIVO'
            and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
        join smrpaap s on smrpaap_program=sorlcur_program  AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
        join smrarul on smrpaap_area=smrarul_area
             and SMRARUL_TERM_CODE_EFF=smrpaap_term_code_eff
             and     smrarul_area in (select ZSTPARA_PARAM_VALOR
                                        from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
             and SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR
                                                                     from ZSTPARA
                                                                      where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                         and spriden_pidm in (select spriden_pidm
                                                                                                 from spriden
                                                                                                   where spriden_id=ZSTPARA_PARAM_ID))
        join smbpgen on sorlcur_program=smbpgen_program and smbpgen_term_code_eff=smrpaap_term_code_eff
        join smbagen on smbagen_area=smrpaap_area
            and smbagen_active_ind='Y'
            and smbagen_term_code_eff=smrpaap_term_code_eff
        join smralib on smrpaap_area=smralib_area  and SMRALIB_LEVL_CODE=SORLCUR_LEVL_CODE
        join smracaa on  smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
        join shrtckn w on shrtckn_pidm=spriden_pidm
           and  shrtckn_subj_code=smrarul_subj_code
           and  shrtckn_crse_numb=smrarul_crse_numb_low
           and  shrtckn_seq_no in (select max(shrtckn_seq_no)
                                        from shrtckn ww
                                          where w.shrtckn_pidm=ww.shrtckn_pidm
                                           and w.shrtckn_subj_code=ww.shrtckn_subj_code
                                           and w.shrtckn_crse_numb=ww.shrtckn_crse_numb)
        join shrtckg on shrtckg_pidm=shrtckn_pidm
            and shrtckg_term_code=shrtckn_term_code
            and shrtckg_tckn_seq_no=shrtckn_seq_no
            and shrtckg_term_code=shrtckn_term_code
        join scrsyln on scrsyln_subj_code=shrtckn_subj_code and    scrsyln_crse_numb=shrtckn_crse_numb
        join shrgrde on shrgrde_code=shrtckg_grde_code_final
            and shrgrde_levl_code=SORLCUR_LEVL_CODE
            and shrgrde_passed_ind='Y'
        /* cambio escalas para prod */
            and shrgrde_term_code_effective=(select zstpara_param_desc
                                               from zstpara
                                                 where zstpara_mapa_id='ESC_SHAGRD'
                                                   and substr((select f_getspridenid(Ppidm) from dual),1,2)=zstpara_param_id
                                                   and zstpara_param_valor=sgbstdn_levl_code)
        join stvterm on stvterm_code=shrtckn_term_code
        join scbcrse on scbcrse_subj_code=shrtckn_subj_code and scbcrse_crse_numb=shrtckn_crse_numb
        left outer join zstpara on zstpara_mapa_id='MAESTRIAS_BIM'
            and zstpara_param_id=sorlcur_program
            and zstpara_param_desc=SORLCUR_TERM_CODE_CTLG
        where 1=1
         and spriden_pidm = Ppidm
         and spriden_change_ind is null
         and shrtckg_grde_code_final not in ('NP','NA','5.0','6.0')
        order by  "Matricula",  "per","materia";
    end if;

      RETURN (histac_out);
      
 exception when others then 
  dbms_output.put_line('error gral HIAC QR:: '|| sqlerrm);
 END F_HIAC_OUT;


FUNCTION F_AVCU_OUT (Ppidm number, Pprog varchar2,pusu_siu varchar2) RETURN PKG_QR_DIG.avcu_out
           AS
 avance_n_out PKG_QR_DIG.avcu_out;

  VL_DIPLO NUMBER:=0;
  VL_DIPLO2 NUMBER:=0;
  --VL_PIDM NUMBER:= Ppidm;
  vsalida varchar2(400); 
  
 BEGIN

      BEGIN
        SELECT NVL(count(*),0)
         INTO  VL_DIPLO2
          FROM TZTPROG A
           WHERE 1=1
            and A.PIDM = Ppidm
            and A.CAMPUS='UTS'
            AND A.NIVEL='EC'
            AND A.ESTATUS in('BT');

        EXCEPTION
            WHEN OTHERS THEN
             VL_DIPLO2 := 0;
        END;


     IF   VL_DIPLO2>=1 THEN

           VL_DIPLO:=0;

     ELSIF VL_DIPLO2 =0 THEN

        BEGIN
                SELECT NVL(count(*),0)
                INTO  VL_DIPLO
                FROM TZTPROG A
                WHERE 1=1
                and A.PIDM = Ppidm
                and A.CAMPUS='UTS'
                AND A.NIVEL='EC';
        EXCEPTION
            WHEN OTHERS THEN
             VL_DIPLO := 0;
        END;

     END IF;

  IF VL_DIPLO =0  THEN

       begin
         
         delete from avance_n
         where protocolo=9999
           and USUARIO_SIU=pusu_siu;
           commit;
       exception when others then
        vsalida := sqlerrm;
       end;

        
    BEGIN


      insert into avance_n
        select distinct /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
        case
        when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
        when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
        else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
        end  as per,  ----
        smrpaap_area  as area,   ----
        case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR 
                                         from ZSTPARA 
                                          where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
        case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                 when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                 when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                 when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                 when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                 when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                 when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                 else smralib_area_desc
         end
        else smralib_area_desc
        end  as nombre_area,  ---
        smrarul_subj_code||smrarul_crse_numb_low  as materia, ----
        scrsyln_long_course_title as nombre_mat, ----
        case when k.calif in ('NA','NP','AC') then '1'
        when k.st_mat='EC' then '101'
        else  k.calif
        end as calif, ---
        nvl(k.st_mat,'PC'),  ---
        smracaa_rule  as regla,   ---
        case when k.st_mat='EC' then null
        else k.calif
        end  as origen,
        k.fecha, ---
        ppidm ,
        pusu_siu
     from smrpaap s, smrarul, sgbstdn y, sorlcur so, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
        (select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
             w.shrtckn_subj_code subj, 
             w.shrtckn_crse_numb code,
             shrtckg_grde_code_final CALIF, 
             decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, 
             shrtckg_final_grde_chg_date fecha
              from shrtckn w,shrtckg, shrgrde, smrprle
               where shrtckn_pidm = Ppidm
                and  shrtckg_pidm=w.shrtckn_pidm
                and  SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401')
                and  shrtckg_tckn_seq_no =w.shrtckn_seq_no
                and  shrtckg_term_code =w.shrtckn_term_code
                and  smrprle_program = Pprog
                and  shrgrde_levl_code =smrprle_levl_code  -------------------
           /* cambio escalas para prod */             
                and shrgrde_term_code_effective = (select zstpara_param_desc 
                                                    from zstpara 
                                                     where zstpara_mapa_id='ESC_SHAGRD' 
                                                      and substr((select f_getspridenid(Ppidm) from dual),1,2)=zstpara_param_id 
                                                      and zstpara_param_valor=smrprle_levl_code)
                and  shrgrde_code=shrtckg_grde_code_final
                and  decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))   -- anadido para sacar la calificacion mayor  OLC
                      in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))) 
                           from shrtckn ww, shrtckg zz
                            where w.shrtckn_pidm=ww.shrtckn_pidm
                             and  w.shrtckn_subj_code=ww.shrtckn_subj_code  
                             and  w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                             and  ww.shrtckn_pidm=zz.shrtckg_pidm 
                             and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no 
                             and ww.shrtckn_term_code=zz.shrtckg_term_code)
                             and SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                  and shrtckn_pidm in (select spriden_pidm 
                                                                                                        from spriden 
                                                                                                          where spriden_id=ZSTPARA_PARAM_ID))
          union
            select shrtrce_subj_code as subj, 
                   shrtrce_crse_numb as code,
                   shrtrce_grde_code as CALIF, 
                   'EQ'  as ST_MAT, 
                   trunc(shrtrce_activity_date) as fecha
               from shrtrce
                 where shrtrce_pidm = Ppidm
                   and SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401' )
       union
           select SHRTRTK_SUBJ_CODE_INST as subj, 
                 SHRTRTK_CRSE_NUMB_INST as code,
               /*nvl(SHRTRTK_GRDE_CODE_INST,0)*/  
               '0' as CALIF, 
               'EQ' as ST_MAT, 
               trunc(SHRTRTK_ACTIVITY_DATE) as fecha
             from  SHRTRTK
               where  SHRTRTK_PIDM = Ppidm
            union
              select ssbsect_subj_code as subj, 
                    ssbsect_crse_numb as code, 
                    '101' as CALIF, 
                    'EC' as ST_MAT, 
                    trunc(sfrstcr_rsts_date)+120 as fecha
                from sfrstcr, smrprle, ssbsect, spriden
                 where smrprle_program = Pprog
                  and sfrstcr_pidm=Ppidm  
                  and sfrstcr_grde_code is null 
                  and sfrstcr_rsts_code='RE'
                  and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401' )
                  and spriden_pidm=sfrstcr_pidm 
                  and spriden_change_ind is null
                 --  and    sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                  and ssbsect_term_code=sfrstcr_term_code
                  and ssbsect_crn=sfrstcr_crn
        union
             select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
               ssbsect_subj_code as subj, 
               ssbsect_crse_numb as code, 
               sfrstcr_grde_code as CALIF,  
               decode (shrgrde_passed_ind,'Y','AP','N','NA') as ST_MAT, 
               trunc(sfrstcr_rsts_date) as fecha
             from sfrstcr, smrprle, ssbsect, spriden, shrgrde
              where smrprle_program = Pprog
               and  sfrstcr_pidm= Ppidm  
               and sfrstcr_grde_code is not null
               and  sfrstcr_pidm not in (select shrtckn_pidm 
                                          from shrtckn 
                                            where sfrstcr_term_code=shrtckn_term_code 
                                             and shrtckn_crn=sfrstcr_crn)
               and  SFRSTCR_RSTS_CODE!='DD'  --- agregado
               and  spriden_pidm=sfrstcr_pidm 
               and spriden_change_ind is null
               --   and   sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
               and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401')
               and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                  where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                    and sfrstcr_pidm in (select spriden_pidm 
                                                                                           from spriden 
                                                                                           where spriden_id=ZSTPARA_PARAM_ID))
               and  ssbsect_term_code=sfrstcr_term_code
               and  ssbsect_crn=sfrstcr_crn
               and  shrgrde_levl_code=smrprle_levl_code   -------------------
            /* cambio escalas para prod */            
               and shrgrde_term_code_effective=(select zstpara_param_desc 
                                                   from zstpara 
                                                   where zstpara_mapa_id='ESC_SHAGRD' 
                                                   and substr((select f_getspridenid(Ppidm) from dual),1,2)=zstpara_param_id 
                                                   and zstpara_param_valor=smrprle_levl_code)
               and  shrgrde_code=sfrstcr_grde_code
      ) k
      where   1=1
        and spriden_pidm = Ppidm  
        and spriden_change_ind is null
        and sorlcur_pidm= spriden_pidm
        and SORLCUR_LMOD_CODE = 'LEARNER'
        and SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                             from sorlcur ss
                             where so.SORLCUR_PIDM=ss.sorlcur_pidm
                               and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                               and ss.sorlcur_program = Pprog)
        and    smrpaap_program= Pprog
        AND    smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
        and    smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
        and    SMBAGEN_ACTIVE_IND='Y'           --solo areas activas  OLC
        and    SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF   --solo areas activas  OLC
        and    smrpaap_area=smrarul_area
        and    sgbstdn_pidm=spriden_pidm
        and    sgbstdn_program_1=smrpaap_program
        and    sgbstdn_term_code_eff in ( select max(sgbstdn_term_code_eff) 
                                          from sgbstdn x
                                           where x.sgbstdn_pidm=y.sgbstdn_pidm
                                             and x.sgbstdn_program_1=y.sgbstdn_program_1)
        and    sztdtec_program=sgbstdn_program_1 
        and    sztdtec_status='ACTIVO'  
        and    SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
        and    SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
        and    SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
        and    stvstst_code=sgbstdn_stst_code
        and    smralib_area=smrpaap_area
        AND    smracaa_area = smrarul_area
        AND    smracaa_rule = smrarul_key_rule
        and    SMRACAA_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG
        and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401')
        and    (  (smrarul_area not in ( select smriecc_area from smriecc) 
                   and smrarul_area not in (select smriemj_area from smriemj)) 
                or (smrarul_area in (select smriemj_area from smriemj
                                       where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                    where  cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                      and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                      and   cu.sorlcur_pidm = Ppidm
                                                                      and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                      and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                      and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                      and   cu.SORLCUR_SEQNO in ( select max(SORLCUR_SEQNO) 
                                                                                                   from sorlcur ss
                                                                                                     where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                        and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                        and ss.sorlcur_program = Pprog)
                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                              and ss.sorlcur_program =Pprog)
                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                            and   sorlcur_program   = Pprog )   )
          and smrarul_area not in (select smriecc_area from smriecc)) 
          or (smrarul_area in ( select smriecc_area from smriecc where smriecc_majr_code_conc in
                                             ( select distinct SORLFOS_MAJR_CODE
                                                 from  sorlcur cu, sorlfos ss
                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                  and ss.sorlcur_program = Pprog )
                                                    and   cu.sorlcur_pidm=Ppidm
                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                    and   sorlcur_program   = Pprog )
                                   )) )
        and k.subj=smrarul_subj_code 
        and k.code=smrarul_crse_numb_low
        and scrsyln_subj_code=smrarul_subj_code 
        and scrsyln_crse_numb=smrarul_crse_numb_low
        and zstpara_mapa_id(+)='MAESTRIAS_BIM' 
        and zstpara_param_id(+)=sgbstdn_program_1 
        and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
    
    union
    
       select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
        case
        when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
        when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
        else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
        end as  per,  ---
         smrpaap_area as area, ---
          case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
              case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                     when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                     when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                     when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                     when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                     when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                     when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                     else smralib_area_desc
               end
            else smralib_area_desc
          end  as  nombre_area, ---
            smrarul_subj_code||smrarul_crse_numb_low as materia, ---
            scrsyln_long_course_title as nombre_mat, ---
             null calif,  ---
             'PC' ,  ---
             smracaa_rule as regla, ---
             null as origen, ---
             null as fecha, --
             Ppidm ,
             Pusu_siu
      from spriden, smrpaap, sgbstdn y, sorlcur so,SZTDTEC, smrarul, smracaa, smralib, stvstst, scrsyln, zstpara,smbagen
        where 1=1   
        and  spriden_pidm = Ppidm  
        and  spriden_change_ind is null
        and  sorlcur_pidm= spriden_pidm
        and  SORLCUR_LMOD_CODE = 'LEARNER'
        and  SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                  from sorlcur ss 
                                   where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                    and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                    and ss.sorlcur_program = Pprog)
       and   smrpaap_program = Pprog
       AND   smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
       and   smrpaap_area=SMBAGEN_AREA
       and   SMBAGEN_ACTIVE_IND='Y'
       and   SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
       and   smrpaap_area=smrarul_area
       and   sgbstdn_pidm=spriden_pidm
       and   sgbstdn_program_1=smrpaap_program
       and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                        where x.sgbstdn_pidm=y.sgbstdn_pidm
                                          and x.sgbstdn_program_1=y.sgbstdn_program_1)
       and  sztdtec_program=sgbstdn_program_1 
       and  sztdtec_status='ACTIVO' 
       and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
       and  SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
       and  stvstst_code=sgbstdn_stst_code
       and  smralib_area=smrpaap_area
       AND  smracaa_area = smrarul_area
       AND  smracaa_rule = smrarul_key_rule
       AND  SMRARUL_TERM_CODE_EFF = SORLCUR_TERM_CODE_CTLG
       and  SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001' )
       and  SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR 
                                                                from ZSTPARA 
                                                                  where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                    and spriden_pidm in (select spriden_pidm  
                                                                                          from spriden 
                                                                                          where spriden_id=ZSTPARA_PARAM_ID))
        and  (  (smrarul_area not in (select smriecc_area from smriecc) 
                  and smrarul_area not in (select smriemj_area from smriemj)) 
               or (smrarul_area in (select smriemj_area 
                                     from smriemj
                                      where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                 from sorlcur cu, sorlfos ss
                                                                where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                  and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                  and cu.sorlcur_pidm=Ppidm
                                                                  and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                  and SORLFOS_LFST_CODE = 'MAJOR'
                                                                  and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                                                                            from sorlcur ss
                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                              and ss.sorlcur_program =Pprog)
                                                                 and cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                          and ss.sorlcur_program =Pprog)
                                                                  and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                  and   sorlcur_program   = Pprog )    )
       and smrarul_area not in (select smriecc_area from smriecc)) 
       or  (smrarul_area in ( select smriecc_area 
                              from smriecc 
                               where smriecc_majr_code_conc in (select distinct SORLFOS_MAJR_CODE
                                                                 from sorlcur cu, sorlfos ss
                                                                where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                  and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                  and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                                                                            from sorlcur ss
                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                              and ss.sorlcur_program = Pprog )
                                                                  and   cu.sorlcur_pidm = Ppidm
                                                                  and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                  and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                  and   SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                  and   sorlcur_program   = Pprog ) 
                             )) )
       and  scrsyln_subj_code=smrarul_subj_code 
       and scrsyln_crse_numb=smrarul_crse_numb_low
       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTCKN_SUBJ_CODE,SHRTCKN_CRSE_NUMB  from shrtckn where shrtckn_pidm = Ppidm )
       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRCE_SUBJ_CODE,SHRTRCE_CRSE_NUMB  from SHRTRCE where SHRTRCE_pidm = Ppidm )     --agregado
       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRTK_SUBJ_CODE_INST,SHRTRTK_CRSE_NUMB_INST  from SHRTRTK where SHRTRTK_pidm = Ppidm )  --agregado
       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select ssbsect_subj_code subj, ssbsect_crse_numb code  
                                                               from  sfrstcr, smrprle, ssbsect, spriden  --agregado para materias EC y aprobadas sin rolar
                                                               where  smrprle_program = Pprog
                                                                 and  sfrstcr_pidm = Ppidm  
                                                                 and (sfrstcr_grde_code is null or sfrstcr_grde_code is not null)  
                                                                 and sfrstcr_rsts_code='RE'
                                                                 and  spriden_pidm=sfrstcr_pidm 
                                                                 and spriden_change_ind is null
                                                                 and  ssbsect_term_code=sfrstcr_term_code
                                                                 and  ssbsect_crn=sfrstcr_crn)
       and  zstpara_mapa_id(+)='MAESTRIAS_BIM' 
       and zstpara_param_id(+)=sgbstdn_program_1 
       and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG;

      commit;
    EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR EN INSERT PRINCIPAL '||SQLERRM  );
    end;
    
    
         /*segunda parte del proceso obtiene el cursor final  */ 
   open avance_n_out
      FOR
        select distinct avance1.materia as materia, 
          avance1.nombre_mat as nombre_mat,
          avance1.calif as calif,
          avance1.per as per, 
          avance1.area as area,
          case when substr(spriden_id,1,2)='08' then ' '
          else
              case when substr(avance1.materia,1,4)='L1HB' then 'MATERIAS INTRODUCTORIAS'
                    when substr(avance1.materia,1,4)='M1HB' then 'MATERIAS INTRODUCTORIAS'
              else upper(avance1.nombre_area)
              end
          end as nombre_area,
          avance1.ord as ord,
          CASE WHEN avance1.apr = 'AP' THEN 
          NULL 
          ELSE apr 
          END as tipo,
         ----------------------------------------
         case when
              round (( select count(unique materia) 
                    from avance_n x
                 where  apr in ('AP','EQ')
                 and    protocolo = 9999
                 and    pidm_alu = Ppidm
                 and    usuario_siu = Pusu_siu
                 and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                 and    calif not in ('NP','AC')
                 and    ( to_number(calif)  in (select max(to_number(calif)) 
                                                 from avance_n xx
                                                    where x.materia=xx.materia
                                                    and   x.protocolo=xx.protocolo
                                                    and   x.pidm_alu=xx.pidm_alu
                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) 
                     or calif is null)
                 and  ( ( area not in (select smriecc_area from smriecc) 
                 and  area not in (select smriemj_area from smriemj))
                   or   -- VALIDA LA EXITENCIA EN SMAALIB
                      ( area in (select smriemj_area 
                                  from smriemj
                                     where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                        and   cu.sorlcur_pidm = Ppidm
                                                                        and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                        and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                        and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                        and   cu.SORLCUR_SEQNO in ( select max(SORLCUR_SEQNO) 
                                                                                                      from sorlcur ss
                                                                                                        where cu.SORLCUR_PIDM = ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code = ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog)
                                                                       and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program =Pprog)
                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                        and   sorlcur_program   =Pprog
                                                                                           )    )
                     and area not in (select smriecc_area from smriecc)) 
                     or     -- VALIDA LA EXITENCIA EN SMAALIB
                         ( area in (select smriecc_area 
                                      from smriecc 
                                        where smriecc_majr_code_conc in  ( select distinct SORLFOS_MAJR_CODE
                                                                             from  sorlcur cu, sorlfos ss
                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                             where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                               and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                               and ss.sorlcur_program =Pprog )
                                                                                and   cu.sorlcur_pidm=Ppidm
                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                and   sorlcur_program   = Pprog ) 
                                      ) ) )
                      ) *100 /
                      ( select  distinct SMBPGEN_REQ_COURSES_I_TRAD  
                          from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                            where SMBPGEN_program=Pprog
                                and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG 
                                                                from sorlcur
                                                                   where  sorlcur_pidm = Ppidm
                                                                      and sorlcur_program = Pprog 
                                                                      and sorlcur_lmod_code='LEARNER'
                                                                      and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) 
                                                                                             from sorlcur ss
                                                                                               where ss.sorlcur_pidm = Ppidm
                                                                                                 and ss.sorlcur_program = Pprog 
                                                                                                 and ss.sorlcur_lmod_code='LEARNER')))
                  )>100  then 100
             else
                round ( ( select count(unique materia) 
                          from avance_n x
                            where  apr in ('AP','EQ')
                             and    protocolo=9999
                             and    pidm_alu = Ppidm
                             and    usuario_siu = Pusu_siu
                             and    area not in ( select ZSTPARA_PARAM_VALOR 
                                                   from ZSTPARA 
                                                    where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' 
                                                     and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                             and    calif not in ('NP','AC')
                             and    (to_number(calif)  in (select max(to_number(calif)) 
                                                           from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu and CALIF!=0) 
                              Or calif is null)
                         and (  (area not in (select smriecc_area from smriecc) 
                          and area not in (select smriemj_area from smriemj)) 
                         or   -- VALIDA LA EXITENCIA EN SMAALIB
                            ( area in (select smriemj_area 
                                       from smriemj
                                        where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                        and   cu.sorlcur_pidm = Ppidm
                                                                        and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                        and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                        --and   cu.SORLCUR_ROLL_IND  = 'Y'
                                                                        and   cu.SORLCUR_SEQNO in ( select max(SORLCUR_SEQNO) 
                                                                                                     from sorlcur ss
                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog )
                                                                        and   cu.SORLCUR_TERM_CODE in ( select max(SORLCUR_TERM_CODE) 
                                                                                                       from sorlcur ss
                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog )
                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                        and   sorlcur_program   = Pprog )    )
                          and area not in (select smriecc_area from smriecc)) 
                            or -- VALIDA LA EXITENCIA EN SMAALIB
                               ( area in (select smriecc_area 
                                           from smriecc 
                                            where smriecc_majr_code_conc in ( select distinct SORLFOS_MAJR_CODE
                                                                               from  sorlcur cu, sorlfos ss
                                                                               where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                             where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                               and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                               and ss.sorlcur_program = Pprog )
                                                                                and  cu.sorlcur_pidm = Ppidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and   SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   = Pprog
                                                                                                 ) ) ) )
                          ) *100 /
                (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  
                  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                    where SMBPGEN_program=Pprog
                     and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG 
                                                   from sorlcur
                                                        where  sorlcur_pidm = Ppidm
                                                           and sorlcur_program = Pprog 
                                                           and sorlcur_lmod_code='LEARNER'
                                                           and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) 
                                                                                from sorlcur ss
                                                                                     where ss.sorlcur_pidm = Ppidm
                                                                                     and ss.sorlcur_program = Pprog 
                                                                                     and ss.sorlcur_lmod_code='LEARNER'))))
           end as avance_curr,
          (SELECT DISTINCT SCBCRSE_CREDIT_HR_LOW
                FROM scbcrse bs
                WHERE (SCBCRSE_SUBJ_CODE || SCBCRSE_CRSE_NUMB) = avance1.materia  ) as creditos
   FROM  spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
       ( SELECT 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
           FROM  ( select 9999, per, area, nombre_area, materia, nombre_mat,
                   case when calif='1' then cal_origen
                            when apr='EC' then null
                    else calif
                    end as calif, 
                    apr, 
                    regla, 
                    null as n_area,
                   case when substr(materia,1,2)='L3' then 5
                    else 1
                   end as ord,
                   fecha
                   from  sgbstdn y, avance_n x
                      where  x.protocolo=9999
                        and    sgbstdn_pidm = Ppidm
                        and    sgbstdn_program_1 = Pprog
                        and    x.pidm_alu = Ppidm
                        and    x.usuario_siu = Pusu_siu
                        and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) 
                                                          from sgbstdn x
                                                          where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                            and x.sgbstdn_program_1=y.sgbstdn_program_1)
                        and   area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                        and  ( to_number(calif) in ( select max(to_number(calif)) 
                                                     from avance_n xx
                                                      where x.materia=xx.materia
                                                      and  x.protocolo=xx.protocolo   ----cambio
                                                      and  x.pidm_alu=sgbstdn_pidm  ----cambio
                                                      and  x.pidm_alu=xx.pidm_alu   ---- cambio
                                                      and  x.usuario_siu=xx.usuario_siu) or calif is null)
                      union
                          select distinct 9999, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                            case when calif='1' then cal_origen
                                 when apr='EC' then null
                            else calif
                            end as calif, 
                            apr, 
                            regla, 
                            null n_area,
                            case when substr(materia,1,2)='L3' then 5
                            else 1
                            end as ord, 
                            fecha
                            from  sgbstdn y, avance_n x
                           where   x.protocolo=9999
                            and     sgbstdn_pidm = Ppidm
                            and    x.pidm_alu=sgbstdn_pidm
                            and     x.usuario_siu = Pusu_siu
                            and     apr='EC'
                            and     sgbstdn_program_1 = Pprog
                            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) 
                                                              from sgbstdn x
                                                               where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                 and x.sgbstdn_program_1=y.sgbstdn_program_1)
                           and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                  union
                          select protocolo, per, area, nombre_area, materia, nombre_mat,
                                case when calif='1' then cal_origen
                                     when apr='EC' then null
                                else calif
                                end as calif, 
                                apr, 
                                regla, 
                                stvmajr_desc n_area, 
                                2 ord, 
                                fecha
                             from  sgbstdn y, avance_n x, smriemj, stvmajr
                               where   x.protocolo=9999
                                and     sgbstdn_pidm = Ppidm
                                and     x.pidm_alu=sgbstdn_pidm
                                and     x.usuario_siu = Pusu_siu
                                and     sgbstdn_program_1 = Pprog
                                and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) 
                                                                    from sgbstdn x
                                                                   where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                     and x.sgbstdn_program_1=y.sgbstdn_program_1)
                               and    area=smriemj_area
                                -- and smriemj_majr_code=sgbstdn_majr_code_1   --vic
                                and smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                from  sorlcur cu, sorlfos ss
                                                                where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                and   cu.sorlcur_pidm = Ppidm
                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                                                                           from sorlcur ss
                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                              and ss.sorlcur_program = Pprog)
                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) 
                                                                                                from sorlcur ss
                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                  and ss.sorlcur_program = Pprog)
                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                and   sorlcur_program   = Pprog
              )
               and    area not in (select smriecc_area from smriecc)
               and    smriemj_majr_code=stvmajr_code
               and    (to_number(calif) in ( select max(to_number(calif)) 
                                             from avance_n xx
                                              where x.materia=xx.materia
                                              and   x.protocolo=xx.protocolo
                                              and   x.pidm_alu=xx.pidm_alu
                                              and   x.usuario_siu=xx.usuario_siu) or calif is null)
            union
                select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                    case when calif='1' then cal_origen
                         when apr='EC' then null
                     else calif
                    end  as calif, 
                    apr, 
                    regla, 
                    smralib_area_desc n_area, 
                    3 ord, 
                    fecha
                    from sgbstdn y, avance_n x ,smralib, smriecc a
                      where  x.protocolo=9999
                        and   sgbstdn_pidm = Ppidm
                        and   x.pidm_alu=sgbstdn_pidm
                        and   x.usuario_siu = Pusu_siu
                        and   sgbstdn_program_1 = Pprog
                        and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) 
                                                         from sgbstdn x
                                                         where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                           and x.sgbstdn_program_1=y.sgbstdn_program_1)
                       and    area=smralib_area
                       and    area=smriecc_area
                       --    and    smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)---modifico vic   18.04.2018
                       and   smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                         from  sorlcur cu, sorlfos ss
                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                            --  and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                            --  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                            --  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                            --  and ss.sorlcur_program =Pprog )
                                                            and   cu.sorlcur_pidm = Ppidm
                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                            and  SORLCUR_CACT_CODE =SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                            and   sorlcur_program   = Pprog
                                                             )
--                                                                   and    smriecc_majr_code_conc=stvmajr_code
                       and  ( to_number(calif) in (select max(to_number(calif)) from avance_n xx
                              where x.materia=xx.materia
                              and   x.protocolo=xx.protocolo
                              and   x.pidm_alu=xx.pidm_alu
                              and   x.usuario_siu=xx.usuario_siu) or calif is null)
--                                                                          or calif='1')   -----------------
                              and    (fecha in (select distinct fecha from avance_n xx
                              where x.materia=xx.materia
                              and   x.protocolo=xx.protocolo
                              and   x.pidm_alu=xx.pidm_alu
                              and   x.usuario_siu=xx.usuario_siu) or fecha is null)
                             order by  n_area desc, per, nombre_area,regla
                           )
        GROUP BY 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
        )  avance1
   where 1=1 
       and spriden_pidm = Ppidm
        and   sorlcur_pidm= spriden_pidm
        and   SORLCUR_LMOD_CODE = 'LEARNER'
        and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                  from sorlcur ss 
                                   where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                   and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                   and ss.sorlcur_program = Pprog)
        and     spriden_change_ind is null
        and     sgbstdn_pidm=spriden_pidm
        and     sgbstdn_program_1 = Pprog
        and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                           where a.sgbstdn_pidm=b.sgbstdn_pidm
                                             and a.sgbstdn_program_1=b.sgbstdn_program_1)
        and     sztdtec_program=sgbstdn_program_1
        and     sztdtec_status='ACTIVO'
        and     SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE
        and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
        and     sgbstdn_stst_code=stvstst_code
         order by  avance1.per;
  

  ELSIF VL_DIPLO >= 1 THEN
       
       begin
          delete from avance_n
                       where protocolo=9999
                       and USUARIO_SIU = Pusu_siu;
                       commit;
       exception when others then
        vsalida := sqlerrm;
       end;
  
  
        BEGIN   /*DIPLOMADOS*/
          
           insert into avance_n
                select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                    case
                        when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                        when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                        else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                    end  as per,  ----
                    smrpaap_area as area,   ----
                      case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                          case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                 when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                 when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                 when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                 when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                 when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                 when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                 else smralib_area_desc
                           end
                        else smralib_area_desc
                        end as nombre_area,  ---
                        smrarul_subj_code||smrarul_crse_numb_low as materia, ----
                        scrsyln_long_course_title as nombre_mat, ----
                         case when k.calif in ('NA','NP','AC') then '1'
                              when k.st_mat='EC' then '101'
                         else  k.calif
                         end as calif, ---
                         nvl(k.st_mat,'PC'),  ---
                         smracaa_rule as regla,   ---
                         case when k.st_mat='EC' then null
                           else k.calif
                         end  as origen,
                         k.fecha as fecha, ---
                         Ppidm ,
                         pusu_siu
                   from smrpaap s, smrarul, sgbstdn y, sorlcur so, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
                           (  select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                     w.shrtckn_subj_code as subj, 
                                     w.shrtckn_crse_numb as code,
                                     shrtckg_grde_code_final as CALIF, 
                                     decode (shrgrde_passed_ind,'Y','AP','N','NA') as ST_MAT, 
                                     shrtckg_final_grde_chg_date as fecha
                                 from shrtckn w,shrtckg, shrgrde, smrprle
                                  where 1=1
                                    and shrtckn_pidm = Ppidm
                                     and  shrtckg_pidm=w.shrtckn_pidm
                                     and  SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401' )
                                     and  shrtckg_tckn_seq_no=w.shrtckn_seq_no
                                     and  shrtckg_term_code=w.shrtckn_term_code
                                     and  smrprle_program = Pprog
                                     and  shrgrde_levl_code=smrprle_levl_code  -------------------
                                     /* cambio escalas para prod */             
                                     and shrgrde_term_code_effective=(select zstpara_param_desc 
                                                                         from zstpara 
                                                                          where zstpara_mapa_id='ESC_SHAGRD' 
                                                                           and substr((select f_getspridenid(Ppidm) from dual),1,2)=zstpara_param_id 
                                                                           and zstpara_param_valor=smrprle_levl_code)
                                     and  shrgrde_code=shrtckg_grde_code_final
                                     and  decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))   -- anadido para sacar la calificacion mayor  OLC
                                                    in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))) 
                                                         from shrtckn ww, shrtckg zz
                                                           where w.shrtckn_pidm=ww.shrtckn_pidm
                                                             and  w.shrtckn_subj_code=ww.shrtckn_subj_code  
                                                             and w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                                             and  ww.shrtckn_pidm=zz.shrtckg_pidm 
                                                             and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no 
                                                             and ww.shrtckn_term_code=zz.shrtckg_term_code)
                                    and   SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR 
                                                                                        from ZSTPARA
                                                                                         where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                          and shrtckn_pidm in (select spriden_pidm 
                                                                                                                from spriden 
                                                                                                                  where spriden_id=ZSTPARA_PARAM_ID))
                            union
                                   select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                           shrtrce_grde_code  CALIF, 
                                           'EQ'  ST_MAT, 
                                           trunc(shrtrce_activity_date) fecha
                                      from shrtrce
                                     where shrtrce_pidm = Ppidm
                                       and SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401' )
                            union
                                    select SHRTRTK_SUBJ_CODE_INST subj, SHRTRTK_CRSE_NUMB_INST code,
                                           '0' as CALIF, 
                                           'EQ' as  ST_MAT, 
                                           trunc(SHRTRTK_ACTIVITY_DATE) as fecha
                                        from  SHRTRTK
                                        where  SHRTRTK_PIDM = Ppidm
                             union
                                     select ssbsect_subj_code subj, ssbsect_crse_numb code, 
                                          '101' as CALIF, 
                                          'EC' as  ST_MAT, 
                                          trunc(sfrstcr_rsts_date)+120 as fecha
                                       from sfrstcr, smrprle, ssbsect, spriden
                                      where smrprle_program = Pprog
                                        and sfrstcr_pidm = Ppidm  
                                        and sfrstcr_grde_code is null 
                                        and sfrstcr_rsts_code='RE'
                                        and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401' )
                                        and spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                        and ssbsect_term_code=sfrstcr_term_code
                                        and ssbsect_crn=sfrstcr_crn
                             union
                                     select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                       ssbsect_subj_code subj, ssbsect_crse_numb code, 
                                        sfrstcr_grde_code as CALIF,  
                                        decode (shrgrde_passed_ind,'Y','AP','N','NA') as ST_MAT, 
                                        trunc(sfrstcr_rsts_date) as  fecha
                                     from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                      where smrprle_program = Pprog
                                       and  sfrstcr_pidm = Ppidm  
                                       and sfrstcr_grde_code is not null
                                       and  sfrstcr_pidm not in (select shrtckn_pidm 
                                                                    from shrtckn 
                                                                     where sfrstcr_term_code=shrtckn_term_code 
                                                                     and shrtckn_crn=sfrstcr_crn)
                                       and  SFRSTCR_RSTS_CODE!='DD'  --- agregado
                                       and  spriden_pidm=sfrstcr_pidm 
                                       and spriden_change_ind is null
                                       and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401' )
                                       and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                      where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                        and sfrstcr_pidm in (select spriden_pidm 
                                                                                                                             from spriden 
                                                                                                                             where spriden_id=ZSTPARA_PARAM_ID))
                                       and  ssbsect_term_code=sfrstcr_term_code
                                       and  ssbsect_crn=sfrstcr_crn
                                       and  shrgrde_levl_code=smrprle_levl_code      
                                       and shrgrde_term_code_effective=(select zstpara_param_desc 
                                                                          from zstpara 
                                                                           where zstpara_mapa_id='ESC_SHAGRD' 
                                                                            and substr((select f_getspridenid(Ppidm) from dual),1,2)=zstpara_param_id 
                                                                            and zstpara_param_valor=smrprle_levl_code)
                                       and  shrgrde_code=sfrstcr_grde_code
                                   ) k
                            where   spriden_pidm=Ppidm  and spriden_change_ind is null
                               and   sorlcur_pidm= spriden_pidm
                               and   SORLCUR_LMOD_CODE = 'LEARNER'
                               and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                         where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                           and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                           and ss.sorlcur_program = Pprog)
                                   and    smrpaap_program = Pprog
                                   AND    smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                                   and    smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                   and    SMBAGEN_ACTIVE_IND='Y'           --solo areas activas  OLC
                                   and    SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF   --solo areas activas  OLC
                                   and    smrpaap_area=smrarul_area
                                   and    sgbstdn_pidm=spriden_pidm
                                   and    SORLCUR_program=smrpaap_program
                                   and    sztdtec_program=SORLCUR_program 
                                   and    sztdtec_status='ACTIVO'  
                                   and    SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                   and    SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                   and    SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
                                   and    stvstst_code=sgbstdn_stst_code
                                   and    smralib_area=smrpaap_area
                                   AND    smracaa_area = smrarul_area
                                   AND    smracaa_rule = smrarul_key_rule
                                   and    SMRACAA_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG
                                   and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401' )
                                   and   (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) 
                                     or   (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                              and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                              and   cu.sorlcur_pidm = Ppidm
                                                                                              and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                              and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                              and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                                                                                                         from sorlcur ss
                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                            and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                            and ss.sorlcur_program = Pprog)
                                                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) 
                                                                                                                                from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program = Pprog)
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   = Pprog
                                )    )
                           and smrarul_area not in (select smriecc_area from smriecc)) or
                             (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                 ( select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                        and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                      and ss.sorlcur_program = Pprog )
                                                                        and   cu.sorlcur_pidm = Ppidm
                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                        and   sorlcur_program   = Pprog ) )
                                 )   )
               and k.subj=smrarul_subj_code 
               and k.code=smrarul_crse_numb_low
               and scrsyln_subj_code=smrarul_subj_code 
               and scrsyln_crse_numb=smrarul_crse_numb_low
               and zstpara_mapa_id(+)='MAESTRIAS_BIM' 
               and zstpara_param_id(+)=SORLCUR_program 
               and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
          union
               select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                     case
                      when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                      when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                           else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                    end as per,  ---
                  smrpaap_area as area, ---
                   case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                      case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                             when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                             when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                             when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                             when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                             when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                             when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                             else smralib_area_desc
                       end
                    else smralib_area_desc
                    end  as  nombre_area, ---
                    smrarul_subj_code||smrarul_crse_numb_low as materia, ---
                    scrsyln_long_course_title as nombre_mat, ---
                    null as calif,  ---
                    'PC' ,  ---
                    smracaa_rule as regla, ---
                     null as origen, ---
                     null as fecha, --
                     Ppidm ,
                     Pusu_siu
           from spriden, smrpaap, sgbstdn y, sorlcur so,SZTDTEC, smrarul, smracaa, smralib, stvstst, scrsyln, zstpara,smbagen
               where 1=1
               and spriden_pidm = Ppidm  
               and spriden_change_ind is null
               and   so.sorlcur_pidm= spriden_pidm
               and   so.SORLCUR_LMOD_CODE = 'LEARNER'
               and   so.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                            from sorlcur ss 
                                              where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                and   ss.SORLCUR_LMOD_CODE = 'LEARNER'
                                                and ss.sorlcur_program = Pprog)
               and   smrpaap_program = Pprog
               AND   smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
               and   smrpaap_area=SMBAGEN_AREA
               and   SMBAGEN_ACTIVE_IND='Y'
               and   SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
               and   smrpaap_area=smrarul_area
               and   sgbstdn_pidm=spriden_pidm
               and   so.SORLCUR_program=smrpaap_program
               and   sztdtec_program=so.SORLCUR_program and sztdtec_status='ACTIVO' and  SZTDTEC_CAMP_CODE=so.SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
               and   SZTDTEC_TERM_CODE=so.SORLCUR_TERM_CODE_CTLG
               and   stvstst_code=sgbstdn_stst_code
               and   smralib_area=smrpaap_area
               AND   smracaa_area = smrarul_area
               AND   smracaa_rule = smrarul_key_rule
               AND   SMRARUL_TERM_CODE_EFF = so.SORLCUR_TERM_CODE_CTLG
               and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001' )
               and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR 
                                                                        from ZSTPARA 
                                                                         where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                           and spriden_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
               and   (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj))
                 or  (smrarul_area in (select smriemj_area 
                                        from smriemj
                                          where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from sorlcur cu, sorlfos ss
                                                                     where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                      and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                      and cu.sorlcur_pidm = Ppidm
                                                                      and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                      and SORLFOS_LFST_CODE = 'MAJOR'
                                                                      and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) 
                                                                                               from sorlcur ss
                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                  and ss.sorlcur_program = Pprog)
                                                                      and cu.SORLCUR_TERM_CODE in ( select max(SORLCUR_TERM_CODE) 
                                                                                                    from sorlcur ss
                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                      and ss.sorlcur_program = Pprog)
                                                                      and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                      and   sorlcur_program   =Pprog
                      )  )
                 and smrarul_area not in (select smriecc_area from smriecc)) 
                   or  (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                        ( select distinct SORLFOS_MAJR_CODE
                                                                         from sorlcur cu, sorlfos ss
                                                                         where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                          and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                          and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                      and ss.sorlcur_program = Pprog )
                                                                          and   cu.sorlcur_pidm = Ppidm
                                                                          and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                          and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                          and  SORLCUR_CACT_CODE =SORLFOS_CACT_CODE
                                                                          and   sorlcur_program   = Pprog
                       ) )) )
               and  scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTCKN_SUBJ_CODE,SHRTCKN_CRSE_NUMB  from shrtckn where shrtckn_pidm=Ppidm )
               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRCE_SUBJ_CODE,SHRTRCE_CRSE_NUMB  from SHRTRCE where SHRTRCE_pidm=Ppidm )     --agregado
               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRTK_SUBJ_CODE_INST,SHRTRTK_CRSE_NUMB_INST  from SHRTRTK where SHRTRTK_pidm=Ppidm )  --agregado
               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select ssbsect_subj_code subj, ssbsect_crse_numb code  
                                                                       from  sfrstcr, smrprle, ssbsect, spriden  --agregado para materias EC y aprobadas sin rolar
                                                                       where  smrprle_program = Pprog
                                                                         and  sfrstcr_pidm = Ppidm  
                                                                         and (sfrstcr_grde_code is null or sfrstcr_grde_code is not null)  
                                                                         and sfrstcr_rsts_code='RE'
                                                                         and  spriden_pidm=sfrstcr_pidm 
                                                                         and spriden_change_ind is null
                                                                         and  ssbsect_term_code=sfrstcr_term_code
                                                                         and  ssbsect_crn=sfrstcr_crn )
               and zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=SORLCUR_program and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG;

             commit;
        end; 
  
  
  
          --*********************  segunda parte ***************************
    open avance_n_out
            FOR
         select distinct avance1.materia as materia, 
          avance1.nombre_mat as nombre_mat,
          avance1.calif as calif,
          avance1.per as per, 
          avance1.area as area,
          case when substr(spriden_id,1,2)='08' then ' '
          else
              case when substr(avance1.materia,1,4)='L1HB' then 'MATERIAS INTRODUCTORIAS'
                    when substr(avance1.materia,1,4)='M1HB' then 'MATERIAS INTRODUCTORIAS'
              else upper(avance1.nombre_area)
              end
          end as "nombre_area",
          avance1.ord as ord,
          CASE WHEN avance1.apr = 'AP' THEN NULL ELSE apr END as tipo,
         ----------------------------------------
         case when
              round (( select count(unique materia) 
                    from avance_n x
                 where  apr in ('AP','EQ')
                 and    protocolo = 9999
                 and    pidm_alu = Ppidm
                 and    usuario_siu = Pusu_siu
                 and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                 and    calif not in ('NP','AC')
                 and    ( to_number(calif)  in (select max(to_number(calif)) 
                                                 from avance_n xx
                                                    where x.materia=xx.materia
                                                    and   x.protocolo=xx.protocolo
                                                    and   x.pidm_alu=xx.pidm_alu
                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) 
                     or calif is null)
                 and  ( ( area not in (select smriecc_area from smriecc) 
                 and  area not in (select smriemj_area from smriemj))
                   or   -- VALIDA LA EXITENCIA EN SMAALIB
                      ( area in (select smriemj_area 
                                  from smriemj
                                     where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                        and   cu.sorlcur_pidm = Ppidm
                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                        and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                        and   cu.SORLCUR_SEQNO in ( select max(SORLCUR_SEQNO) 
                                                                                                      from sorlcur ss
                                                                                                        where cu.SORLCUR_PIDM = ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code = ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog)
                                                                       and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program =Pprog)
                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                        and   sorlcur_program   =Pprog
                                                                                           )    )
                     and area not in (select smriecc_area from smriecc)) 
                     or     -- VALIDA LA EXITENCIA EN SMAALIB
                         ( area in (select smriecc_area 
                                      from smriecc 
                                        where smriecc_majr_code_conc in  ( select distinct SORLFOS_MAJR_CODE
                                                                             from  sorlcur cu, sorlfos ss
                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                             where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                               and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                               and ss.sorlcur_program =Pprog )
                                                                                and   cu.sorlcur_pidm=Ppidm
                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                and   sorlcur_program   = Pprog ) 
                                      ) ) )
                      ) *100 /
                      ( select  distinct SMBPGEN_REQ_COURSES_I_TRAD  
                          from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                            where SMBPGEN_program=Pprog
                                and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG 
                                                                from sorlcur
                                                                   where  sorlcur_pidm = Ppidm
                                                                      and sorlcur_program = Pprog 
                                                                      and sorlcur_lmod_code='LEARNER'
                                                                      and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) 
                                                                                             from sorlcur ss
                                                                                               where ss.sorlcur_pidm = Ppidm
                                                                                                 and ss.sorlcur_program = Pprog 
                                                                                                 and ss.sorlcur_lmod_code='LEARNER')))
                  )>100  then 100
             else
                round ( ( select count(unique materia) 
                          from avance_n x
                            where  apr in ('AP','EQ')
                             and    protocolo=9999
                             and    pidm_alu = Ppidm
                             and    usuario_siu = Pusu_siu
                             and    area not in ( select ZSTPARA_PARAM_VALOR 
                                                   from ZSTPARA 
                                                    where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' 
                                                     and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                             and    calif not in ('NP','AC')
                             and    (to_number(calif)  in (select max(to_number(calif)) 
                                                           from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu and CALIF!=0) 
                              Or calif is null)
                         and (  (area not in (select smriecc_area from smriecc) 
                          and area not in (select smriemj_area from smriemj)) 
                         or   -- VALIDA LA EXITENCIA EN SMAALIB
                            ( area in (select smriemj_area 
                                       from smriemj
                                        where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from  sorlcur cu, sorlfos ss
                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                        and   cu.sorlcur_pidm = Ppidm
                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                        and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                        and   cu.SORLCUR_SEQNO in ( select max(SORLCUR_SEQNO) 
                                                                                                     from sorlcur ss
                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog )
                                                                        and   cu.SORLCUR_TERM_CODE in ( select max(SORLCUR_TERM_CODE) 
                                                                                                       from sorlcur ss
                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                          and ss.sorlcur_program = Pprog )
                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                        and   sorlcur_program   = Pprog )    )
                          and area not in (select smriecc_area from smriecc)) 
                            or -- VALIDA LA EXITENCIA EN SMAALIB
                               ( area in (select smriecc_area 
                                           from smriecc 
                                            where smriecc_majr_code_conc in ( select distinct SORLFOS_MAJR_CODE
                                                                               from  sorlcur cu, sorlfos ss
                                                                               where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                             where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                               and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                               and ss.sorlcur_program = Pprog )
                                                                                and  cu.sorlcur_pidm = Ppidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and   SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   = Pprog
                                                                                                 ) ) ) )
                          ) *100 /
                (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  
                  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                    where SMBPGEN_program=Pprog
                     and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG 
                                                   from sorlcur
                                                        where  sorlcur_pidm = Ppidm
                                                           and sorlcur_program = Pprog 
                                                           and sorlcur_lmod_code='LEARNER'
                                                           and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) 
                                                                                from sorlcur ss
                                                                                     where ss.sorlcur_pidm = Ppidm
                                                                                     and ss.sorlcur_program = Pprog 
                                                                                     and ss.sorlcur_lmod_code='LEARNER'))))
         end as avance_curr,
          (SELECT DISTINCT SCBCRSE_CREDIT_HR_LOW
                FROM scbcrse bs
                WHERE (SCBCRSE_SUBJ_CODE || SCBCRSE_CRSE_NUMB) = avance1.materia  ) as creditos
   FROM  spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
        (SELECT 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
           FROM  ( select 9999, per, area, nombre_area, materia, nombre_mat,
                           case when calif='1' then cal_origen
                                when apr='EC' then null
                            else calif
                            end as calif, 
                            apr, 
                            regla, 
                            null as n_area,
                           case when substr(materia,1,2)='L3' then 5
                            else 1
                           end as ord,
                           fecha
              from  sgbstdn y, avance_n x,sorlcur co
                 where  x.protocolo=9999
                    and    sgbstdn_pidm = co.sorlcur_pidm 
                    and    co.sorlcur_program = Pprog
                    and    sgbstdn_pidm      = x.pidm_alu 
                    and    x.pidm_alu = Ppidm
                    and    x.usuario_siu = Pusu_siu
                    and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                    and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                              where x.materia=xx.materia
                              and  x.protocolo=xx.protocolo   ----cambio
                              and  x.pidm_alu=sgbstdn_pidm  ----cambio
                              and  x.pidm_alu=xx.pidm_alu   ---- cambio
                              and  x.usuario_siu=xx.usuario_siu) or calif is null)
           union
                   select distinct 9999, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                   case when calif='1' then cal_origen
                        when apr='EC' then null
                    else calif
                    end as calif, 
                    apr, 
                    regla, 
                    null n_area,
                    case when substr(materia,1,2)='L3' then 5
                    else 1
                    end as ord, 
                    fecha
                    from  sgbstdn y, avance_n x,sorlcur co
                           where   x.protocolo=9999
                            and     sgbstdn_pidm = Ppidm
                            and    x.pidm_alu=sgbstdn_pidm
                            and    co.sorlcur_pidm = Ppidm
                            and     x.usuario_siu = Pusu_siu
                            and     apr='EC'
                            and     co.sorlcur_program = Pprog
                            and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
          union
                    select protocolo, per, area, nombre_area, materia, nombre_mat,
                            case when calif='1' then cal_origen
                                  when apr='EC' then null
                            else calif
                            end as calif, 
                            apr, 
                            regla, 
                            stvmajr_desc as n_area, 
                            2 ord, 
                            fecha
                        from  sgbstdn y, avance_n x, smriemj, stvmajr,sorlcur co
                           where   x.protocolo=9999
                            and     sgbstdn_pidm = Ppidm
                            and     x.pidm_alu=sgbstdn_pidm
                            and     co.sorlcur_pidm = Ppidm
                            and     x.usuario_siu = Pusu_siu
                            and     co.SORLCUR_PROGRAM = Pprog
                            and    area=smriemj_area
                            and smriemj_majr_code= (select distinct SORLFOS_MAJR_CODE
                                                                from  sorlcur cu, sorlfos ss
                                                                where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                and   cu.sorlcur_pidm = Ppidm
                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                              and ss.sorlcur_program = Pprog)
                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                  and ss.sorlcur_program = Pprog)
                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                and   sorlcur_program   = Pprog
                                                              )
                           and    area not in (select smriecc_area from smriecc)
                           and    smriemj_majr_code=stvmajr_code
                           and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                  where x.materia=xx.materia
                                  and   x.protocolo=xx.protocolo
                                  and   x.pidm_alu=xx.pidm_alu
                                  and   x.usuario_siu=xx.usuario_siu) or calif is null)
        union
              select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                    case when calif='1' then cal_origen
                         when apr='EC' then null
                     else calif
                    end as calif, 
                    apr, 
                    regla, 
                    smralib_area_desc as n_area, 
                    3 ord, 
                    fecha
                from sgbstdn y, avance_n x ,smralib, smriecc a,sorlcur co
                   where  x.protocolo=9999
                        and   sgbstdn_pidm = Ppidm
                        and   co.sorlcur_pidm = Ppidm
                        and   x.pidm_alu=sgbstdn_pidm
                        and   x.usuario_siu = Pusu_siu
                        and   co.SORLCUR_PROGRAM = Pprog
                        and    area=smralib_area
                        and    area=smriecc_area
                        and     smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                           from  sorlcur cu, sorlfos ss
                                                           where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                            and   cu.sorlcur_pidm = Ppidm
                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                            and   sorlcur_program   = Pprog
                                                             )
                       and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                              where x.materia=xx.materia
                              and   x.protocolo=xx.protocolo
                              and   x.pidm_alu=xx.pidm_alu
                              and   x.usuario_siu=xx.usuario_siu) or calif is null)
                       and    (fecha in (select distinct fecha from avance_n xx
                              where x.materia=xx.materia
                              and   x.protocolo=xx.protocolo
                              and   x.pidm_alu=xx.pidm_alu
                              and   x.usuario_siu=xx.usuario_siu) or fecha is null)
            order by   n_area desc, per, nombre_area,regla
       )
     GROUP BY 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
      )  avance1
       where 1=1
       and  spriden_pidm = Ppidm
        and   so.sorlcur_pidm = spriden_pidm
        and   so.SORLCUR_LMOD_CODE = 'LEARNER'
        and   so.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                   and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                     and  ss.SORLCUR_LMOD_CODE = 'LEARNER'
                                     and ss.sorlcur_program = Pprog)
        and     spriden_change_ind is null
        and     sgbstdn_pidm=spriden_pidm
        and     so.SORLCUR_PROGRAM = Pprog
        and     sztdtec_program = so.SORLCUR_PROGRAM
        and     sztdtec_status='ACTIVO'
        and     SZTDTEC_CAMP_CODE=so.SORLCUR_CAMP_CODE
        and     SZTDTEC_TERM_CODE=so.SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
        and     sgbstdn_stst_code=stvstst_code
   order by  avance1.per;
        
   
   
   END IF;

   RETURN (avance_n_out);

 END F_AVCU_OUT;


PROCEDURE P_CRED_AUTO (ppidm number default null ) IS

vsalida VARCHAR2(200);
-- anonimo para proceso que busque a los alumnos de nuevo ingreso para enviarles su credencia digital x mail.
--proyecto credenciales costo cero glovicx 29.05.2024

vetiquetaok  VARCHAR2(4):= 'CRED';
VCODE        varchar2(4) :='CRED';
vfoto          varchar2(1):= 'N';
VFOLIO_DOCTO   varchar2(20);
vl_existe      number:=0;
VSECUENCIA     VARCHAR2 (50);
squery         VARCHAR2 (70);
squery2        VARCHAR2 (50);
VSEC_FOLIO     SZTQRDG.SZT_SEQ_FOLIO%TYPE;
VSEC_FOLIO2    VARCHAR2 (10);
VSEQNO         number:= 100;
VREG_INSERTA    number:= 0;
VNO_RVOE        VARCHAR2 (30);
VFECHA_RVOE     VARCHAR2 (30);
val_prog        number:= 0;
vnom_prog       VARCHAR2 (80);

begin
---- primero sacamos los alumnos del universo
FOR jump in (select distinct T.pidm, T.campus, T.nivel, T.programa,sp, T.CTLG
                from tztprog t
                where 1=1
                and T.SGBSTDN_STYP_CODE = 'N'
                and T.PIDM   = NVL(ppidm,T.PIDM )
                and trunc(T.FECHA_PRIMERA) >= ('01/07/2024') -- fecha de inicio en prod
                AND  T.pidm  NOT IN (SELECT SZT_PIDM
                                      FROM SZTQRDG
                                       WHERE 1=1
                                        AND SZT_DATA_ORIGIN= 'CRED_QRAUTO'
                                        AND SZT_CODE_ACCESORIO = 'CRED'
                                        AND SZT_PIDM           = T.pidm)
                and rownum < 20
               ) LOOP


--- primero validamos que el alumno tenga el código de la foto 
       begin
          select distinct ('Y')
             INTO vfoto
                from SARCHKL sk
                where 1=1
                and SK.SARCHKL_PIDM  = jump.pidm
                and sk.SARCHKL_ADMR_CODE in ('FESD',  'FOCD')
                and sk.SARCHKL_CKST_CODE = 'VALIDADO';

       exception when others then
        vfoto := 'N';
       
       end;
       
 IF vfoto = 'Y'  THEN
     -- primero validamos que ese alumno tenga su etiqueta en GORADID--TIIN-- hay que vincular con un poarametrizador code serv vs etiqueta vs code detalle
     ----NO LLEVA GORADID BORRAR TODA ESTA SECCION PARA PROD
        
     /*
              Begin
                        Select count(1)
                            Into vl_existe
                            from GENERAL.GORADID
                        Where GORADID_PIDM = JUMP.PIDM
                        And GORADID_ADID_CODE  = vetiquetaok;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;

               dbms_output.put_line('Antes del insert goradid:  '|| vl_existe||'-'||JUMP.PIDM||'-'||vetiquetaok );

          If vl_existe =0 then

                         begin
                            insert into GORADID values(JUMP.PIDM,vetiquetaok, vetiquetaok, 'CREDQR_AUTO', sysdate, VCODE,null, 0,null);
                         Exception
                         When others then
                         vsalida:='Error al insertar Etiqueta'||sqlerrm;
                         dbms_output.put_line(vsalida );
                         
                         end;
                         
           END IF;
     */     
          ---SE OBTIENE LA SECUENCIA DEPENDIENDO DEL CODIGO

         BEGIN
            SELECT ZSTPARA_PARAM_VALOR
              INTO VSECUENCIA
              FROM ZSTPARA
             WHERE     1 = 1
                   AND ZSTPARA_MAPA_ID = 'CODIGOQR'
                   AND ZSTPARA_PARAM_ID = VCODE;
         EXCEPTION
            WHEN OTHERS
            THEN
               VSECUENCIA := NULL;
         END;
          ----PRIMERO CALCULAMOS EL CONSECUTIVO-- PARA ESTE TIPO

         squery := 'SELECT ' || VSECUENCIA;
         squery2 := squery || ' FROM DUAL';

          dbms_output.put_line('salida_SECUENCIA..>>>>'||squery2);



         EXECUTE IMMEDIATE (squery2) INTO VSEC_FOLIO;

         --dbms_output.put_line('salida..SEQ.>>>>'||JUMP.CODE_ACC||'---'|| VSEC_FOLIO|| ' MATERIA '|| trim(VMATERIA));



         BEGIN
         
            IF LENGTH (VSEC_FOLIO) < 2
            THEN
               VSEC_FOLIO2 := LPAD (VSEC_FOLIO, 2, '0');
            --'uno'
            ELSE
               VSEC_FOLIO2 := VSEC_FOLIO;
            --'dos'
            END IF;
         
         EXCEPTION WHEN OTHERS THEN
         
               NULL;
         END;


         VFOLIO_DOCTO := SUBSTR (VCODE, 1, 3) || TO_CHAR (SYSDATE, 'YYYY')|| '/'|| VSEC_FOLIO2;
       
                ---- aqui va insertar en QRDI
              
            ------ se insertan los alumnos en la tabla QR
         BEGIN
            INSERT INTO SZTQRDG (SZT_PIDM,
                                 SZT_PROGRAMA,
                                 SZT_FOLIO_DOCTO,
                                 SZT_SEQNO_SIU,
                                 SZT_CODE_ACCESORIO,
                                 SZT_ENVIO_ALUMNO,
                                 SZT_FECHA_ENVIO,
                                 SZT_ACTIVITY_DATE,
                                 SZT_USER,
                                 SZT_DATA_ORIGIN,
                                 SZT_SEQ_FOLIO
                                 )
                 VALUES (
                           JUMP.PIDM,
                           JUMP.PROGRAMA,
                           VFOLIO_DOCTO,  --folio_docto
                           VSEQNO+VSEC_FOLIO2, --SZT_SEQNO_SIU SE ARMO ESTA SEC POR QUE NO HAY COMPRA 
                           VCODE,
                           5,     --ENVIO_ALUMNO,SE PONE 5 PARA QUE CATY LAS PUEDA IDENTIFICAR QUE SON GRATIS
                           REPLACE ( TO_CHAR (SYSDATE, 'DD-MONTH-yyyy')|| '-'|| TO_CHAR (SYSDATE, 'HH24:MI:SS'),' ',''), --fecha envio
                           REPLACE ( TO_CHAR (SYSDATE, 'DD-MONTH-yyyy')|| '-'|| TO_CHAR (SYSDATE, 'HH24:MI:SS'),' ',''), --activity date
                           USER,           --SZT_USER,
                           'CRED_QRAUTO',   --SZT_DATA_ORIGIN
                           VSEC_FOLIO2
                            );

            VREG_INSERTA := SQL%ROWCOUNT;
         EXCEPTION WHEN OTHERS THEN
               NULL;
               
         END;
     
         ------- CALCULA NO RVOE--
         BEGIN
            SELECT DISTINCT
                   NVL (zt.SZTDTEC_NUM_RVOE, '000000') AS numrvoe,
                   --TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'YYYY-MM-DD')   AS fech_rvoe
                   TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'DD-Month-yyyy'),
                   ZT.SZTDTEC_PROGRAMA_COMP
                INTO VNO_RVOE,
                   VFECHA_RVOE,
                   vnom_prog
              FROM SZTDTEC zt
                WHERE     1 = 1
                   AND zt.SZTDTEC_CAMP_CODE = JUMP.CAMPUS
                   AND zt.SZTDTEC_PROGRAM = JUMP.PROGRAMA
                   AND zt.SZTDTEC_TERM_CODE = JUMP.CTLG;
         EXCEPTION
            WHEN OTHERS
            THEN
               VNO_RVOE := NULL;
               VFECHA_RVOE := NULL;
               
         END;

     
     
        BEGIN
            SELECT 1
              INTO val_prog
              FROM datos_qr QR
             WHERE 1 = 1 
              AND QR.CVE_PROG = JUMP.PROGRAMA;
         EXCEPTION
            WHEN OTHERS
            THEN
               val_prog := 0;
         END;

         BEGIN
            IF val_prog = 0
            THEN
               INSERT INTO datos_qr
                    VALUES (JUMP.PROGRAMA,VNO_RVOE,REPLACE (VFECHA_RVOE, ' ', ''),vnom_prog);
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;



   COMMIT;

     
     
          
  ELSE
  
   DBMS_OUTPUT.PUT_LINE('NO CUMPLE CON EL DOCUMENTO FOTO: FESD,FOCD VALIDO '   ); 
   
 END IF;      





END LOOP;

EXCEPTION WHEN OTHERS THEN 

vsalida:='Error general del proceso p_automatic '||sqlerrm;

DBMS_OUTPUT.PUT_LINE('ERROR GRAL: '|| vsalida );
 

END P_CRED_AUTO;


procedure P_AUTOMATIC (ppidm number default null ) is



---- anonimo para convertirlo en funcion para recuperar el universo de estudiantes que cumplen con las materias de DPLO
--  este flujo es automatico se va ejecutar mediante un job y va ir insertando en la tabla de QRDI a los alumnos que vayan cumpliendo
--  created by glovicx 15.05. 2024



vcursor       SYS_REFCURSOR;
vvalor1       varchar2(200):='XX';
vserv4        varchar2(8):='XX';
VCODE                VARCHAR2(10):= 'DPLO';
VETIQUETA            varchar2(6):='NA';
vestatus              varchar2(1):='Y';
vmateriasOK           varchar2(200);
vdiplomaok            varchar2(300);
vetiquetaok           varchar2(6);
vsalida               varchar2(300):= 'EXITO';
VMAIL                 varchar2(80);  
VDESCRPT              VARCHAR2(90);
VAVANCE               VARCHAR2(10);
VFOLIO_DOCTO          VARCHAR2(30);
VSTATUS_ENVIO         VARCHAR2(9);
VFECHA_ENVIO_CAP      VARCHAR2(20);      
VNO_RVOE              NUMBER;
VNO_MATERIAS_ACRED   VARCHAR2(9);
VNO_MATERIAS_TOTAL   VARCHAR2(9);
VSEC_FOLIO           NUMBER;
VCICLO               VARCHAR2(10);
VCICLO_INI           VARCHAR2(10);
VCICLO_FIN           VARCHAR2(10);
vtalleres            VARCHAR2(10);
VSEM_ACTUAL          VARCHAR2(20);
VPROM_ANTE           VARCHAR2(10);
VPROMEDIO            VARCHAR2(10);
vinicio2             VARCHAR2 (18);
vfin2                VARCHAR2 (18);
VSECUENCIA           VARCHAR2 (28);
squery               VARCHAR2 (70);
squery2              VARCHAR2 (50);
VSEC_FOLIO2          VARCHAR2 (20);
Vciclo_gtlg          VARCHAR2 (20);
VSESO                NUMBER := 0;               
vvalidaQR            varchar2(1):='N';
vl_existe            NUMBER := 0;

begin

--dbms_output.put_line('ainicio p_automatic  '|| ppidm );
----- calculamos el universo de alumnos que son candidatos a este flujo
FOR jump in ( select t1.pidm vpidm, t1.estatus vestatus, t1.campus vcampus, t1.nivel vnivel, t1.programa vprograma, t1.sp,ctlg vctlg
                from TZTPROG  t1
                where 1=1 
                AND T1.PIDM = nvl(ppidm,T1.PIDM)
                and t1.ESTATUS = 'MA'
                and t1.FECHA_PRIMERA >= ('01/10/2023')
                and t1.programa in ( select distinct dt.SZTDTEC_PROGRAM
                                        from sztdtec dt
                                        where 1=1
                                          and dt.SZTDTEC_NUM_RVOE in (select distinct dg.SZT_RVOE
                                                                        from SZTDIGR dg
                                                                          where 1=1) )
               --AND ROWNUM < 5000
                                                           
 ) LOOP
     
     IF vcursor%ISOPEN THEN
           CLOSE vcursor;
       END IF;  
         
 
     --DBMS_OUTPUT.PUT_LINE('INICIO CURSOR UNIVERSO:  '||  JUMP.vpidm||'-'|| JUMP.vestatus||'-'|| JUMP.vcampus||'-'|| JUMP.vnivel||'-'|| JUMP.vprograma||'-'|| JUMP.sp||'-'|| JUMP.vctlg  );
  ---aqui buscamos por alumno cuantos cursos tiene disponibles para insertar en QRDI
    begin
            vcursor :=  BANINST1.PKG_SERV_SIU.F_CURSO_DPLO  (jump.vPIDM , jump.vprograma , 'QR_MASIV2'  ); 
       
      LOOP
      vetiquetaok := '';
      vmateriasOK := '';
      vdiplomaok  := '';
      vvalor1     := '';
      vl_existe   := 0;
      
      
           
           FETCH vcursor
          
            INTO vetiquetaok,vvalor1;     ---F_CURSO_DPLO
          
            EXIT WHEN vcursor%NOTFOUND;
          
        
         
        IF vvalor1 = 'ERROR'  then 
       --- quiere decir que NO hay ningun curso x insertar
        null;
            --DBMS_OUTPUT.PUT_LINE('NO ENCONTRO DIPLOS');
       ELSE
         ---- se realizan todos los calculos de las variables para el insert
         
         -----OBTENER TOTAL DE MATERIAS-- Y PROMEDIO ACTUAL
          begin 
            VNO_MATERIAS_TOTAL :=  BANINST1.PKG_DATOS_ACADEMICOS.TOTAL_MATE2 (JUMP.VPIDM, JUMP.VPROGRAMA);
             VPROMEDIO := BANINST1.PKG_DATOS_ACADEMICOS.promedio1 (JUMP.VPIDM, JUMP.VPROGRAMA);
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
                                  AND f.SFRSTCR_PIDM = JUMP.VPIDM
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
         EXCEPTION  WHEN OTHERS THEN
               VCICLO := NULL;
               vinicio2 := NULL;
           --  DBMS_OUTPUT.PUT_LINE ('ERROR1 EN FECHAS INICIO ' || JUMP.VPIDM || '--' || SQLERRM);
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
                                  AND f.SFRSTCR_PIDM = JUMP.VPIDM
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
          EXCEPTION  WHEN OTHERS THEN
               VCICLO := NULL;
               vfin2 := NULL;
            -- DBMS_OUTPUT.PUT_LINE ('ERROR1 EN MATERIAS ' || JUMP.VPIDM || '--' || SQLERRM);
         END;

       

            BEGIN
               SELECT DISTINCT TO_CHAR (STVTERM_END_DATE, 'DD-Month-yyyy')
                 -- to_char (STVTERM_START_DATE,'DD-Month-yyyy')
                 INTO VCICLO_FIN
                 FROM stvterm v
                WHERE 1 = 1 AND STVTERM_CODE = VCICLO;
            EXCEPTION  WHEN OTHERS THEN
                  -- VCICLO_INI  := null;
                  VCICLO_FIN := NULL;
            END;
        

         ------OBTIENE EL AVANCE CURRICULAR ---nueva forma glovicx 25.01.23


           Begin
                  SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 (JUMP.VPIDM, JUMP.VPROGRAMA)
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
                  SELECT BANINST1.PKG_DATOS_ACADEMICOS.acreditadas1 (JUMP.VPIDM, JUMP.VPROGRAMA)
                    INTO VNO_MATERIAS_ACRED
                    FROM DUAL;
               --   DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
         EXCEPTION  WHEN OTHERS  THEN
                     VNO_MATERIAS_ACRED := 0;
         END;


         ---SE OBTIENE LA SECUENCIA DEPENDIENDO DEL CODIGO

         BEGIN
            SELECT ZSTPARA_PARAM_VALOR
              INTO VSECUENCIA
              FROM ZSTPARA
             WHERE     1 = 1
                   AND ZSTPARA_MAPA_ID = 'CODIGOQR'
                   AND ZSTPARA_PARAM_ID = VCODE;
         EXCEPTION  WHEN OTHERS   THEN
               VSECUENCIA := NULL;
         END;

       
         squery := 'SELECT ' || VSECUENCIA;
         squery2 := squery || ' FROM DUAL';

          --dbms_output.put_line('salida_SECUENCIA..>>>>'||squery2);



         EXECUTE IMMEDIATE (squery2) INTO VSEC_FOLIO;

         



         BEGIN
            IF LENGTH (VSEC_FOLIO) < 2
            THEN
               VSEC_FOLIO2 := LPAD (VSEC_FOLIO, 2, '0');
            --'uno'
            ELSE
               VSEC_FOLIO2 := VSEC_FOLIO;
            --'dos'
            END IF;
         EXCEPTION  WHEN OTHERS  THEN
               NULL;
         END;


        VFOLIO_DOCTO := SUBSTR (VCODE, 1, 3) || TO_CHAR (SYSDATE, 'YYYY')|| '/'|| VSEC_FOLIO2;

         --DBMS_OUTPUT.put_line (  'salida..FOLIO.>>>>' || VFOLIO_DOCTO || '--' || Vciclo_gtlg);

         --END IF;


         ------CALCULA NUM DE TALLERES--

         BEGIN
            SELECT DISTINCT SMBPGEN_MAX_COURSES_I_NONTRAD
              INTO vtalleres
              FROM SMBPGEN
             WHERE     1 = 1
                   AND SMBPGEN_PROGRAM = JUMP.VPROGRAMA
                   AND SMBPGEN_ACTIVE_IND = 'Y'
                   AND SMBPGEN_TERM_CODE_EFF = JUMP.vctlg;
         EXCEPTION  WHEN OTHERS  THEN
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
                   AND SMRPCMT_PROGRAM = JUMP.VPROGRAMA;
         EXCEPTION  WHEN OTHERS  THEN
               VSESO := 0;
         END;

          -- dbms_output.put_line('salida talleres y SESO '|| JUMP.vctlg  );

         ------- CALCULA NO RVOE--
         BEGIN
            SELECT DISTINCT
                   zt.SZTDTEC_NUM_RVOE AS numrvoe
                   INTO VNO_RVOE
              FROM SZTDTEC zt
             WHERE     1 = 1
                   AND zt.SZTDTEC_CAMP_CODE = jump.vcampus
                   AND zt.SZTDTEC_PROGRAM = JUMP.VPROGRAMA
                   AND zt.SZTDTEC_TERM_CODE = JUMP.vctlg;
         EXCEPTION
            WHEN OTHERS
            THEN
               VNO_RVOE := NULL;
               
            -- dbms_output.put_line('ERROR AL CALCULAR RVOE '|| JUMP.vctlg||'-'|| SQLERRM  );
         END;




         ----se ejecuta la funcion para saber en que cuatrimestre se encuentra
         VSEM_ACTUAL := BANINST1.PKG_QR_DIG.F_curso_actual (JUMP.VPIDM,JUMP.VPROGRAMA, jump.vnivel,jump.vcampus);


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
                     AND f1.SFRSTCR_PIDM = JUMP.VPIDM
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


         IF jump.vnivel IN ('MA', 'MS', 'DO')
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
                                          AND SFRSTCR_PIDM = JUMP.VPIDM
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
                                                AND SFRSTCR_PIDM = JUMP.VPIDM
                                                AND f.SFRSTCR_GRDE_CODE NOT IN ('NA', 'NP', 'AC')
                                                AND f.SFRSTCR_GRDE_CODE IS NOT NULL
                                                AND f.SFRSTCR_GRDE_CODE != '5.0'
                                                AND SUBSTR (F.SFRSTCR_TERM_CODE, 5, 1) NOT IN (8, 9)
                                                AND (SFRSTCR_TERM_CODE,SFRSTCR_PTRM_CODE) IN
                                                       (  SELECT DISTINCT MAX ( f2.SFRSTCR_TERM_CODE),f2.SFRSTCR_PTRM_CODE
                                                            FROM SFRSTCR f2
                                                           WHERE     1 = 1
                                                                 AND f2.SFRSTCR_PIDM = JUMP.VPIDM
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



         BEGIN
            SELECT TO_CHAR (vinicio2, 'dd/mm/yyyy') INTO vinicio2 FROM DUAL;

           -- DBMS_OUTPUT.PUT_LINE ('dentro feca ini -- ' || vinicio2);
         EXCEPTION
            WHEN OTHERS
            THEN
               vinicio2 := vinicio2;
         END;

        


         --SI ES YES ENTONCES HAY QUE CAMBIAR ALGUNOS DATOS A INGLES SOLO PARA COES GLOVICX 07.09.022
                -----SON CAMPUS EN ESPAÑOL
            VCICLO_INI := REPLACE (TRIM (VCICLO_INI), ' ', '');
            VCICLO_FIN := REPLACE (TRIM (VCICLO_FIN), ' ', '');

            IF VPROM_ANTE IS NULL
            THEN
               VPROM_ANTE := 'en curso';
            END IF;
               
              BEGIN
                 SELECT   DISTINCT  GOREMAL_EMAIL_ADDRESS
                      INTO VMAIL
                       FROM GOREMAL
                         WHERE     GOREMAL_PIDM = JUMP.VPIDM
                           AND GOREMAL_STATUS_IND  = 'A'
                             AND GOREMAL_EMAL_CODE = 'PRIN';
             EXCEPTION  WHEN OTHERS  THEN
              vsalida  := sqlerrm;       
             
             END;
           
          --- aqupi tenemos que crear un cursor por que existen   
            BEGIN
             
              select distinct  w1.VALOR5
                INTO vdiplomaok
                 from twpasow w1
                  where 1=1
                    and w1.valor1 = to_char(JUMP.VPIDM)
                    and w1.valor4 = VCODE
                    and w1.VALOR2 = vetiquetaok
                    and w1.valor3  = (select min (w2.valor3)  from twpasow w2
                                        where 1=1
                                          and  w1.valor1 = w2.valor1
                                          and  w1.VALOR2  = w2.valor2  )
                    ;       
            
            exception when others then
              vdiplomaok := null;
              
              --dbms_output.put_line('error en sacar el nombre del diplomado:  '||JUMP.VPIDM||'-'||VCODE||'-'||vetiquetaok||'-'|| sqlerrm );
              
              
            END;
            
            
            begin
                            
                select  g.SZT_MATERIAS_REQ
                   INTO vmateriasok 
                     from  SZTDIGR g
                      where 1=1
                       and g.SZT_ETIQUETA = vetiquetaok
                       and g.SZT_RVOE     = VNO_RVOE
                       and g.SZT_SEQ      = (select min  (G2.SZT_SEQ) 
                                               from SZTDIGR g2
                                                 where 1=1 
                                                    and g2.SZT_ETIQUETA = g.SZT_ETIQUETA
                                                    and  g2.SZT_RVOE    = g.SZT_RVOE )
                           --and g.SZT_DIPLOMA  = vdiplomaok 
                        ;
              
            EXCEPTION  WHEN OTHERS  THEN
               vmateriasok := null;
              -- dbms_output.put_line('error en sacarlas materias:  '||JUMP.VPIDM||'-'||VNO_RVOE||'-'||vetiquetaok||'-'|| sqlerrm );
              
            END;
             
             
         --dbms_output.put_line(' despuyes de materias y etiquetas:  '||JUMP.VPIDM||'-'||  VNO_RVOE||'-'||vetiquetaok||'-'||vdiplomaok||'->'|| vmateriasok   );
             
              
         --dbms_output.put_line(' ANTES DE INSERTAR EN QRDI :  '||JUMP.VPIDM||'-'|| JUMP.VPROGRAMA||'-'||VAVANCE||'-'||VPROMEDIO||'-'||VFOLIO_DOCTO||'-'|| VCODE||'-'||
           --                        VSTATUS_ENVIO||'-'|| VFECHA_ENVIO_CAP||'-'||VNO_MATERIAS_ACRED||'-'||VNO_MATERIAS_TOTAL||'-'|| VSEC_FOLIO||'-'||VCICLO||'-'|| VCICLO_INI||'-'||
             --                      VCICLO_FIN||'-'||vtalleres||'-'||VSEM_ACTUAL||'-'||VPROM_ANTE||'-'||VETIQUETAOK||'-'|| VDIPLOMAOK||'-'||VMAIL||'-'|| vmateriasok||'-'|| 
               --                    vserv4||'-'||vvalor1 );
       
        -- primero validamos que no exista ya el registro x diploma
            begin
                                 
                select 'Y'
                  INTO vvalidaQR           
                    from SZTQRDI d
                    where 1=1
                    and d.SZTQRDI_PIDM = JUMP.VPIDM
                    and d.SZTQRDI_ETIQUETA = vetiquetaok
                    and d.SZTQRDI_CODE_ACCESORIO  =  VCODE 
                   -- and d.SZTQRDI_DIPLOMA    = vdiplomaok
               UNION     
                 select 'Y'
                    from SZTQRON n 
                    where 1=1
                    and n.SZTQRON_PIDM = JUMP.VPIDM
                    and n.SZTQRON_ETIQUETA = vetiquetaok
                    and n.SZTQRON_CODE_ACCESORIO  =  VCODE
                   -- and n.SZTQRON_DIPLOMA    = vdiplomaok
                     ;

            exception when others then 
             vvalidaQR := 'N';
             vsalida := 'El registro ya existe en QRDI '||JUMP.VPIDM ||'-'|| vetiquetaok  ;
            end;
                -- primero validamos que ese alumno tenga su etiqueta en GORADID--TIIN-- hay que vincular con un poarametrizador code serv vs etiqueta vs code detalle
                 Begin
                        Select count(1)
                            Into vl_existe
                            from GENERAL.GORADID
                        Where GORADID_PIDM = JUMP.VPIDM
                        And GORADID_ADID_CODE  = vetiquetaok;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;

               --dbms_output.put_line('Antes del insert goradid:  '|| vl_existe||'-'||vetiquetaok||'-'||vetiquetaok );

          If vl_existe =0 then

                         begin
                            insert into GORADID values(JUMP.VPIDM,vetiquetaok, vetiquetaok, 'QR_AUTO', sysdate, VCODE,null, 0,null);
                         Exception
                         When others then
                         vsalida:='Error al insertar Etiqueta'||sqlerrm;
                         end;
                         
           END IF;
           
                ---- aqui va insertar en QRDI
             IF vvalidaQR = 'N' then 
                
                begin
                     inserT  into SZTQRDI
                               (SZTQRDI_PIDM,
                                SZTQRDI_PROGRAMA,
                                SZTQRDI_AVANCE,
                                SZTQRDI_PROMEDIO,
                                SZTQRDI_FOLIO_DOCTO,
                                SZTQRDI_SEQNO_SIU,
                                SZTQRDI_CODE_ACCESORIO,
                                SZTQRDI_ENVIO_ALUMNO,
                                SZTQRDI_FECHA_ENVIO,
                                SZTQRDI_ACTIVITY_DATE,
                                SZTQRDI_NO_MATERIAS_ACRED,
                                SZTQRDI_NO_MATERIAS_TOTAL,
                                SZTQRDI_USER,
                                SZTQRDI_DATA_ORIGIN,
                                SZTQRDI_SEQ_FOLIO,
                                SZTQRDI_CICLO_CURSA,
                                SZTQRDI_FECHAS_CICLO_INI,
                                SZTQRDI_FECHAS_CICLO_FIN,
                                SZTQRDI_TALLERES,
                                SZTQRDI_PERIODO_ACT,
                                SZTQRDI_PROM_ANTERIOR,
                                SZTQRDI_ETIQUETA,
                                SZTQRDI_DIPLOMA,
                                SZTQRDI_MAIL,
                                SZTQRDI_MATERIAS_REQ
                                 )
                         VALUES (  JUMP.VPIDM,
                                   JUMP.VPROGRAMA,
                                   VAVANCE,
                                   REPLACE (TO_CHAR (TRIM (VPROMEDIO), 99.99),' ',''),
                                   VFOLIO_DOCTO,
                                   null, --VSEQNO,
                                   vCODE,
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
                                   'QRDI_JOB',                     --SZT_DATA_ORIGIN
                                   VSEC_FOLIO,
                                   VCICLO,
                                   VCICLO_INI,
                                   VCICLO_FIN,
                                   --'luis.aguilar@utel.edu.mx', --v_email_alumno,   HAY QUE QUITAR EL MAIL DE LUIS Y DEJAR ALUMNO
                                   --VNOM_PROGRAMA,
                                   vtalleres,
                                   VSEM_ACTUAL, 
                                   --upper(Vcorreponda),
                                   --upper(VCARGO),
                                   --upper(VINSTITUTO)
                                   VPROM_ANTE,
                                   VETIQUETAOK,
                                   VDIPLOMAOK,
                                   VMAIL,
                                   vmateriasok  
                                     );
                
                
                exception when others then
                
                vsalida := sqlerrm;
                dbms_output.put_line(' error al insertar el regs- ' ||sqlerrm );
                end;
                
                     IF vcursor%ISOPEN THEN
                       CLOSE vcursor;
                     END IF;  
                    
                
             end if; 
               
       END IF;
      
      
       COMMIT;
         IF vcursor%ISOPEN THEN
           CLOSE vcursor;
         END IF;  
        
      end loop;
   
        
   
         IF vcursor%ISOPEN THEN
           CLOSE vcursor;
         END IF;  
         
          
        
      exception when others then
      null;
       dbms_output.put_line(' error en fase de dplo cursor- ' ||sqlerrm );
      end;


 --dbms_output.put_line(' AL -FINALIZAR proceso  ' ||vsalida  );
COMMIT;
END LOOP;


COMMIT;
EXCEPTION WHEN OTHERS THEN 

vsalida:=': proceso p_automatic '||sqlerrm;
dbms_output.put_line(' ERROR GRAL ' ||vsalida  );

end p_automatic;


FUNCTION F_MET_SS RETURN SYS_REFCURSOR  IS
---FUNCION QUE SE USA PARA UNA DE LAS PREGUNTAS PARA ADQUIRIR EL SERVICIO SOCIAL DESDE EL AUTOSERVICIO     
--  ESTA FUNCIÓN LA CONSUME PYTHON PARA PRESENTAR LAS OPCIONES DE ENVIO EL Método de entrega GLOVICX 15.11.2024 PROYECTO 
-- DOCUMENTOS QR_SS

cur_salida  SYS_REFCURSOR;
VSALIDA   VARCHAR2(400);


BEGIN

 open cur_salida  FOR  
        select ZSTPARA_PARAM_ID,  ZSTPARA_PARAM_DESC
            from ZSTPARA
            where 1=1
            AND ZSTPARA_MAPA_ID = 'MET_SS';
            
  
 RETURN cur_salida;

exception when others then
VSALIDA := SQLERRM;

dbms_output.put_line('Error general funcion f_MET_SS  '|| VSALIDA );


END F_MET_SS;


FUNCTION F_MODALIDAD_SS RETURN SYS_REFCURSOR  IS
---FUNCION QUE SE USA PARA UNA DE LAS PREGUNTAS PARA ADQUIRIR EL SERVICIO SOCIAL DESDE EL AUTOSERVICIO     
--  ESTA FUNCIÓN LA CONSUME PYTHON PARA PRESENTAR LAS OPCIONES DE ENVIO EL Método de entrega GLOVICX 15.11.2024 PROYECTO 
-- DOCUMENTOS QR_SS

cur_salida  SYS_REFCURSOR;
VSALIDA   VARCHAR2(400);


BEGIN

 open cur_salida  FOR  
        select ZSTPARA_PARAM_ID,  ZSTPARA_PARAM_DESC
            from ZSTPARA
            where 1=1
            AND ZSTPARA_MAPA_ID = 'MODALIDAD_SS';
            
  
 RETURN cur_salida;

exception when others then
VSALIDA := SQLERRM;

dbms_output.put_line('Error general funcion f_MET_SS  '|| VSALIDA );


END F_MODALIDAD_SS;


PROCEDURE P_UNIVERSO_SS  (ppidm NUMBER) IS

/* --PROYECTO bETZY FLUJO COMPLERTO SS  GLOVICX 20.11.2024
--- ESTE ES LA 1RA PARTE DEL FLUJO DESPUES SIGUE LA PARTE DE MALU CUANDO YA LO PUEDEN ADQUIRIR EN EL AUTO SERVICIO
Lógica 
Función (Alumnos y Egresados, Campus UTL 01, nivel Licenciatura, 70% de avance curricular o mayor y documentos

  INSERTAR Etiquetar  AUSS  GORADIS
 
 INSERTAR EN LA NUEVA Tabla (PIDM, código de programa, periodo de catálogo, fecha de envío de mail, ACTIVITY_DATE, 2 campos adicionales Phyton y Oracle) 
Validación en la tabla (llave primaria, PIDM, programa, catálogo de periodo) si es igual no se inserta y si es diferente se inserta 

 Te comparto el agrupador configurado en SEED SERVICIO_SOC  ETIQUETA SERVICIO SOCIAL.

------
crear un p_universo_ss   donde se ontengan todos los alumnos con las condiones mencionadas
*/

P_ADID_ID   varchar2(6):= 'AUSS';
vl_existe   NUMBER:= 0;    
vsalida     VARCHAR2(300):= 'EXITO';
VAVANCE     NUMBER:= 0;
vdocto       varchar2(100):= 'EXITO';
VCONTA_DOC    NUMBER:= 0;
VCONTA_NODOC  NUMBER:= 0;

BEGIN
------ aqui sacamos el universo de alumnos con los filtro del ss
FOR jump in ( select distinct T.pidm PIDM,  T.programa PROGRAMA, sp, T.CTLG , t.campus, t.nivel
                from tztprog t
                where 1=1
                and T.ESTATUS  in ('MA','EG')
                AND T.campus  = 'UTL'
                and T.nivel   = 'LI'
                and T.PIDM   = NVL(ppidm,T.PIDM )
                --and trunc(T.FECHA_PRIMERA) >= ('01/07/2024') -- fecha de inicio en prod
                AND  T.pidm  NOT IN (SELECT SZT_PIDM
                                       FROM SZTAUSS AU
                                        WHERE 1=1
                                         AND AU.SZT_PIDM  = T.pidm
                                         AND AU.SZT_PROGRAMA  = T.programa
                                         AND AU.SZT_TERM_CTLG =  T.CTLG
                                        )
                --and rownum < 3
               ) LOOP
             
             VCONTA_DOC  := 0;  -- INICIAMOS VARIABLE
             dbms_output.put_line('inicios de proceso ss '||ppidm);  
            --- primero validamos que cumpla con los documentos en el parametrizador 
            for onn in ( SELECT ZSTPARA_PARAM_VALOR documento, ZSTPARA_PARAM_DESC estatus
                            FROM zstpara
                            WHERE 1=1
                            AND zstpara_mapa_id = 'SERVICIO_SOC'
                            AND SUBSTR(ZSTPARA_PARAM_ID,1,3) = jump.campus
                            AND SUBSTR(ZSTPARA_PARAM_ID,5,2) = jump.nivel)  loop
            ----- lo enviamos a la funcion de validacion...
                -- aqui recibimos el cursor
                            
              vdocto :=  PKG_QR_DIG.F_VALIDA_DOCTO (JUMP.PIDM, onn.documento, onn.estatus, null );
                 
                 dbms_output.put_line('SALIENDO DE funcion ss '||ppidm||','||onn.documento||','||onn.estatus||'-valida docto--'||vdocto );
                   
              IF vdocto = onn.estatus  THEN
                
                VCONTA_DOC := VCONTA_DOC + 1 ;
                
                ELSE
                
                VCONTA_NODOC := VCONTA_NODOC +1;
                
              END IF;
              
              
            end loop;
               
      IF VCONTA_DOC >= 2   THEN
             --ENTRA A LA SEGUNDA PARTE   
               
            --dbms_output.put_line('entra a la segunda parte '||ppidm||'-valida docto--'||VCONTA_DOC ); 
             
          ---validamos que tenga mas del 70% avance
           Begin
                  SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 (JUMP.PIDM, JUMP.PROGRAMA)
                    INTO VAVANCE
                    FROM DUAL;
               --   DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
           EXCEPTION  WHEN OTHERS  THEN
               VAVANCE := 0;
           END;

                 IF TO_NUMBER(VAVANCE) >= 100 THEN
                       VAVANCE := '100';
                  END IF;
       --DBMS_OUTPUT.PUT_LINE('EL AVANCE DEL ALUNO ES  '||JUMP.PIDM ||'-'||VAVANCE );
        IF VAVANCE >= 70 THEN         
               
        --DBMS_OUTPUT.PUT_LINE('AL INICIAR PROCESO SS '||JUMP.PIDM ||'-'||JUMP.PROGRAMA||'-'|| VSALIDA );
          ----- se debe insertar una etiqueta en goradid
            Begin
                    Select count(1)
                        Into vl_existe
                        from GENERAL.GORADID
                    Where GORADID_PIDM = jump.PIDM
                    And GORADID_ADID_CODE  = P_ADID_ID;
             Exception  When Others then
                    vl_existe :=0;
            End;

             If vl_existe =0 then
                 begin
                   insert into GORADID values(jump.PIDM,P_ADID_ID, P_ADID_ID, 'WWW_QRDI', sysdate, 'SS_AUSS',null, 0,null);
                 Exception
                 When others then
                 vsalida:='Error al insertar Etiqueta'||sqlerrm;
                 end;
             END IF;
             
             IF vsalida = 'EXITO' THEN
                 -- SE INSERTA EL REG EN LA BITACORA DE ENVIOS DE MAIL QUE HACE DESDE PYTHON
                 BEGIN
                     INSERT INTO SZTAUSS (SZT_PIDM,SZT_PROGRAMA,SZT_TERM_CTLG,SZT_ACTIVITY_DATE,SZT_FECHA_ENVIO_MAIL,SZT_DATA_ORIGIN,SZT_USER,SZT_COMENTARIOS_BANNER,SZT_COMENTARIOS_SIU)
                           VALUES (JUMP.PIDM, JUMP.PROGRAMA, JUMP.CTLG, SYSDATE,NULL,'SS_AUSS',USER, NULL,NULL    );
                  Exception
                     When others then
                     vsalida:='Error al insertar Etiqueta'||sqlerrm;
                  end;
                 
             END IF;
              --DBMS_OUTPUT.PUT_LINE('AL TERMINAR LOS  INSERTS '||JUMP.PIDM ||'-'||JUMP.PROGRAMA||'-'|| VSALIDA );

        COMMIT;
        END IF;
        
      END IF;
      
END LOOP;



END  P_UNIVERSO_SS;


FUNCTION F_VALIDA_DOCTO (PPDIM NUMBER, PDOCTO VARCHAR2, PESTATUS VARCHAR2, PESTATUS2 VARCHAR2 )  RETURN VARCHAR2 IS
-- ESTA FUNCIÓN SE GENERA PARA SABER EL ESTATUS DE UN DOCUMENTO 
-- SE CREO PARA VALIDAR LOS DOCTOS DE SS PERO SE PUEDE USAR PARA CUALQUIER OTRO PROYECTO. GLOVICX 22.11.2024

VSALIDA VARCHAR2(200):='EXITO';
--VESTATUS   VARCHAR2(30):='SI';

BEGIN
      -- dbms_output.put_line('inicia funcion docto '|| PPDIM ||'-'||pdocto||'-'||pestatus||'-'||pestatus2   );
         begin
               
             select distinct kl.SARCHKL_CKST_CODE
                  INTO VSALIDA
              from sarchkl kl   
                where 1=1 
                 and kl.SARCHKL_PIDM = PPDIM
                 AND kl.SARCHKL_ADMR_CODE  =  PDOCTO
                 and ( kl.SARCHKL_CKST_CODE  =  PESTATUS
                   OR  kl.SARCHKL_CKST_CODE  =  PESTATUS2 )
                 ;
              
         exception when others then
            VSALIDA :=  'NO';
             dbms_output.put_line('ERROORRR   EN valida docto '|| PPDIM ||'-'||pdocto||'-'||pestatus||'-'||pestatus2   );       
         end;



RETURN VSALIDA;

END F_VALIDA_DOCTO;


FUNCTION F_UPD_AUSS (PPIDM NUMBER, PPROGRAMA VARCHAR2, PPERIODO VARCHAR2, PFECH_ENV  DATE,  PBANDERA NUMBER, PCOMENT VARCHAR2 ) 
 RETURN VARCHAR2 IS

VSALIDA VARCHAR2(400):='EXITO' ;

BEGIN

  UPDATE SZTAUSS AU
     SET    SZT_FECHA_ENVIO_MAIL = PFECH_ENV,
            SZT_FLAG             = PBANDERA,
            SZT_COMENTARIOS_SIU  = PCOMENT
      WHERE 1=1
      AND SZT_PIDM = PPIDM
      AND SZT_PROGRAMA = PPROGRAMA
      AND SZT_TERM_CTLG  = PPERIODO;

COMMIT;

RETURN   (VSALIDA);

EXCEPTION WHEN OTHERS THEN

RETURN   (SQLERRM);

END F_UPD_AUSS;

FUNCTION F_MOD_LIBERACION RETURN SYS_REFCURSOR  IS
---FUNCION QUE SE USA PARA UNA DE LAS PREGUNTAS PARA ADQUIRIR EL SERVICIO SOCIAL DESDE EL AUTOSERVICIO     
--  ESTA FUNCIÓN LA CONSUME PYTHON PARA PRESENTAR LAS OPCIONES DE ENVIO EL Método de entrega GLOVICX 15.11.2024 PROYECTO 
-- DOCUMENTOS QR_SS

cur_salida  SYS_REFCURSOR;
VSALIDA   VARCHAR2(400);


BEGIN

 open cur_salida  FOR  
        select ZSTPARA_PARAM_ID,  ZSTPARA_PARAM_DESC
            from ZSTPARA
            where 1=1
            AND ZSTPARA_MAPA_ID = 'MOD_LIBERACION';
            
  
 RETURN cur_salida;

exception when others then
VSALIDA := SQLERRM;

dbms_output.put_line('Error general funcion f_MET_SS  '|| VSALIDA );


END F_MOD_LIBERACION;



END PKG_QR_DIG;
/

DROP PUBLIC SYNONYM PKG_QR_DIG;

CREATE OR REPLACE PUBLIC SYNONYM PKG_QR_DIG FOR BANINST1.PKG_QR_DIG;


GRANT EXECUTE ON BANINST1.PKG_QR_DIG TO PUBLIC;
